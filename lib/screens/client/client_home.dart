import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientHome extends StatelessWidget {
  const ClientHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil Client')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/client/create-request'),
              child: const Text('Nouvelle demande'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/client/my-requests'),
              child: const Text('Mes demandes'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/client/search-artisans'),
              child: const Text('Rechercher artisans'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/client/profile'),
              child: const Text('Mon profil'),
            ),
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
