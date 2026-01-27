# Tasks: User Authentication

**Input**: Design documents from `/specs/003-user-auth/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are not explicitly requested in the specification. Focus on implementation tasks with manual testing via acceptance scenarios.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile**: `mobile/lib/`
- **Desktop**: `desktop/src-tauri/src/` (Rust) and `desktop/src/` (TypeScript/Svelte)
- **Backend**: `supabase/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependency setup

- [x] T001 Configure Supabase Auth in Supabase Dashboard (enable email/password provider)
- [x] T002 [P] Add sign_in_with_apple dependency to mobile/pubspec.yaml
- [x] T003 [P] Add google_sign_in dependency to mobile/pubspec.yaml
- [x] T004 [P] Add @supabase/supabase-js dependency to desktop/package.json
- [x] T005 [P] Verify Supabase client configuration in mobile/lib/core/supabase_client.dart
- [x] T006 [P] Create desktop/src/lib/api/auth.ts file structure

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core authentication infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T007 Create desktop/src-tauri/src/auth/mod.rs module structure
- [x] T008 [P] Implement SupabaseAuth struct in desktop/src-tauri/src/auth/mod.rs with session storage
- [x] T009 [P] Add auth module to desktop/src-tauri/src/main.rs
- [x] T010 [P] Create desktop/src/lib/api/auth.ts with Supabase client initialization
- [x] T011 [P] Update mobile/lib/data/repositories/auth_repository.dart interface with OAuth method signatures
- [x] T012 [P] Update mobile/lib/data/repositories/auth_repository_impl.dart with OAuth method stubs

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Email/Password Authentication (Priority: P1) 🎯 MVP

**Goal**: Users can create accounts and sign in using email and password on both mobile and desktop apps. Sessions persist across app restarts.

**Independent Test**: Create an account with email/password, sign in, close and reopen app, verify session persists. Sign out and verify access is revoked.

### Implementation for User Story 1

#### Mobile (Flutter)

- [x] T013 [US1] Implement signUpWithEmail method in mobile/lib/data/repositories/auth_repository_impl.dart
- [x] T014 [US1] Implement signInWithEmail method in mobile/lib/data/repositories/auth_repository_impl.dart
- [x] T015 [US1] Implement signOut method in mobile/lib/data/repositories/auth_repository_impl.dart
- [x] T016 [US1] Create mobile/lib/features/auth/sign_in_screen.dart UI
- [x] T017 [US1] Create mobile/lib/features/auth/sign_up_screen.dart UI
- [x] T018 [US1] Add email and password validation in sign up screen
- [x] T019 [US1] Add error handling and user feedback in auth screens
- [x] T020 [US1] Create mobile/lib/features/auth/auth_guard.dart for route protection
- [x] T021 [US1] Integrate auth guard in mobile app routing

#### Desktop (Tauri)

- [x] T022 [US1] Implement auth_sign_up_with_email Tauri command in desktop/src-tauri/src/auth/mod.rs
- [x] T023 [US1] Implement auth_sign_in_with_email Tauri command in desktop/src-tauri/src/auth/mod.rs
- [x] T024 [US1] Implement auth_sign_out Tauri command in desktop/src-tauri/src/auth/mod.rs
- [x] T025 [US1] Implement auth_get_session Tauri command in desktop/src-tauri/src/auth/mod.rs
- [x] T026 [US1] Implement auth_get_current_user Tauri command in desktop/src-tauri/src/auth/mod.rs
- [x] T027 [US1] Register auth commands in desktop/src-tauri/src/main.rs invoke_handler
- [x] T028 [US1] Implement signUpWithEmail function in desktop/src/lib/api/auth.ts
- [x] T029 [US1] Implement signInWithEmail function in desktop/src/lib/api/auth.ts
- [x] T030 [US1] Implement signOut function in desktop/src/lib/api/auth.ts
- [x] T031 [US1] Implement getSession function in desktop/src/lib/api/auth.ts
- [x] T032 [US1] Create desktop/src/routes/auth/sign-in/+page.svelte UI
- [x] T033 [US1] Create desktop/src/routes/auth/sign-up/+page.svelte UI
- [x] T034 [US1] Add email and password validation in sign up page
- [x] T035 [US1] Add error handling and user feedback in auth pages
- [x] T036 [US1] Implement session persistence in desktop/src-tauri/src/auth/mod.rs (store refresh token)
- [x] T037 [US1] Implement session restoration on app startup in desktop/src-tauri/src/auth/mod.rs
- [x] T038 [US1] Create auth guard in desktop/src/routes/+layout.svelte
- [x] T039 [US1] Protect authenticated routes in desktop app

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently. Users can sign up, sign in, and sign out on both platforms with persistent sessions.

