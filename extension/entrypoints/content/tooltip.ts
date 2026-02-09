import type { LookupResponse } from '@/lib/types';

const TOOLTIP_ID = 'mastery-tooltip-host';

const STAGE_COLORS: Record<string, string> = {
  new: '#3b82f6',
  practicing: '#f59e0b',
  stabilizing: '#f97316',
  known: '#10b981',
  mastered: '#8b5cf6',
};

function createStyles(): string {
  return `
    :host {
      all: initial;
      position: fixed;
      z-index: 2147483647;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }
    .tooltip {
      background: #fff;
      border: 1px solid #e2e8f0;
      border-radius: 10px;
      box-shadow: 0 8px 24px rgba(0,0,0,0.15);
      padding: 14px 16px;
      max-width: 380px;
      min-width: 260px;
      color: #1a202c;
      font-size: 14px;
      line-height: 1.5;
      animation: mastery-fade-in 0.15s ease-out;
    }
    @keyframes mastery-fade-in {
      from { opacity: 0; transform: translateY(4px); }
      to { opacity: 1; transform: translateY(0); }
    }
    .header {
      display: flex;
      align-items: baseline;
      gap: 8px;
      margin-bottom: 4px;
    }
    .lemma {
      font-size: 18px;
      font-weight: 600;
      color: #1a202c;
    }
    .ipa {
      font-size: 13px;
      color: #718096;
    }
    .translation {
      font-size: 16px;
      font-weight: 600;
      color: #2d3748;
      margin-bottom: 8px;
    }
    .divider {
      height: 1px;
      background: #e2e8f0;
      margin: 8px 0;
    }
    .context {
      font-size: 13px;
      color: #4a5568;
      margin: 4px 0;
    }
    .context em {
      font-style: italic;
      font-weight: 600;
      color: #1a202c;
    }
    .status {
      display: flex;
      align-items: center;
      gap: 6px;
      margin-top: 8px;
      font-size: 12px;
      color: #718096;
    }
    .stage-badge {
      display: inline-block;
      padding: 1px 8px;
      border-radius: 9999px;
      font-size: 11px;
      font-weight: 500;
      color: #fff;
      text-transform: capitalize;
    }
    .sign-in {
      text-align: center;
      padding: 8px 0;
    }
    .sign-in-text {
      font-size: 13px;
      color: #718096;
    }
    .error-text {
      font-size: 13px;
      color: #e53e3e;
    }
  `;
}

function formatContext(text: string): string {
  // Replace *word* with <em>word</em>
  return text.replace(/\*([^*]+)\*/g, '<em>$1</em>');
}

function renderTooltipContent(data: LookupResponse): string {
  const stageColor = STAGE_COLORS[data.stage] ?? '#718096';
  const statusText = data.is_new
    ? 'Saved'
    : 'New context saved';

  return `
    <div class="tooltip">
      <div class="header">
        <span class="lemma">${escapeHtml(data.lemma)}</span>
        <span class="ipa">${escapeHtml(data.pronunciation)}</span>
      </div>
      <div class="translation">${escapeHtml(data.translation)}</div>
      <div class="divider"></div>
      <div class="context">${formatContext(escapeHtml(data.context_original))}</div>
      <div class="context">${formatContext(escapeHtml(data.context_translated))}</div>
      <div class="status">
        <span class="stage-badge" style="background:${stageColor}">${escapeHtml(data.stage)}</span>
        <span>${statusText}</span>
      </div>
    </div>
  `;
}

function renderSignInPrompt(): string {
  return `
    <div class="tooltip">
      <div class="sign-in">
        <div class="lemma" style="margin-bottom:8px">Mastery</div>
        <div class="sign-in-text">Sign in via the extension popup to look up words.</div>
      </div>
    </div>
  `;
}

function renderError(message: string): string {
  return `
    <div class="tooltip">
      <div class="error-text">${escapeHtml(message)}</div>
    </div>
  `;
}

function escapeHtml(text: string): string {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

let currentHost: HTMLElement | null = null;
let dismissListeners: (() => void)[] = [];

function removeTooltip(): void {
  if (currentHost) {
    currentHost.remove();
    currentHost = null;
  }
  for (const cleanup of dismissListeners) {
    cleanup();
  }
  dismissListeners = [];
}

function positionTooltip(host: HTMLElement, x: number, y: number): void {
  const padding = 8;
  const tooltipRect = host.getBoundingClientRect();
  const viewportH = window.innerHeight;

  let top = y + padding;
  // Flip above if near bottom
  if (top + tooltipRect.height > viewportH - padding) {
    top = y - tooltipRect.height - padding;
  }

  let left = x - 20;
  const viewportW = window.innerWidth;
  if (left + 400 > viewportW) {
    left = viewportW - 400 - padding;
  }
  if (left < padding) {
    left = padding;
  }

  host.style.top = `${top}px`;
  host.style.left = `${left}px`;
}

function showTooltip(html: string, x: number, y: number): void {
  removeTooltip();

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

  // Position after rendering so we can measure
  requestAnimationFrame(() => {
    positionTooltip(host, x, y);
  });

  // Auto-dismiss on click outside or scroll
  const onClickOutside = (e: MouseEvent) => {
    if (e.target instanceof Node && !host.contains(e.target)) {
      removeTooltip();
    }
  };
  const onScroll = () => removeTooltip();
  const onKeydown = (e: KeyboardEvent) => {
    if (e.key === 'Escape') removeTooltip();
  };

  // Delay adding click listener to avoid immediate dismissal from the dblclick
  setTimeout(() => {
    document.addEventListener('click', onClickOutside, true);
  }, 100);
  window.addEventListener('scroll', onScroll, true);
  document.addEventListener('keydown', onKeydown);

  dismissListeners.push(
    () => document.removeEventListener('click', onClickOutside, true),
    () => window.removeEventListener('scroll', onScroll, true),
    () => document.removeEventListener('keydown', onKeydown),
  );
}

export function showLookupTooltip(data: LookupResponse, x: number, y: number): void {
  showTooltip(renderTooltipContent(data), x, y);
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

export { removeTooltip };
