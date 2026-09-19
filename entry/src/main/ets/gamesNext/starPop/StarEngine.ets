import { AchievementEvent, AchievementFact } from '../../shell/AchievementModule';
import { STAR_COUNT, STAR_ID, StarFall, StarMode, StarPlan, StarProfile, StarPuzzle, StarRound,
  starBonus, starColors, starTarget } from './StarModel';
import { starCollapse, starGroup, starGroups, starRemaining, starValidBoard } from './StarRules';
import { starFallback } from './StarFallback';
import { starVerifyPuzzle } from './StarGenerator';
import { starCopyPlan, starValidPlan } from './StarPlanner';

export interface StarSave { version: number; round: StarRound; profile: StarProfile; pending: AchievementEvent[]; }
function count(value: number): boolean { return Number.isSafeInteger(value) && value >= 0; }
function copyRound(round: StarRound): StarRound { return JSON.parse(JSON.stringify(round)) as StarRound; }

export class StarEngine {
  round: StarRound;
  profile: StarProfile = { totalCleared: 0, maxGroup: 0, bestEasy: 0, bestClassic: 0, stageEasy: 0, stageClassic: 0 };
  pending: AchievementEvent[] = [];

  constructor() { this.round = this.freshRound('easy', starFallback('easy')); }

  private freshRound(mode: StarMode, puzzle: StarPuzzle): StarRound {
    const ids: number[] = []; for (let i = 0; i < STAR_COUNT; i++) ids.push(i);
    return { session: `star-${Date.now()}-${Math.floor(Math.random() * 1e9)}`, seed: puzzle.seed, mode: mode,
      stage: 1, target: starTarget(1, puzzle.witness), witness: puzzle.witness, cells: puzzle.cells.slice(), ids: ids,
      score: 0, total: 0, moves: 0, stageMoves: 0, highWater: 0, undoUsed: false, undo: undefined,
      status: 'playing', bonus: 0, bestGroup: 0,
      hintPlan: { path: puzzle.path.slice(), score: puzzle.witness } };
  }

  start(mode: StarMode, puzzle: StarPuzzle): boolean {
    if (!starVerifyPuzzle(puzzle, mode) || this.pending.some((e: AchievementEvent): boolean => e.type === 'sessionEnd')) return false;
    this.round = this.freshRound(mode, puzzle); return true;
  }

  pop(cell: number): StarFall | undefined {
    const r = this.round;
    if (r.status !== 'playing') return undefined;
    const group = starGroup(r.cells, cell);
    if (group.length < 2) return undefined;
    r.undo = { cells: r.cells.slice(), ids: r.ids.slice(), score: r.score, moves: r.moves, stageMoves: r.stageMoves,
      hintPlan: starCopyPlan(r.hintPlan) };
    const move = starCollapse(r.cells, r.ids, group);
    // Every tile in the recommended group is the same move, regardless of the tapped cell.
    const plan = r.hintPlan;
    r.hintPlan = plan !== undefined && group.includes(plan.path[0]) ?
      { path: plan.path.slice(1), score: plan.score - move.gain } : undefined;
    r.cells = move.cells; r.ids = move.ids; r.score += move.gain; r.moves++; r.stageMoves++;
    r.bestGroup = Math.max(r.bestGroup, group.length);
    const cleared = STAR_COUNT - starRemaining(r.cells);
    this.profile.totalCleared += Math.max(0, cleared - r.highWater);
    r.highWater = Math.max(r.highWater, cleared);
    this.profile.maxGroup = Math.max(this.profile.maxGroup, group.length);
    this.queueMilestone();
    if (starGroups(r.cells).length === 0) {
      r.bonus = starBonus(starRemaining(r.cells));
      r.status = r.score + r.bonus >= r.target ? 'stageEnd' : 'failed';
    }
    this.updateBest();
    return move;
  }

  canUndo(): boolean { return this.round.undo !== undefined && !this.round.undoUsed && this.round.status !== 'finished'; }
  undo(): boolean {
    const r = this.round, previous = r.undo;
    if (!this.canUndo() || previous === undefined) return false;
    r.cells = previous.cells.slice(); r.ids = previous.ids.slice(); r.score = previous.score;
    r.moves = previous.moves; r.stageMoves = previous.stageMoves; r.undoUsed = true; r.undo = undefined;
    r.hintPlan = starCopyPlan(previous.hintPlan);
    r.status = 'playing'; r.bonus = 0;
    return true;
  }

