# Feature Specification: Kindle Import

**Feature Branch**: `001-kindle-import`
**Created**: 2026-01-24
**Status**: Draft
**Input**: User description: "Import highlights from Kindle devices or app"

## Product Context

Mastery is a vocabulary learning application that helps users build a comprehensive inventory of words they know. The system creates personalized flashcards and learning objects tailored to each user's learning style.

**Kindle Import is the first of multiple vocabulary import sources.** Highlights serve as raw input that will be processed to extract vocabulary, capture usage context (surrounding sentences), and feed the learning system. Future import sources may include browser extension captures, manual entry, and other reading platforms.

**Data Model Vision**: The system centers on vocabulary entries keyed by the foreign word (English as first supported language). Each entry aggregates multiple usage examples, learning materials, and metadata from various sources including Kindle highlights.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Manual File Import (Priority: P1)

As a Kindle reader, I want to import my highlights by selecting my Kindle clippings file so that I can view and organize all my book highlights in Mastery without any technical setup.

**Why this priority**: This is the foundational import method that works for all Kindle users regardless of their device or reading habits. It requires no additional software setup and provides immediate value.

**Independent Test**: Can be fully tested by uploading a "My Clippings.txt" file and verifying highlights appear organized by book. Delivers core value of centralizing highlights.

**Acceptance Scenarios**:

1. **Given** a user has a "My Clippings.txt" file from their Kindle, **When** they select and upload the file, **Then** all highlights are parsed and displayed grouped by book title
2. **Given** a clippings file contains highlights from multiple books, **When** the import completes, **Then** each highlight is associated with its correct book and author
3. **Given** a user has previously imported highlights, **When** they import the same file again, **Then** duplicate highlights are detected and not re-imported
4. **Given** the file contains bookmarks or notes (not highlights), **When** imported, **Then** notes are imported separately from highlights, bookmarks are ignored

---

### User Story 2 - Automatic Desktop Import (Priority: P2)

As a frequent Kindle reader, I want my highlights to automatically sync when I connect my Kindle device so that I don't have to manually export and import files.

**Why this priority**: Reduces friction for power users who read frequently. Requires desktop agent (Tauri) to be installed, hence lower priority than manual import.

**Independent Test**: Can be tested by connecting a Kindle device via USB with the desktop agent running and verifying new highlights appear automatically.

**Acceptance Scenarios**:

1. **Given** the desktop agent is running and a Kindle is connected via USB, **When** the agent detects the device, **Then** it automatically reads new highlights from "My Clippings.txt"
2. **Given** new highlights are detected on the Kindle, **When** automatic sync occurs, **Then** only new highlights (not previously imported) are added to the user's library
3. **Given** the desktop agent is running, **When** a Kindle is disconnected, **Then** the agent stops monitoring and displays a "device disconnected" status
4. **Given** the user has disabled automatic sync in preferences, **When** a Kindle is connected, **Then** no automatic import occurs but manual import is still available

---

### User Story 3 - View and Organize Imported Highlights (Priority: P3)

As a user who has imported highlights, I want to browse my highlights by book and search across all highlights so that I can find and revisit specific passages.

**Why this priority**: Provides value only after imports exist. Essential for making imported data useful but depends on P1/P2 being complete.

**Independent Test**: Can be tested with pre-loaded highlight data by browsing books, viewing highlights, and searching for specific text.

**Acceptance Scenarios**:

1. **Given** a user has imported highlights from multiple books, **When** they view their library, **Then** they see a list of books with highlight counts
2. **Given** a user selects a book from their library, **When** they open it, **Then** they see all highlights from that book in reading order
3. **Given** a user enters a search term, **When** they search, **Then** matching highlights are displayed with the search term highlighted and book context shown
4. **Given** a user is viewing a highlight, **When** they tap/click on it, **Then** they can see the full highlight text, book title, author, and date added

---

### Edge Cases

