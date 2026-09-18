import { GLOW_MAX_TILE, GlowDirection, GlowTile, GlowMotion, GlowTurn, GlowSave, glowClone, glowMax } from './GlowModel';

function lineIndex(direction: GlowDirection, line: number, step: number): number {
  if (direction === 'left') return line * 4 + step;
  if (direction === 'right') return line * 4 + 3 - step;
  if (direction === 'up') return step * 4 + line;
  return (3 - step) * 4 + line;
}

/** Pure slide: no spawning or input mutation, and a merged pair is consumed once. */
export function glowSlide(tiles: GlowTile[], direction: GlowDirection): GlowTurn {
  const result: GlowTurn = { moved: false, gain: 0, motions: [], tiles: [], merged: [], spawned: 0,
    previousMax: glowMax(tiles) };
  for (let line = 0; line < 4; line++) {
    const packed: GlowTile[] = [];
    for (let step = 0; step < 4; step++) {
      const index = lineIndex(direction, line, step);
      const tile = tiles.find((item: GlowTile) => item.index === index);
      if (tile !== undefined) packed.push(tile);
    }
    let output = 0;
    for (let at = 0; at < packed.length; at++) {
      const tile = packed[at];
      const target = lineIndex(direction, line, output++);
      const other = packed[at + 1];
      const merges = other !== undefined && tile.value === other.value && tile.value < GLOW_MAX_TILE;
      result.motions.push({ id: tile.id, value: tile.value, from: tile.index, to: target });
      result.tiles.push({ id: tile.id, value: merges ? tile.value * 2 : tile.value, index: target });
      if (target !== tile.index) result.moved = true;
      if (merges) {
        result.motions.push({ id: other.id, value: other.value, from: other.index, to: target });
        result.merged.push(tile.id);
        result.gain += tile.value * 2;
        result.moved = true;
        at++;
      }
    }
  }
  return result;
}

export function glowCanMove(tiles: GlowTile[]): boolean {
  if (tiles.length < 16) return true;
  for (let i = 0; i < 16; i++) {
    const tile = tiles.find((item: GlowTile) => item.index === i);
    if (tile === undefined) return true;
    if (tile.value >= GLOW_MAX_TILE) continue;
    if (i % 4 < 3 && tiles.some((item: GlowTile) => item.index === i + 1 && item.value === tile.value)) return true;
    if (i < 12 && tiles.some((item: GlowTile) => item.index === i + 4 && item.value === tile.value)) return true;
  }
  return false;
}

function integer(value: number, min: number, max: number): boolean {
  return typeof value === 'number' && Number.isInteger(value) && value >= min && value <= max;
}

export class GlowEngine {
  tiles: GlowTile[] = [];
  score: number = 0;
  moves: number = 0;
  streak: number = 0;
  bestStreak: number = 0;
  continued: boolean = false;
  ended: boolean = false;
  reported: boolean = false;
  session: string = '';
  private seed: number = 1;
  private nextId: number = 1;

  constructor() { this.reset(); }

  reset(seed: number = Math.floor(Math.random() * 4294967296)): void {
    this.seed = seed >>> 0;
    this.session = `glow:${Date.now()}:${this.seed}:${Math.random().toString(36).slice(2, 8)}`;
    this.nextId = 1;
    this.tiles = [];
    this.score = 0;
    this.moves = 0;
    this.streak = 0;
    this.bestStreak = 0;
    this.continued = false;
    this.ended = false;
    this.reported = false;
    this.spawn();
    this.spawn();
  }

  private random(): number {
    this.seed = (1664525 * this.seed + 1013904223) >>> 0;
    return this.seed / 4294967296;
  }

  private spawn(): number {
    const empty: number[] = [];
    for (let i = 0; i < 16; i++) if (!this.tiles.some((tile: GlowTile) => tile.index === i)) empty.push(i);
    if (empty.length === 0) return 0;
    const index = empty[Math.floor(this.random() * empty.length)];
    const tile: GlowTile = { id: this.nextId++, index: index, value: this.random() < 0.9 ? 2 : 4 };
    this.tiles.push(tile);
    return tile.id;
  }

  move(direction: GlowDirection): GlowTurn {
    if (this.ended || this.needsCelebration()) {
      return { moved: false, gain: 0, motions: [], tiles: glowClone(this.tiles), merged: [], spawned: 0,
        previousMax: glowMax(this.tiles) };
    }
    const turn = glowSlide(this.tiles, direction);
    if (!turn.moved) return turn;
    this.tiles = glowClone(turn.tiles);
    this.score += turn.gain;
    this.moves++;
    this.streak = turn.gain > 0 ? this.streak + 1 : 0;
    this.bestStreak = Math.max(this.bestStreak, this.streak);
    turn.spawned = this.spawn();
    turn.tiles = glowClone(this.tiles);
    this.ended = !glowCanMove(this.tiles);
    return turn;
  }

  needsCelebration(): boolean { return !this.continued && glowMax(this.tiles) >= 2048; }
  continuePlaying(): void { if (glowMax(this.tiles) >= 2048) this.continued = true; }

  serialize(): string {
    const save: GlowSave = { version: 1, session: this.session, seed: this.seed, nextId: this.nextId,
      tiles: glowClone(this.tiles), score: this.score, moves: this.moves, streak: this.streak,
      bestStreak: this.bestStreak, continued: this.continued, ended: this.ended, reported: this.reported };
    return JSON.stringify(save);
  }

  restore(raw: string): boolean {
    try {
      const save = JSON.parse(raw) as GlowSave;
      if (save === null || typeof save !== 'object' || save.version !== 1 ||
        typeof save.session !== 'string' || save.session.length < 1 || save.session.length > 160 ||
        !integer(save.seed, 0, 4294967295) || !integer(save.nextId, 3, 100000003) ||
        !integer(save.score, 0, Number.MAX_SAFE_INTEGER) || save.score % 4 !== 0 ||
        !integer(save.moves, 0, 100000000) || !integer(save.streak, 0, save.moves) ||
        !integer(save.bestStreak, save.streak, save.moves) || typeof save.continued !== 'boolean' ||
        typeof save.ended !== 'boolean' || typeof save.reported !== 'boolean' ||
        !Array.isArray(save.tiles) || save.tiles.length < 2 || save.tiles.length > 16) return false;
      const ids: Set<number> = new Set<number>();
      const slots: Set<number> = new Set<number>();
      for (let i = 0; i < save.tiles.length; i++) {
        const tile = save.tiles[i];
        if (tile === null || typeof tile !== 'object' || !integer(tile.id, 1, save.nextId - 1) ||
          !integer(tile.index, 0, 15) || !integer(tile.value, 2, GLOW_MAX_TILE) ||
          !Number.isInteger(Math.log2(tile.value)) || ids.has(tile.id) || slots.has(tile.index)) return false;
        ids.add(tile.id);
        slots.add(tile.index);
      }
      if (save.nextId !== save.moves + 3 || save.ended === glowCanMove(save.tiles) ||
        save.continued && glowMax(save.tiles) < 2048 || save.reported && !save.ended) return false;
      this.session = save.session;
      this.seed = save.seed;
      this.nextId = save.nextId;
      this.tiles = glowClone(save.tiles);
      this.score = save.score;
      this.moves = save.moves;
      this.streak = save.streak;
      this.bestStreak = save.bestStreak;
      this.continued = save.continued;
      this.ended = save.ended;
      this.reported = save.reported;
      return true;
    } catch (_) { return false; }
  }
}
