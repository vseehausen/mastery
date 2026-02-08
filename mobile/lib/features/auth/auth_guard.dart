import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/learning_providers.dart';
import '../../core/theme/color_tokens.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/oauth_loading_screen.dart';

/// Auth guard widget that shows login if user is not authenticated
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  /// Check if error is a refresh token error that should trigger sign out
  bool _isRefreshTokenError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('refresh token') ||
        message.contains('refresh_token') ||
        message.contains('invalid_grant');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final authState = ref.watch(authStateProvider);
    final oauthInProgress = ref.watch(oauthInProgressProvider);

    // Trigger enrichment replenishment when user becomes authenticated
    ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      if (previous == false && next == true) {
        // User just logged in - replenish enrichment buffer
        final userId = ref.read(currentUserIdProvider);
        if (userId != null) {
          ref.read(enrichmentServiceProvider).replenishIfNeeded(userId);
        }
        // Clear OAuth flag when authenticated
        ref.read(oauthInProgressProvider.notifier).state = false;
      }
    });

    // Safety timeout: clear OAuth flag after 30 seconds if still in progress
    if (oauthInProgress && !isAuthenticated) {
      Future.delayed(const Duration(seconds: 30), () {
        if (ref.read(oauthInProgressProvider) &&
            !ref.read(isAuthenticatedProvider)) {
          ref.read(oauthInProgressProvider.notifier).state = false;
        }
      });
    }

    // Auto-clear session on refresh token errors
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          if (_isRefreshTokenError(error)) {
            Supabase.instance.client.auth.signOut();
          }
        },
      );
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
      error: (error, stack) {
        // If it's a refresh token error, show auth screen directly
        if (_isRefreshTokenError(error)) {
          return const AuthScreen();
        }
        return Scaffold(
          body: Builder(
            builder: (context) {
              final colors = context.masteryColors;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colors.destructive,
                    ),
                    const SizedBox(height: 16),
                    Text('Authentication error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Supabase.instance.client.auth.signOut();
                      },
                      child: const Text('Go to Sign In'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
