# Testing Guide: User Authentication

**Feature**: 003-user-auth  
**Date**: 2026-01-26

## Prerequisites

### 1. Supabase Configuration

1. **Enable Email/Password Auth**:
   - Go to Supabase Dashboard → Authentication → Providers
   - Ensure "Email" provider is enabled
   - Configure email settings (SMTP optional for development)

2. **Verify Environment Variables**:
   - Mobile: `mobile/.env` should contain:
     ```
     SUPABASE_URL=https://vfeovvfpivbqeziwinwz.supabase.co
     SUPABASE_ANON_KEY=your-anon-key-here
     ```
   - Desktop: `desktop/.env` should contain (note `VITE_` prefix):
     ```
     VITE_SUPABASE_URL=https://vfeovvfpivbqeziwinwz.supabase.co
     VITE_SUPABASE_ANON_KEY=your-anon-key-here
     ```
   - Desktop Rust: Uses `.env` from project root (no `VITE_` prefix):
     ```
     SUPABASE_URL=https://vfeovvfpivbqeziwinwz.supabase.co
     SUPABASE_ANON_KEY=your-anon-key-here
     ```

### 2. Install Dependencies

**Mobile**:
```bash
cd mobile
flutter pub get
```

**Desktop**:
```bash
cd desktop
pnpm install  # or npm install
```

## Testing Mobile App (Flutter)

### Test 1: Sign Up Flow

1. **Launch the app**:
   ```bash
   cd mobile
   flutter run
   ```

2. **Navigate to Sign Up**:
   - Tap "Sign In" button on home screen
   - Tap "Sign Up" link at bottom

3. **Create Account**:
   - Enter a valid email (e.g., `test@example.com`)
   - Enter password (at least 8 characters)
   - Confirm password
   - Tap "Create Account"

4. **Verify**:
   - ✅ Should show "Check Your Email" screen
   - ✅ Email verification message displayed
   - ✅ Can navigate back to sign in

### Test 2: Sign In Flow

1. **Sign In**:
   - From home screen, tap "Sign In"
   - Enter email and password from Test 1
   - Tap "Sign In"

2. **Verify**:
   - ✅ Should navigate back to home screen
   - ✅ Should see user email displayed
   - ✅ Should see "Sign Out" button in header
   - ✅ Should be able to access protected features

### Test 3: Session Persistence

1. **Sign In** (if not already signed in)

2. **Close App**:
   - Fully close the Flutter app (not just minimize)

3. **Reopen App**:
   - Launch the app again

4. **Verify**:
   - ✅ Should remain signed in
   - ✅ User email still displayed
   - ✅ No redirect to sign-in screen

### Test 4: Sign Out Flow

1. **Sign Out**:
   - Tap "Sign Out" button in header

2. **Verify**:
   - ✅ Should redirect to sign-in screen
   - ✅ Cannot access protected features
   - ✅ Home screen shows "Sign In" button

### Test 5: Error Handling

1. **Invalid Credentials**:
   - Try signing in with wrong password
   - ✅ Should show error message: "Invalid email or password"

2. **Invalid Email Format**:
   - Try signing up with invalid email (e.g., `notanemail`)
   - ✅ Should show validation error

3. **Weak Password**:
   - Try signing up with password < 8 characters
   - ✅ Should show validation error

4. **Password Mismatch**:
   - Try signing up with mismatched passwords
   - ✅ Should show error: "Passwords do not match"

## Testing Desktop App (Tauri)

### Test 1: Sign Up Flow

1. **Launch the app**:
   ```bash
   cd desktop
   npm run tauri dev
   ```

2. **Navigate to Sign Up**:
   - App should redirect to `/auth/sign-in` if not authenticated
   - Click "Sign Up" link

3. **Create Account**:
   - Enter valid email (e.g., `test@example.com`)
   - Enter password (at least 8 characters)
   - Confirm password
   - Click "Create Account"

4. **Verify**:
   - ✅ Should show "Check Your Email" screen
   - ✅ Email verification message displayed
   - ✅ Can navigate back to sign in

### Test 2: Sign In Flow

1. **Sign In**:
   - Navigate to `/auth/sign-in` (or click link from sign-up)
   - Enter email and password
   - Click "Sign In"

2. **Verify**:
   - ✅ Should redirect to home page (`/`)
   - ✅ Should see user email in header
   - ✅ Should see "Sign Out" button
   - ✅ Can access Kindle import features

### Test 3: Session Persistence

1. **Sign In** (if not already signed in)

2. **Check Session File**:
   - Session should be stored at:
     - macOS: `~/Library/Application Support/com.mastery.app/auth/session.json`
     - Windows: `%APPDATA%\com.mastery.app\auth\session.json`
     - Linux: `~/.local/share/com.mastery.app/auth/session.json`

3. **Close App**:
   - Fully quit the desktop app

