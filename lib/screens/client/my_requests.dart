import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/request_provider.dart';
import '../../models/request.dart';
import 'package:go_router/go_router.dart'; 


class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RequestProvider>(context, listen: false).loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Demandes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<RequestProvider>(context, listen: false).loadRequests();
            },
          ),
        ],
      ),
      body: Consumer<RequestProvider>(
        builder: (context, requestProvider, child) {
          if (requestProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (requestProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Erreur: ${requestProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      requestProvider.clearError();
                      requestProvider.loadRequests();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final clientRequests = requestProvider.clientRequests;

          if (clientRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vous n\'avez aucune demande',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.go('/client/create-request');
                    },
                    child: const Text('Créer une demande'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => requestProvider.loadRequests(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clientRequests.length,
              itemBuilder: (context, index) {
                final request = clientRequests[index];
                return RequestCard(request: request);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/client/create-request');
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final Request request;

  const RequestCard({super.key, required this.request});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec catégorie et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.statusFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              request.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Détails
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Date: ${_formatDate(request.preferredDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.euro, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Budget: ${request.estimatedBudget.toStringAsFixed(2)}€',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Adresse: ${request.address}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (request.photos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.photo_library, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${request.photos.length} photo(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    context.go('/client/request/${request.id}');
                  },
                  child: const Text('Voir détails'),
                ),
                if (request.status == 'pending') ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      _showCancelDialog(context, request);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Annuler'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Request request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la demande'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette demande ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final requestProvider = Provider.of<RequestProvider>(context, listen: false);
                await requestProvider.updateRequest(request.id!, {'status': 'cancelled'});
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demande annulée')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }
}
