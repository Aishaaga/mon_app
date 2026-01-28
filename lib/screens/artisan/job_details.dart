import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JobDetailsScreen extends StatelessWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Intervention $jobId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Détails intervention $jobId'),
            ElevatedButton(
              onPressed: () => context.go('/artisan/payment'),
              child: const Text('Terminer et facturer'),
            ),
          ],
        ),
      ),
    );
  }
}
