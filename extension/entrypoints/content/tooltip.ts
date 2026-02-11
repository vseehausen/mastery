import type { LookupResponse, ProgressStage, TooltipDetail } from '@/lib/types';
import appCss from '@/entrypoints/app.css?inline';

const TOOLTIP_ID = 'mastery-tooltip-host';
const FONT_LINK_ID = 'mastery-fonts';

const STAGE_NAMES: Record<ProgressStage, string> = {
  new: 'New',
  practicing: 'Practicing',
  stabilizing: 'Stabilizing',
  known: 'Known',
  mastered: 'Mastered',
};

const STAGE_ORDER: ProgressStage[] = ['new', 'practicing', 'stabilizing', 'known', 'mastered'];

const REVIEW_TEXT: Record<ProgressStage, string | null> = {
  new: null,
  practicing: 'Next review tomorrow',
  stabilizing: 'Next in 5d',
  known: 'Next in 14d',
  mastered: 'Next in 42d',
};

function ensureFonts(): void {
  if (document.getElementById(FONT_LINK_ID)) return;
  const link = document.createElement('link');
  link.id = FONT_LINK_ID;
  link.rel = 'stylesheet';
  link.href =
    'https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Literata:ital,wght@0,400;0,500;0,600;1,400;1,500&family=JetBrains+Mono:wght@400;500&display=swap';
  document.head.appendChild(link);
}

// ---------------------------------------------------------------------------
// Styles — tokens from app.css, layout/component CSS here
// ---------------------------------------------------------------------------

function createStyles(): string {
  return `
    ${appCss}

    :host {
      all: initial;
      position: fixed;
      z-index: 2147483647;
    }

    /* Override Tailwind preflight: SVGs must stay inline in our layout */
    svg {
      display: inline-block;
      vertical-align: middle;
    }

    /* ---- Card shell ---- */
    .tooltip {
      background: var(--card);
      border-radius: var(--radius-card);
      width: 270px;
      box-shadow: 0 8px 30px rgba(0, 0, 0, var(--shadow-alpha));
      border: 1px solid var(--border);
      overflow: hidden;
      animation: mastery-fade-in 0.15s ease-out;
    }

    @keyframes mastery-fade-in {
      from { opacity: 0; transform: translateY(4px); }
      to { opacity: 1; transform: translateY(0); }
    }

    /* ---- Accent bar (stage colour) ---- */
    .accent-bar {
      display: block;
      width: 100%;
      height: 3px;
      background: var(--sc);
    }

    .tooltip-body {
      padding: calc(var(--spacing) * 3) calc(var(--spacing) * 4) calc(var(--spacing) * 4);
    }

    /* ---- Header: raw word + badge ---- */
    .header {
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .header--no-ipa { margin-bottom: var(--spacing); }

    .raw-word {
      font-family: var(--font-serif);
      font-size: var(--text-sm);
      font-weight: var(--font-weight-normal);
      line-height: 1;
      color: var(--muted-foreground);
    }

    /* ---- Stage badge (dots + label) ---- */
    .badge {
      display: inline-flex;
      align-items: center;
      gap: var(--spacing);
      font-family: var(--font-sans);
      font-size: var(--text-xs);
      font-weight: var(--font-weight-semibold);
      line-height: 1;
      padding: var(--spacing) calc(var(--spacing) * 2) var(--spacing) 6px;
      border-radius: var(--radius-badge);
      background: var(--sbg);
      color: var(--sc);
      border: 1px solid color-mix(in srgb, var(--sc) 15%, transparent);
    }

    .badge-dots { display: flex; gap: 2px; }

    .badge-dot {
      width: 3px;
      height: 3px;
      border-radius: 50%;
    }

    .badge-dot--filled  { background: var(--sc); }
    .badge-dot--empty   { background: var(--dim); }

    /* ---- IPA ---- */
    .ipa {
      font-family: var(--font-mono);
      font-size: var(--text-xs);
      font-weight: var(--font-weight-normal);
      line-height: 1;
      color: var(--dim);
      margin-top: 1px;
      margin-bottom: var(--spacing);
    }

    /* ---- Translation + part-of-speech ---- */
    .translation-row {
      display: flex;
      align-items: baseline;
      gap: 6px;
    }

    .translation {
      font-family: var(--font-sans);
      font-size: var(--text-lg);
      font-weight: var(--font-weight-semibold);
      line-height: var(--leading-tight);
      color: var(--card-foreground);
    }

    .pos {
      font-family: var(--font-sans);
      font-size: var(--text-xs);
      font-weight: var(--font-weight-normal);
      line-height: 1;
      color: var(--dim);
    }

    /* ---- Divider + definition (Variant B: serif italic) ---- */
    .divider {
      height: 1px;
      background: var(--muted);
      margin: calc(var(--spacing) * 3) 0 calc(var(--spacing) * 2);
    }

    .definition {
      font-family: var(--font-serif);
      font-size: var(--text-xs);
      font-style: italic;
      font-weight: var(--font-weight-normal);
      line-height: 1.6;
      color: var(--muted-foreground);
    }

    /* ---- Context sentence ---- */
    .context {
      margin-top: calc(var(--spacing) * 2);
      font-family: var(--font-serif);
      font-size: var(--text-xs);
      font-weight: var(--font-weight-normal);
      line-height: 1.6;
      color: var(--muted-foreground);
    }

    .context-label {
      font-family: var(--font-sans);
      font-size: var(--text-xs);
      font-weight: var(--font-weight-medium);
      color: var(--dim);
      margin-bottom: 2px;
    }

    .context-translated {
      margin-top: 2px;
      font-style: italic;
      color: var(--dim);
    }

    /* ---- Footer ---- */
    .footer {
      margin-top: calc(var(--spacing) * 3);
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .footer-left {
      display: flex;
      align-items: center;
      gap: var(--spacing);
      color: var(--sc);
    }

    .footer-text {
      font-family: var(--font-sans);
      font-size: var(--text-xs);
      font-weight: var(--font-weight-normal);
      line-height: 1;
      color: var(--muted-foreground);
    }

    .footer-review {
      font-family: var(--font-sans);
      font-size: var(--text-xs);
      font-weight: var(--font-weight-normal);
      line-height: 1;
      color: var(--dim);
    }

    /* ---- Loading state ---- */
    .state-body { padding: calc(var(--spacing) * 4); }

    .loading {
      display: flex;
      align-items: center;
      gap: calc(var(--spacing) * 2);
    }

    .spinner {
      width: calc(var(--spacing) * 4);
      height: calc(var(--spacing) * 4);
      border: 2px solid var(--border);
      border-top-color: var(--muted-foreground);
      border-radius: 50%;
      animation: mastery-spin 0.6s linear infinite;
    }

    @keyframes mastery-spin { to { transform: rotate(360deg); } }

    .loading-text {
      font-family: var(--font-sans);
      font-size: var(--text-sm);
      font-weight: var(--font-weight-normal);
      line-height: 1;
      color: var(--muted-foreground);
    }

    /* ---- Error / sign-in states ---- */
    .error-text {
      font-family: var(--font-sans);
      font-size: var(--text-sm);
      font-weight: var(--font-weight-normal);
      line-height: var(--leading-normal);
      color: var(--destructive);
    }

    .sign-in-title {
      font-family: var(--font-sans);
      font-size: var(--text-base);
      font-weight: var(--font-weight-semibold);
      line-height: 1;
      color: var(--card-foreground);
      margin-bottom: calc(var(--spacing) * 2);
    }

    .sign-in-text {
      font-family: var(--font-sans);
      font-size: var(--text-sm);
      font-weight: var(--font-weight-normal);
      line-height: var(--leading-normal);
      color: var(--muted-foreground);
    }
  `;
}

