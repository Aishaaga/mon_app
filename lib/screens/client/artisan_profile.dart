import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';

class ClientArtisanProfileScreen extends StatefulWidget {
  final String artisanId;

  const ClientArtisanProfileScreen({super.key, required this.artisanId});

  @override
  State<ClientArtisanProfileScreen> createState() => _ClientArtisanProfileScreenState();
}

class _ClientArtisanProfileScreenState extends State<ClientArtisanProfileScreen> {
  AppUser? _artisan;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  int _completedJobs = 0;

  @override
  void initState() {
    super.initState();
    _loadArtisanProfile();
  }

  Future<void> _loadArtisanProfile() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Charger les informations de l'artisan
      final artisanDoc = await firestore.collection('users').doc(widget.artisanId).get();
      
      if (artisanDoc.exists) {
        final artisanData = artisanDoc.data();
        
        if (artisanData != null) {
          // Les données utilisent firstName et lastName séparés
          String firstName = artisanData['firstName']?.toString() ?? '';
          String lastName = artisanData['lastName']?.toString() ?? '';
          
          _artisan = AppUser(
            id: artisanDoc.id,
            firstName: firstName,
            lastName: lastName,
            email: artisanData['email'] ?? '',
            phone: artisanData['phone'] ?? '',
            address: artisanData['address'] ?? '',
            userType: artisanData['userType'] ?? 'artisan',
            createdAt: artisanData['createdAt']?.toDate() ?? DateTime.now(),
            updatedAt: artisanData['updatedAt']?.toDate(),
            profileImageUrl: artisanData['profileImage'], // Note: profileImage pas profileImageUrl
          );
        }
      }
      
      // Charger les jobs complétés de l'artisan
      // TODO: Corriger les permissions Firestore pour la collection jobs
      /*final jobsSnapshot = await firestore
          .collection('jobs')
          .where('artisanId', isEqualTo: widget.artisanId)
          .where('status', isEqualTo: 'completed')
          .get();
      
      _completedJobs = jobsSnapshot.docs.length;*/
      
      // Pour l'instant, utiliser une valeur simulée
      _completedJobs = 12;
      
      // Charger les avis (simulés pour l'instant)
      _reviews = [
        {
          'clientName': 'Mohamed Ali',
          'rating': 5.0,
          'comment': 'Excellent travail, très professionnel',
          'date': DateTime.now().subtract(const Duration(days: 30)),
        },
        {
          'clientName': 'Fatima Zahra',
          'rating': 4.5,
          'comment': 'Bon travail, ponctuel et sérieux',
          'date': DateTime.now().subtract(const Duration(days: 60)),
        },
      ];
      
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_artisan?.fullName ?? 'Profil artisan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/search-artisans'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => _toggleFavorite(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _artisan == null
              ? const Center(child: Text('Artisan non trouvé'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header avec photo et infos de base
                      _buildHeaderSection(),
                      const SizedBox(height: 24),

                      // Statistiques
                      _buildStatsSection(),
                      const SizedBox(height: 24),

                      // Description
                      _buildDescriptionSection(),
                      const SizedBox(height: 24),

                      // Compétences
                      _buildSkillsSection(),
                      const SizedBox(height: 24),

                      // Avis des clients
                      _buildReviewsSection(),
                      const SizedBox(height: 24),

                      // Actions
                      _buildActionsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _artisan!.profileImageUrl != null
                  ? NetworkImage(_artisan!.profileImageUrl!)
                  : null,
              backgroundColor: Colors.green[100],
              child: _artisan!.profileImageUrl == null
                  ? Text(
                      '${_artisan!.firstName.isNotEmpty ? _artisan!.firstName[0] : ''}${_artisan!.lastName.isNotEmpty ? _artisan!.lastName[0] : ''}'.toUpperCase(),
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _artisan!.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '4.8',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(' (${_reviews.length} avis)'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_artisan!.address.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _artisan!.address,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '$_completedJobs',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text('Interventions'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '2 ans',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Text('Expérience'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '95%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Text('Satisfaction'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'À propos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Artisan professionnel avec plusieurs années d\'expérience dans le domaine. Je m\'engage à fournir un travail de qualité avec des matériaux durables. Ponctuel et sérieux, je saurai répondre à vos attentes.',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    final skills = ['Électricité', 'Plomberie', 'Climatisation', 'Sécurité'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compétences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) => Chip(
                label: Text(skill),
                backgroundColor: Colors.green[100],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Avis des clients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._reviews.map((review) => _buildReviewCard(review)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review['clientName'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  ...List.generate(5, (index) => Icon(
                    index < review['rating'].floor()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review['comment']),
          const SizedBox(height: 4),
          Text(
            '${review['date'].day}/${review['date'].month}/${review['date'].year}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _contactArtisan(),
            icon: const Icon(Icons.message),
            label: const Text('Contacter l\'artisan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _contactArtisan(),
            icon: const Icon(Icons.message),
            label: const Text('Contacter l\'artisan'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleFavorite() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajouté aux favoris')),
    );
  }

  void _contactArtisan() {
    context.go('/chat/${widget.artisanId}');
  }

  void _callArtisan() {
    if (_artisan?.phone.isNotEmpty == true) {
      // Implémenter l'appel téléphonique
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appel: ${_artisan!.phone}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non disponible')),
      );
    }
  }
}
