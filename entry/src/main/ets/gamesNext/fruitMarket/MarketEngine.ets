import {
  MarketBody, MarketMerge, MarketRound, MARKET_DROP_DELAY, MARKET_FLOOR, MARKET_FRUITS,
  MARKET_LEFT, MARKET_LINE, MARKET_OVERFLOW_GRACE, MARKET_RIGHT, MARKET_STEP, marketMergeScore
} from './MarketModel';

const OPENING: number[] = [0, 0, 1, 2, 2, 3];
const GRAVITY: number = 1250;
const MAX_SPEED: number = 620;
const SOLVER_PASSES: number = 6;

/** Simulation coordinates never depend on window dimensions. Pausing does not advance time. */
export class MarketEngine {
  round: MarketRound;
  events: MarketMerge[] = [];
  private accumulator: number = 0;
  private sorted: MarketBody[] = [];
  private sourceBodies: MarketBody[] = [];
  private removed: Set<number> = new Set<number>();
  private created: MarketBody[] = [];

  constructor(seed: number = Date.now()) {
    this.round = {
      version: 1, sessionId: `market-next-${seed}-${Math.floor(Math.random() * 1000000)}`,
      time: 0, seed: Math.max(1, Math.floor(seed) >>> 0), nextId: 1, drops: 0, score: 0, best: 0,
      current: 0, next: 0, aim: 180, readyAt: 0, highest: 0, merges: 0, overflow: 0,
      ended: false, reported: false, bodies: []
    };
  }

  canDrop(): boolean {
    return !this.round.ended && this.round.time + 0.000001 >= this.round.readyAt;
  }

  aimAt(x: number): void {
    const radius = MARKET_FRUITS[this.round.current].radius;
    this.round.aim = Math.max(MARKET_LEFT + radius, Math.min(MARKET_RIGHT - radius, x));
  }

  drop(): boolean {
    if (!this.canDrop()) return false;
    this.aimAt(this.round.aim);
    this.round.bodies.push(this.body(this.round.current, this.round.aim, 59, 0, 40));
    this.round.drops += 1;
    this.round.current = this.round.next;
    this.round.next = this.levelAt(this.round.drops + 1);
    this.round.readyAt = this.round.time + MARKET_DROP_DELAY;
    this.aimAt(this.round.aim);
    return true;
  }

  advance(seconds: number): MarketMerge[] {
    if (this.events.length > 0) this.events = [];
    if (this.round.ended || !Number.isFinite(seconds) || seconds <= 0) return this.events;
    // Discard long suspended-frame gaps instead of fast-forwarding a resumed game.
    this.accumulator += Math.min(seconds, 0.05);
    while (this.accumulator + 0.000001 >= MARKET_STEP && !this.round.ended) {
      this.tick();
      this.accumulator -= MARKET_STEP;
    }
    return this.events;
  }

  landingY(): number {
    const radius = MARKET_FRUITS[this.round.current].radius;
    let y = MARKET_FLOOR - radius;
    for (let i = 0; i < this.round.bodies.length; i += 1) {
      const body = this.round.bodies[i];
      const sum = radius + MARKET_FRUITS[body.level].radius;
      const dx = this.round.aim - body.x;
      if (Math.abs(dx) < sum) y = Math.min(y, body.y - Math.sqrt(sum * sum - dx * dx));
    }
    return Math.max(59, y);
  }

  serialize(): string {
    return JSON.stringify(this.round);
  }

  restore(raw: string): boolean {
    try {
      const saved = JSON.parse(raw) as MarketRound;
      if (!validRound(saved)) return false;
      this.round = saved;
      this.accumulator = 0;
      this.events = [];
      this.aimAt(saved.aim);
      return true;
    } catch (_) {
      return false;
    }
  }

