import { STAR_COUNT, StarMode, StarPuzzle, starBonus, starColors, starGain } from './StarModel';
import { starCollapse, starGroups, starRemaining } from './StarRules';

export class StarRandom {
  value: number;
  constructor(seed: number) { this.value = (seed >>> 0) || 0x9E3779B9; }
  next(): number {
    let n = this.value; n ^= n << 13; n ^= n >>> 17; n ^= n << 5;
    this.value = n >>> 0; return this.value / 4294967296;
  }
}

/** Two bounded heuristic walks, advanced a step at a time off the input path. */
export class StarGenerator {
  private original: number[] = [];
  private cells: number[] = [];
  private ids: number[] = [];
  private path: number[] = [];
  private score: number = 0;
  private policy: number = 0;
  private best: StarPuzzle;
  steps: number = 0;
  done: boolean = false;

  constructor(seed: number, mode: StarMode) {
    const rng = new StarRandom(seed);
    for (let i = 0; i < STAR_COUNT; i++) this.original.push(i % starColors(mode));
    for (let i = STAR_COUNT - 1; i > 0; i--) {
      const j = Math.floor(rng.next() * (i + 1));
      const value = this.original[i]; this.original[i] = this.original[j]; this.original[j] = value;
    }
    this.best = { seed: seed >>> 0, cells: this.original.slice(), witness: 0, path: [] };
    this.resetWalk();
  }

  private resetWalk(): void {
    this.cells = this.original.slice(); this.ids = []; this.path = []; this.score = 0;
    for (let i = 0; i < STAR_COUNT; i++) this.ids.push(i);
  }

  advance(): void {
    if (this.done) return;
    this.steps++;
    const groups = starGroups(this.cells);
    if (groups.length === 0) {
      const score = this.score + starBonus(starRemaining(this.cells));
      if (score > this.best.witness) this.best = { seed: this.best.seed, cells: this.original.slice(), witness: score, path: this.path.slice() };
      this.policy++;
      if (this.policy >= 2) this.done = true;
      else this.resetWalk();
      return;
    }
    groups.sort((a: number[], b: number[]): number => b.length - a.length);
    let selected = groups[0], bestRank = Number.NEGATIVE_INFINITY;
    // Only inspect the three largest options; no unbounded tree search.
    for (let i = 0; i < Math.min(this.policy === 0 ? 1 : 3, groups.length); i++) {
      const group = groups[i];
      let rank = starGain(group.length);
      if (this.policy === 1) {
        const after = starCollapse(this.cells, this.ids, group);
        const next = starGroups(after.cells);
        let biggest = 0, joined = 0;
        for (let j = 0; j < next.length; j++) { biggest = Math.max(biggest, next[j].length); joined += next[j].length; }
        rank += .6 * starGain(biggest) - 15 * (starRemaining(after.cells) - joined);
      }
      if (rank > bestRank) { bestRank = rank; selected = group; }
    }
    this.path.push(selected[0]);
    const move = starCollapse(this.cells, this.ids, selected);
    this.cells = move.cells; this.ids = move.ids; this.score += move.gain;
  }

  result(): StarPuzzle | undefined { return this.done && this.best.witness >= 100 ? this.best : undefined; }
}

export function starVerifyPuzzle(puzzle: StarPuzzle, mode: StarMode): boolean {
  if (!Number.isInteger(puzzle.seed) || puzzle.seed < 0 || puzzle.seed > 4294967295 ||
    !Array.isArray(puzzle.cells) || puzzle.cells.length !== STAR_COUNT || !Array.isArray(puzzle.path) ||
    puzzle.path.length > 40 || puzzle.path.length === 0 || !Number.isInteger(puzzle.witness) || puzzle.witness < 100) return false;
  let cells = puzzle.cells.slice(); const colors = starColors(mode);
  if (cells.some((c: number): boolean => !Number.isInteger(c) || c < 0 || c >= colors)) return false;
  let ids: number[] = []; for (let i = 0; i < STAR_COUNT; i++) ids.push(i);
  let score = 0;
  for (let i = 0; i < puzzle.path.length; i++) {
    const group = starGroupForProof(cells, puzzle.path[i]);
    if (group.length < 2) return false;
    const move = starCollapse(cells, ids, group); cells = move.cells; ids = move.ids; score += move.gain;
  }
  return starGroups(cells).length === 0 && score + starBonus(starRemaining(cells)) === puzzle.witness;
}

function starGroupForProof(cells: number[], cell: number): number[] {
  const groups = starGroups(cells);
  for (let i = 0; i < groups.length; i++) if (groups[i].includes(cell)) return groups[i];
  return [];
}
