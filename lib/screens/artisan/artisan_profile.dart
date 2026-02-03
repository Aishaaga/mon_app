import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/custom_app_bar.dart';
import '../../widgets/user_info_card.dart';
import '../../models/user.dart';

class ArtisanProfileScreen extends StatefulWidget {
  const ArtisanProfileScreen({super.key});

  @override
  State<ArtisanProfileScreen> createState() => _ArtisanProfileScreenState();
}

class _ArtisanProfileScreenState extends State<ArtisanProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _experienceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedCategory = 'Électricien';
  List<String> _skills = ['Installation', 'Dépannage', 'Maintenance'];
  List<String> _certifications = ['Certification Électrique A', 'Permis de travail'];
  double _hourlyRate = 150.0;

  final List<String> _categories = [
    'Électricien',
    'Plombier',
    'Menuisier',
    'Peintre',
    'Maçon',
    'Couvreur',
    'Climaticien',
    'Jardinier',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    // Charger les données depuis AuthProvider
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    if (authProvider.userData != null) {
      final userData = authProvider.userData!;
      _phoneController.text = userData['phone'] ?? '';
      _addressController.text = userData['address'] ?? '';
      _descriptionController.text = userData['description'] ?? 'Artisan professionnel avec plus de 5 ans d\'expérience';
      _experienceController.text = userData['experience'] ?? '5 ans';
      _selectedCategory = userData['category'] ?? 'Électricien';
      _hourlyRate = (userData['hourlyRate'] as num?)?.toDouble() ?? 150.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profil professionnel',
        showBackButton: true,
        onBackPressed: () => context.go('/artisan/home'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: _isEditing ? 'Sauvegarder' : 'Modifier',
          ),
        ],
      ),
      body: Consumer<app_auth.AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = authProvider.userData!;
          final user = AppUser(
            id: FirebaseAuth.instance.currentUser?.uid ?? '',
            firstName: userData['fullName']?.split(' ').first ?? '',
            lastName: userData['fullName']?.split(' ').last ?? '',
            email: userData['email'] ?? '',
            phone: userData['phone'] ?? '',
            address: userData['address'] ?? '',
            userType: userData['userType'] ?? 'artisan',
            createdAt: userData['createdAt']?.toDate() ?? DateTime.now(),
            updatedAt: userData['updatedAt']?.toDate(),
            profileImageUrl: userData['profileImageUrl'],
          );

          return RefreshIndicator(
            onRefresh: () async {
              // Recharger les données du profil
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carte profil utilisateur
                    UserInfoCard(user: user),
                    const SizedBox(height: 24),

                    // Informations professionnelles
                    _buildProfessionalInfo(),
                    const SizedBox(height: 24),

                    // Compétences et certifications
                    _buildSkillsAndCertifications(),
                    const SizedBox(height: 24),

                    // Tarifs et disponibilité
                    _buildPricingAndAvailability(),
                    const SizedBox(height: 24),

                    // Statistiques et performance
                    _buildStatistics(),
                    const SizedBox(height: 24),

                    // Actions rapides
                    _buildQuickActions(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ), // ✅ ICI : Ferme le Consumer
    );
  }

  Widget _buildProfessionalInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Informations professionnelles',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Catégorie
            if (_isEditing)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Spécialité',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              )
            else
              _buildInfoRow('Spécialité', _selectedCategory, Icons.category),

            const SizedBox(height: 12),

            // Description
            if (_isEditing)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description professionnelle',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              )
            else
              _buildInfoRow('Description', _descriptionController.text, Icons.description),

            const SizedBox(height: 12),

            // Expérience
            if (_isEditing)
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Années d\'expérience',
                  border: OutlineInputBorder(),
                ),
              )
            else
              _buildInfoRow('Expérience', _experienceController.text, Icons.timeline),

            const SizedBox(height: 12),

            // Contact
            if (_isEditing)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone professionnel',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              )
            else
              _buildInfoRow('Téléphone', _phoneController.text, Icons.phone),

            const SizedBox(height: 12),

            // Adresse
            if (_isEditing)
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Zone d\'intervention',
                  border: OutlineInputBorder(),
                ),
              )
            else
              _buildInfoRow('Zone d\'intervention', _addressController.text, Icons.location_on),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsAndCertifications() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Compétences et certifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: _addSkill,
                      tooltip: 'Ajouter une compétence',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Compétences
            Text(
              'Compétences principales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  backgroundColor: Colors.green.withOpacity(0.1),
                  deleteIcon: _isEditing ? const Icon(Icons.close, size: 16) : null,
                  onDeleted: _isEditing ? () => _removeSkill(skill) : null,
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Certifications
            Text(
              'Certifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _certifications.map((certification) {
                return Chip(
                  label: Text(certification),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  deleteIcon: _isEditing ? const Icon(Icons.close, size: 16) : null,
                  onDeleted: _isEditing ? () => _removeCertification(certification) : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingAndAvailability() {
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
                  'Tarifs et disponibilité',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tarif horaire
            if (_isEditing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarif horaire: ${_hourlyRate.toStringAsFixed(2)} DH',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: _hourlyRate,
                    min: 50,
                    max: 500,
                    divisions: 45,
                    label: '${_hourlyRate.toStringAsFixed(2)} DH/h',
                    onChanged: (value) {
                      setState(() {
                        _hourlyRate = value;
                      });
                    },
                  ),
                ],
              )
            else
              _buildInfoRow('Tarif horaire', '${_hourlyRate.toStringAsFixed(2)} DH', Icons.euro),

            const SizedBox(height: 12),

            // Disponibilité
            _buildInfoRow('Disponibilité', 'Immédiate', Icons.schedule),
            const SizedBox(height: 12),
            _buildInfoRow('Zone de service', 'Casablanca et environs', Icons.map),

            const SizedBox(height: 16),

            // Options de paiement
            Text(
              'Moyens de paiement acceptés',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('Espèces')),
                Chip(label: Text('Carte bancaire')),
                Chip(label: Text('Virement')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Statistiques de performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Interventions', '127', Icons.build, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Clients satisfaits', '118', Icons.people, Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Note moyenne', '4.8', Icons.star, Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Taux de réponse', '95%', Icons.message, Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/artisan/earnings'),
                    icon: const Icon(Icons.euro),
                    label: const Text('Mes revenus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Portfolio bientôt disponible')),
                      );
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Portfolio'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Partage de profil bientôt disponible')),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Partager mon profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                const SizedBox(height: 2),
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

  void _toggleEditMode() {
    if (_isEditing) {
      // Sauvegarder les modifications
      if (_formKey.currentState!.validate()) {
        _saveProfile();
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès!')),
        );
      }
    } else {
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _saveProfile() {
    // Implémenter la sauvegarde dans Firestore
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    // TODO: Sauvegarder les données mises à jour
  }

  void _addSkill() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une compétence'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Nom de la compétence',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Ajouter la compétence
              Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _removeCertification(String certification) {
    setState(() {
      _certifications.remove(certification);
    });
  }
}
