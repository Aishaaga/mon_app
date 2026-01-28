import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ArtisanPaymentScreen extends StatelessWidget {
  const ArtisanPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Écran de paiement (version artisan)'),
            ElevatedButton(
              onPressed: () => context.go('/artisan/home'),
              child: const Text('Retour au tableau de bord'),
            ),
          ],
        ),
      ),
    );
  }
}
