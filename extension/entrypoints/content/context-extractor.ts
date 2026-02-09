const BLOCK_ELEMENTS = new Set([
  'P', 'DIV', 'LI', 'TD', 'TH', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6',
  'BLOCKQUOTE', 'ARTICLE', 'SECTION', 'FIGCAPTION', 'DD', 'DT',
]);

// Sentence boundary: period/exclamation/question followed by whitespace or end
const SENTENCE_BOUNDARY = /[.!?](?:\s|$)/;

function getBlockParent(node: Node): Element {
  let current: Node | null = node;
  while (current) {
    if (current instanceof Element && BLOCK_ELEMENTS.has(current.tagName)) {
      return current;
    }
    current = current.parentNode;
  }
  // Fallback to body or the node's parent element
  return (node instanceof Element ? node : node.parentElement) ?? document.body;
}

function getTextContent(element: Element): string {
  return element.textContent?.replace(/\s+/g, ' ').trim() ?? '';
}

export function extractSentence(word: string, anchorNode: Node): string {
  const block = getBlockParent(anchorNode);
  const fullText = getTextContent(block);

  if (!fullText) return '';

  // Find the word in the text
  const wordIndex = fullText.toLowerCase().indexOf(word.toLowerCase());
  if (wordIndex === -1) {
    // Fallback: return first 200 chars
    return fullText.slice(0, 200);
  }

  // Walk backwards from word to find sentence start
  let sentenceStart = 0;
  for (let i = wordIndex - 1; i >= 0; i--) {
    if (SENTENCE_BOUNDARY.test(fullText.slice(i, i + 2))) {
      sentenceStart = i + 2; // Skip the punctuation + space
      break;
    }
  }

  // Walk forwards from word to find sentence end
  let sentenceEnd = fullText.length;
  const searchFrom = wordIndex + word.length;
  for (let i = searchFrom; i < fullText.length; i++) {
    if (SENTENCE_BOUNDARY.test(fullText.slice(i, i + 2))) {
      sentenceEnd = i + 1; // Include the punctuation
      break;
    }
  }

  const sentence = fullText.slice(sentenceStart, sentenceEnd).trim();

  // If no sentence boundary found and text is very long, limit to 200 chars around the word
  if (sentence.length > 300) {
    const relativeWordIndex = wordIndex - sentenceStart;
    const start = Math.max(0, relativeWordIndex - 100);
    const end = Math.min(sentence.length, relativeWordIndex + word.length + 100);
    return sentence.slice(start, end).trim();
  }

  return sentence;
}
