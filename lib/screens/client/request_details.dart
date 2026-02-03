import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../providers/request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/request.dart';

class ClientRequestDetailsScreen extends StatefulWidget {
  final String requestId;

  const ClientRequestDetailsScreen({super.key, required this.requestId});

  @override
  State<ClientRequestDetailsScreen> createState() => _ClientRequestDetailsScreenState();
}

class _ClientRequestDetailsScreenState extends State<ClientRequestDetailsScreen> {
  Request? _request;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    try {
      final requestProvider = Provider.of<RequestProvider>(context, listen: false);
      await requestProvider.loadRequests();
      
      final requests = requestProvider.requests;
      final request = requests.firstWhere((r) => r.id == widget.requestId);
      
      setState(() {
        _request = request;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

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
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _getMockQuotes() {
    // Simuler des devis reçus
    return [
      {
        'artisanId': 'artisan1',
        'artisanName': 'Mohamed Benali',
        'artisanRating': 4.8,
        'artisanReviews': 23,
        'price': 850.0,
        'description': 'Je peux intervenir rapidement avec matériel professionnel',
        'avatar': 'https://via.placeholder.com/50',
      },
      {
        'artisanId': 'artisan2',
        'artisanName': 'Karim Tazi',
        'artisanRating': 4.5,
        'artisanReviews': 15,
        'price': 750.0,
        'description': 'Expérience 10 ans, disponible demain',
        'avatar': 'https://via.placeholder.com/50',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la demande'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/my-requests'),
        ),
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadRequest,
            tooltip: 'Rafraîchir',
          ),
          if (_request?.status == 'pending')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editRequest(),
              tooltip: 'Modifier',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _request == null
              ? const Center(child: Text('Demande non trouvée'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statut
                      _buildStatusSection(),
                      const SizedBox(height: 20),

                      // Informations de base
                      _buildBasicInfoSection(),
                      const SizedBox(height: 20),

                      // Photos
                      if (_request!.photos.isNotEmpty) ...[
                        _buildPhotosSection(),
                        const SizedBox(height: 20),
                      ],

                      // Devis reçus (si pending)
                      if (_request!.status == 'pending') ...[
                        _buildQuotesSection(),
                        const SizedBox(height: 20),
                      ],

                      // Artisan assigné (si accepted)
                      if (_request!.status == 'accepted' || _request!.status == 'in_progress') ...[
                        _buildAssignedArtisanSection(),
                        const SizedBox(height: 20),
                      ],

                      // Historique et timeline
                      _buildTimelineSection(),
                      const SizedBox(height: 20),

                      // Actions selon le statut
                      _buildActionsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(_request!.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(_request!.status)),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(_request!.status),
            color: _getStatusColor(_request!.status),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statut: ${_request!.statusFormatted}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(_request!.status),
                ),
              ),
              Text(
                'Demande #${_request!.id?.substring(0, 8)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations de base',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Catégorie', _request!.category, Icons.category),
            _buildInfoRow('Description', _request!.description, Icons.description),
            _buildInfoRow('Budget estimé', '${_request!.estimatedBudget.toStringAsFixed(2)} DH', Icons.euro),
            _buildInfoRow('Adresse', _request!.address, Icons.location_on),
            _buildInfoRow('Date souhaitée', _formatDate(_request!.preferredDate), Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Photos de la demande',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _request!.photos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showImageDialog(_request!.photos[index]),
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          _request!.photos[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                        ),
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

  Widget _buildQuotesSection() {
    final quotes = _getMockQuotes();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Devis reçus',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${quotes.length} devis',
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
            ...quotes.map((quote) => _buildQuoteCard(quote)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(Map<String, dynamic> quote) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(quote['avatar']),
                radius: 25,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote['artisanName'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        Text('${quote['artisanRating']}'),
                        Text(' (${quote['artisanReviews']} avis)'),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${quote['price'].toStringAsFixed(2)} DH',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(quote['description']),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _viewArtisanProfile(quote['artisanId']),
                child: const Text('Voir profil'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _acceptQuote(quote),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accepter le devis'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedArtisanSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Artisan assigné',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: NetworkImage('https://via.placeholder.com/50'),
                  radius: 30,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mohamed Benali',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Électricien professionnel • 4.8 ⭐',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _contactArtisan('message'),
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _contactArtisan('call'),
                    icon: const Icon(Icons.phone),
                    label: const Text('Appeler'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date d\'intervention',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_formatDate(_request!.preferredDate)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique et statut',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTimelineItem(
              'Création',
              _formatDate(_request!.createdAt),
              Icons.add_circle,
              Colors.green,
              true,
            ),
            if (_request!.status != 'pending')
              _buildTimelineItem(
                'Devis reçus',
                '2 artisans ont proposé',
                Icons.request_quote,
                Colors.blue,
                true,
              ),
            if (_request!.status == 'accepted' || _request!.status == 'in_progress' || _request!.status == 'completed')
              _buildTimelineItem(
                'Devis accepté',
                'Mohamed Benali sélectionné',
                Icons.check_circle,
                Colors.green,
                true,
              ),
            if (_request!.status == 'in_progress' || _request!.status == 'completed')
              _buildTimelineItem(
                'En cours',
                'Intervention en cours',
                Icons.build,
                Colors.orange,
                _request!.status == 'in_progress',
              ),
            if (_request!.status == 'completed')
              _buildTimelineItem(
                'Terminé',
                'Service complété',
                Icons.done_all,
                Colors.purple,
                true,
              ),
            const SizedBox(height: 8),
            Text(
              'Dernière mise à jour: ${_formatDate(_request!.updatedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, IconData icon, Color color, bool completed) {
    return Row(
      children: [
        Icon(
          completed ? icon : Icons.radio_button_unchecked,
          color: completed ? color : Colors.grey,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: completed ? color : Colors.grey,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    switch (_request!.status) {
      case 'pending':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actions possibles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editRequest(),
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelRequest(),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Annuler'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      
      case 'accepted':
      case 'in_progress':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actions possibles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _contactArtisan('message'),
                        icon: const Icon(Icons.message),
                        label: const Text('Contacter l\'artisan'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_request!.status == 'in_progress')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _markAsCompleted(),
                          icon: const Icon(Icons.check),
                          label: const Text('Marquer terminé'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      
      case 'completed':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actions possibles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rateArtisan(),
                        icon: const Icon(Icons.star),
                        label: const Text('Noter l\'artisan'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _createSimilarRequest(),
                        icon: const Icon(Icons.add),
                        label: const Text('Demander à nouveau'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _payForService(),
                    icon: const Icon(Icons.payment),
                    label: const Text('Payer le service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Stack(
            children: [
              Center(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 100),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editRequest() {
    context.go('/client/create-request?edit=${_request!.id}');
  }

  void _cancelRequest() {
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
                await requestProvider.updateRequest(_request!.id!, {'status': 'cancelled'});
                await _loadRequest();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demande annulée')),
                  );
                }
              } catch (e) {
                if (mounted) {
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

  void _viewArtisanProfile(String artisanId) {
    context.go('/client/artisan/$artisanId');
  }

  void _acceptQuote(Map<String, dynamic> quote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter le devis'),
        content: Text(
          'Voulez-vous accepter le devis de ${quote['artisanName']} pour ${quote['price'].toStringAsFixed(2)} DH ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final requestProvider = Provider.of<RequestProvider>(context, listen: false);
                await requestProvider.updateRequest(_request!.id!, {
                  'status': 'accepted',
                  'assignedArtisanId': quote['artisanId'],
                  'assignedArtisanName': quote['artisanName'],
                  'acceptedPrice': quote['price'],
                });
                await _loadRequest();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Devis accepté avec succès!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
  }

  void _contactArtisan(String method) {
    if (method == 'message') {
      context.go('/chat/artisan123');
    } else if (method == 'call') {
      // Implémenter l'appel téléphonique
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fonction d\'appel bientôt disponible')),
      );
    }
  }

  void _markAsCompleted() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marquer comme terminé'),
        content: const Text(
          'Confirmez-vous que le service a été complété avec succès ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final requestProvider = Provider.of<RequestProvider>(context, listen: false);
                await requestProvider.updateRequest(_request!.id!, {'status': 'completed'});
                await _loadRequest();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service marqué comme terminé!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _rateArtisan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Noter l\'artisan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comment évaluez-vous le service de Mohamed Benali ?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.star,
                    color: index < 4 ? Colors.amber : Colors.grey,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Laissez un commentaire...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Merci pour votre avis!')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _createSimilarRequest() {
    context.go('/client/create-request?similar=${_request!.id}');
  }

  void _payForService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payer le service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Montant à payer: ${_request!.estimatedBudget.toStringAsFixed(2)} DH'),
            const SizedBox(height: 16),
            const Text(
              'Choisissez votre méthode de paiement:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Carte bancaire'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paiement par carte bientôt disponible')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Espèces'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paiement en espèces confirmé')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}
