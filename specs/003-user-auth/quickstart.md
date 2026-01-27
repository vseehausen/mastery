# Quickstart: User Authentication

**Feature**: 003-user-auth  
**Date**: 2026-01-26

## Prerequisites

1. Supabase project with Auth enabled
2. OAuth providers configured in Supabase Dashboard:
   - Apple Sign In (requires Apple Developer account)
   - Google Sign In (requires Google Cloud Console setup)
3. Environment variables configured (see below)

## Environment Setup

### Mobile (.env)

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Desktop (.env)

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## Mobile (Flutter) Setup

### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.8.3  # Already added
  sign_in_with_apple: ^6.1.0
  google_sign_in: ^6.2.0
```

```bash
flutter pub get
```

### 2. Configure Apple Sign In (iOS)

1. Enable Sign In with Apple capability in Xcode
2. Configure Apple Developer Console:
   - Create App ID with Sign In capability
   - Create Service ID for web OAuth
   - Generate private key
3. Add credentials to Supabase Dashboard

### 3. Configure Google Sign In

1. Create OAuth 2.0 credentials in Google Cloud Console
2. Add iOS client ID to `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   ```
3. Add Android configuration to `android/app/build.gradle`
4. Add credentials to Supabase Dashboard

### 4. Initialize Supabase

```dart
// lib/main.dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
  runApp(MyApp());
}
```

### 5. Use Authentication

```dart
// Sign in with email/password
final response = await Supabase.instance.client.auth.signInWithPassword(
  email: email,
  password: password,
);

// Sign in with Apple
final appleCredential = await SignInWithApple.getAppleIDCredential(
  scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
);
final response = await Supabase.instance.client.auth.signInWithIdToken(
  provider: Provider.apple,
  idToken: appleCredential.identityToken!,
  accessToken: appleCredential.authorizationCode,
);

// Sign in with Google
final googleUser = await GoogleSignIn().signIn();
final googleAuth = await googleUser!.authentication;
final response = await Supabase.instance.client.auth.signInWithIdToken(
  provider: Provider.google,
  idToken: googleAuth.idToken!,
  accessToken: googleAuth.accessToken,
);

// Sign out
await Supabase.instance.client.auth.signOut();

// Check auth state
final user = Supabase.instance.client.auth.currentUser;
final isAuthenticated = user != null;
```

## Desktop (Tauri) Setup

### 1. Add Dependencies

```toml
# Cargo.toml - No new Rust dependencies needed
# Use existing: reqwest, serde, serde_json
```

```json
// package.json
{
  "dependencies": {
    "@supabase/supabase-js": "^2.39.0"
  }
}
```

### 2. Configure Deep Links

```json
// tauri.conf.json
{
  "tauri": {
    "bundle": {
      "identifier": "com.mastery.app",
      "urlProtocols": [
        {
          "scheme": "mastery",
          "protocol": "Mastery Protocol"
        }
      ]
    }
  }
}
```

### 3. Register URL Handler

```rust
// src-tauri/src/main.rs
use tauri::Manager;

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            // Handle deep links
            app.handle().plugin(
                tauri_plugin_deep_link::init(|url| {
                    // Handle mastery://auth/callback?code=...
                    if url.starts_with("mastery://auth/callback") {
                        // Extract code/token and complete OAuth
                    }
                })
            )?;
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

### 4. Initialize Supabase Client

```typescript
// src/lib/api/auth.ts
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    flowType: 'pkce',
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false, // We handle deep links manually
  },
});
```

### 5. Implement OAuth Flow

```typescript
// src/lib/api/auth.ts
export async function signInWithOAuth(provider: string) {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: provider as any,
    options: {
      redirectTo: 'mastery://auth/callback',
    },
  });
  
  if (data?.url) {
    // Open browser with OAuth URL
    await invoke('open_browser', { url: data.url });
  }
  
  return { data, error };
}

// Handle callback
export async function handleOAuthCallback(url: string) {
  const { data, error } = await supabase.auth.getSessionFromUrl(url);
  return { data, error };
}
```

### 6. Rust Auth Module

```rust
// src-tauri/src/auth/mod.rs
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

pub struct SupabaseAuth {
    supabase_url: String,
    anon_key: String,
    session_path: PathBuf,
}

impl SupabaseAuth {
    pub fn new(app_data_dir: PathBuf) -> Self {
        // Load from env
        let supabase_url = std::env::var("SUPABASE_URL").unwrap();
        let anon_key = std::env::var("SUPABASE_ANON_KEY").unwrap();
        
        Self {
            supabase_url,
            anon_key,
            session_path: app_data_dir.join("auth").join("session.json"),
        }
    }
    
    pub async fn sign_in_with_email(&self, email: &str, password: &str) -> Result<Session, AuthError> {
        // Call Supabase Auth API
    }
    
    pub async fn get_session(&self) -> Option<Session> {
        // Load from file or refresh if expired
    }
    
    pub async fn sign_out(&self) -> Result<(), AuthError> {
        // Delete session file
    }
}
```

## Testing

### Mobile

```dart
// test/auth_test.dart
void main() {
  testWidgets('User can sign in with email', (tester) async {
    // Test sign in flow
  });
  
  testWidgets('User session persists across app restarts', (tester) async {
    // Test session persistence
  });
}
```

### Desktop

```rust
// src-tauri/src/auth/mod.rs (tests)
#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_sign_in_with_email() {
        // Test sign in flow
    }
}
```

## Common Issues

### Mobile: Apple Sign In not working
- Verify capability enabled in Xcode
- Check Service ID configuration in Apple Developer Console
- Ensure redirect URLs match in Supabase Dashboard

### Mobile: Google Sign In not working
- Verify OAuth credentials configured correctly
- Check URL schemes in Info.plist (iOS) or build.gradle (Android)
- Ensure redirect URLs match in Supabase Dashboard

### Desktop: Deep link not working
- Verify URL scheme registered in tauri.conf.json
- Check URL handler registered in setup()
- Test deep link manually: `open mastery://auth/callback?code=test`

### Desktop: Session not persisting
- Check app data directory permissions
- Verify session file is being written
- Check session refresh logic

## Next Steps

1. Implement auth UI screens (sign in, sign up)
2. Add auth guards to protect routes
3. Update API calls to include auth tokens
4. Test OAuth flows on all platforms
5. Configure additional OAuth providers (GitHub, Microsoft)
