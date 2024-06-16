import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditBookScreen extends StatefulWidget {
  final DocumentSnapshot document;

  const EditBookScreen({Key? key, required this.document}) : super(key: key);

  @override
  _EditBookScreenState createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document['title']);
    _authorController = TextEditingController(text: widget.document['author']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar libro'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _authorController,
                decoration: InputDecoration(labelText: 'Autor'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _updateBook(context),
                child: Text('Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateBook(BuildContext context) async {
    await FirebaseFirestore.instance.collection('books').doc(widget.document.id).update({
      'title': _titleController.text,
      'author': _authorController.text,
    });

    // Mostrar la SnackBar de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Libro modificado exitosamente'),
      ),
    );

    Navigator.of(context).pop(); // Regresar a la pantalla anterior
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }
}
