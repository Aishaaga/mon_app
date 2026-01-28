import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

// AUTH SCREENS
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_client.dart';
import '../screens/auth/register_artisan.dart';

// CLIENT SCREENS
import '../screens/client/client_home.dart';
import '../screens/client/create_request.dart';
import '../screens/client/my_requests.dart';
import '../screens/client/request_details.dart';
import '../screens/client/search_artisans.dart';
import '../screens/client/artisan_profile.dart';
import '../screens/client/messages_list.dart';
import '../screens/client/client_profile.dart';

// ARTISAN SCREENS - CORRECTION DES NOMS
import '../screens/artisan/artisan_home.dart';
import '../screens/artisan/available_requests.dart';
import '../screens/artisan/request_details.dart'; // Même nom mais différent dossier
import '../screens/artisan/send_quote.dart';
import '../screens/artisan/my_jobs.dart';
import '../screens/artisan/job_details.dart';
import '../screens/artisan/messages_list.dart'; // Même nom mais différent dossier
import '../screens/artisan/artisan_profile.dart';
import '../screens/artisan/earnings.dart';
import '../screens/artisan/payment_screen.dart';

// SHARED SCREENS
import '../screens/shared/chat_screen.dart';
import '../screens/shared/payment_screen.dart';

class AppRouter {
  // Garde d'authentification
  static Future<String?> _authGuard(
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final isAuthPage =
        state.uri.path == '/login' ||
        state.uri.path == '/register/client' ||
        state.uri.path == '/register/artisan';

    // Si l'utilisateur n'est pas connecté ET n'est pas sur une page d'auth
    if (user == null && !isAuthPage) {
      return '/login';
    }

    // Si l'utilisateur est connecté ET est sur une page d'auth
    if (user != null && isAuthPage) {
      // Pour l'instant, redirige vers client_home par défaut
      // Tu pourras améliorer pour détecter le type d'utilisateur
      return '/client/home';
    }

    return null; // Pas de redirection
  }

  // Configuration du routeur
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: _authGuard,
    routes: [
      // ============ AUTHENTIFICATION ============
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register/client',
        name: 'register_client',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RegisterClientScreen(),
        ),
      ),
      GoRoute(
        path: '/register/artisan',
        name: 'register_artisan',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RegisterArtisanScreen(),
        ),
      ),

      // ============ CLIENT ============
      GoRoute(
        path: '/client/home',
        name: 'client_home',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const ClientHome()),
      ),
      GoRoute(
        path: '/client/create-request',
        name: 'create_request',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const CreateRequestScreen(),
        ),
      ),
      GoRoute(
        path: '/client/my-requests',
        name: 'my_requests',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const MyRequestsScreen()),
      ),
      GoRoute(
        path: '/client/request/:id',
        name: 'client_request_details',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: ClientRequestDetailsScreen(
            requestId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/client/search-artisans',
        name: 'search_artisans',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SearchArtisansScreen(),
        ),
      ),
      GoRoute(
        path: '/client/artisan/:id',
        name: 'client_artisan_profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: ClientArtisanProfileScreen(
            artisanId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/client/messages',
        name: 'client_messages',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ClientMessagesListScreen(),
        ),
      ),
      GoRoute(
        path: '/client/profile',
        name: 'client_profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ClientProfileScreen(),
        ),
      ),

      // ============ ARTISAN ============
      GoRoute(
        path: '/artisan/home',
        name: 'artisan_home',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const ArtisanHome()),
      ),
      GoRoute(
        path: '/artisan/available-requests',
        name: 'available_requests',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AvailableRequestsScreen(),
        ),
      ),
      GoRoute(
        path: '/artisan/request/:id',
        name: 'artisan_request_details',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: ArtisanRequestDetailsScreen(
            requestId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/artisan/send-quote/:id',
        name: 'send_quote',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: SendQuoteScreen(requestId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/artisan/my-jobs',
        name: 'my_jobs',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const MyJobsScreen()),
      ),
      GoRoute(
        path: '/artisan/job/:id',
        name: 'job_details',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: JobDetailsScreen(jobId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/artisan/messages',
        name: 'artisan_messages',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ArtisanMessagesListScreen(),
        ),
      ),
      GoRoute(
        path: '/artisan/profile',
        name: 'artisan_own_profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ArtisanProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/artisan/earnings',
        name: 'earnings',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const EarningsScreen()),
      ),
      GoRoute(
        path: '/artisan/payment',
        name: 'artisan_payment',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ArtisanPaymentScreen(),
        ),
      ),

      // ============ PARTAGÉ ============
      GoRoute(
        path: '/chat/:userId',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final returnRoute = state.uri.queryParameters['returnTo'];

          return MaterialPage(
            key: state.pageKey,
            child: ChatScreen(userId: userId, returnRoute: returnRoute),
          );
        },
      ),
      GoRoute(
        path: '/payment',
        name: 'shared_payment',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SharedPaymentScreen(),
        ),
      ),
    ],

    // Gestion des erreurs 404
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                'Page non trouvée',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'L\'URL ${state.uri.path} n\'existe pas',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Helper pour naviguer facilement
class NavigationHelper {
  static void goToLogin(BuildContext context) {
    context.go('/login');
  }

  static void goToClientHome(BuildContext context) {
    context.go('/client/home');
  }

  static void goToArtisanHome(BuildContext context) {
    context.go('/artisan/home');
  }

  static void goToChat(BuildContext context, String userId) {
    context.go('/chat/$userId');
  }

  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }
}
