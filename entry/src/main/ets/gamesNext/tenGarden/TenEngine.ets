import { TenHint, TenPath, TenProfile, TenPuzzle, TenRound, TenSave, TenTileView, tenInteger, tenProfile } from './TenModel';
import { tenEqual, tenHasMove, tenPuzzle, tenSaveValid, tenShift, tenStart, tenValidPath } from './TenRules';

export class TenEngine {
  round: TenRound = tenStart();
  puzzle: TenPuzzle = tenPuzzle(1);
  private resumeRound: TenRound | undefined = undefined;
  constructor(stage: number = 1) { this.round = tenStart(stage); this.puzzle = tenPuzzle(stage); }
  direction(): number { return (this.puzzle.direction + this.round.history.length) % 4; }
  hasMove(): boolean { return this.round.phase === 'playing' && tenHasMove(this.round.board, this.puzzle.size); }
  resumeStage(): number { return this.resumeRound === undefined ? 0 : this.resumeRound.stage; }
  profile(): TenProfile { return tenProfile(this.resumeRound === undefined ? this.round : this.resumeRound); }
  submit(path: number[]): boolean {
    if (this.round.phase !== 'playing' || !tenValidPath(this.round.board, path, this.puzzle.size)) return false;
    const direction = this.direction();
    this.round.board = tenShift(this.round.board, path, this.puzzle.size, direction);
    this.round.ids = tenShift(this.round.ids, path, this.puzzle.size, direction);
    this.round.history.push({ cells: path.slice() });
    this.round.credited = Math.max(this.round.credited, this.round.history.length);
    if (this.round.board.every((v: number): boolean => v === 0)) this.round.phase = 'complete';
    return true;
  }
  rewind(steps: number = 1): boolean {
    if (this.round.phase !== 'playing' || !tenInteger(steps, 1, this.round.history.length)) return false;
    this.round.history.splice(this.round.history.length - steps);
    this.rebuild();
    this.round.undos += steps;
    return true;
  }
  restart(): boolean {
    if (this.round.phase !== 'playing') return false;
    this.round.history = [];
    this.rebuild();
    return true;
  }
  next(): boolean {
    if (this.resumeRound !== undefined) {
      if (this.round.phase !== 'complete') return false;
      const stage = this.round.stage + 1;
      if (stage >= this.resumeRound.stage) return this.resume();
      this.round = tenStart(stage); this.puzzle = tenPuzzle(stage);
      return true;
    }
    if (this.round.phase !== 'complete' || !this.round.reported || this.round.stage >= 1000000) return false;
    const stage = this.round.stage + 1;
    this.round = tenStart(stage);
    this.puzzle = tenPuzzle(stage);
    return true;
  }
  previous(): boolean {
    if (this.round.stage <= 1) return false;
    if (this.resumeRound === undefined) this.resumeRound = JSON.parse(JSON.stringify(this.round)) as TenRound;
    const stage = this.round.stage - 1;
    this.round = tenStart(stage); this.puzzle = tenPuzzle(stage);
    return true;
  }
  resume(): boolean {
    if (this.resumeRound === undefined) return false;
    this.round = this.resumeRound; this.resumeRound = undefined;
    this.puzzle = tenPuzzle(this.round.stage);
    return true;
  }
  private rebuild(): void {
    this.round.board = this.puzzle.values.slice();
    this.round.ids = this.puzzle.values.map((v: number, i: number): number => v > 0 ? i + 1 : 0);
    this.round.history.forEach((path: TenPath, step: number) => {
      this.round.board = tenShift(this.round.board, path.cells, this.puzzle.size, (this.puzzle.direction + step) % 4);
      this.round.ids = tenShift(this.round.ids, path.cells, this.puzzle.size, (this.puzzle.direction + step) % 4);
    });
  }
  hint(): TenHint | undefined {
    if (this.round.phase !== 'playing') return undefined;
    const states: number[][] = [this.puzzle.values.slice()];
    this.round.history.forEach((path: TenPath, step: number) => {
      states.push(tenShift(states[states.length - 1], path.cells, this.puzzle.size, (this.puzzle.direction + step) % 4));
    });
    let verified = this.puzzle.values.slice();
    let result: TenHint = { rewind: this.round.history.length, path: this.puzzle.solution[0].cells.slice() };
    for (let step = 0; step < this.puzzle.solution.length && step < states.length; step += 1) {
      if (tenEqual(verified, states[step])) result = { rewind: this.round.history.length - step,
        path: this.puzzle.solution[step].cells.slice() };
      verified = tenShift(verified, this.puzzle.solution[step].cells, this.puzzle.size, (this.puzzle.direction + step) % 4);
    }
    const target = states[this.round.history.length - result.rewind];
    return tenValidPath(target, result.path, this.puzzle.size) ? result : undefined;
  }
  applyHint(hint: TenHint): boolean {
    const current = this.hint();
    if (current === undefined || current.rewind !== hint.rewind || !tenEqual(current.path, hint.path)) return false;
    if (hint.rewind > 0 && !this.rewind(hint.rewind)) return false;
    this.round.hints += 1;
    return true;
  }
  tiles(): TenTileView[] {
    const result: TenTileView[] = [];
    this.round.ids.forEach((id: number, index: number) => {
      if (id > 0) result.push({ id: id, value: this.round.board[index], index: index });
    });
    return result;
  }
  snapshot(): TenSave {
    return JSON.parse(JSON.stringify({ version: 1, round: this.round, profile: this.profile(), resumeRound: this.resumeRound })) as TenSave;
  }
  serialize(): string { return JSON.stringify(this.snapshot()); }
  restore(raw: string): boolean {
    try {
      const saved = JSON.parse(raw) as TenSave;
      if (!tenSaveValid(saved)) return false;
      this.round = saved.round;
      this.resumeRound = saved.resumeRound;
      this.puzzle = tenPuzzle(saved.round.stage);
      return true;
    } catch (_) { return false; }
  }
}
