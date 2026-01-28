import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Méthode de déconnexion avec contexte
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();

      // Navigation vers login - S'assurer que le contexte est valide
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      });
    } catch (e) {
      throw Exception('Erreur de déconnexion: $e');
    }
  }

  // Méthode alternative qui retourne un booléen pour gérer la navigation dans le widget
  Future<bool> signOutAndNavigate(BuildContext context) async {
    try {
      await _auth.signOut();
      return true; // Succès
    } catch (e) {
      print('Erreur de déconnexion: $e');
      return false; // Échec
    }
  }

  // Méthode de déconnexion sans contexte (juste sign out)
  Future<void> signOutOnly() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur de déconnexion: $e');
    }
  }

  // Vérifier si l'utilisateur est connecté
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Récupérer l'utilisateur courant
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
