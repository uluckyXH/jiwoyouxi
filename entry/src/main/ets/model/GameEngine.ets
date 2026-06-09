import {
  beats,
  BlackHoleState,
  clamp,
  cloneOptions,
  ControlZone,
  Entity,
  GameBounds,
  GameEventKind,
  GamePhase,
  GameSnapshot,
  NativeGameOptions,
  NativeRenderState,
  Obstacle,
  PowerUp,
  PowerUpKind,
  ReviveMark,
  ThanosState,
  TraitorMark,
  TYPE_COUNT,
  defaultOptions
} from './GameTypes';
import { aliveTypeCount, aliveTypeList, countEntities, leadingType } from './GameRules';
import { TenAgainstOneSystem } from './TenAgainstOneSystem';
import { BountySystem } from './BountySystem';
import { BattleReportRecorder, NativeBattleReport } from './BattleReport';
import { factionEmoji, factionLabel } from './ThemeConfig';
import { NativeCanvasRenderer } from '../render/CanvasRenderer';

const BASE_RADIUS: number = 13;
const BASE_SPEED: number = 74;
const MAX_SPEED: number = 168;
const COLLISION_PUSH: number = 0.32;
const TRAITOR_DELAY: number = 2000;
const SHRINK_DELAY: number = 7000;
const SHRINK_SPEED: number = 9;
const SNAP_REVEAL_DELAY: number = 1650;
const SNAP_OVERLAY_DURATION: number = 3900;
const POWER_UP_LIFETIME: number = 12000;
const POWER_UP_INTERVAL: number = 6500;
const GAME_START_LAYOUT_HOLD: number = 1000;

interface LastPosition { x: number; y: number; }

export class NativeGameEngine {
  private options: NativeGameOptions = defaultOptions();
  private entities: Entity[] = [];
  private obstacles: Obstacle[] = [];
  private traitorMarks: TraitorMark[] = [];
  private revives: ReviveMark[] = [];
  private zones: ControlZone[] = [];
  private powerUps: PowerUp[] = [];
  private renderer: NativeCanvasRenderer = new NativeCanvasRenderer();
  private tenAgainstOne: TenAgainstOneSystem = new TenAgainstOneSystem();
  private bounty: BountySystem = new BountySystem();
  private battleReport: BattleReportRecorder = new BattleReportRecorder();
  private splitUsed: boolean[] = [false, false, false];
  private reviveUsed: boolean[] = [false, false, false];
  private previousCounts: number[] = [0, 0, 0];
  private lastPositions: LastPosition[] = [{ x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 }];
  private blackHole: BlackHoleState = { active: false, x: 0, y: 0, radius: 26, reach: 88, nextAt: 0 };
  private thanos: ThanosState = {
    enabled: false,
    warned: false,
    active: false,
    snapped: false,
    nextAt: 0,
    warningAt: 0,
    snapAt: 0,
    hideAt: 0
  };
  private bounds: GameBounds = { left: 16, top: 112, right: 360, bottom: 680 };
  private width: number = 390;
  private height: number = 760;
  private shrinkPadding: number = 0;
  private roundStart: number = 0;
  private holdUntil: number = 0;
  private lastTime: number = 0;
  private nextEntityId: number = 1;
  private phase: GamePhase = GamePhase.Setup;
  private winner: number = -1;
  private eventText: string = '';
  private eventKind: GameEventKind = GameEventKind.None;
  private eventId: number = 0;
  private eventUntil: number = 0;
  private nextTraitorAt: number = 0;
  private nextPowerUpAt: number = 0;
  private lastShrinkEventAt: number = 0;
  private earlyTraitorUsed: boolean = false;
  private handActive: boolean = false;
  private handPull: boolean = false;
  private handX: number = 0;
  private handY: number = 0;

  resize(width: number, height: number): void {
    this.width = Math.max(280, width);
    this.height = Math.max(420, height);
    this.updateBounds();
    this.keepEntitiesInBounds();
  }

  start(options: NativeGameOptions, now: number): void {
    this.options = cloneOptions(options);
    this.entities = [];
    this.obstacles = [];
    this.traitorMarks = [];
    this.revives = [];
    this.zones = [];
    this.powerUps = [];
    this.splitUsed = [false, false, false];
    this.reviveUsed = [false, false, false];
    this.previousCounts = [0, 0, 0];
    this.lastPositions = [{ x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 }];
    this.shrinkPadding = 0;
    this.roundStart = now;
    this.holdUntil = now + GAME_START_LAYOUT_HOLD;
    this.lastTime = now;
    this.nextEntityId = 1;
    this.phase = GamePhase.Playing;
    this.winner = -1;
    this.eventText = '';
    this.eventKind = GameEventKind.None;
    this.eventUntil = 0;
    this.nextTraitorAt = now + 20000;
    this.nextPowerUpAt = now + 5000;
    this.lastShrinkEventAt = 0;
    this.earlyTraitorUsed = false;
    this.bounty.reset(this.options.bounty);
    this.handActive = false;
    this.updateBounds();
    this.spawnEntities();
    this.spawnObstacles();
    this.spawnZones();
    this.resetBlackHole(now);
    this.resetThanos(now);
    this.tenAgainstOne.reset(options.tenAgainstOne, now, this.options);
    this.previousCounts = countEntities(this.entities);
    this.battleReport.reset(this.options, now, this.entities, this.previousCounts);
    this.addEvent('乱斗开始', now, GameEventKind.None);
  }