- What happens when the clippings file is corrupted or in an unexpected format? System displays a clear error message identifying the issue and suggests re-exporting from Kindle
- What happens when a highlight has no associated book metadata? Highlight is imported with "Unknown Book" placeholder, user can manually assign book later
- What happens when the same highlight appears multiple times in the clippings file? Only the first occurrence is imported, duplicates are silently skipped
- What happens when the Kindle is disconnected mid-import? Import of already-read highlights completes, pending highlights can be recovered on next connection
- What happens when storage is full? User is notified before import starts if insufficient space, import is blocked until space is freed
- What happens when the same highlight is modified on two devices while offline? Last-write-wins based on timestamp; user is not prompted to resolve conflicts manually

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST parse Kindle "My Clippings.txt" file format and extract highlights, notes, and metadata (book title, author, location, date)
- **FR-002**: System MUST detect and skip duplicate highlights based on content, book, and location
- **FR-003**: System MUST store imported highlights locally for offline access
- **FR-004**: System MUST organize highlights by book with automatic grouping
- **FR-005**: System MUST provide full-text search across all imported highlights
- **FR-006**: System MUST support manual file selection and import on mobile and desktop
- **FR-007**: Desktop agent MUST detect Kindle device connection via USB and read clippings file
- **FR-008**: Desktop agent MUST run in background and monitor for device connections
- **FR-009**: System MUST sync imported highlights to cloud when online (for cross-device access)
- **FR-010**: System MUST preserve highlight import history to prevent re-importing duplicates after app reinstall (via cloud sync)
- **FR-011**: System MUST require user authentication before any feature access; users must create an account or sign in before first import
- **FR-012**: System MUST resolve sync conflicts using last-write-wins strategy based on modification timestamp; most recent change overwrites earlier versions
- **FR-013**: System MUST allow users to edit highlight text after import
- **FR-014**: System MUST allow users to delete highlights from their library
- **FR-015**: System MUST support adding metadata to highlights (surrounding sentence, usage context, personal notes) for future vocabulary processing
- **FR-016**: System MUST create an English language entry at initialization; all imported highlights default to English; data model supports future multi-language expansion

### Key Entities

- **Highlight**: A text passage marked by the user; contains content, location reference, creation date, type (highlight vs note), and is editable after import. Serves as raw input for vocabulary extraction. Can be amended with metadata (surrounding sentence, usage context).
- **Book**: A source containing highlights; identified by title and author, may include additional metadata (ASIN if available)
- **ImportSession**: A record of an import operation; tracks source (file/device), timestamp, highlights imported, duplicates skipped
- **User**: The account owner; owns highlights and books, has preferences for auto-sync and learning style
- **VocabularyEntry** *(future, referenced for context)*: A word or phrase keyed by the foreign word (English first); aggregates usage examples from multiple sources (highlights, browser extension, manual entry); stores learning variations and personalized flashcard configurations
- **Language**: A supported language for vocabulary learning; English created as first entry at system initialization. Highlights and future vocabulary entries reference their language. Designed for multi-language expansion.

## Clarifications

### Session 2026-01-24

- Q: Is an account required to use the app? → A: Account required for all features (must sign up before first import)
- Q: How are sync conflicts resolved when same highlight modified on multiple devices? → A: Last-write-wins (most recent change overwrites, based on timestamp)
- Q: Can users modify highlights after import? → A: Fully mutable. Highlights are one of multiple vocabulary import sources; they feed a vocabulary learning system that processes words into personalized flashcards. Highlights will be amended with metadata (surrounding sentence, usage context). Data model centers on foreign word as key with usage/learning variations attached.
- Q: What is the scope boundary for this feature? → A: Import, storage, and CRUD only; vocabulary extraction and flashcard generation are separate future features
- Q: What is the primary language learning direction? → A: Learning English vocabulary (user reads English books). A Language entity for English should be created at the start to support adding other languages in the future.

## Assumptions

- Kindle clippings file follows the standard "My Clippings.txt" format used by all Kindle devices (delimiter-separated entries with metadata header)
- Users have a single Kindle account (multi-account Kindle support is out of scope for initial release)
- Desktop agent requires one-time installation; no automatic installation from mobile app
- Import performance: files up to 10MB (approximately 50,000 highlights) should be supported
- English is the first supported language for vocabulary learning; other languages are future scope
- Vocabulary extraction and flashcard generation are separate future features; this spec covers only the import pipeline and highlight storage/editing
- Highlight data model should be extensible to support future vocabulary metadata without migration

## Out of Scope

The following are explicitly **not** part of this feature (deferred to future features):

- Vocabulary extraction from highlights (identifying individual words/phrases)
- Flashcard or learning object generation
- Spaced repetition scheduling
- Learning style analysis or personalization
- Other import sources (browser extension, manual entry, other reading platforms)
- Languages other than English content
- Multi-account Kindle support

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can import a typical clippings file (1000 highlights) in under 30 seconds
- **SC-002**: 95% of users successfully complete their first manual import without errors
- **SC-003**: Duplicate detection accuracy is 99% or higher (no false positives creating duplicates)
- **SC-004**: Users can find any highlight via search in under 3 seconds
- **SC-005**: Desktop agent detects connected Kindle device within 5 seconds of connection
- **SC-006**: Imported highlights are available offline immediately after import completes
- **SC-007**: Cross-device sync completes within 60 seconds of coming online
