import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PersonnesPage extends StatefulWidget {
  const PersonnesPage({super.key});

  @override
  State<PersonnesPage> createState() => _PersonnesPageState();
}

class _PersonnesPageState extends State<PersonnesPage> {
  // Contrôleurs pour les champs de formulaire
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final ageController = TextEditingController();

  // Référence à la collection Firestore
  final CollectionReference personnes = FirebaseFirestore.instance.collection(
    'personnes',
  );

  // ID du document en cours d'édition (null = création, non null = modification)
  String? editingId;

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD Personnes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: const Center(child: Text('Page Personnes - À compléter')),
    );
  }
}