  pause(): void {
    if (this.phase === GamePhase.Playing) {
      this.phase = GamePhase.Paused;
    }
  }

  resume(now: number): void {
    if (this.phase === GamePhase.Paused) {
      this.phase = GamePhase.Playing;
      this.lastTime = now;
    }
  }

  resetToSetup(): void {
    this.phase = GamePhase.Setup;
    this.entities = [];
    this.obstacles = [];
    this.traitorMarks = [];
    this.revives = [];
    this.zones = [];
    this.powerUps = [];
    this.handActive = false;
    this.bounty.reset(false);
    this.winner = -1;
    this.holdUntil = 0;
    this.tenAgainstOne.reset(false, Date.now(), this.options);
  }

  setHand(active: boolean, x: number, y: number, pull: boolean): void {
    if (!this.options.godHand) {
      this.handActive = false;
      return;
    }
    this.handActive = active;
    this.handX = x;
    this.handY = y;
    this.handPull = pull;
  }

  update(now: number): GameSnapshot {
    if (this.phase !== GamePhase.Playing) {
      return this.snapshot(now);
    }

    const dt = clamp((now - this.lastTime) / 1000, 0.001, 0.05);
    this.lastTime = now;
    if (now < this.holdUntil) {
      return this.snapshot(now);
    }
    if (this.tenAgainstOne.paused(now)) {
      return this.snapshot(now);
    }
    this.updateShrink(now, dt);
    this.bounty.update(now, this.roundStart, countEntities(this.entities), this.options, (text: string, eventNow: number, kind: GameEventKind) => {
      this.addEvent(text, eventNow, kind);
    });
    this.updateBlackHole(now, dt);
    this.updateTraitors(now);
    this.updateThanos(now);
    this.updateRevives(now);
    this.updatePowerUps(now);
    this.updateEntities(now, dt);
    this.resolveCollisions(now);
    this.updateZones(dt);
    this.updateLastStand(now);
    this.updateTenAgainstOne(now);
    this.battleReport.recordTimeline(now, countEntities(this.entities));
    this.checkFinish(now);
    return this.snapshot(now);
  }

  draw(ctx: CanvasRenderingContext2D): void {
    this.renderer.draw(ctx, this.renderState());
  }

  report(): NativeBattleReport {
    return this.battleReport.summary();
  }

  private renderState(): NativeRenderState {
    return {
      width: this.width,
      height: this.height,
      bounds: this.bounds,
      options: this.options,
      entities: this.entities,
      obstacles: this.obstacles,
      zones: this.zones,
      powerUps: this.powerUps,
      blackHole: this.blackHole,
      bountyActive: this.bounty.active(),
      bountyLeader: this.bounty.leader(),
      traitorMarks: this.traitorMarks,
      lastTime: this.lastTime,
      rageType: this.tenAgainstOne.rageType(this.lastTime),
      rageUntil: this.tenAgainstOne.rageUntil(),
      handActive: this.handActive,
      handPull: this.handPull,
      handX: this.handX,
      handY: this.handY
    };
  }

  snapshot(now: number): GameSnapshot {
    const counts = countEntities(this.entities);
    const aliveTypes = aliveTypeCount(counts);
    const elapsed = Math.max(0, now - this.roundStart);
    const limit = this.options.durationSec * 1000;
    const timeLeftSec = this.options.deathmatch ? -1 : Math.max(0, (limit - elapsed) / 1000);
    let status = '准备中';
    if (this.phase === GamePhase.Playing) {
      status = this.options.deathmatch ? '死斗中' : `剩余 ${timeLeftSec.toFixed(1)}s`;
      if (this.options.controlZones) {
        status = `据点 ${this.zoneScoreText()}`;
      }
    } else if (this.phase === GamePhase.Paused) {
      status = '已暂停';
    } else if (this.phase === GamePhase.Result) {
      status = this.winner >= 0 ? `${this.factionLabel(this.winner)} 获胜` : '无人获胜';
    }
    return {
      counts: counts,
      aliveTypes: aliveTypes,
      timeLeftSec: timeLeftSec,
      status: status,
      eventText: now < this.eventUntil ? this.eventText : '',
      eventId: this.eventId,
      eventKind: now < this.eventUntil ? this.eventKind : GameEventKind.None,
      winner: this.winner,
      phase: this.phase,
      bountyActive: this.bounty.active(),
      bountyLeader: this.bounty.leader(),
      thanosVisible: this.thanos.active,
      thanosText: this.thanos.snapped ? '所有派系消失一半' : '啪，打个响指',
      heroOverlayVisible: this.tenAgainstOne.overlayVisible(now),
      heroOverlayText: this.tenAgainstOne.overlayText(),
      heroOverlaySubText: this.tenAgainstOne.overlaySubText(now),
      rageType: this.tenAgainstOne.rageType(now),
      rageTimeLeftSec: this.tenAgainstOne.rageTimeLeftSec(now),
      rageProgress: this.tenAgainstOne.rageProgress(now)
    };
  }

