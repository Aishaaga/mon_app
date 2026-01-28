import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Helper de navigation spécifique pour les artisans
class ArtisanNavigator {
  final BuildContext context;

  ArtisanNavigator(this.context);

  // Navigation vers les différentes pages
  void goToHome() => context.go('/artisan/home');
  void goToAvailableRequests() => context.go('/artisan/available-requests');
  void goToMyJobs() => context.go('/artisan/my-jobs');
  void goToMessages() => context.go('/artisan/messages');
  void goToProfile() => context.go('/artisan/profile');
  void goToEarnings() => context.go('/artisan/earnings');

  void goToRequestDetails(String requestId) {
    context.go('/artisan/request/$requestId');
  }

  void goToSendQuote(String requestId) {
    context.go('/artisan/send-quote/$requestId');
  }

  void goToJobDetails(String jobId) {
    context.go('/artisan/job/$jobId');
  }

  void goToChat(String userId) {
    context.go('/chat/$userId');
  }

  void goToPayment() {
    context.go('/artisan/payment');
  }

  void goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      goToHome();
    }
  }

  // Détecter l'index actuel pour BottomNavigationBar
  static int getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/artisan/home')) return 0;
    if (location.startsWith('/artisan/available-requests')) return 1;
    if (location.startsWith('/artisan/my-jobs')) return 2;
    if (location.startsWith('/artisan/messages')) return 3;
    if (location.startsWith('/artisan/profile')) return 4;

    return 0;
  }

  // BottomNavigationBar pour artisan
  static Widget artisanBottomNavBar(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Tableau de bord',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Demandes',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Interventions'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/artisan/home');
            break;
          case 1:
            context.go('/artisan/available-requests');
            break;
          case 2:
            context.go('/artisan/my-jobs');
            break;
          case 3:
            context.go('/artisan/messages');
            break;
          case 4:
            context.go('/artisan/profile');
            break;
        }
      },
    );
  }
}
