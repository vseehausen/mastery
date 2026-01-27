# Research: User Authentication

**Feature**: 003-user-auth  
**Date**: 2026-01-26

## Research Questions

### 1. Supabase Auth OAuth Configuration

**Question**: How to configure Apple Sign In and Google Sign In in Supabase?

**Decision**: Configure OAuth providers in Supabase Dashboard under Authentication > Providers. Each provider requires:
- Client ID and Client Secret from provider
- Redirect URLs configured in both Supabase and provider console
- Provider-specific settings (Apple requires team ID, key ID, private key)

**Rationale**: Supabase Auth handles OAuth flows, token exchange, and user creation automatically. Configuration is done via dashboard, no custom code needed.

**Alternatives Considered**: 
- Custom OAuth implementation: Rejected - too complex, security risks, maintenance burden
- Auth0/Firebase Auth: Rejected - already using Supabase, would add another dependency

**References**:
- Supabase Auth OAuth docs: https://supabase.com/docs/guides/auth/social-login
- Apple Sign In setup: https://supabase.com/docs/guides/auth/social-login/auth-apple
- Google Sign In setup: https://supabase.com/docs/guides/auth/social-login/auth-google

---

### 2. Tauri Deep Link Handling for OAuth Redirects

**Question**: How to handle OAuth browser redirects back to Tauri desktop app?

**Decision**: Use Tauri's custom URL scheme registration and deep link handling:
1. Register custom URL scheme in `tauri.conf.json` (e.g., `mastery://`)
2. Configure Supabase redirect URL as `mastery://auth/callback`
3. Use Tauri's `on_url` event handler to capture redirect
4. Extract auth code/token from URL and complete authentication

**Rationale**: Standard pattern for desktop OAuth flows. Tauri provides built-in support for custom URL schemes and deep link handling.

**Alternatives Considered**:
- Local HTTP server: Rejected - more complex, requires port management, firewall issues
- Polling for auth completion: Rejected - inefficient, poor UX

**References**:
- Tauri deep links: https://tauri.app/v2/guides/features/deep-links/
- Tauri URL protocol: https://tauri.app/v2/api/js/window/#urlprotocol

---

### 3. Flutter OAuth Provider Setup

**Question**: How to implement native Apple Sign In and Google Sign In in Flutter?

**Decision**: Use platform-specific packages:
- `sign_in_with_apple` for Apple Sign In (iOS/macOS)
- `google_sign_in` for Google Sign In
- Integrate with Supabase Flutter SDK's `signInWithOAuth()` method

**Rationale**: Native SDKs provide best UX and security. Supabase Flutter SDK supports PKCE flow which works with native providers.

**Alternatives Considered**:
- Web-based OAuth in WebView: Rejected - worse UX, security concerns
- Custom OAuth implementation: Rejected - unnecessary complexity

**References**:
- Supabase Flutter Auth: https://supabase.com/docs/reference/dart/auth-signinwithoauth
- sign_in_with_apple: https://pub.dev/packages/sign_in_with_apple
- google_sign_in: https://pub.dev/packages/google_sign_in

---

### 4. Session Persistence Patterns

**Question**: How to persist authentication sessions across app restarts?

**Decision**: 
- **Mobile**: Supabase Flutter SDK automatically persists sessions in secure storage (Keychain on iOS, EncryptedSharedPreferences on Android)
- **Desktop**: Store refresh token securely in app data directory, use Supabase JS SDK's session restoration

**Rationale**: Both SDKs handle session persistence automatically. Desktop may need explicit session restoration on app startup.

**Alternatives Considered**:
- Custom token storage: Rejected - SDKs handle this securely, no need to reinvent
- Server-side session management: Rejected - adds complexity, breaks offline-first principle

**References**:
- Supabase Flutter session persistence: https://supabase.com/docs/reference/dart/auth-getsession
- Supabase JS session management: https://supabase.com/docs/reference/javascript/auth-getsession

---

### 5. Additional OAuth Providers

**Question**: Which additional OAuth providers should be supported?

**Decision**: Start with Apple and Google (required), then add GitHub and Microsoft based on common usage patterns. Configuration follows same pattern as Apple/Google.

**Rationale**: Apple and Google cover majority of users. GitHub and Microsoft are common for developer/enterprise users. Can add more providers later if needed.

**Alternatives Considered**:
- Facebook: Rejected - declining usage, privacy concerns
- Twitter/X: Rejected - API instability, less common for productivity apps

**References**:
- Supabase supported providers: https://supabase.com/docs/guides/auth/social-login

---

### 6. Account Linking Strategy

**Question**: How to handle account linking when same email is used across multiple providers?

**Decision**: Supabase Auth automatically links accounts with same verified email address. If email is not verified, accounts remain separate. Manual linking can be done via Supabase Admin API if needed.

**Rationale**: Supabase handles this automatically, reducing implementation complexity. Email verification ensures security.

**Alternatives Considered**:
- Manual account linking UI: Rejected - Supabase handles this automatically, adds unnecessary complexity
- Prevent multiple providers: Rejected - poor UX, users expect flexibility

**References**:
- Supabase account linking: https://supabase.com/docs/guides/auth/auth-deep-dive/auth-deep-dive-jwts#linking-accounts

---

## Technical Decisions Summary

1. **OAuth Configuration**: Dashboard-based configuration, no custom code
2. **Desktop OAuth Flow**: Custom URL scheme with Tauri deep link handling
3. **Mobile OAuth**: Native SDKs integrated with Supabase Flutter
4. **Session Persistence**: SDK-managed secure storage
5. **Additional Providers**: GitHub and Microsoft after Apple/Google
6. **Account Linking**: Automatic via Supabase based on verified email

## Dependencies to Add

### Mobile (pubspec.yaml)
- `sign_in_with_apple: ^6.1.0` (for Apple Sign In)
- `google_sign_in: ^6.2.0` (for Google Sign In)

### Desktop (Cargo.toml)
- No new Rust dependencies (use existing reqwest, serde)
- May need Tauri plugin for URL handling if not in core

### Desktop (package.json)
- `@supabase/supabase-js: ^2.39.0` (for Supabase client)

## Configuration Required

1. **Supabase Dashboard**:
   - Enable Apple Sign In provider
   - Enable Google Sign In provider
   - Configure redirect URLs for desktop (`mastery://auth/callback`)
   - Configure redirect URLs for mobile (app-specific URLs)

2. **Apple Developer Console**:
   - Create App ID with Sign In capability
   - Create Service ID for web OAuth
   - Generate private key for Apple Sign In

3. **Google Cloud Console**:
   - Create OAuth 2.0 credentials
   - Configure authorized redirect URIs

4. **Tauri Configuration**:
   - Register custom URL scheme in `tauri.conf.json`