---

## Phase 4: User Story 2 - OAuth Authentication on Mobile (Priority: P2)

**Goal**: Users can sign in to the mobile app using Apple Sign In or Google Sign In with native platform capabilities.

**Independent Test**: Select Apple or Google sign-in on mobile, complete native authentication flow, verify user is signed in. Close and reopen app, verify session persists.

### Implementation for User Story 2

- [ ] T040 [US2] Configure Apple Sign In in Apple Developer Console (App ID, Service ID, private key) **MANUAL**
- [ ] T041 [US2] Configure Apple Sign In in Supabase Dashboard with credentials **MANUAL**
- [ ] T042 [US2] Configure Google Sign In in Google Cloud Console (OAuth credentials) **MANUAL**
- [ ] T043 [US2] Configure Google Sign In in Supabase Dashboard with credentials **MANUAL**
- [ ] T044 [US2] Add Apple Sign In capability to mobile/ios/Runner.xcodeproj **MANUAL - requires Xcode**
- [x] T045 [US2] Configure Google Sign In URL scheme in mobile/ios/Runner/Info.plist
- [ ] T046 [US2] Configure Google Sign In in mobile/android/app/build.gradle **MANUAL - needs google-services.json**
- [x] T047 [US2] Implement signInWithApple method in mobile/lib/data/repositories/auth_repository_impl.dart
- [x] T048 [US2] Implement signInWithGoogle method in mobile/lib/data/repositories/auth_repository_impl.dart
- [x] T049 [US2] Add signInWithApple method signature to mobile/lib/domain/repositories/auth_repository.dart
- [x] T050 [US2] Add signInWithGoogle method signature to mobile/lib/domain/repositories/auth_repository.dart
- [x] T051 [US2] Add Apple Sign In button to mobile/lib/features/auth/sign_in_screen.dart
- [x] T052 [US2] Add Google Sign In button to mobile/lib/features/auth/sign_in_screen.dart
- [x] T053 [US2] Handle OAuth cancellation in mobile auth screens
- [x] T054 [US2] Add error handling for OAuth failures in mobile auth screens

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently. Mobile users can authenticate via email/password or OAuth providers.

---

## Phase 5: User Story 3 - OAuth Authentication on Desktop (Priority: P2)

**Goal**: Users can sign in to the desktop app using OAuth providers via browser-based flow with deep link redirects.

**Independent Test**: Select OAuth provider on desktop, verify browser opens, complete authentication, verify redirect back to app, verify user is signed in.

### Implementation for User Story 3

