# Feature Specification: User Authentication

**Feature Branch**: `003-user-auth`  
**Created**: 2026-01-26  
**Status**: Draft  
**Input**: User description: "i want to add auth. i want to use supabase auth. email pw is good, but i want to use apple and google auth at least, ideally other important auth providers, too. as convenient as possible. then add auth to the app and desktop. at desktop i would see a browser link being generated and then a the user is forwarded back to the app."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Email/Password Authentication (Priority: P1)

A user creates an account using their email address and a password. They can sign in using these credentials on both mobile and desktop apps. The system validates credentials and maintains a secure session.

**Why this priority**: Email/password is the most universal authentication method and serves as the foundation for all other auth flows. It's essential for users who don't want to use third-party providers.

**Independent Test**: Can be fully tested by creating an account with email/password, signing in, and verifying the user session is established and maintained across app restarts.

**Acceptance Scenarios**:

1. **Given** a new user, **When** they provide a valid email and password, **Then** an account is created and they are automatically signed in
2. **Given** an existing user, **When** they provide correct email and password, **Then** they are signed in and can access the app
3. **Given** a user provides incorrect credentials, **When** they attempt to sign in, **Then** they receive a clear error message
4. **Given** a signed-in user, **When** they close and reopen the app, **Then** they remain signed in (session persists)
5. **Given** a signed-in user, **When** they sign out, **Then** they are returned to the sign-in screen and cannot access protected features

---

### User Story 2 - OAuth Authentication on Mobile (Priority: P2)

A user signs in to the mobile app using Apple Sign In or Google Sign In. The authentication flow is seamless and uses native platform capabilities. After successful authentication, the user is signed in and can access the app.

**Why this priority**: OAuth providers offer convenience and security benefits. Mobile platforms have native support for these providers, making the experience smooth.

**Independent Test**: Can be fully tested by selecting Apple or Google sign-in on mobile, completing the native authentication flow, and verifying the user is signed in.

**Acceptance Scenarios**:

1. **Given** a user on mobile, **When** they select Apple Sign In, **Then** the native Apple authentication flow is presented and upon completion they are signed in
2. **Given** a user on mobile, **When** they select Google Sign In, **Then** the native Google authentication flow is presented and upon completion they are signed in
3. **Given** a user cancels OAuth authentication, **When** they return to the app, **Then** they remain on the sign-in screen
4. **Given** a user successfully authenticates via OAuth, **When** they return to the app later, **Then** they remain signed in (session persists)

---

### User Story 3 - OAuth Authentication on Desktop (Priority: P2)

A user signs in to the desktop app using OAuth providers (Apple, Google, or others). The app generates a browser link, opens it in the default browser, and the user completes authentication there. Upon successful authentication, the browser redirects back to the desktop app, which completes the sign-in process.

**Why this priority**: Desktop apps require a different OAuth flow than mobile. The browser-based approach is standard for desktop applications and provides a secure authentication experience.

**Independent Test**: Can be fully tested by selecting an OAuth provider on desktop, verifying a browser link is generated and opened, completing authentication in the browser, and confirming the desktop app receives the authentication result and signs the user in.

**Acceptance Scenarios**:

1. **Given** a user on desktop, **When** they select an OAuth provider (Apple/Google), **Then** a browser link is generated and the default browser opens to the authentication page
2. **Given** the browser is open for authentication, **When** the user completes authentication, **Then** the browser redirects back to the desktop app
3. **Given** the browser redirects back to the app, **When** the app receives the authentication result, **Then** the user is signed in and the browser window closes or navigates to a success page
4. **Given** a user cancels authentication in the browser, **When** they return to the desktop app, **Then** they remain on the sign-in screen
5. **Given** authentication fails in the browser, **When** the user returns to the desktop app, **Then** they see an error message

---

### User Story 4 - Additional OAuth Providers (Priority: P3)

A user can sign in using additional OAuth providers beyond Apple and Google. The system supports other commonly used providers that offer similar convenience and security.

**Why this priority**: While Apple and Google cover most users, additional providers increase accessibility and user choice. This is a nice-to-have enhancement.

**Independent Test**: Can be fully tested by selecting an additional OAuth provider and verifying the authentication flow works identically to Apple/Google flows.

**Acceptance Scenarios**:

1. **Given** additional OAuth providers are configured, **When** a user selects one, **Then** the authentication flow works the same as Apple/Google (native on mobile, browser on desktop)
2. **Given** a user authenticates with an additional provider, **When** they sign in, **Then** their account is created or linked appropriately

---

### Edge Cases

- What happens when a user tries to sign in with an email that's already registered via OAuth?
- How does the system handle OAuth provider outages or service unavailability?
- What happens if the browser redirect fails on desktop (network issue, app closed)?
- How does the system handle expired authentication tokens?
- What happens when a user signs in with OAuth but their email is already registered with email/password?
- How does the system handle account linking when the same email is used across multiple providers?
- What happens if the desktop app is closed while the browser authentication is in progress?
- How does the system handle authentication when the device is offline?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to create accounts using email and password
- **FR-002**: System MUST validate email format and enforce password strength requirements
- **FR-003**: System MUST allow users to sign in using email and password credentials
- **FR-004**: System MUST support Apple Sign In on mobile platforms
- **FR-005**: System MUST support Google Sign In on mobile platforms
- **FR-006**: System MUST support Apple Sign In on desktop via browser-based OAuth flow
- **FR-007**: System MUST support Google Sign In on desktop via browser-based OAuth flow
- **FR-008**: Desktop app MUST generate browser links for OAuth authentication
- **FR-009**: Desktop app MUST open the default browser with the authentication link
- **FR-010**: Desktop app MUST handle browser redirects back to the app after authentication
- **FR-011**: System MUST support additional OAuth providers beyond Apple and Google
- **FR-012**: System MUST maintain user sessions across app restarts
- **FR-013**: System MUST allow users to sign out
- **FR-014**: System MUST protect authenticated routes and features from unauthenticated access
- **FR-015**: System MUST handle authentication errors gracefully with clear user-facing messages
- **FR-016**: System MUST handle account linking when the same email is used across multiple authentication methods

### Key Entities

- **User Account**: Represents an authenticated user, containing: unique identifier, email address, authentication method(s), account creation timestamp, and last sign-in timestamp
- **Authentication Session**: Represents an active user session, containing: user identifier, session token, expiration time, and device/platform information

## Assumptions

- Supabase Auth handles token management, refresh, and security best practices
- OAuth providers (Apple, Google) are configured in Supabase dashboard
- Desktop app can register custom URL scheme or deep link handler for browser redirects
- Mobile platforms support native OAuth SDKs for Apple and Google
- Additional OAuth providers will be selected based on common usage patterns (e.g., GitHub, Microsoft, Facebook)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create an account with email/password in under 1 minute
- **SC-002**: Users can sign in with email/password in under 10 seconds
- **SC-003**: Users can complete OAuth authentication on mobile in under 30 seconds
- **SC-004**: Users can complete OAuth authentication on desktop (including browser flow) in under 1 minute
- **SC-005**: 95% of authentication attempts succeed on first try
- **SC-006**: User sessions persist across app restarts for at least 7 days
- **SC-007**: Authentication errors are displayed to users within 2 seconds of occurrence
- **SC-008**: Desktop browser redirect back to app succeeds in 100% of successful authentication cases
- **SC-009**: Users can sign out and return to sign-in screen in under 2 seconds