  canAdvance(): boolean { return this.round.status === 'stageEnd' || (this.round.status === 'playing' && this.round.score >= this.round.target); }
  advance(puzzle: StarPuzzle): boolean {
    const r = this.round;
    if (!this.canAdvance() || !starVerifyPuzzle(puzzle, r.mode)) return false;
    r.total += r.score + starBonus(starRemaining(r.cells)); r.stage++;
    r.seed = puzzle.seed; r.witness = puzzle.witness; r.target = starTarget(r.stage, puzzle.witness);
    r.hintPlan = { path: puzzle.path.slice(), score: puzzle.witness };
    r.cells = puzzle.cells.slice(); r.ids = []; for (let i = 0; i < STAR_COUNT; i++) r.ids.push(i);
    r.score = 0; r.stageMoves = 0; r.highWater = 0; r.undoUsed = false; r.undo = undefined;
    r.bonus = 0; r.status = 'playing'; this.updateBest(); return true;
  }

  finish(): boolean {
    const r = this.round;
    if (r.status !== 'failed') return false;
    r.status = 'finished'; this.updateBest();
    this.pending.push({ eventId: `star:${r.session}:end`, sessionId: r.session, gameId: STAR_ID,
      type: 'sessionEnd', occurredAt: Date.now(), isOfficial: true,
      facts: [{ key: 'totalCleared', value: this.profile.totalCleared }, { key: 'maxGroup', value: this.profile.maxGroup },
        { key: 'score', value: this.totalScore() }] });
    return true;
  }

  hint(): number[] {
    if (this.round.status !== 'playing') return [];
    const plan = this.round.hintPlan;
    if (plan !== undefined && plan.path.length > 0) return starGroup(this.round.cells, plan.path[0]);
    const groups = starGroups(this.round.cells);
    if (groups.length === 0) return [];
    let best = groups[0];
    for (let i = 1; i < groups.length; i++) if (groups[i].length > best.length) best = groups[i];
    return best;
  }

  hintIsWinning(): boolean {
    const r = this.round;
    return r.status === 'playing' && r.hintPlan !== undefined && r.hintPlan.path.length > 0 &&
      r.score + r.hintPlan.score >= r.target;
  }

  applyHintPlan(plan: StarPlan): boolean {
    if (this.round.status !== 'playing' || !starValidPlan(this.round.cells, plan)) return false;
    this.round.hintPlan = starCopyPlan(plan);
    return true;
  }

  totalScore(): number { return this.round.total + this.round.score + this.round.bonus; }
  bestScore(): number { return this.round.mode === 'easy' ? this.profile.bestEasy : this.profile.bestClassic; }
  bestStage(): number { return this.round.mode === 'easy' ? this.profile.stageEasy : this.profile.stageClassic; }

  private updateBest(): void {
    if (this.round.mode === 'easy') {
      this.profile.bestEasy = Math.max(this.profile.bestEasy, this.totalScore());
      this.profile.stageEasy = Math.max(this.profile.stageEasy, this.round.stage);
    } else {
      this.profile.bestClassic = Math.max(this.profile.bestClassic, this.totalScore());
      this.profile.stageClassic = Math.max(this.profile.stageClassic, this.round.stage);
    }
  }

  private queueMilestone(): void {
    const facts: AchievementFact[] = [{ key: 'totalCleared', value: this.profile.totalCleared }, { key: 'maxGroup', value: this.profile.maxGroup }];
    // The newest monotonic facts subsume earlier unacknowledged milestones.
    this.pending = this.pending.filter((e: AchievementEvent): boolean => e.type !== 'milestone');
    this.pending.push({ eventId: `star:progress:${this.profile.totalCleared}:${this.profile.maxGroup}`, sessionId: this.round.session,
      gameId: STAR_ID, type: 'milestone', occurredAt: Date.now(), isOfficial: true, facts: facts });
  }

