import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteConfirmationScreen extends StatelessWidget {
  final DocumentSnapshot document;

  const DeleteConfirmationScreen({Key? key, required this.document}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmación para eliminar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("¿Deseas eliminar el libro?"),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _deleteBook(context),
                  child: Text('Eliminar'),
                ),
                SizedBox(width: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteBook(BuildContext context) async {
    await FirebaseFirestore.instance.collection('books').doc(document.id).delete();
    Navigator.of(context).pop(); // Cerrar la pantalla de confirmación
  }
}