  private tick(): void {
    const round = this.round;
    round.time += MARKET_STEP;
    for (let i = 0; i < round.bodies.length; i += 1) {
      const body = round.bodies[i];
      body.vy = Math.min(MAX_SPEED, body.vy + GRAVITY * MARKET_STEP);
      body.vx *= 0.998;
      body.x += body.vx * MARKET_STEP;
      body.y += body.vy * MARKET_STEP;
      body.angle += body.vx / MARKET_FRUITS[body.level].radius * MARKET_STEP * 0.7;
      this.walls(body);
    }
    for (let pass = 0; pass < SOLVER_PASSES; pass += 1) {
      this.collide(pass === 0);
      for (let i = 0; i < round.bodies.length; i += 1) this.walls(round.bodies[i]);
    }
    let overflowing = false;
    for (let i = 0; i < round.bodies.length; i += 1) {
      const body = round.bodies[i];
      if (round.time - body.born >= 0.7 && body.y - MARKET_FRUITS[body.level].radius < MARKET_LINE) {
        overflowing = true;
        break;
      }
    }
    round.overflow = overflowing ? round.overflow + MARKET_STEP : 0;
    if (round.overflow >= MARKET_OVERFLOW_GRACE) round.ended = true;
  }

  private walls(body: MarketBody): void {
    const radius = MARKET_FRUITS[body.level].radius;
    if (body.x < MARKET_LEFT + radius) {
      body.x = MARKET_LEFT + radius;
      if (body.vx < 0) body.vx *= -0.22;
    } else if (body.x > MARKET_RIGHT - radius) {
      body.x = MARKET_RIGHT - radius;
      if (body.vx > 0) body.vx *= -0.22;
    }
    if (body.y > MARKET_FLOOR - radius) {
      body.y = MARKET_FLOOR - radius;
      if (body.vy > 0) body.vy = body.vy > 65 ? -body.vy * 0.12 : 0;
      body.vx *= 0.94;
    }
  }

  private collide(allowMerge: boolean): void {
    const bodies = this.round.bodies;
    const sorted = this.sorted;
    if (this.sourceBodies !== bodies || sorted.length !== bodies.length) {
      sorted.length = bodies.length;
      for (let i = 0; i < bodies.length; i += 1) sorted[i] = bodies[i];
      this.sourceBodies = bodies;
    }
    // Between solver passes the list is nearly ordered. Re-sort in place on EVERY
    // pass, so moved/merged fruit cannot be skipped by a stale broad phase.
    for (let i = 1; i < sorted.length; i += 1) {
      const body = sorted[i];
      const left = body.x - MARKET_FRUITS[body.level].radius;
      let j = i - 1;
      while (j >= 0 && sorted[j].x - MARKET_FRUITS[sorted[j].level].radius > left) {
        sorted[j + 1] = sorted[j];
        j -= 1;
      }
      sorted[j + 1] = body;
    }
    const removed = this.removed;
    const created = this.created;
    removed.clear();
    created.length = 0;
    for (let i = 0; i < sorted.length; i += 1) {
      const a = sorted[i];
      if (removed.size > 0 && removed.has(a.id)) continue;
      const ar = MARKET_FRUITS[a.level].radius;
      for (let j = i + 1; j < sorted.length; j += 1) {
        const b = sorted[j];
        const br = MARKET_FRUITS[b.level].radius;
        if (b.x - br > a.x + ar + 2) break;
        if (removed.size > 0 && removed.has(b.id)) continue;
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const rr = ar + br;
        if (Math.abs(dy) > rr || dx * dx + dy * dy >= rr * rr) continue;
        if (allowMerge && a.level === b.level && a.level < 10 &&
          this.round.time >= a.unlock && this.round.time >= b.unlock) {
          const level = a.level + 1;
          const fruit = this.body(level, (a.x + b.x) / 2, (a.y + b.y) / 2,
            (a.vx + b.vx) * 0.3, Math.min(-45, (a.vy + b.vy) * 0.15));
          created.push(fruit);
          removed.add(a.id);
          removed.add(b.id);
          const points = marketMergeScore(a.level);
          this.round.score += points;
          this.round.best = Math.max(this.round.best, this.round.score);
          this.round.merges += 1;
          this.round.highest = Math.max(this.round.highest, level);
          this.events.push({ x: fruit.x, y: fruit.y, level: level, points: points, time: this.round.time });
          break;
        }
        // Deterministic normal also separates exactly coincident, non-mergeable bodies.
        const distance = Math.sqrt(dx * dx + dy * dy);
        const nx = distance > 0.0001 ? dx / distance : (a.id < b.id ? 1 : -1);
        const ny = distance > 0.0001 ? dy / distance : 0;
        const invA = 1 / (ar * ar);
        const invB = 1 / (br * br);
        const inv = invA + invB;
        const correction = Math.max(0, rr - distance - 0.08) * 0.75 / inv;
        a.x -= nx * correction * invA;
        a.y -= ny * correction * invA;
        b.x += nx * correction * invB;
        b.y += ny * correction * invB;
        const normalSpeed = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny;
        if (normalSpeed < 0) {
          const impulse = -(1 + (normalSpeed < -80 ? 0.12 : 0)) * normalSpeed / inv;
          a.vx -= impulse * nx * invA;
          a.vy -= impulse * ny * invA;
          b.vx += impulse * nx * invB;
          b.vy += impulse * ny * invB;
          const tangent = (b.vx - a.vx) * -ny + (b.vy - a.vy) * nx;
          const friction = Math.max(-impulse * 0.18, Math.min(impulse * 0.18, -tangent / inv));
          a.vx -= friction * -ny * invA;
          a.vy -= friction * nx * invA;
          b.vx += friction * -ny * invB;
          b.vy += friction * nx * invB;
        }
      }
    }
    if (removed.size > 0) {
      this.round.bodies = bodies.filter((body: MarketBody): boolean => !removed.has(body.id)).concat(created);
    }
  }

