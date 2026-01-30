//   onPressed: () => context.go('/client/home'),
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/user_info_card.dart';
import '../../models/user.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Firebase User
    final userData = authProvider.userData; // Données Firestore (Map)
    final firebaseUser = authProvider.currentUser; // Firebase User

    AppUser? appUser;
    if (firebaseUser != null && userData != null) {
      final fullName =
          userData['fullName'] ?? firebaseUser.displayName ?? 'Utilisateur';
      final nameParts = fullName.split(' ');

      appUser = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        firstName: nameParts.isNotEmpty ? nameParts[0] : '',
        lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        phone: userData['phone'] ?? '',
        address: userData['address'] ?? '',
        userType: userData['userType'] ?? 'client',
        profileImageUrl: userData['profileImageUrl'],
        createdAt: userData['createdAt'] != null
            ? (userData['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/home'),
        ),
      ),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text('Utilisateur non connecté'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Carte d'information utilisateur
                  UserInfoCard(user: appUser!),

                  const SizedBox(height: 20),

                  // Boutons d'action
                  ElevatedButton.icon(
                    onPressed: () {
                      // Naviguer vers l'écran d'édition
                      context.push('/client/edit-profile');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier le profil'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: () async {
                      await authProvider.logout();
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
