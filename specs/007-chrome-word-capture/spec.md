# Feature Specification: Chrome Word Capture Extension

**Feature Branch**: `007-chrome-word-capture`
**Created**: 2026-02-09
**Status**: Draft
**Input**: User description: "Chrome extension for vocabulary capture from web reading — lookup IS capture, with contextual translation tooltip, lemmatization, and popup stats"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Look Up a Word While Reading (Priority: P1)

A user reading a web article double-clicks any word they don't know. A tooltip appears near the word within 300ms showing: the word with pronunciation (IPA), translation in the user's native language, the original context sentence with the target word highlighted, and a translated context sentence with the corresponding word highlighted. The word is automatically saved to the user's vocabulary — there is no "Add" button. Lookup IS capture.

**Why this priority**: This is the core value proposition. It replaces the user's dictionary with something faster and more useful, and every lookup becomes vocabulary for spaced repetition practice in the mobile app. Without this flow, the extension has no purpose.

**Independent Test**: Can be fully tested by double-clicking any word on any webpage and verifying the tooltip appears with correct translation, pronunciation, context sentence, and translated context sentence. The word should appear in the user's vocabulary on next app sync.

**Acceptance Scenarios**:

1. **Given** a logged-in user reading any webpage, **When** they double-click a word, **Then** a tooltip appears near the word within 300ms showing: the lemma, IPA pronunciation, native-language translation, original context sentence with the word highlighted, and translated context sentence with the corresponding word highlighted.
2. **Given** a logged-in user reading any webpage, **When** they double-click a word they have never looked up before, **Then** the tooltip shows a subtle "Saved" confirmation and the word is persisted to their vocabulary in the backend.
3. **Given** a logged-in user who has previously looked up a word, **When** they double-click the same word (or an inflected form) on a different page, **Then** the tooltip shows the word's current learning stage (e.g., "Stabilizing") and a "New context saved" message, and the new context sentence is added to the word's context library.
4. **Given** a logged-in user who double-clicks an inflected form (e.g., "ameliorating"), **When** the tooltip appears, **Then** it displays the lemma ("ameliorate") as the canonical entry with the translation, while preserving the original inflected form in the context sentence.
5. **Given** a user who has previously looked up a word, **When** they double-click the same word again, **Then** the tooltip appears instantly from local cache (under 50ms) without a network request for the word/translation data.
6. **Given** a user double-clicks a word, **When** the tooltip is visible, **Then** clicking anywhere outside the tooltip or scrolling the page dismisses it.
7. **Given** a user double-clicks a word, **When** the tooltip renders, **Then** it appears below the word if sufficient viewport space exists, or above it if the word is near the page bottom, and never overlaps the word itself.
8. **Given** an unauthenticated user on any webpage, **When** they double-click a word, **Then** a tooltip appears with a sign-in prompt only — no translation, pronunciation, or context data is shown.

---

### User Story 2 - Context Menu Word Lookup (Priority: P2)

A user selects a word or short phrase on a webpage, right-clicks, and chooses "Look up in Mastery" from the context menu. The same tooltip appears with the same behavior as double-click lookup.

**Why this priority**: Provides an alternative capture method for cases where double-click doesn't work well (e.g., words in interactive elements, or when the user wants to look up a multi-word phrase). Completes the capture mechanism.

**Independent Test**: Can be tested by selecting any word or phrase, right-clicking, selecting "Look up in Mastery", and verifying the tooltip appears with correct translation and context data.

**Acceptance Scenarios**:

1. **Given** a logged-in user on any webpage, **When** they select a single word, right-click, and choose "Look up in Mastery", **Then** the same tooltip appears as for double-click lookup, with translation, context sentence, and translated context sentence.
2. **Given** a logged-in user who selects a multi-word phrase (e.g., "break down"), **When** they use the context menu to look it up, **Then** the phrase is stored as-is without lemmatization, with translation and context.
3. **Given** no text is selected, **When** the user right-clicks, **Then** the "Look up in Mastery" context menu item is not shown (or is disabled).

---

### User Story 3 - Popup with Page Stats (Priority: P3)

A user clicks the Mastery toolbar icon to see a popup showing their total tracked word count, words looked up on the current page (with learning stage badges), and access to settings.

**Why this priority**: Provides visibility into the user's capture activity during a reading session and connects the extension experience to the mobile app. Reinforces the value of the extension by showing accumulated vocabulary.

**Independent Test**: Can be tested by looking up several words on a page, then clicking the toolbar icon and verifying the popup shows accurate counts and word list with correct stage badges.

