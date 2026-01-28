import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SharedPaymentScreen extends StatelessWidget {
  const SharedPaymentScreen({super.key});

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
            const Text('Écran de paiement partagé'),
            ElevatedButton(
              onPressed: () {
                // Retourne au dashboard selon le type d'utilisateur
                context.go('/client/home'); // ou '/artisan/home'
              },
              child: const Text('Payer et retourner'),
            ),
          ],
        ),
      ),
    );
  }
}
