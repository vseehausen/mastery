# Mastery Improvement Backlog

This document tracks known issues and improvement opportunities discovered during manual testing sessions. Items are grouped by category for easier prioritization and implementation planning.

## Data/Sync Bugs

- **Desync between session cards and vocab enrichment data**
  - Issue: Session cards may show outdated or mismatched information compared to the latest vocabulary enrichment data
  - Impact: User sees inconsistent information during learning sessions

- **Result page status mismatch (known vs stabilizing)**
  - Issue: Post-session result page displays incorrect status for words (e.g., showing "known" when should be "stabilizing")
  - Impact: Misleading feedback about learning progress

## Enrichment Quality

- **Recognition card needs L1 confusables (not alternative translations)**
  - Example: "dilapidated"
  - Issue: Recognition cards need L1 words that look/sound similar but mean different things (confusables), not semantic alternative translations
  - Fix: Add L1 confusables to enrichment data and use them as distractors for recognition practice
  - Note: Currently disabled in card preview until confusables are available

## Session Algorithm

- **Card ordering: start simple, place level-ups at emotional moments**
  - Issue: Current ordering may not optimize for user engagement and motivation
  - Opportunity: Implement smarter sequencing that builds confidence early and places successes at psychologically optimal moments

- **Cloze card difficulty tuning**
  - Issue: Cloze cards may be too easy or too hard
  - Opportunity: Refine difficulty calibration based on word complexity and user level

## UX/Features

- **Onboarding & early gratification redesign**
  - Components:
    - Welcome words: Pre-selected starter vocabulary for immediate engagement
    - Chatbot: Interactive guide for first-time users
  - Goal: Reduce friction and provide quick wins for new users

- **Native language detection to reject words + subtle delete method on learning screen**
  - Issue: Users may accidentally add words in their native language (e.g., "Auge" for German speakers)
  - Feature: Detect and prevent native language words from being added
  - Related: Provide an unobtrusive way to delete words from the learning screen

- **Show alternatives on other card types where appropriate**
  - Issue: Alternatives are useful context but currently limited to specific card types
  - Opportunity: Expand the display of word alternatives to more card types where they add value

---

*Last updated: 2026-02-11*
