#!/usr/bin/env node

/**
 * Process pending enrichments from enrichment_queue
 *
 * Usage:
 *   node scripts/process-enrichment-queue.mjs [--limit 10]
 */

import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Load environment variables
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
config({ path: join(__dirname, '../supabase/.env.local') });

const SUPABASE_URL = process.env.VITE_SUPABASE_URL || process.env.SUPABASE_URL;
const SUPABASE_SECRET_KEY = process.env.SUPABASE_SECRET_KEY;
const SUPABASE_PUBLISHABLE_KEY = process.env.VITE_SUPABASE_PUBLISHABLE_KEY || process.env.SUPABASE_PUBLISHABLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SECRET_KEY || !SUPABASE_PUBLISHABLE_KEY) {
  console.error('Missing SUPABASE_URL, SUPABASE_SECRET_KEY, or SUPABASE_PUBLISHABLE_KEY');
  process.exit(1);
}

// Use secret key to bypass RLS when reading queue
const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SECRET_KEY);
const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);

// Parse limit from args
const args = process.argv.slice(2);
let limit = 10;
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--limit' && args[i + 1]) {
    limit = parseInt(args[i + 1], 10);
    i++;
  }
}

async function processPendingEnrichments() {
  console.log(`🔄 Processing up to ${limit} pending enrichments...\n`);

  // Fetch pending enrichments (use admin client to bypass RLS)
  const { data: pending, error: fetchError } = await supabaseAdmin
    .from('enrichment_queue')
    .select('user_id, vocabulary_id')
    .eq('status', 'pending')
    .limit(limit);

  if (fetchError) {
    console.error('Failed to fetch pending enrichments:', fetchError);
    process.exit(1);
  }

  if (!pending || pending.length === 0) {
    console.log('✅ No pending enrichments in queue');
    return;
  }

  console.log(`Found ${pending.length} pending enrichment(s)\n`);

  let success = 0;
  let failed = 0;

  for (const item of pending) {
    try {
      console.log(`Enriching vocabulary ${item.vocabulary_id} for user ${item.user_id}...`);

      // Call enrich-vocabulary edge function
      const response = await fetch(`${SUPABASE_URL}/functions/v1/enrich-vocabulary/request`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${SUPABASE_SECRET_KEY}`,
        },
        body: JSON.stringify({
          native_language_code: 'de',
          vocabulary_ids: [item.vocabulary_id],
          batch_size: 1,
        }),
      });

      if (response.ok) {
        const result = await response.json();
        const enrichedWord = result.enriched?.[0]?.word || 'unknown';
        console.log(`✓ Success: ${enrichedWord}`);
        success++;
      } else {
        const error = await response.text();
        console.error(`✗ Failed: ${response.status} - ${error}`);
        failed++;
      }
    } catch (err) {
      console.error(`✗ Error: ${err.message}`);
      failed++;
    }
  }

  console.log(`\n📊 Summary:`);
  console.log(`   Success: ${success}`);
  console.log(`   Failed: ${failed}`);
}

processPendingEnrichments().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
