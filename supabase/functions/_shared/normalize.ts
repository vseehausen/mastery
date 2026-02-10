/** Normalize a word for storage and lookup: trim + lowercase.
 *  No stemming — lemma resolution is deferred to enrichment (AI). */
export function normalize(word: string): string {
  return word.trim().toLowerCase();
}
