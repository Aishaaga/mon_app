import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/home'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Profil client'),
            ElevatedButton(
              onPressed: () async {
                // 1. Déconnecter
                await FirebaseAuth.instance.signOut();

                // 2. Forcer la navigation vers login
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: const Text('Déconnexion'),
            ),
          ],
        ),
      ),
    );
  }
}
