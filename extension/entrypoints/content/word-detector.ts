export interface WordDetection {
  rawWord: string;
  position: { x: number; y: number };
  anchorNode: Node;
}

type WordHandler = (detection: WordDetection) => void;

const IGNORED_TAGS = new Set([
  'INPUT', 'TEXTAREA', 'SELECT', 'BUTTON',
]);

function isEditableElement(el: Element): boolean {
  if (IGNORED_TAGS.has(el.tagName)) return true;
  if (el.getAttribute('contenteditable') === 'true') return true;
  if (el.closest('[contenteditable="true"]')) return true;
  return false;
}

function isValidWord(text: string): boolean {
  const trimmed = text.trim();
  if (!trimmed || trimmed.length > 50) return false;
  // Reject if purely numeric
  if (/^\d+$/.test(trimmed)) return false;
  // Reject URLs
  if (/^https?:\/\//i.test(trimmed)) return false;
  // Must contain at least one letter
  if (!/[a-zA-Z]/.test(trimmed)) return false;
  return true;
}

export function attachWordDetector(handler: WordHandler): () => void {
  const listener = (event: MouseEvent) => {
    const target = event.target;
    if (!(target instanceof Element)) return;
    if (isEditableElement(target)) return;

    const selection = window.getSelection();
    if (!selection || selection.isCollapsed) return;

    const rawWord = selection.toString().trim();
    if (!isValidWord(rawWord)) return;

    const anchorNode = selection.anchorNode;
    if (!anchorNode) return;

    handler({
      rawWord,
      position: { x: event.clientX, y: event.clientY },
      anchorNode,
    });
  };

  document.addEventListener('dblclick', listener);
  return () => document.removeEventListener('dblclick', listener);
}
