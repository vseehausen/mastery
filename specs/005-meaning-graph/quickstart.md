# Quickstart: Meaning Graph Development

**Feature**: 005-meaning-graph | **Branch**: `005-meaning-graph`

## Prerequisites

- Flutter 3.x + Dart 3.x
- Supabase CLI installed and linked to project
- OpenAI API key (for enrichment edge function)
- DeepL API key (for translation fallback)

## Setup

### 1. Environment Secrets

```bash
# Set API keys for the enrichment edge function
cd supabase
supabase secrets set OPENAI_API_KEY=<your-openai-key>
supabase secrets set DEEPL_API_KEY=<your-deepl-key>
supabase secrets set GOOGLE_TRANSLATE_API_KEY=<your-google-key>  # optional fallback
```

### 2. Database Migration

```bash
# Apply the new migration
cd supabase
supabase db push
```

This creates: `meanings`, `cues`, `confusable_sets`, `confusable_set_members`, `meaning_edits`, `enrichment_queue` tables and adds `native_language_code` + `meaning_display_mode` to `user_learning_preferences`.

### 3. Deploy Edge Function

```bash
cd supabase
supabase functions deploy enrich-vocabulary
```

### 4. Mobile Setup

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # Regenerate Drift code
flutter analyze  # Verify no issues
flutter test     # Run tests
```

## Key Files to Modify

### Backend
- `supabase/migrations/20260131000001_add_meaning_graph.sql` — New tables
- `supabase/functions/enrich-vocabulary/index.ts` — New enrichment function
- `supabase/functions/sync/index.ts` — Add new tables to push/pull

### Mobile - Data Layer
- `mobile/lib/data/database/tables.dart` — Add Drift table definitions
- `mobile/lib/data/database/database.dart` — Schema version 5 → 6, add migration
- `mobile/lib/data/repositories/meaning_repository.dart` — New
- `mobile/lib/data/repositories/enrichment_repository.dart` — New

### Mobile - Domain Layer
- `mobile/lib/domain/services/cue_selector.dart` — New: maturity-based cue selection
- `mobile/lib/domain/services/session_planner.dart` — Filter un-enriched cards, assign cue type
- `mobile/lib/domain/models/cue_type.dart` — New enum
- `mobile/lib/domain/models/planned_item.dart` — Add cueType field

### Mobile - Feature Layer
- `mobile/lib/features/learn/screens/session_screen.dart` — Dispatch to cue-type cards
- `mobile/lib/features/learn/widgets/` — New card widgets per cue type
- `mobile/lib/features/vocabulary/vocabulary_detail_screen.dart` — Add meaning cards
- `mobile/lib/features/vocabulary/presentation/widgets/meaning_card.dart` — New
- `mobile/lib/features/settings/language_setting.dart` — New

## Testing Strategy

### Unit Tests
- `CueSelector`: verify maturity thresholds, weight distribution, missing data handling
- `MeaningRepository`: CRUD operations, pin/edit logic
- `EnrichmentService`: mock API responses, test fallback chain
- `SessionPlanner` changes: verify un-enriched cards are filtered

### Widget Tests
- Each new cue card widget (definition, synonym, cloze, disambiguation)
- Meaning card expand/collapse
- Meaning editor (edit, pin)

### Integration Tests
- End-to-end enrichment flow: import word → trigger enrichment → verify meanings stored
- Session flow: enriched word appears with correct cue type based on maturity

## Common Commands

```bash
# Mobile development
cd mobile && flutter run                                    # Run app
cd mobile && flutter test                                   # All tests
cd mobile && flutter analyze                                # Lint check
cd mobile && dart run build_runner build --delete-conflicting-outputs  # Regen Drift

# Backend development
cd supabase && supabase functions serve enrich-vocabulary    # Local edge function
cd supabase && supabase db push                              # Push migrations
cd supabase && supabase functions deploy enrich-vocabulary   # Deploy

# Testing enrichment locally
curl -X POST http://localhost:54321/functions/v1/enrich-vocabulary/request \
  -H "Authorization: Bearer <user-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"native_language_code": "de", "batch_size": 2}'
```
