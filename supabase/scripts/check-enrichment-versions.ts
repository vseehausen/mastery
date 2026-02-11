#!/usr/bin/env -S deno run --allow-env --allow-net --allow-read
// Check enrichment_version distribution in global_dictionary

import { createClient } from "jsr:@supabase/supabase-js@2";
import { load } from "jsr:@std/dotenv";

// Load environment variables
await load({ envPath: "./supabase/.env.local", export: true });

const SUPABASE_URL = Deno.env.get("VITE_SUPABASE_URL");
const SUPABASE_SECRET_KEY = Deno.env.get("SUPABASE_SECRET_KEY");

if (!SUPABASE_URL || !SUPABASE_SECRET_KEY) {
  console.error("Error: SUPABASE_URL or SUPABASE_SECRET_KEY not set");
  Deno.exit(1);
}

const client = createClient(SUPABASE_URL, SUPABASE_SECRET_KEY);

// Get version distribution
const { data, error } = await client
  .from("global_dictionary")
  .select("enrichment_version");

if (error) {
  console.error("Error:", error);
  Deno.exit(1);
}

// Count by version
const counts = new Map<number | null, number>();
for (const row of data) {
  const version = row.enrichment_version;
  counts.set(version, (counts.get(version) || 0) + 1);
}

console.log("Enrichment Version Distribution:");
console.log("================================");
for (const [version, count] of Array.from(counts.entries()).sort((a, b) => (a[0] ?? -1) - (b[0] ?? -1))) {
  console.log(`v${version ?? "NULL"}: ${count} entries`);
}
console.log("================================");
console.log(`Total: ${data.length} entries`);
