import {
  RPS_BATTLE_MAX_TOTAL_ENTITIES,
  RpsBattleBlackHoleState,
  RpsBattleControlZone,
  RpsBattleEntity,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleLastStandState,
  RpsBattleModeRules,
  RpsBattleObstacleState,
  RpsBattleOptions,
  RpsBattlePowerUpKind,
  RpsBattlePowerUpPickup,
  RpsBattlePowerUpState,
  RpsBattleResult,
  RpsBattleShrinkBounds,
  RpsBattleShrinkState,
  RpsBattleSpawnRequest,
  RpsBattleSnapState,
  RpsBattleSnapshot,
  RpsBattleTraitorConversion,
  RpsBattleTraitorState
} from './RpsBattleTypes';
import { rpsBattleResolveModeRulesByKey } from './RpsBattleModeConfig';
import {
  rpsBattleBeats,
  rpsBattleBuildResult,
  rpsBattleCloneEntities,
  rpsBattleEmptyCounts,
  rpsBattleInitialResult,
  rpsBattlePredatorOf,
  rpsBattlePreyOf
} from './RpsBattleRules';
import {
  RPS_BATTLE_BLACK_HOLE_TRAITOR_MAX_DELAY_SEC,
  RPS_BATTLE_BLACK_HOLE_TRAITOR_MIN_DELAY_SEC,
  RpsBattleBlackHoleSystem
} from './RpsBattleBlackHoleSystem';
import { RpsBattleLastStandSystem } from './RpsBattleLastStandSystem';
import { RpsBattleObstacleSystem } from './RpsBattleObstacleSystem';
import { RpsBattlePowerUpSystem } from './RpsBattlePowerUpSystem';
import { RpsBattleShrinkSystem } from './RpsBattleShrinkSystem';
import { RpsBattleSnapSystem } from './RpsBattleSnapSystem';
import {
  RPS_BATTLE_TRAITOR_RAGE_DURATION_SEC,
  RpsBattleTraitorSystem
} from './RpsBattleTraitorSystem';
import { RpsBattleZoneSystem } from './RpsBattleZoneSystem';

const ENTITY_RADIUS: number = 14;
const ENTITY_MAX_SPEED: number = 94;
const ENTITY_CHASE_ACCEL: number = 118;
const ENTITY_FLEE_ACCEL: number = 72;
const ENTITY_WANDER_ACCEL: number = 22;
const ENTITY_FLEE_DISTANCE: number = 92;
const ENTITY_FLEE_DISTANCE_SQ: number = ENTITY_FLEE_DISTANCE * ENTITY_FLEE_DISTANCE;
const ENTITY_EDGE_PADDING: number = 18;
const COLLISION_GRID_CELL_SIZE: number = ENTITY_RADIUS * 3;
const ENTITY_SPEED_BOOST_DURATION_SEC: number = 6;
const ENTITY_SPEED_BOOST_NUDGE: number = 1.22;
const ENTITY_SPEED_BOOST_LIMIT_MULTIPLIER: number = 1.25;
const ENTITY_TRAITOR_RAGE_NUDGE: number = 1.18;
const ENTITY_TRAITOR_RAGE_LIMIT_MULTIPLIER: number = 1.22;
const ENTITY_SPLIT_OFFSET: number = 18;
const ENTITY_SPLIT_RADIUS_SCALE: number = 0.86;
const RPS_BATTLE_TEAM_SPLIT_MAX_PER_PICKUP: number = 8;
const RPS_BATTLE_REINFORCEMENT_RESERVE: number = 3;
const RPS_BATTLE_REVIVE_BLACK_HOLE_SAFE_PADDING: number = ENTITY_RADIUS * 2.5;
const RPS_BATTLE_ZONE_CONTESTER_ACCEL: number = 58;
const RPS_BATTLE_ZONE_GUARD_ACCEL: number = 42;
const RPS_BATTLE_ZONE_SUPPORT_ACCEL: number = 24;
const RPS_BATTLE_ZONE_PREDATOR_PRESSURE_SCALE: number = 0.32;
const RPS_BATTLE_ZONE_INSIDE_OWNER_SCALE: number = 0.35;
const RPS_BATTLE_ZONE_OPENING_RUSH_SEC: number = 4;
const RPS_BATTLE_ZONE_OPENING_ACCEL_SCALE: number = 1.32;

interface RpsBattleSpawnPoint {
  x: number;
  y: number;
}

