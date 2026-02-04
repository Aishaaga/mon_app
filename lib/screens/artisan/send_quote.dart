import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/request_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/request.dart';

class SendQuoteScreen extends StatefulWidget {
  final String requestId;

  const SendQuoteScreen({super.key, required this.requestId});

  @override
  State<SendQuoteScreen> createState() => _SendQuoteScreenState();
}

class _SendQuoteScreenState extends State<SendQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  double _estimatedPrice = 0.0;
  int _estimatedDuration = 1;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  List<String> _materials = [];
  final _materialController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Envoyer un devis',
        showBackButton: true,
        onBackPressed: () => context.go('/artisan/request/${widget.requestId}'),
        backgroundColor: Colors.green,
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
                  Text('Chargement de la demande...'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte résumé de la demande
                  _buildRequestSummary(request),
                  const SizedBox(height: 24),

                  // Formulaire devis
                  _buildQuoteForm(),
                  const SizedBox(height: 24),

                  // Matériaux nécessaires
                  _buildMaterialsSection(),
                  const SizedBox(height: 24),

                  // Planning
                  _buildPlanningSection(),
                  const SizedBox(height: 24),

                  // Notes additionnelles
                  _buildNotesSection(),
                  const SizedBox(height: 32),

                  // Bouton envoi
                  _buildSendButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestSummary(Request request) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé de la demande',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              request.category,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              request.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.euro, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Budget client: ${request.estimatedBudget.toInt()} DH',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.address,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre proposition',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Description du travail
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description du travail proposé',
                hintText: 'Décrivez en détail ce que vous allez faire...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez décrire votre proposition';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Prix estimé
            Text(
              'Prix estimé: ${_estimatedPrice.toInt()} DH',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _estimatedPrice,
              min: 0,
              max: 10000,
              divisions: 100,
              label: '${_estimatedPrice.toInt()} DH',
              onChanged: (value) {
                setState(() {
                  _estimatedPrice = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Durée estimée
            Text(
              'Durée estimée: $_estimatedDuration jour(s)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Slider(
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
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Matériaux nécessaires',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _materialController,
                    decoration: const InputDecoration(
                      labelText: 'Ajouter un matériel',
                      hintText: 'Ex: Peinture blanche 5L',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addMaterial,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _materials.map((material) {
                return Chip(
                  label: Text(material),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeMaterial(material),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planning proposé',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Date de début
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _startDate != null
                    ? 'Début: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                    : 'Sélectionner une date de début',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectStartDate,
            ),

            // Heure de début
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                _startTime != null
                    ? 'À: ${_startTime!.format(context)}'
                    : 'Sélectionner une heure de début',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectStartTime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes additionnelles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes pour le client',
                hintText: 'Informations complémentaires, garanties, etc...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSending ? null : _sendQuote,
        icon: _isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send),
        label: Text(_isSending ? 'Envoi en cours...' : 'Envoyer le devis'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _addMaterial() {
    if (_materialController.text.trim().isNotEmpty) {
      setState(() {
        _materials.add(_materialController.text.trim());
        _materialController.clear();
      });
    }
  }

  void _removeMaterial(String material) {
    setState(() {
      _materials.remove(material);
    });
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _sendQuote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_estimatedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez définir un prix')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final requestProvider = Provider.of<RequestProvider>(context, listen: false);
      final jobProvider = Provider.of<JobProvider>(context, listen: false);

      // Charger toutes les demandes pour trouver celle-ci
      await requestProvider.loadAllRequests();
      
      // Trouver la demande originale
      final request = requestProvider.requests
          .where((r) => r.id == widget.requestId)
          .firstOrNull;

      if (request == null) {
        print('❌ Demande non trouvée: ${widget.requestId}');
        print('❌ Demandes disponibles: ${requestProvider.requests.map((r) => r.id).toList()}');
        throw Exception('Demande non trouvée: ${widget.requestId}');
      }

      print('✅ Demande trouvée: ${request.category}');

      // Créer un Job dans la collection jobs
      final jobId = await jobProvider.createJob(
        requestId: request.id!,
        clientId: request.clientId,
        category: request.category,
        description: request.description,
        photos: request.photos!,
        estimatedBudget: request.estimatedBudget,
        address: request.address,
        quotePrice: _estimatedPrice,
        quoteDescription: _descriptionController.text,
        quoteDuration: _estimatedDuration,
        quoteMaterials: _materials,
        quoteNotes: _notesController.text,
      );

      if (jobId != null) {
        print('✅ Job créé avec ID: $jobId');

        // Mettre à jour le statut de la demande originale
        await requestProvider.updateRequest(widget.requestId, {
          'status': 'accepted',
          'artisanId': FirebaseAuth.instance.currentUser?.uid,
        });

        print('✅ Demande mise à jour vers accepted');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Devis envoyé avec succès! Le client a accepté votre proposition.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/artisan/my-jobs');
        }
      } else {
        throw Exception('Échec de création du job');
      }
    } catch (e) {
      print('❌ Erreur envoi devis: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}
