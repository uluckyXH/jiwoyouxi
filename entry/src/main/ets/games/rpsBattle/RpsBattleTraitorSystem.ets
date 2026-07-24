import {
  RPS_BATTLE_LOGICAL_FACTIONS,
  RpsBattleEntity,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleTraitorConversion,
  RpsBattleTraitorMark,
  RpsBattleTraitorPulse,
  RpsBattleTraitorState
} from './RpsBattleTypes';

export const RPS_BATTLE_TRAITOR_DELAY_SEC: number = 2;
export const RPS_BATTLE_TRAITOR_FIRST_AT_SEC: number = 1.2;
export const RPS_BATTLE_TRAITOR_INTERVAL_SEC: number = 6.8;
export const RPS_BATTLE_TRAITOR_EARLY_MIN_SEC: number = 0.8;
export const RPS_BATTLE_TRAITOR_EARLY_MAX_SEC: number = 1.5;
export const RPS_BATTLE_TRAITOR_CLEAR_PROTECTION_SEC: number = 12;
export const RPS_BATTLE_TRAITOR_MAX_CLEAR_RESCUES: number = 2;
export const RPS_BATTLE_TRAITOR_RESCUE_DELAY_SEC: number = 1.2;
export const RPS_BATTLE_TRAITOR_RAGE_DURATION_SEC: number = 0.9;
export const RPS_BATTLE_TRAITOR_PULSE_DURATION_SEC: number = 0.9;

interface RpsBattleEntityPick {
  entityId: number;
  x: number;
  y: number;
}

export class RpsBattleTraitorSystem {
  private marks: RpsBattleTraitorMark[] = [];
  private pulses: RpsBattleTraitorPulse[] = [];
  private nextTraitorAtSec: number = RPS_BATTLE_TRAITOR_FIRST_AT_SEC;
  private earlyTraitorUsed: boolean = false;
  private clearRescueCount: number = 0;
  private markedCount: number = 0;
  private convertedCount: number = 0;
  private lastMarkCount: number = 0;
  private lastConversionCount: number = 0;

  reset(): void {
    this.marks = [];
    this.pulses = [];
    this.nextTraitorAtSec = RPS_BATTLE_TRAITOR_FIRST_AT_SEC;
    this.earlyTraitorUsed = false;
    this.clearRescueCount = 0;
    this.markedCount = 0;
    this.convertedCount = 0;
    this.lastMarkCount = 0;
    this.lastConversionCount = 0;
  }

  clear(): void {
    this.reset();
    this.marks = [];
    this.pulses = [];
  }

  resize(ratioX: number, ratioY: number): void {
    for (let i = 0; i < this.pulses.length; i += 1) {
      const pulse = this.pulses[i];
      pulse.x *= ratioX;
      pulse.y *= ratioY;
    }
  }

  update(entities: RpsBattleEntity[], counts: RpsBattleFactionCounts, elapsedSec: number,
    random: () => number): RpsBattleTraitorConversion[] {
    this.lastMarkCount = 0;
    this.lastConversionCount = 0;
    this.prunePulses(elapsedSec);
    const conversions = this.collectDueConversions(entities, elapsedSec);
    const aliveFactions = this.aliveFactions(counts);
    if (!this.earlyTraitorUsed && elapsedSec >= RPS_BATTLE_TRAITOR_EARLY_MIN_SEC &&
      elapsedSec <= RPS_BATTLE_TRAITOR_EARLY_MAX_SEC && aliveFactions.length >= 2) {
      this.earlyTraitorUsed = true;
      this.queueTraitor(entities, counts, elapsedSec, random, '');
      this.nextTraitorAtSec = elapsedSec + RPS_BATTLE_TRAITOR_INTERVAL_SEC;
      return conversions;
    }
    if (!this.earlyTraitorUsed && elapsedSec > RPS_BATTLE_TRAITOR_EARLY_MAX_SEC) {
      this.earlyTraitorUsed = true;
    }
    if (elapsedSec < RPS_BATTLE_TRAITOR_FIRST_AT_SEC || elapsedSec < this.nextTraitorAtSec) {
      return conversions;
    }
    this.nextTraitorAtSec = elapsedSec + RPS_BATTLE_TRAITOR_INTERVAL_SEC;
    const triggerCount = Math.min(aliveFactions.length, this.markedCount === 0 ? 1 : (random() < 0.5 ? 1 : 2));
    for (let i = 0; i < triggerCount; i += 1) {
      if (aliveFactions.length === 0) {
        break;
      }
      const index = Math.min(aliveFactions.length - 1, Math.floor(random() * aliveFactions.length));
      const faction = aliveFactions[index];
      aliveFactions.splice(index, 1);
      this.queueTraitor(entities, counts, elapsedSec, random, faction);
    }
    return conversions;
  }

