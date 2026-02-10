export type TooltipDetail = 'compact' | 'standard' | 'full';

export interface Settings {
  nativeLanguage: string;
  tooltipDetail: TooltipDetail;
  autoCapture: boolean;
  pausedSites: string[];
}

const DEFAULTS: Settings = {
  nativeLanguage: 'de',
  tooltipDetail: 'standard',
  autoCapture: true,
  pausedSites: [],
};

const STORAGE_KEY = 'masterySettings';

export async function getSettings(): Promise<Settings> {
  const result = await browser.storage.local.get(STORAGE_KEY);
  const stored = result[STORAGE_KEY] as Partial<Settings> | undefined;
  return { ...DEFAULTS, ...stored };
}

export async function updateSettings(partial: Partial<Settings>): Promise<Settings> {
  const current = await getSettings();
  const updated = { ...current, ...partial };
  await browser.storage.local.set({ [STORAGE_KEY]: updated });
  return updated;
}

export async function isSitePaused(domain: string): Promise<boolean> {
  const settings = await getSettings();
  return settings.pausedSites.includes(domain);
}