// ---------------------------------------------------------------------------
// HTML renderers
// ---------------------------------------------------------------------------

function renderBadge(stage: ProgressStage): string {
  const idx = STAGE_ORDER.indexOf(stage);
  const dots = STAGE_ORDER.map(
    (_, i) => `<span class="badge-dot ${i <= idx ? 'badge-dot--filled' : 'badge-dot--empty'}"></span>`,
  ).join('');

  return `<span class="badge"><span class="badge-dots">${dots}</span>${STAGE_NAMES[stage]}</span>`;
}

const CHECK_SVG =
  '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';

/**
 * Render tooltip content based on the detail level:
 *
 * | Element             | Compact | Standard | Full |
 * |---------------------|---------|----------|------|
 * | Raw word + badge    | Yes     | Yes      | Yes  |
 * | IPA pronunciation   | No      | Yes      | Yes  |
 * | Translation + POS   | Yes     | Yes      | Yes  |
 * | Definition          | No      | Yes      | Yes  |
 * | Context sentence    | No      | No       | Yes  |
 * | Footer              | Yes     | Yes      | Yes  |
 */
function renderTooltipContent(data: LookupResponse, detail: TooltipDetail = 'standard'): string {
  const { stage, pronunciation, part_of_speech, english_definition, is_new, context_original, context_translated } = data;
  const showIPA = detail !== 'compact' && !!pronunciation;
  const showDef = detail !== 'compact' && !!english_definition;
  const showContext = detail === 'full' && (!!context_original || !!context_translated);
  const hasPOS = !!part_of_speech;
  const review = REVIEW_TEXT[stage];

  return `
    <div class="tooltip-root">
      <div class="tooltip" style="--sc:var(--stage-${stage});--sbg:var(--stage-${stage}-bg)">
        <div class="accent-bar"></div>
        <div class="tooltip-body">
          <div class="header${showIPA ? '' : ' header--no-ipa'}">
            <span class="raw-word">${escapeHtml(data.raw_word)}</span>
            ${renderBadge(stage)}
          </div>
          ${showIPA ? `<div class="ipa">${escapeHtml(pronunciation)}</div>` : ''}
          <div class="translation-row">
            <span class="translation">${escapeHtml(data.translation)}</span>
            ${hasPOS ? `<span class="pos">${escapeHtml(part_of_speech!)}</span>` : ''}
          </div>
          ${showDef ? `
          <div class="divider"></div>
          <div class="definition">${escapeHtml(english_definition)}</div>
          ` : ''}
          ${showContext ? `
          <div class="context">
            ${context_original ? `<div>${formatContext(context_original)}</div>` : ''}
            ${context_translated ? `<div class="context-translated">${formatContext(context_translated)}</div>` : ''}
          </div>
          ` : ''}
          <div class="footer">
            <div class="footer-left">
              ${CHECK_SVG}
              <span class="footer-text">${is_new ? 'Saved to vocabulary' : 'In your vocabulary'}</span>
            </div>
            ${review ? `<span class="footer-review">${review}</span>` : ''}
          </div>
        </div>
      </div>
    </div>`;
}

