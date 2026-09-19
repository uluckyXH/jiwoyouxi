import { BLOOM_HISTORY_LIMIT, BloomMode, BloomProfile, BloomRound, BloomSave, BloomTurn,
  bloomCloneRound, bloomConfig, bloomEmptyTurn } from './BloomModel';
import { bloomAllLines, bloomLinesAt, bloomPath } from './BloomRules';

let bloomSessionSequence: number = 0;

export class BloomEngine {
  round: BloomRound = { session: '', mode: 'garden', board: [], next: [], seed: 1,
    score: 0, moves: 0, cleared: 0, ended: false, reported: false };
  profile: BloomProfile = { bestGarden: 0, bestClassic: 0, totalCleared: 0 };
  history: BloomRound[] = [];
  credited: number = 0;

  constructor(mode: BloomMode = 'garden', seed: number = Date.now()) { this.reset(mode, seed); }

  reset(mode: BloomMode = this.round.mode, seed: number = Date.now() + Math.floor(Math.random() * 1000000)): void {
    const config = bloomConfig(mode);
    bloomSessionSequence += 1;
    this.round = { session: `bloom-${Date.now().toString(36)}-${bloomSessionSequence}-${(seed >>> 0).toString(36)}`,
      mode: config.mode, board: new Array<number>(config.size * config.size).fill(-1), next: [],
      seed: (seed >>> 0) || 1, score: 0, moves: 0, cleared: 0, ended: false, reported: false };
    this.history = [];
    this.credited = 0;
    for (let i = 0; i < config.initial; i += 1) {
      const empty = this.emptyCells();
      const index = empty[this.random(empty.length)];
      this.round.board[index] = this.random(config.colors);
      // An opening board never contains an already completed line.
      if (bloomLinesAt(this.round.board, config.size, index).length > 0) {
        this.round.board[index] = (this.round.board[index] + 1) % config.colors;
      }
    }
    this.round.next = this.nextBatch();
  }

  move(from: number, to: number): BloomTurn {
    if (this.round.ended) { return bloomEmptyTurn(); }
    const config = bloomConfig(this.round.mode);
    const path = bloomPath(this.round.board, config.size, from, to);
    if (path.length < 2) { return bloomEmptyTurn(); }
    this.history.push(bloomCloneRound(this.round));
    if (this.history.length > BLOOM_HISTORY_LIMIT) { this.history.shift(); }
    const color = this.round.board[from];
    this.round.board[from] = -1;
    this.round.board[to] = color;
    const afterMove = this.round.board.slice();
    let removed = bloomLinesAt(this.round.board, config.size, to);
    const clearFromMove = removed.length > 0;
    const spawned: number[] = [];
    if (!clearFromMove) {
      const batch = this.round.next.slice();
      for (let i = 0; i < batch.length; i += 1) {
        const empty = this.emptyCells();
        if (empty.length === 0) { break; }
        const index = empty[this.random(empty.length)];
        this.round.board[index] = batch[i];
        spawned.push(index);
      }
      removed = bloomAllLines(this.round.board, config.size, spawned);
      this.round.next = this.nextBatch();
    }
    const spawnBoard = this.round.board.slice();
    removed.forEach((index: number) => { this.round.board[index] = -1; });
    // Clearing the last beads must not leave a board with nothing selectable.
    const refilled: number[] = [];
    if (removed.length > 0 && this.round.board.every((color: number) => color < 0)) {
      this.round.next.forEach((color: number) => {
        const empty = this.emptyCells();
        const index = empty[this.random(empty.length)];
        this.round.board[index] = color;
        refilled.push(index);
      });
      this.round.next = this.nextBatch();
    }
    const gain = removed.length * 2;
    this.round.moves += 1;
    this.round.cleared += removed.length;
    this.round.score += gain;
    this.round.ended = this.emptyCells().length === 0;
    // A round's high-water mark survives undo: replaying a clear cannot farm a lifetime badge.
    this.profile.totalCleared += Math.max(0, this.round.cleared - this.credited);
    this.credited = Math.max(this.credited, this.round.cleared);
    if (this.round.mode === 'garden') {
      this.profile.bestGarden = Math.max(this.profile.bestGarden, this.round.score);
    } else { this.profile.bestClassic = Math.max(this.profile.bestClassic, this.round.score); }
    return { valid: true, path: path, color: color, afterMove: afterMove, spawnBoard: spawnBoard,
      spawned: spawned, refilled: refilled, removed: removed, gain: gain, clearFromMove: clearFromMove };
  }

