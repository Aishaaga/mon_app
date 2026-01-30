import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/request_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  // Controllers
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Variables
  String _selectedCategory = '';
  DateTime? _selectedDate;
  List<String> _photos = [];
  bool _isLoading = false;

  // Catégories disponibles
  final List<String> _categories = [
    'Plomberie',
    'Électricité',
    'Menuiserie',
    'Peinture',
    'Jardinage',
    'Nettoyage',
    'Climatisation',
    'Serrurerie',
    'Informatique',
    'Autre',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _budgetController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _photos.addAll(images.map((image) => image.path).toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection des images: $e')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date souhaitée')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final requestProvider = Provider.of<RequestProvider>(context, listen: false);
      
      final requestId = await requestProvider.createRequest(
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        photos: _photos, // Pour l'instant, on stocke les chemins locaux
        preferredDate: Timestamp.fromDate(_selectedDate!),
        estimatedBudget: double.tryParse(_budgetController.text) ?? 0.0,
        address: _addressController.text.trim(),
      );

      if (requestId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande créée avec succès!')),
        );
        
        // Naviguer vers my_requests après création
        if (mounted) {
          context.go('/client/my-requests');
        }
      } else {
        throw Exception('Échec de la création de la demande');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Demande'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Sélection catégorie
              const Text(
                'Catégorie de service',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Sélectionnez une catégorie',
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
              ),
              const SizedBox(height: 20),

              // 2. Description détaillée
              const Text(
                'Description détaillée',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Décrivez votre besoin en détail...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez décrire votre demande';
                  }
                  if (value.trim().length < 10) {
                    return 'La description doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 3. Upload photos
              const Text(
                'Photos (optionnel)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Ajouter des photos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              if (_photos.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              _photos[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),

              // 4. Date souhaitée
              const Text(
                'Date souhaitée',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Sélectionner une date',
                        style: TextStyle(
                          color: _selectedDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 5. Budget estimé
              const Text(
                'Budget estimé (DH)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '0.00',
                  prefixText: 'DH ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez indiquer un budget';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un montant valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 6. Adresse
              const Text(
                'Adresse',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Adresse complète du service',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez indiquer une adresse';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Bouton de soumission
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'PUBLIER LA DEMANDE',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
