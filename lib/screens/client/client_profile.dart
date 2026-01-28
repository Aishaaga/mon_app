import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Profil client'),
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
