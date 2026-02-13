# Feature Specification: Word Audio

**Feature Branch**: `008-word-audio`
**Created**: 2026-02-13
**Status**: Draft
**Input**: User description: "Audio for vocabulary words — generation (backend TTS) and playback (Flutter client)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Audio plays on answer reveal (Priority: P1)

A learner is in a session reviewing vocabulary. When they reveal the answer on a recall card (tap to flip) or select the correct answer on a recognition card (MC/binary), the pronunciation of the target word plays automatically. This reinforces the auditory memory of the word alongside the visual.

**Why this priority**: Audio on reveal is the core value — hearing the word at the moment of retrieval strengthens memory encoding. Without this, the feature has no purpose.

**Independent Test**: Start a session, answer any card. Audio plays immediately on answer reveal without noticeable delay.

**Acceptance Scenarios**:

1. **Given** a recall card is displayed and audio is enabled, **When** the user taps to reveal the answer, **Then** the word's pronunciation audio plays automatically
2. **Given** a recognition card is displayed and audio is enabled, **When** the user selects the correct answer and it highlights, **Then** the word's pronunciation audio plays automatically
3. **Given** a recognition card is displayed and audio is enabled, **When** the user selects an incorrect answer, **Then** no audio plays until the correct answer is shown
4. **Given** audio is enabled and a session is in progress, **When** audio plays on reveal, **Then** there is no perceptible delay (audio was prefetched)

---

### User Story 2 - Audio generated for every word (Priority: P1)

When a new word is enriched through the pipeline, the system automatically generates a TTS audio file for the word's lemma and stores it. This happens as part of the existing enrichment flow — no manual trigger needed.

**Why this priority**: Without generated audio files, playback has nothing to play. This is a hard dependency for all other stories.

**Independent Test**: Add a new word, trigger enrichment, verify an audio file exists in storage for that word's lemma.

**Acceptance Scenarios**:

1. **Given** a new word enters the enrichment pipeline, **When** enrichment completes, **Then** an audio file of the lemma pronunciation is stored and the word's record references it
2. **Given** the enrichment pipeline re-enriches a stale word, **When** the word already has audio, **Then** audio is regenerated (to match any lemma changes)
3. **Given** the enrichment pipeline re-enriches a stale word, **When** the lemma hasn't changed and audio exists, **Then** existing audio is reused (no redundant generation)

---

### User Story 3 - Manual replay via speaker icon (Priority: P2)

After the answer is revealed, a small speaker icon appears next to the word. The user can tap it to replay the pronunciation. This is optional and unobtrusive — the icon is minimal and doesn't add visual noise.

**Why this priority**: Replay supports deliberate practice but is secondary to auto-play on reveal. The feature works without it; this enhances it.

**Independent Test**: After revealing an answer, tap the speaker icon. Audio replays.

**Acceptance Scenarios**:

1. **Given** the answer side of a card is visible, **When** the user looks at the word, **Then** a small speaker icon is visible next to it
2. **Given** the answer side is visible, **When** the user taps the speaker icon, **Then** the word's audio plays again
3. **Given** audio is disabled in settings, **When** the answer side is visible, **Then** no speaker icon appears

---

### User Story 4 - Audio toggle in settings (Priority: P2)

A single toggle in the settings screen lets the user enable or disable word audio. It defaults to on. When off, no audio plays during sessions and no speaker icon appears.

**Why this priority**: Users need control over audio (e.g., studying in quiet environments). Simple toggle with a sensible default.

**Independent Test**: Toggle audio off in settings, start a session, verify no audio plays and no speaker icon shows. Toggle back on, verify audio resumes.

**Acceptance Scenarios**:

1. **Given** a new user opens settings, **When** they view the learning section, **Then** the audio toggle is visible and defaulted to on
2. **Given** audio is toggled off, **When** the user completes a card in a session, **Then** no audio plays and no speaker icon is visible
3. **Given** audio is toggled on after being off, **When** the user starts a new session, **Then** audio plays on reveal as expected

---

### User Story 5 - Prefetch and local caching (Priority: P2)