**Acceptance Scenarios**:

1. **Given** a logged-in user who has looked up words, **When** they click the Mastery toolbar icon, **Then** the popup shows their total tracked word count across all sessions.
2. **Given** a user on a page where they have looked up 3 words, **When** they open the popup, **Then** it lists those 3 words with their current learning stage badges (e.g., "New", "Stabilizing").
3. **Given** a user has not looked up any words on the current page, **When** they open the popup, **Then** it shows zero words for the current page but still displays the total word count and settings access.

---

### User Story 4 - Offline Cached Lookups (Priority: P4)

A user who has previously looked up a word can see its tooltip even when offline, using locally cached data. New lookups while offline show a clear "Offline — translation unavailable" message.

**Why this priority**: Graceful degradation for a connected experience. Previously looked-up words should remain accessible from cache, while new lookups honestly communicate the need for connectivity.

**Independent Test**: Can be tested by looking up a word while online, going offline, then double-clicking the same word (should show cached tooltip) and a new word (should show offline message).

**Acceptance Scenarios**:

1. **Given** a user has previously looked up "ubiquitous" while online, **When** they double-click "ubiquitous" while offline, **Then** the tooltip appears with cached translation, pronunciation, and stage data.
2. **Given** a user is offline, **When** they double-click a word they have never looked up before, **Then** a message "Offline — translation unavailable" appears instead of the tooltip.

---

### Edge Cases

- What happens when a user double-clicks a number, URL, or non-word text? The system ignores non-word selections and does not trigger a tooltip.
- What happens when a user double-clicks a word on a page with heavily nested or dynamic DOM (e.g., a single-page app)? Context sentence extraction walks up to the nearest block-level container and extracts the containing sentence, falling back to the first 200 characters if sentence boundaries can't be detected.
- What happens when the tooltip would render outside the visible viewport? The tooltip repositions to remain fully visible, preferring placement below the word but flipping above if near the bottom.
- What happens when the user's auth token expires? The extension prompts the user to re-authenticate via the popup or redirects to app login.
- What happens when the backend returns an error for a lookup? A brief, user-friendly error message appears in the tooltip position (e.g., "Couldn't translate — try again") and the word is NOT saved.
- What happens when the same word appears in the local cache but with a stale learning stage? The cached stage is shown immediately, and the system updates the cache asynchronously from the backend on the next successful request.
- What happens when a user has 5,000+ words cached locally? The cache is pruned using a least-recently-used (LRU) strategy, keeping the most recently accessed entries.
- What happens when a user double-clicks inside an input field, textarea, or contenteditable element? The lookup does not trigger — these are text editing contexts, not reading contexts.
- What happens when an unauthenticated user double-clicks a word? A tooltip appears with a sign-in prompt only — no translation data is shown. All lookup functionality requires authentication.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a translation tooltip within 300ms of a user double-clicking a word on any webpage.
- **FR-002**: Tooltip MUST show: the lemma form of the word, IPA pronunciation, native-language translation, original context sentence with the lookup word highlighted, and translated context sentence with the corresponding translated word highlighted.
- **FR-003**: Every word lookup MUST automatically save the word to the user's vocabulary — there is no separate "add" action.
- **FR-004**: System MUST perform lemmatization so that inflected forms (e.g., "ameliorating") map to their canonical lemma ("ameliorate") as a single vocabulary entry.
- **FR-005**: System MUST store the raw encountered form alongside the lemma for each context occurrence.
- **FR-006**: When a previously tracked word is looked up again, system MUST add the new context sentence to the word's context library and display the word's current learning stage in the tooltip.
- **FR-007**: System MUST provide a right-click context menu item "Look up in Mastery" for selected text, triggering the same tooltip behavior as double-click.
- **FR-008**: Multi-word selections via context menu MUST be stored as-is (without lemmatization).
- **FR-009**: System MUST cache looked-up words locally for instant tooltip display (under 50ms) on repeat lookups.
- **FR-010**: Local cache MUST be pruned using an LRU strategy with a maximum of approximately 5,000 entries.
- **FR-011**: System MUST store the source page URL and title with every captured word for future source-tracking features.
- **FR-012**: The popup MUST show: total tracked word count, words looked up on the current page with learning stage badges, and settings access.
- **FR-013**: The tooltip MUST auto-dismiss when the user clicks outside it or scrolls the page.
- **FR-014**: The tooltip MUST contain no interactive buttons — it is purely informational.
- **FR-015**: The tooltip MUST be visually isolated from the host page's styles.
- **FR-016**: System MUST NOT trigger lookups when a user double-clicks inside input fields, textareas, or contenteditable elements.
- **FR-017**: System MUST display "Offline — translation unavailable" for new lookups when no network connection is available.
- **FR-018**: System MUST serve cached word data when available, even when offline.
- **FR-019**: System MUST have zero measurable impact on page load performance — no DOM scanning or manipulation on page load.
- **FR-020**: System MUST require user authentication to sync vocabulary to the backend.
- **FR-021**: When an unauthenticated user double-clicks a word, the system MUST show a sign-in prompt in the tooltip position instead of translation data. No lookup functionality is available without authentication.

