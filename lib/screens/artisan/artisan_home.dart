import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/request_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/user_info_card.dart';
import '../../models/user.dart';

class ArtisanHome extends StatefulWidget {
  const ArtisanHome({super.key});

  @override
  State<ArtisanHome> createState() => _ArtisanHomeState();
}

class _ArtisanHomeState extends State<ArtisanHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tableau de bord Artisan',
        showBackButton: false,
        backgroundColor: Colors.green,
        leading: const SizedBox(), // Force un leading vide au lieu de null
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications bientôt disponibles')),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                context.go('/artisan/profile');
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Mon profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Déconnexion', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final jobProvider = Provider.of<JobProvider>(context, listen: false);
          final requestProvider = Provider.of<RequestProvider>(context, listen: false);
          await Future.wait([
            jobProvider.loadMyJobs(),
            requestProvider.loadRequests(),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section utilisateur
              Consumer<app_auth.AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.userData == null) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text('Chargement du profil...'),
                          ],
                        ),
                      ),
                    );
                  }

                  // Créer un AppUser temporaire depuis les données
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

                  return UserInfoCard(user: user);
                },
              ),

              const SizedBox(height: 24),

              // Statistiques
              Consumer2<RequestProvider, JobProvider>(
                builder: (context, requestProvider, jobProvider, child) {
                  // Charger les données si nécessaire
                  if (jobProvider.myJobs.isEmpty) {
                    jobProvider.loadMyJobs();
                  }
                  if (requestProvider.availableRequests.isEmpty) {
                    requestProvider.loadRequests();
                  }
                  
                  final availableRequests = requestProvider.availableRequests;
                  final myJobs = jobProvider.myJobs;
                  final activeJobs = myJobs.where((job) => 
                    job.status == 'accepted' || job.status == 'in_progress'
                  ).length;
                  final completedJobs = myJobs.where((job) => 
                    job.status == 'completed'
                  ).length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes statistiques',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              title: 'Demandes disponibles',
                              value: availableRequests.length.toString(),
                              icon: Icons.assignment,
                              color: Colors.orange,
                              subtitle: availableRequests.length > 0 ? 'Nouvelles opportunités' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: 'Mes interventions',
                              value: activeJobs.toString(),
                              icon: Icons.build,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              title: 'Terminées',
                              value: completedJobs.toString(),
                              icon: Icons.check_circle,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: 'Taux de réponse',
                              value: '92%',
                              icon: Icons.trending_up,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Actions rapides
              Text(
                'Actions rapides',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              DashboardCard(
                title: 'Demandes disponibles',
                subtitle: 'Voir les nouvelles demandes de service',
                icon: Icons.assignment,
                iconColor: Colors.orange,
                onTap: () => context.go('/artisan/available-requests'),
              ),

              DashboardCard(
                title: 'Mes interventions',
                subtitle: 'Gérer mes travaux en cours',
                icon: Icons.build,
                iconColor: Colors.green,
                onTap: () => context.go('/artisan/my-jobs'),
              ),

              DashboardCard(
                title: 'Messages',
                subtitle: 'Communiquer avec les clients',
                icon: Icons.message,
                iconColor: Colors.purple,
                onTap: () => context.go('/artisan/messages'),
              ),

              DashboardCard(
                title: 'Mes revenus',
                subtitle: 'Suivre mes gains et paiements',
                icon: Icons.euro,
                iconColor: Colors.blue,
                onTap: () => context.go('/artisan/earnings'),
              ),

              const SizedBox(height: 24),

              // Section performance
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Performance cette semaine',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Excellente performance! Vous avez répondu à 8 demandes cette semaine.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: 0.8,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '80% d\'objectif atteint',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Section d'aide
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Besoin d\'aide ?',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Notre équipe support est disponible pour vous aider avec toutes vos questions.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Support bientôt disponible')),
                                );
                              },
                              icon: const Icon(Icons.support_agent),
                              label: const Text('Contacter le support'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('FAQ bientôt disponible')),
                                );
                              },
                              icon: const Icon(Icons.question_answer),
                              label: const Text('FAQ'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de déconnexion: $e')),
        );
      }
    }
  }
}
