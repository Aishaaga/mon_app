import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';

class SharedPaymentScreen extends StatefulWidget {
  final String jobId;
  final String clientId;
  final String artisanId;
  final double amount;
  final String userType;
  final String? jobTitle;

  const SharedPaymentScreen({
    super.key,
    required this.jobId,
    required this.clientId,
    required this.artisanId,
    required this.amount,
    required this.userType,
    this.jobTitle,
  });

  @override
  State<SharedPaymentScreen> createState() => _SharedPaymentScreenState();
}

class _SharedPaymentScreenState extends State<SharedPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  PaymentMethod _selectedMethod = PaymentMethod.creditCard;
  bool _isProcessing = false;
  Payment? _currentPayment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userType == 'client' ? 'Paiement' : 'Détails du paiement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _currentPayment != null
          ? _buildPaymentStatusView()
          : _buildPaymentForm(),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummary(),
          const SizedBox(height: 24),
          _buildPaymentMethodSelection(),
          const SizedBox(height: 24),
          if (widget.userType == 'client') ...[
            _buildPaymentButton(),
            const SizedBox(height: 16),
            _buildSecurityInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé de la commande',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (widget.jobTitle != null) ...[
              Text(
                widget.jobTitle!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Montant total:'),
                Text(
                  '${widget.amount.toStringAsFixed(2)} €',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Méthode de paiement',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ...PaymentMethod.values.map((method) {
              return RadioListTile<PaymentMethod>(
                title: Text(_getPaymentMethodText(method)),
                subtitle: Text(_getPaymentMethodDescription(method)),
                value: method,
                groupValue: _selectedMethod,
                onChanged: widget.userType == 'client'
                    ? (value) => setState(() => _selectedMethod = value!)
                    : null,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: _isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('Traitement en cours...'),
                ],
              )
            : Text(
                'Payer ${widget.amount.toStringAsFixed(2)} €',
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.lock, color: Colors.green),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Paiement sécurisé via cryptage SSL',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusView() {
    if (_currentPayment == null) return const SizedBox.shrink();

    final payment = _currentPayment!;
    final isSuccess = payment.status == PaymentStatus.completed;
    final isFailed = payment.status == PaymentStatus.failed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              size: 80,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              isSuccess ? 'Paiement réussi!' : 'Échec du paiement',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isSuccess ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (payment.transactionId != null) ...[
              Text(
                'ID de transaction: ${payment.transactionId}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Montant: ${payment.amount.toStringAsFixed(2)} €',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Méthode: ${payment.methodText}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            if (isSuccess) ...[
              ElevatedButton(
                onPressed: () => _navigateToHome(),
                child: const Text('Retour à l\'accueil'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _showReceipt(),
                child: const Text('Voir le reçu'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => setState(() {
                  _currentPayment = null;
                  _isProcessing = false;
                }),
                child: const Text('Réessayer'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Annuler'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final paymentRequest = PaymentRequest(
        jobId: widget.jobId,
        clientId: widget.clientId,
        artisanId: widget.artisanId,
        amount: widget.amount,
        method: _selectedMethod,
        description: widget.jobTitle,
      );

      final payment = await _paymentService.createPayment(paymentRequest);
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      
      final processedPayment = await _paymentService.processPayment(
        payment.id,
        transactionId: transactionId,
      );

      setState(() {
        _currentPayment = processedPayment;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToHome() {
    if (widget.userType == 'client') {
      context.go('/client/home');
    } else {
      context.go('/artisan/home');
    }
  }

  void _showReceipt() {
    if (_currentPayment == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reçu de paiement'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${_currentPayment!.id}'),
              const SizedBox(height: 8),
              Text('Date: ${_currentPayment!.createdAt}'),
              const SizedBox(height: 8),
              Text('Montant: ${_currentPayment!.amount.toStringAsFixed(2)} €'),
              const SizedBox(height: 8),
              Text('Méthode: ${_currentPayment!.methodText}'),
              const SizedBox(height: 8),
              if (_currentPayment!.transactionId != null)
                Text('Transaction: ${_currentPayment!.transactionId}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Carte de crédit';
      case PaymentMethod.debitCard:
        return 'Carte de débit';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.stripe:
        return 'Stripe';
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.bankTransfer:
        return 'Virement bancaire';
    }
  }

  String _getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Payer avec Visa, Mastercard, etc.';
      case PaymentMethod.debitCard:
        return 'Payer directement depuis votre compte';
      case PaymentMethod.paypal:
        return 'Payer avec votre compte PayPal';
      case PaymentMethod.stripe:
        return 'Paiement sécurisé via Stripe';
      case PaymentMethod.cash:
        return 'Payer en espèces à l\'artisan';
      case PaymentMethod.bankTransfer:
        return 'Virement bancaire direct';
    }
  }
}
