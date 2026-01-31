# Feature Specification: Meaning Graph

**Feature Branch**: `005-meaning-graph`
**Created**: 2026-01-31
**Status**: Draft
**Input**: User description: "Better Translations + Multiple Meanings (Meaning Graph) — Learn English words as concepts (meanings + usage), not as brittle 1:1 translations."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rich Translations with Alternatives (Priority: P1)

As a learner, when I view a vocabulary word, I want to see the best translation in my native language plus 2-3 alternatives, so I understand nuance and can pick the most accurate one for my context.

**Why this priority**: This is the foundational capability. Without rich translations, no other meaning-graph features can function. Every word must have structured meaning data before cue types or disambiguation can work.

**Independent Test**: Can be fully tested by viewing any vocabulary word's detail screen and verifying that a primary translation, alternatives, and an English definition are displayed. Delivers immediate value by replacing single-word translations with richer context.

**Acceptance Scenarios**:

1. **Given** a vocabulary word exists in the user's library, **When** the user opens the word detail screen, **Then** the system displays a primary translation in the user's native language, a one-line English definition, and up to 3 alternative translations.
2. **Given** a vocabulary word has multiple meanings, **When** the user views the word detail, **Then** each meaning is shown as a separate card with its own translation and English definition.
3. **Given** the user disagrees with the primary translation, **When** they tap "Edit", **Then** they can change the primary translation to their preferred wording and it persists across sessions.
4. **Given** the user wants to pin an alternative as primary, **When** they tap "Pin this meaning", **Then** the selected translation becomes the primary and is used in learning sessions.
5. **Given** a word has more than 3 alternative translations, **When** viewing alternatives, **Then** only the top 3 are shown with a "Show more" option.

---

### User Story 2 - Definition-Based Active Recall (Priority: P2)

As a learner progressing beyond beginner stage, I want learning prompts that start from an English definition or synonym so I can practice retrieving the word from meaning — the way I would need it in real conversation.

**Why this priority**: This is the core learning innovation. Once meanings are stored (P1), the system can generate definition cues (C→A) and synonym cues (D→A) that train active production rather than passive recognition.

**Independent Test**: Can be tested by starting a learning session with a word that has reached "growing" stage and verifying that definition-based and synonym-based prompts appear alongside translation prompts.

**Acceptance Scenarios**:

1. **Given** a learning card is in "new" stage, **When** the card appears in a session, **Then** only translation cues (native language→English) are presented.
2. **Given** a learning card has progressed to "growing" stage, **When** the card appears in a session, **Then** the system mixes in definition cues ("achieves results with minimal waste" → ?) and synonym cues alongside translation cues.
3. **Given** a learning card has reached "mature" stage, **When** the card appears in a session, **Then** definition cues and synonym cues are prioritized over translation cues.
4. **Given** a definition cue is shown, **When** the user reveals the answer, **Then** the target word is displayed along with the FSRS self-grading buttons (Again / Hard / Good / Easy).

---

### User Story 3 - Confusion/Disambiguation Prompts (Priority: P3)

As a learner, I want the app to challenge me with similar-looking words (e.g., "efficient" vs "effective" vs "fast") so I learn to distinguish them and avoid common mistakes.

**Why this priority**: Disambiguation builds on existing meanings (P1) and active recall (P2). It addresses a real pain point — false confidence from recognizing words without understanding boundaries — but requires the foundation of structured meanings first.

**Independent Test**: Can be tested by presenting a disambiguation prompt for a mature word and verifying that the user must choose between confusable options, with a short explanation shown after answering.

**Acceptance Scenarios**:

1. **Given** a learning card is mature and has known confusable neighbors, **When** the card appears in a session, **Then** the system occasionally presents a multiple-choice disambiguation prompt (e.g., "The team designed a more ___ workflow." with options: effective / efficient / fast).
2. **Given** a disambiguation prompt is answered correctly, **When** the answer is revealed, **Then** a short explanation reinforces why the chosen word is correct ("Correct — minimal waste of resources").
3. **Given** a disambiguation prompt is answered incorrectly, **When** the answer is revealed, **Then** a short explanation highlights the distinction ("Not quite — 'effective' means it works/achieves the goal, 'efficient' means minimal waste").
4. **Given** a word has no known confusable neighbors, **When** the card appears in a session, **Then** no disambiguation prompt is generated and other cue types are used instead.

---

### User Story 4 - Context Cloze Prompts (Priority: P4)

As a learner, I want fill-in-the-blank exercises using real example sentences so I practice using the word in context rather than in isolation.

**Why this priority**: Context cloze rounds out the multi-cue approach. It is lower priority because it requires example sentences to be available (from encounters or generated) and the core value is already delivered by P1-P3.

