import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';

/// Supabase implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl(this._client)
      : _googleSignIn = GoogleSignIn(
          scopes: ['email'],
          // iOS client ID from Google Cloud Console
          clientId: Platform.isIOS
              ? '771280991163-45gom2dnikc42h0ajt4cre62mds5v9u2.apps.googleusercontent.com'
              : null,
        );

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
    // Apple Sign In only available on iOS/macOS
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw UnsupportedError('Apple Sign In is only available on iOS/macOS');
    }

    try {
      print('Apple Sign In: Getting credentials...');
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      print('Apple Sign In: Got credential, identityToken exists: ${credential.identityToken != null}');

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Apple Sign In failed: No identity token');
      }

      print('Apple Sign In: Signing in with Supabase...');
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
      print('Apple Sign In: Success! User: ${response.user?.email}');
      return response;
    } catch (e) {
      print('Apple Sign In Error: $e');
      rethrow;
    }
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
    try {
      print('Google Sign In: Starting...');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign In cancelled');
      }
      print('Google Sign In: Got user ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      print('Google Sign In: Got tokens, idToken exists: ${idToken != null}');

      if (idToken == null) {
        throw Exception('Google Sign In failed: No ID token');
      }

      print('Google Sign In: Signing in with Supabase...');
      // Don't pass accessToken - it causes nonce mismatch issues
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      print('Google Sign In: Success! User: ${response.user?.email}');
      return response;
    } catch (e) {
      print('Google Sign In Error: $e');
      rethrow;
    }
  }

  @override
  bool get isAuthenticated => currentUser != null;

  @override
  String? get userId => currentUser?.id;
}
