import {
  RpsBattleEntity,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleTenAgainstOnePhase,
  RpsBattleTenAgainstOneState
} from './RpsBattleTypes';

export const RPS_BATTLE_TEN_AGAINST_ONE_CHECK_INTERVAL_SEC: number = 0.25;
export const RPS_BATTLE_TEN_AGAINST_ONE_ELIGIBLE_SEC: number = 1;
export const RPS_BATTLE_TEN_AGAINST_ONE_INTRO_SEC: number = 1.2;
export const RPS_BATTLE_TEN_AGAINST_ONE_RAGE_SEC: number = 10;
export const RPS_BATTLE_TEN_AGAINST_ONE_SPEED_MULTIPLIER: number = 1.5;

export class RpsBattleTenAgainstOneSystem {
  private enabled: boolean = false;
  private phase: RpsBattleTenAgainstOnePhase = 'waiting';
  private underdog: RpsBattleFaction | '' = '';
  private majority: RpsBattleFaction | '' = '';
  private eligibleSinceSec: number = -1;
  private introEndsAtSec: number = -1;
  private rageEndsAtSec: number = -1;
  private triggerCount: number = 0;
  private nextCheckAtSec: number = 0;

  reset(enabled: boolean): void {
    this.enabled = enabled;
    this.phase = 'waiting';
    this.underdog = '';
    this.majority = '';
    this.eligibleSinceSec = -1;
    this.introEndsAtSec = -1;
    this.rageEndsAtSec = -1;
    this.triggerCount = 0;
    this.nextCheckAtSec = 0;
  }

  clear(): void {
    this.reset(false);
  }

  update(counts: RpsBattleFactionCounts, elapsedSec: number, durationSec: number): void {
    if (!this.enabled) {
      return;
    }
    if (this.phase === 'intro' && elapsedSec >= this.introEndsAtSec) {
      this.phase = 'rage';
    }
    if (this.phase === 'rage' && elapsedSec >= this.rageEndsAtSec) {
      this.phase = 'completed';
    }
    if (this.phase !== 'waiting' || this.triggerCount > 0 || elapsedSec < this.nextCheckAtSec) {
      return;
    }
    this.nextCheckAtSec = elapsedSec + RPS_BATTLE_TEN_AGAINST_ONE_CHECK_INTERVAL_SEC;
    const underdog = this.eligibleUnderdog(counts);
    if (underdog === '') {
      this.eligibleSinceSec = -1;
      return;
    }
    if (this.eligibleSinceSec < 0) {
      this.eligibleSinceSec = elapsedSec;
      return;
    }
    if (elapsedSec - this.eligibleSinceSec < RPS_BATTLE_TEN_AGAINST_ONE_ELIGIBLE_SEC) {
      return;
    }
    const requiredDuration = RPS_BATTLE_TEN_AGAINST_ONE_INTRO_SEC + RPS_BATTLE_TEN_AGAINST_ONE_RAGE_SEC;
    if (durationSec - elapsedSec < requiredDuration) {
      this.eligibleSinceSec = -1;
      return;
    }
    const majority = this.otherAliveFaction(counts, underdog);
    if (majority === '') {
      this.eligibleSinceSec = -1;
      return;
    }
    this.trigger(underdog, majority, elapsedSec);
  }

  isSimulationFrozen(): boolean {
    return this.phase === 'intro';
  }

  isRagingFaction(faction: RpsBattleFaction): boolean {
    return this.phase === 'rage' && this.underdog === faction;
  }

  rageTargetFaction(): RpsBattleFaction | '' {
    return this.phase === 'rage' ? this.majority : '';
  }

  speedMultiplier(faction: RpsBattleFaction): number {
    return this.isRagingFaction(faction) ? RPS_BATTLE_TEN_AGAINST_ONE_SPEED_MULTIPLIER : 1;
  }

  resolveCollision(a: RpsBattleEntity, b: RpsBattleEntity): RpsBattleEntity | null {
    if (this.phase !== 'rage') {
      return null;
    }
    if (a.faction === this.underdog && b.faction === this.majority) {
      return b;
    }
    if (b.faction === this.underdog && a.faction === this.majority) {
      return a;
    }
    return null;
  }

  isActive(): boolean {
    return this.phase === 'intro' || this.phase === 'rage';
  }

  snapshot(): RpsBattleTenAgainstOneState | null {
    if (!this.enabled) {
      return null;
    }
    return {
      phase: this.phase,
      underdog: this.underdog,
      majority: this.majority,
      eligibleSinceSec: this.eligibleSinceSec,
      introEndsAtSec: this.introEndsAtSec,
      rageEndsAtSec: this.rageEndsAtSec,
      triggerCount: this.triggerCount
    };
  }

  currentState(): RpsBattleTenAgainstOneState | null {
    return this.snapshot();
  }

  private eligibleUnderdog(counts: RpsBattleFactionCounts): RpsBattleFaction | '' {
    const first = this.firstAliveFaction(counts);
    if (first === '') {
      return '';
    }
    const second = this.otherAliveFaction(counts, first);
    if (second === '') {
      return '';
    }
    const firstCount = this.countForFaction(counts, first);
    const secondCount = this.countForFaction(counts, second);
    const underdog = firstCount <= secondCount ? first : second;
    const majority = underdog === first ? second : first;
    const underdogCount = this.countForFaction(counts, underdog);
    const majorityCount = this.countForFaction(counts, majority);
    if (underdogCount <= 0 || majorityCount < underdogCount * 10 || !this.beats(majority, underdog)) {
      return '';
    }
    return underdog;
  }

  private trigger(underdog: RpsBattleFaction, majority: RpsBattleFaction, elapsedSec: number): void {
    this.underdog = underdog;
    this.majority = majority;
    this.phase = 'intro';
    this.introEndsAtSec = elapsedSec + RPS_BATTLE_TEN_AGAINST_ONE_INTRO_SEC;
    this.rageEndsAtSec = this.introEndsAtSec + RPS_BATTLE_TEN_AGAINST_ONE_RAGE_SEC;
    this.triggerCount += 1;
  }

  private firstAliveFaction(counts: RpsBattleFactionCounts): RpsBattleFaction | '' {
    let aliveCount = 0;
    let first: RpsBattleFaction | '' = '';
    if (counts.rock > 0) {
      first = 'rock';
      aliveCount += 1;
    }
    if (counts.scissors > 0) {
      if (first === '') {
        first = 'scissors';
      }
      aliveCount += 1;
    }
    if (counts.paper > 0) {
      if (first === '') {
        first = 'paper';
      }
      aliveCount += 1;
    }
    return aliveCount === 2 ? first : '';
  }

  private otherAliveFaction(counts: RpsBattleFactionCounts, faction: RpsBattleFaction): RpsBattleFaction | '' {
    if (faction !== 'rock' && counts.rock > 0) {
      return 'rock';
    }
    if (faction !== 'scissors' && counts.scissors > 0) {
      return 'scissors';
    }
    if (faction !== 'paper' && counts.paper > 0) {
      return 'paper';
    }
    return '';
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

  private beats(attacker: RpsBattleFaction, defender: RpsBattleFaction): boolean {
    return (attacker === 'rock' && defender === 'scissors') ||
      (attacker === 'scissors' && defender === 'paper') ||
      (attacker === 'paper' && defender === 'rock');
  }
}