function renderLoading(word: string): string {
  return `
    <div class="tooltip-root">
      <div class="tooltip">
        <div class="state-body">
          <div class="loading">
            <div class="spinner"></div>
            <span class="loading-text">Looking up "${escapeHtml(word)}"…</span>
          </div>
        </div>
      </div>
    </div>`;
}

function renderSignInPrompt(): string {
  return `
    <div class="tooltip-root">
      <div class="tooltip">
        <div class="state-body">
          <div class="sign-in-title">Mastery</div>
          <div class="sign-in-text">Sign in via the extension popup to look up words.</div>
        </div>
      </div>
    </div>`;
}

function renderError(message: string): string {
  return `
    <div class="tooltip-root">
      <div class="tooltip">
        <div class="state-body">
          <div class="error-text">${escapeHtml(message)}</div>
        </div>
      </div>
    </div>`;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function escapeHtml(text: string): string {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

/** Format context text: converts *word* markers to bold */
function formatContext(text: string): string {
  return escapeHtml(text).replace(/\*([^*]+)\*/g, '<strong>$1</strong>');
}

// ---------------------------------------------------------------------------
// Tooltip lifecycle (show / position / dismiss)
// ---------------------------------------------------------------------------

let currentHost: HTMLElement | null = null;
let dismissListeners: (() => void)[] = [];

function removeTooltip(): void {
  if (currentHost) {
    currentHost.remove();
    currentHost = null;
  }
  for (const cleanup of dismissListeners) cleanup();
  dismissListeners = [];
}

function positionTooltip(host: HTMLElement, x: number, y: number): void {
  const padding = 8;
  const rect = host.getBoundingClientRect();
  const vw = window.innerWidth;
  const vh = window.innerHeight;
  const w = rect.width || 290;

  let top = y + padding;
  if (top + rect.height > vh - padding) {
    top = y - rect.height - padding;
  }

  let left = x - 20;
  if (left + w > vw - padding) left = vw - w - padding;
  if (left < padding) left = padding;

  host.style.top = `${top}px`;
  host.style.left = `${left}px`;
}

function showTooltip(html: string, x: number, y: number): void {
  removeTooltip();
  ensureFonts();

  const host = document.createElement('div');
  host.id = TOOLTIP_ID;
  const shadow = host.attachShadow({ mode: 'closed' });

  const style = document.createElement('style');
  style.textContent = createStyles();
  shadow.appendChild(style);

  const container = document.createElement('div');
  container.innerHTML = html;
  shadow.appendChild(container);

  document.body.appendChild(host);
  currentHost = host;

  requestAnimationFrame(() => positionTooltip(host, x, y));

  // Auto-dismiss
  const onClickOutside = (e: MouseEvent) => {
    if (e.target instanceof Node && !host.contains(e.target)) removeTooltip();
  };
  const onScroll = () => removeTooltip();
  const onKeydown = (e: KeyboardEvent) => {
    if (e.key === 'Escape') removeTooltip();
  };

  setTimeout(() => document.addEventListener('click', onClickOutside, true), 100);
  window.addEventListener('scroll', onScroll, true);
  document.addEventListener('keydown', onKeydown);

  dismissListeners.push(
    () => document.removeEventListener('click', onClickOutside, true),
    () => window.removeEventListener('scroll', onScroll, true),
    () => document.removeEventListener('keydown', onKeydown),
  );
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

export function showLookupTooltip(data: LookupResponse, x: number, y: number, detail: TooltipDetail = 'standard'): void {
  showTooltip(renderTooltipContent(data, detail), x, y);
}

export function showSignInTooltip(x: number, y: number): void {
  showTooltip(renderSignInPrompt(), x, y);
}

export function showErrorTooltip(message: string, x: number, y: number): void {
  showTooltip(renderError(message), x, y);
}

export function showOfflineTooltip(x: number, y: number): void {
  showTooltip(renderError('Offline — translation unavailable'), x, y);
}

export function showLoadingTooltip(word: string, x: number, y: number): void {
  showTooltip(renderLoading(word), x, y);
}

export { removeTooltip };
