import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';

/// Supabase implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client)
      : _googleSignIn = GoogleSignIn(
          scopes: ['email'],
          // iOS client ID from Google Cloud Console
          clientId: Platform.isIOS
              ? '771280991163-45gom2dnikc42h0ajt4cre62mds5v9u2.apps.googleusercontent.com'
              : null,
        );

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<AuthResponse> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw UnsupportedError('Apple Sign In is only available on iOS/macOS');
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple Sign In failed: No identity token');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
    );
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign In cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Google Sign In failed: No ID token');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  @override
  bool get isAuthenticated => currentUser != null;

  @override
  String? get userId => currentUser?.id;
}
