import { BlockPiece, BlockRound, BlockEvent, BLOCK_COLS, BLOCK_ROWS, BLOCK_HIDDEN,
  BLOCK_LOCK_MS, BLOCK_CLEAR_MS, BLOCK_SHAPES, blockSpeed } from './BlockModel';

const KICK_X: number[] = [0, -1, 1, -2, 2, 0, -1, 1, 0];
const KICK_Y: number[] = [0, 0, 0, 0, 0, -1, -1, -1, -2];
const LINE_POINTS: number[] = [0, 100, 300, 500, 800];

/** Independent, serializable game state. No UI, timers, images or platform APIs. */
export class BlockEngine {
  round: BlockRound;
  revision: number = 0;
  events: BlockEvent[] = [];

  constructor(seed: number = Date.now()) {
    this.round = { version: 1, session: 'block-next-' + seed + '-' + Math.floor(Math.random() * 1000000),
      seed: Math.floor(seed) >>> 0, board: new Array<number>(BLOCK_COLS * BLOCK_ROWS).fill(0), queue: [], bag: [],
      piece: { kind: 0, turn: 0, x: 3, y: 1 }, hold: -1, holdUsed: false,
      score: 0, best: 0, lines: 0, level: 1, combo: -1, maxClear: 0, lastClear: 0, pieces: 0,
      phase: 'falling', clearing: [], clearLeft: 0, fallMs: 0, lockMs: 0, resets: 0,
      elapsed: 0, reported: false, milestones: 0 };
    this.spawn(this.take());
  }

  fits(piece: BlockPiece): boolean {
    const cells = BLOCK_SHAPES[piece.kind][piece.turn];
    for (let i = 0; i < 4; i += 1) {
      const x = piece.x + cells[i] % 4;
      const y = piece.y + Math.floor(cells[i] / 4);
      if (x < 0 || x >= BLOCK_COLS || y < 0 || y >= BLOCK_ROWS || this.round.board[y * BLOCK_COLS + x] !== 0) return false;
    }
    return true;
  }

  shifted(dx: number, dy: number): BlockPiece {
    const p = this.round.piece;
    return { kind: p.kind, turn: p.turn, x: p.x + dx, y: p.y + dy };
  }

  grounded(): boolean { return !this.fits(this.shifted(0, 1)); }

  ghostY(): number {
    const p = this.shifted(0, 0);
    while (this.fits({ kind: p.kind, turn: p.turn, x: p.x, y: p.y + 1 })) p.y += 1;
    return p.y;
  }

  command(action: string): boolean {
    if (this.round.phase !== 'falling') return false;
    if (action === 'left' || action === 'right') return this.move(action === 'left' ? -1 : 1);
    if (action === 'rotate' || action === 'reverse') return this.rotate(action === 'rotate' ? 1 : -1);
    if (action === 'down') {
      if (!this.down()) return false;
      this.addScore(1);
      this.emit('move');
      return true;
    }
    if (action === 'drop') {
      const y = this.ghostY();
      this.addScore((y - this.round.piece.y) * 2);
      this.round.piece.y = y;
      this.emit('drop');
      this.lock();
      return true;
    }
    if (action === 'hold' && !this.round.holdUsed) {
      const kind = this.round.piece.kind;
      const next = this.round.hold < 0 ? this.take() : this.round.hold;
      this.round.hold = kind;
      this.round.holdUsed = true;
      this.spawn(next);
      this.emit('hold');
      return true;
    }
    return false;
  }

  advance(milliseconds: number): void {
    if (!Number.isFinite(milliseconds) || milliseconds <= 0 || this.round.phase === 'over') return;
    let remaining = Math.min(250, milliseconds);
    const round = this.round;
    while (remaining > 0.001 && round.phase !== 'over') {
      if (round.phase === 'clearing') {
        const step = Math.min(remaining, round.clearLeft);
        round.elapsed += step;
        round.clearLeft -= step;
        remaining -= step;
        this.revision += 1;
        if (round.clearLeft <= 0.001) this.compact();
      } else {
        const grounded = this.grounded();
        const due = grounded ? BLOCK_LOCK_MS - round.lockMs : blockSpeed(round.level) - round.fallMs;
        const step = Math.min(remaining, Math.max(0, due));
        round.elapsed += step;
        remaining -= step;
        if (grounded) {
          round.lockMs += step;
          if (round.lockMs + 0.001 >= BLOCK_LOCK_MS) this.lock();
        } else {
          round.lockMs = 0;
          round.fallMs += step;
          if (round.fallMs + 0.001 >= blockSpeed(round.level)) {
            round.fallMs = 0;
            this.down();
          }
        }
      }
    }
  }

