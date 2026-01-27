# Data Model: User Authentication

**Feature**: 003-user-auth  
**Date**: 2026-01-26

## Overview

Authentication data is primarily managed by Supabase Auth. This document describes the entities relevant to the application layer and how they map to Supabase Auth concepts.

## Entities

### User Account

**Source**: Supabase Auth `auth.users` table (managed by Supabase)

Represents an authenticated user in the system.

**Attributes**:
- `id` (UUID): Unique user identifier (primary key)
- `email` (string): User's email address (may be null for OAuth-only accounts)
- `email_confirmed_at` (timestamp): When email was verified (null if unverified)
- `created_at` (timestamp): Account creation timestamp
- `last_sign_in_at` (timestamp): Most recent sign-in timestamp
- `app_metadata` (JSONB): Provider-specific metadata (e.g., provider name, provider user ID)
- `user_metadata` (JSONB): User-provided metadata (display name, avatar URL, etc.)

**Relationships**:
- One user can have multiple authentication identities (email/password, Apple, Google, etc.)
- One user can have multiple active sessions (different devices)

**Validation Rules**:
- Email format validated by Supabase
- Password strength enforced by Supabase (configurable)
- Email verification required for email/password accounts (configurable)

**State Transitions**:
- `unauthenticated` → `authenticated`: User signs in successfully
- `authenticated` → `unauthenticated`: User signs out or session expires
- `authenticated` → `authenticated`: Session refreshed (automatic)

---

### Authentication Session

**Source**: Supabase Auth session tokens (stored locally per platform)

Represents an active user session with access and refresh tokens.

**Attributes**:
- `access_token` (JWT): Short-lived token for API authentication (expires in ~1 hour)
- `refresh_token` (string): Long-lived token for obtaining new access tokens (expires in ~30 days)
- `expires_at` (timestamp): Access token expiration time
- `user` (User): Associated user account
- `provider` (string): Authentication provider used (email, apple, google, etc.)

**Storage**:
- **Mobile**: Stored securely by Supabase Flutter SDK (Keychain/EncryptedSharedPreferences)
- **Desktop**: Stored in app data directory, encrypted at rest

**State Transitions**:
- `active` → `expired`: Access token expires (refresh automatically)
- `active` → `revoked`: User signs out or token is invalidated
- `expired` → `active`: Session refreshed using refresh token

---

### Authentication Identity

**Source**: Supabase Auth `auth.identities` table (managed by Supabase)

Represents a single authentication method linked to a user account. One user can have multiple identities (e.g., email/password + Apple Sign In).

**Attributes**:
- `id` (UUID): Unique identity identifier
- `user_id` (UUID): Foreign key to user account
- `provider` (string): Authentication provider (email, apple, google, etc.)
- `provider_id` (string): User's ID in the provider's system
- `identity_data` (JSONB): Provider-specific data (email, name, avatar, etc.)
- `created_at` (timestamp): When identity was linked

**Relationships**:
- Many identities belong to one user account
- One identity belongs to one provider

**Validation Rules**:
- Provider must be supported by Supabase Auth
- Provider ID must be unique per provider

---

## Platform-Specific Storage

### Mobile (Flutter)

**Session Storage**: 
- Managed by `supabase_flutter` package
- iOS: Keychain Services
- Android: EncryptedSharedPreferences

**Local State**:
- Current user cached in memory via Riverpod providers
- Auth state streamed via `authStateChanges` stream

### Desktop (Tauri)

**Session Storage**:
- Refresh token stored in app data directory: `{app_data}/auth/session.json`
- Encrypted using platform keychain (macOS Keychain, Windows Credential Manager, Linux Secret Service)

**Local State**:
- Current session cached in Rust `SupabaseAuth` struct
- Exposed to frontend via Tauri commands

---

## Data Flow

### Sign In Flow

1. User initiates authentication (email/password or OAuth)
2. Credentials sent to Supabase Auth
3. Supabase validates and returns session tokens
4. Session tokens stored locally (platform-specific)
5. User object cached in application state
6. Subsequent API calls include access token in Authorization header

### Sign Out Flow

1. User initiates sign out
2. Local session tokens deleted
3. Refresh token invalidated on server (optional, Supabase handles)
4. User state cleared from application cache
5. User redirected to sign-in screen

### Session Refresh Flow

1. Access token expires (or about to expire)
2. Application detects expiration
3. Refresh token sent to Supabase Auth
4. New access token and refresh token returned
5. Tokens updated in local storage
6. Application continues with new tokens

---

## Security Considerations

1. **Token Storage**: Tokens stored securely using platform keychain/secure storage
2. **Token Transmission**: All API calls use HTTPS
3. **Token Expiration**: Access tokens expire quickly, refresh tokens rotated
4. **Email Verification**: Required for email/password accounts to prevent account takeover
5. **OAuth Scopes**: Minimal scopes requested (email, profile only)
6. **PKCE Flow**: Used for OAuth to prevent authorization code interception

---

## Migration Notes

**Existing Data**: No migration needed - Supabase Auth manages all authentication data.

**User Data Linking**: Existing user data (highlights, vocabulary) will be linked to authenticated users via `user_id` foreign keys. Migration strategy:
- If dev users exist, map them to new authenticated users
- If no dev users, start fresh with authenticated users only
