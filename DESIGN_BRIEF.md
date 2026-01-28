# Mastery - Design Briefing

## Overview

**Mastery** is an AI-driven vocabulary learning application that acts as a "virtual shadow brain" for professionals who speak English fluently and want to expand their active vocabulary. The app continuously learns what vocabulary you already know, intelligently introduces new words, and maintains a comprehensive state of your vocabulary knowledge—enhancing it through proven learning techniques like spaced repetition and personalized learning styles.

Mastery collects vocabulary data from everywhere you read (Kindle highlights, vocabulary lookups, browser captures, and more), then uses AI to understand your current vocabulary state and strategically introduce new words to expand your active vocabulary.

## Core Value Proposition

Mastery acts as your vocabulary shadow brain by:
- **Collecting vocabulary everywhere** — Kindle highlights, vocabulary lookups, browser captures, and future import sources
- **AI-driven understanding** — The system learns what vocabulary you already know and intelligently identifies gaps
- **Strategic vocabulary expansion** — AI introduces new words at the right time, keeping a state of your brain and enhancing it
- **Proven learning techniques** — Spaced repetition and personalized learning types optimize retention
- **Context-rich learning** — Words are always presented with their usage context (the sentence where they appeared)
- **Offline-first** — Study anywhere, anytime without requiring internet connectivity

## Target Users

**Primary Audience:**
- **Professionals** who speak English fluently and want to expand their active vocabulary
- **Knowledge workers** who read extensively and want to systematically improve their vocabulary
- **People who value precision** — users who want to move words from passive recognition to active use

**User Characteristics:**
- Already fluent in English (not learning English as a second language)
- Goal is expanding active vocabulary (words they can use confidently) rather than basic comprehension
- Read regularly across multiple sources (books, articles, documents)
- Value data-driven, AI-enhanced learning approaches
- Appreciate context-rich learning (words with usage examples)

## Platform Architecture

Mastery operates across three platforms:

### Mobile App (Flutter - iOS & Android)
- Primary learning interface
- AI-driven vocabulary review sessions with spaced repetition
- Personalized learning paths based on learning style
- View vocabulary lists and highlights
- Browse by book
- Search across all imported content
- Shadow brain dashboard showing vocabulary state and growth
- Works fully offline after initial sync

### Desktop App (Tauri - macOS, Windows, Linux)
- Import agent for Kindle devices
- Connects to Kindle via USB
- Automatic vocabulary and highlight sync
- Import history and management
- Browser-based OAuth authentication flow

### Backend (Supabase)
- Cloud sync and storage
- User authentication
- Data processing (vocabulary parsing)
- AI/ML services for vocabulary state tracking and learning recommendations
- Spaced repetition algorithm and scheduling
- Learning style personalization engine
- Cross-device synchronization

## Key Features & User Flows

### 1. Authentication
**Mobile:**
- Email/password sign-up and sign-in
- Native Apple Sign In
- Native Google Sign In
- Session persistence across app restarts

**Desktop:**
- Email/password sign-up and sign-in
- OAuth via browser (generates link, opens browser, redirects back to app)
- Apple, Google, and other OAuth providers

**Design Considerations:**
- Clean, minimal sign-in screens
- Clear provider options
- Error states for failed authentication
- Loading states during authentication

### 2. Kindle Vocabulary Import
**Desktop Flow:**
1. User connects Kindle device via USB
2. Desktop app automatically detects device
3. User triggers import (or automatic sync enabled)
4. App reads `vocab.db` (Vocabulary Builder database)
5. Sends to server for parsing
6. Vocabulary extracted with context sentences
7. Stored locally and synced to cloud
8. Import history recorded

**Manual File Import (Mobile/Desktop):**
1. User selects "My Clippings.txt" file
2. File uploaded and parsed
3. Highlights organized by book
4. Duplicates automatically detected and skipped

**Design Considerations:**
- Clear connection status indicators
- Progress feedback during import
- Import history visualization
- Success/error states
- Duplicate detection feedback

### 3. Vocabulary Display (Mobile)
**List View:**
- Vocabulary words with truncated context sentences
- Sorted by newest first (chronological)
- Book association visible
- Offline access indicator

