import {
  RpsBattleEntity,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleOptions,
  RpsBattleResult,
  RpsBattleSnapshot
} from './RpsBattleTypes';
import {
  rpsBattleBeats,
  rpsBattleBuildResult,
  rpsBattleCloneEntities,
  rpsBattleEmptyCounts,
  rpsBattleInitialResult,
  rpsBattlePredatorOf,
  rpsBattlePreyOf
} from './RpsBattleRules';

const ENTITY_RADIUS: number = 14;
const ENTITY_MAX_SPEED: number = 94;
const ENTITY_CHASE_ACCEL: number = 118;
const ENTITY_FLEE_ACCEL: number = 72;
const ENTITY_WANDER_ACCEL: number = 22;
const ENTITY_FLEE_DISTANCE: number = 92;
const ENTITY_FLEE_DISTANCE_SQ: number = ENTITY_FLEE_DISTANCE * ENTITY_FLEE_DISTANCE;
const ENTITY_EDGE_PADDING: number = 18;
const COLLISION_GRID_CELL_SIZE: number = ENTITY_RADIUS * 3;

export class RpsBattleEngine {
  private boardWidth: number;
  private boardHeight: number;
  private options: RpsBattleOptions;
  private random: () => number;
  private entities: RpsBattleEntity[] = [];
  private rockEntities: RpsBattleEntity[] = [];
  private scissorsEntities: RpsBattleEntity[] = [];
  private paperEntities: RpsBattleEntity[] = [];
  private countsCache: RpsBattleFactionCounts = rpsBattleEmptyCounts();
  private factionIndexById: number[] = [];
  private collisionBuckets: RpsBattleEntity[][] = [];
  private collisionActiveBucketIndices: number[] = [];
  private collisionBucketMarks: number[] = [];
  private collisionBucketVersion: number = 1;
  private nextId: number = 1;
  private conversions: number = 0;
  private lastTargetScanCount: number = 0;
  private lastCollisionCheckCount: number = 0;
  private lastMovementMs: number = 0;
  private lastTargetSearchMs: number = 0;
  private lastCollisionMs: number = 0;
  private lastConversionMs: number = 0;
  private lastResultMs: number = 0;

  constructor(boardWidth: number, boardHeight: number, options: RpsBattleOptions,
    random: () => number = () => Math.random()) {
    this.boardWidth = Math.max(240, boardWidth);
    this.boardHeight = Math.max(240, boardHeight);
    this.options = options;
    this.random = random;
    this.reset();
  }

  reset(): void {
    this.entities = [];
    this.rockEntities = [];
    this.scissorsEntities = [];
    this.paperEntities = [];
    this.factionIndexById = [];
    this.countsCache = rpsBattleEmptyCounts();
    this.nextId = 1;
    this.conversions = 0;
    this.spawnFaction('rock', this.boardWidth * 0.24, this.boardHeight * 0.28);
    this.spawnFaction('scissors', this.boardWidth * 0.76, this.boardHeight * 0.30);
    this.spawnFaction('paper', this.boardWidth * 0.50, this.boardHeight * 0.74);
  }

  resize(boardWidth: number, boardHeight: number): void {
    const nextWidth = Math.max(240, boardWidth);
    const nextHeight = Math.max(240, boardHeight);
    const ratioX = nextWidth / this.boardWidth;
    const ratioY = nextHeight / this.boardHeight;
    this.boardWidth = nextWidth;
    this.boardHeight = nextHeight;
    for (let i = 0; i < this.entities.length; i += 1) {
      const entity = this.entities[i];
      entity.x = this.clamp(entity.x * ratioX, ENTITY_EDGE_PADDING, this.boardWidth - ENTITY_EDGE_PADDING);
      entity.y = this.clamp(entity.y * ratioY, ENTITY_EDGE_PADDING, this.boardHeight - ENTITY_EDGE_PADDING);
    }
  }

