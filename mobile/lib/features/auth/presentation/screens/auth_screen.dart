import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../widgets/auth_logo.dart';
import '../widgets/oauth_button.dart';
import '../widgets/auth_divider.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../providers/auth_provider.dart';
import 'email_sign_up_screen.dart';
import 'email_sign_in_screen.dart';

/// Welcome/Auth screen with OAuth options and email sign in
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Logo section
              const AuthLogo(
                title: 'Mastery',
                subtitle: 'Your vocabulary shadow brain',
              ),
              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: MasteryTextStyles.bodySmall.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // OAuth buttons
              OAuthButton(
                onPressed: _isLoading ? null : _signInWithApple,
                icon: Icons.apple,
                label: 'Continue with Apple',
              ),
              const SizedBox(height: 12),
              OAuthButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
              ),
              const SizedBox(height: 32),

              // Divider
              const AuthDivider(),
              const SizedBox(height: 32),

              // Email button
              OAuthButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const EmailSignUpScreen(),
                          ),
                        );
                      },
                icon: Icons.mail_outline,
                label: 'Continue with Email',
              ),
              const SizedBox(height: 48),

              // Sign in link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: MasteryTextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const EmailSignInScreen(),
                              ),
                            );
                          },
                    child: Text(
                      'Sign in',
                      style: MasteryTextStyles.bodySmall.copyWith(
                        color: ShadTheme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithApple() async {
    // Only available on iOS/macOS
    if (!Platform.isIOS && !Platform.isMacOS) {
      setState(() {
        _errorMessage = 'Apple Sign In is not available on this device';
      });
      return;
    }

    // Set OAuth in progress BEFORE starting
    ref.read(oauthInProgressProvider.notifier).state = true;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithApple();
      // Don't navigate here - AuthGuard handles it
    } catch (e) {
      // Clear OAuth flag on error
      ref.read(oauthInProgressProvider.notifier).state = false;
      setState(() {
        _errorMessage = _getOAuthErrorMessage(e, 'Apple');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    // Set OAuth in progress BEFORE starting
    ref.read(oauthInProgressProvider.notifier).state = true;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.signInWithGoogle();
      
      // Check if sign-in actually succeeded
      if (response.session == null) {
        throw Exception('Sign in succeeded but no session was created');
      }
      
      // Don't navigate here - AuthGuard handles it
      // OAuth flag will be cleared by AuthGuard when isAuthenticated becomes true
    } catch (e) {
      // Clear OAuth flag on error
      ref.read(oauthInProgressProvider.notifier).state = false;
      setState(() {
        _errorMessage = _getOAuthErrorMessage(e, 'Google');
      });
      // Log error for debugging
      debugPrint('Google sign-in error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getOAuthErrorMessage(dynamic error, String provider) {
    final message = error.toString().toLowerCase();
    if (message.contains('cancel')) {
      return '$provider Sign In was cancelled';
    }
    if (message.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    if (message.contains('unsupported')) {
      return '$provider Sign In is not available on this device';
    }
    return '$provider Sign In failed. Please try again.';
  }
}
