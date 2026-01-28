import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes demandes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/home'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Liste de mes demandes'),
            ElevatedButton(
              onPressed: () => context.go('/client/request/123'),
              child: const Text('Voir détail demande 123'),
            ),
          ],
        ),
      ),
    );
  }
}
