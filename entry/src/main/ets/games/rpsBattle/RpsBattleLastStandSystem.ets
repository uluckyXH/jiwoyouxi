import {
  RPS_BATTLE_LOGICAL_FACTIONS,
  RpsBattleEntity,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleLastStandPulse,
  RpsBattleLastStandState,
  RpsBattleReviveMark,
  RpsBattleSpawnRequest
} from './RpsBattleTypes';

export const RPS_BATTLE_LAST_STAND_SPLIT_INTERVAL_SEC: number = 1;
export const RPS_BATTLE_LAST_STAND_SPLIT_CHANCE: number = 0.66;
export const RPS_BATTLE_LAST_STAND_REVIVE_TRIGGER_COUNT: number = 3;
export const RPS_BATTLE_LAST_STAND_REVIVE_CHANCE: number = 1;
export const RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC: number = 2.2;
export const RPS_BATTLE_LAST_STAND_REINFORCEMENT_COOLDOWN_SEC: number = 5;
export const RPS_BATTLE_LAST_STAND_SPLIT_OFFSET: number = 18;
export const RPS_BATTLE_LAST_STAND_PULSE_DURATION_SEC: number = 0.9;

const RPS_BATTLE_LAST_STAND_ENTITY_MARGIN: number = 18;
const RPS_BATTLE_LAST_STAND_SPLIT_SPEED_SCALE: number = 0.94;
const RPS_BATTLE_LAST_STAND_REVIVE_SPEED_SCALE: number = 1.18;

export class RpsBattleLastStandSystem {
  private splitUsed: boolean[] = [false, false, false];
  private nextSplitCheckAtSec: number[] = [0, 0, 0];
  private nextReviveCheckAtSec: number[] = [0, 0, 0];
  private hasSeenFaction: boolean[] = [false, false, false];
  private previousCounts: RpsBattleFactionCounts = { rock: 0, scissors: 0, paper: 0 };
  private lastX: number[] = [0, 0, 0];
  private lastY: number[] = [0, 0, 0];
  private reviveMarks: RpsBattleReviveMark[] = [];
  private pulses: RpsBattleLastStandPulse[] = [];
  private splitCount: number = 0;
  private reviveCount: number = 0;
  private lastEventCount: number = 0;
  private lastReviveCount: number = 0;

  reset(entities: RpsBattleEntity[], counts: RpsBattleFactionCounts, boardWidth: number, boardHeight: number): void {
    this.splitUsed = [false, false, false];
    this.nextSplitCheckAtSec = [0, 0, 0];
    this.nextReviveCheckAtSec = [0, 0, 0];
    this.hasSeenFaction = [counts.rock > 0, counts.scissors > 0, counts.paper > 0];
    this.previousCounts = this.cloneCounts(counts);
    this.lastX = [boardWidth * 0.5, boardWidth * 0.5, boardWidth * 0.5];
    this.lastY = [boardHeight * 0.5, boardHeight * 0.5, boardHeight * 0.5];
    this.reviveMarks = [];
    this.pulses = [];
    this.splitCount = 0;
    this.reviveCount = 0;
    this.lastEventCount = 0;
    this.lastReviveCount = 0;
    this.updateLastPositions(entities);
  }

  clear(): void {
    this.reviveMarks = [];
    this.pulses = [];
    this.previousCounts = { rock: 0, scissors: 0, paper: 0 };
    this.splitUsed = [false, false, false];
    this.nextSplitCheckAtSec = [0, 0, 0];
    this.nextReviveCheckAtSec = [0, 0, 0];
    this.hasSeenFaction = [false, false, false];
    this.splitCount = 0;
    this.reviveCount = 0;
    this.lastEventCount = 0;
    this.lastReviveCount = 0;
  }

  resize(ratioX: number, ratioY: number, boardWidth: number, boardHeight: number): void {
    for (let i = 0; i < this.lastX.length; i += 1) {
      this.lastX[i] = this.clamp(this.lastX[i] * ratioX, RPS_BATTLE_LAST_STAND_ENTITY_MARGIN,
        boardWidth - RPS_BATTLE_LAST_STAND_ENTITY_MARGIN);
      this.lastY[i] = this.clamp(this.lastY[i] * ratioY, RPS_BATTLE_LAST_STAND_ENTITY_MARGIN,
        boardHeight - RPS_BATTLE_LAST_STAND_ENTITY_MARGIN);
    }
    for (let i = 0; i < this.reviveMarks.length; i += 1) {
      const mark = this.reviveMarks[i];
      mark.x = this.clamp(mark.x * ratioX, RPS_BATTLE_LAST_STAND_ENTITY_MARGIN,
        boardWidth - RPS_BATTLE_LAST_STAND_ENTITY_MARGIN);
      mark.y = this.clamp(mark.y * ratioY, RPS_BATTLE_LAST_STAND_ENTITY_MARGIN,
        boardHeight - RPS_BATTLE_LAST_STAND_ENTITY_MARGIN);
    }
    for (let i = 0; i < this.pulses.length; i += 1) {
      const pulse = this.pulses[i];
      pulse.x = this.clamp(pulse.x * ratioX, RPS_BATTLE_LAST_STAND_ENTITY_MARGIN,
        boardWidth - RPS_BATTLE_LAST_STAND_ENTITY_MARGIN);
      pulse.y = this.clamp(pulse.y * ratioY, RPS_BATTLE_LAST_STAND_ENTITY_MARGIN,
        boardHeight - RPS_BATTLE_LAST_STAND_ENTITY_MARGIN);
    }
  }

