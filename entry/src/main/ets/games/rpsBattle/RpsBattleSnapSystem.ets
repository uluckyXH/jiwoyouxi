import {
  RpsBattleEntity,
  RpsBattleFactionCounts,
  RpsBattleSnapState
} from './RpsBattleTypes';

export const RPS_BATTLE_SNAP_WARNING_MIN_SEC: number = 3;
export const RPS_BATTLE_SNAP_WARNING_MAX_SEC: number = 4;
export const RPS_BATTLE_SNAP_WARNING_DURATION_SEC: number = 1.8;
export const RPS_BATTLE_SNAP_RESOLVED_DURATION_SEC: number = 0.8;

export class RpsBattleSnapSystem {
  private state: RpsBattleSnapState | null = null;

  reset(random: () => number): void {
    const warningAtSec = this.randomBetween(random, RPS_BATTLE_SNAP_WARNING_MIN_SEC,
      RPS_BATTLE_SNAP_WARNING_MAX_SEC);
    this.state = {
      phase: 'waiting',
      warningAtSec: warningAtSec,
      resolveAtSec: warningAtSec + RPS_BATTLE_SNAP_WARNING_DURATION_SEC,
      resolvedAtSec: -1,
      removed: this.emptyCounts(),
      totalRemoved: 0
    };
  }

  clear(): void {
    this.state = null;
  }

  update(rockEntities: RpsBattleEntity[], scissorsEntities: RpsBattleEntity[], paperEntities: RpsBattleEntity[],
    elapsedSec: number, random: () => number): number[] {
    if (this.state === null) {
      return [];
    }
    if (this.state.phase === 'waiting' && elapsedSec >= this.state.warningAtSec) {
      this.state.phase = 'warning';
    }
    if (this.state.phase === 'warning' && elapsedSec >= this.state.resolveAtSec) {
      const removedIds = this.collectRandomRemovalIds(rockEntities, scissorsEntities, paperEntities, random);
      this.state.phase = 'resolved';
      this.state.resolvedAtSec = elapsedSec;
      return removedIds;
    }
    if (this.state.phase === 'resolved' &&
      elapsedSec >= this.state.resolvedAtSec + RPS_BATTLE_SNAP_RESOLVED_DURATION_SEC) {
      this.state.phase = 'completed';
    }
    return [];
  }

  currentState(): RpsBattleSnapState | null {
    return this.state;
  }

  snapshot(): RpsBattleSnapState | null {
    if (this.state === null) {
      return null;
    }
    return {
      phase: this.state.phase,
      warningAtSec: this.state.warningAtSec,
      resolveAtSec: this.state.resolveAtSec,
      resolvedAtSec: this.state.resolvedAtSec,
      removed: {
        rock: this.state.removed.rock,
        scissors: this.state.removed.scissors,
        paper: this.state.removed.paper
      },
      totalRemoved: this.state.totalRemoved
    };
  }

  private collectRandomRemovalIds(rockEntities: RpsBattleEntity[], scissorsEntities: RpsBattleEntity[],
    paperEntities: RpsBattleEntity[], random: () => number): number[] {
    const removedIds: number[] = [];
    const removed = this.emptyCounts();
    removed.rock = this.collectFactionRemovalIds(rockEntities, random, removedIds);
    removed.scissors = this.collectFactionRemovalIds(scissorsEntities, random, removedIds);
    removed.paper = this.collectFactionRemovalIds(paperEntities, random, removedIds);
    if (this.state !== null) {
      this.state.removed = removed;
      this.state.totalRemoved = removedIds.length;
    }
    return removedIds;
  }

  private collectFactionRemovalIds(entities: RpsBattleEntity[], random: () => number, target: number[]): number {
    const removalCount = Math.floor(entities.length / 2);
    if (removalCount <= 0) {
      return 0;
    }
    const candidateIds: number[] = [];
    for (let i = 0; i < entities.length; i += 1) {
      candidateIds.push(entities[i].id);
    }
    for (let i = 0; i < removalCount; i += 1) {
      const index = this.randomIndex(random, candidateIds.length);
      target.push(candidateIds[index]);
      const lastIndex = candidateIds.length - 1;
      if (index !== lastIndex) {
        candidateIds[index] = candidateIds[lastIndex];
      }
      candidateIds.pop();
    }
    return removalCount;
  }

  private emptyCounts(): RpsBattleFactionCounts {
    return {
      rock: 0,
      scissors: 0,
      paper: 0
    };
  }

  private randomIndex(random: () => number, length: number): number {
    if (length <= 1) {
      return 0;
    }
    const value = Math.max(0, Math.min(0.999999, random()));
    return Math.floor(value * length);
  }

  private randomBetween(random: () => number, min: number, max: number): number {
    if (max <= min) {
      return min;
    }
    const value = Math.max(0, Math.min(1, random()));
    return min + value * (max - min);
  }
}
