import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchArtisansScreen extends StatelessWidget {
  const SearchArtisansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche artisans'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/home'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Liste des artisans'),
            ElevatedButton(
              onPressed: () => context.go('/client/artisan/789'),
              child: const Text('Voir profil artisan 789'),
            ),
          ],
        ),
      ),
    );
  }
}
