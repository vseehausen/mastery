# Research: Meaning Graph

**Feature**: 005-meaning-graph | **Date**: 2026-01-31

## R1: AI Service for Meaning Generation

**Decision**: Use OpenAI API (GPT-4o-mini) as primary enrichment service, called from a Supabase Edge Function.

**Rationale**:
- Supabase Edge Functions natively support calling external APIs via `fetch()` with secrets management (`supabase secrets set OPENAI_API_KEY=...`)
- GPT-4o-mini provides the best cost/quality ratio for structured vocabulary data (translations, definitions, confusable sets) — significantly cheaper than GPT-4o or Claude while sufficient for this use case
- Structured output (JSON mode) ensures consistent response format for parsing
- The prompt can request all meaning data in a single call: primary translation, alternatives, English definition, synonyms, confusable words, and example sentences

**Alternatives considered**:
- **Anthropic Claude (Haiku)**: Comparable quality and cost, but OpenAI's structured JSON output mode is more mature and reliable for consistent data extraction
- **Supabase built-in AI inference**: Limited to embeddings and basic tasks; not suitable for complex multi-field vocabulary enrichment
- **Local LLM**: Would eliminate API costs but adds infrastructure complexity; violates YAGNI for this phase

## R2: Translation API Fallback Chain

**Decision**: Three-tier fallback: (1) OpenAI GPT-4o-mini → (2) DeepL API → (3) Encounter context extraction

**Rationale**:
- **Tier 1 (OpenAI)**: Generates full meaning graph in one call (translations + definitions + confusables + examples). Best quality.
- **Tier 2 (DeepL)**: If OpenAI fails or is rate-limited, DeepL provides high-quality German-English translations with glossary support. $20/1M chars. Supports 33 languages (covers the configurable native language requirement for European languages). Falls back to Google Cloud Translation for languages DeepL doesn't support (130+ languages, permanent 500K chars/month free tier).
- **Tier 3 (Context extraction)**: If both API services fail, extract a basic "meaning" from the word's encounter context (the original sentence from Kindle/source). This provides at minimum a usage example even without a proper translation.

**Alternatives considered**:
- **Google Cloud Translation only**: Cheaper but lower quality than DeepL for European languages
- **Amazon Translate**: 25% cheaper than Google but less accurate for the DE-EN pair
- **Microsoft Translator**: Comparable to Google; no compelling advantage

## R3: FSRS Maturity Stage Thresholds

**Decision**: Map FSRS card states to learning stages using stability as the primary metric:

| Learning Stage | FSRS Mapping | Cue Types |
|----------------|-------------|-----------|
| New | `state == 0` (new) or `state == 1` (learning) with `stability < 1.0` | Translation only |
| Growing | `state == 1` (learning) with `stability >= 1.0` or `state == 2` (review) with `stability < 21.0` | >=30% non-translation |
| Mature | `state == 2` (review) with `stability >= 21.0` | >=60% non-translation |

**Rationale**:
- `stability < 1.0` means the word is still in initial acquisition — only simple translation cues are appropriate
- `stability >= 1.0 and < 21.0` (roughly 1-21 days of expected retention) — the word is being consolidated, mix in definition/synonym cues
- `stability >= 21.0` (3+ weeks of retention) — the word is well-known enough to challenge with disambiguation and concept-level recall
- These thresholds are conservative; they can be tuned based on SC-001/SC-002 success metrics

**Alternatives considered**:
- **Using `reps` count**: Less reliable — reps don't reflect actual retention quality
- **Using `retrievability`**: Depends on time since last review; stability is a more stable (pun intended) measure of long-term knowledge

## R4: Cue Type Selection Algorithm

**Decision**: Weighted random selection within each maturity stage.

```
function selectCueType(card, hasMeaning, hasEncounterContext, hasConfusables):
  stage = getMaturityStage(card)

  if stage == NEW:
    return TRANSLATION

  candidates = []

  if stage == GROWING:
    candidates = [
      (TRANSLATION, 70),
      (DEFINITION, 15),
      (SYNONYM, 10),
      (CONTEXT_CLOZE, 5)  // only if hasEncounterContext
    ]

  if stage == MATURE:
    candidates = [
      (TRANSLATION, 20),
      (DEFINITION, 25),
      (SYNONYM, 20),
      (CONTEXT_CLOZE, 15),      // only if hasEncounterContext
      (DISAMBIGUATION, 20)       // only if hasConfusables
    ]

  // Remove unavailable cue types and redistribute weights
  filter out candidates where data is missing
  normalize weights to sum to 100
  return weighted random pick
```