  private updateBounds(): void {
    const topReserve = this.width < 620 ? 118 : 82;
    const bottomReserve = this.width < 620 ? 82 : 72;
    const baseLeft = 14 + this.shrinkPadding;
    const baseTop = topReserve + this.shrinkPadding;
    const baseRight = this.width - 14 - this.shrinkPadding;
    const baseBottom = this.height - bottomReserve - this.shrinkPadding;
    this.bounds = {
      left: Math.min(baseLeft, this.width * 0.38),
      top: Math.min(baseTop, this.height * 0.42),
      right: Math.max(baseRight, this.width * 0.62),
      bottom: Math.max(baseBottom, this.height * 0.58)
    };
  }

  private spawnEntities(): void {
    for (let type = 0; type < TYPE_COUNT; type += 1) {
      const count = clamp(Math.round(this.options.counts[type]), 3, 60);
      for (let i = 0; i < count; i += 1) {
        const angle = Math.random() * Math.PI * 2;
        const radius = BASE_RADIUS + Math.random() * 3;
        this.entities.push({
          id: this.nextEntityId,
          type: type,
          x: this.random(this.bounds.left + 28, this.bounds.right - 28),
          y: this.random(this.bounds.top + 28, this.bounds.bottom - 28),
          vx: Math.cos(angle) * BASE_SPEED,
          vy: Math.sin(angle) * BASE_SPEED,
          radius: radius,
          speed: BASE_SPEED + Math.random() * 24,
          shield: 0,
          alive: true,
          rageUntil: 0
        });
        this.nextEntityId += 1;
      }
    }
  }

  private spawnObstacles(): void {
    if (!this.options.obstacles) {
      return;
    }
    const count = this.width < 620 ? 3 : 5;
    for (let i = 0; i < count; i += 1) {
      this.obstacles.push({
        x: this.random(this.bounds.left + 60, this.bounds.right - 60),
        y: this.random(this.bounds.top + 70, this.bounds.bottom - 70),
        width: this.random(38, 82),
        height: this.random(28, 76)
      });
    }
  }

  private spawnZones(): void {
    if (!this.options.controlZones) {
      return;
    }
    const radius = this.width < 620 ? 48 : 62;
    this.zones.push({
      x: this.width * 0.5,
      y: this.bounds.top + (this.bounds.bottom - this.bounds.top) * 0.5,
      radius: radius,
      owner: -1,
      score: 0
    });
  }

  private resetBlackHole(now: number): void {
    this.blackHole = {
      active: false,
      x: this.width * 0.5,
      y: this.height * 0.5,
      radius: 24,
      reach: 82,
      nextAt: now + this.random(9000, 16000)
    };
  }

  private resetThanos(now: number): void {
    const next = now + this.random(9000, this.options.deathmatch ? 23000 : 18000);
    this.thanos = {
      enabled: this.options.thanos,
      warned: false,
      active: false,
      snapped: false,
      nextAt: next,
      warningAt: next - 3000,
      snapAt: 0,
      hideAt: 0
    };
  }

  private updateEntities(now: number, dt: number): void {
    for (let i = 0; i < this.entities.length; i += 1) {
      const entity = this.entities[i];
      if (!entity.alive) {
        continue;
      }
      this.applyTargeting(entity, dt);
      this.applyBlackHoleForce(entity, dt);
      this.applyHandForce(entity, dt);
      const tenBoost = this.tenAgainstOne.boost(entity.type, now);
      const bountyBoost = this.bounty.active() && entity.type !== this.bounty.leader() ? 1.16 : 1;
      const speedLimit = now < entity.rageUntil ? MAX_SPEED * 1.25 * tenBoost * bountyBoost : MAX_SPEED * tenBoost * bountyBoost;
      const velocity = Math.sqrt(entity.vx * entity.vx + entity.vy * entity.vy);
      if (velocity > speedLimit) {
        entity.vx = entity.vx / velocity * speedLimit;
        entity.vy = entity.vy / velocity * speedLimit;
      }
      entity.x += entity.vx * dt;
      entity.y += entity.vy * dt;
      this.resolveBounds(entity);
      this.resolveObstacle(entity);
      this.collectPowerUps(entity, now);
      this.lastPositions[entity.type] = { x: entity.x, y: entity.y };
    }
  }

