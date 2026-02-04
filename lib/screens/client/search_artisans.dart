import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart' as app_auth;
import '../../models/user.dart';

class SearchArtisansScreen extends StatefulWidget {
  const SearchArtisansScreen({super.key});

  @override
  State<SearchArtisansScreen> createState() => _SearchArtisansScreenState();
}

class _SearchArtisansScreenState extends State<SearchArtisansScreen> {
  List<AppUser> _artisans = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadArtisans();
  }

  Future<void> _loadArtisans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Charger tous les utilisateurs avec userType = 'artisan'
      final snapshot = await firestore
          .collection('users')
          .where('userType', isEqualTo: 'artisan')
          .get();
      
      final artisans = snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Gérer le cas où fullName est null
        String fullName = data['fullName']?.toString() ?? '';
        String firstName = '';
        String lastName = '';
        
        if (fullName.isNotEmpty) {
          final parts = fullName.split(' ');
          firstName = parts.isNotEmpty ? parts.first : '';
          lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        }
        
        return AppUser(
          id: doc.id,
          firstName: firstName,
          lastName: lastName,
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          address: data['address'] ?? '',
          userType: data['userType'] ?? 'artisan',
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          updatedAt: data['updatedAt']?.toDate(),
          profileImageUrl: data['profileImageUrl'],
        );
      }).toList();

      setState(() {
        _artisans = artisans;
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

  List<AppUser> get _filteredArtisans {
    if (_searchQuery.isEmpty) return _artisans;
    
    return _artisans.where((artisan) {
      final fullName = '${artisan.firstName} ${artisan.lastName}'.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return fullName.contains(query) ||
             artisan.email.toLowerCase().contains(query) ||
             artisan.address.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher un artisan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/home'),
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, email, adresse...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Liste des artisans
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredArtisans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun artisan disponible'
                                  : 'Aucun artisan trouvé pour "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredArtisans.length,
                        itemBuilder: (context, index) {
                          final artisan = _filteredArtisans[index];
                          return _ArtisanCard(
                            artisan: artisan,
                            onTap: () => context.go('/client/artisan/${artisan.id}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ArtisanCard extends StatelessWidget {
  final AppUser artisan;
  final VoidCallback onTap;

  const _ArtisanCard({
    required this.artisan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo de profil
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green[100],
                backgroundImage: artisan.profileImageUrl != null
                    ? NetworkImage(artisan.profileImageUrl!)
                    : null,
                child: artisan.profileImageUrl == null
                    ? Text(
                        artisan.firstName.isNotEmpty && artisan.lastName.isNotEmpty
                            ? '${artisan.firstName[0]}${artisan.lastName[0]}'.toUpperCase()
                            : artisan.email.isNotEmpty
                                ? artisan.email[0].toUpperCase()
                                : 'A',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${artisan.firstName.isNotEmpty ? artisan.firstName : ''} ${artisan.lastName.isNotEmpty ? artisan.lastName : ''}'.trim().isEmpty 
                          ? artisan.email 
                          : '${artisan.firstName} ${artisan.lastName}'.trim(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artisan.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (artisan.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        artisan.address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Icône
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
