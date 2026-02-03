# Mastery

**Your vocabulary shadow brain** — Learn words naturally from the books you read.

Mastery captures vocabulary from your Kindle highlights and transforms them into personalized learning sessions using spaced repetition and AI-powered enrichment.

## What It Does

### Capture
Connect your Kindle to the desktop agent and automatically import your vocabulary lookups — every word you've highlighted or looked up while reading.

### Enrich
Each word is automatically enriched with:
- **Translations** (DeepL/Google Translate to your native language)
- **Definitions** (clear English explanations)
- **Synonyms** (related words to expand your vocabulary)
- **Context** (the original sentence from your book)
- **Confusables** (commonly confused words with explanations)

### Learn
Practice with intelligent spaced repetition (FSRS algorithm) that adapts to your memory:
- **Multiple cue types**: translations, definitions, synonyms, fill-in-the-blank
- **Self-graded recall**: see the word, think of the meaning, reveal and grade yourself
- **Smart scheduling**: words appear just before you'd forget them
- **Progress tracking**: see your vocabulary grow over time

## Features

| Feature | Status |
|---------|--------|
| Kindle vocabulary import (USB) | ✅ Complete |
| User authentication (Apple/Google/Email) | ✅ Complete |
| AI-powered word enrichment | ✅ Complete |
| Spaced repetition learning (FSRS) | ✅ Complete |
| Multi-cue learning cards | ✅ Complete |
| Vocabulary library with search | ✅ Complete |
| Learning progress & streaks | ✅ Complete |
| German translations | ✅ Complete |
| Multi-language support | 🔜 Planned |
| Browser extension capture | 🔜 Planned |
| Social features | 🔜 Planned |

## How It Works

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Kindle    │────▶│   Desktop   │────▶│  Supabase   │
│  (vocab.db) │     │   Agent     │     │  (Backend)  │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────────────────┤
                    │                          │
                    ▼                          ▼
            ┌─────────────┐            ┌─────────────┐
            │  Enrichment │            │   Mobile    │
            │  (AI APIs)  │            │    App      │
            └─────────────┘            └─────────────┘
```

1. **Desktop Agent** reads vocabulary from your Kindle's `vocab.db` file
2. **Supabase Backend** stores vocabulary, encounters, and learning progress
3. **Enrichment Service** calls translation APIs and GPT-4o-mini for definitions
4. **Mobile App** displays your vocabulary and manages learning sessions

## Tech Stack

- **Mobile**: Flutter (iOS/Android)
- **Desktop**: Tauri (macOS/Windows/Linux)
- **Backend**: Supabase (PostgreSQL, Edge Functions, Auth)
- **AI**: OpenAI GPT-4o-mini, DeepL, Google Translate
- **Algorithm**: FSRS (Free Spaced Repetition Scheduler)

## Data Model

```
User
 └── Vocabulary (unique words)
      ├── Meanings (translations, definitions)
      │    └── Cues (learning prompts)
      ├── Encounters (context from books)
      │    └── Source (book metadata)
      └── LearningCard (FSRS state)
```

## Current State (February 2026)

The app is feature-complete for the core learning loop:

- **265+ test vocabulary words** imported and enriched
- **5 cue types** working: translation, definition, synonym, disambiguation, context cloze
- **Session optimization**: Single RPC call loads all session data
- **Production deployed** on Supabase with Apple/Google OAuth

### Recent Updates
- Optimized session loading from ~36 queries to 1 RPC call
- Added translation quality validation to prevent bad enrichment data
- Removed local SQLite — app is fully cloud-based with Riverpod caching

## Development

See [CLAUDE.md](./CLAUDE.md) for development guidelines, commands, and code style.

See [.specify/memory/constitution.md](./.specify/memory/constitution.md) for core principles.

```bash
# Mobile
cd mobile && flutter run

# Desktop
cd desktop && npm run tauri dev

# Backend
cd supabase && supabase functions serve
```

## License

Private — All rights reserved.