  private applyTargeting(entity: Entity, dt: number): void {
    const prey = this.nearestEntity(entity, (entity.type + 1) % TYPE_COUNT);
    const predator = this.nearestEntity(entity, (entity.type + 2) % TYPE_COUNT);
    const tenBoost = this.tenAgainstOne.boost(entity.type, this.lastTime);
    if (prey !== null) {
      const dx = prey.x - entity.x;
      const dy = prey.y - entity.y;
      const d = Math.max(1, Math.sqrt(dx * dx + dy * dy));
      const accel = entity.speed * 1.8 * tenBoost;
      entity.vx += dx / d * accel * dt;
      entity.vy += dy / d * accel * dt;
    }
    if (predator !== null) {
      const dx = entity.x - predator.x;
      const dy = entity.y - predator.y;
      const d = Math.max(1, Math.sqrt(dx * dx + dy * dy));
      const avoid = Math.max(0, 1 - d / 150) * entity.speed * 2.2 * tenBoost;
      entity.vx += dx / d * avoid * dt;
      entity.vy += dy / d * avoid * dt;
    }
    if (this.bounty.active() && entity.type !== this.bounty.leader()) {
      const target = this.nearestEntity(entity, this.bounty.leader());
      if (target !== null) {
        const dx = target.x - entity.x;
        const dy = target.y - entity.y;
        const d = Math.max(1, Math.sqrt(dx * dx + dy * dy));
        const force = entity.speed * 1.15 * tenBoost;
        entity.vx += dx / d * force * dt;
        entity.vy += dy / d * force * dt;
      }
    }
    entity.vx += this.random(-18, 18) * dt;
    entity.vy += this.random(-18, 18) * dt;
  }

  private nearestEntity(entity: Entity, type: number): Entity | null {
    let best: Entity | null = null;
    let bestDist = Number.POSITIVE_INFINITY;
    for (let i = 0; i < this.entities.length; i += 1) {
      const other = this.entities[i];
      if (!other.alive || other.type !== type || other.id === entity.id) {
        continue;
      }
      const dx = other.x - entity.x;
      const dy = other.y - entity.y;
      const dist = dx * dx + dy * dy;
      if (dist < bestDist) {
        best = other;
        bestDist = dist;
      }
    }
    return best;
  }

  private applyBlackHoleForce(entity: Entity, dt: number): void {
    if (!this.blackHole.active) {
      return;
    }
    const dx = this.blackHole.x - entity.x;
    const dy = this.blackHole.y - entity.y;
    const d = Math.max(1, Math.sqrt(dx * dx + dy * dy));
    if (d > this.blackHole.reach) {
      return;
    }
    const force = (1 - d / this.blackHole.reach) * 280;
    entity.vx += dx / d * force * dt;
    entity.vy += dy / d * force * dt;
    if (d < this.blackHole.radius + entity.radius * 0.35) {
      entity.alive = false;
      this.blackHole.radius = Math.min(this.blackHole.radius * 1.3, 116);
      this.blackHole.reach = Math.min(this.blackHole.reach * 1.3, 310);
      this.addEvent(`黑洞吞噬 ${this.factionLabel(entity.type)}`, this.lastTime, GameEventKind.Warning);
    }
  }

  private applyHandForce(entity: Entity, dt: number): void {
    if (!this.handActive || !this.options.godHand) {
      return;
    }
    const dx = entity.x - this.handX;
    const dy = entity.y - this.handY;
    const d = Math.max(1, Math.sqrt(dx * dx + dy * dy));
    const range = 130;
    if (d > range) {
      return;
    }
    const direction = this.handPull ? -1 : 1;
    const force = (1 - d / range) * 720 * direction;
    entity.vx += dx / d * force * dt;
    entity.vy += dy / d * force * dt;
  }

