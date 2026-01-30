import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/oauth_loading_screen.dart';

/// Auth guard widget that shows login if user is not authenticated
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final authState = ref.watch(authStateProvider);
    final oauthInProgress = ref.watch(oauthInProgressProvider);

    // Trigger sync when user becomes authenticated
    ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      if (previous == false && next == true) {
        // User just logged in - trigger sync
        final syncService = ref.read(syncServiceProvider);
        syncService.sync();
        // Clear OAuth flag when authenticated
        ref.read(oauthInProgressProvider.notifier).state = false;
      }
    });

    return authState.when(
      data: (state) {
        if (!isAuthenticated) {
          // Show loading screen if OAuth in progress
          if (oauthInProgress) {
            return OAuthLoadingScreen(
              onCancel: () {
                ref.read(oauthInProgressProvider.notifier).state = false;
              },
            );
          }
          return const AuthScreen();
        }
        return child;
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Authentication error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const AuthScreen(),
                    ),
                  );
                },
                child: const Text('Go to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