Audio files are downloaded and cached locally during session pre-population so there is zero latency when a card is revealed. Subsequent sessions reuse cached files.

**Why this priority**: Latency-free playback is essential for the experience to feel polished. Without caching, network delays would make audio feel broken.

**Independent Test**: Start a session while offline (after having loaded it once). Audio still plays from cache.

**Acceptance Scenarios**:

1. **Given** a session is being pre-populated, **When** audio is enabled, **Then** audio files for all session cards are downloaded in the background
2. **Given** an audio file was previously cached, **When** the same word appears in a later session, **Then** the cached file is used without re-downloading
3. **Given** prefetch is in progress, **When** the user starts answering cards, **Then** card interaction is not blocked by audio loading

---

### Edge Cases

- What happens when a word has no audio file (enrichment failed or TTS unavailable)? Silent — card works normally without audio.
- What happens when the device is on a slow/offline connection during prefetch? Prefetch fails silently; cards work without audio. Cached files from previous sessions still play.
- What happens when the user has device volume muted or on silent mode? Audio respects device volume settings. No special handling needed.
- What happens when audio is playing and the user quickly navigates to the next card? Current audio stops; next card's audio takes priority.
- What happens if two audio files would play simultaneously (rapid card advancement)? Previous playback is cancelled before new one starts.
- What happens when the maintenance endpoint re-enriches words? Audio is regenerated only if the lemma changed; otherwise existing audio is preserved.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST generate a pronunciation audio file for each word's lemma during enrichment
- **FR-002**: System MUST store audio files in persistent cloud storage accessible via URL
- **FR-003**: System MUST record the audio file location on the word's dictionary record
- **FR-004**: System MUST auto-play the word's audio when the answer is revealed on any card type
- **FR-005**: System MUST prefetch audio files for all session cards during session pre-population
- **FR-006**: System MUST cache audio files locally on the device for offline and instant playback
- **FR-007**: System MUST display a speaker icon next to the word on the answer side for manual replay
- **FR-008**: System MUST provide a toggle in the learning settings to enable/disable audio (default: on)
- **FR-009**: System MUST NOT block card rendering or user interaction if audio is unavailable or loading
- **FR-010**: System MUST cancel in-progress audio playback when advancing to the next card
- **FR-011**: System MUST skip audio generation for words that already have audio and an unchanged lemma during re-enrichment
- **FR-012**: System MUST hide the speaker icon when audio is disabled in settings

### Key Entities

- **Audio File**: A pronunciation recording of a word's lemma. One per word. Stored in cloud storage, referenced by URL from the dictionary record.
- **Audio Setting**: A user-level preference (on/off) controlling whether audio plays during sessions and whether the replay icon is visible.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Audio plays within 100ms of answer reveal for prefetched words (no perceptible delay)
- **SC-002**: 100% of newly enriched words have audio generated as part of the enrichment pipeline
- **SC-003**: Audio files are cached locally after first download — subsequent plays require no network
- **SC-004**: Audio failures (missing file, network error) never block or delay card interaction
- **SC-005**: Users can disable audio in one tap from the settings screen

## Assumptions

- The enrichment pipeline runs server-side and has access to a TTS service (the specific provider is an implementation detail)
- Audio files are small (single word pronunciations, typically <50KB) so storage and bandwidth costs are minimal
- The target language for pronunciation is English (the word's language), not the user's native language
- Device audio output follows system volume and silent mode — no in-app volume control needed
- Session pre-population already fetches card data; audio prefetch piggybacks on this existing flow

## Scope Boundaries

**In scope**:
- TTS generation for lemma pronunciation
- Storage and retrieval of audio files
- Auto-play on answer reveal (all card types)
- Manual replay icon
- Audio toggle setting
- Prefetch and local caching
- Graceful degradation on failure

**Out of scope**:
- Method 8: Audio Recognition card (separate feature, depends on this)
- Audio for example sentences or full phrases
- Multiple pronunciation variants (dialects, speeds)
- In-app volume control
- Audio for the user's native language translations
