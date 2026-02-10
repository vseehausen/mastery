# Supabase API Keys for Agents

## Key Format Changes (June 2025+)

Supabase is transitioning to a new API key format for improved security and developer experience.

### New API Key Types

| Type | Format | Privileges | Use Case |
|------|--------|------------|----------|
| **Publishable key** | `sb_publishable_...` | Low | Safe to expose: web pages, mobile apps, GitHub actions, CLIs, source code |
| **Secret keys** | `sb_secret_...` | Elevated | Backend only: servers, Edge Functions, admin panels, microservices |
| **anon** (legacy) | JWT (long lived) | Low | Same as publishable key (being phased out) |
| **service_role** (legacy) | JWT (long lived) | Elevated | Same as secret keys (being phased out) |

### For Agent Scripts

**Use `SUPABASE_PUBLISHABLE_KEY`** (new format: `sb_publishable_...`)
- Stored in `.env.local`
- Safe to use in scripts that don't need elevated privileges
- Works with all Supabase client libraries

**DO NOT hardcode**:
- Supabase URL
- API keys
- Always load from environment variables

### Key Differences from Legacy Keys

1. **Secret keys require explicit reveal** - Each access logged in Audit Log
2. **Instant revocation** - Deleting a key revokes it immediately
3. **Browser protection** - Secret keys blocked in browsers (HTTP 401)
4. **Realtime limitations** - 24hr connection limit without signed-in user
5. **Edge Functions** - **MUST deploy with `--no-verify-jwt`** flag for functions called from browser extensions with publishable keys
6. **Authorization header** - No longer accepts API keys, only user JWTs

### Edge Function Deployment

**CRITICAL**: When using the new publishable keys, Edge Functions MUST be deployed with `--no-verify-jwt`:

```bash
npx supabase functions deploy lookup-word --no-verify-jwt
npx supabase functions deploy enrich-vocabulary --no-verify-jwt
```

Without this flag, functions will fail with HTTP 401 when called with publishable keys from browser extensions.

### Migration Timeline

- **June 2025**: Early preview (opt-in)
- **July 2025**: Full launch (recommended to migrate)
- **November 2025**: Monthly migration reminders
- **Late 2026**: Legacy keys removed

## Environment Variables Required

```bash
SUPABASE_URL=https://[project-ref].supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_...  # Use this for scripts
SUPABASE_ANON_KEY=eyJ...  # Legacy, still works but deprecated
```

## Example Usage

```javascript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_PUBLISHABLE_KEY  // NOT SUPABASE_ANON_KEY
);
```

## Local Edge Function Debugging

### Quick Start

```bash
# 1. Start local Supabase (needs Docker)
npx supabase start

# 2. Serve functions with env file (in separate terminal)
npx supabase functions serve --env-file supabase/.env.local

# 3. Test with curl (get service role key from `npx supabase status`)
curl -X POST http://127.0.0.1:54321/functions/v1/enrich-vocabulary/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY_FROM_supabase_status>" \
  -d '{"native_language_code":"de","vocabulary_ids":["<ID>"],"batch_size":1}'

# 4. Check deployed function logs
npx supabase functions logs enrich-vocabulary --limit 50
```

### Key Details

- `--env-file supabase/.env.local` loads non-SUPABASE vars (OPENAI_API_KEY, DEEPL_API_KEY, etc.) — vars starting with `SUPABASE_` are auto-injected by the local stack and skipped from the env file
- Console output (`console.log`, `console.error`) prints directly to the terminal running `functions serve`
- For breakpoint debugging: `npx supabase functions serve --inspect-mode brk` + Chrome DevTools at `chrome://inspect`
- Local functions are accessible at `http://127.0.0.1:54321/functions/v1/{name}`

### Deployed Secrets

Edge Functions on the deployed Supabase project access secrets set via `npx supabase secrets set`. They do NOT read from `.env.local`. After adding a new third-party API key to `.env.local`, also run:

```bash
npx supabase secrets set KEY_NAME="value"
```

## Edge Function Code Patterns

- **One write path per business action.** If the same DB write exists as a function AND inline elsewhere, the copies will drift. Consolidate to one function, call it everywhere.
- **Typed outcomes over branch soup.** When resolution has multiple paths, return a discriminated union, then map once to response. Avoids duplicated response-building blocks.
- **User-scoped client by default.** Use `createSupabaseClient(req)` for user requests — RLS does the authz. Reserve `createServiceClient()` for server-to-server calls only.
- **Shared utilities in `_shared/`.** If two functions duplicate logic, extract to `_shared/`. Keep modules small and single-purpose.
- **Delete dead code immediately.** Unused functions add cognitive load and make refactors scary. Remove on sight.

## Testing Edge Functions

### Quick Start

```bash
# Unit tests (no local Supabase needed)
deno test --allow-all supabase/functions/tests/unit/

# All tests (requires local Supabase + functions serve)
npx supabase start
npx supabase functions serve --env-file supabase/.env.local --no-verify-jwt
deno test --allow-all supabase/functions/tests/

# Single function
deno test --allow-all supabase/functions/tests/enrich-vocabulary.test.ts

# Include external API tests (costs money, needs keys in .env.local)
RUN_API_TESTS=1 deno test --allow-all supabase/functions/tests/
```

### Writing Tests

- Unit tests go in `tests/unit/` — pure functions, no DB needed
- Integration tests go in `tests/<function-name>.test.ts`
- Use `helpers.ts` for shared utilities (`ensureTestUser`, `cleanupTestData`, skip guards)
- Integration tests must gracefully skip when local Supabase isn't running
- Use `sanitizeOps: false, sanitizeResources: false` for integration tests
- Pre-seed `global_dictionary` to avoid external API calls in tests

### Test Conventions

- All tests live in `supabase/functions/tests/` with `.test.ts` suffix
- Unit tests go in `tests/unit/`, integration tests go in `tests/`
- `helpers.ts` provides shared utilities: client factories, test user management, cleanup, skip guards
- `.env` contains local deterministic keys; `fixtures/` holds test data files