**Independent Test**: Can be tested by presenting a cloze prompt for a word that has associated encounter context, and verifying the blank is correctly placed and the answer can be revealed.

**Acceptance Scenarios**:

1. **Given** a vocabulary word has encounter context (original sentence), **When** the word appears in a session at growing or mature stage, **Then** a cloze prompt may be shown with the target word blanked out.
2. **Given** a cloze prompt is shown, **When** the user reveals the answer, **Then** the full sentence is displayed with the target word highlighted.
3. **Given** the user answers incorrectly or struggles, **When** a hint is shown, **Then** it provides a meaning-based hint (e.g., "This is about resource use, not just speed") rather than revealing the word.

---

### User Story 5 - Meaning Selection for Ambiguous Words (Priority: P5)

As a learner encountering an ambiguous word with multiple distinct meanings, I want to choose which meaning to learn first so I'm not overwhelmed.

**Why this priority**: This is an edge case that improves UX for ambiguous words but is not required for the core flow. Most words work fine with a single primary meaning.

**Independent Test**: Can be tested by adding an ambiguous word (e.g., "bank") and verifying the meaning picker appears, allows selection, and respects the user's choice in subsequent sessions.

**Acceptance Scenarios**:

1. **Given** a word has 2+ distinct meanings (not just translation variants), **When** the word is first added to learning, **Then** the system presents a "Pick your meaning" screen with a recommended default.
2. **Given** the meaning picker is shown, **When** the user selects a meaning, **Then** that meaning becomes the active learning focus and learning cards are created for it.
3. **Given** the user chose one meaning, **When** they later visit the word detail, **Then** they can activate additional meanings for learning.

---

### Edge Cases

- **Word with no available translations**: System shows English definition only and marks the translation as "Not available — add your own".
- **User edits a meaning that was auto-generated**: User's edit takes precedence; the original is preserved as a hidden fallback.
- **Meaning generation returns low-confidence results**: System marks these with a subtle indicator and prompts user to verify or edit.
- **Too many alternative translations**: Only top 3 displayed; remainder behind "Show more" tap.
- **Language toggle**: User can switch between native-language-only and English-only meaning display via a setting toggle.
- **Native language change**: If the user changes their native language, existing meanings with translations in the old language are preserved but new enrichments generate translations in the new language. Previously enriched words can be re-enriched on demand.
- **Word already in library gets new meanings from updated source**: New meanings are appended, existing pinned meanings are preserved.
- **No encounter context available for cloze**: System skips context cloze and uses other cue types instead.
- **Confusable set contains words not in the user's library**: Disambiguation prompts still work — unknown confusable words are shown as options but not tracked for learning.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST store multiple meanings per vocabulary word, each with a primary native-language translation, up to 5 alternative native-language translations, and a one-line English definition.
- **FR-017**: Users MUST be able to set their native language in settings. The system uses this language for all translations. German is the default. The set of supported native languages is determined by the translation services available in the backend fallback chain.
- **FR-002**: System MUST display one primary meaning by default, with additional meanings and alternatives accessible via expand/collapse UI.
- **FR-003**: Users MUST be able to edit any translation or English definition, with user edits taking precedence over auto-generated content.
- **FR-004**: Users MUST be able to pin an alternative translation as the primary translation for a given meaning.
- **FR-005**: System MUST support five cue types for learning sessions: translation cue (B→A), definition cue (C→A), synonym cue (D→A), context cloze, and disambiguation (multiple-choice between confusable words).
- **FR-006**: System MUST select cue types based on learning card maturity: new cards use translation cues only; growing cards include at least 30% non-translation cues (definition, synonym); mature cards include at least 60% non-translation cues (definition, synonym, disambiguation).
- **FR-007**: System MUST support disambiguation prompts that present a multiple-choice question with confusable word options and a short post-answer explanation.
- **FR-008**: System MUST preserve calm, timeboxed session behavior — meaning-graph features integrate into existing session flow without increasing session length or cognitive load.
- **FR-009**: System MUST show a "Pick your meaning" flow when a word has multiple distinct meanings (not translation variants), with a recommended default.
- **FR-010**: System MUST sync meaning data (translations, definitions, user edits, pins) through the existing sync mechanism.
- **FR-013**: System MUST maintain a rolling buffer of pre-enriched words (target: ~10 words with full meaning data ready). After import or when buffer falls below threshold, the system enriches the next batch in the background. Only enriched words are eligible for learning sessions.
- **FR-014**: System MUST NOT present a word in a learning session if its meaning data has not yet been generated. Un-enriched words remain in the library but are excluded from session scheduling until enriched.
- **FR-015**: Meaning generation MUST happen server-side (backend) with a fallback chain: primary AI/LLM service → translation API (e.g., DeepL or Google Cloud Translation) → extraction from encounter context (original sentence from source material). If all services fail, the word remains un-enriched and is retried on the next background cycle.
- **FR-016**: The app requires an active internet connection. Meaning generation, sync, and enrichment replenishment are online-only operations.
- **FR-011**: System MUST display short, practical explanations in disambiguation prompts using "Not the same as..." format rather than academic definitions.
- **FR-012**: System MUST support a language toggle allowing users to view meanings in their native language only, English only, or both.