  undo(): boolean {
    if (this.round.ended || this.history.length === 0) { return false; }
    const previous = this.history.pop();
    if (previous === undefined) { return false; }
    this.round = bloomCloneRound(previous);
    return true;
  }

  best(): number { return this.round.mode === 'garden' ? this.profile.bestGarden : this.profile.bestClassic; }

  snapshot(): BloomSave {
    return { version: 1, round: bloomCloneRound(this.round), history: this.history.map(bloomCloneRound),
      profile: { bestGarden: this.profile.bestGarden, bestClassic: this.profile.bestClassic,
        totalCleared: this.profile.totalCleared }, credited: this.credited };
  }

  serialize(): string { return JSON.stringify(this.snapshot()); }

  restore(raw: string): boolean {
    if (raw.length === 0 || raw.length > 262144) { return false; }
    try {
      const saved = JSON.parse(raw) as BloomSave;
      if (!this.validSave(saved)) { return false; }
      this.round = bloomCloneRound(saved.round);
      this.profile = { bestGarden: saved.profile.bestGarden, bestClassic: saved.profile.bestClassic,
        totalCleared: saved.profile.totalCleared };
      this.credited = saved.credited;
      this.history = saved.history.map(bloomCloneRound);
      return true;
    } catch (_) { return false; }
  }

  private random(limit: number): number {
    let seed = this.round.seed;
    seed ^= seed << 13;
    seed ^= seed >>> 17;
    seed ^= seed << 5;
    this.round.seed = (seed >>> 0) || 1;
    return Math.floor(this.round.seed / 4294967296 * limit);
  }

  private nextBatch(): number[] {
    const config = bloomConfig(this.round.mode);
    const next: number[] = [];
    for (let i = 0; i < config.batch; i += 1) { next.push(this.random(config.colors)); }
    return next;
  }

  private emptyCells(): number[] {
    const result: number[] = [];
    this.round.board.forEach((color: number, index: number) => { if (color < 0) { result.push(index); } });
    return result;
  }

  private count(value: number): boolean { return Number.isInteger(value) && value >= 0 && value <= 1000000000; }

  private validRound(round: BloomRound): boolean {
    if (round === undefined || round === null || !['garden', 'classic'].includes(round.mode) ||
      typeof round.session !== 'string' || round.session.length === 0 || round.session.length > 128 ||
      !Number.isInteger(round.seed) || round.seed < 1 || round.seed > 4294967295 ||
      !this.count(round.score) || !this.count(round.moves) || !this.count(round.cleared) ||
      round.score !== round.cleared * 2 || typeof round.ended !== 'boolean' || typeof round.reported !== 'boolean') { return false; }
    const config = bloomConfig(round.mode);
    if (!Array.isArray(round.board) || round.board.length !== config.size * config.size ||
      !round.board.every((color: number) => Number.isInteger(color) && color >= -1 && color < config.colors) ||
      !Array.isArray(round.next) || round.next.length !== config.batch ||
      !round.next.every((color: number) => Number.isInteger(color) && color >= 0 && color < config.colors)) { return false; }
    if (round.ended !== !round.board.includes(-1) || (round.reported && !round.ended)) { return false; }
    return !round.board.some((color: number, index: number) => color >= 0 && bloomLinesAt(round.board, config.size, index).length > 0);
  }

  private validSave(saved: BloomSave): boolean {
    if (saved === null || saved === undefined || saved.version !== 1 || !this.validRound(saved.round) ||
      saved.profile === undefined || saved.profile === null || !this.count(saved.profile.bestGarden) ||
      !this.count(saved.profile.bestClassic) || !this.count(saved.profile.totalCleared) || !this.count(saved.credited) ||
      saved.credited < saved.round.cleared || saved.profile.totalCleared < saved.credited ||
      !Array.isArray(saved.history) || saved.history.length > BLOOM_HISTORY_LIMIT) { return false; }
    const best = saved.round.mode === 'garden' ? saved.profile.bestGarden : saved.profile.bestClassic;
    if (best < saved.credited * 2) { return false; }
    let moves = -1;
    for (let i = 0; i < saved.history.length; i += 1) {
      const round = saved.history[i];
      if (!this.validRound(round) || round.session !== saved.round.session || round.mode !== saved.round.mode ||
        round.ended || round.moves <= moves || round.moves >= saved.round.moves || round.cleared > saved.credited) { return false; }
      moves = round.moves;
    }
    return true;
  }
}
