import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/request_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/custom_app_bar.dart';
import '../../models/request.dart';
import '../../models/user.dart';

class ArtisanRequestDetailsScreen extends StatefulWidget {
  final String requestId;

  const ArtisanRequestDetailsScreen({super.key, required this.requestId});

  @override
  State<ArtisanRequestDetailsScreen> createState() => _ArtisanRequestDetailsScreenState();
}

class _ArtisanRequestDetailsScreenState extends State<ArtisanRequestDetailsScreen> {
  final _quoteController = TextEditingController();
  final _messageController = TextEditingController();
  double _estimatedPrice = 0.0;
  int _estimatedDuration = 1;
  bool _isSendingQuote = false;

  @override
  void dispose() {
    _quoteController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Détails de la demande',
        showBackButton: true,
        onBackPressed: () => context.go('/artisan/available-requests'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partage bientôt disponible')),
              );
            },
            tooltip: 'Partager',
          ),
        ],
      ),
      body: Consumer<RequestProvider>(
        builder: (context, requestProvider, child) {
          final request = requestProvider.requests
              .where((r) => r.id == widget.requestId)
              .firstOrNull;

          if (request == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des détails...'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await requestProvider.loadAvailableRequests();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte principale avec informations de base
                  _buildBasicInfoCard(request),
                  const SizedBox(height: 16),

                  // Carte de description détaillée
                  _buildDescriptionCard(request),
                  const SizedBox(height: 16),

                  // Carte photos
                  if (request.photos != null && request.photos!.isNotEmpty)
                    _buildPhotosCard(request),
                  const SizedBox(height: 16),

                  // Carte informations client
                  _buildClientInfoCard(request),
                  const SizedBox(height: 16),

                  // Carte localisation
                  _buildLocationCard(request),
                  const SizedBox(height: 16),

                  // Carte devis (si artisan n'a pas encore envoyé de devis)
                  if (request.status == 'pending')
                    _buildQuoteCard(request),
                  const SizedBox(height: 16),

                  // Carte actions
                  _buildActionsCard(request),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoCard(Request request) {
    final isPending = request.status == 'pending';
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.category, // Utiliser category comme titre principal
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'DISPONIBLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.category, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  request.category,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.euro, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '${request.estimatedBudget.toInt()} DH',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.schedule, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Publié ${_formatDate(request.createdAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.flag, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  request.statusFormatted,
                  style: TextStyle(
                    fontSize: 14,
                    color: isPending ? Colors.orange : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            // Date préférée
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Date souhaitée: ${_formatDate(request.preferredDate)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(Request request) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Description détaillée',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosCard(Request request) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Photos (${request.photos!.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: request.photos!.length,
                itemBuilder: (context, index) {
                  final photoUrl = request.photos![index];
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfoCard(Request request) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Informations du client',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: const Icon(Icons.person, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client ID: ${request.clientId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Informations de contact disponibles après acceptation',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact disponible après envoi de devis')),
                    );
                  },
                  tooltip: 'Contacter le client',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(Request request) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Localisation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.place, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.address,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    Text(
                      'Carte non disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(Request request) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.euro, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Envoyer un devis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Prix estimé
            Text(
              'Prix estimé (DH)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Slider(
              value: _estimatedPrice,
              min: 0,
              max: 5000,
              divisions: 50,
              label: '${_estimatedPrice.toInt()} DH',
              onChanged: (value) {
                setState(() {
                  _estimatedPrice = value;
                });
              },
            ),
            Text(
              '${_estimatedPrice.toInt()} DH',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Durée estimée
            Text(
              'Durée estimée (jours)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _estimatedDuration.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '$_estimatedDuration jours',
                    onChanged: (value) {
                      setState(() {
                        _estimatedDuration = value.toInt();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$_estimatedDuration',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Message
            Text(
              'Message pour le client',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Décrivez votre proposition et votre expertise...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            
            const SizedBox(height: 16),
            
            // Bouton envoyer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSendingQuote ? null : _sendQuote,
                icon: _isSendingQuote 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSendingQuote ? 'Envoi en cours...' : 'Envoyer le devis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(Request request) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions rapides',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Messagerie bientôt disponible')),
                      );
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Contacter le client'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sauvegarde bientôt disponible')),
                      );
                    },
                    icon: const Icon(Icons.bookmark),
                    label: const Text('Sauvegarder'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () {
                  _showReportDialog(request);
                },
                icon: const Icon(Icons.flag, color: Colors.red),
                label: const Text('Signaler la demande', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendQuote() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter un message pour le client')),
      );
      return;
    }

    setState(() {
      _isSendingQuote = true;
    });

    try {
      // TODO: Implémenter l'envoi du devis à Firestore
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devis envoyé avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/artisan/available-requests');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingQuote = false;
        });
      }
    }
  }

  void _showReportDialog(Request request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler la demande'),
        content: const Text('Pourquoi signalez-vous cette demande?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demande signalée')),
              );
            },
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "aujourd'hui";
    } else if (difference.inDays == 1) {
      return 'hier';
    } else if (difference.inDays < 7) {
      return 'il y a ${difference.inDays} jours';
    } else {
      return 'le ${date.day}/${date.month}/${date.year}';
    }
  }
}
