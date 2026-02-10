// From the OpenAPI spec:
export interface LookupRequest {
  raw_word: string; // max 100 chars
  sentence: string; // max 500 chars
  url: string;
  title: string; // max 500 chars
}

export interface LookupResponse {
  lemma: string;
  raw_word: string;
  translation: string;
  pronunciation: string;
  part_of_speech: string | null;
  english_definition: string;
  context_original: string; // original sentence with *word* wrapped in asterisks
  context_translated: string; // translated sentence with *word* wrapped in asterisks
  stage: ProgressStage;
  is_new: boolean;
  vocabulary_id: string;
}

export type ProgressStage = 'new' | 'practicing' | 'stabilizing' | 'known' | 'mastered';

export interface StatsResponse {
  total_words: number;
  page_words: PageWord[];
}

export interface PageWord {
  lemma: string;
  translation: string;
  stage: ProgressStage;
}

export interface ErrorResponse {
  error: string;
  message: string;
  details?: unknown;
}

// Local cache types (chrome.storage.local)
export interface CacheEntry {
  lemma: string;
  translation: string;
  pronunciation: string;
  stage: ProgressStage;
  lookupCount: number;
  lastAccessed: number; // Unix timestamp for LRU eviction
  // Enrichment fields (may be populated after initial lookup)
  englishDefinition?: string;
  partOfSpeech?: string | null;
  synonyms?: string[];
}

export interface ExtensionStorage {
  vocabulary: Record<string, CacheEntry>; // keyed by lemma, max ~5,000
  settings: {
    nativeLanguage: string; // e.g. "de"
  };
  auth: {
    accessToken: string;
    refreshToken: string;
    userId: string;
    expiresAt: number;
  };
  pageWords: Record<string, string[]>; // keyed by tab URL, value = lemmas
}

// Message types for content script <-> service worker communication
export interface LookupMessage {
  type: 'lookup';
  payload: LookupRequest;
}

export interface LookupResultMessage {
  type: 'lookupResult';
  payload: LookupResponse;
  fromCache: boolean;
}

export interface ContextMenuLookupMessage {
  type: 'contextMenuLookup';
  payload: LookupResponse;
}

export interface NeedsAuthMessage {
  type: 'needsAuth';
}

export interface ErrorMessage {
  type: 'error';
  message: string;
  offline?: boolean;
}

export interface LookupUpdateMessage {
  type: 'lookupUpdate';
  payload: LookupResponse;
}

export type ServiceWorkerResponse =
  | LookupResultMessage
  | NeedsAuthMessage
  | ErrorMessage;

export type ContentMessage = LookupMessage;
