import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/request.dart';

class RequestProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Request> _requests = [];
  bool _isLoading = false;
  String? _error;

  List<Request> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtenir les demandes du client connecté
  List<Request> get clientRequests {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];
    return _requests.where((request) => request.clientId == currentUser.uid).toList();
  }

  // Charger toutes les demandes
  Future<void> loadRequests() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore.collection('requests').get();
      _requests = snapshot.docs
          .map((doc) => Request.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de chargement des demandes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Créer une nouvelle demande
  Future<String?> createRequest({
    required String category,
    required String description,
    required List<String> photos,
    required Timestamp preferredDate,
    required double estimatedBudget,
    required String address,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final now = Timestamp.now();
      final request = Request(
        clientId: currentUser.uid,
        category: category,
        description: description,
        photos: photos,
        preferredDate: preferredDate,
        estimatedBudget: estimatedBudget,
        address: address,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore.collection('requests').add(request.toMap());
      
      // Ajouter la demande locale
      final newRequest = request.copyWith(id: docRef.id);
      _requests.add(newRequest);

      _isLoading = false;
      notifyListeners();

      return docRef.id;
    } catch (e) {
      _error = 'Erreur de création de demande: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Mettre à jour une demande
  Future<bool> updateRequest(String requestId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('requests').doc(requestId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });

      // Mettre à jour localement
      final index = _requests.indexWhere((req) => req.id == requestId);
      if (index != -1) {
        final currentRequest = _requests[index];
        _requests[index] = currentRequest.copyWith(
          ...data,
          'updatedAt': Timestamp.now(),
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur de mise à jour: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Supprimer une demande
  Future<bool> deleteRequest(String requestId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('requests').doc(requestId).delete();

      // Supprimer localement
      _requests.removeWhere((req) => req.id == requestId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur de suppression: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtenir les demandes disponibles pour les artisans (statut pending)
  List<Request> get availableRequests {
    return _requests.where((request) => request.status == 'pending').toList();
  }

  // Obtenir les demandes par catégorie
  List<Request> getRequestsByCategory(String category) {
    return _requests.where((request) => request.category == category).toList();
  }

  // Effacer les erreurs
  void clearError() {
    _error = null;
    notifyListeners();
  }
}