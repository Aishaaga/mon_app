import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/request_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/user_info_card.dart';
import '../../models/user.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tableau de bord',
        showBackButton: false,
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
                context.go('/client/profile');
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
          final requestProvider = Provider.of<RequestProvider>(context, listen: false);
          await requestProvider.loadRequests();
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
                  final firstName = userData['firstName']?.toString() ?? '';
                  final lastName = userData['lastName']?.toString() ?? '';
                  final fullName = '$firstName $lastName'.trim();
                  
                  print('DEBUG: userData = $userData');
                  print('DEBUG: firstName = "$firstName"');
                  print('DEBUG: lastName = "$lastName"');
                  print('DEBUG: fullName = "$fullName"');
                  
                  final user = AppUser(
                    id: FirebaseAuth.instance.currentUser?.uid ?? '',
                    firstName: firstName,
                    lastName: lastName,
                    email: userData['email'] ?? '',
                    phone: userData['phone'] ?? '',
                    address: userData['address'] ?? '',
                    userType: userData['userType'] ?? 'client',
                    createdAt: userData['createdAt']?.toDate() ?? DateTime.now(),
                    updatedAt: userData['updatedAt']?.toDate(),
                    profileImageUrl: userData['profileImage'],
                  );
                  
                  print('DEBUG: user.fullName = "${user.fullName}"');

                  return UserInfoCard(user: user);
                },
              ),

              const SizedBox(height: 24),

              // Statistiques
              Consumer<RequestProvider>(
                builder: (context, requestProvider, child) {
                  final clientRequests = requestProvider.clientRequests;
                  final pendingCount = clientRequests.where((r) => r.status == 'pending').length;
                  final inProgressCount = clientRequests.where((r) => r.status == 'in_progress').length;
                  final completedCount = clientRequests.where((r) => r.status == 'completed').length;

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
                              title: 'Total demandes',
                              value: clientRequests.length.toString(),
                              icon: Icons.assignment,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: 'En attente',
                              value: pendingCount.toString(),
                              icon: Icons.pending,
                              color: Colors.orange,
                              subtitle: pendingCount > 0 ? 'Nouveaux devis' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              title: 'En cours',
                              value: inProgressCount.toString(),
                              icon: Icons.build,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: 'Terminées',
                              value: completedCount.toString(),
                              icon: Icons.check_circle,
                              color: Colors.purple,
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
                title: 'Nouvelle demande',
                subtitle: 'Créer une demande de service',
                icon: Icons.add_circle,
                iconColor: Colors.green,
                onTap: () => context.go('/client/create-request'),
              ),

              DashboardCard(
                title: 'Mes demandes',
                subtitle: 'Voir et suivre mes demandes',
                icon: Icons.assignment,
                iconColor: Colors.blue,
                onTap: () => context.go('/client/my-requests'),
              ),

              DashboardCard(
                title: 'Messages',
                subtitle: 'Communiquer avec les artisans',
                icon: Icons.message,
                iconColor: Colors.purple,
                onTap: () => context.go('/client/messages'),
              ),

              DashboardCard(
                title: 'Rechercher artisans',
                subtitle: 'Trouver des professionnels',
                icon: Icons.search,
                iconColor: Colors.orange,
                onTap: () => context.go('/client/search-artisans'),
              ),

              const SizedBox(height: 24),

              // Section d'aide


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
