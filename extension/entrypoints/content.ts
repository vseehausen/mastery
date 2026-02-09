import { attachWordDetector } from './content/word-detector';
import { extractSentence } from './content/context-extractor';
import {
  showLookupTooltip,
  showSignInTooltip,
  showErrorTooltip,
  showOfflineTooltip,
} from './content/tooltip';
import type { LookupMessage, ServiceWorkerResponse } from '@/lib/types';

export default defineContentScript({
  matches: ['<all_urls>'],
  main() {
    attachWordDetector(async ({ rawWord, position, anchorNode }) => {
      const sentence = extractSentence(rawWord, anchorNode);
      const url = window.location.href;
      const title = document.title;

      const message: LookupMessage = {
        type: 'lookup',
        payload: { raw_word: rawWord, sentence, url, title },
      };

      try {
        const response: ServiceWorkerResponse = await browser.runtime.sendMessage(message);

        if (!response) return;

        switch (response.type) {
          case 'lookupResult':
            showLookupTooltip(response.payload, position.x, position.y);
            break;
          case 'needsAuth':
            showSignInTooltip(position.x, position.y);
            break;
          case 'error':
            if (response.offline) {
              showOfflineTooltip(position.x, position.y);
            } else {
              showErrorTooltip(
                response.message || "Couldn't translate — try again",
                position.x,
                position.y,
              );
            }
            break;
        }
      } catch (err) {
        console.error('[Mastery] Lookup failed:', err);
        showErrorTooltip("Couldn't translate — try again", position.x, position.y);
      }
    });

    // Listen for context menu lookup results from the service worker
    browser.runtime.onMessage.addListener((message: ServiceWorkerResponse) => {
      if (message.type === 'lookupResult' && 'fromContextMenu' in message) {
        const selection = window.getSelection();
        if (selection && !selection.isCollapsed) {
          const range = selection.getRangeAt(0);
          const rect = range.getBoundingClientRect();
          showLookupTooltip(message.payload, rect.left, rect.bottom);
        }
      }
    });
  },
});
