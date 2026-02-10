import { attachWordDetector } from './content/word-detector';
import { extractSentence } from './content/context-extractor';
import {
  showLookupTooltip,
  showSignInTooltip,
  showErrorTooltip,
  showOfflineTooltip,
  showLoadingTooltip,
} from './content/tooltip';
import type { LookupMessage, ServiceWorkerResponse, LookupUpdateMessage, TooltipDetail } from '@/lib/types';

export default defineContentScript({
  matches: ['<all_urls>'],
  main() {
    console.log('[Mastery] Content script loaded');

    // Settings state — read from storage, updated via storage.onChanged
    let tooltipDetail: TooltipDetail = 'standard';
    let pausedSites: string[] = [];
    let autoCapture = true;

    interface StoredSettings {
      tooltipDetail?: TooltipDetail;
      pausedSites?: string[];
      autoCapture?: boolean;
    }

    // Load initial settings
    browser.storage.local.get('masterySettings').then((result) => {
      const s = result.masterySettings as StoredSettings | undefined;
      if (s) {
        tooltipDetail = s.tooltipDetail ?? 'standard';
        pausedSites = s.pausedSites ?? [];
        autoCapture = s.autoCapture ?? true;
      }
    });

    // React to settings changes from popup
    browser.storage.onChanged.addListener((changes, area) => {
      if (area === 'local' && changes.masterySettings) {
        const s = changes.masterySettings.newValue as StoredSettings | undefined;
        if (s) {
          tooltipDetail = s.tooltipDetail ?? 'standard';
          pausedSites = s.pausedSites ?? [];
          autoCapture = s.autoCapture ?? true;
        }
      }
    });

    function isSitePaused(): boolean {
      try {
        const domain = window.location.hostname;
        return pausedSites.includes(domain);
      } catch {
        return false;
      }
    }

    // Store current tooltip position and lemma for progressive updates
    let currentTooltipData: { lemma: string; x: number; y: number } | null = null;

    attachWordDetector(async ({ rawWord, position, anchorNode }) => {
      // Skip if site is paused or auto-capture is disabled
      if (isSitePaused() || !autoCapture) return;

      console.log('[Mastery] Word detected:', rawWord);

      // Show loading tooltip immediately
      showLoadingTooltip(rawWord, position.x, position.y);

      const sentence = extractSentence(rawWord, anchorNode);
      const url = window.location.href;
      const title = document.title;

      const message: LookupMessage = {
        type: 'lookup',
        payload: { raw_word: rawWord, sentence, url, title },
      };

      try {
        console.log('[Mastery] Sending lookup message to background');
        const response: ServiceWorkerResponse = await browser.runtime.sendMessage(message);
        console.log('[Mastery] Received response from background:', response);

        if (!response) {
          console.warn('[Mastery] No response from background');
          return;
        }

        switch (response.type) {
          case 'lookupResult':
            showLookupTooltip(response.payload, position.x, position.y, tooltipDetail);
            currentTooltipData = { lemma: response.payload.lemma, x: position.x, y: position.y };
            break;
          case 'needsAuth':
            showSignInTooltip(position.x, position.y);
            currentTooltipData = null;
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
            currentTooltipData = null;
            break;
        }
      } catch (err) {
        console.error('[Mastery] Lookup failed:', err);
        showErrorTooltip("Couldn't translate — try again", position.x, position.y);
        currentTooltipData = null;
      }
    });

    // Listen for context menu lookup results and progressive updates from the service worker
    browser.runtime.onMessage.addListener((message: ServiceWorkerResponse | LookupUpdateMessage) => {
      if (message.type === 'lookupResult' && 'fromContextMenu' in message) {
        const selection = window.getSelection();
        if (selection && !selection.isCollapsed) {
          const range = selection.getRangeAt(0);
          const rect = range.getBoundingClientRect();
          showLookupTooltip(message.payload, rect.left, rect.bottom, tooltipDetail);
          currentTooltipData = { lemma: message.payload.lemma, x: rect.left, y: rect.bottom };
        }
      } else if (message.type === 'lookupUpdate') {
        // Progressive update: re-render tooltip with enriched data if it's still showing
        if (currentTooltipData && currentTooltipData.lemma === message.payload.lemma) {
          console.log('[Mastery] Received progressive update, re-rendering tooltip');
          showLookupTooltip(message.payload, currentTooltipData.x, currentTooltipData.y, tooltipDetail);
        }
      }
    });
  },
});