**Detail View:**
- Full word
- Complete context sentence
- Book title and author
- Lookup timestamp
- Book cover (if available)

**Design Considerations:**
- Scannable list design
- Clear typography hierarchy
- Context truncation that doesn't break sentences
- Smooth navigation between list and detail
- Empty states for first-time users

### 4. Highlight Management (Mobile)
**Library View:**
- Books with highlight counts
- Search across all highlights
- Filter by book

**Book Detail:**
- Highlights in reading order
- Full highlight text
- Location references
- Date added

**Design Considerations:**
- Book-centric organization
- Reading order preservation
- Search with highlighted terms
- Visual distinction between highlights and notes

### 5. Cross-Device Sync
- Automatic sync when online
- Offline-first architecture (works without internet)
- Last-write-wins conflict resolution
- Sync status indicators

**Design Considerations:**
- Subtle sync indicators
- Offline mode clearly communicated
- Sync conflict handling (rare, but needs clear messaging)

### 6. AI-Driven Learning System
**Shadow Brain Concept:**
- System maintains a comprehensive state of user's vocabulary knowledge
- AI identifies which words are known vs. unknown
- Intelligently introduces new vocabulary at optimal times
- Tracks vocabulary growth and mastery over time

**Learning Features:**
- **Spaced Repetition**: Algorithm schedules reviews based on forgetting curves
- **Personalized Learning Types**: Adapts to individual learning styles (visual, contextual, etc.)
- **Vocabulary State Dashboard**: Visual representation of vocabulary knowledge state
- **Smart Introductions**: AI suggests new words based on reading patterns and current knowledge
- **Active Vocabulary Focus**: Emphasis on moving words from passive recognition to active use

**Design Considerations:**
- Clear visualization of vocabulary state and progress
- Intuitive review sessions that feel natural, not gamified
- Transparent AI decisions (why this word now?)
- Progress tracking that motivates without overwhelming
- Learning analytics that show vocabulary growth over time

## Design Principles

### 1. Offline-First
- All core features work without internet
- Clear offline indicators
- Sync happens seamlessly in background
- No blocking "waiting for sync" states

### 2. Context-Rich
- Vocabulary always shown with usage context
- Book associations prominently displayed
- Reading order preserved
- Timestamps provide temporal context

### 3. Minimal Friction
- Automatic Kindle detection
- One-click imports
- Native authentication flows
- No unnecessary steps

### 4. Reading-Focused
- Book-centric organization
- Preserve reading experience context
- Typography optimized for reading
- Visual hierarchy supports content discovery

### 5. AI-Enhanced Learning
- Shadow brain concept is clear and understandable
- AI decisions are transparent (why this word now?)
- Learning feels natural, not gamified
- Progress is visible but not overwhelming
- System adapts to individual learning styles

### 6. Trust & Transparency
- Clear import history
- Duplicate detection feedback
- Sync status visibility
- AI reasoning is explainable
- Error messages are actionable

## Brand Identity

### Brand Essence
Mastery acts as your vocabulary shadow brain—an AI-driven system that understands what you know, intelligently expands your active vocabulary, and maintains a comprehensive state of your vocabulary knowledge. We capture vocabulary everywhere you read, preserve the context of discovery, and use proven learning techniques to transform passive recognition into active mastery.

### Core Values
- **AI-Enhanced Learning** — Shadow brain that understands and enhances your vocabulary state
- **Offline-First** — Learning happens anywhere
- **Context-Rich** — Words with meaning
- **Minimal Friction** — Seamless capture from everywhere
- **Reading-Focused** — Preserve the experience
- **Data-Driven** — Collect vocabulary from all reading sources

### Voice & Tone
Calm, knowledgeable, encouraging. We speak like a thoughtful reading companion — never condescending, always supportive of the learning journey.

## Visual Style Considerations

### Typography
- **Font Family**: Inter — A clean, highly legible typeface optimized for UI. Used throughout mobile and desktop applications for consistency.
- **Type Scale**:
  - Heading 1: 32px / 700 (font weight)
  - Heading 2: 24px / 600
  - Heading 3: 18px / 600
  - Body: 16px / 400
  - Small: 14px / 400
  - Caption: 12px / 500
