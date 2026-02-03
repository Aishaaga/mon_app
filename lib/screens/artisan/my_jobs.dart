import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/request_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/dashboard_card.dart';
import '../../models/request.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  String _selectedStatus = 'all';
  String _sortBy = 'recent';

  final List<String> _statusOptions = [
    'all',
    'accepted',
    'in_progress',
    'completed',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyJobs();
    });
  }

  Future<void> _loadMyJobs() async {
    try {
      // Charger toutes les demandes pour voir celles acceptées par l'artisan
      await Provider.of<RequestProvider>(context, listen: false).loadAllRequests();
    } catch (e) {
      print('Erreur chargement interventions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mes interventions',
        showBackButton: true,
        onBackPressed: () => context.go('/artisan/home'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrer',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadMyJobs();
        },
        child: Consumer<RequestProvider>(
          builder: (context, requestProvider, child) {
            if (requestProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filtrer les demandes acceptées par l'artisan (simulation)
            final myJobs = _filterJobs(requestProvider.requests);

            if (myJobs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune intervention',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Envoyez des devis pour commencer à travailler',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/artisan/available-requests'),
                      icon: const Icon(Icons.search),
                      label: const Text('Trouver des demandes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Statistiques
                _buildStatsHeader(myJobs),
                
                // Liste des interventions
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: myJobs.length,
                    itemBuilder: (context, index) {
                      final job = myJobs[index];
                      return _buildJobCard(job);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

List<Request> _filterJobs(List<Request> requests) {
  // Simulation: filtrer les demandes qui ont été acceptées par l'artisan
  // En réalité, cela viendrait d'une collection "quotes" ou "jobs" avec artisanId
  final currentUser = FirebaseAuth.instance.currentUser;
  
  var filtered = requests.where((r) => 
    (r.status == 'accepted' || r.status == 'in_progress' || r.status == 'completed') &&
    // Simulation: considérer que les demandes acceptées ont un artisanId
    // Vérifier d'abord si r.id n'est pas null avant d'appeler contains
    ((r.id?.contains('artisan') ?? false) || r.status != 'pending') // Logique de simulation
  ).toList();

  if (_selectedStatus != 'all') {
    filtered = filtered.where((r) => r.status == _selectedStatus).toList();
  }

  // Tri
  switch (_sortBy) {
    case 'recent':
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case 'budget_high':
      filtered.sort((a, b) => b.estimatedBudget.compareTo(a.estimatedBudget));
      break;
    case 'budget_low':
      filtered.sort((a, b) => a.estimatedBudget.compareTo(b.estimatedBudget));
      break;
  }

  return filtered;
}

  Widget _buildStatsHeader(List<Request> jobs) {
        int accepted = 0;
        int inProgress = 0;
        int completed = 0;
        double totalEarnings = 0.0;

        for (var job in jobs) {
          switch (job.status) {
            case 'accepted':
              accepted++;
              break;
            case 'in_progress':
              inProgress++;
              break;
            case 'completed':
              completed++;
              totalEarnings += job.estimatedBudget;
              break;
          }
        }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Text(
            'Mes statistiques',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Acceptées', accepted.toString(), Icons.assignment, Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem('En cours', inProgress.toString(), Icons.build, Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem('Terminées', completed.toString(), Icons.check_circle, Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.euro, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Gains totaux: ${totalEarnings.toInt()} DH',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          const SizedBox(height: 4),
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

  Widget _buildJobCard(Request job) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (job.status) {
      case 'accepted':
        statusColor = Colors.orange;
        statusText = 'Accepté';
        statusIcon = Icons.assignment;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusText = 'En cours';
        statusIcon = Icons.build;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Terminé';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = job.statusFormatted;
        statusIcon = Icons.help;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          context.go('/artisan/job/${job.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.category,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                job.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Informations clés
              Row(
                children: [
                  Icon(Icons.euro, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '${job.estimatedBudget.toInt()} DH',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(job.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Actions selon statut
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.go('/artisan/job/${job.id}');
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Voir détails'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (job.status == 'accepted') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _startJob(job),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Commencer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                  if (job.status == 'in_progress') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _completeJob(job),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Terminer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer et trier'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Statut
                const Text('Statut'),
                DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('Toutes')),
                    const DropdownMenuItem(value: 'accepted', child: Text('Acceptées')),
                    const DropdownMenuItem(value: 'in_progress', child: Text('En cours')),
                    const DropdownMenuItem(value: 'completed', child: Text('Terminées')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Tri
                const Text('Trier par'),
                DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'recent', child: Text('Plus récent')),
                    DropdownMenuItem(value: 'budget_high', child: Text('Budget décroissant')),
                    DropdownMenuItem(value: 'budget_low', child: Text('Budget croissant')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _startJob(Request job) {
    // TODO: Mettre à jour le statut en "in_progress"
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Intervention commencée!')),
    );
  }

  void _completeJob(Request job) {
    // TODO: Mettre à jour le statut en "completed"
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Intervention terminée!')),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Aujourd'hui";
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
