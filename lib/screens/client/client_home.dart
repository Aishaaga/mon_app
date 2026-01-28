import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart'; // Import du service

import '../auth/login_screen.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  State<ClientHome> createState() => _ClientHome();
}

class _ClientHome extends State<ClientHome> {
  // Contrôleurs pour les champs de formulaire
  final AuthService _authService = AuthService();
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final ageController = TextEditingController();

  // Référence à la collection Firestore
  final CollectionReference personnes = FirebaseFirestore.instance.collection(
    'personnes',
  );

  // ID du document en cours d'édition (null = création, non null = modification)
  String? editingId;

  Future<void> _signOut() async {
    // Méthode 1 : Utiliser la méthode qui retourne un booléen
    final success = await _authService.signOutAndNavigate(context);

    if (success && mounted) {
      // Navigation explicite dans le widget
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } else if (!success) {
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la déconnexion')),
        );
      }
    }
  }

  // Méthode alternative plus simple
  Future<void> _signOutSimple() async {
    try {
      // Déconnexion de Firebase
      await FirebaseAuth.instance.signOut();

      // Navigation vers l'écran de login
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _signOut();
            },
          ),
        ],
      ),
      body: const Center(child: Text('Page ClientHome - À compléter')),
    );
  }
}
