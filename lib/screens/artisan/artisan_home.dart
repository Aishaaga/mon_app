import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ArtisanHome extends StatelessWidget {
  const ArtisanHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord Artisan')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/artisan/available-requests'),
              child: const Text('Demandes disponibles'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/artisan/my-jobs'),
              child: const Text('Mes interventions'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/artisan/profile'),
              child: const Text('Mon profil'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/artisan/earnings'),
              child: const Text('Mes revenus'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Déconnexion'),
            ),
          ],
        ),
      ),
    );
  }
}
