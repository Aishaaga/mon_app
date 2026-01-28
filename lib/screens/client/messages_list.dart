import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientMessagesListScreen extends StatelessWidget {
  const ClientMessagesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Liste des conversations'),
            ElevatedButton(
              onPressed: () => context.go('/chat/user123'),
              child: const Text('Ouvrir chat'),
            ),
          ],
        ),
      ),
    );
  }
}