  update(dtSec: number, elapsedSec: number): RpsBattleResult {
    this.lastTargetScanCount = 0;
    this.lastCollisionCheckCount = 0;
    this.lastMovementMs = 0;
    this.lastTargetSearchMs = 0;
    this.lastCollisionMs = 0;
    this.lastConversionMs = 0;
    this.lastResultMs = 0;
    const dt = this.clamp(dtSec, 0, 0.05);
    const movementStartedAt = Date.now();
    this.applyMovement(dt, elapsedSec);
    this.lastMovementMs = Date.now() - movementStartedAt;
    const collisionStartedAt = Date.now();
    this.resolveCollisions(elapsedSec);
    this.lastCollisionMs = Date.now() - collisionStartedAt;
    const resultStartedAt = Date.now();
    const result = this.resultAt(elapsedSec);
    this.lastResultMs = Date.now() - resultStartedAt;
    return result;
  }

  entitiesForRender(): RpsBattleEntity[] {
    return this.entities;
  }

  conversionCount(): number {
    return this.conversions;
  }

  entityCount(): number {
    return this.entities.length;
  }

  lastStepTargetScanCount(): number {
    return this.lastTargetScanCount;
  }

  lastStepCollisionCheckCount(): number {
    return this.lastCollisionCheckCount;
  }

  lastStepMovementMs(): number {
    return this.lastMovementMs;
  }

  lastStepTargetSearchMs(): number {
    return this.lastTargetSearchMs;
  }

  lastStepCollisionMs(): number {
    return this.lastCollisionMs;
  }

  lastStepConversionMs(): number {
    return this.lastConversionMs;
  }

  lastStepResultMs(): number {
    return this.lastResultMs;
  }

  counts(): RpsBattleFactionCounts {
    return this.copyCounts();
  }

  timeLeftSec(elapsedSec: number): number {
    return Math.max(0, this.options.durationSec - elapsedSec);
  }

  resultAt(elapsedSec: number): RpsBattleResult {
    const counts = this.copyCounts();
    let result: RpsBattleResult = rpsBattleInitialResult(this.options.supportFaction);
    const aliveCount = (counts.rock > 0 ? 1 : 0) + (counts.scissors > 0 ? 1 : 0) + (counts.paper > 0 ? 1 : 0);
    if (aliveCount <= 1) {
      result = rpsBattleBuildResult(this.options, counts, elapsedSec, this.conversions, 'clear');
    } else if (elapsedSec >= this.options.durationSec) {
      result = rpsBattleBuildResult(this.options, counts, this.options.durationSec, this.conversions, 'time');
    }
    return result;
  }

  snapshot(elapsedSec: number): RpsBattleSnapshot {
    const counts = this.copyCounts();
    return {
      entities: rpsBattleCloneEntities(this.entities),
      counts: counts,
      elapsedSec: Math.min(this.options.durationSec, elapsedSec),
      timeLeftSec: Math.max(0, this.options.durationSec - elapsedSec),
      conversions: this.conversions,
      result: this.resultAt(elapsedSec)
    };
  }

  private spawnFaction(faction: RpsBattleFaction, centerX: number, centerY: number): void {
    const spread = Math.min(this.boardWidth, this.boardHeight) * 0.11;
    for (let i = 0; i < this.options.initialCount; i += 1) {
      const angle = this.random() * Math.PI * 2;
      const distance = spread * (0.25 + this.random() * 0.75);
      const speedAngle = this.random() * Math.PI * 2;
      const speed = 28 + this.random() * 26;
      const entity: RpsBattleEntity = {
        id: this.nextId,
        faction: faction,
        x: this.clamp(centerX + Math.cos(angle) * distance, ENTITY_EDGE_PADDING, this.boardWidth - ENTITY_EDGE_PADDING),
        y: this.clamp(centerY + Math.sin(angle) * distance, ENTITY_EDGE_PADDING, this.boardHeight - ENTITY_EDGE_PADDING),
        vx: Math.cos(speedAngle) * speed,
        vy: Math.sin(speedAngle) * speed,
        radius: ENTITY_RADIUS,
        convertedAt: 0
      };
      this.entities.push(entity);
      this.addToFactionCache(entity);
      this.nextId += 1;
    }
  }

