# Feature Specification: Vocabulary Import & Display

**Feature Branch**: `002-vocabulary-import-display`  
**Created**: 2026-01-26  
**Status**: Draft  
**Input**: User description: "Desktop app parses input file into vocabulary (on server), Flutter app displays vocabulary list (no import, learning UI in separate spec)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Import Vocabulary from Kindle (Priority: P1)

A user connects their Kindle to the desktop app and imports their vocabulary from Kindle's Vocabulary Builder (vocab.db). The desktop app sends the vocab.db file to the server for parsing, which extracts individual vocabulary words with their usage context (the sentence where the word was looked up). The parsed vocabulary is stored and synced to the cloud.

**Why this priority**: This is the core data ingestion path. Without vocabulary import, there's nothing to display in the mobile app.

**Independent Test**: Can be fully tested by connecting a Kindle device, triggering import, and verifying vocabulary items appear in the database with correct word, context, and book association.

**Acceptance Scenarios**:

1. **Given** a Kindle is connected with vocab.db present, **When** the user triggers import, **Then** vocab.db is sent to server for parsing and results are stored locally and synced to cloud
2. **Given** the server receives vocab.db, **When** parsing completes, **Then** each vocabulary entry contains: word, usage context sentence, book title, and lookup timestamp
3. **Given** a user has previously imported vocabulary, **When** they import again, **Then** only new vocabulary items are added (no duplicates)

---

### User Story 2 - View Vocabulary List on Mobile (Priority: P2)

A user opens the Flutter mobile app and sees a list of all their imported vocabulary words. Each list item shows the word and a truncated context sentence. Tapping an item reveals full details including the complete context and book information. The list syncs from the cloud and is available offline.

**Why this priority**: This is the primary consumption interface. Once vocabulary is imported, users need to see it on mobile.

**Independent Test**: Can be fully tested by opening the mobile app with synced vocabulary data and verifying the list displays words with truncated context.

**Acceptance Scenarios**:

1. **Given** a user has imported vocabulary via desktop, **When** they open the mobile app, **Then** they see a list of vocabulary words with truncated context
2. **Given** the vocabulary list is displayed, **When** tapping an item, **Then** the user sees full details: word, complete context sentence, and book title
3. **Given** vocabulary has been synced, **When** the device goes offline, **Then** the vocabulary list remains accessible

---

### User Story 3 - View Import History (Priority: P3)

A user can see a history of their vocabulary imports on the desktop app, showing when imports occurred and how many words were added each time.

**Why this priority**: Provides transparency into the import process and helps users track their vocabulary growth over time.

**Independent Test**: Can be fully tested by performing multiple imports and verifying the history shows each import with timestamp and word count.

**Acceptance Scenarios**:

1. **Given** the user has performed imports, **When** they view import history, **Then** they see a list of imports with date and word count
2. **Given** an import is in progress, **When** viewing the desktop app, **Then** the user sees import progress feedback

---

### Edge Cases

- What happens when vocab.db is empty or missing on the Kindle?
- How does the system handle corrupted vocab.db entries?
- What happens if parsing fails on the server?
- How does the system handle very large vocab.db files (thousands of entries)?
- What happens when the mobile app syncs with no internet connection?
- How are vocabulary items handled when the book title cannot be determined?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Desktop app MUST detect and read vocab.db (Vocabulary Builder database) from connected Kindle devices
- **FR-002**: Desktop app MUST send vocab.db content to server for parsing (not parse locally)
- **FR-003**: Server MUST parse Kindle vocab.db and extract: word, usage context sentence, book title, lookup timestamp
- **FR-004**: Server MUST return parsed vocabulary entries to desktop app for local storage
- **FR-005**: System MUST prevent duplicate vocabulary entries (same word + same context + same book)
- **FR-006**: Desktop app MUST sync parsed vocabulary to cloud storage
- **FR-007**: Mobile app MUST sync vocabulary from cloud on app launch (when online)
- **FR-008**: Mobile app MUST display vocabulary list with word and truncated context, sorted by newest first; tapping reveals full context and book
- **FR-009**: Mobile app MUST store vocabulary locally for offline access
- **FR-010**: Desktop app MUST record import sessions with timestamp and entry count
- **FR-011**: Desktop app MUST provide visual feedback during import and parsing
- **FR-012**: System MUST handle parsing errors gracefully and report them to the user

### Key Entities

- **Vocabulary**: A word looked up on Kindle via Vocabulary Builder, containing: the word itself, usage context sentence (where the word was looked up), lookup timestamp, and sync metadata
- **Book**: Source book for vocabulary lookups, containing: title, author (if available), and identifier (ASIN if available)
- **ImportSession**: Record of a vocab.db import operation, containing: timestamp, source device, entries imported count, and status

## Clarifications

### Session 2026-01-26

- Q: What is the Kindle vocabulary data source? → A: vocab.db (Kindle Vocabulary Builder - words looked up while reading), not highlights
- Q: What level of detail in mobile vocabulary list view? → A: Word + truncated context (tap for full details including book)
- Q: How should vocabulary list be organized by default? → A: Chronological (newest first)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can import vocabulary from a connected Kindle device in under 30 seconds for typical file sizes (up to 1000 entries)
- **SC-002**: Imported vocabulary appears in the mobile app within 5 seconds of sync
- **SC-003**: Users can view their complete vocabulary list on mobile while offline
- **SC-004**: 100% of valid vocabulary entries from the Kindle file are successfully parsed and stored
- **SC-005**: Users can identify which book each vocabulary word came from
- **SC-006**: Users receive clear feedback if import fails, including actionable error information
