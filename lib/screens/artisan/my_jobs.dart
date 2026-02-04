import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/job_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/dashboard_card.dart';
import '../../models/job.dart';

class MyJobsWrapper extends StatelessWidget {
  const MyJobsWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JobProvider(),
      child: const MyJobsScreen(),
    );
  }
}

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  String _selectedStatus = 'all';
  String _sortBy = 'recent';
  List<Job> _localJobs = []; // Stockage local des jobs

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
      final firestore = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;
      
      if (auth.currentUser == null) {
        return;
      }

      // Récupérer les jobs de l'artisan depuis Firestore (sans tri pour éviter l'index)
      final snapshot = await firestore
          .collection('jobs')
          .where('artisanId', isEqualTo: auth.currentUser!.uid)
          .get();

      // Convertir en objets Job et trier localement
      final jobs = snapshot.docs
          .map((doc) => Job.fromMap(doc.data(), doc.id))
          .toList();

      // Trier localement par date de création (plus récent d'abord)
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Mettre à jour le provider si disponible
      try {
        final jobProvider = Provider.of<JobProvider>(context, listen: false);
        jobProvider.clearAllJobs();
        for (final job in jobs) {
          jobProvider.addTestJob(job);
        }
      } catch (e) {
        // Stocker localement si le provider n'est pas disponible
        _localJobs = jobs;
      }
      
      // Forcer la mise à jour de l'interface
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Erreur silencieuse
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir les jobs depuis le provider ou localement
    List<Job> jobs;
    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      jobs = jobProvider.myJobs;
    } catch (e) {
      jobs = _localJobs;
    }

    // Filtrer les jobs
    final myJobs = _filterJobs(jobs);

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
        child: Builder(
          builder: (context) {
            print('🏗️ Builder rebuild avec ${myJobs.length} jobs');

            if (myJobs.isEmpty) {
              print('❌ Aucun job à afficher');
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
                      'Aucune intervention trouvée',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Commencez par envoyer des devis aux demandes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/artisan/available-requests'),
                      icon: const Icon(Icons.search),
                      label: const Text('Trouver des demandes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _createTestData,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Créer données de test'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearTestData,
                            icon: const Icon(Icons.clear),
                            label: const Text('Effacer données'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            print('✅ Affichage de ${myJobs.length} jobs');
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
                      print('🎯 Construction carte job: ${job.category} - ${job.status}');
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

List<Job> _filterJobs(List<Job> jobs) {
  // Filtrer les jobs par statut
  var filtered = jobs;

  if (_selectedStatus != 'all') {
    filtered = jobs.where((job) => job.status == _selectedStatus).toList();
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

  Widget _buildStatsHeader(List<Job> jobs) {
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
              totalEarnings += job.earnings;
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

  Widget _buildJobCard(Job job) {
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
                        if (job.id == null || job.id!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Erreur: ID du job invalide')),
                          );
                          return;
                        }
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

  void _startJob(Job job) async {
    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      await jobProvider.startJob(job.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Intervention commencée!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _completeJob(Job job) async {
    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      await jobProvider.completeJob(job.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Intervention terminée!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
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

  // Fonction pour effacer les données de test
  void _clearTestData() async {
    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      
      // Effacer tous les jobs locaux (uniquement les données de test)
      jobProvider.clearAllJobs();
      
      // Recharger depuis Firestore
      await jobProvider.loadMyJobs();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données de test effacées! Rechargement depuis Firestore...'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  // Fonction pour créer des données de test
  void _createTestData() async {
    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      
      // Créer des jobs de test avec différents statuts
      final testJobs = [
        Job(
          id: 'test-accepted-1',
          requestId: 'request-1',
          artisanId: FirebaseAuth.instance.currentUser?.uid ?? 'test-artisan',
          clientId: 'client-test-1',
          category: 'Plomberie',
          description: 'Réparation fuite d\'eau dans la cuisine. Le robinet fuit et il faut changer les joints.',
          photos: [],
          estimatedBudget: 1500.0,
          address: '123 Rue Test, Casablanca',
          status: 'accepted',
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
          quotePrice: 1500.0,
          quoteDescription: 'Réparation complète du robinet et changement des joints',
          quoteDuration: 2,
          quoteMaterials: ['Joints', 'Robinet', 'Outils'],
          quoteNotes: 'Matériel inclus dans le prix',
        ),
        Job(
          id: 'test-in-progress-1',
          requestId: 'request-2',
          artisanId: FirebaseAuth.instance.currentUser?.uid ?? 'test-artisan',
          clientId: 'client-test-2',
          category: 'Électricité',
          description: 'Installation de nouveaux points lumineux dans le salon. Prévoir 3 ampoules LED.',
          photos: [],
          estimatedBudget: 2000.0,
          address: '456 Avenue Test, Rabat',
          status: 'in_progress',
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
          startedAt: Timestamp.now(),
          quotePrice: 2000.0,
          quoteDescription: 'Installation de 3 points lumineux avec ampoules LED',
          quoteDuration: 3,
          quoteMaterials: ['Ampoules LED', 'Câbles', 'Interrupteurs'],
          quoteNotes: 'Garantie 2 ans sur les installations',
        ),
        Job(
          id: 'test-completed-1',
          requestId: 'request-3',
          artisanId: FirebaseAuth.instance.currentUser?.uid ?? 'test-artisan',
          clientId: 'client-test-3',
          category: 'Peinture',
          description: 'Peinture complète des murs du salon et des chambres. Couleur blanche.',
          photos: [],
          estimatedBudget: 3500.0,
          address: '789 Boulevard Test, Marrakech',
          status: 'completed',
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
          startedAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
          completedAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          quotePrice: 3500.0,
          quoteDescription: 'Peinture complète salon + 2 chambres',
          quoteDuration: 5,
          quoteMaterials: ['Peinture blanche', 'Pinceaux', 'Rouleaux'],
          quoteNotes: 'Travail garanti 1 an',
        ),
      ];

      // Ajouter les jobs de test au provider
      for (final job in testJobs) {
        jobProvider.addTestJob(job);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données de test créées avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}