export class RpsBattleEngine {
  private boardWidth: number;
  private boardHeight: number;
  private options: RpsBattleOptions;
  private modeRules: RpsBattleModeRules;
  private random: () => number;
  private entities: RpsBattleEntity[] = [];
  private zoneSystem: RpsBattleZoneSystem = new RpsBattleZoneSystem();
  private blackHoleSystem: RpsBattleBlackHoleSystem = new RpsBattleBlackHoleSystem();
  private lastStandSystem: RpsBattleLastStandSystem = new RpsBattleLastStandSystem();
  private powerUpSystem: RpsBattlePowerUpSystem = new RpsBattlePowerUpSystem();
  private shrinkSystem: RpsBattleShrinkSystem = new RpsBattleShrinkSystem();
  private traitorSystem: RpsBattleTraitorSystem = new RpsBattleTraitorSystem();
  private snapSystem: RpsBattleSnapSystem = new RpsBattleSnapSystem();
  private obstacleSystem: RpsBattleObstacleSystem = new RpsBattleObstacleSystem();
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
  private lastZoneMs: number = 0;
  private lastZoneInsideCount: number = 0;
  private lastBlackHoleMs: number = 0;
  private lastBlackHoleKillCount: number = 0;
  private lastLastStandMs: number = 0;
  private lastLastStandEventCount: number = 0;
  private lastLastStandReviveCount: number = 0;
  private lastPowerUpMs: number = 0;
  private lastPowerUpPickupCount: number = 0;
  private lastPowerUpTeamEffectCount: number = 0;
  private lastPowerUpActiveCount: number = 0;
  private lastShrinkMs: number = 0;
  private lastShrinkPadding: number = 0;
  private lastTraitorMs: number = 0;
  private lastTraitorMarkCount: number = 0;
  private lastTraitorConversionCount: number = 0;
  private lastSnapMs: number = 0;
  private lastSnapRemovedCount: number = 0;
  private lastObstacleMs: number = 0;
  private lastObstacleHitCount: number = 0;

