import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _paymentsCollection = 
      FirebaseFirestore.instance.collection('payments');

  Future<Payment> createPayment(PaymentRequest request) async {
    try {
      final paymentId = _paymentsCollection.doc().id;
      final payment = Payment(
        id: paymentId,
        jobId: request.jobId,
        clientId: request.clientId,
        artisanId: request.artisanId,
        amount: request.amount,
        method: request.method,
        description: request.description,
        createdAt: DateTime.now(),
      );

      await _paymentsCollection.doc(paymentId).set(payment.toMap());
      return payment;
    } catch (e) {
      throw Exception('Erreur lors de la création du paiement: $e');
    }
  }

  Future<Payment?> getPayment(String paymentId) async {
    try {
      final doc = await _paymentsCollection.doc(paymentId).get();
      if (doc.exists) {
        return Payment.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du paiement: $e');
    }
  }

  Future<List<Payment>> getPaymentsForClient(String clientId) async {
    try {
      final snapshot = await _paymentsCollection
          .where('clientId', isEqualTo: clientId)
          .get();

      final payments = snapshot.docs
          .map((doc) => Payment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Trier côté client par date décroissante
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return payments;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paiements du client: $e');
    }
  }

  Future<List<Payment>> getPaymentsForArtisan(String artisanId) async {
    try {
      final snapshot = await _paymentsCollection
          .where('artisanId', isEqualTo: artisanId)
          .get();

      final payments = snapshot.docs
          .map((doc) => Payment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Trier côté client par date décroissante
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return payments;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paiements de l\'artisan: $e');
    }
  }

  Future<List<Payment>> getPaymentsForJob(String jobId) async {
    try {
      final snapshot = await _paymentsCollection
          .where('jobId', isEqualTo: jobId)
          .get();

      final payments = snapshot.docs
          .map((doc) => Payment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Trier côté client par date décroissante
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return payments;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paiements du job: $e');
    }
  }

  Future<Payment> updatePaymentStatus(String paymentId, PaymentStatus newStatus) async {
    try {
      final payment = await getPayment(paymentId);
      if (payment == null) {
        throw Exception('Paiement non trouvé');
      }

      final updatedPayment = payment.copyWith(
        status: newStatus,
        completedAt: newStatus == PaymentStatus.completed ? DateTime.now() : null,
      );

      await _paymentsCollection.doc(paymentId).update(updatedPayment.toMap());
      return updatedPayment;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut du paiement: $e');
    }
  }

  Future<Payment> processPayment(String paymentId, {String? transactionId}) async {
    try {
      final payment = await updatePaymentStatus(paymentId, PaymentStatus.processing);
      
      await Future.delayed(const Duration(seconds: 2));

      final isSuccessful = await _simulatePaymentProcessing();
      final finalStatus = isSuccessful ? PaymentStatus.completed : PaymentStatus.failed;
      
      final finalPayment = await updatePaymentStatus(paymentId, finalStatus);
      
      if (isSuccessful && transactionId != null) {
        final updatedPayment = finalPayment.copyWith(transactionId: transactionId);
        await _paymentsCollection.doc(paymentId).update(updatedPayment.toMap());
        return updatedPayment;
      }
      
      return finalPayment;
    } catch (e) {
      await updatePaymentStatus(paymentId, PaymentStatus.failed);
      throw Exception('Erreur lors du traitement du paiement: $e');
    }
  }

  Future<bool> _simulatePaymentProcessing() async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<Payment> refundPayment(String paymentId) async {
    try {
      final payment = await getPayment(paymentId);
      if (payment == null) {
        throw Exception('Paiement non trouvé');
      }

      if (payment.status != PaymentStatus.completed) {
        throw Exception('Seuls les paiements terminés peuvent être remboursés');
      }

      return await updatePaymentStatus(paymentId, PaymentStatus.refunded);
    } catch (e) {
      throw Exception('Erreur lors du remboursement du paiement: $e');
    }
  }

  Stream<List<Payment>> streamPaymentsForClient(String clientId) {
    return _paymentsCollection
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
          final payments = snapshot.docs
              .map((doc) => Payment.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          
          // Trier côté client par date décroissante
          payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return payments;
        });
  }

  Stream<List<Payment>> streamPaymentsForArtisan(String artisanId) {
    return _paymentsCollection
        .where('artisanId', isEqualTo: artisanId)
        .snapshots()
        .map((snapshot) {
          final payments = snapshot.docs
              .map((doc) => Payment.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          
          // Trier côté client par date décroissante
          payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return payments;
        });
  }

  Future<double> getTotalEarningsForArtisan(String artisanId) async {
    try {
      final payments = await getPaymentsForArtisan(artisanId);
      double total = 0.0;
      for (final payment in payments) {
        if (payment.status == PaymentStatus.completed) {
          total += payment.amount;
        }
      }
      return total;
    } catch (e) {
      throw Exception('Erreur lors du calcul des revenus: $e');
    }
  }

  Future<double> getTotalSpentForClient(String clientId) async {
    try {
      final payments = await getPaymentsForClient(clientId);
      double total = 0.0;
      for (final payment in payments) {
        if (payment.status == PaymentStatus.completed) {
          total += payment.amount;
        }
      }
      return total;
    } catch (e) {
      throw Exception('Erreur lors du calcul des dépenses: $e');
    }
  }
}