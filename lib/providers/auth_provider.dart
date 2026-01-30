import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  User? get currentUser => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _userData = doc.data();
      }
      notifyListeners();
    } catch (e) {
      print('Erreur chargement données utilisateur: $e');
    }
  }

  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> registerUser({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _userData = null;
    notifyListeners();
  }

  Future<String?> getUserType() async {
    if (_user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        return doc.data()?['userType'];
      }
      return null;
    } catch (e) {
      print('Erreur récupération type utilisateur: $e');
      return null;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadUserData(_user!.uid);
    } catch (e) {
      print('Erreur mise à jour profil: $e');
      rethrow;
    }
  }
}
