import { MINE_LEVELS, MineLevel, MineSave, SurveyCell, mineLevel, mineNeighbors } from './MineModel';

/** Pure rules. Layout, theme and elapsed wall time never mutate the mine distribution. */
export class MineEngine {
  level: MineLevel = MINE_LEVELS[0];
  cells: SurveyCell[] = [];
  phase: string = 'ready';
  elapsedMs: number = 0;
  flagMode: boolean = false;
  session: string = '';
  everWrongFlag: boolean = false;
  manualAllFlags: boolean = false;
  reported: boolean = false;
  bestTimes: number[] = [0, 0, 0];
  private seed: number = 1;

  constructor() { this.reset('easy'); }

  reset(key: string, seed: number = Date.now() % 4294967296): void {
    this.level = mineLevel(key);
    this.seed = Math.floor(Math.abs(seed)) % 4294967296;
    this.session = `mine-next:${Date.now()}:${this.seed}:${Math.floor(Math.random() * 1000000)}`;
    this.phase = 'ready';
    this.elapsedMs = 0;
    this.flagMode = false;
    this.everWrongFlag = false;
    this.manualAllFlags = false;
    this.reported = false;
    this.cells = [];
    for (let index = 0; index < this.level.rows * this.level.cols; index += 1) {
      this.cells.push({ index: index, mine: false, open: false, flag: false, near: 0, exploded: false });
    }
  }

  finished(): boolean { return this.phase === 'won' || this.phase === 'lost'; }
  flags(): number { return this.cells.filter((cell: SurveyCell) => cell.flag).length; }
  opened(): number { return this.cells.filter((cell: SurveyCell) => cell.open && !cell.mine).length; }
  safeTotal(): number { return this.cells.length - this.level.mines; }
  score(): number { return this.phase === 'won' ? Math.max(100, 10000 - Math.floor(this.elapsedMs / 1000) * 10) : 0; }
  bestTime(): number { return this.bestTimes[MINE_LEVELS.findIndex((level: MineLevel) => level.key === this.level.key)]; }

  advance(milliseconds: number): void {
    if (this.phase === 'playing' && Number.isFinite(milliseconds) && milliseconds > 0) {
      this.elapsedMs = Math.min(359999000, this.elapsedMs + milliseconds);
    }
  }

  flag(index: number): string {
    if (!this.validIndex(index) || this.finished() || this.cells[index].open) return 'none';
    const cell = this.cells[index];
    if (!cell.flag && this.flags() >= this.level.mines) return 'limit';
    cell.flag = !cell.flag;
    if (cell.flag && this.phase === 'playing' && !cell.mine) this.everWrongFlag = true;
    return cell.flag ? 'flag' : 'unflag';
  }

  open(index: number): string {
    if (!this.validIndex(index) || this.finished() || this.cells[index].flag) return 'none';
    if (this.cells[index].open) return this.chord(index);
    if (this.phase === 'ready') this.place(index);
    return this.reveal([index]);
  }

  chord(index: number): string {
    if (!this.validIndex(index) || this.phase !== 'playing') return 'none';
    const cell = this.cells[index];
    if (!cell.open || cell.near === 0) return 'none';
    const neighbors = mineNeighbors(index, this.level.rows, this.level.cols);
    const flags = neighbors.filter((i: number) => this.cells[i].flag).length;
    if (flags !== cell.near) return 'mismatch';
    return this.reveal(neighbors.filter((i: number) => !this.cells[i].flag && !this.cells[i].open));
  }

  copyCells(): SurveyCell[] {
    return this.cells.map((cell: SurveyCell): SurveyCell => ({ index: cell.index, mine: cell.mine,
      open: cell.open, flag: cell.flag, near: cell.near, exploded: cell.exploded }));
  }

  serialize(): string {
    const save: MineSave = { version: 1, level: this.level.key, phase: this.phase, seed: this.seed,
      session: this.session, elapsedMs: this.elapsedMs, cells: this.copyCells(), flagMode: this.flagMode,
      everWrongFlag: this.everWrongFlag, manualAllFlags: this.manualAllFlags, reported: this.reported,
      bestTimes: this.bestTimes.slice() };
    return JSON.stringify(save);
  }

