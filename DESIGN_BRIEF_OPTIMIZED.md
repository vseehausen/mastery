# Mastery — Design Brief (Optimized)

## Product in one sentence

**Mastery is an AI-driven “vocabulary shadow brain” for fluent English-speaking professionals—capturing words in context from everywhere they read and turning them into measurable, active vocabulary growth through spaced repetition and personalized learning.**

## What we’re building (high-level)

- **Shadow brain**: the app keeps a living model of what the user knows (and how well), then uses it to decide **what to introduce, what to review, and when**.
- **Capture everywhere**: vocabulary is collected from multiple sources (Kindle first; browser/article capture and other sources next).
- **Active vocabulary focus**: move words from “I recognize it” → “I can confidently use it.”
- **Offline-first**: the core experience works offline; sync happens when online.

## Target audience

### Primary audience

- **Fluent English-speaking professionals** (knowledge workers) who read a lot and want to **upgrade active vocabulary**.

### Key user traits

- High standards for polish, speed, and clarity
- Prefer minimal friction and high signal over gamification
- Want to understand “why this word / why now” without being overwhelmed

## Brand & voice

### Essence

**A calm, knowledgeable companion** that quietly improves your vocabulary over time—like a second brain for language.

### Voice & tone

- Calm, encouraging, never condescending
- Clear and precise language; avoids hype
- Confident but transparent about recommendations (“because …”)

## Success criteria (design impact)

- **Fast comprehension**: a user can understand their “vocabulary state” at a glance.
- **Low effort**: capture + first meaningful learning session feels easy.
- **Trust**: users believe the system is accurate and helpful.
- **Consistency**: mobile and desktop feel like one product family.

## Core concept: “Shadow brain”

### Mental model

The system maintains a vocabulary state with at least three questions:

- **Do you know this word?** (confidence)
- **Can you actively use it?** (active vs passive)
- **When should you see it next?** (spaced repetition scheduling)

### UI responsibilities

- Make the model visible without showing raw complexity
- Provide lightweight explanations (“why this word now?”)
- Show progress as **state change** (unknown → learning → known → active)

## Core jobs-to-be-done

- **Capture** words while reading with near-zero effort
- **Review** efficiently (spaced repetition) without breaking focus
- **Understand progress**: what improved, what’s next, why it matters
- **Search and recall**: quickly find the context where a word was encountered

## Key flows (designer focus)

### 1) Authentication (mobile + desktop)

- Mobile: email/password + native Apple/Google sign-in
- Desktop: email/password + browser-based OAuth with redirect back to app

Design requirements:
- Clear primary path, strong error states, low-friction recovery
- “Signed-in state” should feel stable and trustworthy

### 2) Capture/import (desktop-first, then everywhere)

Current capture sources:
- **Kindle vocabulary lookups** (`vocab.db`) via desktop import
- **Kindle highlights** (`My Clippings.txt`) via manual import

Design requirements:
- Device connection + import status is obvious
- Progress feedback is calm and informative (not “busy”)
- Import history builds trust (“what happened and when”)

### 3) Learn (mobile-first)

The learning experience is the product:

- **Daily / quick sessions**: spaced repetition reviews
- **Introduce new words** based on shadow brain state and reading behavior
- **Detail view**: word + context + book/source + learning history

Design requirements:
- Sessions feel focused and premium (no noisy gamification)
- Small, consistent signals for “confidence” and “next review”
- “Why now?” explanation available but optional

## Information architecture (recommended)

### Mobile

- **Dashboard** (Shadow Brain): state overview, today’s session, growth
- **Session**: review + introduction
- **Vocabulary**: list with status + filters (newest, due, weak, active-gap)
- **Word detail**: context, source, history, notes
- **Library/Context**: books/sources, highlights
- **Search**: words + contexts
- **Settings**: learning preferences, personalization controls, account

### Desktop

- **Dashboard**: device status, import CTA, last import summary
- **Import history**: sessions, counts, errors
- **Settings**: auto-sync, account, troubleshooting

## Constraints & non-goals (for design scope)

- MVP focuses on **capture + organization + learning surface** (with room for AI-driven evolution).
- Avoid UI that implies medical/diagnostic “brain measurement.”
- Avoid heavy gamification (streak fireworks, loud badges) unless it supports professionals’ motivation without noise.

## Deliverables (what we need from design)

- Mobile: Dashboard, Session, Vocabulary list, Word detail, Search, Settings, Auth
- Desktop: Import dashboard, Import history, Settings, Auth
- Empty states + error states (auth, import failures, offline, parsing errors)

---

**Last updated**: 2026-01-28
