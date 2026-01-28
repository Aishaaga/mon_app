import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ArtisanProfileScreen extends StatelessWidget {
  const ArtisanProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil professionnel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Profil artisan'),
            ElevatedButton(
              onPressed: () => context.go('/artisan/earnings'),
              child: const Text('Voir mes revenus'),
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