  restore(raw: string): boolean {
    try {
      if (raw.length === 0 || raw.length > 80000) return false;
      const save = JSON.parse(raw) as MineSave;
      if (save === null || save.version !== 1 || !MINE_LEVELS.some((level: MineLevel) => level.key === save.level) ||
        !['ready', 'playing', 'won', 'lost'].includes(save.phase) ||
        typeof save.session !== 'string' || save.session.length < 1 || save.session.length > 160 ||
        !Number.isInteger(save.seed) || save.seed < 0 || save.seed >= 4294967296 ||
        !Number.isFinite(save.elapsedMs) || save.elapsedMs < 0 || save.elapsedMs > 359999000 ||
        typeof save.flagMode !== 'boolean' || typeof save.everWrongFlag !== 'boolean' ||
        typeof save.manualAllFlags !== 'boolean' || typeof save.reported !== 'boolean' ||
        !Array.isArray(save.bestTimes) || save.bestTimes.length !== 3 ||
        save.bestTimes.some((time: number) => !Number.isFinite(time) || time < 0 || time > 359999000)) return false;
      const level = mineLevel(save.level);
      if (!Array.isArray(save.cells) || save.cells.length !== level.rows * level.cols) return false;
      let mines = 0;
      let flags = 0;
      let safeOpen = 0;
      let explosions = 0;
      for (let i = 0; i < save.cells.length; i += 1) {
        const cell = save.cells[i];
        if (cell === null || cell.index !== i || typeof cell.mine !== 'boolean' || typeof cell.open !== 'boolean' ||
          typeof cell.flag !== 'boolean' || typeof cell.exploded !== 'boolean' ||
          !Number.isInteger(cell.near) || cell.near < 0 || cell.near > 8 ||
          (cell.exploded && (!cell.mine || !cell.open)) || (cell.open && cell.flag && !cell.mine)) return false;
        if (cell.mine) mines += 1;
        if (cell.flag) flags += 1;
        if (cell.open && !cell.mine) safeOpen += 1;
        if (cell.exploded) explosions += 1;
      }
      if (flags > level.mines || (save.phase === 'ready' ? mines !== 0 || safeOpen !== 0 || save.elapsedMs !== 0 : mines !== level.mines)) return false;
      if ((save.phase === 'won' && safeOpen !== save.cells.length - level.mines) ||
        (save.phase === 'playing' && safeOpen >= save.cells.length - level.mines) ||
        (save.phase === 'lost' ? explosions !== 1 : explosions !== 0)) return false;
      for (let i = 0; i < save.cells.length; i += 1) {
        const near = mineNeighbors(i, level.rows, level.cols).filter((n: number) => save.cells[n].mine).length;
        if (save.cells[i].near !== near || (save.phase !== 'lost' && save.cells[i].mine && save.cells[i].open)) return false;
      }
      this.level = level;
      this.phase = save.phase;
      this.seed = save.seed;
      this.session = save.session;
      this.elapsedMs = save.elapsedMs;
      this.cells = save.cells;
      this.flagMode = save.flagMode;
      this.everWrongFlag = save.everWrongFlag;
      this.manualAllFlags = save.manualAllFlags;
      this.reported = save.reported;
      this.bestTimes = save.bestTimes;
      return true;
    } catch (_) { return false; }
  }

  private validIndex(index: number): boolean {
    return Number.isInteger(index) && index >= 0 && index < this.cells.length;
  }

  private random(): number {
    this.seed = (1664525 * this.seed + 1013904223) % 4294967296;
    return this.seed / 4294967296;
  }

  private place(first: number): void {
    const safe = mineNeighbors(first, this.level.rows, this.level.cols);
    safe.push(first);
    const candidates: number[] = [];
    for (let i = 0; i < this.cells.length; i += 1) if (!safe.includes(i)) candidates.push(i);
    // Partial Fisher-Yates has bounded cost even on dense boards.
    for (let i = 0; i < this.level.mines; i += 1) {
      const pick = i + Math.floor(this.random() * (candidates.length - i));
      const selected = candidates[pick];
      candidates[pick] = candidates[i];
      candidates[i] = selected;
      this.cells[selected].mine = true;
    }
    this.cells.forEach((cell: SurveyCell) => {
      cell.near = mineNeighbors(cell.index, this.level.rows, this.level.cols)
        .filter((i: number) => this.cells[i].mine).length;
      if (cell.flag && !cell.mine) this.everWrongFlag = true;
    });
    this.phase = 'playing';
  }

  private reveal(indices: number[]): string {
    const mine = indices.find((index: number) => this.cells[index].mine);
    if (mine !== undefined) {
      this.cells[mine].exploded = true;
      this.cells.forEach((cell: SurveyCell) => { if (cell.mine) cell.open = true; });
      this.phase = 'lost';
      return 'lost';
    }
    const before = this.opened();
    const queue = indices.slice();
    for (let head = 0; head < queue.length; head += 1) {
      const cell = this.cells[queue[head]];
      if (cell.open || cell.flag || cell.mine) continue;
      cell.open = true;
      if (cell.near === 0) {
        mineNeighbors(cell.index, this.level.rows, this.level.cols).forEach((n: number) => {
          if (!this.cells[n].open && !this.cells[n].flag) queue.push(n);
        });
      }
    }
    if (this.opened() === this.safeTotal()) {
      this.manualAllFlags = this.cells.every((cell: SurveyCell) => !cell.mine || cell.flag);
      this.cells.forEach((cell: SurveyCell) => { if (cell.mine) cell.flag = true; });
      this.phase = 'won';
      const i = MINE_LEVELS.findIndex((level: MineLevel) => level.key === this.level.key);
      const time = Math.max(1, this.elapsedMs);
      if (this.bestTimes[i] === 0 || time < this.bestTimes[i]) this.bestTimes[i] = time;
      return 'won';
    }
    const count = this.opened() - before;
    return count === 0 ? 'none' : count > 1 ? 'flood' : 'open';
  }
}
