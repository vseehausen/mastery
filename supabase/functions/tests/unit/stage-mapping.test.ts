// Unit tests for vocabulary stage mapping from lookup-word.
//
// Maps FSRS learning card state to user-facing stage:
//   state 0 → new
//   state 1 → practicing (learning)
//   state 3 → practicing (relearning)
//   state 2 + stability < 7 → practicing
//   state 2 + stability 7–20 → stabilizing
//   state 2 + stability 21–59 → known
//   state 2 + stability >= 60 → mastered
//
// Run:
//   deno test --allow-all supabase/functions/tests/unit/stage-mapping-test.ts

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

/** Re-implementation of stage mapping logic from lookup-word/index.ts. */
function getStage(card: { state: number; stability: number } | null): string {
  if (!card) return "new";
  if (card.state === 0) return "new";
  if (card.state === 1 || card.state === 3) return "practicing";
  if (card.state === 2) {
    if (card.stability < 7) return "practicing";
    if (card.stability < 21) return "stabilizing";
    if (card.stability < 60) return "known";
    return "mastered";
  }
  return "new";
}

Deno.test("stage: null card → new", () => {
  assertEquals(getStage(null), "new");
});

Deno.test("stage: state 0 → new", () => {
  assertEquals(getStage({ state: 0, stability: 0 }), "new");
});

Deno.test("stage: state 1 (learning) → practicing", () => {
  assertEquals(getStage({ state: 1, stability: 0 }), "practicing");
});

Deno.test("stage: state 3 (relearning) → practicing", () => {
  assertEquals(getStage({ state: 3, stability: 5 }), "practicing");
});

Deno.test("stage: state 2 low stability → practicing", () => {
  assertEquals(getStage({ state: 2, stability: 3 }), "practicing");
});

Deno.test("stage: state 2 stability boundary (6.99) → practicing", () => {
  assertEquals(getStage({ state: 2, stability: 6.99 }), "practicing");
});

Deno.test("stage: state 2 stability=7 → stabilizing", () => {
  assertEquals(getStage({ state: 2, stability: 7 }), "stabilizing");
});

Deno.test("stage: state 2 stability=14 → stabilizing", () => {
  assertEquals(getStage({ state: 2, stability: 14 }), "stabilizing");
});

Deno.test("stage: state 2 stability boundary (20.99) → stabilizing", () => {
  assertEquals(getStage({ state: 2, stability: 20.99 }), "stabilizing");
});

Deno.test("stage: state 2 stability=21 → known", () => {
  assertEquals(getStage({ state: 2, stability: 21 }), "known");
});

Deno.test("stage: state 2 stability=45 → known", () => {
  assertEquals(getStage({ state: 2, stability: 45 }), "known");
});

Deno.test("stage: state 2 stability boundary (59.99) → known", () => {
  assertEquals(getStage({ state: 2, stability: 59.99 }), "known");
});

Deno.test("stage: state 2 stability=60 → mastered", () => {
  assertEquals(getStage({ state: 2, stability: 60 }), "mastered");
});

Deno.test("stage: state 2 stability=100 → mastered", () => {
  assertEquals(getStage({ state: 2, stability: 100 }), "mastered");
});

Deno.test("stage: unknown state 4 → new (fallback)", () => {
  assertEquals(getStage({ state: 4, stability: 50 }), "new");
});
