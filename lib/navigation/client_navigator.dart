import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Helper de navigation spécifique pour les clients
class ClientNavigator {
  final BuildContext context;

  ClientNavigator(this.context);

  // Navigation vers les différentes pages
  void goToHome() => context.go('/client/home');
  void goToCreateRequest() => context.go('/client/create-request');
  void goToMyRequests() => context.go('/client/my-requests');
  void goToSearchArtisans() => context.go('/client/search-artisans');
  void goToMessages() => context.go('/client/messages');
  void goToProfile() => context.go('/client/profile');

  void goToRequestDetails(String requestId) {
    context.go('/client/request/$requestId');
  }

  void goToArtisanProfile(String artisanId) {
    context.go('/client/artisan/$artisanId');
  }

  void goToChat(String userId) {
    context.go('/chat/$userId');
  }

  void goToPayment() {
    context.go('/payment');
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

    if (location.startsWith('/client/home')) return 0;
    if (location.startsWith('/client/my-requests')) return 1;
    if (location.startsWith('/client/search-artisans')) return 2;
    if (location.startsWith('/client/messages')) return 3;
    if (location.startsWith('/client/profile')) return 4;

    return 0;
  }

  // BottomNavigationBar pour client
  static Widget clientBottomNavBar(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'Mes demandes',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Rechercher'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/client/home');
            break;
          case 1:
            context.go('/client/my-requests');
            break;
          case 2:
            context.go('/client/search-artisans');
            break;
          case 3:
            context.go('/client/messages');
            break;
          case 4:
            context.go('/client/profile');
            break;
        }
      },
    );
  }
}
