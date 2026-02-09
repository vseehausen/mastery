# Mastery Chrome Extension

Double-click any word on any webpage to translate and learn it.

## Setup

```bash
pnpm install
cp .env.example .env  # Add your Supabase credentials
pnpm dev
```

## Tech Stack

- WXT (Chrome extension framework)
- Svelte 5
- Tailwind CSS v4
- Supabase (new publishable key format)

## Development

- `pnpm dev` - Start dev server with hot reload
- `pnpm build` - Build for production
- `pnpm test` - Run tests

Debugging: Open `chrome://extensions` → click "service worker" or inspect popup
