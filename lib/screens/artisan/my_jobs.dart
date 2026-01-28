import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes interventions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/artisan/home'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Liste des interventions'),
            ElevatedButton(
              onPressed: () => context.go('/artisan/job/999'),
              child: const Text('Voir détail intervention 999'),
            ),
          ],
        ),
      ),
    );
  }
}
