import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SendQuoteScreen extends StatelessWidget {
  final String requestId;

  const SendQuoteScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Devis demande $requestId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Formulaire devis pour $requestId'),
            ElevatedButton(
              onPressed: () => context.go('/artisan/home'),
              child: const Text('Envoyer devis'),
            ),
          ],
        ),
      ),
    );
  }
}
