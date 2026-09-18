import {
  MarketBody, MarketMerge, MarketRound, MARKET_DROP_DELAY, MARKET_FLOOR, MARKET_FRUITS,
  MARKET_LEFT, MARKET_LINE, MARKET_OVERFLOW_GRACE, MARKET_RIGHT, MARKET_STEP, marketMergeScore
} from './MarketModel';

const OPENING: number[] = [0, 0, 1, 2, 2, 3];
const GRAVITY: number = 1250;
const MAX_SPEED: number = 620;
const SOLVER_PASSES: number = 6;
const MAX_CATCH_UP_STEPS: number = 2;
const RADII: number[] = MARKET_FRUITS.map(fruit => fruit.radius);
const INVERSE_MASS: number[] = RADII.map(radius => 1 / (radius * radius));

const CONTACT_MARGIN: number = 6;
const SLEEP_DELAY: number = 0.8;

/** Runtime contact state is separate from the serializable fruit and SVG model. */
class MarketParticle {
  body: MarketBody;
  radius: number;
  inverseMass: number;
  sleeping: boolean = false;
  removed: boolean = false;
  quiet: number = 0;
  previousX: number = 0;
  previousY: number = 0;
  anchorX: number = 0;
  anchorY: number = 0;
  floorSupport: boolean = false;
  supports: MarketParticle[] = [];

  constructor(body: MarketBody) {
    this.body = body;
    this.radius = RADII[body.level];
    this.inverseMass = INVERSE_MASS[body.level];
  }
}