  private body(level: number, x: number, y: number, vx: number, vy: number): MarketBody {
    return { id: this.round.nextId++, level: level, x: x, y: y, vx: vx, vy: vy,
      angle: 0, born: this.round.time, unlock: this.round.time + 0.18 };
  }

  private levelAt(index: number): number {
    if (index < OPENING.length) return OPENING[index];
    this.round.seed = (Math.imul(this.round.seed, 1664525) + 1013904223) >>> 0;
    return Math.floor(this.round.seed / 4294967296 * 5);
  }
}

function finiteRange(value: number, min: number, max: number): boolean {
  return Number.isFinite(value) && value >= min && value <= max;
}

function integerRange(value: number, min: number, max: number): boolean {
  return Number.isInteger(value) && finiteRange(value, min, max);
}

function validRound(round: MarketRound): boolean {
  if (round === null || round === undefined || round.version !== 1 ||
    typeof round.sessionId !== 'string' || !round.sessionId.startsWith('market-next-') ||
    !finiteRange(round.time, 0, 1e9) || !integerRange(round.seed, 0, 4294967295) ||
    !integerRange(round.nextId, 1, 1e9) || !integerRange(round.drops, 0, 1e8) ||
    !integerRange(round.score, 0, 1e9) || !integerRange(round.best, 0, 1e9) || !integerRange(round.current, 0, 4) ||
    !integerRange(round.next, 0, 4) || !finiteRange(round.aim, 0, 360) ||
    !finiteRange(round.readyAt, 0, round.time + MARKET_DROP_DELAY + 0.01) ||
    !integerRange(round.highest, 0, 10) || !integerRange(round.merges, 0, 1e8) ||
    !finiteRange(round.overflow, 0, MARKET_OVERFLOW_GRACE + 0.1) ||
    typeof round.ended !== 'boolean' || typeof round.reported !== 'boolean' ||
    !Array.isArray(round.bodies) || round.bodies.length > 256) return false;
  const ids: Set<number> = new Set<number>();
  for (let i = 0; i < round.bodies.length; i += 1) {
    const b = round.bodies[i];
    if (b === null || b === undefined || !integerRange(b.id, 1, round.nextId - 1) || ids.has(b.id) ||
      !integerRange(b.level, 0, 10) || !finiteRange(b.x, MARKET_LEFT, MARKET_RIGHT) ||
      !finiteRange(b.y, -100, MARKET_FLOOR) || !finiteRange(b.vx, -2000, 2000) ||
      !finiteRange(b.vy, -2000, 2000) || !finiteRange(b.angle, -1e9, 1e9) ||
      !finiteRange(b.born, 0, round.time) || !finiteRange(b.unlock, 0, round.time + 0.2)) return false;
    ids.add(b.id);
  }
  return true;
}