### Key Entities

- **Word Entry**: The canonical vocabulary record. Identified by its lemma. Holds translation, pronunciation, learning stage, lookup count, and a collection of context occurrences.
- **Context Occurrence**: A single encounter of a word in reading. Holds the raw encountered form, the original sentence, the translated sentence, the source URL, source title, and timestamp.
- **Local Cache Entry**: A lightweight copy of a Word Entry stored on-device for fast tooltip rendering. Contains translation, pronunciation, stage, and lookup count. Pruned by LRU when cache exceeds capacity.
- **Source**: The webpage where a word was encountered. Identified by URL, with title and timestamp. Linked to one or more Context Occurrences.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users see a complete translation tooltip within 300ms of double-clicking a word (for new lookups requiring a network request).
- **SC-002**: Users see a complete translation tooltip within 50ms for previously cached words.
- **SC-003**: The extension causes zero measurable increase in page load time on content-heavy websites (news sites, long-form articles, SPAs).
- **SC-004**: 95% of single-word lookups correctly resolve to the expected lemma form.
- **SC-005**: 100% of word lookups are automatically captured — no words are lost due to missing "save" steps.
- **SC-006**: Users can look up words on any publicly accessible webpage without errors on at least 99% of sites.
- **SC-007**: The extension requests only minimal permissions — no "browsing activity" or "browsing history" warnings appear during installation.
- **SC-008**: Users who install the extension perform at least 5 word lookups in their first reading session (indicating the interaction model is intuitive).
- **SC-009**: Words captured via the extension appear in the mobile app for practice within one sync cycle.

## Clarifications

### Session 2026-02-09

- Q: What happens when an unauthenticated user double-clicks a word? → A: The tooltip shows a sign-in prompt only (no translation data). All lookup functionality requires authentication. The extension is a vocabulary mastery tool, not a translation service.
- Q: What reading/learning languages does V1 support? → A: English-only for V1. No language picker is exposed to the user. However, the system should be architected in a language-agnostic way so additional languages can be added in the future without rework.
- Q: What does the "Open Mastery App" button in the popup do? → A: Remove it for V1. The popup shows stats and settings only. An app link can be added later when a web dashboard or deep link target exists.

## Assumptions

- Users are already authenticated with a Mastery account. The extension does not handle account creation — users create accounts in the mobile app first.
- The user's native language (translation target) is configured during initial extension setup or pulled from their account settings.
- The backend provides lemmatization, translation, pronunciation, and context sentence translation as a single response for each lookup.
- V1 supports English as the only reading/learning language. No language selection is exposed to the user. The system is architected to be language-agnostic so additional languages can be added in the future without rework.
- The extension targets Chrome for V1. Firefox, Edge, and Safari support are deferred to V2.
- Known word highlighting on pages is deferred to V2 — it is not part of this specification's scope.
- Side panel UI is deferred to V2.
- Multi-word phrase detection and phrasal verb databases are deferred to V2 — V1 stores multi-word selections as-is.
- Offline word capture queuing is not supported in V1 — the extension requires connectivity for new lookups.
- Practice features live exclusively in the mobile app — the extension never attempts to redirect users into practice mode.

## Scope Boundaries

### In Scope (V1)

- Double-click word lookup with contextual translation tooltip
- Automatic vocabulary capture on every lookup
- Context sentence extraction and bilingual translation with word highlighting
- Lemmatization (inflected forms map to canonical lemma)
- Right-click context menu "Look up in Mastery" for selected text
- Popup showing word count, page-specific lookups with stage badges, settings
- Backend sync for vocabulary persistence
- Local cache for instant repeat lookups
- Source URL/title storage with every capture

### Out of Scope (V2+)

- Known word highlighting on web pages
- Side panel UI
- Multi-word phrase detection / phrasal verb database
- Firefox, Edge, Safari support
- Offline capture queue
- Practice or review features within the extension
- Reading/learning language selection (V1 is English-only; language picker deferred)
