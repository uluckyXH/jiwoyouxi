import { FCArchive, FCFrame, FCMove, fcCanMove, fcClone, fcLocate, fcOrdered, fcRank, fcSafe, fcSuit, fcValidPiles } from './FreecellModel';

/** Logical commits are independent of native animation, window geometry and audio. */
export class FreecellSession {
  piles: number[][] = [];
  history: FCFrame[] = [];
  seed: number = 1;
  session: string = '';
  moves: number = 0;
  elapsed: number = 0;
  reported: boolean = false;
  constructor() { this.newGame(); }
  newGame(seed: number = Math.floor(Math.random() * 1000000) + 1): void {
    this.seed = Math.min(1000000, Math.max(1, Math.floor(Number.isFinite(seed) ? seed : 1)));
    this.session = `freecell-room-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    this.piles = [];
    for (let p = 0; p < 16; p++) this.piles.push([]);
    this.moves = 0; this.elapsed = 0; this.reported = false; this.history = [];
    let value = this.seed;
    const random = (): number => { value = value * 16807 % 2147483647; return (value - 1) / 2147483646; };
    const ranks: number[] = [13, 13, 13, 13];
    const caps: number[] = [7, 7, 7, 7, 6, 6, 6, 6];
    for (let i = 7; i > 0; i--) { const j = Math.floor(random() * (i + 1)); const cap = caps[i]; caps[i] = caps[j]; caps[j] = cap; }
    for (let count = 0; count < 52; count++) {
      const suits = [0, 1, 2, 3].filter((s: number) => ranks[s] > 0);
      const suit = suits[Math.floor(random() * suits.length)];
      const columns = [0, 1, 2, 3, 4, 5, 6, 7].filter((p: number) => this.piles[p].length < caps[p]);
      const target = columns[Math.floor(random() * columns.length)];
      this.piles[target].push(suit * 13 + ranks[suit] - 1); ranks[suit]--;
    }
  }
  collected(): number { return this.piles.slice(12).reduce((n: number, p: number[]) => n + p.length, 0); }
  won(): boolean { return this.collected() === 52; }
  key(): string { return this.piles.map((p: number[]) => p.join('.')).join('|'); }
  selected(card: number): number[] {
    const where = fcLocate(this.piles, card);
    if (where.pile < 0 || where.pile >= 12) return [];
    const cards = this.piles[where.pile].slice(where.index);
    return fcOrdered(cards) ? cards : [];
  }
  move(card: number, target: number): boolean {
    if (!fcCanMove(this.piles, card, target)) return false;
    this.history.push({ piles: fcClone(this.piles), moves: this.moves });
    if (this.history.length > 200) this.history.shift();
    const loc = fcLocate(this.piles, card);
    const next = fcClone(this.piles);
    next[target].push(...next[loc.pile].splice(loc.index));
    this.piles = next; this.moves++;
    return true;
  }
  undo(): boolean {
    const previous = this.history.pop();
    if (previous === undefined) return false;
    this.piles = fcClone(previous.piles); this.moves = previous.moves;
    // Completion is a durable fact about this session, even after undo/replay.
    return true;
  }
  suggestions(): FCMove[] {
    const safe: FCMove[] = []; const normal: FCMove[] = []; const last: FCMove[] = [];
    for (let p = 0; p < 12; p++) {
      for (let i = 0; i < this.piles[p].length; i++) {
        const card = this.piles[p][i];
        for (let t = 0; t < 16; t++) {
          if (!fcCanMove(this.piles, card, t)) continue;
          const move: FCMove = { card: card, target: t };
          if (t >= 12 && fcSafe(this.piles, card)) safe.push(move);
          else if (t < 8 && this.piles[t].length > 0) normal.push(move);
          else last.push(move);
        }
      }
    }
    return safe.concat(normal, last);
  }
  automatic(visited: string[]): FCMove | undefined {
    const suggestions = this.suggestions();
    for (let i = 0; i < suggestions.length; i++) {
      const move = suggestions[i]; const from = fcLocate(this.piles, move.card);
      if (move.target >= 12 && !fcSafe(this.piles, move.card)) continue;
      if (move.target >= 8 && move.target < 12) continue;
      if (move.target < 8 && this.piles[move.target].length === 0 && from.index === 0) continue;
      const next = fcClone(this.piles);
      next[move.target].push(...next[from.pile].splice(from.index));
      if (!visited.includes(next.map((p: number[]) => p.join('.')).join('|'))) return move;
    }
    return undefined;
  }
  serialize(): string {
    const data: FCArchive = { version: 1, seed: this.seed, session: this.session, elapsed: this.elapsed,
      moves: this.moves, piles: this.piles, history: this.history, reported: this.reported };
    return JSON.stringify(data);
  }
  restore(raw: string): boolean {
    if (raw.length > 2000000) return false;
    try {
      const d = JSON.parse(raw) as FCArchive;
      if (d === null || d.version !== 1 || !Number.isInteger(d.seed) || d.seed < 1 || d.seed > 1000000 ||
        typeof d.session !== 'string' || d.session.length < 8 || d.session.length > 150 ||
        !Number.isSafeInteger(d.moves) || d.moves < 0 || !Number.isSafeInteger(d.elapsed) || d.elapsed < 0 ||
        typeof d.reported !== 'boolean' || !fcValidPiles(d.piles) || !Array.isArray(d.history) || d.history.length > 200) return false;
      for (let i = 0; i < d.history.length; i++) {
        const frame = d.history[i];
        if (frame === null || !fcValidPiles(frame.piles) || frame.moves !== d.moves - d.history.length + i || frame.moves < 0) return false;
      }
      this.seed = d.seed; this.session = d.session; this.elapsed = d.elapsed; this.moves = d.moves;
      this.piles = fcClone(d.piles); this.history = d.history; this.reported = d.reported;
      return true;
    } catch (_) { return false; }
  }
}