- [x] T055 [US3] Register custom URL scheme (mastery://) in desktop/src-tauri/tauri.conf.json
- [ ] T056 [US3] Configure OAuth redirect URLs in Supabase Dashboard (mastery://auth/callback) **MANUAL**
- [x] T057 [US3] Implement deep link handler in desktop/src-tauri/src/main.rs setup
- [x] T058 [US3] Implement auth_sign_in_with_oauth Tauri command in desktop/src-tauri/src/auth/mod.rs
- [x] T059 [US3] Implement auth_on_oauth_callback Tauri command in desktop/src-tauri/src/auth/mod.rs
- [x] T060 [US3] Register OAuth commands in desktop/src-tauri/src/main.rs invoke_handler
- [x] T061 [US3] Implement signInWithOAuth function in desktop/src/lib/api/auth.ts
- [x] T062 [US3] Implement handleOAuthCallback function in desktop/src/lib/api/auth.ts
- [x] T063 [US3] Add Apple Sign In button to desktop/src/routes/auth/sign-in/+page.svelte
- [x] T064 [US3] Add Google Sign In button to desktop/src/routes/auth/sign-in/+page.svelte
- [x] T065 [US3] Implement browser opening logic in desktop/src/lib/api/auth.ts (use Tauri opener plugin)
- [x] T066 [US3] Handle OAuth callback URL parsing in desktop/src/lib/api/auth.ts
- [x] T067 [US3] Handle OAuth cancellation in desktop auth pages
- [x] T068 [US3] Add error handling for OAuth failures in desktop auth pages
- [x] T069 [US3] Add loading state during OAuth flow in desktop UI

**Checkpoint**: At this point, User Stories 1, 2, AND 3 should all work independently. Desktop users can authenticate via email/password or OAuth providers with browser flow.

---

## Phase 6: User Story 4 - Additional OAuth Providers (Priority: P3) - SKIPPED

**Status**: Skipped for now. Only Apple and Google OAuth implemented per user request.

### Implementation for User Story 4

- [ ] T070 [US4] Configure GitHub OAuth in GitHub Developer Settings
- [ ] T071 [US4] Configure GitHub OAuth in Supabase Dashboard
- [ ] T072 [US4] Configure Microsoft OAuth in Azure Portal
- [ ] T073 [US4] Configure Microsoft OAuth in Supabase Dashboard
- [ ] T074 [US4] Add signInWithGitHub method to mobile/lib/data/repositories/auth_repository_impl.dart
- [ ] T075 [US4] Add signInWithMicrosoft method to mobile/lib/data/repositories/auth_repository_impl.dart
- [ ] T076 [US4] Add GitHub Sign In button to mobile/lib/features/auth/sign_in_screen.dart
- [ ] T077 [US4] Add Microsoft Sign In button to mobile/lib/features/auth/sign_in_screen.dart
- [ ] T078 [US4] Add GitHub Sign In button to desktop/src/routes/auth/sign-in/+page.svelte
- [ ] T079 [US4] Add Microsoft Sign In button to desktop/src/routes/auth/sign-in/+page.svelte
- [ ] T080 [US4] Verify account linking works for additional providers (same email)

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T081 [P] Clean up debug logging in desktop/src-tauri/src/auth/mod.rs
- [x] T082 [P] Clean up debug logging in desktop/src-tauri/src/kindle/mod.rs
- [x] T083 [P] Clean up debug logging in desktop/src-tauri/src/vocab/mod.rs
- [x] T084 [P] Clean up debug logging in desktop/src-tauri/src/main.rs
- [x] T085 [P] Clean up TypeScript auth API (remove unused Supabase client)
- [x] T086 [P] Improve error messages for common auth failures (invalid credentials, network errors)
- [x] T087 [P] Add loading states during authentication operations
- [x] T088 [P] Mobile auth guard and session restoration on startup
- [x] T089 [P] Desktop auth guard and session check on page load
- [x] T090 [P] Password reset functionality in mobile app
- [x] T091 [P] Fix Rust compilation warnings (unused imports, visibility)
- [x] T092 [P] Fix Flutter lint warnings in auth screens
- [ ] T093 [P] Run quickstart.md validation steps **MANUAL**
- [ ] T094 [P] Configure OAuth providers in Supabase Dashboard **MANUAL**

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Depends on US1 for shared auth infrastructure
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Depends on US1 for shared auth infrastructure, independent of US2
- **User Story 4 (P3)**: Can start after US2 and US3 - Uses same OAuth patterns, just different providers

### Within Each User Story

- Mobile and Desktop implementations can be done in parallel (different files)
- UI screens depend on repository/service layer
- Auth guards depend on auth state management
- Session persistence should be implemented early in each story

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes:
  - US1 Mobile and US1 Desktop can run in parallel
  - US2 and US3 can start in parallel after US1 (they're independent)
- Mobile and Desktop implementations within a story can run in parallel
- Different OAuth providers can be configured in parallel

---

## Parallel Example: User Story 1

```bash
# Mobile and Desktop can be implemented in parallel:

# Mobile tasks (can run together):
- T013-T021: Mobile auth repository, UI screens, auth guard

# Desktop tasks (can run together):
- T022-T039: Desktop auth commands, API functions, UI pages, auth guard

# These are independent - different files, no conflicts
```

---

## Parallel Example: User Story 2 & 3

```bash
# US2 (Mobile OAuth) and US3 (Desktop OAuth) can run in parallel:

# US2 Mobile tasks:
- T040-T054: Configure providers, implement mobile OAuth methods, add UI buttons

# US3 Desktop tasks:
- T055-T069: Configure deep links, implement desktop OAuth flow, add UI buttons

# These are independent - different platforms, different files
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Email/Password on Mobile + Desktop)
4. **STOP and VALIDATE**: Test User Story 1 independently
   - Sign up with email/password
   - Sign in with email/password
   - Verify session persists across app restarts
   - Sign out and verify access revoked
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo (Mobile OAuth)
4. Add User Story 3 → Test independently → Deploy/Demo (Desktop OAuth)
5. Add User Story 4 → Test independently → Deploy/Demo (Additional Providers)
6. Polish phase → Final improvements

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 Mobile
   - Developer B: User Story 1 Desktop
3. Once US1 is complete:
   - Developer A: User Story 2 (Mobile OAuth)
   - Developer B: User Story 3 (Desktop OAuth)
4. Developer C: User Story 4 (Additional Providers) - can start after US2/US3
5. All developers: Polish phase

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Mobile and Desktop implementations are independent within each story
- OAuth provider configuration can be done in parallel
- Session persistence is critical - test thoroughly
- Auth guards protect routes - ensure they work correctly
- Error handling should be user-friendly and informative
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