  private applyMovement(dt: number, elapsedSec: number): void {
    for (let i = 0; i < this.entities.length; i += 1) {
      const entity = this.entities[i];
      let ax = 0;
      let ay = 0;
      const targetSearchStartedAt = Date.now();
      const prey = this.nearestEntity(entity, this.entitiesOfFaction(rpsBattlePreyOf(entity.faction)));
      const predator = this.nearestEntity(entity, this.entitiesOfFaction(rpsBattlePredatorOf(entity.faction)));
      this.lastTargetSearchMs += Date.now() - targetSearchStartedAt;
      if (prey !== undefined) {
        const dx = prey.x - entity.x;
        const dy = prey.y - entity.y;
        const distanceSq = dx * dx + dy * dy;
        if (distanceSq < 0.000001) {
          const angle = this.random() * Math.PI * 2;
          ax += Math.cos(angle) * ENTITY_CHASE_ACCEL;
          ay += Math.sin(angle) * ENTITY_CHASE_ACCEL;
        } else {
          const inverseDistance = 1 / Math.sqrt(distanceSq);
          ax += dx * inverseDistance * ENTITY_CHASE_ACCEL;
          ay += dy * inverseDistance * ENTITY_CHASE_ACCEL;
        }
      }
      if (predator !== undefined) {
        const dx = entity.x - predator.x;
        const dy = entity.y - predator.y;
        const distanceSq = dx * dx + dy * dy;
        if (distanceSq < ENTITY_FLEE_DISTANCE_SQ) {
          const distance = Math.sqrt(distanceSq);
          const weight = 1 - distance / ENTITY_FLEE_DISTANCE;
          if (distance < 0.001) {
            const angle = this.random() * Math.PI * 2;
            ax += Math.cos(angle) * ENTITY_FLEE_ACCEL * weight;
            ay += Math.sin(angle) * ENTITY_FLEE_ACCEL * weight;
          } else {
            const inverseDistance = 1 / distance;
            ax += dx * inverseDistance * ENTITY_FLEE_ACCEL * weight;
            ay += dy * inverseDistance * ENTITY_FLEE_ACCEL * weight;
          }
        }
      }
      const wander = elapsedSec * 1.8 + entity.id * 0.73;
      ax += Math.cos(wander) * ENTITY_WANDER_ACCEL;
      ay += Math.sin(wander * 0.83) * ENTITY_WANDER_ACCEL;
      entity.vx += ax * dt;
      entity.vy += ay * dt;
      this.clampVelocity(entity);
      entity.x += entity.vx * dt;
      entity.y += entity.vy * dt;
      this.resolveBounds(entity);
    }
  }

  private resolveCollisions(elapsedSec: number): void {
    const columnCount = Math.max(1, Math.ceil(this.boardWidth / COLLISION_GRID_CELL_SIZE));
    const rowCount = Math.max(1, Math.ceil(this.boardHeight / COLLISION_GRID_CELL_SIZE));
    this.prepareCollisionBuckets(columnCount * rowCount);
    for (let i = 0; i < this.entities.length; i += 1) {
      const entity = this.entities[i];
      const bucketIndex = this.collisionBucketIndex(entity, columnCount, rowCount);
      this.activateCollisionBucket(bucketIndex);
      this.collisionBuckets[bucketIndex].push(entity);
    }
    for (let activeIndex = 0; activeIndex < this.collisionActiveBucketIndices.length; activeIndex += 1) {
      const bucketIndex = this.collisionActiveBucketIndices[activeIndex];
      const row = Math.floor(bucketIndex / columnCount);
      const column = bucketIndex - row * columnCount;
      const bucket = this.collisionBuckets[bucketIndex];
      this.resolveCollisionBucket(bucket, elapsedSec);
      if (column + 1 < columnCount) {
        this.resolveCollisionBucketPair(bucket, this.collisionBuckets[bucketIndex + 1], elapsedSec);
      }
      if (row + 1 < rowCount) {
        const nextRowIndex = bucketIndex + columnCount;
        if (column > 0) {
          this.resolveCollisionBucketPair(bucket, this.collisionBuckets[nextRowIndex - 1], elapsedSec);
        }
        this.resolveCollisionBucketPair(bucket, this.collisionBuckets[nextRowIndex], elapsedSec);
        if (column + 1 < columnCount) {
          this.resolveCollisionBucketPair(bucket, this.collisionBuckets[nextRowIndex + 1], elapsedSec);
        }
      }
    }
  }

  private resolveCollisionBucket(bucket: RpsBattleEntity[], elapsedSec: number): void {
    for (let i = 0; i < bucket.length; i += 1) {
      const a = bucket[i];
      for (let j = i + 1; j < bucket.length; j += 1) {
        this.resolveCollisionPair(a, bucket[j], elapsedSec);
      }
    }
  }

