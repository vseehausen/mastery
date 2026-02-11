import { lookupWord, triggerEnrichmentIfNeeded, getSupabaseClient } from '@/lib/api-client';
import { isAuthenticated, signInWithOAuth, type OAuthProvider } from '@/lib/auth';
import { getCachedWord, setCachedWord, addPageWord, clearPageWords } from '@/lib/cache';
import type {
  ContentMessage,
  LookupRequest,
  ServiceWorkerResponse,
  LookupResponse,
  LookupUpdateMessage,
} from '@/lib/types';

console.log('[Mastery] Background script file loaded (top level)');

export default defineBackground(() => {
  console.log('[Mastery] Background script defineBackground callback running');
  // Register context menu on install
  browser.runtime.onInstalled.addListener(() => {
    console.log('[Mastery] Extension installed/updated - creating context menu');
    browser.contextMenus.create({
      id: 'mastery-lookup',
      title: 'Look up in Mastery',
      contexts: ['selection'],
    });
  });

  // Handle messages from content script and popup
  browser.runtime.onMessage.addListener(
    (message: any, _sender, sendResponse: (response: any) => void) => {
      console.log('[Mastery] ✨ NEW VERSION ✨ Background received message:', message.type, 'Full message:', message);

      if (message.type === 'lookup') {
        console.log('[Mastery] Handling lookup for:', message.payload.raw_word);
        handleLookup(message.payload).then(sendResponse);
        return true;
      }

      if (message.type === 'oauth') {
        console.log('[Mastery] ⚡ OAUTH HANDLER TRIGGERED for provider:', message.provider);
        signInWithOAuth(message.provider)
          .then((result) => {
            console.log('[Mastery] ✅ OAuth completed with result:', result);
            sendResponse(result);
          })
          .catch((err) => {
            console.error('[Mastery] ❌ OAuth failed with error:', err);
            sendResponse({ error: err.message });
          });
        return true;
      }

      console.log('[Mastery] ⚠️ Unknown message type:', message.type);
      return false;
    },
  );

  // Handle context menu clicks
  browser.contextMenus.onClicked.addListener(async (info, tab) => {
    console.log('[Mastery] Context menu clicked:', info.menuItemId, info.selectionText);
    if (info.menuItemId !== 'mastery-lookup' || !info.selectionText || !tab?.id) {
      console.log('[Mastery] Context menu ignored - missing data');
      return;
    }

    const request: LookupRequest = {
      raw_word: info.selectionText.trim().slice(0, 100),
      sentence: info.selectionText.trim(), // Best we can do from context menu
      url: tab.url ?? '',
      title: tab.title ?? '',
    };

    const response = await handleLookup(request);
    console.log('[Mastery] Context menu lookup response:', response);

    // Send result to content script for tooltip rendering
    browser.tabs.sendMessage(tab.id, {
      ...response,
      fromContextMenu: true,
    }).catch(err => {
      console.error('[Mastery] Failed to send context menu result to tab:', err);
    });
  });

  // Clear page words when tab navigates
  browser.tabs.onUpdated.addListener((_tabId, changeInfo) => {
    if (changeInfo.url) {
      clearPageWords(changeInfo.url);
    }
  });
});

