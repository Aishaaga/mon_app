import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatelessWidget {
  final String userId;
  final String? returnRoute; // Route de retour optionnelle

  const ChatScreen({super.key, required this.userId, this.returnRoute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat avec $userId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (returnRoute != null) {
              context.go(returnRoute!);
            } else if (context.canPop()) {
              context.pop();
            } else {
              // Par défaut selon le préfixe de l'userId
              if (userId.startsWith('client')) {
                context.go('/artisan/available-requests');
              } else {
                context.go('/client/my-requests');
              }
            }
          },
        ),
      ),
      body: Center(child: Text('Chat avec $userId')),
    );
  }
}
