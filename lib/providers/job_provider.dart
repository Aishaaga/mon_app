import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job.dart';

class JobProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Job> _jobs = [];
  bool _isLoading = false;
  String? _error;

  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtenir les jobs de l'artisan connecté
  List<Job> get myJobs {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];
    return _jobs.where((job) => job.artisanId == currentUser.uid).toList();
  }

  // Charger tous les jobs de l'artisan
  Future<void> loadMyJobs() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _jobs = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Charger tous les jobs de l'artisan
      final snapshot = await _firestore
          .collection('jobs')
          .where('artisanId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();
      
      _jobs = snapshot.docs
          .map((doc) => Job.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de chargement des jobs: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Créer un job à partir d'une demande acceptée
  Future<String?> createJob({
    required String requestId,
    required String clientId,
    required String category,
    required String description,
    required List<String> photos,
    required double estimatedBudget,
    required String address,
    required double quotePrice,
    required String quoteDescription,
    required int quoteDuration,
    required List<String> quoteMaterials,
    required String quoteNotes,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Artisan non connecté');
      }

      final job = Job.fromRequest(
        requestId: requestId,
        artisanId: currentUser.uid,
        clientId: clientId,
        category: category,
        description: description,
        photos: photos,
        estimatedBudget: estimatedBudget,
        address: address,
        quotePrice: quotePrice,
        quoteDescription: quoteDescription,
        quoteDuration: quoteDuration,
        quoteMaterials: quoteMaterials,
        quoteNotes: quoteNotes,
      );

      final docRef = await _firestore.collection('jobs').add(job.toMap());
      
      // Ajouter le job localement
      final newJob = job.copyWith(id: docRef.id);
      _jobs.add(newJob);

      _isLoading = false;
      notifyListeners();

      return docRef.id;
    } catch (e) {
      _error = 'Erreur de création du job: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Mettre à jour un job
  Future<bool> updateJob(String jobId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('jobs').doc(jobId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });

      // Mettre à jour localement
      final index = _jobs.indexWhere((job) => job.id == jobId);
      if (index != -1) {
        final currentJob = _jobs[index];
        _jobs[index] = currentJob.copyWith(
          status: data['status'] ?? currentJob.status,
          startedAt: data['startedAt'] ?? currentJob.startedAt,
          completedAt: data['completedAt'] ?? currentJob.completedAt,
          updatedAt: Timestamp.now(),
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur de mise à jour du job: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Commencer un job
  Future<bool> startJob(String jobId) async {
    return await updateJob(jobId, {
      'status': 'in_progress',
      'startedAt': Timestamp.now(),
    });
  }

  // Terminer un job
  Future<bool> completeJob(String jobId) async {
    return await updateJob(jobId, {
      'status': 'completed',
      'completedAt': Timestamp.now(),
    });
  }

  // Annuler un job
  Future<bool> cancelJob(String jobId) async {
    return await updateJob(jobId, {
      'status': 'cancelled',
    });
  }

  // Supprimer un job
  Future<bool> deleteJob(String jobId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('jobs').doc(jobId).delete();

      // Supprimer localement
      _jobs.removeWhere((job) => job.id == jobId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur de suppression du job: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtenir les jobs par statut
  List<Job> getJobsByStatus(String status) {
    return myJobs.where((job) => job.status == status).toList();
  }

  // Statistiques
  Map<String, dynamic> getStatistics() {
    final myJobsList = myJobs;
    
    int accepted = 0;
    int inProgress = 0;
    int completed = 0;
    double totalEarnings = 0.0;

    for (var job in myJobsList) {
      switch (job.status) {
        case 'accepted':
          accepted++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        case 'completed':
          completed++;
          totalEarnings += job.earnings;
          break;
      }
    }

    return {
      'accepted': accepted,
      'inProgress': inProgress,
      'completed': completed,
      'totalEarnings': totalEarnings,
      'totalJobs': myJobsList.length,
    };
  }

  // Ajouter un job de test
  void addTestJob(Job job) {
    _jobs.add(job);
    notifyListeners();
  }

  // Effacer tous les jobs (pour les tests)
  void clearAllJobs() {
    _jobs.clear();
    notifyListeners();
  }

  // Effacer les erreurs
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