  private resolveCollisions(now: number): void {
    for (let i = 0; i < this.entities.length; i += 1) {
      const a = this.entities[i];
      if (!a.alive) {
        continue;
      }
      for (let j = i + 1; j < this.entities.length; j += 1) {
        const b = this.entities[j];
        if (!b.alive) {
          continue;
        }
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const dist = Math.max(0.1, Math.sqrt(dx * dx + dy * dy));
        const minDist = a.radius + b.radius;
        if (dist >= minDist) {
          continue;
        }
        const overlap = (minDist - dist) * COLLISION_PUSH;
        const nx = dx / dist;
        const ny = dy / dist;
        a.x -= nx * overlap;
        a.y -= ny * overlap;
        b.x += nx * overlap;
        b.y += ny * overlap;
        const avx = a.vx;
        const avy = a.vy;
        a.vx = b.vx * 0.72;
        a.vy = b.vy * 0.72;
        b.vx = avx * 0.72;
        b.vy = avy * 0.72;
        if (a.type === b.type) {
          continue;
        }
        if (this.tenAgainstOne.resolveCollision(a, b, now, (text: string, eventNow: number, kind: GameEventKind) => {
          this.addEvent(text, eventNow, kind);
        })) {
          continue;
        }
        if (beats(a.type, b.type)) {
          this.convertEntity(b, a, now);
        } else if (beats(b.type, a.type)) {
          this.convertEntity(a, b, now);
        }
      }
    }
  }

  private convertEntity(entity: Entity, winner: Entity, now: number): void {
    const from = entity.type;
    const toType = winner.type;
    if (entity.shield > 0) {
      entity.shield -= 1;
      return;
    }
    entity.type = toType;
    entity.rageUntil = now + 240;
    entity.vx *= 1.08;
    entity.vy *= 1.08;
    if (this.bounty.isLeader(from)) {
      this.bounty.applyReward(winner, now, this.options, (text: string, eventNow: number, kind: GameEventKind) => {
        this.addEvent(text, eventNow, kind);
      });
    }
    this.battleReport.recordConversion(winner.id, winner.type, entity.id, now, countEntities(this.entities));
    this.addEvent(`${this.factionLabel(from)} 被 ${this.factionLabel(toType)} 转化`, now, GameEventKind.Attack);
  }

  private updateBlackHole(now: number, dt: number): void {
    if (!this.options.blackHole) {
      return;
    }
    if (!this.blackHole.active && now >= this.blackHole.nextAt) {
      this.blackHole.active = true;
      this.blackHole.x = this.random(this.bounds.left + 70, this.bounds.right - 70);
      this.blackHole.y = this.random(this.bounds.top + 70, this.bounds.bottom - 70);
      this.blackHole.radius = 24;
      this.blackHole.reach = 82;
      this.addEvent('危险来临：黑洞出现', now, GameEventKind.Warning);
    }
    if (this.blackHole.active) {
      this.blackHole.radius += Math.sin(now / 240) * 0.012 * dt;
    }
  }

  private updateTraitors(now: number): void {
    if (!this.options.traitor) {
      return;
    }
    const elapsed = now - this.roundStart;
    const counts = countEntities(this.entities);
    if (!this.earlyTraitorUsed && elapsed >= 10000 && elapsed <= 15000 && aliveTypeCount(counts) === 2) {
      this.earlyTraitorUsed = true;
      this.queueTraitor(now, -1);
      return;
    }
    if (elapsed < 20000 || now < this.nextTraitorAt) {
      this.applyTraitorMarks(now);
      return;
    }
    this.nextTraitorAt = now + 10000;
    const alive = aliveTypeList(counts);
    const triggerCount = Math.min(alive.length, Math.random() < 0.5 ? 1 : 2);
    for (let i = 0; i < triggerCount; i += 1) {
      const index = Math.floor(Math.random() * alive.length);
      const type = alive[index];
      alive.splice(index, 1);
      this.queueTraitor(now, type);
    }
    this.applyTraitorMarks(now);
  }

  private queueTraitor(now: number, forcedType: number): void {
    const counts = countEntities(this.entities);
    const alive = aliveTypeList(counts);
    if (alive.length < 2) {
      return;
    }
    let fromType = forcedType;
    if (fromType < 0) {
      fromType = alive[Math.floor(Math.random() * alive.length)];
    }
    const candidates = this.entities.filter((item: Entity) => item.alive && item.type === fromType && !this.hasTraitorMark(item.id));
    if (candidates.length === 0) {
      return;
    }
    let toType = Math.floor(Math.random() * TYPE_COUNT);
    while (toType === fromType) {
      toType = Math.floor(Math.random() * TYPE_COUNT);
    }
    const entity = candidates[Math.floor(Math.random() * candidates.length)];
    this.traitorMarks.push({
      entityId: entity.id,
      fromType: fromType,
      toType: toType,
      startAt: now,
      triggerAt: now + TRAITOR_DELAY
    });
    this.addEvent(`${this.factionLabel(fromType)} 阵营出现叛徒`, now, GameEventKind.Warning);
  }

