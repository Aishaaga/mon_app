import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateRequestScreen extends StatelessWidget {
  const CreateRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle demande'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/home'),
        ),
      ),
      body: const Center(child: Text('Écran de création de demande')),
    );
  }
}