### Key Entities

- **Meaning**: A distinct sense of a vocabulary word. Contains a primary native-language translation, alternative translations, a one-line English definition, an optional extended definition, the language code of the translation, and a confidence score. Linked to one Vocabulary entry; a Vocabulary may have multiple Meanings.
- **Cue**: A prompt trigger for a learning session. Types: translation, definition, synonym, context_cloze, disambiguation. Each Cue belongs to one Meaning.
- **ConfusableSet**: A group of related words that learners commonly confuse (e.g., efficient/effective/fast). Contains the words, a distinguishing explanation per word, and optional example sentences.
- **MeaningEdit**: A record of user edits to auto-generated meaning data, preserving the original value and the user's override.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users who reach "mature" stage on a word can correctly answer definition-based cues (C→A) at a rate of 70% or higher after 14 days.
- **SC-002**: Users encounter fewer than 15% confusion errors on disambiguation prompts for words they have studied for 7+ days.
- **SC-003**: Fewer than 20% of words in a user's library require manual translation edits (indicating auto-generated translations are sufficiently accurate).
- **SC-004**: 80% of users who complete 5+ learning sessions report that they feel more confident using vocabulary words in conversation (measured via optional in-app prompt).
- **SC-005**: Users can view a word's full meaning details (all translations, definitions, alternatives) within 2 taps from the library screen.
- **SC-006**: Session duration remains within the existing timeboxed limits — adding meaning-graph cues does not increase average session length by more than 10%.

## Clarifications

### Session 2026-01-31

- Q: How should existing vocabulary (imported before this feature) get meaning data? → A: Rolling buffer strategy — maintain ~10 pre-enriched words ready at all times. Enrich first ~10 after import in background; replenish automatically as user consumes enriched words. Caps AI cost while ensuring zero-latency access. Un-enriched words are excluded from learning sessions until enriched.
- Q: What happens when meaning generation fails (service unavailable, error)? → A: App is online-required (constitution updated). Backend uses a fallback chain: primary AI service → translation API (DeepL/Google) → encounter context extraction. Failed words stay un-enriched and are retried on next background cycle. No offline fallback needed.
- Q: What do "mix" and "prioritize" mean for cue type selection by maturity? → A: Soft ranges — new = translation cues only; growing = at least 30% non-translation cues (definition, synonym); mature = at least 60% non-translation cues (definition, synonym, disambiguation).
- Q: How are disambiguation prompt outcomes mapped to FSRS ratings? → A: Correct answer maps to `ReviewRating.good`; incorrect answer maps to `ReviewRating.again`. The review then flows through the existing FSRS scheduling pipeline unchanged.
- Q: Should native language be configurable or hardcoded to German? → A: Configurable. Users set their native language in settings (default: German). All translations are generated in the user's chosen language. Supported languages determined by backend translation service coverage.

## Assumptions

- The system generates meaning data (translations, definitions, confusable sets) server-side via a fallback chain: primary AI/LLM service → translation API (DeepL or Google Cloud Translation) → encounter context extraction. Generation uses a rolling buffer strategy: after import, the first ~10 words are enriched in the background; as the user consumes enriched words (learns or views them), the system replenishes the buffer automatically. This caps AI cost while ensuring zero-latency access for the user.
- The app requires an active internet connection (online-required architecture). Local SQLite caches data for performance, not for offline use.
- The user's native language is configurable (default: German). Supported languages are determined by backend translation service coverage (DeepL supports 33 languages; Google Cloud Translation supports 130+). Translations are generated in whichever native language the user has selected.
- Confusable sets are pre-defined or generated per word, not crowd-sourced. Confusable explanations are generated in the user's native language.
- The FSRS scheduling algorithm (already implemented) is reused as-is; cue type selection is an overlay on top of FSRS, not a replacement.
- Encounter context (original sentences from source material) is available for some words but not all. Context cloze prompts are only shown when encounter data exists.
- "New", "growing", and "mature" stages map to existing FSRS card states (learning, review with low stability, review with high stability). Exact thresholds are an implementation detail.