  private applyTraitorMarks(now: number): void {
    const nextMarks: TraitorMark[] = [];
    for (let i = 0; i < this.traitorMarks.length; i += 1) {
      const mark = this.traitorMarks[i];
      const entity = this.findEntity(mark.entityId);
      if (entity === null || !entity.alive) {
        continue;
      }
      if (now >= mark.triggerAt) {
        entity.type = mark.toType;
        entity.rageUntil = now + 900;
        this.addEvent(`叛徒加入 ${this.factionLabel(mark.toType)}`, now, GameEventKind.Warning);
      } else {
        nextMarks.push(mark);
      }
    }
    this.traitorMarks = nextMarks;
  }

  private updateThanos(now: number): void {
    if (!this.thanos.enabled || this.thanos.snapped) {
      return;
    }
    if (!this.thanos.warned && now >= this.thanos.warningAt) {
      this.thanos.warned = true;
      this.addEvent('危险来临：灭霸 3 秒后登场', now, GameEventKind.Warning);
    }
    if (!this.thanos.active && now >= this.thanos.nextAt) {
      this.thanos.active = true;
      this.thanos.snapAt = now + SNAP_REVEAL_DELAY;
      this.thanos.hideAt = now + SNAP_OVERLAY_DURATION;
      this.addEvent('灭霸登场，响指将至', now, GameEventKind.Warning);
    }
    if (this.thanos.active && !this.thanos.snapped && now >= this.thanos.snapAt) {
      this.applyThanosSnap(now);
    }
    if (this.thanos.active && now >= this.thanos.hideAt) {
      this.thanos.active = false;
    }
  }

  private applyThanosSnap(now: number): void {
    for (let type = 0; type < TYPE_COUNT; type += 1) {
      const list = this.entities.filter((item: Entity) => item.alive && item.type === type);
      const removeCount = Math.floor(list.length / 2);
      for (let i = 0; i < removeCount; i += 1) {
        const index = Math.floor(Math.random() * list.length);
        const entity = list[index];
        entity.alive = false;
        list.splice(index, 1);
      }
    }
    this.thanos.snapped = true;
    this.addEvent('响指完成：所有派系减半', now, GameEventKind.Snap);
  }

  private updateRevives(now: number): void {
    if (this.revives.length === 0) {
      return;
    }
    const pending: ReviveMark[] = [];
    for (let i = 0; i < this.revives.length; i += 1) {
      const revive = this.revives[i];
      if (now >= revive.at) {
        this.spawnOne(revive.type, revive.x, revive.y, 1.12);
        this.addEvent(`${this.factionLabel(revive.type)} 原地复活`, now, GameEventKind.PowerUp);
      } else {
        pending.push(revive);
      }
    }
    this.revives = pending;
  }

  private updateLastStand(now: number): void {
    if (!this.options.lastStand) {
      this.previousCounts = countEntities(this.entities);
      return;
    }
    const counts = countEntities(this.entities);
    for (let type = 0; type < TYPE_COUNT; type += 1) {
      if (counts[type] === 1 && !this.splitUsed[type] && Math.random() < 0.018) {
        const source = this.entities.find((item: Entity) => item.alive && item.type === type);
        if (source !== undefined) {
          this.spawnOne(type, source.x + this.random(-18, 18), source.y + this.random(-18, 18), 0.94);
          this.splitUsed[type] = true;
          this.addEvent(`${this.factionLabel(type)} 绝地分裂`, now, GameEventKind.PowerUp);
        }
      }
      if (counts[type] === 0 && this.previousCounts[type] === 1 && !this.reviveUsed[type] && Math.random() < 0.26) {
        this.reviveUsed[type] = true;
        this.revives.push({
          type: type,
          x: this.lastPositions[type].x,
          y: this.lastPositions[type].y,
          at: now + 5000
        });
        this.addEvent(`${this.factionLabel(type)} 留下复活印记`, now, GameEventKind.Warning);
      }
    }
    this.previousCounts = counts;
  }

  private spawnOne(type: number, x: number, y: number, scale: number): void {
    const angle = Math.random() * Math.PI * 2;
    this.entities.push({
      id: this.nextEntityId,
      type: type,
      x: clamp(x, this.bounds.left + 20, this.bounds.right - 20),
      y: clamp(y, this.bounds.top + 20, this.bounds.bottom - 20),
      vx: Math.cos(angle) * BASE_SPEED,
      vy: Math.sin(angle) * BASE_SPEED,
      radius: BASE_RADIUS * scale,
      speed: BASE_SPEED + 18,
      shield: 0,
      alive: true,
      rageUntil: 0
    });
    this.nextEntityId += 1;
  }

