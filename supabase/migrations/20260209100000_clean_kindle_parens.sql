-- Clean Kindle artifacts: strip trailing empty parentheses from word and stem
-- e.g. "wee ()" → "wee"
UPDATE vocabulary
SET word = trim(regexp_replace(word, '\s*\(\s*\)\s*$', '')),
    stem = trim(regexp_replace(stem, '\s*\(\s*\)\s*$', '')),
    updated_at = now()
WHERE (word ~ '\(\s*\)\s*$' OR stem ~ '\(\s*\)\s*$')
  AND deleted_at IS NULL;
