import {
  RpsBattleEntity,
  RpsBattlePowerUp,
  RpsBattlePowerUpKind,
  RpsBattlePowerUpPickup,
  RpsBattlePowerUpPulse,
  RpsBattlePowerUpState
} from './RpsBattleTypes';

export const RPS_BATTLE_POWER_UP_FIRST_DELAY_SEC: number = 3;
export const RPS_BATTLE_POWER_UP_INTERVAL_SEC: number = 4;
export const RPS_BATTLE_POWER_UP_INTERVAL_JITTER_MIN_SEC: number = -0.8;
export const RPS_BATTLE_POWER_UP_INTERVAL_JITTER_MAX_SEC: number = 1;
export const RPS_BATTLE_POWER_UP_LIFETIME_SEC: number = 12;
export const RPS_BATTLE_POWER_UP_MAX_ACTIVE: number = 6;
export const RPS_BATTLE_POWER_UP_RADIUS: number = 14;
export const RPS_BATTLE_POWER_UP_EDGE_MARGIN: number = 34;
export const RPS_BATTLE_POWER_UP_PULSE_DURATION_SEC: number = 0.72;

export class RpsBattlePowerUpSystem {
  private items: RpsBattlePowerUp[] = [];
  private pulses: RpsBattlePowerUpPulse[] = [];
  private nextPowerUpAtSec: number = 0;
  private nextId: number = 1;
  private spawnedCount: number = 0;
  private pickedCount: number = 0;
  private teamEffectCount: number = 0;
  private lastPickedCount: number = 0;
  private lastTeamEffectCount: number = 0;

  reset(elapsedSec: number = 0): void {
    this.items = [];
    this.pulses = [];
    this.nextPowerUpAtSec = elapsedSec + RPS_BATTLE_POWER_UP_FIRST_DELAY_SEC;
    this.nextId = 1;
    this.spawnedCount = 0;
    this.pickedCount = 0;
    this.teamEffectCount = 0;
    this.lastPickedCount = 0;
    this.lastTeamEffectCount = 0;
  }

  clear(): void {
    this.items = [];
    this.pulses = [];
    this.nextPowerUpAtSec = 0;
    this.nextId = 1;
    this.spawnedCount = 0;
    this.pickedCount = 0;
    this.teamEffectCount = 0;
    this.lastPickedCount = 0;
    this.lastTeamEffectCount = 0;
  }

  resize(ratioX: number, ratioY: number, boardWidth: number, boardHeight: number): void {
    for (let i = 0; i < this.items.length; i += 1) {
      const item = this.items[i];
      item.x = this.clamp(item.x * ratioX, RPS_BATTLE_POWER_UP_EDGE_MARGIN,
        boardWidth - RPS_BATTLE_POWER_UP_EDGE_MARGIN);
      item.y = this.clamp(item.y * ratioY, RPS_BATTLE_POWER_UP_EDGE_MARGIN,
        boardHeight - RPS_BATTLE_POWER_UP_EDGE_MARGIN);
    }
    for (let i = 0; i < this.pulses.length; i += 1) {
      const pulse = this.pulses[i];
      pulse.x = this.clamp(pulse.x * ratioX, RPS_BATTLE_POWER_UP_EDGE_MARGIN,
        boardWidth - RPS_BATTLE_POWER_UP_EDGE_MARGIN);
      pulse.y = this.clamp(pulse.y * ratioY, RPS_BATTLE_POWER_UP_EDGE_MARGIN,
        boardHeight - RPS_BATTLE_POWER_UP_EDGE_MARGIN);
    }
  }

  updateSpawnAndExpire(isEnabled: boolean, elapsedSec: number, boardWidth: number, boardHeight: number,
    random: () => number): void {
    this.lastPickedCount = 0;
    this.lastTeamEffectCount = 0;
    if (!isEnabled) {
      this.clear();
      return;
    }
    this.pruneExpiredItems(elapsedSec);
    this.prunePulses(elapsedSec);
    if (elapsedSec < this.nextPowerUpAtSec || this.items.length >= RPS_BATTLE_POWER_UP_MAX_ACTIVE) {
      return;
    }
    this.nextPowerUpAtSec = elapsedSec + RPS_BATTLE_POWER_UP_INTERVAL_SEC +
      this.randomBetween(random, RPS_BATTLE_POWER_UP_INTERVAL_JITTER_MIN_SEC,
        RPS_BATTLE_POWER_UP_INTERVAL_JITTER_MAX_SEC);
    this.items.push({
      id: this.nextId,
      kind: this.randomKind(),
      x: this.randomBetween(random, RPS_BATTLE_POWER_UP_EDGE_MARGIN,
        Math.max(RPS_BATTLE_POWER_UP_EDGE_MARGIN, boardWidth - RPS_BATTLE_POWER_UP_EDGE_MARGIN)),
      y: this.randomBetween(random, RPS_BATTLE_POWER_UP_EDGE_MARGIN,
        Math.max(RPS_BATTLE_POWER_UP_EDGE_MARGIN, boardHeight - RPS_BATTLE_POWER_UP_EDGE_MARGIN)),
      radius: RPS_BATTLE_POWER_UP_RADIUS,
      expiresAtSec: elapsedSec + RPS_BATTLE_POWER_UP_LIFETIME_SEC
    });
    this.nextId += 1;
    this.spawnedCount += 1;
  }

