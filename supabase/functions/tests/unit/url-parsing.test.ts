// Unit tests for URL domain extraction from lookup-word.
//
// Run:
//   deno test --allow-all supabase/functions/tests/unit/url-parsing-test.ts

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

/** Re-implementation of extractDomain from lookup-word/index.ts */
function extractDomain(urlStr: string): string {
  try {
    const url = new URL(urlStr);
    return url.hostname.replace(/^www\./, "");
  } catch {
    return "";
  }
}

Deno.test("extractDomain: normal HTTPS URL", () => {
  assertEquals(extractDomain("https://example.com/page"), "example.com");
});

Deno.test("extractDomain: strips www prefix", () => {
  assertEquals(extractDomain("https://www.example.com/page"), "example.com");
});

Deno.test("extractDomain: HTTP URL", () => {
  assertEquals(
    extractDomain("http://blog.example.com/post"),
    "blog.example.com",
  );
});

Deno.test("extractDomain: URL with port", () => {
  assertEquals(extractDomain("https://localhost:3000/page"), "localhost");
});

Deno.test("extractDomain: URL with subdomain", () => {
  assertEquals(
    extractDomain("https://docs.github.com/en/pages"),
    "docs.github.com",
  );
});

Deno.test("extractDomain: invalid URL returns empty string", () => {
  assertEquals(extractDomain("not-a-url"), "");
});

Deno.test("extractDomain: empty string returns empty string", () => {
  assertEquals(extractDomain(""), "");
});

Deno.test("extractDomain: missing protocol returns empty string", () => {
  assertEquals(extractDomain("example.com/page"), "");
});