  nextDelay(): number {
    if (this.round.phase === 'over') return 0;
    if (this.round.phase === 'clearing') return Math.max(8, Math.min(32, this.round.clearLeft));
    const due = this.grounded() ? BLOCK_LOCK_MS - this.round.lockMs : blockSpeed(this.round.level) - this.round.fallMs;
    return Math.max(8, Math.min(200, due));
  }

  takeEvents(): BlockEvent[] { const events = this.events; this.events = []; return events; }
  serialize(): string { return JSON.stringify(this.round); }

  restore(raw: string): boolean {
    try {
      const saved = JSON.parse(raw) as BlockRound;
      if (!validBlockRound(saved)) return false;
      const before = this.round;
      this.round = saved;
      if (saved.phase === 'falling' && !this.fits(saved.piece)) { this.round = before; return false; }
      this.events = [];
      this.revision += 1;
      return true;
    } catch (_) { return false; }
  }

  private move(dx: number): boolean {
    const wasGrounded = this.grounded();
    const next = this.shifted(dx, 0);
    if (!this.fits(next)) return false;
    this.round.piece = next;
    this.resetLock(wasGrounded);
    this.revision += 1;
    this.emit('move');
    return true;
  }

  private rotate(direction: number): boolean {
    if (this.round.piece.kind === 1) return false;
    const p = this.round.piece;
    const turn = (p.turn + direction + 4) % 4;
    const wasGrounded = this.grounded();
    for (let i = 0; i < KICK_X.length; i += 1) {
      const candidate: BlockPiece = { kind: p.kind, turn: turn, x: p.x + KICK_X[i], y: p.y + KICK_Y[i] };
      if (this.fits(candidate)) {
        this.round.piece = candidate;
        this.resetLock(wasGrounded);
        this.revision += 1;
        this.emit('rotate');
        return true;
      }
    }
    return false;
  }

  private resetLock(wasGrounded: boolean): void {
    if (wasGrounded && this.round.resets < 15) {
      this.round.lockMs = 0;
      this.round.resets += 1;
    }
  }

  private down(): boolean {
    const next = this.shifted(0, 1);
    if (!this.fits(next)) return false;
    this.round.piece = next;
    this.round.fallMs = 0;
    this.round.lockMs = 0;
    this.revision += 1;
    return true;
  }

  private lock(): void {
    const round = this.round;
    const p = round.piece;
    const cells = BLOCK_SHAPES[p.kind][p.turn];
    for (let i = 0; i < 4; i += 1) round.board[(p.y + Math.floor(cells[i] / 4)) * BLOCK_COLS + p.x + cells[i] % 4] = p.kind + 1;
    round.pieces += 1;
    round.clearing = [];
    for (let y = 0; y < BLOCK_ROWS; y += 1) {
      let full = true;
      for (let x = 0; x < BLOCK_COLS; x += 1) if (round.board[y * BLOCK_COLS + x] === 0) { full = false; break; }
      if (full) round.clearing.push(y);
    }
    round.lastClear = round.clearing.length;
    if (round.lastClear > 0) {
      round.combo += 1;
      round.maxClear = Math.max(round.maxClear, round.lastClear);
      this.addScore((LINE_POINTS[round.lastClear] + Math.max(0, round.combo) * 50) * round.level);
      round.lines += round.lastClear;
      const level = 1 + Math.floor(round.lines / 20);
      if (level > round.level) this.emit('level');
      round.level = level;
      round.phase = 'clearing';
      round.clearLeft = BLOCK_CLEAR_MS;
      this.emit(round.lastClear === 4 ? 'four' : 'clear', round.lastClear);
    } else {
      round.combo = -1;
      this.emit('lock');
      this.nextPiece();
    }
    this.revision += 1;
  }

  private compact(): void {
    const round = this.round;
    let write = BLOCK_ROWS - 1;
    for (let read = BLOCK_ROWS - 1; read >= 0; read -= 1) {
      if (round.clearing.includes(read)) continue;
      for (let x = 0; x < BLOCK_COLS; x += 1) round.board[write * BLOCK_COLS + x] = round.board[read * BLOCK_COLS + x];
      write -= 1;
    }
    while (write >= 0) {
      for (let x = 0; x < BLOCK_COLS; x += 1) round.board[write * BLOCK_COLS + x] = 0;
      write -= 1;
    }
    round.clearing = [];
    round.clearLeft = 0;
    this.nextPiece();
    this.revision += 1;
  }

  private nextPiece(): void {
    if (this.round.board.slice(0, BLOCK_HIDDEN * BLOCK_COLS).some((cell: number): boolean => cell > 0)) {
      this.end(); return;
    }
    this.round.holdUsed = false;
    this.spawn(this.take());
  }