**Rationale**:
- Weighted random prevents predictability (users would game deterministic patterns)
- Weights ensure the minimum non-translation thresholds from spec (30% growing, 60% mature) are met in expectation
- Missing data (no encounter context, no confusables) gracefully degrades by redistributing weight to available cue types

**Alternatives considered**:
- **Round-robin**: Too predictable; users would know what's coming
- **Strict fixed sequence**: Inflexible; doesn't adapt to missing data
- **ML-based selection**: Over-engineering for MVP; revisit based on telemetry data

## R5: Enrichment Buffer Strategy

**Decision**: Server-side enrichment queue with PostgreSQL table, triggered by client request.

**Flow**:
1. When vocabulary is imported (or user manually triggers), client calls `POST /enrich-vocabulary/request` with vocabulary IDs
2. Edge function checks how many words the user has enriched vs un-enriched
3. If enriched buffer < 10, picks next batch of un-enriched words (oldest first), calls AI/translation chain
4. Stores results in `meanings`, `cues`, `confusable_sets` tables
5. Returns enriched data to client (or client pulls via sync)
6. Client-side: after each learning session or vocabulary detail view, check buffer. If < threshold, trigger replenishment.

**Buffer parameters**:
- Target buffer size: 10 enriched words ready
- Replenishment trigger: buffer drops below 5
- Batch size per request: 5 words (balance between latency and cost)
- Max concurrent enrichment: 1 request at a time per user (prevent cost spikes)

**Rationale**:
- Server-side enrichment keeps API keys off the client
- Batch processing amortizes API call overhead
- Threshold-based trigger (< 5 remaining) with batch of 5 ensures buffer rarely hits 0
- Single concurrent request per user prevents runaway costs

**Alternatives considered**:
- **Client-side enrichment**: Would expose API keys; rejected
- **Background cron job**: Adds infrastructure complexity; user-triggered is simpler and respects YAGNI
- **Enrich all at once**: Too expensive; rejected per spec clarification

## R6: Enrichment Prompt Design

**Decision**: Single structured prompt returning all meaning data as JSON.

**Prompt template** (for OpenAI with JSON mode):

```
You are a vocabulary enrichment assistant for language learners.

Given an English word and optional context sentence, return a JSON object with:
- meanings: array of distinct senses (max 3), each with:
  - primary_translation: best translation in {native_language}
  - alternative_translations: up to 3 alternatives in {native_language}
  - english_definition: one-sentence plain English definition
  - synonyms: up to 3 English synonyms
  - part_of_speech: noun/verb/adjective/adverb/other
- confusables: array of commonly confused words (max 3), each with:
  - word: the confusable English word
  - explanation: one-sentence distinction in {native_language}
  - example_sentence: English sentence demonstrating correct usage
- confidence: 0.0-1.0 indicating overall confidence

Word: {word}
Stem: {stem}
Context: {context_sentence}
Native language: {native_language_code}
```

**Rationale**:
- Single call generates all data needed per word (cost-efficient)
- JSON mode ensures parseable output
- Context sentence from encounters improves translation accuracy
- Confidence score enables the "low-confidence" edge case from spec

## R7: Native Language Support

**Decision**: Store language code (ISO 639-1) in user preferences. Pass to enrichment service. DeepL supports 33 languages; for unsupported languages, fall through to Google Cloud Translation (130+ languages).

**Supported language tiers**:
- **Tier 1 (DeepL-supported)**: German, French, Spanish, Italian, Portuguese, Dutch, Polish, Russian, Japanese, Chinese, Korean, and 22 others — highest quality
- **Tier 2 (Google-only)**: Hindi, Swahili, Thai, Arabic, and 100+ others — good quality
- **Tier 3 (AI-only)**: Any language OpenAI supports but neither DeepL nor Google covers — acceptable quality, no dedicated translation fallback

**Rationale**: Covers the vast majority of language learners. German users (primary audience) get the best quality path. Other languages work with graceful degradation.