/** Simulation coordinates never depend on window dimensions. Pausing does not advance time. */
export class MarketEngine {
  round: MarketRound;
  events: MarketMerge[] = [];
  lastSteps: number = 0;
  lastSolvedSteps: number = 0;
  lastPairChecks: number = 0;
  sleeping: boolean = false;
  sleepingBodies: number = 0;
  visualVersion: number = 0;
  lastBroadChecks: number = 0;
  lastSolverPasses: number = 0;
  private accumulator: number = 0;
  private particles: MarketParticle[] = [];
  private particleMap: Map<number, MarketParticle> = new Map<number, MarketParticle>();
  private sorted: MarketParticle[] = [];
  private sourceBodies: MarketBody[] = [];
  private pairsA: MarketParticle[] = [];
  private pairsB: MarketParticle[] = [];
  private pairCount: number = 0;
  private pairsDirty: boolean = false;
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
    const aim = Math.max(MARKET_LEFT + radius, Math.min(MARKET_RIGHT - radius, x));
    if (aim !== this.round.aim) this.visualVersion += 1;
    this.round.aim = aim;
  }

  drop(): boolean {
    if (!this.canDrop()) return false;
    this.sleeping = false;
    this.visualVersion += 1;
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
    this.lastSteps = 0;
    this.lastSolvedSteps = 0;
    this.lastPairChecks = 0;
    this.lastBroadChecks = 0;
    this.lastSolverPasses = 0;
    if (this.events.length > 0) this.events = [];
    if (this.round.ended || !Number.isFinite(seconds) || seconds <= 0) return this.events;
    // A slow display callback must not trigger an ever-growing physics backlog.
    // 60 Hz keeps max fall travel (10.34 units) below the smallest fruit's diameter (26).
    this.accumulator = Math.min(this.accumulator + seconds, MARKET_STEP * MAX_CATCH_UP_STEPS);
    while (this.accumulator + 0.000001 >= MARKET_STEP && this.lastSteps < MAX_CATCH_UP_STEPS && !this.round.ended) {
      this.tick();
      this.accumulator -= MARKET_STEP;
      this.lastSteps += 1;
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
    this.round.resting = this.particles.filter((p: MarketParticle): boolean => p.sleeping && !p.removed)
      .map((p: MarketParticle): number => p.body.id);
    return JSON.stringify(this.round);
  }

  restore(raw: string): boolean {
    try {
      const saved = JSON.parse(raw) as MarketRound;
      if (!validRound(saved)) return false;
      this.round = saved;
      this.accumulator = 0;
      this.events = [];
      this.sourceBodies = [];
      this.particles = [];
      this.particleMap.clear();
      this.syncParticles();
      const resting = new Set<number>(saved.resting === undefined ? [] : saved.resting);
      for (let i = 0; i < this.particles.length; i += 1) {
        const p = this.particles[i];
        if (resting.has(p.body.id) && p.body.vx === 0 && p.body.vy === 0 && saved.time >= p.body.unlock &&
          p.body.x - p.radius >= MARKET_LEFT && p.body.x + p.radius <= MARKET_RIGHT &&
          p.body.y + p.radius <= MARKET_FLOOR) {
          p.sleeping = this.captureSupports(p);
          p.quiet = p.sleeping ? SLEEP_DELAY : 0;
        }
      }
      this.sleeping = false;
      this.visualVersion += 1;
      this.aimAt(saved.aim);
      return true;
    } catch (_) {
      return false;
    }
  }

  private syncParticles(): void {
    const bodies = this.round.bodies;
    if (this.sourceBodies === bodies && this.particles.length === bodies.length) return;
    const previous = this.particleMap;
    for (let i = 0; i < this.particles.length; i += 1) this.particles[i].removed = true;
    const next: Map<number, MarketParticle> = new Map<number, MarketParticle>();
    this.particles.length = 0;
    for (let i = 0; i < bodies.length; i += 1) {
      const body = bodies[i];
      const known = previous.get(body.id);
      const p = known !== undefined && known.body === body ? known : new MarketParticle(body);
      p.removed = false;
      this.particles.push(p);
      next.set(body.id, p);
    }
    this.particleMap = next;
    this.sorted = this.particles.slice();
    this.sourceBodies = bodies;
    this.pairsDirty = true;
  }

  private wakeParticle(p: MarketParticle): void {
    if (!p.sleeping) return;
    p.sleeping = false;
    p.quiet = 0;
    this.pairsDirty = true;
  }

  private validateSupports(): void {
    for (let i = 0; i < this.particles.length; i += 1) {
      const p = this.particles[i];
      if (!p.sleeping || p.floorSupport) continue;
      if (p.supports.length === 0) { this.wakeParticle(p); continue; }
      for (let j = 0; j < p.supports.length; j += 1) {
        const support = p.supports[j];
        const dx = support.body.x - p.body.x;
        const dy = support.body.y - p.body.y;
        const reach = p.radius + support.radius + 0.5;
        if (support.removed || dy <= 0 || dx * dx + dy * dy > reach * reach) {
          this.wakeParticle(p);
          break;
        }
      }
    }
  }

  private tick(): void {
    const round = this.round;
    round.time += MARKET_STEP;
    this.syncParticles();
    this.validateSupports();
    let active = 0;
    for (let i = 0; i < this.particles.length; i += 1) {
      const p = this.particles[i];
      if (p.sleeping) continue;
      active += 1;
      const body = p.body;
      p.previousX = body.x;
      p.previousY = body.y;
      body.vy = Math.min(MAX_SPEED, body.vy + GRAVITY * MARKET_STEP);
      body.vx *= 0.996004;
      body.x += body.vx * MARKET_STEP;
      body.y += body.vy * MARKET_STEP;
      body.angle += body.vx / p.radius * MARKET_STEP * 0.7;
      this.walls(p);
    }
    if (active > 0) {
      this.lastSolvedSteps += 1;
      this.visualVersion += 1;
      this.buildPairs();
      for (let pass = 0; pass < SOLVER_PASSES; pass += 1) {
        this.lastSolverPasses += 1;
        const overlap = this.solveContacts(pass === 0);
        for (let i = 0; i < this.particles.length; i += 1) {
          const p = this.particles[i];
          if (p.sleeping) continue;
          this.walls(p);
          // A cached pair list is valid only while BOTH fruit stay within half
          // its padding. Deep overlaps, merges and wakes rebuild it immediately.
          const movedX = p.body.x - p.anchorX;
          const movedY = p.body.y - p.anchorY;
          if (movedX * movedX + movedY * movedY > CONTACT_MARGIN * CONTACT_MARGIN / 4) this.pairsDirty = true;
        }
        if (!this.pairsDirty && overlap < 0.12) break;
        if (this.pairsDirty && pass + 1 < SOLVER_PASSES) this.buildPairs();
      }
      for (let i = 0; i < this.particles.length; i += 1) {
        const p = this.particles[i];
        if (!p.sleeping && p.body.vy > 0) {
          // Position constraints have already stopped a supported fruit. Do not
          // carry fictitious downward velocity into the next resting contact.
          // Upward rebound velocity is preserved.
          p.body.vy = Math.min(p.body.vy, Math.max(0, (p.body.y - p.previousY) / MARKET_STEP));
        }
      }
      this.updateSleeping();
    }
    this.sleepingBodies = 0;
    let overflowing = false;
    for (let i = 0; i < this.particles.length; i += 1) {
      const p = this.particles[i];
      if (p.sleeping) this.sleepingBodies += 1;
      if (round.time - p.body.born >= 0.7 && p.body.y - p.radius < MARKET_LINE) overflowing = true;
    }
    this.sleeping = this.sleepingBodies === this.particles.length;
    round.overflow = overflowing ? round.overflow + MARKET_STEP : 0;
    if (round.overflow >= MARKET_OVERFLOW_GRACE) round.ended = true;
  }

  private captureSupports(p: MarketParticle): boolean {
    p.supports.length = 0;
    p.floorSupport = p.body.y + p.radius >= MARKET_FLOOR - 0.12;
    if (p.floorSupport) return true;
    for (let i = 0; i < this.particles.length; i += 1) {
      const support = this.particles[i];
      if (support === p || support.removed) continue;
      const dx = support.body.x - p.body.x;
      const dy = support.body.y - p.body.y;
      const sum = p.radius + support.radius;
      // A shallow diagonal contact can support a tightly packed fruit too.
      // Strictly downward support links cannot form floating support cycles.
      if (dy > 0.001 && dx * dx + dy * dy <= (sum + 0.5) * (sum + 0.5)) p.supports.push(support);
    }
    return p.supports.length > 0;
  }

  private updateSleeping(): void {
    for (let i = 0; i < this.particles.length; i += 1) {
      const p = this.particles[i];
      if (p.sleeping) continue;
      const body = p.body;
      const quiet = Math.abs(body.x - p.previousX) < 0.08 && Math.abs(body.y - p.previousY) < 0.08 &&
        this.round.time >= body.unlock;
      p.quiet = quiet ? p.quiet + MARKET_STEP : 0;
      if (p.quiet >= SLEEP_DELAY && this.captureSupports(p)) {
        p.sleeping = true;
        body.vx = 0;
        body.vy = 0;
      }
    }
  }

  private walls(p: MarketParticle): void {
    const body = p.body;
    const radius = p.radius;
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

  /** Build nearby pairs once per step, not once per solver iteration. */
  private buildPairs(): void {
    const sorted = this.sorted;
    for (let i = 1; i < sorted.length; i += 1) {
      const p = sorted[i];
      const left = p.body.x - p.radius;
      let j = i - 1;
      while (j >= 0 && sorted[j].body.x - sorted[j].radius > left) {
        sorted[j + 1] = sorted[j];
        j -= 1;
      }
      sorted[j + 1] = p;
    }
    this.pairCount = 0;
    this.pairsDirty = false;
    for (let i = 0; i < sorted.length; i += 1) {
      const a = sorted[i];
      a.anchorX = a.body.x;
      a.anchorY = a.body.y;
      for (let j = i + 1; j < sorted.length; j += 1) {
        const b = sorted[j];
        if (b.body.x - b.radius > a.body.x + a.radius + CONTACT_MARGIN) break;
        if (a.sleeping && b.sleeping) continue;
        this.lastBroadChecks += 1;
        const sum = a.radius + b.radius + CONTACT_MARGIN;
        const dx = b.body.x - a.body.x;
        const dy = b.body.y - a.body.y;
        if (dx * dx + dy * dy > sum * sum) continue;
        this.pairsA[this.pairCount] = a;
        this.pairsB[this.pairCount] = b;
        this.pairCount += 1;
      }
    }
    this.pairsA.length = this.pairCount;
    this.pairsB.length = this.pairCount;
  }

  private solveContacts(allowMerge: boolean): number {
    const removed = this.removed;
    const created = this.created;
    removed.clear();
    created.length = 0;
    let maximumOverlap = 0;
    for (let i = 0; i < this.pairCount; i += 1) {
      const pa = this.pairsA[i];
      const pb = this.pairsB[i];
      if ((pa.sleeping && pb.sleeping) || pa.removed || pb.removed) continue;
      const a = pa.body;
      const b = pb.body;
      this.lastPairChecks += 1;
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const rr = pa.radius + pb.radius;
      const distanceSquared = dx * dx + dy * dy;
      if (distanceSquared >= rr * rr) continue;
      if (allowMerge && a.level === b.level && a.level < 10 &&
        this.round.time >= a.unlock && this.round.time >= b.unlock) {
        const level = a.level + 1;
        const fruit = this.body(level, (a.x + b.x) / 2, (a.y + b.y) / 2,
          (a.vx + b.vx) * 0.3, Math.min(-45, (a.vy + b.vy) * 0.15));
        created.push(fruit);
        removed.add(a.id);
        removed.add(b.id);
        pa.removed = true;
        pb.removed = true;
        const points = marketMergeScore(a.level);
        this.round.score += points;
        this.round.best = Math.max(this.round.best, this.round.score);
        this.round.merges += 1;
        this.round.highest = Math.max(this.round.highest, level);
        this.events.push({ x: fruit.x, y: fruit.y, level: level, points: points, time: this.round.time });
        continue;
      }
      const distance = Math.sqrt(distanceSquared);
      const nx = distance > 0.0001 ? dx / distance : (a.id < b.id ? 1 : -1);
      const ny = distance > 0.0001 ? dy / distance : 0;
      const overlap = rr - distance;
      maximumOverlap = Math.max(maximumOverlap, overlap);
      const normalSpeed = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny;
      // Quiet supports stay at rest under a gentle contact. An actual impact or
      // penetration wakes the touched fruit and rebuilds its nearby contacts.
      if (overlap > 3 || (normalSpeed < -160 && (pa.sleeping ? pb.quiet : pa.quiet) < 0.1)) {
        this.wakeParticle(pa);
        this.wakeParticle(pb);
      }
      const invA = pa.sleeping ? 0 : pa.inverseMass;
      const invB = pb.sleeping ? 0 : pb.inverseMass;
      const inv = invA + invB;
      if (inv === 0) continue;
      const correction = Math.max(0, overlap - 0.08) * 0.75 / inv;
      a.x -= nx * correction * invA;
      a.y -= ny * correction * invA;
      b.x += nx * correction * invB;
      b.y += ny * correction * invB;
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
    if (removed.size > 0) {
      this.round.bodies = this.round.bodies.filter((body: MarketBody): boolean => !removed.has(body.id)).concat(created);
      this.syncParticles();
      this.validateSupports();
      return 1;
    }
    return maximumOverlap;
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
  if (round.resting !== undefined) {
    if (!Array.isArray(round.resting) || round.resting.length > round.bodies.length) return false;
    const restingIds: Set<number> = new Set<number>();
    for (let i = 0; i < round.resting.length; i += 1) {
      const id = round.resting[i];
      if (!Number.isInteger(id) || !ids.has(id) || restingIds.has(id)) return false;
      restingIds.add(id);
    }
  }
  return true;
}
