import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../shared/payment_screen.dart';

class ClientPaymentScreen extends StatefulWidget {
  final String? jobId;
  final String? artisanId;
  final String? jobTitle;
  final double? amount;

  const ClientPaymentScreen({
    super.key,
    this.jobId,
    this.artisanId,
    this.jobTitle,
    this.amount,
  });

  @override
  State<ClientPaymentScreen> createState() => _ClientPaymentScreenState();
}

class _ClientPaymentScreenState extends State<ClientPaymentScreen> 
    with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  late TabController _tabController;
  bool _isLoading = false;
  List<Payment> _recentPayments = [];
  double _totalSpent = 0.0;
  String? _clientId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _clientId = FirebaseAuth.instance.currentUser?.uid;
    _loadPaymentData();
    
    // Récupérer les paramètres de l'URL si disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractUrlParameters();
    });
  }

  void _extractUrlParameters() {
    final uri = Uri.base;
    final jobId = uri.queryParameters['jobId'] ?? widget.jobId;
    final artisanId = uri.queryParameters['artisanId'] ?? widget.artisanId;
    final jobTitle = uri.queryParameters['jobTitle'] ?? widget.jobTitle;
    final amount = double.tryParse(uri.queryParameters['amount'] ?? '') ?? widget.amount;
    
    if (jobId != null && artisanId != null && amount != null) {
      setState(() {
        // Mettre à jour les paramètres si nécessaire
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes paiements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.jobId != null 
              ? context.go('/client/job/${widget.jobId}')
              : context.go('/client/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.payment), text: 'Nouveau paiement'),
            Tab(icon: Icon(Icons.history), text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewPaymentTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildNewPaymentTab() {
    if (widget.jobId == null || widget.artisanId == null || widget.amount == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune mission sélectionnée pour le paiement',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accédez à une demande acceptée pour effectuer le paiement',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/client/my-requests'),
              icon: const Icon(Icons.list),
              label: const Text('Voir mes demandes'),
            ),
            const SizedBox(height: 16),
            const Text(
              'OU',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showManualPaymentForm(),
              icon: const Icon(Icons.add_circle),
              label: const Text('Créer un paiement manuellement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SharedPaymentScreen(
      jobId: widget.jobId!,
      clientId: _clientId!,
      artisanId: widget.artisanId!,
      amount: widget.amount!,
      userType: 'client',
      jobTitle: widget.jobTitle,
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadPaymentData,
      child: Column(
        children: [
          _buildSpendingSummary(),
          Expanded(child: _buildPaymentsList()),
        ],
      ),
    );
  }

  Widget _buildSpendingSummary() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Dépenses totales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${_totalSpent.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Ce mois',
                  _getMonthlySpending(),
                  Colors.purple,
                ),
                _buildStatItem(
                  'Cette semaine',
                  _getWeeklySpending(),
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(2)} €',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun paiement trouvé',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de paiements enregistrés',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadPaymentData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recentPayments.length,
      itemBuilder: (context, index) {
        final payment = _recentPayments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(payment.status),
          child: Icon(
            _getStatusIcon(payment.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          payment.description ?? 'Paiement pour mission #${payment.jobId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${payment.methodText} • ${_formatDate(payment.createdAt)}'),
            const SizedBox(height: 4),
            Text(
              payment.statusText,
              style: TextStyle(
                color: _getStatusColor(payment.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${payment.amount.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (payment.status == PaymentStatus.completed) ...[
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.receipt, size: 20),
                onPressed: () => _showPaymentDetails(payment),
              ),
            ],
          ],
        ),
        onTap: () => _showPaymentDetails(payment),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check;
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.processing:
        return Icons.sync;
      case PaymentStatus.failed:
        return Icons.close;
      case PaymentStatus.refunded:
        return Icons.undo;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  double _getMonthlySpending() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    return _recentPayments
        .where((payment) => 
            payment.status == PaymentStatus.completed &&
            payment.createdAt.isAfter(monthStart))
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double _getWeeklySpending() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return _recentPayments
        .where((payment) => 
            payment.status == PaymentStatus.completed &&
            payment.createdAt.isAfter(weekStart))
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  Future<void> _loadPaymentData() async {
    if (_clientId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur non authentifié'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payments = await _paymentService.getPaymentsForClient(_clientId!);
      final spent = await _paymentService.getTotalSpentForClient(_clientId!);

      setState(() {
        _recentPayments = payments;
        _totalSpent = spent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  void _showPaymentDetails(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du paiement'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID:', payment.id),
              _buildDetailRow('Mission:', payment.jobId),
              _buildDetailRow('Artisan:', payment.artisanId),
              _buildDetailRow('Montant:', '${payment.amount.toStringAsFixed(2)} €'),
              _buildDetailRow('Méthode:', payment.methodText),
              _buildDetailRow('Statut:', payment.statusText),
              _buildDetailRow('Date:', _formatDate(payment.createdAt)),
              if (payment.transactionId != null)
                _buildDetailRow('Transaction:', payment.transactionId!),
              if (payment.completedAt != null)
                _buildDetailRow('Terminé le:', _formatDate(payment.completedAt!)),
              if (payment.description != null)
                _buildDetailRow('Description:', payment.description!),
            ],
          ),
        ),
        actions: [
          if (payment.status == PaymentStatus.completed)
            TextButton(
              onPressed: () => _requestRefund(payment),
              child: const Text('Demander remboursement'),
            ),
          if (payment.status == PaymentStatus.completed)
            TextButton(
              onPressed: () => _downloadInvoice(payment),
              child: const Text('Télécharger facture'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _requestRefund(Payment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demander un remboursement'),
        content: Text(
          'Êtes-vous sûr de vouloir demander un remboursement de ${payment.amount.toStringAsFixed(2)} € ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _paymentService.refundPayment(payment.id);
        Navigator.of(context).pop();
        _loadPaymentData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Remboursement demandé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
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
  }

  void _downloadInvoice(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Facture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Facture #${payment.id}'),
            Text('Montant: ${payment.amount.toStringAsFixed(2)} €'),
            const Text('Téléchargement simulé'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManualPaymentForm() {
    final jobIdController = TextEditingController();
    final artisanNameController = TextEditingController(); // Changé: nom au lieu d'ID
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un paiement manuellement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jobIdController,
                decoration: const InputDecoration(
                  labelText: 'ID de la mission',
                  hintText: 'job_123 (optionnel)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: artisanNameController, // Changé: nom au lieu d'ID
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'artisan',
                  hintText: 'Jean Dupont',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant (€)',
                  hintText: '100.00',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Réparation plomberie',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez remplir le montant au minimum'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final request = PaymentRequest(
                  jobId: jobIdController.text.isNotEmpty ? jobIdController.text : 'manual_${DateTime.now().millisecondsSinceEpoch}',
                  clientId: _clientId!,
                  artisanId: artisanNameController.text.isNotEmpty ? artisanNameController.text : 'artisan_inconnu', // Utiliser le nom
                  amount: double.parse(amountController.text),
                  method: PaymentMethod.creditCard,
                  description: descriptionController.text.isNotEmpty 
                      ? descriptionController.text 
                      : 'Paiement manuel pour ${artisanNameController.text}',
                );

                await _paymentService.createPayment(request);
                Navigator.of(context).pop();
                _loadPaymentData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paiement créé avec succès!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