  private resolveCollisionBucketPair(aBucket: RpsBattleEntity[], bBucket: RpsBattleEntity[],
    elapsedSec: number): void {
    for (let i = 0; i < aBucket.length; i += 1) {
      const a = aBucket[i];
      for (let j = 0; j < bBucket.length; j += 1) {
        this.resolveCollisionPair(a, bBucket[j], elapsedSec);
      }
    }
  }

  private resolveCollisionPair(a: RpsBattleEntity, b: RpsBattleEntity, elapsedSec: number): void {
    this.lastCollisionCheckCount += 1;
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const minDistance = a.radius + b.radius;
    const distanceSq = dx * dx + dy * dy;
    if (distanceSq > minDistance * minDistance) {
      return;
    }
    const distance = Math.max(0.01, Math.sqrt(distanceSq));
    const nx = dx / distance;
    const ny = dy / distance;
    const overlap = minDistance - distance;
    a.x -= nx * overlap * 0.5;
    a.y -= ny * overlap * 0.5;
    b.x += nx * overlap * 0.5;
    b.y += ny * overlap * 0.5;
    this.resolveBounds(a);
    this.resolveBounds(b);
    const push = 18;
    a.vx -= nx * push;
    a.vy -= ny * push;
    b.vx += nx * push;
    b.vy += ny * push;
    this.clampVelocity(a);
    this.clampVelocity(b);
    this.resolveConversion(a, b, elapsedSec);
  }

  private resolveConversion(a: RpsBattleEntity, b: RpsBattleEntity, elapsedSec: number): void {
    if (a.faction === b.faction) {
      return;
    }
    if (rpsBattleBeats(a.faction, b.faction)) {
      this.convertEntity(b, a.faction, elapsedSec);
    } else if (rpsBattleBeats(b.faction, a.faction)) {
      this.convertEntity(a, b.faction, elapsedSec);
    }
  }

  private convertEntity(entity: RpsBattleEntity, faction: RpsBattleFaction, elapsedSec: number): void {
    const previousFaction = entity.faction;
    if (previousFaction === faction) {
      return;
    }
    const startedAt = Date.now();
    this.removeFromFactionCache(entity, previousFaction);
    entity.faction = faction;
    this.addToFactionCache(entity);
    entity.convertedAt = elapsedSec;
    entity.vx += (this.random() - 0.5) * 54;
    entity.vy += (this.random() - 0.5) * 54;
    this.clampVelocity(entity);
    this.conversions += 1;
    this.lastConversionMs += Date.now() - startedAt;
  }

  private nearestEntity(source: RpsBattleEntity, candidates: RpsBattleEntity[]): RpsBattleEntity | undefined {
    let nearest: RpsBattleEntity | undefined = undefined;
    let bestDistanceSq = Number.MAX_VALUE;
    const sourceX = source.x;
    const sourceY = source.y;
    this.lastTargetScanCount += candidates.length;
    for (let i = 0; i < candidates.length; i += 1) {
      const item = candidates[i];
      const dx = item.x - sourceX;
      const dy = item.y - sourceY;
      const distanceSq = dx * dx + dy * dy;
      if (distanceSq < bestDistanceSq) {
        bestDistanceSq = distanceSq;
        nearest = item;
      }
    }
    return nearest;
  }

  private entitiesOfFaction(faction: RpsBattleFaction): RpsBattleEntity[] {
    if (faction === 'rock') {
      return this.rockEntities;
    }
    if (faction === 'scissors') {
      return this.scissorsEntities;
    }
    return this.paperEntities;
  }

  private addToFactionCache(entity: RpsBattleEntity): void {
    const entities = this.entitiesOfFaction(entity.faction);
    this.factionIndexById[entity.id] = entities.length;
    entities.push(entity);
    this.addCount(entity.faction, 1);
  }

