# API Contract: enrich-vocabulary

**Edge Function**: `supabase/functions/enrich-vocabulary/index.ts`
**Auth**: Required (Supabase JWT)

## Endpoints

### POST /enrich-vocabulary/request

Trigger enrichment for a batch of vocabulary words. The server processes up to `batch_size` words using the AI/translation fallback chain and returns the results.

**Request**:
```json
{
  "vocabulary_ids": ["uuid-1", "uuid-2", "..."],
  "native_language_code": "de",
  "batch_size": 5
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| vocabulary_ids | string[] | No | Specific words to enrich (bypasses buffer logic, enriches these exact words). If omitted, server picks the next un-enriched words by priority using the rolling buffer strategy. |
| native_language_code | string | Yes | ISO 639-1 code for translations |
| batch_size | number | No | Max words to process (default: 5, max: 10) |

**Response (200)**:
```json
{
  "enriched": [
    {
      "vocabulary_id": "uuid-1",
      "word": "efficient",
      "meanings": [
        {
          "id": "meaning-uuid-1",
          "primary_translation": "effizient",
          "alternative_translations": ["leistungsfähig", "ressourcenschonend"],
          "english_definition": "Achieves results with minimal waste of time or resources.",
          "extended_definition": null,
          "part_of_speech": "adjective",
          "synonyms": ["productive", "effective", "streamlined"],
          "confidence": 0.95,
          "is_primary": true,
          "sort_order": 0,
          "source": "ai",
          "cues": [
            {
              "id": "cue-uuid-1",
              "cue_type": "translation",
              "prompt_text": "effizient",
              "answer_text": "efficient",
              "hint_text": null,
              "metadata": {}
            },
            {
              "id": "cue-uuid-2",
              "cue_type": "definition",
              "prompt_text": "Achieves results with minimal waste of time or resources.",
              "answer_text": "efficient",
              "hint_text": "Think about resource usage, not speed.",
              "metadata": {}
            },
            {
              "id": "cue-uuid-3",
              "cue_type": "synonym",
              "prompt_text": "Productive and streamlined with minimal waste",
              "answer_text": "efficient",
              "hint_text": null,
              "metadata": {}
            }
          ]
        }
      ],
      "confusable_set": {
        "id": "confusable-uuid-1",
        "words": ["efficient", "effective", "fast"],
        "explanations": {
          "efficient": "Minimal waste of resources",
          "effective": "Achieves the desired goal",
          "fast": "High speed only"
        },
        "example_sentences": {
          "efficient": "The new process is extremely efficient.",
          "effective": "The medicine was effective against the infection.",
          "fast": "She is a fast runner."
        }
      }
    }
  ],
  "failed": [
    {
      "vocabulary_id": "uuid-3",
      "error": "All enrichment services unavailable",
      "will_retry": true
    }
  ],
  "buffer_status": {
    "enriched_count": 12,
    "un_enriched_count": 488,
    "buffer_target": 10
  }
}
```

**Response (401)**: Unauthorized
**Response (429)**: Rate limited (max 1 concurrent request per user)
**Response (500)**: Internal error

### GET /enrich-vocabulary/status

Check enrichment buffer status for the current user.

**Response (200)**:
```json
{
  "enriched_count": 12,
  "un_enriched_count": 488,
  "buffer_target": 10,
  "pending_in_queue": 0,
  "needs_replenishment": false
}
```

## Modified Endpoint: sync/pull

Add new tables to the pull response:

**Additional fields in response**:
```json
{
  "...existing fields...",
  "meanings": [...],
  "cues": [...],
  "confusable_sets": [...],
  "confusable_set_members": [...],
  "meaning_edits": [...]
}
```

## Modified Endpoint: sync/push

Accept changes for new tables in the push request:

**Additional supported tables**: `meanings`, `cues`, `confusable_sets`, `confusable_set_members`, `meaning_edits`

These follow the same push pattern as existing tables (insert/upsert/update/delete with last-write-wins conflict resolution).

## Error Handling

| Scenario | Behavior |
|----------|----------|
| OpenAI API failure | Fall through to DeepL |
| DeepL API failure | Fall through to Google Cloud Translation |
| Google API failure | Fall through to encounter context extraction |
| All services fail | Mark word as `failed` in enrichment_queue, retry on next request (max 3 attempts) |
| Rate limit hit | Return 429 to client; client retries after delay |
| Invalid vocabulary_id | Skip, include in `failed` array |
| User has no un-enriched words | Return empty `enriched` array with buffer_status |

## Fallback Quality Levels

| Source | Generates | Quality |
|--------|-----------|---------|
| OpenAI (Tier 1) | Full meaning graph: translations, definition, synonyms, confusables, cues | Best |
| DeepL (Tier 2) | Primary translation + alternatives only; definition from word stem; no confusables | Good |
| Google (Tier 2b) | Same as DeepL but for languages DeepL doesn't support | Good |
| Context (Tier 3) | Extract word usage from encounter sentence; no structured translation | Minimal |

When Tier 2 or 3 is used, `meaning.confidence` is set lower (0.6 for Tier 2, 0.3 for Tier 3) and the `source` field reflects the service used.
