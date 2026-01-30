# Contract: Distractor Service

**Service**: `DistractorService`
**Location**: `mobile/lib/domain/services/distractor_service.dart`

## Purpose

Selects plausible wrong answers (distractors) for Recognition mode (MCQ). Distractors should be challenging enough to require actual recall, but not so similar that they cause confusion between legitimately distinct items.

## Interface

### `selectDistractors`

Selects N distractor items for a multiple-choice question.

**Input**:
```
targetItemId: String          # The correct answer's vocabulary ID
partOfSpeech: String?         # Optional POS filter (noun, verb, adj, etc.)
difficultyBucket: int         # 1-5 scale derived from FSRS difficulty
excludeIds: List<String>      # IDs to exclude (e.g., recently shown items, same session)
count: int = 3                # Number of distractors to return
```

**Output**:
```
List<Distractor>:
  - itemId: String            # Vocabulary item ID
  - surfaceForm: String       # The word/phrase shown to user
  - gloss: String             # Translation/definition shown after answer
```

**Algorithm**:

1. **Filter candidates** from vocabulary pool:
   - Exclude `targetItemId`
   - Exclude all `excludeIds`
   - Exclude items sharing same lemma or translation as target
   - Exclude items reviewed in current session (prevent "I just saw this")

2. **Prefer same POS** (if `partOfSpeech` provided):
   - First attempt: filter to matching POS
   - Fallback: if fewer than `count` candidates, relax POS constraint

3. **Match difficulty bucket** (±1 tolerance):
   - Primary: same `difficultyBucket` as target
   - Secondary: `difficultyBucket ± 1`
   - Tertiary: any bucket (if still insufficient candidates)

4. **Rank candidates**:
   - **Preferred**: Confusables with high embedding similarity to target (if embeddings available)
   - **Fallback**: Random selection from filtered bucket

5. **Return** top `count` distractors

## Selection Priority

```
1. Same POS + same difficulty + confusable (embedding similarity > 0.7)
2. Same POS + similar difficulty (±1) + confusable
3. Same POS + similar difficulty + random
4. Any POS + similar difficulty + random
5. Any available item (last resort)
```

## Constraints

- MUST return exactly `count` distractors (or fewer only if vocabulary pool is exhausted)
- MUST NOT return the target item
- MUST NOT return items with identical translation/gloss to target
- SHOULD prefer items the user has seen before (to test discrimination, not introduce new items as distractors)
- SHOULD avoid showing the same distractor twice in one session

## Dependencies

- `VocabularyRepository` (access to vocabulary pool)
- `LearningCardRepository` (access to user's learning history for "seen before" preference)
- Optional: Embedding service for confusable detection (MVP: random selection acceptable)

## MVP Simplification

For MVP, confusable detection via embeddings is optional. Acceptable MVP behavior:
- Filter by POS and difficulty bucket
- Random selection from filtered pool
- Track shown distractors per session to avoid repeats

## Example

```dart
// Target: "ephemeral" (adjective, difficulty bucket 4)
final distractors = await distractorService.selectDistractors(
  targetItemId: 'vocab-123',
  partOfSpeech: 'adjective',
  difficultyBucket: 4,
  excludeIds: ['vocab-456', 'vocab-789'], // shown this session
  count: 3,
);

// Returns:
// [
//   Distractor(itemId: 'vocab-234', surfaceForm: 'transient', gloss: 'lasting only a short time'),
//   Distractor(itemId: 'vocab-345', surfaceForm: 'perpetual', gloss: 'never ending'),
//   Distractor(itemId: 'vocab-567', surfaceForm: 'fleeting', gloss: 'passing swiftly'),
// ]
```

## Error Handling

- If vocabulary pool has fewer than `count` valid candidates: return all available (may be 0-2)
- If no candidates at all: return empty list (caller should fall back to Recall mode)