- **Readability first**: Optimize for reading vocabulary and context sentences
- **Clear hierarchy**: Distinguish between words, context, metadata
- **Multi-language ready**: Support for future language expansion

### Color Palette
- **PRIMARY**: Ink Black `#18181B` — Primary text and UI elements
- **ACCENT**: Amber Gold `#F59E0B` — Accent color for highlights, CTAs, and important actions
- **SUCCESS**: Emerald `#10B981` — Success states, positive feedback
- **BACKGROUND**: Warm White `#FAFAF9` — App background, card backgrounds
- **MUTED**: Stone Gray `#71717A` — Secondary text, muted elements, borders

**Design Considerations:**
- **Accessibility**: WCAG AA compliance minimum
- **Reading-friendly**: Comfortable for extended reading sessions
- **Status indicators**: Clear visual feedback for sync, import, errors
- **Warm undertones**: Background uses warm white to reduce eye strain during reading

### Layout
- **Mobile-first**: Optimize for mobile consumption experience
- **Desktop efficiency**: Desktop app focuses on import management
- **Consistent navigation**: Clear information architecture across platforms

### Components
- **Vocabulary cards**: Word + context + book info
- **Book cards**: Cover + title + highlight count
- **Import status**: Progress indicators, success/error states
- **Search interface**: Fast, responsive, with highlighted results

### App Icon
The Mastery icon represents knowledge building through reading. The book symbol with rising elements suggests growth and mastery of vocabulary. Master icon size: 1024x1024.

## Key Screens/Views to Design

### Mobile App
1. **Sign In / Sign Up** - Authentication entry point
2. **Shadow Brain Dashboard** - Vocabulary state overview, growth metrics, AI insights
3. **Learning Session** - Spaced repetition review interface
4. **Vocabulary List** - All collected vocabulary with learning status
5. **Vocabulary Detail** - Full word context, learning history, usage examples
6. **Library** - Books with highlights
7. **Book Detail** - Highlights from a book
8. **Search** - Full-text search across content
9. **Learning Analytics** - Progress tracking, vocabulary growth over time
10. **Settings** - Learning preferences, sync status, AI personalization options

### Desktop App
1. **Sign In** - Authentication (with browser OAuth flow)
2. **Dashboard** - Import status, device connection
3. **Import History** - Timeline of imports with statistics
4. **Settings** - Auto-sync preferences, account management

## Technical Constraints

- **Mobile**: Flutter framework, Material/Cupertino design systems
- **Desktop**: Tauri (Rust + TypeScript), Svelte 5 UI framework
- **Backend**: Supabase (PostgreSQL, Edge Functions)
- **Offline Storage**: SQLite (mobile via Drift), local file system (desktop)

## Success Metrics (Design Impact)

- Users can find vocabulary quickly (search in <3 seconds)
- Import process feels seamless (<30 seconds for typical imports)
- Clear visual feedback prevents user confusion
- Offline mode is clearly communicated
- Authentication flows feel native and secure

## Questions for Design Exploration

1. How should vocabulary cards be designed to balance word prominence with context?
2. What visual treatment distinguishes highlights from vocabulary entries?
3. How should import progress be communicated without being intrusive?
4. What empty states encourage first-time users to import?
5. How should book covers be integrated (if available)?
6. What visual language communicates "learning" vs "reading"?
7. How should sync status be indicated without cluttering the UI?
8. **How should the "shadow brain" concept be visualized?** — What UI patterns communicate that the system understands your vocabulary state?
9. **How do we make AI decisions transparent?** — Users should understand why certain words are being introduced or reviewed
10. **What does a vocabulary state dashboard look like?** — Visual representation of known vs. unknown vocabulary, growth over time
11. **How should spaced repetition sessions feel?** — Natural and focused, not gamified or distracting
12. **How do we show vocabulary mastery progression?** — Moving from recognition to active use
13. **What visual indicators show AI is working?** — Subtle cues that the system is learning and adapting

## Next Steps

1. Review user flows and identify key interaction points
2. Design mobile vocabulary list and detail views
3. Design desktop import dashboard
4. Create authentication screen designs
5. Establish design system (colors, typography, components)
6. Design empty states and error states
7. Prototype key interactions

---

**Last Updated**: 2026-01-28  
**Contact**: Development team for technical questions