  snapshot(): StarSave {
    return JSON.parse(JSON.stringify({ version: 1, round: this.round, profile: this.profile, pending: this.pending })) as StarSave;
  }
  serialize(): string { return JSON.stringify(this.snapshot()); }

  restore(raw: string): boolean {
    try {
      const saved = JSON.parse(raw) as StarSave;
      if (saved === null || saved.version !== 1 || saved.round === undefined || saved.round === null ||
        saved.profile === undefined || saved.profile === null || !Array.isArray(saved.pending) || saved.pending.length > 8) return false;
      const r = saved.round, p = saved.profile;
      if ((r.mode !== 'easy' && r.mode !== 'classic') || typeof r.session !== 'string' || r.session.length < 5 ||
        !count(r.seed) || r.seed > 4294967295 || !count(r.stage) || r.stage < 1 || !count(r.witness) || r.witness < 100 ||
        r.target !== starTarget(r.stage, r.witness) || r.target > r.witness || !count(r.score) || !count(r.total) || !count(r.moves) ||
        !count(r.stageMoves) || r.stageMoves > r.moves || r.stageMoves > 40 || !count(r.highWater) || r.highWater > STAR_COUNT ||
        r.highWater < STAR_COUNT - starRemaining(r.cells ?? []) || typeof r.undoUsed !== 'boolean' || !count(r.bestGroup) ||
        r.bestGroup > STAR_COUNT || !count(r.bonus) || !['playing', 'stageEnd', 'failed', 'finished'].includes(r.status) ||
        !starValidBoard(r.cells, r.ids, starColors(r.mode))) return false;
      if (![p.totalCleared, p.maxGroup, p.bestEasy, p.bestClassic, p.stageEasy, p.stageClassic].every((n: number): boolean => count(n)) ||
        p.maxGroup > STAR_COUNT || p.totalCleared < r.highWater || p.maxGroup < r.bestGroup) return false;
      const hasMoves = starGroups(r.cells).length > 0;
      if (r.status === 'playing' ? (!hasMoves || r.bonus !== 0) : (hasMoves || r.bonus !== starBonus(starRemaining(r.cells)))) return false;
      if (r.status === 'stageEnd' && r.score + r.bonus < r.target) return false;
      if ((r.status === 'failed' || r.status === 'finished') && r.score + r.bonus >= r.target) return false;
      if (r.undo !== undefined) {
        const u = r.undo;
        if (u === null || !starValidBoard(u.cells, u.ids, starColors(r.mode)) || !count(u.score) || u.score >= r.score ||
          !count(u.moves) || u.moves + 1 !== r.moves || !count(u.stageMoves) || u.stageMoves + 1 !== r.stageMoves) return false;
      }
      const eventIds: string[] = [];
      for (let i = 0; i < saved.pending.length; i++) {
        const e = saved.pending[i];
        if (e === null || e.gameId !== STAR_ID || (e.type !== 'milestone' && e.type !== 'sessionEnd') || e.isOfficial !== true ||
          typeof e.eventId !== 'string' || !e.eventId.startsWith('star:') || eventIds.includes(e.eventId) ||
          typeof e.sessionId !== 'string' || e.sessionId.length === 0 || !count(e.occurredAt) || e.occurredAt === 0 || !Array.isArray(e.facts) ||
          e.facts.some((f: AchievementFact): boolean => f === null || !['totalCleared', 'maxGroup', 'score'].includes(f.key) || !count(f.value))) return false;
        eventIds.push(e.eventId);
      }
      this.round = copyRound(r); this.profile = JSON.parse(JSON.stringify(p)) as StarProfile;
      // v1 saves may predate route hints. A missing/damaged optional route must not discard the board.
      if (!starValidPlan(this.round.cells, this.round.hintPlan)) this.round.hintPlan = undefined;
      const undo = this.round.undo;
      if (undo !== undefined && !starValidPlan(undo.cells, undo.hintPlan)) undo.hintPlan = undefined;
      this.pending = JSON.parse(JSON.stringify(saved.pending)) as AchievementEvent[];
      return true;
    } catch (_) { return false; }
  }
}
