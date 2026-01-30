// Process Learning Cards Edge Function
// Creates learning cards for any vocabulary that doesn't have one yet.
// Can be called manually or scheduled to handle edge cases.

import { handleCors } from '../_shared/cors.ts';
import { createSupabaseClient, createServiceClient, getUserId } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';

Deno.serve(async (req) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // Only accept POST
  if (req.method !== 'POST') {
    return errorResponse('Method not allowed', 405);
  }

  // Get user ID from auth
  let userId = await getUserId(req);
  let isDevMode = false;

  // For development: allow passing userId with a dev secret header
  if (!userId) {
    const devSecret = Deno.env.get('DEV_SECRET');
    const providedSecret = req.headers.get('X-Dev-Secret');

    if (devSecret && providedSecret === devSecret) {
      try {
        const body = await req.clone().json();
        if (body.userId) {
          userId = body.userId;
          isDevMode = true;
          console.log('[dev mode] Using userId from request body:', userId);
        }
      } catch {
        // Ignore parse errors
      }
    }
  }

  if (!userId) {
    return unauthorizedResponse();
  }

  // Use service client in dev mode to bypass RLS, regular client otherwise
  const client = isDevMode ? createServiceClient() : createSupabaseClient(req);

  try {
    // Find vocabulary without learning cards using a left join approach
    // First get all vocabulary IDs for the user
    const { data: allVocab, error: vocabError } = await client
      .from('vocabulary')
      .select('id')
      .eq('user_id', userId)
      .is('deleted_at', null);

    if (vocabError) {
      console.error('Error fetching vocabulary:', vocabError);
      return errorResponse('Failed to fetch vocabulary', 500);
    }

    if (!allVocab || allVocab.length === 0) {
      return jsonResponse({
        processed: 0,
        message: 'No vocabulary items found',
      });
    }

    // Get all existing learning card vocabulary IDs
    const { data: existingCards, error: cardsError } = await client
      .from('learning_cards')
      .select('vocabulary_id')
      .eq('user_id', userId)
      .is('deleted_at', null);

    if (cardsError) {
      console.error('Error fetching learning cards:', cardsError);
      return errorResponse('Failed to fetch learning cards', 500);
    }

    const existingVocabIds = new Set(existingCards?.map(c => c.vocabulary_id) || []);

    // Find vocabulary IDs without cards
    const vocabWithoutCards = allVocab.filter(v => !existingVocabIds.has(v.id));

    if (vocabWithoutCards.length === 0) {
      return jsonResponse({
        processed: 0,
        message: 'All vocabulary items already have learning cards',
      });
    }

    // Create learning cards in batches
    const batchSize = 100;
    let created = 0;
    const errors: string[] = [];

    for (let i = 0; i < vocabWithoutCards.length; i += batchSize) {
      const batch = vocabWithoutCards.slice(i, i + batchSize);

      const learningCards = batch.map(v => ({
        user_id: userId,
        vocabulary_id: v.id,
        state: 0,        // new
        due: new Date().toISOString(),
        stability: 0.0,
        difficulty: 0.0,
        reps: 0,
        lapses: 0,
        is_leech: false,
        is_pending_sync: false,
        version: 1,
      }));

      const { error: insertError } = await client
        .from('learning_cards')
        .upsert(learningCards, {
          onConflict: 'user_id,vocabulary_id',
          ignoreDuplicates: true
        });

      if (insertError) {
        console.error('Insert error:', insertError);
        errors.push(`Batch ${i / batchSize + 1}: ${insertError.message}`);
      } else {
        created += batch.length;
      }
    }

    return jsonResponse({
      processed: created,
      skipped: vocabWithoutCards.length - created,
      totalVocabulary: allVocab.length,
      errors: errors.length > 0 ? errors : undefined,
    });
  } catch (error) {
    console.error('Process learning cards error:', error);
    return errorResponse('Internal server error', 500);
  }
});