  private spawn(kind: number): void {
    const round = this.round;
    round.piece = { kind: kind, turn: 0, x: 3, y: 1 };
    round.phase = 'falling';
    round.fallMs = 0; round.lockMs = 0; round.resets = 0;
    if (!this.fits(round.piece)) this.end();
    this.revision += 1;
  }

  private end(): void { this.round.phase = 'over'; this.revision += 1; this.emit('finish'); }
  private addScore(points: number): void { this.round.score += points; this.round.best = Math.max(this.round.best, this.round.score); }
  private emit(name: string, lines: number = 0): void { this.events.push({ name: name, lines: lines }); }

  private take(): number {
    while (this.round.queue.length < 4) {
      if (this.round.bag.length === 0) {
        this.round.bag = [0, 1, 2, 3, 4, 5, 6];
        for (let i = 6; i > 0; i -= 1) {
          this.round.seed = (Math.imul(this.round.seed, 1664525) + 1013904223) >>> 0;
          const j = Math.floor(this.round.seed / 4294967296 * (i + 1));
          const value = this.round.bag[i]; this.round.bag[i] = this.round.bag[j]; this.round.bag[j] = value;
        }
      }
      const kind = this.round.bag.pop();
      if (kind !== undefined) this.round.queue.push(kind);
    }
    const kind = this.round.queue.shift();
    return kind === undefined ? 0 : kind;
  }
}

function blockRange(value: number, min: number, max: number): boolean {
  return Number.isFinite(value) && value >= min && value <= max;
}
function blockInteger(value: number, min: number, max: number): boolean {
  return Number.isInteger(value) && blockRange(value, min, max);
}
function validBlockRound(r: BlockRound): boolean {
  if (r === null || r === undefined || r.version !== 1 || typeof r.session !== 'string' ||
    !r.session.startsWith('block-next-') || !blockInteger(r.seed, 0, 4294967295) ||
    !Array.isArray(r.board) || r.board.length !== 220 || !r.board.every((v: number): boolean => blockInteger(v, 0, 7)) ||
    !Array.isArray(r.queue) || r.queue.length !== 3 || !r.queue.every((v: number): boolean => blockInteger(v, 0, 6)) ||
    !Array.isArray(r.bag) || r.bag.length > 6 || new Set<number>(r.bag).size !== r.bag.length ||
    !r.bag.every((v: number): boolean => blockInteger(v, 0, 6)) ||
    !blockInteger(r.hold, -1, 6) || typeof r.holdUsed !== 'boolean' ||
    !blockInteger(r.score, 0, 1e12) || !blockInteger(r.best, r.score, 1e12) ||
    !blockInteger(r.lines, 0, 1e8) || r.level !== 1 + Math.floor(r.lines / 20) ||
    !blockInteger(r.combo, -1, 1e8) || !blockInteger(r.maxClear, 0, 4) || !blockInteger(r.lastClear, 0, 4) ||
    !blockInteger(r.pieces, 0, 1e9) || !['falling', 'clearing', 'over'].includes(r.phase) ||
    !blockRange(r.clearLeft, 0, BLOCK_CLEAR_MS) || !blockRange(r.fallMs, 0, 700) ||
    !blockRange(r.lockMs, 0, BLOCK_LOCK_MS) || !blockInteger(r.resets, 0, 15) ||
    !blockRange(r.elapsed, 0, 1e12) || typeof r.reported !== 'boolean' || !blockInteger(r.milestones, 0, 7) ||
    !Array.isArray(r.clearing) || r.clearing.length > 4 || new Set<number>(r.clearing).size !== r.clearing.length) return false;
  const p = r.piece;
  if (p === null || p === undefined || !blockInteger(p.kind, 0, 6) || !blockInteger(p.turn, 0, 3) ||
    !blockInteger(p.x, -3, 9) || !blockInteger(p.y, 0, 21)) return false;
  for (let i = 0; i < r.clearing.length; i += 1) {
    const row = r.clearing[i];
    if (!blockInteger(row, 0, 21)) return false;
    for (let x = 0; x < 10; x += 1) if (r.board[row * 10 + x] === 0) return false;
  }
  // A non-clearing snapshot cannot contain a full row. Otherwise a later lock
  // could score more than four rows or retain already-cleared cells.
  for (let row = 0; row < BLOCK_ROWS; row += 1) {
    let full = true;
    for (let col = 0; col < BLOCK_COLS; col += 1) {
      if (r.board[row * BLOCK_COLS + col] === 0) { full = false; break; }
    }
    if (full !== r.clearing.includes(row)) return false;
  }
  return r.phase === 'clearing' ? r.clearing.length > 0 && r.clearLeft > 0 : r.clearing.length === 0 && r.clearLeft === 0;
}