  constructor(boardWidth: number, boardHeight: number, options: RpsBattleOptions,
    random: () => number = () => Math.random()) {
    this.boardWidth = Math.max(240, boardWidth);
    this.boardHeight = Math.max(240, boardHeight);
    this.options = options;
    this.modeRules = rpsBattleResolveModeRulesByKey(options.modeKey, options.mechanics);
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
    if (this.modeRules.hasControlZone) {
      this.zoneSystem.reset(this.boardWidth, this.boardHeight);
    } else {
      this.zoneSystem.clear();
    }
    if (this.modeRules.hasBlackHole) {
      if (this.modeRules.hasTraitor) {
        this.blackHoleSystem.reset(this.boardWidth, this.boardHeight, this.random,
          RPS_BATTLE_BLACK_HOLE_TRAITOR_MIN_DELAY_SEC, RPS_BATTLE_BLACK_HOLE_TRAITOR_MAX_DELAY_SEC);
      } else {
        this.blackHoleSystem.reset(this.boardWidth, this.boardHeight, this.random);
      }
    } else {
      this.blackHoleSystem.clear();
    }
    if (this.modeRules.hasPowerUps) {
      this.powerUpSystem.reset(0);
    } else {
      this.powerUpSystem.clear();
    }
    if (this.modeRules.hasShrink) {
      this.shrinkSystem.reset(this.boardWidth, this.boardHeight);
    } else {
      this.shrinkSystem.clear();
    }
    if (this.modeRules.hasTraitor) {
      this.traitorSystem.reset();
    } else {
      this.traitorSystem.clear();
    }
    if (this.modeRules.hasSnap) {
      this.snapSystem.reset(this.random);
    } else {
      this.snapSystem.clear();
    }
    if (this.modeRules.hasObstacles) {
      this.obstacleSystem.reset(this.boardWidth, this.boardHeight, this.random);
    } else {
      this.obstacleSystem.clear();
    }
    this.spawnFaction('rock', this.options.initialCounts.rock, this.boardWidth * 0.24, this.boardHeight * 0.28);
    this.spawnFaction('scissors', this.options.initialCounts.scissors, this.boardWidth * 0.76, this.boardHeight * 0.30);
    this.spawnFaction('paper', this.options.initialCounts.paper, this.boardWidth * 0.50, this.boardHeight * 0.74);
    if (this.modeRules.hasLastStand) {
      this.lastStandSystem.reset(this.entities, this.copyCounts(), this.boardWidth, this.boardHeight);
    } else {
      this.lastStandSystem.clear();
    }
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
    if (this.modeRules.hasControlZone) {
      this.zoneSystem.resize(this.boardWidth, this.boardHeight);
    }
    if (this.modeRules.hasBlackHole) {
      this.blackHoleSystem.resize(this.boardWidth, this.boardHeight);
    }
    if (this.modeRules.hasLastStand) {
      this.lastStandSystem.resize(ratioX, ratioY, this.boardWidth, this.boardHeight);
    }
    if (this.modeRules.hasPowerUps) {
      this.powerUpSystem.resize(ratioX, ratioY, this.boardWidth, this.boardHeight);
    }
    if (this.modeRules.hasShrink) {
      this.shrinkSystem.resize(this.boardWidth, this.boardHeight);
    }
    if (this.modeRules.hasTraitor) {
      this.traitorSystem.resize(ratioX, ratioY);
    }
    if (this.modeRules.hasObstacles) {
      this.obstacleSystem.resize(ratioX, ratioY, this.boardWidth, this.boardHeight);
    }
    for (let i = 0; i < this.entities.length; i += 1) {
      this.resolveBounds(this.entities[i]);
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
    this.lastZoneMs = 0;
    this.lastZoneInsideCount = 0;
    this.lastBlackHoleMs = 0;
    this.lastBlackHoleKillCount = 0;
    this.lastLastStandMs = 0;
    this.lastLastStandEventCount = 0;
    this.lastLastStandReviveCount = 0;
    this.lastPowerUpMs = 0;
    this.lastPowerUpPickupCount = 0;
    this.lastPowerUpTeamEffectCount = 0;
    this.lastPowerUpActiveCount = 0;
    this.lastShrinkMs = 0;
    this.lastShrinkPadding = 0;
    this.lastTraitorMs = 0;
    this.lastTraitorMarkCount = 0;
    this.lastTraitorConversionCount = 0;
    this.lastSnapMs = 0;
    this.lastSnapRemovedCount = 0;
    this.lastObstacleMs = 0;
    this.lastObstacleHitCount = 0;
    const dt = this.clamp(dtSec, 0, 0.05);
    if (this.modeRules.hasPowerUps) {
      const powerUpStartedAt = Date.now();
      this.powerUpSystem.updateSpawnAndExpire(true, elapsedSec, this.boardWidth, this.boardHeight, this.random);
      this.lastPowerUpMs += Date.now() - powerUpStartedAt;
    }
    if (this.modeRules.hasShrink) {
      const shrinkStartedAt = Date.now();
      this.shrinkSystem.update(elapsedSec, dt, this.boardWidth, this.boardHeight);
      const shrink = this.shrinkSystem.snapshot();
      this.lastShrinkPadding = shrink === null ? 0 : shrink.padding;
      this.lastShrinkMs = Date.now() - shrinkStartedAt;
    }
    if (this.modeRules.hasTraitor) {
      const traitorStartedAt = Date.now();
      const traitorConversions = this.traitorSystem.update(this.entities, this.copyCounts(), elapsedSec, this.random);
      this.applyTraitorConversions(traitorConversions, elapsedSec);
      this.lastTraitorMarkCount = this.traitorSystem.lastFrameMarkCount();
      this.lastTraitorConversionCount = this.traitorSystem.lastFrameConversionCount();
      this.lastTraitorMs += Date.now() - traitorStartedAt;
    }
    if (this.modeRules.hasSnap && this.aliveFactionCount() > 1) {
      const snapStartedAt = Date.now();
      const removedIds = this.snapSystem.update(this.rockEntities, this.scissorsEntities, this.paperEntities,
        elapsedSec, this.random);
      this.removeEntitiesById(removedIds);
      this.lastSnapRemovedCount = removedIds.length;
      this.lastSnapMs = Date.now() - snapStartedAt;
    }
    const movementStartedAt = Date.now();
    this.applyMovement(dt, elapsedSec);
    this.lastMovementMs = Date.now() - movementStartedAt;
    if (this.modeRules.hasObstacles) {
      const obstacleStartedAt = Date.now();
      for (let i = 0; i < this.entities.length; i += 1) {
        const entity = this.entities[i];
        this.lastObstacleHitCount += this.obstacleSystem.resolveEntity(entity);
        this.resolveBounds(entity);
      }
      this.lastObstacleMs = Date.now() - obstacleStartedAt;
    }
    if (this.modeRules.hasPowerUps) {
      const powerUpStartedAt = Date.now();
      const pickups = this.powerUpSystem.collect(this.entities, elapsedSec, this.modeRules.hasTeamPowerUps);
      this.applyPowerUpPickups(pickups, elapsedSec);
      this.lastPowerUpPickupCount = this.powerUpSystem.lastFramePickedCount();
      this.lastPowerUpTeamEffectCount = this.powerUpSystem.lastFrameTeamEffectCount();
      this.lastPowerUpActiveCount = this.powerUpSystem.activeCount();
      this.lastPowerUpMs += Date.now() - powerUpStartedAt;
    }
    if (this.modeRules.hasBlackHole) {
      const blackHoleStartedAt = Date.now();
      const zone = this.zoneSystem.currentZone();
      const shrinkBounds = this.modeRules.hasShrink ?
        this.shrinkSystem.currentBounds(this.boardWidth, this.boardHeight) : null;
      const swallowed = this.blackHoleSystem.update(this.entities, elapsedSec, dt, this.boardWidth, this.boardHeight,
        this.random, zone === null ? -1 : zone.x, zone === null ? -1 : zone.y, zone === null ? 0 : zone.radius,
        shrinkBounds);
      this.removeSwallowedEntities(swallowed);
      this.lastBlackHoleKillCount = swallowed.length;
      this.lastBlackHoleMs = Date.now() - blackHoleStartedAt;
    }
    const collisionStartedAt = Date.now();
    this.resolveCollisions(elapsedSec);
    this.lastCollisionMs = Date.now() - collisionStartedAt;
    if (this.modeRules.hasControlZone) {
      const zoneStartedAt = Date.now();
      this.lastZoneInsideCount = this.zoneSystem.update(this.entities, dt);
      this.lastZoneMs = Date.now() - zoneStartedAt;
    }
    if (this.modeRules.hasLastStand) {
      const lastStandStartedAt = Date.now();
      const spawnRequests = this.lastStandSystem.update(this.entities, this.copyCounts(), elapsedSec, this.boardWidth,
        this.boardHeight, this.random);
      this.applyLastStandSpawnRequests(spawnRequests, elapsedSec);
      this.lastStandSystem.completeFrame(this.entities, this.copyCounts());
      this.lastLastStandEventCount = this.lastStandSystem.lastFrameEventCount();
      this.lastLastStandReviveCount = this.lastStandSystem.lastFrameReviveCount();
      this.lastLastStandMs = Date.now() - lastStandStartedAt;
    }
    if (this.modeRules.hasTraitor) {
      const traitorStartedAt = Date.now();
      this.ensureTraitorClearProtection(elapsedSec);
      this.lastTraitorMarkCount = this.traitorSystem.lastFrameMarkCount();
      this.lastTraitorConversionCount = this.traitorSystem.lastFrameConversionCount();
      this.lastTraitorMs += Date.now() - traitorStartedAt;
    }
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

  lastStepZoneMs(): number {
    return this.lastZoneMs;
  }

  lastStepZoneInsideCount(): number {
    return this.lastZoneInsideCount;
  }

  lastStepBlackHoleMs(): number {
    return this.lastBlackHoleMs;
  }

  lastStepBlackHoleKillCount(): number {
    return this.lastBlackHoleKillCount;
  }

  lastStepLastStandMs(): number {
    return this.lastLastStandMs;
  }

  lastStepLastStandEventCount(): number {
    return this.lastLastStandEventCount;
  }

  lastStepLastStandReviveCount(): number {
    return this.lastLastStandReviveCount;
  }

  lastStepPowerUpMs(): number {
    return this.lastPowerUpMs;
  }

  lastStepPowerUpPickupCount(): number {
    return this.lastPowerUpPickupCount;
  }

  lastStepPowerUpTeamEffectCount(): number {
    return this.lastPowerUpTeamEffectCount;
  }

  lastStepPowerUpActiveCount(): number {
    return this.lastPowerUpActiveCount;
  }

  lastStepShrinkMs(): number {
    return this.lastShrinkMs;
  }

  lastStepShrinkPadding(): number {
    return this.lastShrinkPadding;
  }

  lastStepTraitorMs(): number {
    return this.lastTraitorMs;
  }

  lastStepTraitorMarkCount(): number {
    return this.lastTraitorMarkCount;
  }

  lastStepTraitorConversionCount(): number {
    return this.lastTraitorConversionCount;
  }

  lastStepSnapMs(): number {
    return this.lastSnapMs;
  }

  lastStepSnapRemovedCount(): number {
    return this.lastSnapRemovedCount;
  }

  lastStepObstacleMs(): number {
    return this.lastObstacleMs;
  }

  lastStepObstacleHitCount(): number {
    return this.lastObstacleHitCount;
  }

  counts(): RpsBattleFactionCounts {
    return this.copyCounts();
  }

  controlZoneForRender(): RpsBattleControlZone | null {
    return this.zoneSystem.currentZone();
  }

  controlZoneSnapshot(): RpsBattleControlZone | null {
    return this.zoneSystem.snapshot();
  }

  blackHoleForRender(): RpsBattleBlackHoleState | null {
    return this.blackHoleSystem.currentState();
  }

  blackHoleSnapshot(): RpsBattleBlackHoleState | null {
    return this.blackHoleSystem.snapshot();
  }

  lastStandForRender(): RpsBattleLastStandState | null {
    return this.lastStandSystem.snapshot();
  }

  lastStandSnapshot(): RpsBattleLastStandState | null {
    return this.lastStandSystem.snapshot();
  }

  powerUpsForRender(): RpsBattlePowerUpState | null {
    return this.powerUpSystem.snapshot();
  }

  powerUpsSnapshot(): RpsBattlePowerUpState | null {
    return this.powerUpSystem.snapshot();
  }

  shrinkForRender(): RpsBattleShrinkState | null {
    return this.shrinkSystem.snapshot();
  }

  shrinkSnapshot(): RpsBattleShrinkState | null {
    return this.shrinkSystem.snapshot();
  }

  traitorForRender(): RpsBattleTraitorState | null {
    return this.traitorSystem.snapshot();
  }

  traitorSnapshot(): RpsBattleTraitorState | null {
    return this.traitorSystem.snapshot();
  }

  snapForRender(): RpsBattleSnapState | null {
    return this.snapSystem.currentState();
  }

  snapSnapshot(): RpsBattleSnapState | null {
    return this.snapSystem.snapshot();
  }

  obstaclesForRender(): RpsBattleObstacleState | null {
    return this.obstacleSystem.currentState();
  }

  obstaclesSnapshot(): RpsBattleObstacleState | null {
    return this.obstacleSystem.snapshot();
  }

  isDeathmatch(): boolean {
    return this.modeRules.hasDeathmatch;
  }

  timeLeftSec(elapsedSec: number): number {
    return Math.max(0, this.options.durationSec - elapsedSec);
  }

  resultAt(elapsedSec: number): RpsBattleResult {
    const counts = this.copyCounts();
    let result: RpsBattleResult = rpsBattleInitialResult(this.options.supportFaction);
    const aliveCount = (counts.rock > 0 ? 1 : 0) + (counts.scissors > 0 ? 1 : 0) + (counts.paper > 0 ? 1 : 0);
    if (this.modeRules.hasControlZone) {
      const zoneWinner = this.zoneSystem.finishWinner();
      if (zoneWinner !== '') {
        result = rpsBattleBuildResult(this.options, counts, elapsedSec, this.conversions, 'zone', zoneWinner);
      } else if (elapsedSec >= this.options.durationSec) {
        result = rpsBattleBuildResult(
          this.options,
          counts,
          this.options.durationSec,
          this.conversions,
          'time',
          this.zoneSystem.timeWinner(),
          true
        );
      }
    } else if (aliveCount <= 1 && !this.waitingForLastStandRevive() && !this.waitingForTraitorResolution()) {
      result = rpsBattleBuildResult(this.options, counts, elapsedSec, this.conversions, 'clear');
    } else if (!this.modeRules.hasDeathmatch && elapsedSec >= this.options.durationSec) {
      result = rpsBattleBuildResult(this.options, counts, this.options.durationSec, this.conversions, 'time');
    }
    return result;
  }

  snapshot(elapsedSec: number): RpsBattleSnapshot {
    const counts = this.copyCounts();
    return {
      entities: rpsBattleCloneEntities(this.entities),
      counts: counts,
      controlZone: this.zoneSystem.snapshot(),
      blackHole: this.blackHoleSystem.snapshot(),
      lastStand: this.lastStandSystem.snapshot(),
      powerUps: this.powerUpSystem.snapshot(),
      shrink: this.shrinkSystem.snapshot(),
      traitor: this.traitorSystem.snapshot(),
      snap: this.snapSystem.snapshot(),
      obstacles: this.obstacleSystem.snapshot(),
      elapsedSec: Math.min(this.options.durationSec, elapsedSec),
      timeLeftSec: Math.max(0, this.options.durationSec - elapsedSec),
      conversions: this.conversions,
      result: this.resultAt(elapsedSec)
    };
  }

  private spawnFaction(faction: RpsBattleFaction, count: number, centerX: number, centerY: number): void {
    const spread = Math.min(this.boardWidth, this.boardHeight) * 0.11;
    for (let i = 0; i < count; i += 1) {
      const angle = this.random() * Math.PI * 2;
      const distance = spread * (0.25 + this.random() * 0.75);
      this.spawnEntity(
        faction,
        centerX + Math.cos(angle) * distance,
        centerY + Math.sin(angle) * distance,
        1,
        1,
        0
      );
    }
  }

  private spawnEntity(faction: RpsBattleFaction, x: number, y: number, speedScale: number, radiusScale: number,
    convertedAtSec: number): RpsBattleEntity {
    const speedAngle = this.random() * Math.PI * 2;
    const speed = (28 + this.random() * 26) * speedScale;
    const entity: RpsBattleEntity = {
      id: this.nextId,
      faction: faction,
      x: this.clamp(x, ENTITY_EDGE_PADDING, this.boardWidth - ENTITY_EDGE_PADDING),
      y: this.clamp(y, ENTITY_EDGE_PADDING, this.boardHeight - ENTITY_EDGE_PADDING),
      vx: Math.cos(speedAngle) * speed,
      vy: Math.sin(speedAngle) * speed,
      radius: ENTITY_RADIUS * radiusScale,
      shield: 0,
      speedBoostUntilSec: 0,
      traitorRageUntilSec: 0,
      convertedAt: convertedAtSec
    };
    this.entities.push(entity);
    this.addToFactionCache(entity);
    this.nextId += 1;
    return entity;
  }

  private applyMovement(dt: number, elapsedSec: number): void {
    const zone = this.modeRules.hasControlZone ? this.zoneSystem.currentZone() : null;
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
      if (zone !== null) {
        const zoneAccel = this.zoneIntentAccel(entity, predator, zone, elapsedSec);
        if (zoneAccel > 0) {
          const dx = zone.x - entity.x;
          const dy = zone.y - entity.y;
          const distanceSq = dx * dx + dy * dy;
          if (distanceSq < 0.000001) {
            const angle = entity.id * 1.37;
            ax += Math.cos(angle) * zoneAccel;
            ay += Math.sin(angle) * zoneAccel;
          } else {
            const inverseDistance = 1 / Math.sqrt(distanceSq);
            ax += dx * inverseDistance * zoneAccel;
            ay += dy * inverseDistance * zoneAccel;
          }
        }
      }
      const wander = elapsedSec * 1.8 + entity.id * 0.73;
      ax += Math.cos(wander) * ENTITY_WANDER_ACCEL;
      ay += Math.sin(wander * 0.83) * ENTITY_WANDER_ACCEL;
      entity.vx += ax * dt;
      entity.vy += ay * dt;
      this.clampVelocity(entity, elapsedSec);
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
    this.clampVelocity(a, elapsedSec);
    this.clampVelocity(b, elapsedSec);
    this.resolveConversion(a, b, elapsedSec);
  }

  private resolveConversion(a: RpsBattleEntity, b: RpsBattleEntity, elapsedSec: number): void {
    if (a.faction === b.faction) {
      return;
    }
    if (rpsBattleBeats(a.faction, b.faction)) {
      if (this.consumeShield(b)) {
        return;
      }
      this.convertEntity(b, a.faction, elapsedSec);
    } else if (rpsBattleBeats(b.faction, a.faction)) {
      if (this.consumeShield(a)) {
        return;
      }
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
    this.clampVelocity(entity, elapsedSec);
    this.conversions += 1;
    this.lastConversionMs += Date.now() - startedAt;
  }

  private removeSwallowedEntities(swallowed: RpsBattleEntity[]): void {
    if (swallowed.length === 0) {
      return;
    }
    for (let i = 0; i < swallowed.length; i += 1) {
      this.removeEntity(swallowed[i]);
    }
  }

  private removeEntitiesById(entityIds: number[]): void {
    for (let i = 0; i < entityIds.length; i += 1) {
      const entity = this.findEntityById(entityIds[i]);
      if (entity !== null) {
        this.removeEntity(entity);
      }
    }
  }

  private applyTraitorConversions(conversions: RpsBattleTraitorConversion[], elapsedSec: number): void {
    for (let i = 0; i < conversions.length; i += 1) {
      const conversion = conversions[i];
      const entity = this.findEntityById(conversion.entityId);
      if (entity === null) {
        continue;
      }
      this.convertEntity(entity, conversion.toFaction, elapsedSec);
      entity.traitorRageUntilSec = Math.max(entity.traitorRageUntilSec,
        elapsedSec + RPS_BATTLE_TRAITOR_RAGE_DURATION_SEC);
      entity.vx *= ENTITY_TRAITOR_RAGE_NUDGE;
      entity.vy *= ENTITY_TRAITOR_RAGE_NUDGE;
      this.clampVelocity(entity, elapsedSec);
    }
  }

  private ensureTraitorClearProtection(elapsedSec: number): void {
    const counts = this.copyCounts();
    const aliveCount = (counts.rock > 0 ? 1 : 0) + (counts.scissors > 0 ? 1 : 0) + (counts.paper > 0 ? 1 : 0);
    if (aliveCount !== 1) {
      return;
    }
    this.traitorSystem.tryQueueClearRescue(this.entities, counts, elapsedSec, this.random);
  }

  private applyPowerUpPickups(pickups: RpsBattlePowerUpPickup[], elapsedSec: number): void {
    for (let i = 0; i < pickups.length; i += 1) {
      const pickup = pickups[i];
      if (pickup.isTeam) {
        this.applyTeamPowerUp(pickup.faction, pickup.kind, elapsedSec);
        continue;
      }
      const collector = this.findEntityById(pickup.collectorId);
      if (collector !== null) {
        this.applyPowerUpToEntity(collector, pickup.kind, elapsedSec);
      }
    }
  }

  private applyTeamPowerUp(faction: RpsBattleFaction, kind: RpsBattlePowerUpKind, elapsedSec: number): void {
    const members = this.entitiesOfFaction(faction);
    if (kind === 'split') {
      const spawnCount = Math.min(
        members.length,
        Math.max(0, RPS_BATTLE_MAX_TOTAL_ENTITIES - this.entities.length),
        RPS_BATTLE_TEAM_SPLIT_MAX_PER_PICKUP
      );
      for (let i = 0; i < spawnCount; i += 1) {
        this.spawnSplitFromEntity(members[i], elapsedSec);
      }
      return;
    }
    for (let i = 0; i < members.length; i += 1) {
      this.applyPowerUpToEntity(members[i], kind, elapsedSec);
    }
  }

  private applyPowerUpToEntity(entity: RpsBattleEntity, kind: RpsBattlePowerUpKind, elapsedSec: number): void {
    if (kind === 'speed') {
      entity.speedBoostUntilSec = Math.max(entity.speedBoostUntilSec, elapsedSec + ENTITY_SPEED_BOOST_DURATION_SEC);
      entity.vx *= ENTITY_SPEED_BOOST_NUDGE;
      entity.vy *= ENTITY_SPEED_BOOST_NUDGE;
      this.clampVelocity(entity, elapsedSec);
      return;
    }
    if (kind === 'shield') {
      entity.shield = Math.max(entity.shield, 1);
      return;
    }
    if (this.entities.length >= RPS_BATTLE_MAX_TOTAL_ENTITIES) {
      return;
    }
    this.spawnSplitFromEntity(entity, elapsedSec);
  }

  private spawnSplitFromEntity(entity: RpsBattleEntity, elapsedSec: number): void {
    const x = entity.x + (this.random() * 2 - 1) * ENTITY_SPLIT_OFFSET;
    const y = entity.y + (this.random() * 2 - 1) * ENTITY_SPLIT_OFFSET;
    this.spawnEntity(entity.faction, x, y, 1, ENTITY_SPLIT_RADIUS_SCALE, elapsedSec);
  }

  private applyLastStandSpawnRequests(requests: RpsBattleSpawnRequest[], elapsedSec: number): void {
    for (let i = 0; i < requests.length; i += 1) {
      const request = requests[i];
      const maxEntities = request.eventKind === 'revive' ?
        RPS_BATTLE_MAX_TOTAL_ENTITIES + RPS_BATTLE_REINFORCEMENT_RESERVE :
        RPS_BATTLE_MAX_TOTAL_ENTITIES;
      if (this.entities.length >= maxEntities) {
        continue;
      }
      let spawnPoint: RpsBattleSpawnPoint = {
        x: request.x,
        y: request.y
      };
      if (request.eventKind === 'revive') {
        spawnPoint = this.resolveSafeReviveSpawnPoint(request);
      }
      this.spawnEntity(request.faction, spawnPoint.x, spawnPoint.y, request.speedScale, 1, elapsedSec);
    }
  }

  private resolveSafeReviveSpawnPoint(request: RpsBattleSpawnRequest): RpsBattleSpawnPoint {
    const x = this.clamp(request.x, ENTITY_EDGE_PADDING, this.boardWidth - ENTITY_EDGE_PADDING);
    const y = this.clamp(request.y, ENTITY_EDGE_PADDING, this.boardHeight - ENTITY_EDGE_PADDING);
    const blackHole = this.blackHoleSystem.currentState();
    if (blackHole === null || !blackHole.active) {
      return {
        x: x,
        y: y
      };
    }
    const safeDistance = Math.max(
      blackHole.radius + ENTITY_RADIUS * 4,
      blackHole.reach + RPS_BATTLE_REVIVE_BLACK_HOLE_SAFE_PADDING
    );
    if (!this.insideBlackHoleDanger(x, y, blackHole, safeDistance)) {
      return {
        x: x,
        y: y
      };
    }
    const home = this.factionHomeSpawnPoint(request.faction);
    if (!this.insideBlackHoleDanger(home.x, home.y, blackHole, safeDistance)) {
      return home;
    }
    return this.farthestReviveSpawnPoint(blackHole);
  }

  private factionHomeSpawnPoint(faction: RpsBattleFaction): RpsBattleSpawnPoint {
    let xRatio = 0.50;
    let yRatio = 0.74;
    if (faction === 'rock') {
      xRatio = 0.24;
      yRatio = 0.28;
    } else if (faction === 'scissors') {
      xRatio = 0.76;
      yRatio = 0.30;
    }
    return {
      x: this.clamp(this.boardWidth * xRatio, ENTITY_EDGE_PADDING, this.boardWidth - ENTITY_EDGE_PADDING),
      y: this.clamp(this.boardHeight * yRatio, ENTITY_EDGE_PADDING, this.boardHeight - ENTITY_EDGE_PADDING)
    };
  }

  private farthestReviveSpawnPoint(blackHole: RpsBattleBlackHoleState): RpsBattleSpawnPoint {
    const left = ENTITY_EDGE_PADDING;
    const right = this.boardWidth - ENTITY_EDGE_PADDING;
    const top = ENTITY_EDGE_PADDING;
    const bottom = this.boardHeight - ENTITY_EDGE_PADDING;
    let best: RpsBattleSpawnPoint = {
      x: left,
      y: top
    };
    let bestDistanceSq = this.distanceSq(best.x, best.y, blackHole.x, blackHole.y);
    const candidates: RpsBattleSpawnPoint[] = [
      { x: right, y: top },
      { x: left, y: bottom },
      { x: right, y: bottom }
    ];
    for (let i = 0; i < candidates.length; i += 1) {
      const candidate = candidates[i];
      const distanceSq = this.distanceSq(candidate.x, candidate.y, blackHole.x, blackHole.y);
      if (distanceSq > bestDistanceSq) {
        best = candidate;
        bestDistanceSq = distanceSq;
      }
    }
    return best;
  }

  private waitingForLastStandRevive(): boolean {
    return this.modeRules.hasLastStand && this.lastStandSystem.hasPendingReviveMarks();
  }

  private aliveFactionCount(): number {
    let count = 0;
    if (this.countsCache.rock > 0) {
      count += 1;
    }
    if (this.countsCache.scissors > 0) {
      count += 1;
    }
    if (this.countsCache.paper > 0) {
      count += 1;
    }
    return count;
  }

  private waitingForTraitorResolution(): boolean {
    return this.modeRules.hasTraitor && this.traitorSystem.hasPendingMarks();
  }

  private removeEntity(entity: RpsBattleEntity): void {
    for (let i = 0; i < this.entities.length; i += 1) {
      if (this.entities[i].id === entity.id) {
        this.removeFromFactionCache(entity, entity.faction);
        const lastIndex = this.entities.length - 1;
        if (i !== lastIndex) {
          this.entities[i] = this.entities[lastIndex];
        }
        this.entities.pop();
        return;
      }
    }
  }

  private findEntityById(entityId: number): RpsBattleEntity | null {
    for (let i = 0; i < this.entities.length; i += 1) {
      if (this.entities[i].id === entityId) {
        return this.entities[i];
      }
    }
    return null;
  }

  private consumeShield(entity: RpsBattleEntity): boolean {
    if (entity.shield <= 0) {
      return false;
    }
    entity.shield -= 1;
    return true;
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

  private zoneIntentAccel(entity: RpsBattleEntity, predator: RpsBattleEntity | undefined,
    zone: RpsBattleControlZone, elapsedSec: number): number {
    const roleBucket = entity.id % 20;
    const ownsZone = zone.owner === entity.faction;
    const capturesZone = zone.capturingFaction === entity.faction;
    const isOpeningRush = elapsedSec < RPS_BATTLE_ZONE_OPENING_RUSH_SEC;
    let accel = 0;
    if (roleBucket < 9) {
      accel = ownsZone ? RPS_BATTLE_ZONE_SUPPORT_ACCEL : RPS_BATTLE_ZONE_CONTESTER_ACCEL;
    } else if (roleBucket < 14) {
      accel = ownsZone || capturesZone ? RPS_BATTLE_ZONE_GUARD_ACCEL : RPS_BATTLE_ZONE_SUPPORT_ACCEL;
    } else if (isOpeningRush && roleBucket < 17) {
      accel = ownsZone ? RPS_BATTLE_ZONE_SUPPORT_ACCEL : RPS_BATTLE_ZONE_GUARD_ACCEL;
    } else if (!ownsZone && roleBucket % 3 === 0) {
      accel = RPS_BATTLE_ZONE_SUPPORT_ACCEL;
    }
    if (accel <= 0) {
      return 0;
    }
    const dx = entity.x - zone.x;
    const dy = entity.y - zone.y;
    if (ownsZone && dx * dx + dy * dy <= zone.radius * zone.radius) {
      accel *= RPS_BATTLE_ZONE_INSIDE_OWNER_SCALE;
    }
    if (isOpeningRush && !ownsZone) {
      accel *= RPS_BATTLE_ZONE_OPENING_ACCEL_SCALE;
    }
    if (predator !== undefined) {
      const predatorDx = entity.x - predator.x;
      const predatorDy = entity.y - predator.y;
      if (predatorDx * predatorDx + predatorDy * predatorDy < ENTITY_FLEE_DISTANCE_SQ) {
        accel *= RPS_BATTLE_ZONE_PREDATOR_PRESSURE_SCALE;
      }
    }
    return accel;
  }

  private insideBlackHoleDanger(x: number, y: number, blackHole: RpsBattleBlackHoleState,
    safeDistance: number): boolean {
    return this.distanceSq(x, y, blackHole.x, blackHole.y) < safeDistance * safeDistance;
  }

  private distanceSq(ax: number, ay: number, bx: number, by: number): number {
    const dx = ax - bx;
    const dy = ay - by;
    return dx * dx + dy * dy;
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
    const bounds: RpsBattleShrinkBounds = this.modeRules.hasShrink ?
      this.shrinkSystem.currentBounds(this.boardWidth, this.boardHeight) : {
        left: 0,
        top: 0,
        right: this.boardWidth,
        bottom: this.boardHeight
      };
    if (entity.x < bounds.left + entity.radius) {
      entity.x = bounds.left + entity.radius;
      entity.vx = Math.abs(entity.vx) * 0.86;
    } else if (entity.x > bounds.right - entity.radius) {
      entity.x = bounds.right - entity.radius;
      entity.vx = -Math.abs(entity.vx) * 0.86;
    }
    if (entity.y < bounds.top + entity.radius) {
      entity.y = bounds.top + entity.radius;
      entity.vy = Math.abs(entity.vy) * 0.86;
    } else if (entity.y > bounds.bottom - entity.radius) {
      entity.y = bounds.bottom - entity.radius;
      entity.vy = -Math.abs(entity.vy) * 0.86;
    }
  }

  private clampVelocity(entity: RpsBattleEntity, elapsedSec: number): void {
    const speed = Math.sqrt(entity.vx * entity.vx + entity.vy * entity.vy);
    let maxSpeed = ENTITY_MAX_SPEED;
    if (elapsedSec < entity.speedBoostUntilSec) {
      maxSpeed = Math.max(maxSpeed, ENTITY_MAX_SPEED * ENTITY_SPEED_BOOST_LIMIT_MULTIPLIER);
    }
    if (elapsedSec < entity.traitorRageUntilSec) {
      maxSpeed = Math.max(maxSpeed, ENTITY_MAX_SPEED * ENTITY_TRAITOR_RAGE_LIMIT_MULTIPLIER);
    }
    if (speed <= maxSpeed || speed <= 0) {
      return;
    }
    const ratio = maxSpeed / speed;
    entity.vx *= ratio;
    entity.vy *= ratio;
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
  }
}
