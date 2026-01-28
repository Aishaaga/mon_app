import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientArtisanProfileScreen extends StatelessWidget {
  final String artisanId;

  const ClientArtisanProfileScreen({super.key, required this.artisanId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil artisan $artisanId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Profil de l\'artisan $artisanId'),
            ElevatedButton(
              onPressed: () => context.go('/chat/$artisanId'),
              child: const Text('Contacter'),
            ),
          ],
        ),
      ),
    );
  }
}
