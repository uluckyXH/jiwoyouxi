export const FC_ASSETS: string = 'gamesNext/warmFreecell/';
export const FC_LOGO: string = `${FC_ASSETS}scene/logo.svg`;
export const FC_HINT: string = '点选后再点目标 · 长按可拖动纸牌';
export interface FCLocation { pile: number; index: number; }
export interface FCMove { card: number; target: number; }
export interface FCFrame { piles: number[][]; moves: number; }
export interface FCArchive {
  version: number; seed: number; session: string; elapsed: number; moves: number;
  piles: number[][]; history: FCFrame[]; reported: boolean;
}
export function fcSuit(card: number): number { return Math.floor(card / 13); }
export function fcRank(card: number): number { return card % 13 + 1; }
export function fcRed(card: number): boolean { return fcSuit(card) === 1 || fcSuit(card) === 2; }
export function fcRankText(card: number): string {
  const rank = fcRank(card);
  return rank === 1 ? 'A' : rank === 11 ? 'J' : rank === 12 ? 'Q' : rank === 13 ? 'K' : `${rank}`;
}
export function fcName(card: number): string {
  return `${['黑桃', '红桃', '方块', '梅花'][fcSuit(card)]}${fcRankText(card)}`;
}
export function fcClone(piles: number[][]): number[][] { return piles.map((pile: number[]) => pile.slice()); }
export function fcLocate(piles: number[][], card: number): FCLocation {
  for (let pile = 0; pile < piles.length; pile++) {
    const index = piles[pile].indexOf(card);
    if (index >= 0) return { pile: pile, index: index };
  }
  return { pile: -1, index: -1 };
}
export function fcOrdered(cards: number[]): boolean {
  for (let i = 1; i < cards.length; i++) {
    if (fcRank(cards[i - 1]) !== fcRank(cards[i]) + 1 || fcRed(cards[i - 1]) === fcRed(cards[i])) return false;
  }
  return cards.length > 0;
}
export function fcCapacity(piles: number[][], target: number): number {
  let free = 0;
  let columns = 0;
  for (let i = 8; i < 12; i++) if (piles[i].length === 0) free++;
  for (let i = 0; i < 8; i++) if (i !== target && piles[i].length === 0) columns++;
  return (free + 1) * Math.pow(2, columns);
}
export function fcCanMove(piles: number[][], card: number, target: number): boolean {
  if (!Number.isInteger(target) || target < 0 || target >= 16) return false;
  const source = fcLocate(piles, card);
  if (source.pile < 0 || source.pile >= 12 || source.pile === target) return false;
  const cards = piles[source.pile].slice(source.index);
  if (!fcOrdered(cards)) return false;
  const dest = piles[target];
  if (target >= 12) return cards.length === 1 && target === 12 + fcSuit(card) && fcRank(card) === dest.length + 1;
  if (target >= 8) return cards.length === 1 && dest.length === 0;
  if (cards.length > fcCapacity(piles, target)) return false;
  return dest.length === 0 || (fcRank(dest[dest.length - 1]) === fcRank(card) + 1 &&
    fcRed(dest[dest.length - 1]) !== fcRed(card));
}
export function fcSafe(piles: number[][], card: number): boolean {
  if (!fcCanMove(piles, card, 12 + fcSuit(card))) return false;
  for (let suit = 0; suit < 4; suit++) {
    if (fcRed(suit * 13) !== fcRed(card) && piles[12 + suit].length < fcRank(card) - 1) return false;
  }
  return true;
}
export function fcValidPiles(piles: number[][]): boolean {
  if (!Array.isArray(piles) || piles.length !== 16) return false;
  const seen: Set<number> = new Set<number>();
  for (let p = 0; p < 16; p++) {
    if (!Array.isArray(piles[p]) || (p >= 8 && p < 12 && piles[p].length > 1)) return false;
    for (let i = 0; i < piles[p].length; i++) {
      const card = piles[p][i];
      if (!Number.isInteger(card) || card < 0 || card > 51 || seen.has(card)) return false;
      if (p >= 12 && (fcSuit(card) !== p - 12 || fcRank(card) !== i + 1)) return false;
      seen.add(card);
    }
  }
  return seen.size === 52;
}
