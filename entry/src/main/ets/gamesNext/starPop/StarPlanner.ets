import { STAR_COUNT, StarPlan, starBonus, starGain } from './StarModel';
import { starCollapse, starGroup, starGroups, starRemaining } from './StarRules';

/** Two bounded walks shared by generation and hints; callers yield between advances. */
export class StarPlanner {
  private original: number[];
  private cells: number[] = [];
  private ids: number[] = [];
  private path: number[] = [];
  private score: number = 0;
  private policy: number = 0;
  private best: StarPlan = { path: [], score: -1 };
  steps: number = 0;
  done: boolean = false;

  constructor(cells: number[]) {
    this.original = cells.slice();
    this.resetWalk();
  }

  private resetWalk(): void {
    this.cells = this.original.slice();
    this.ids = this.cells.map((color: number, cell: number): number => color < 0 ? -1 : cell);
    this.path = [];
    this.score = 0;
  }

  advance(): void {
    if (this.done) {
      return;
    }
    this.steps++;
    const groups = starGroups(this.cells);
    if (groups.length === 0) {
      const score = this.score + starBonus(starRemaining(this.cells));
      if (score > this.best.score) {
        this.best = { path: this.path.slice(), score: score };
      }
      this.policy++;
      if (this.policy >= 2) {
        this.done = true;
      } else {
        this.resetWalk();
      }
      return;
    }
    groups.sort((a: number[], b: number[]): number => b.length - a.length);
    let selected = groups[0];
    let bestRank = Number.NEGATIVE_INFINITY;
    // Match the generator's original policies; never branch into an unbounded search.
    for (let i = 0; i < Math.min(this.policy === 0 ? 1 : 3, groups.length); i++) {
      const group = groups[i];
      let rank = starGain(group.length);
      if (this.policy === 1) {
        const after = starCollapse(this.cells, this.ids, group);
        const next = starGroups(after.cells);
        let biggest = 0;
        let joined = 0;
        for (let j = 0; j < next.length; j++) {
          biggest = Math.max(biggest, next[j].length);
          joined += next[j].length;
        }
        rank += .6 * starGain(biggest) - 15 * (starRemaining(after.cells) - joined);
      }
      if (rank > bestRank) {
        bestRank = rank;
        selected = group;
      }
    }
    this.path.push(selected[0]);
    const move = starCollapse(this.cells, this.ids, selected);
    this.cells = move.cells;
    this.ids = move.ids;
    this.score += move.gain;
  }

  result(): StarPlan | undefined {
    return this.done ? starCopyPlan(this.best) : undefined;
  }
}

export function starCopyPlan(plan: StarPlan | undefined): StarPlan | undefined {
  return plan === undefined ? undefined : { path: plan.path.slice(), score: plan.score };
}

/** Replay only the recorded moves. A legal first group alone is not a score proof. */
export function starValidPlan(original: number[], plan: StarPlan | undefined): boolean {
  if (plan === undefined || plan === null || !Array.isArray(plan.path) || plan.path.length > 40 ||
    !Number.isSafeInteger(plan.score) || plan.score < 0) {
    return false;
  }
  let cells = original.slice();
  let ids: number[] = [];
  for (let i = 0; i < STAR_COUNT; i++) {
    ids.push(cells[i] < 0 ? -1 : i);
  }
  let score = 0;
  for (let i = 0; i < plan.path.length; i++) {
    const group = starGroup(cells, plan.path[i]);
    if (group.length < 2) {
      return false;
    }
    const move = starCollapse(cells, ids, group);
    cells = move.cells;
    ids = move.ids;
    score += move.gain;
  }
  return starGroups(cells).length === 0 && score + starBonus(starRemaining(cells)) === plan.score;
}
