import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract interface for authentication operations
abstract class AuthRepository {
  /// Get the current authenticated user
  User? get currentUser;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<void> signOut();

  /// Send password reset email
  Future<void> resetPassword(String email);

  /// Sign in with Apple Sign In
  Future<AuthResponse> signInWithApple();

  /// Sign in with Google Sign In
  Future<AuthResponse> signInWithGoogle();

  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Get current user's ID
  String? get userId;
}
