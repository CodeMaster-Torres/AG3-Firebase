import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'edit_book_screen.dart'; // Importar la pantalla de edición
import 'delete_confirmation_screen.dart'; // Importar la pantalla de confirmación de eliminación

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: LoginScreen(), // Mostrar la pantalla de login al inicio
    );
  }
}

class LoginScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> _signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential authResult = await _auth.signInWithCredential(credential);
    final User? user = authResult.user;

    return user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Login with Google'),
          onPressed: () async {
            User? user = await _signInWithGoogle();
            if (user != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            }
          },
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? imageUrl;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Firebase Storage",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (imageUrl != null)
                  Container(
                    height: 200,
                    width: 200,
                    child: Image.network(imageUrl!),
                  )
                else
                  const SizedBox(height: 200, width: 200),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Book Title"),
                ),
                TextField(
                  controller: _authorController,
                  decoration: const InputDecoration(labelText: "Author"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => uploadBook(),
                  child: const Text("Upload Book"),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.pinkAccent,
                  ),
                ),
                const SizedBox(height: 20),
                _buildBookList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> uploadBook() async {
    final _storage = FirebaseStorage.instanceFor(bucket: "ag3almacenamiento.appspot.com");
    final _picker = ImagePicker();
    PickedFile? image;

    var permissionStatus = await Permission.manageExternalStorage.status;

    if (permissionStatus.isGranted) {
      image = await _picker.getImage(source: ImageSource.gallery);

      if (image != null) {
        var file = File(image.path);

        try {
          var snapshot = await _storage
              .ref()
              .child('book_covers/${file.path.split('/').last}')
              .putFile(file);

          var downloadUrl = await snapshot.ref.getDownloadURL();
          print("downloadUrl: $downloadUrl");

          await FirebaseFirestore.instance.collection('books').add({
            'title': _titleController.text,
            'author': _authorController.text,
            'coverUrl': downloadUrl,
          });

          setState(() {
            imageUrl = downloadUrl;
            _titleController.clear(); // Limpiar el campo de título después de subir el libro
            _authorController.clear(); // Limpiar el campo de autor después de subir el libro
          });
        } catch (e) {
          print("Error al subir la imagen: $e");
        }
      } else {
        print('No path received');
      }
    } else {
      var status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        uploadBook();
      } else {
        print('No se han concedido los permisos');
      }
    }
  }

  Widget _buildBookList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('books').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return DataTable(
          columns: [
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Author')),
            DataColumn(label: Text('Cover')),
            DataColumn(label: Text('Actions')),
          ],
          rows: snapshot.data!.docs.map((document) {
            return DataRow(cells: [
              DataCell(Text(document['title'])),
              DataCell(Text(document['author'])),
              DataCell(Image.network(document['coverUrl'])),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _editBook(document),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _confirmDeleteBook(context, document),
                  ),
                ],
              )),
            ]);
          }).toList(),
        );
      },
    );
  }

  void _editBook(DocumentSnapshot document) {
    // Navegar a la pantalla de edición pasando el documento del libro
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditBookScreen(document: document)),
    );
  }

  void _confirmDeleteBook(BuildContext context, DocumentSnapshot document) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteConfirmationScreen(document: document); // Mostrar pantalla de confirmación de eliminación
      },
    );
  }
}
