import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AvailableRequestsScreen extends StatelessWidget {
  const AvailableRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes disponibles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Liste des demandes'),
            ElevatedButton(
              onPressed: () => context.go('/artisan/request/456'),
              child: const Text('Voir détail demande 456'),
            ),
          ],
        ),
      ),
    );
  }
}