  update(entities: RpsBattleEntity[], counts: RpsBattleFactionCounts, elapsedSec: number, boardWidth: number,
    boardHeight: number, random: () => number): RpsBattleSpawnRequest[] {
    this.lastEventCount = 0;
    this.lastReviveCount = 0;
    this.updateLastPositions(entities);
    this.prunePulses(elapsedSec);
    const requests: RpsBattleSpawnRequest[] = [];
    this.collectDueRevives(elapsedSec, requests);
    this.trySplit(entities, counts, elapsedSec, boardWidth, boardHeight, random, requests);
    this.tryCreateReviveMarks(counts, elapsedSec, random);
    return requests;
  }

  completeFrame(entities: RpsBattleEntity[], counts: RpsBattleFactionCounts): void {
    this.previousCounts = this.cloneCounts(counts);
    this.updateLastPositions(entities);
  }

  hasPendingReviveMarks(): boolean {
    return this.reviveMarks.length > 0;
  }

  lastFrameEventCount(): number {
    return this.lastEventCount;
  }

  lastFrameReviveCount(): number {
    return this.lastReviveCount;
  }

  snapshot(): RpsBattleLastStandState | null {
    if (this.reviveMarks.length === 0 && this.pulses.length === 0 && this.splitCount === 0 && this.reviveCount === 0) {
      return null;
    }
    const marks: RpsBattleReviveMark[] = [];
    for (let i = 0; i < this.reviveMarks.length; i += 1) {
      const mark = this.reviveMarks[i];
      marks.push({
        faction: mark.faction,
        x: mark.x,
        y: mark.y,
        createdAtSec: mark.createdAtSec,
        dueAtSec: mark.dueAtSec
      });
    }
    const pulses: RpsBattleLastStandPulse[] = [];
    for (let i = 0; i < this.pulses.length; i += 1) {
      const pulse = this.pulses[i];
      pulses.push({
        faction: pulse.faction,
        x: pulse.x,
        y: pulse.y,
        startedAtSec: pulse.startedAtSec,
        kind: pulse.kind
      });
    }
    return {
      reviveMarks: marks,
      pulses: pulses,
      splitCount: this.splitCount,
      reviveCount: this.reviveCount
    };
  }

  private collectDueRevives(elapsedSec: number, requests: RpsBattleSpawnRequest[]): void {
    if (this.reviveMarks.length === 0) {
      return;
    }
    const pending: RpsBattleReviveMark[] = [];
    for (let i = 0; i < this.reviveMarks.length; i += 1) {
      const mark = this.reviveMarks[i];
      if (elapsedSec >= mark.dueAtSec) {
        const factionIndex = this.factionIndex(mark.faction);
        this.nextReviveCheckAtSec[factionIndex] = Math.max(this.nextReviveCheckAtSec[factionIndex],
          elapsedSec + RPS_BATTLE_LAST_STAND_REINFORCEMENT_COOLDOWN_SEC);
        requests.push({
          faction: mark.faction,
          x: mark.x,
          y: mark.y,
          speedScale: RPS_BATTLE_LAST_STAND_REVIVE_SPEED_SCALE,
          eventKind: 'revive'
        });
        this.reviveCount += 1;
        this.lastEventCount += 1;
        this.lastReviveCount += 1;
        this.pulses.push({
          faction: mark.faction,
          x: mark.x,
          y: mark.y,
          startedAtSec: elapsedSec,
          kind: 'revive'
        });
      } else {
        pending.push(mark);
      }
    }
    this.reviveMarks = pending;
  }

