import {
  RpsBattleBountyRewardPulse,
  RpsBattleBountyState,
  RpsBattleFaction,
  RpsBattleFactionCounts
} from './RpsBattleTypes';

export const RPS_BATTLE_BOUNTY_WARMUP_SEC: number = 5;
export const RPS_BATTLE_BOUNTY_CHECK_INTERVAL_SEC: number = 0.5;
export const RPS_BATTLE_BOUNTY_MIN_TOTAL: number = 12;
export const RPS_BATTLE_BOUNTY_MIN_SHARE: number = 0.54;
export const RPS_BATTLE_BOUNTY_MIN_LEAD: number = 4;
export const RPS_BATTLE_BOUNTY_LEAD_SHARE: number = 0.18;
export const RPS_BATTLE_BOUNTY_PULSE_DURATION_SEC: number = 0.72;

export class RpsBattleBountySystem {
  private enabled: boolean = false;
  private active: boolean = false;
  private leader: RpsBattleFaction | '' = '';
  private nextCheckAtSec: number = RPS_BATTLE_BOUNTY_WARMUP_SEC;
  private rewardCount: number = 0;
  private pulses: RpsBattleBountyRewardPulse[] = [];

  reset(enabled: boolean): void {
    this.enabled = enabled;
    this.active = false;
    this.leader = '';
    this.nextCheckAtSec = RPS_BATTLE_BOUNTY_WARMUP_SEC;
    this.rewardCount = 0;
    this.pulses = [];
  }

  clear(): void {
    this.reset(false);
  }

  update(counts: RpsBattleFactionCounts, elapsedSec: number): void {
    this.prunePulses(elapsedSec);
    if (!this.enabled || elapsedSec < this.nextCheckAtSec) {
      return;
    }
    this.nextCheckAtSec = elapsedSec + RPS_BATTLE_BOUNTY_CHECK_INTERVAL_SEC;
    const total = counts.rock + counts.scissors + counts.paper;
    if (total < RPS_BATTLE_BOUNTY_MIN_TOTAL) {
      this.deactivate();
      return;
    }
    const leader = this.uniqueLeader(counts);
    if (leader === '') {
      this.deactivate();
      return;
    }
    const leaderCount = this.countForFaction(counts, leader);
    const secondCount = this.secondCount(counts, leader);
    const requiredLead = Math.max(RPS_BATTLE_BOUNTY_MIN_LEAD, Math.ceil(total * RPS_BATTLE_BOUNTY_LEAD_SHARE));
    if (leaderCount / total < RPS_BATTLE_BOUNTY_MIN_SHARE || leaderCount - secondCount < requiredLead) {
      this.deactivate();
      return;
    }
    this.active = true;
    this.leader = leader;
  }

  isLeader(faction: RpsBattleFaction): boolean {
    return this.active && this.leader === faction;
  }

  shouldHunt(faction: RpsBattleFaction): boolean {
    return this.active && faction !== this.leader;
  }

  leaderFaction(): RpsBattleFaction | '' {
    return this.leader;
  }

  registerReward(fromFaction: RpsBattleFaction, faction: RpsBattleFaction, x: number, y: number,
    elapsedSec: number): boolean {
    if (!this.isLeader(fromFaction)) {
      return false;
    }
    this.rewardCount += 1;
    this.pulses.push({
      faction: faction,
      x: x,
      y: y,
      startedAtSec: elapsedSec
    });
    return true;
  }

  isActive(): boolean {
    return this.active;
  }

  snapshot(): RpsBattleBountyState | null {
    if (!this.enabled) {
      return null;
    }
    const pulses: RpsBattleBountyRewardPulse[] = [];
    for (let i = 0; i < this.pulses.length; i += 1) {
      const pulse = this.pulses[i];
      pulses.push({
        faction: pulse.faction,
        x: pulse.x,
        y: pulse.y,
        startedAtSec: pulse.startedAtSec
      });
    }
    return {
      active: this.active,
      leader: this.leader,
      rewardCount: this.rewardCount,
      pulses: pulses
    };
  }

  currentState(): RpsBattleBountyState | null {
    if (!this.enabled) {
      return null;
    }
    return {
      active: this.active,
      leader: this.leader,
      rewardCount: this.rewardCount,
      pulses: this.pulses
    };
  }

  private deactivate(): void {
    this.active = false;
    this.leader = '';
  }

  private uniqueLeader(counts: RpsBattleFactionCounts): RpsBattleFaction | '' {
    let leader: RpsBattleFaction = 'rock';
    let highest = counts.rock;
    let tied = false;
    if (counts.scissors > highest) {
      leader = 'scissors';
      highest = counts.scissors;
      tied = false;
    } else if (counts.scissors === highest) {
      tied = true;
    }
    if (counts.paper > highest) {
      leader = 'paper';
      tied = false;
    } else if (counts.paper === highest) {
      tied = true;
    }
    return tied ? '' : leader;
  }

  private secondCount(counts: RpsBattleFactionCounts, leader: RpsBattleFaction): number {
    if (leader === 'rock') {
      return Math.max(counts.scissors, counts.paper);
    }
    if (leader === 'scissors') {
      return Math.max(counts.rock, counts.paper);
    }
    return Math.max(counts.rock, counts.scissors);
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

  private prunePulses(elapsedSec: number): void {
    if (this.pulses.length === 0) {
      return;
    }
    const activePulses: RpsBattleBountyRewardPulse[] = [];
    for (let i = 0; i < this.pulses.length; i += 1) {
      const pulse = this.pulses[i];
      if (elapsedSec - pulse.startedAtSec < RPS_BATTLE_BOUNTY_PULSE_DURATION_SEC) {
        activePulses.push(pulse);
      }
    }
    this.pulses = activePulses;
  }
}