  tryQueueClearRescue(entities: RpsBattleEntity[], counts: RpsBattleFactionCounts, elapsedSec: number,
    random: () => number): boolean {
    if (this.hasPendingMarks()) {
      return true;
    }
    if (elapsedSec > RPS_BATTLE_TRAITOR_CLEAR_PROTECTION_SEC ||
      this.clearRescueCount >= RPS_BATTLE_TRAITOR_MAX_CLEAR_RESCUES) {
      return false;
    }
    const aliveFactions = this.aliveFactions(counts);
    if (aliveFactions.length !== 1) {
      return false;
    }
    const fromFaction = aliveFactions[0];
    if (this.countForFaction(counts, fromFaction) < 2) {
      return false;
    }
    const pick = this.pickUnmarkedEntity(entities, fromFaction, random);
    if (pick === null) {
      return false;
    }
    const toFaction = this.clearRescueTargetFaction(fromFaction, counts, random);
    this.marks.push({
      entityId: pick.entityId,
      fromFaction: fromFaction,
      toFaction: toFaction,
      startAtSec: elapsedSec,
      triggerAtSec: elapsedSec + RPS_BATTLE_TRAITOR_RESCUE_DELAY_SEC
    });
    this.clearRescueCount += 1;
    this.markedCount += 1;
    this.lastMarkCount += 1;
    this.earlyTraitorUsed = true;
    this.nextTraitorAtSec = Math.max(this.nextTraitorAtSec, elapsedSec + RPS_BATTLE_TRAITOR_INTERVAL_SEC);
    return true;
  }

  hasPendingMarks(): boolean {
    return this.marks.length > 0;
  }

  activeMarkCount(): number {
    return this.marks.length;
  }

  lastFrameMarkCount(): number {
    return this.lastMarkCount;
  }

  lastFrameConversionCount(): number {
    return this.lastConversionCount;
  }

  clearRescueUsageCount(): number {
    return this.clearRescueCount;
  }

  snapshot(): RpsBattleTraitorState | null {
    if (this.marks.length === 0 && this.pulses.length === 0 && this.markedCount === 0 && this.convertedCount === 0) {
      return null;
    }
    const marks: RpsBattleTraitorMark[] = [];
    for (let i = 0; i < this.marks.length; i += 1) {
      const mark = this.marks[i];
      marks.push({
        entityId: mark.entityId,
        fromFaction: mark.fromFaction,
        toFaction: mark.toFaction,
        startAtSec: mark.startAtSec,
        triggerAtSec: mark.triggerAtSec
      });
    }
    const pulses: RpsBattleTraitorPulse[] = [];
    for (let i = 0; i < this.pulses.length; i += 1) {
      const pulse = this.pulses[i];
      pulses.push({
        entityId: pulse.entityId,
        faction: pulse.faction,
        x: pulse.x,
        y: pulse.y,
        startedAtSec: pulse.startedAtSec
      });
    }
    return {
      marks: marks,
      pulses: pulses,
      markedCount: this.markedCount,
      convertedCount: this.convertedCount
    };
  }

  private collectDueConversions(entities: RpsBattleEntity[], elapsedSec: number): RpsBattleTraitorConversion[] {
    const pending: RpsBattleTraitorMark[] = [];
    const conversions: RpsBattleTraitorConversion[] = [];
    for (let i = 0; i < this.marks.length; i += 1) {
      const mark = this.marks[i];
      const entity = this.findEntity(entities, mark.entityId);
      if (entity === null) {
        continue;
      }
      if (elapsedSec >= mark.triggerAtSec) {
        conversions.push({
          entityId: entity.id,
          fromFaction: mark.fromFaction,
          toFaction: mark.toFaction,
          x: entity.x,
          y: entity.y
        });
        this.pulses.push({
          entityId: entity.id,
          faction: mark.toFaction,
          x: entity.x,
          y: entity.y,
          startedAtSec: elapsedSec
        });
        this.convertedCount += 1;
        this.lastConversionCount += 1;
      } else {
        pending.push(mark);
      }
    }
    this.marks = pending;
    return conversions;
  }