  private removeFromFactionCache(entity: RpsBattleEntity, faction: RpsBattleFaction): void {
    const entities = this.entitiesOfFaction(faction);
    const cachedIndex = this.factionIndexById[entity.id];
    if (cachedIndex !== undefined && cachedIndex >= 0 && cachedIndex < entities.length &&
      entities[cachedIndex].id === entity.id) {
      const lastIndex = entities.length - 1;
      const lastEntity = entities[lastIndex];
      if (cachedIndex !== lastIndex) {
        entities[cachedIndex] = lastEntity;
        this.factionIndexById[lastEntity.id] = cachedIndex;
      }
      entities.pop();
      this.factionIndexById[entity.id] = -1;
      this.addCount(faction, -1);
      return;
    }
    for (let i = 0; i < entities.length; i += 1) {
      if (entities[i].id === entity.id) {
        entities.splice(i, 1);
        this.factionIndexById[entity.id] = -1;
        this.addCount(faction, -1);
        return;
      }
    }
  }

  private addCount(faction: RpsBattleFaction, delta: number): void {
    if (faction === 'rock') {
      this.countsCache.rock += delta;
    } else if (faction === 'scissors') {
      this.countsCache.scissors += delta;
    } else {
      this.countsCache.paper += delta;
    }
  }

  private copyCounts(): RpsBattleFactionCounts {
    return {
      rock: this.countsCache.rock,
      scissors: this.countsCache.scissors,
      paper: this.countsCache.paper
    };
  }

  private prepareEntityBuckets(buckets: RpsBattleEntity[][], bucketCount: number): void {
    if (buckets.length !== bucketCount) {
      buckets.length = 0;
      for (let i = 0; i < bucketCount; i += 1) {
        buckets.push([]);
      }
      return;
    }
    for (let i = 0; i < buckets.length; i += 1) {
      buckets[i].length = 0;
    }
  }

  private prepareCollisionBuckets(bucketCount: number): void {
    if (this.collisionBuckets.length !== bucketCount) {
      this.prepareEntityBuckets(this.collisionBuckets, bucketCount);
      this.collisionBucketMarks = [];
      this.collisionBucketMarks.length = bucketCount;
      this.collisionActiveBucketIndices = [];
      this.collisionBucketVersion = 1;
      return;
    }
    for (let i = 0; i < this.collisionActiveBucketIndices.length; i += 1) {
      this.collisionBuckets[this.collisionActiveBucketIndices[i]].length = 0;
    }
    this.collisionActiveBucketIndices.length = 0;
    this.collisionBucketVersion += 1;
    if (this.collisionBucketVersion > 1000000000) {
      for (let i = 0; i < this.collisionBucketMarks.length; i += 1) {
        this.collisionBucketMarks[i] = 0;
      }
      this.collisionBucketVersion = 1;
    }
  }

  private activateCollisionBucket(bucketIndex: number): void {
    if (this.collisionBucketMarks[bucketIndex] === this.collisionBucketVersion) {
      return;
    }
    this.collisionBucketMarks[bucketIndex] = this.collisionBucketVersion;
    this.collisionActiveBucketIndices.push(bucketIndex);
  }

  private collisionBucketIndex(entity: RpsBattleEntity, columnCount: number, rowCount: number): number {
    const column = Math.max(0, Math.min(columnCount - 1, Math.floor(entity.x / COLLISION_GRID_CELL_SIZE)));
    const row = Math.max(0, Math.min(rowCount - 1, Math.floor(entity.y / COLLISION_GRID_CELL_SIZE)));
    return row * columnCount + column;
  }

  private resolveBounds(entity: RpsBattleEntity): void {
    if (entity.x < entity.radius) {
      entity.x = entity.radius;
      entity.vx = Math.abs(entity.vx) * 0.86;
    } else if (entity.x > this.boardWidth - entity.radius) {
      entity.x = this.boardWidth - entity.radius;
      entity.vx = -Math.abs(entity.vx) * 0.86;
    }
    if (entity.y < entity.radius) {
      entity.y = entity.radius;
      entity.vy = Math.abs(entity.vy) * 0.86;
    } else if (entity.y > this.boardHeight - entity.radius) {
      entity.y = this.boardHeight - entity.radius;
      entity.vy = -Math.abs(entity.vy) * 0.86;
    }
  }

  private clampVelocity(entity: RpsBattleEntity): void {
    const speed = Math.sqrt(entity.vx * entity.vx + entity.vy * entity.vy);
    if (speed <= ENTITY_MAX_SPEED || speed <= 0) {
      return;
    }
    const ratio = ENTITY_MAX_SPEED / speed;
    entity.vx *= ratio;
    entity.vy *= ratio;
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
  }
}