  private trySplit(entities: RpsBattleEntity[], counts: RpsBattleFactionCounts, elapsedSec: number,
    boardWidth: number, boardHeight: number, random: () => number, requests: RpsBattleSpawnRequest[]): void {
    for (let i = 0; i < RPS_BATTLE_LOGICAL_FACTIONS.length; i += 1) {
      const faction = RPS_BATTLE_LOGICAL_FACTIONS[i];
      if (this.countForFaction(counts, faction) !== 1 || this.splitUsed[i] || elapsedSec < this.nextSplitCheckAtSec[i]) {
        continue;
      }
      this.nextSplitCheckAtSec[i] = elapsedSec + RPS_BATTLE_LAST_STAND_SPLIT_INTERVAL_SEC;
      if (random() >= RPS_BATTLE_LAST_STAND_SPLIT_CHANCE) {
        continue;
      }
      const source = this.findSingleEntity(entities, faction);
      if (source === null) {
        continue;
      }
      const x = this.clamp(source.x + this.randomOffset(random), RPS_BATTLE_LAST_STAND_ENTITY_MARGIN,
        boardWidth - RPS_BATTLE_LAST_STAND_ENTITY_MARGIN);
      const y = this.clamp(source.y + this.randomOffset(random), RPS_BATTLE_LAST_STAND_ENTITY_MARGIN,
        boardHeight - RPS_BATTLE_LAST_STAND_ENTITY_MARGIN);
      requests.push({
        faction: faction,
        x: x,
        y: y,
        speedScale: RPS_BATTLE_LAST_STAND_SPLIT_SPEED_SCALE,
        eventKind: 'split'
      });
      this.splitUsed[i] = true;
      this.splitCount += 1;
      this.lastEventCount += 1;
      this.pulses.push({
        faction: faction,
        x: source.x,
        y: source.y,
        startedAtSec: elapsedSec,
        kind: 'split'
      });
    }
  }

  private tryCreateReviveMarks(counts: RpsBattleFactionCounts, elapsedSec: number, random: () => number): void {
    for (let i = 0; i < RPS_BATTLE_LOGICAL_FACTIONS.length; i += 1) {
      const faction = RPS_BATTLE_LOGICAL_FACTIONS[i];
      const currentCount = this.countForFaction(counts, faction);
      const previousCount = this.countForFaction(this.previousCounts, faction);
      const hasDecreased = previousCount > currentCount;
      const isWipedOut = currentCount === 0;
      if (!this.hasSeenFaction[i] || currentCount > RPS_BATTLE_LAST_STAND_REVIVE_TRIGGER_COUNT ||
        (!hasDecreased && !isWipedOut) || elapsedSec < this.nextReviveCheckAtSec[i] ||
        this.hasPendingReviveMarkForFaction(faction)) {
        continue;
      }
      if (random() >= RPS_BATTLE_LAST_STAND_REVIVE_CHANCE) {
        continue;
      }
      this.nextReviveCheckAtSec[i] = elapsedSec + RPS_BATTLE_LAST_STAND_REINFORCEMENT_COOLDOWN_SEC;
      this.reviveMarks.push({
        faction: faction,
        x: this.lastX[i],
        y: this.lastY[i],
        createdAtSec: elapsedSec,
        dueAtSec: elapsedSec + RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC
      });
      this.pulses.push({
        faction: faction,
        x: this.lastX[i],
        y: this.lastY[i],
        startedAtSec: elapsedSec,
        kind: 'reviveMark'
      });
      this.lastEventCount += 1;
    }
  }

  private hasPendingReviveMarkForFaction(faction: RpsBattleFaction): boolean {
    for (let i = 0; i < this.reviveMarks.length; i += 1) {
      if (this.reviveMarks[i].faction === faction) {
        return true;
      }
    }
    return false;
  }

  private updateLastPositions(entities: RpsBattleEntity[]): void {
    for (let i = 0; i < entities.length; i += 1) {
      const entity = entities[i];
      const index = this.factionIndex(entity.faction);
      this.hasSeenFaction[index] = true;
      this.lastX[index] = entity.x;
      this.lastY[index] = entity.y;
    }
  }

  private prunePulses(elapsedSec: number): void {
    if (this.pulses.length === 0) {
      return;
    }
    const active: RpsBattleLastStandPulse[] = [];
    for (let i = 0; i < this.pulses.length; i += 1) {
      if (elapsedSec - this.pulses[i].startedAtSec <= RPS_BATTLE_LAST_STAND_PULSE_DURATION_SEC) {
        active.push(this.pulses[i]);
      }
    }
    this.pulses = active;
  }

  private findSingleEntity(entities: RpsBattleEntity[], faction: RpsBattleFaction): RpsBattleEntity | null {
    for (let i = 0; i < entities.length; i += 1) {
      if (entities[i].faction === faction) {
        return entities[i];
      }
    }
    return null;
  }

  private randomOffset(random: () => number): number {
    return (random() * 2 - 1) * RPS_BATTLE_LAST_STAND_SPLIT_OFFSET;
  }

  private countForFaction(counts: RpsBattleFactionCounts, faction: RpsBattleFaction): number {
    if (faction === 'rock') {
      return counts.rock;
    }
    if (faction === 'scissors') {
      return counts.scissors;
    }
    return counts.paper;
  }

  private cloneCounts(counts: RpsBattleFactionCounts): RpsBattleFactionCounts {
    return {
      rock: counts.rock,
      scissors: counts.scissors,
      paper: counts.paper
    };
  }

  private factionIndex(faction: RpsBattleFaction): number {
    if (faction === 'rock') {
      return 0;
    }
    if (faction === 'scissors') {
      return 1;
    }
    return 2;
  }

  private clamp(value: number, min: number, max: number): number {
    if (max <= min) {
      return min;
    }
    return Math.max(min, Math.min(max, value));
  }
}