  private queueTraitor(entities: RpsBattleEntity[], counts: RpsBattleFactionCounts, elapsedSec: number,
    random: () => number, forcedFaction: RpsBattleFaction | ''): void {
    const aliveFactions = this.aliveFactions(counts);
    if (aliveFactions.length < 2) {
      return;
    }
    let fromFaction: RpsBattleFaction = aliveFactions[0];
    if (forcedFaction === '') {
      const fromIndex = Math.min(aliveFactions.length - 1, Math.floor(random() * aliveFactions.length));
      fromFaction = aliveFactions[fromIndex];
    } else {
      fromFaction = forcedFaction;
    }
    const pick = this.pickUnmarkedEntity(entities, fromFaction, random);
    if (pick === null) {
      return;
    }
    const toFaction = this.randomOtherFaction(fromFaction, random);
    this.marks.push({
      entityId: pick.entityId,
      fromFaction: fromFaction,
      toFaction: toFaction,
      startAtSec: elapsedSec,
      triggerAtSec: elapsedSec + RPS_BATTLE_TRAITOR_DELAY_SEC
    });
    this.markedCount += 1;
    this.lastMarkCount += 1;
  }

  private pickUnmarkedEntity(entities: RpsBattleEntity[], faction: RpsBattleFaction,
    random: () => number): RpsBattleEntityPick | null {
    let candidateCount = 0;
    for (let i = 0; i < entities.length; i += 1) {
      const entity = entities[i];
      if (entity.faction === faction && !this.hasMarkForEntity(entity.id)) {
        candidateCount += 1;
      }
    }
    if (candidateCount === 0) {
      return null;
    }
    const targetIndex = Math.min(candidateCount - 1, Math.floor(random() * candidateCount));
    let seen = 0;
    for (let i = 0; i < entities.length; i += 1) {
      const entity = entities[i];
      if (entity.faction !== faction || this.hasMarkForEntity(entity.id)) {
        continue;
      }
      if (seen === targetIndex) {
        return {
          entityId: entity.id,
          x: entity.x,
          y: entity.y
        };
      }
      seen += 1;
    }
    return null;
  }

  private randomOtherFaction(fromFaction: RpsBattleFaction, random: () => number): RpsBattleFaction {
    const others: RpsBattleFaction[] = [];
    for (let i = 0; i < RPS_BATTLE_LOGICAL_FACTIONS.length; i += 1) {
      const faction = RPS_BATTLE_LOGICAL_FACTIONS[i];
      if (faction !== fromFaction) {
        others.push(faction);
      }
    }
    const index = Math.min(others.length - 1, Math.floor(random() * others.length));
    return others[index];
  }

  private clearRescueTargetFaction(fromFaction: RpsBattleFaction, counts: RpsBattleFactionCounts,
    random: () => number): RpsBattleFaction {
    const preferred = this.predatorOf(fromFaction);
    if (this.countForFaction(counts, preferred) === 0) {
      return preferred;
    }
    const extinctFactions: RpsBattleFaction[] = [];
    for (let i = 0; i < RPS_BATTLE_LOGICAL_FACTIONS.length; i += 1) {
      const faction = RPS_BATTLE_LOGICAL_FACTIONS[i];
      if (faction !== fromFaction && this.countForFaction(counts, faction) === 0) {
        extinctFactions.push(faction);
      }
    }
    if (extinctFactions.length > 0) {
      const index = Math.min(extinctFactions.length - 1, Math.floor(random() * extinctFactions.length));
      return extinctFactions[index];
    }
    return this.randomOtherFaction(fromFaction, random);
  }

  private predatorOf(faction: RpsBattleFaction): RpsBattleFaction {
    if (faction === 'rock') {
      return 'paper';
    }
    if (faction === 'scissors') {
      return 'rock';
    }
    return 'scissors';
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

  private aliveFactions(counts: RpsBattleFactionCounts): RpsBattleFaction[] {
    const factions: RpsBattleFaction[] = [];
    if (counts.rock > 0) {
      factions.push('rock');
    }
    if (counts.scissors > 0) {
      factions.push('scissors');
    }
    if (counts.paper > 0) {
      factions.push('paper');
    }
    return factions;
  }

  private findEntity(entities: RpsBattleEntity[], entityId: number): RpsBattleEntity | null {
    for (let i = 0; i < entities.length; i += 1) {
      if (entities[i].id === entityId) {
        return entities[i];
      }
    }
    return null;
  }

  private hasMarkForEntity(entityId: number): boolean {
    for (let i = 0; i < this.marks.length; i += 1) {
      if (this.marks[i].entityId === entityId) {
        return true;
      }
    }
    return false;
  }

  private prunePulses(elapsedSec: number): void {
    if (this.pulses.length === 0) {
      return;
    }
    const active: RpsBattleTraitorPulse[] = [];
    for (let i = 0; i < this.pulses.length; i += 1) {
      const pulse = this.pulses[i];
      if (elapsedSec - pulse.startedAtSec < RPS_BATTLE_TRAITOR_PULSE_DURATION_SEC) {
        active.push(pulse);
      }
    }
    this.pulses = active;
  }
}