async function handleLookup(request: LookupRequest): Promise<ServiceWorkerResponse> {
  console.log('[Mastery] handleLookup started for:', request.raw_word);

  // Check auth
  const authed = await isAuthenticated();
  console.log('[Mastery] Auth check:', authed ? 'authenticated' : 'not authenticated');
  if (!authed) {
    return { type: 'needsAuth' };
  }

  // Check cache first (bypass provisional entries — they have unverified translations)
  const cached = await getCachedWord(request.raw_word.toLowerCase());
  const cacheUsable = cached && !cached.provisional;
  console.log('[Mastery] Cache check:', cached ? (cacheUsable ? 'HIT' : 'HIT (provisional, bypassing)') : 'MISS');
  if (cacheUsable) {
    console.log('[Mastery] Returning cached result for:', request.raw_word);
    // Return cached data immediately, then update in background
    const cachedResponse: LookupResponse = {
      lemma: cached.lemma,
      raw_word: request.raw_word,
      translation: cached.translation,
      pronunciation: cached.pronunciation,
      part_of_speech: cached.partOfSpeech ?? null,
      english_definition: cached.englishDefinition ?? '',
      context_original: request.sentence,
      context_translated: '',
      stage: cached.stage,
      is_new: false,
      vocabulary_id: '',
    };

    // Background update: call API to record the encounter and get fresh data
    lookupWord(request)
      .then((fresh) => {
        setCachedWord(fresh);
        addPageWord(request.url, fresh.lemma);
      })
      .catch((err) => console.error('[Mastery] Background update failed:', err));

    return { type: 'lookupResult', payload: cachedResponse, fromCache: true };
  }

  // Check online status
  if (!navigator.onLine) {
    console.log('[Mastery] Offline, cannot lookup');
    return { type: 'error', message: 'Offline — translation unavailable', offline: true };
  }

  // API lookup
  console.log('[Mastery] Calling API for word:', request.raw_word);
  try {
    const response = await lookupWord(request);
    console.log('[Mastery] API response received:', response);
    await setCachedWord(response);
    await addPageWord(request.url, response.lemma);

    // If this is a new word, trigger enrichment in background (fire-and-forget)
    if (response.is_new) {
      console.log('[Mastery] New word detected, triggering background enrichment');
      triggerEnrichmentIfNeeded(); // No await - fire and forget
    }

    // For non-global-dict words (no english_definition), schedule progressive update
    if (!response.english_definition) {
      console.log('[Mastery] Non-global-dict word, scheduling enrichment check');
      scheduleProgressiveUpdate(response.lemma, request);
    }

    console.log('[Mastery] Returning fresh lookup result');
    return { type: 'lookupResult', payload: response, fromCache: false };
  } catch (err) {
    console.error('[Mastery] Lookup error:', err);
    console.error('[Mastery] Error details:', {
      name: (err as Error).name,
      message: (err as Error).message,
      stack: (err as Error).stack,
    });
    return {
      type: 'error',
      message: "Couldn't translate — try again",
    };
  }
}

async function scheduleProgressiveUpdate(lemma: string, originalRequest: LookupRequest): Promise<void> {
  // Wait 6 seconds for enrichment to potentially complete
  setTimeout(async () => {
    try {
      console.log('[Mastery] Checking for enrichment updates for:', lemma);

      // Query vocabulary table to get fresh enrichment data
      const supabase = getSupabaseClient();
      const { data: vocabData, error } = await supabase
        .from('vocabulary')
        .select('lemma, translation, pronunciation, english_definition, part_of_speech, stage')
        .eq('lemma', lemma)
        .single();

      if (error || !vocabData) {
        console.log('[Mastery] No enrichment update found for:', lemma);
        return;
      }

      // Check if enrichment data is now available
      if (vocabData.english_definition) {
        console.log('[Mastery] Enrichment found! Updating cache and notifying tabs');

        // Update cache with enrichment data
        const enrichedResponse: LookupResponse = {
          lemma: vocabData.lemma,
          raw_word: originalRequest.raw_word,
          translation: vocabData.translation,
          pronunciation: vocabData.pronunciation,
          part_of_speech: vocabData.part_of_speech,
          english_definition: vocabData.english_definition,
          context_original: originalRequest.sentence,
          context_translated: '',
          stage: vocabData.stage,
          is_new: false,
          vocabulary_id: '',
        };

        await setCachedWord(enrichedResponse);

        // Notify all tabs about the update
        const tabs = await browser.tabs.query({});
        const updateMessage: LookupUpdateMessage = {
          type: 'lookupUpdate',
          payload: enrichedResponse,
        };

        for (const tab of tabs) {
          if (tab.id) {
            browser.tabs.sendMessage(tab.id, updateMessage).catch(() => {
              // Tab might not have content script, ignore
            });
          }
        }
      }
    } catch (err) {
      console.error('[Mastery] Progressive update failed:', err);
    }
  }, 6000);
}
