import { lookupWord } from '@/lib/api-client';
import { isAuthenticated } from '@/lib/auth';
import { getCachedWord, setCachedWord, addPageWord, clearPageWords } from '@/lib/cache';
import type {
  ContentMessage,
  LookupRequest,
  ServiceWorkerResponse,
  LookupResponse,
} from '@/lib/types';

export default defineBackground(() => {
  console.log('[Mastery] Background script loaded');
  // Register context menu on install
  browser.runtime.onInstalled.addListener(() => {
    console.log('[Mastery] Extension installed/updated');
    browser.contextMenus.create({
      id: 'mastery-lookup',
      title: 'Look up in Mastery',
      contexts: ['selection'],
    });
  });

  // Handle messages from content script
  browser.runtime.onMessage.addListener(
    (message: ContentMessage, _sender, sendResponse: (response: ServiceWorkerResponse) => void) => {
      if (message.type === 'lookup') {
        handleLookup(message.payload).then(sendResponse);
        return true; // Keep the message channel open for async response
      }
    },
  );

  // Handle context menu clicks
  browser.contextMenus.onClicked.addListener(async (info, tab) => {
    if (info.menuItemId !== 'mastery-lookup' || !info.selectionText || !tab?.id) return;

    const request: LookupRequest = {
      raw_word: info.selectionText.trim().slice(0, 100),
      sentence: info.selectionText.trim(), // Best we can do from context menu
      url: tab.url ?? '',
      title: tab.title ?? '',
    };

    const response = await handleLookup(request);

    // Send result to content script for tooltip rendering
    browser.tabs.sendMessage(tab.id, {
      ...response,
      fromContextMenu: true,
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
  // Check auth
  const authed = await isAuthenticated();
  if (!authed) {
    return { type: 'needsAuth' };
  }

  // Check cache first
  const cached = await getCachedWord(request.raw_word.toLowerCase());
  if (cached) {
    // Return cached data immediately, then update in background
    const cachedResponse: LookupResponse = {
      lemma: cached.lemma,
      raw_word: request.raw_word,
      translation: cached.translation,
      pronunciation: cached.pronunciation,
      part_of_speech: null,
      english_definition: '',
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
    return { type: 'error', message: 'Offline — translation unavailable', offline: true };
  }

  // API lookup
  try {
    const response = await lookupWord(request);
    await setCachedWord(response);
    await addPageWord(request.url, response.lemma);
    return { type: 'lookupResult', payload: response, fromCache: false };
  } catch (err) {
    console.error('[Mastery] Lookup error:', err);
    return {
      type: 'error',
      message: "Couldn't translate — try again",
    };
  }
}