4. **Reopen App**:
   - Launch the app again

5. **Verify**:
   - ✅ Should remain signed in
   - ✅ User email still displayed
   - ✅ No redirect to sign-in screen
   - ✅ Session file still exists

### Test 4: Sign Out Flow

1. **Sign Out**:
   - Click "Sign Out" button in header

2. **Verify**:
   - ✅ Should redirect to `/auth/sign-in`
   - ✅ Cannot access home page
   - ✅ Session file should be deleted

### Test 5: Auth Guard Protection

1. **While Signed Out**:
   - Try navigating to `/` directly
   - ✅ Should redirect to `/auth/sign-in`

2. **While Signed In**:
   - Try navigating to `/auth/sign-in` directly
   - ✅ Should redirect to `/`

### Test 6: Error Handling

1. **Invalid Credentials**:
   - Try signing in with wrong password
   - ✅ Should show error message

2. **Invalid Email Format**:
   - Try signing up with invalid email
   - ✅ Should show validation error

3. **Network Error** (simulate):
   - Disconnect internet
   - Try signing in
   - ✅ Should show appropriate error message

## Manual Test Checklist

### Mobile App

- [ ] Can create new account with email/password
- [ ] Can sign in with existing account
- [ ] Session persists after app restart
- [ ] Can sign out successfully
- [ ] Auth guard redirects unauthenticated users
- [ ] Error messages display correctly
- [ ] Email validation works
- [ ] Password validation works (min 8 chars)
- [ ] Password visibility toggle works

### Desktop App

- [ ] Can create new account with email/password
- [ ] Can sign in with existing account
- [ ] Session persists after app restart
- [ ] Session file is created in app data directory
- [ ] Can sign out successfully
- [ ] Session file is deleted on sign out
- [ ] Auth guard redirects unauthenticated users
- [ ] Auth guard redirects authenticated users away from auth pages
- [ ] Error messages display correctly
- [ ] Email validation works
- [ ] Password validation works (min 8 chars)
- [ ] Password visibility toggle works

## Troubleshooting

### Mobile: "Supabase URL or Anon Key not configured"

**Solution**:
1. Check `mobile/.env` file exists
2. Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set
3. Restart the app after adding environment variables

### Desktop: "Failed to get app data dir"

**Solution**:
1. Check app has permissions to write to app data directory
2. Verify Tauri path resolver is working
3. Check console for detailed error messages

### Desktop: Session not persisting

**Solution**:
1. Check session file exists in app data directory
2. Verify file permissions allow read/write
3. Check console for errors loading session
4. Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set in `.env`

### Both: "Invalid login credentials"

**Solution**:
1. Verify email/password are correct
2. Check if email verification is required (Supabase settings)
3. Check Supabase Dashboard → Authentication → Users for account status

### Both: Network errors

**Solution**:
1. Verify internet connection
2. Check Supabase project is active
3. Verify `SUPABASE_URL` is correct
4. Check Supabase Dashboard for service status

## Verification Commands

### Check Mobile Environment
```bash
cd mobile
cat .env | grep SUPABASE
```

### Check Desktop Environment
```bash
# Frontend (Vite) - needs VITE_ prefix
cat desktop/.env | grep VITE_SUPABASE

# Backend (Rust) - no prefix
cat .env | grep SUPABASE
```

### Check Session File (Desktop)
```bash
# macOS
cat ~/Library/Application\ Support/com.mastery.app/auth/session.json

# Windows (PowerShell)
Get-Content "$env:APPDATA\com.mastery.app\auth\session.json"

# Linux
cat ~/.local/share/com.mastery.app/auth/session.json
```

### Test Supabase Connection
```bash
# Using curl to test Supabase endpoint
curl -X POST "https://vfeovvfpivbqeziwinwz.supabase.co/auth/v1/token?grant_type=password" \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpassword"}'
```

## Expected Behavior Summary

### Successful Sign Up
1. User enters email/password
2. Account created in Supabase
3. Email verification sent (if enabled)
4. User sees "Check Your Email" screen
5. User can navigate to sign in

### Successful Sign In
1. User enters email/password
2. Session created and stored locally
3. User redirected to home page
4. User email displayed in UI
5. Protected features accessible

### Session Persistence
1. Session stored securely on device
2. Session loaded on app startup
3. User remains authenticated across restarts
4. No need to sign in again

### Sign Out
1. Session deleted locally
2. User redirected to sign-in page
3. Protected features inaccessible
4. Must sign in again to access app

## Next Steps After Testing

If all tests pass:
- ✅ User Story 1 (Email/Password Auth) is complete
- ✅ Ready to proceed with Phase 4 (OAuth on Mobile) or Phase 5 (OAuth on Desktop)

If tests fail:
- Check error messages in console/logs
- Verify Supabase configuration
- Check environment variables
- Review troubleshooting section above
