import { STAR_COUNT, StarMode, StarPuzzle, starColors } from './StarModel';
import { StarPlanner, starValidPlan } from './StarPlanner';

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
  private seed: number;
  private planner: StarPlanner;

  get steps(): number { return this.planner.steps; }
  get done(): boolean { return this.planner.done; }

  constructor(seed: number, mode: StarMode) {
    const rng = new StarRandom(seed);
    for (let i = 0; i < STAR_COUNT; i++) this.original.push(i % starColors(mode));
    for (let i = STAR_COUNT - 1; i > 0; i--) {
      const j = Math.floor(rng.next() * (i + 1));
      const value = this.original[i]; this.original[i] = this.original[j]; this.original[j] = value;
    }
    this.seed = seed >>> 0;
    this.planner = new StarPlanner(this.original);
  }

  advance(): void { this.planner.advance(); }

  result(): StarPuzzle | undefined {
    const plan = this.planner.result();
    return plan !== undefined && plan.score >= 100 ?
      { seed: this.seed, cells: this.original.slice(), witness: plan.score, path: plan.path } : undefined;
  }
}

export function starVerifyPuzzle(puzzle: StarPuzzle, mode: StarMode): boolean {
  if (!Number.isInteger(puzzle.seed) || puzzle.seed < 0 || puzzle.seed > 4294967295 ||
    !Array.isArray(puzzle.cells) || puzzle.cells.length !== STAR_COUNT || !Array.isArray(puzzle.path) ||
    puzzle.path.length > 40 || puzzle.path.length === 0 || !Number.isInteger(puzzle.witness) || puzzle.witness < 100) return false;
  const colors = starColors(mode);
  if (puzzle.cells.some((c: number): boolean => !Number.isInteger(c) || c < 0 || c >= colors)) return false;
  return starValidPlan(puzzle.cells, { path: puzzle.path, score: puzzle.witness });
}
