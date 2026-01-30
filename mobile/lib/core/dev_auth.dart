import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Development-only authentication helper.
/// Uses service role key to auto-login as dev user.
class DevAuth {
  static String? get _serviceRoleKey => dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
  static String? get _devUserId => dotenv.env['DEV_USER_ID'];
  static String? get _devUserEmail => dotenv.env['DEV_USER_EMAIL'];
  static String? get _supabaseUrl => dotenv.env['SUPABASE_URL'];

  /// Check if dev mode is configured
  static bool get isConfigured =>
      kDebugMode &&
      _serviceRoleKey != null &&
      _serviceRoleKey!.isNotEmpty &&
      _devUserId != null &&
      _devUserId!.isNotEmpty;

  /// Auto-login as dev user using admin API
  static Future<bool> autoLogin() async {
    if (!isConfigured) {
      if (kDebugMode) print('[DevAuth] Not configured, skipping auto-login');
      return false;
    }

    // Skip if already logged in
    if (Supabase.instance.client.auth.currentUser != null) {
      if (kDebugMode) print('[DevAuth] Already logged in, skipping');
      return true;
    }

    try {
      if (kDebugMode) print('[DevAuth] Generating session for dev user...');

      // Use admin API to generate a link, then extract the token
      final response = await http.post(
        Uri.parse('$_supabaseUrl/auth/v1/admin/generate_link'),
        headers: {
          'Authorization': 'Bearer $_serviceRoleKey',
          'apikey': _serviceRoleKey!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'type': 'magiclink', 'email': _devUserEmail}),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('[DevAuth] Failed to generate link: ${response.statusCode}');
          print('[DevAuth] Response: ${response.body}');
        }
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (kDebugMode) print('[DevAuth] Response: $data');

      // The generate_link endpoint returns the link directly at the top level
      final actionLink = data['action_link'] as String?;
      if (actionLink == null) {
        if (kDebugMode) print('[DevAuth] No action_link in response');
        return false;
      }

      // Parse the token from the action link (format: ...?token=xxx&type=magiclink...)
      final uri = Uri.parse(actionLink);
      final fragment = uri.fragment; // Token is in the fragment for PKCE
      final fragmentParams = Uri.splitQueryString(fragment);
      var token = fragmentParams['access_token'];

      // If access_token in fragment, we can set the session directly
      if (token != null) {
        final refreshToken = fragmentParams['refresh_token'];
        if (kDebugMode) print('[DevAuth] Got tokens from fragment');

        await Supabase.instance.client.auth.setSession(refreshToken ?? token);
        return Supabase.instance.client.auth.currentUser != null;
      }

      // Otherwise try query param token for OTP verification
      token = uri.queryParameters['token'];
      if (token == null) {
        if (kDebugMode) print('[DevAuth] No token found in action_link');
        return false;
      }

      // Verify the OTP to get a session
      final authResponse = await Supabase.instance.client.auth.verifyOTP(
        token: token,
        type: OtpType.magiclink,
        email: _devUserEmail,
      );

      if (authResponse.session != null) {
        if (kDebugMode) {
          print(
            '[DevAuth] Successfully logged in as ${authResponse.user?.email}',
          );
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) print('[DevAuth] Error: $e');
      return false;
    }
  }
}
