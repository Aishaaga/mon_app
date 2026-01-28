import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientRequestDetailsScreen extends StatelessWidget {
  final String requestId;

  const ClientRequestDetailsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détail demande $requestId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Détails de la demande $requestId'),
            ElevatedButton(
              onPressed: () => context.go('/chat/artisan456'),
              child: const Text('Contacter artisan'),
            ),
          ],
        ),
      ),
    );
  }
}
