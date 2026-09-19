import { MemoryMode, MemoryRound, MemorySave, MEMORY_PICTURES, memoryPairCount, memoryMatched } from './MemoryModel';

export class MemoryRandom {
  seed: number;
  constructor(seed: number) { this.seed = (seed >>> 0) || 1; }
  pick(max: number): number {
    this.seed ^= this.seed << 13;
    this.seed ^= this.seed >>> 17;
    this.seed ^= this.seed << 5;
    this.seed >>>= 0;
    return Math.floor(this.seed / 4294967296 * max);
  }
  shuffle(values: number[]): void {
    for (let i = values.length - 1; i > 0; i -= 1) {
      const other = this.pick(i + 1);
      const value = values[i];
      values[i] = values[other];
      values[other] = value;
    }
  }
}
let memorySerial: number = 0;
export function memoryDeal(mode: MemoryMode, number: number, seed: number): MemoryRound {
  const random = new MemoryRandom(seed);
  const pictures: number[] = MEMORY_PICTURES.map((_name: string, i: number): number => i);
  random.shuffle(pictures);
  const pairs = memoryPairCount(mode, number);
  const selected = pictures.slice(0, pairs);
  const cards = selected.concat(selected);
  random.shuffle(cards);
  memorySerial += 1;
  return { id: 'memory-' + Date.now() + '-' + random.seed + '-' + memorySerial,
    mode: mode, number: number, pairs: pairs, seed: random.seed, cards: cards,
    matched: cards.map((): boolean => false), first: -1, second: -1, phase: 'ready',
    attempts: 0, streak: 0, topStreak: 0, reported: false };
}
export function memoryInteger(value: number, min: number, max: number = Number.MAX_SAFE_INTEGER): boolean {
  return Number.isSafeInteger(value) && value >= min && value <= max;
}
/** Validate a complete snapshot before replacing any live state. */
export function memorySaveValid(saved: MemorySave): boolean {
  if (saved === null || saved.version !== 1 || !saved.round || !saved.profile) { return false; }
  const r = saved.round;
  const p = saved.profile;
  if (!['journey', 'easy', 'normal', 'focus'].includes(r.mode) ||
    !memoryInteger(r.number, 1) || r.pairs !== memoryPairCount(r.mode, r.number) ||
    typeof r.id !== 'string' || r.id.length < 1 || r.id.length > 180 ||
    !memoryInteger(r.seed, 1, 4294967295) || typeof r.reported !== 'boolean') { return false; }
  if (!Array.isArray(r.cards) || !Array.isArray(r.matched) ||
    r.cards.length !== r.pairs * 2 || r.matched.length !== r.cards.length ||
    !r.cards.every((id: number) => memoryInteger(id, 0, MEMORY_PICTURES.length - 1)) ||
    !r.matched.every((value: boolean) => typeof value === 'boolean')) { return false; }
  for (let id = 0; id < MEMORY_PICTURES.length; id += 1) {
    const slots = r.cards.map((value: number, i: number): number => value === id ? i : -1)
      .filter((index: number) => index >= 0);
    if (slots.length !== 0 && (slots.length !== 2 || r.matched[slots[0]] !== r.matched[slots[1]])) { return false; }
  }
  const found = memoryMatched(r);
  if (!memoryInteger(r.attempts, found) || !memoryInteger(r.streak, 0, found) ||
    !memoryInteger(r.topStreak, r.streak, found) ||
    !memoryInteger(r.first, -1, r.cards.length - 1) || !memoryInteger(r.second, -1, r.cards.length - 1)) { return false; }
  if (r.phase === 'ready') {
    if (r.second !== -1 || (r.first >= 0 && r.matched[r.first]) || found === r.pairs) { return false; }
  } else if (r.phase === 'mismatch' || r.phase === 'match' || r.phase === 'complete') {
    if (r.first < 0 || r.second < 0 || r.first === r.second) { return false; }
    const equal = r.cards[r.first] === r.cards[r.second];
    if (r.phase === 'mismatch') {
      if (equal || r.matched[r.first] || r.matched[r.second] || r.streak !== 0 ||
        r.attempts <= found) { return false; }
    } else if (!equal || !r.matched[r.first] || !r.matched[r.second] || r.streak === 0) { return false; }
    if ((r.phase === 'complete') !== (found === r.pairs)) { return false; }
  } else { return false; }
  if (r.reported && r.phase !== 'complete') { return false; }
  if (!memoryInteger(p.totalPairs, found) || !memoryInteger(p.totalTables, r.phase === 'complete' ? 1 : 0) ||
    !memoryInteger(p.bestStreak, r.topStreak, 12) || p.totalPairs < p.totalTables * 6) { return false; }
  const records: number[] = [p.best6, p.best8, p.best10, p.best12];
  const sizes: number[] = [6, 8, 10, 12];
  for (let i = 0; i < records.length; i += 1) {
    if (!memoryInteger(records[i], 0) || (records[i] > 0 && (records[i] < sizes[i] || p.totalTables === 0))) { return false; }
  }
  if (r.phase === 'complete') {
    const best = records[sizes.indexOf(r.pairs)];
    if (best === 0 || best > r.attempts) { return false; }
  }
  return true;
}