  private updatePowerUps(now: number): void {
    if (!this.options.powerUps) {
      this.powerUps = [];
      return;
    }
    const remaining: PowerUp[] = [];
    for (let i = 0; i < this.powerUps.length; i += 1) {
      if (this.powerUps[i].expiresAt > now) {
        remaining.push(this.powerUps[i]);
      }
    }
    this.powerUps = remaining;
    if (now < this.nextPowerUpAt || this.powerUps.length >= 4) {
      return;
    }
    this.nextPowerUpAt = now + POWER_UP_INTERVAL + this.random(-1800, 2400);
    this.powerUps.push({
      id: this.nextEntityId,
      kind: Math.floor(Math.random() * 3) as PowerUpKind,
      x: this.random(this.bounds.left + 34, this.bounds.right - 34),
      y: this.random(this.bounds.top + 34, this.bounds.bottom - 34),
      radius: 14,
      expiresAt: now + POWER_UP_LIFETIME
    });
    this.nextEntityId += 1;
    this.addEvent('能量道具刷新', now, GameEventKind.PowerUp);
  }

  private collectPowerUps(entity: Entity, now: number): void {
    if (!this.options.powerUps || this.powerUps.length === 0) {
      return;
    }
    const remaining: PowerUp[] = [];
    for (let i = 0; i < this.powerUps.length; i += 1) {
      const item = this.powerUps[i];
      const dx = item.x - entity.x;
      const dy = item.y - entity.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist <= entity.radius + item.radius) {
        this.applyPowerUp(entity, item, now);
      } else {
        remaining.push(item);
      }
    }
    this.powerUps = remaining;
  }

  private applyPowerUp(entity: Entity, item: PowerUp, now: number): void {
    if (this.options.teamPowerUps) {
      for (let i = 0; i < this.entities.length; i += 1) {
        const member = this.entities[i];
        if (member.alive && member.type === entity.type) {
          this.applyPowerUpToEntity(member, item.kind, now);
        }
      }
      this.addEvent(`${this.factionLabel(entity.type)} 全队获得${this.powerUpName(item.kind)}`, now, GameEventKind.PowerUp);
      return;
    }
    this.applyPowerUpToEntity(entity, item.kind, now);
    this.addEvent(`${this.factionLabel(entity.type)} 获得${this.powerUpName(item.kind)}`, now, GameEventKind.PowerUp);
  }

  private applyPowerUpToEntity(entity: Entity, kind: PowerUpKind, now: number): void {
    if (kind === PowerUpKind.Speed) {
      entity.rageUntil = Math.max(entity.rageUntil, now + 6000);
      entity.vx *= 1.22;
      entity.vy *= 1.22;
    } else if (kind === PowerUpKind.Shield) {
      entity.shield = Math.max(entity.shield, 1);
    } else {
      this.spawnOne(entity.type, entity.x + this.random(-18, 18), entity.y + this.random(-18, 18), 0.86);
    }
  }

  private powerUpName(kind: PowerUpKind): string {
    return kind === PowerUpKind.Speed ? '加速' : kind === PowerUpKind.Shield ? '护盾' : '分裂';
  }

  private updateZones(dt: number): void {
    if (!this.options.controlZones) {
      return;
    }
    for (let i = 0; i < this.zones.length; i += 1) {
      const zone = this.zones[i];
      const pressure = [0, 0, 0];
      for (let j = 0; j < this.entities.length; j += 1) {
        const entity = this.entities[j];
        if (!entity.alive) {
          continue;
        }
        const dx = entity.x - zone.x;
        const dy = entity.y - zone.y;
        if (Math.sqrt(dx * dx + dy * dy) <= zone.radius) {
          pressure[entity.type] += 1;
        }
      }
      let owner = -1;
      let max = 0;
      let tied = false;
      for (let type = 0; type < TYPE_COUNT; type += 1) {
        if (pressure[type] > max) {
          owner = type;
          max = pressure[type];
          tied = false;
        } else if (pressure[type] === max && max > 0) {
          tied = true;
        }
      }
      if (owner >= 0 && !tied) {
        zone.owner = owner;
        zone.score = Math.min(100, zone.score + max * 2.8 * dt);
      }
    }
  }

  private updateShrink(now: number, dt: number): void {
    if (!this.options.shrink || now - this.roundStart < SHRINK_DELAY) {
      return;
    }
    const maxPadding = Math.min(this.width, this.height) * 0.28;
    this.shrinkPadding = Math.min(maxPadding, this.shrinkPadding + SHRINK_SPEED * dt);
    this.updateBounds();
    if (now - this.lastShrinkEventAt > 5200) {
      this.lastShrinkEventAt = now;
      this.addEvent('缩圈正在推进', now, GameEventKind.Shrink);
    }
  }

  private updateTenAgainstOne(now: number): void {
    const before = countEntities(this.entities);
    this.tenAgainstOne.tryTrigger(now, before, this.entities, (text: string, eventNow: number, kind: GameEventKind) => {
      this.addEvent(text, eventNow, kind);
    });
    const after = countEntities(this.entities);
    this.tenAgainstOne.updateOutcome(now, after, (winner: number, eventNow: number) => {
      this.finish(winner, eventNow, '以弱胜强');
    }, (text: string, eventNow: number, kind: GameEventKind) => {
      this.addEvent(text, eventNow, kind);
    });
  }

  private checkFinish(now: number): void {
    if (this.phase !== GamePhase.Playing) {
      return;
    }
    const counts = countEntities(this.entities);
    const aliveTypes = aliveTypeCount(counts);
    if (aliveTypes <= 1) {
      this.finish(leadingType(counts), now, '清场');
      return;
    }
    if (this.options.controlZones) {
      for (let i = 0; i < this.zones.length; i += 1) {
        if (this.zones[i].score >= 100 && this.zones[i].owner >= 0) {
          this.finish(this.zones[i].owner, now, '据点达标');
          return;
        }
      }
    }
    if (!this.options.deathmatch && now - this.roundStart >= this.options.durationSec * 1000) {
      const winner = leadingType(counts);
      if (winner >= 0) {
        this.finish(winner, now, '时间到');
      }
    }
  }

  private finish(winner: number, now: number, reason: string): void {
    this.winner = winner;
    this.phase = GamePhase.Result;
    this.battleReport.recordFinish(winner, reason, now, countEntities(this.entities), this.entities);
    if (winner >= 0) {
      this.addEvent(`${this.factionLabel(winner)} 获胜`, now, GameEventKind.Win);
    } else {
      this.addEvent('无人获胜', now, GameEventKind.Win);
    }
  }

  private zoneScoreText(): string {
    if (this.zones.length === 0) return '0';
    const zone = this.zones[0];
    const owner = zone.owner >= 0 ? this.factionEmoji(zone.owner) : '·';
    return `${owner} ${Math.floor(zone.score)}`;
  }

  private addEvent(text: string, now: number, kind: GameEventKind): void {
    this.eventText = text;
    this.eventKind = kind;
    this.eventId += 1;
    this.eventUntil = now + 2200;
    this.battleReport.recordEvent(text, now, countEntities(this.entities), kind !== GameEventKind.Attack && kind !== GameEventKind.None);
  }

  private resolveBounds(entity: Entity): void {
    if (entity.x < this.bounds.left + entity.radius) {
      entity.x = this.bounds.left + entity.radius;
      entity.vx = Math.abs(entity.vx) * 0.88;
    } else if (entity.x > this.bounds.right - entity.radius) {
      entity.x = this.bounds.right - entity.radius;
      entity.vx = -Math.abs(entity.vx) * 0.88;
    }
    if (entity.y < this.bounds.top + entity.radius) {
      entity.y = this.bounds.top + entity.radius;
      entity.vy = Math.abs(entity.vy) * 0.88;
    } else if (entity.y > this.bounds.bottom - entity.radius) {
      entity.y = this.bounds.bottom - entity.radius;
      entity.vy = -Math.abs(entity.vy) * 0.88;
    }
  }

  private resolveObstacle(entity: Entity): void {
    for (let i = 0; i < this.obstacles.length; i += 1) {
      const item = this.obstacles[i];
      const left = item.x - item.width * 0.5;
      const right = item.x + item.width * 0.5;
      const top = item.y - item.height * 0.5;
      const bottom = item.y + item.height * 0.5;
      const nearestX = clamp(entity.x, left, right);
      const nearestY = clamp(entity.y, top, bottom);
      const dx = entity.x - nearestX;
      const dy = entity.y - nearestY;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < entity.radius) {
        if (Math.abs(dx) > Math.abs(dy)) {
          entity.vx *= -0.9;
          entity.x += dx >= 0 ? entity.radius : -entity.radius;
        } else {
          entity.vy *= -0.9;
          entity.y += dy >= 0 ? entity.radius : -entity.radius;
        }
      }
    }
  }

  private keepEntitiesInBounds(): void {
    for (let i = 0; i < this.entities.length; i += 1) {
      this.resolveBounds(this.entities[i]);
    }
  }

  private findEntity(id: number): Entity | null {
    for (let i = 0; i < this.entities.length; i += 1) {
      if (this.entities[i].id === id) {
        return this.entities[i];
      }
    }
    return null;
  }

  private hasTraitorMark(id: number): boolean {
    for (let i = 0; i < this.traitorMarks.length; i += 1) {
      if (this.traitorMarks[i].entityId === id) {
        return true;
      }
    }
    return false;
  }

  private factionLabel(type: number): string {
    return factionLabel(this.options, type);
  }

  private factionEmoji(type: number): string {
    return factionEmoji(this.options, type);
  }

  private random(min: number, max: number): number {
    return min + Math.random() * (max - min);
  }
}
