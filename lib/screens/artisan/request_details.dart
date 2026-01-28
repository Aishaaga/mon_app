import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ArtisanRequestDetailsScreen extends StatelessWidget {
  final String requestId;

  const ArtisanRequestDetailsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détail demande $requestId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(
            '/chat/client789?returnTo=/artisan/request/$requestId',
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Détails demande $requestId'),
            ElevatedButton(
              onPressed: () => context.go('/artisan/send-quote/$requestId'),
              child: const Text('Envoyer devis'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/chat/client789'),
              child: const Text('Contacter client'),
            ),
          ],
        ),
      ),
    );
  }
}
