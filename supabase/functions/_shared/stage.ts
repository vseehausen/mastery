export function mapCardToStage(card: { state: number; stability: number } | null): string {
  if (!card) return 'new';
  if (card.state === 0) return 'new';
  if (card.state === 1 || card.state === 3) return 'practicing';
  if (card.state === 2) {
    if (card.stability < 7) return 'practicing';
    if (card.stability < 21) return 'stabilizing';
    if (card.stability < 60) return 'known';
    return 'mastered';
  }
  return 'new';
}