  collect(entities: RpsBattleEntity[], elapsedSec: number, isTeamEnabled: boolean): RpsBattlePowerUpPickup[] {
    if (this.items.length === 0) {
      return [];
    }
    const pickups: RpsBattlePowerUpPickup[] = [];
    const remaining: RpsBattlePowerUp[] = [];
    for (let itemIndex = 0; itemIndex < this.items.length; itemIndex += 1) {
      const item = this.items[itemIndex];
      const collector = this.findCollector(item, entities);
      if (collector === null) {
        remaining.push(item);
        continue;
      }
      pickups.push({
        collectorId: collector.id,
        faction: collector.faction,
        kind: item.kind,
        x: item.x,
        y: item.y,
        isTeam: isTeamEnabled
      });
      this.pulses.push({
        faction: collector.faction,
        kind: item.kind,
        x: item.x,
        y: item.y,
        startedAtSec: elapsedSec,
        isTeam: isTeamEnabled
      });
      this.pickedCount += 1;
      this.lastPickedCount += 1;
      if (isTeamEnabled) {
        this.teamEffectCount += 1;
        this.lastTeamEffectCount += 1;
      }
    }
    this.items = remaining;
    return pickups;
  }

  lastFramePickedCount(): number {
    return this.lastPickedCount;
  }

  lastFrameTeamEffectCount(): number {
    return this.lastTeamEffectCount;
  }

  activeCount(): number {
    return this.items.length;
  }

  snapshot(): RpsBattlePowerUpState | null {
    if (this.items.length === 0 && this.pulses.length === 0 && this.spawnedCount === 0 && this.pickedCount === 0) {
      return null;
    }
    const items: RpsBattlePowerUp[] = [];
    for (let i = 0; i < this.items.length; i += 1) {
      const item = this.items[i];
      items.push({
        id: item.id,
        kind: item.kind,
        x: item.x,
        y: item.y,
        radius: item.radius,
        expiresAtSec: item.expiresAtSec
      });
    }
    const pulses: RpsBattlePowerUpPulse[] = [];
    for (let i = 0; i < this.pulses.length; i += 1) {
      const pulse = this.pulses[i];
      pulses.push({
        faction: pulse.faction,
        kind: pulse.kind,
        x: pulse.x,
        y: pulse.y,
        startedAtSec: pulse.startedAtSec,
        isTeam: pulse.isTeam
      });
    }
    return {
      items: items,
      pulses: pulses,
      spawnedCount: this.spawnedCount,
      pickedCount: this.pickedCount,
      teamEffectCount: this.teamEffectCount
    };
  }

  private findCollector(item: RpsBattlePowerUp, entities: RpsBattleEntity[]): RpsBattleEntity | null {
    for (let i = 0; i < entities.length; i += 1) {
      const entity = entities[i];
      const dx = item.x - entity.x;
      const dy = item.y - entity.y;
      const pickupDistance = item.radius + entity.radius;
      if (dx * dx + dy * dy <= pickupDistance * pickupDistance) {
        return entity;
      }
    }
    return null;
  }

  private pruneExpiredItems(elapsedSec: number): void {
    if (this.items.length === 0) {
      return;
    }
    const active: RpsBattlePowerUp[] = [];
    for (let i = 0; i < this.items.length; i += 1) {
      if (this.items[i].expiresAtSec > elapsedSec) {
        active.push(this.items[i]);
      }
    }
    this.items = active;
  }

  private prunePulses(elapsedSec: number): void {
    if (this.pulses.length === 0) {
      return;
    }
    const active: RpsBattlePowerUpPulse[] = [];
    for (let i = 0; i < this.pulses.length; i += 1) {
      if (elapsedSec - this.pulses[i].startedAtSec <= RPS_BATTLE_POWER_UP_PULSE_DURATION_SEC) {
        active.push(this.pulses[i]);
      }
    }
    this.pulses = active;
  }

  private randomKind(): RpsBattlePowerUpKind {
    const index = this.spawnedCount % 3;
    if (index === 0) {
      return 'speed';
    }
    if (index === 1) {
      return 'shield';
    }
    return 'split';
  }

  private randomBetween(random: () => number, min: number, max: number): number {
    if (max <= min) {
      return min;
    }
    return min + random() * (max - min);
  }

  private clamp(value: number, min: number, max: number): number {
    if (max <= min) {
      return min;
    }
    return Math.max(min, Math.min(max, value));
  }
}
