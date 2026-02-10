import type { CacheEntry, LookupResponse } from './types';

const MAX_ENTRIES = 5000;
const EVICT_COUNT = 500;

async function getStorageMap<T>(key: string): Promise<Record<string, T>> {
  const result = await browser.storage.local.get(key);
  return (result[key] as Record<string, T>) ?? ({} as Record<string, T>);
}

export async function getCachedWord(lemmaOrRawWord: string): Promise<CacheEntry | null> {
  const vocabulary = await getStorageMap<CacheEntry>('vocabulary');
  const entry = vocabulary[lemmaOrRawWord];
  if (!entry) return null;
  entry.lastAccessed = Date.now();
  entry.lookupCount++;
  vocabulary[lemmaOrRawWord] = entry;
  await browser.storage.local.set({ vocabulary });
  return entry;
}

export async function setCachedWord(response: LookupResponse): Promise<void> {
  const vocabulary = await getStorageMap<CacheEntry>('vocabulary');

  const existing = vocabulary[response.lemma];
  const entry: CacheEntry = {
    lemma: response.lemma,
    translation: response.translation,
    pronunciation: response.pronunciation,
    stage: response.stage,
    lookupCount: (existing?.lookupCount ?? 0) + 1,
    lastAccessed: Date.now(),
    provisional: response.provisional ?? false,
    englishDefinition: response.english_definition,
    partOfSpeech: response.part_of_speech,
    synonyms: existing?.synonyms, // Preserve existing synonyms if any
  };

  // Store under lemma
  vocabulary[response.lemma] = entry;

  // Also create alias under raw_word if different from lemma
  if (response.raw_word !== response.lemma) {
    vocabulary[response.raw_word] = entry;
  }

  const keys = Object.keys(vocabulary);
  if (keys.length > MAX_ENTRIES) {
    const sorted = keys
      .map((k) => ({ key: k, lastAccessed: vocabulary[k].lastAccessed }))
      .sort((a, b) => a.lastAccessed - b.lastAccessed);
    const toRemove = sorted.slice(0, EVICT_COUNT);
    for (const { key } of toRemove) {
      delete vocabulary[key];
    }
  }

  await browser.storage.local.set({ vocabulary });
}

export async function getPageWords(url: string): Promise<string[]> {
  const pageWords = await getStorageMap<string[]>('pageWords');
  return pageWords[url] ?? [];
}

export async function addPageWord(url: string, lemma: string): Promise<void> {
  const pageWords = await getStorageMap<string[]>('pageWords');
  const words = pageWords[url] ?? [];
  if (!words.includes(lemma)) {
    words.push(lemma);
    pageWords[url] = words;
    await browser.storage.local.set({ pageWords });
  }
}

export async function clearPageWords(url: string): Promise<void> {
  const pageWords = await getStorageMap<string[]>('pageWords');
  delete pageWords[url];
  await browser.storage.local.set({ pageWords });
}
