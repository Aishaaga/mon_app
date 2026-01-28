import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatelessWidget {
  final String userId;

  const ChatScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat avec $userId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/request/123'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Interface de chat avec $userId'),
            ElevatedButton(
              onPressed: () => context.go('/client/request/123'),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }
}
