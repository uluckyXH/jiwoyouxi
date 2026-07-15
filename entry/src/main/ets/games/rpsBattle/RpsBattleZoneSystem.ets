import {
  RpsBattleControlZone,
  RpsBattleEntity,
  RpsBattleFaction,
  RpsBattleFactionCounts
} from './RpsBattleTypes';
import { rpsBattleEmptyCounts } from './RpsBattleRules';

export const RPS_BATTLE_CONTROL_ZONE_MAX_SCORE: number = 100;

const RPS_BATTLE_CONTROL_ZONE_SCORE_PER_ENTITY_SEC: number = 2.8;
const RPS_BATTLE_CONTROL_ZONE_MIN_RADIUS: number = 44;
const RPS_BATTLE_CONTROL_ZONE_MAX_RADIUS: number = 62;
const RPS_BATTLE_CONTROL_ZONE_RADIUS_RATIO: number = 0.15;

export class RpsBattleZoneSystem {
  private zone: RpsBattleControlZone | null = null;

  reset(boardWidth: number, boardHeight: number): void {
    const radius = this.resolveRadius(boardWidth, boardHeight);
    this.zone = {
      x: boardWidth * 0.5,
      y: boardHeight * 0.5,
      radius: radius,
      owner: '',
      capturingFaction: '',
      score: 0,
      pressure: rpsBattleEmptyCounts()
    };
  }

  clear(): void {
    this.zone = null;
  }

  resize(boardWidth: number, boardHeight: number): void {
    if (this.zone === null) {
      return;
    }
    this.zone.x = boardWidth * 0.5;
    this.zone.y = boardHeight * 0.5;
    this.zone.radius = this.resolveRadius(boardWidth, boardHeight);
  }

  update(entities: RpsBattleEntity[], dtSec: number): number {
    if (this.zone === null) {
      return 0;
    }
    const zone = this.zone;
    const pressure = zone.pressure;
    pressure.rock = 0;
    pressure.scissors = 0;
    pressure.paper = 0;
    const radiusSq = zone.radius * zone.radius;
    for (let i = 0; i < entities.length; i += 1) {
      const entity = entities[i];
      const dx = entity.x - zone.x;
      const dy = entity.y - zone.y;
      if (dx * dx + dy * dy <= radiusSq) {
        this.addPressure(pressure, entity.faction);
      }
    }
    const capturingFaction = this.uniquePressureLeader(pressure);
    zone.capturingFaction = capturingFaction;
    if (capturingFaction !== '') {
      zone.owner = capturingFaction;
      const ownerPressure = this.pressureValue(pressure, capturingFaction);
      zone.score = Math.min(
        RPS_BATTLE_CONTROL_ZONE_MAX_SCORE,
        zone.score + ownerPressure * RPS_BATTLE_CONTROL_ZONE_SCORE_PER_ENTITY_SEC * dtSec
      );
    }
    return pressure.rock + pressure.scissors + pressure.paper;
  }

  finishWinner(): RpsBattleFaction | '' {
    if (this.zone === null || this.zone.owner === '') {
      return '';
    }
    return this.zone.score >= RPS_BATTLE_CONTROL_ZONE_MAX_SCORE ? this.zone.owner : '';
  }

  currentZone(): RpsBattleControlZone | null {
    return this.zone;
  }

  snapshot(): RpsBattleControlZone | null {
    if (this.zone === null) {
      return null;
    }
    return {
      x: this.zone.x,
      y: this.zone.y,
      radius: this.zone.radius,
      owner: this.zone.owner,
      capturingFaction: this.zone.capturingFaction,
      score: this.zone.score,
      pressure: {
        rock: this.zone.pressure.rock,
        scissors: this.zone.pressure.scissors,
        paper: this.zone.pressure.paper
      }
    };
  }

  private resolveRadius(boardWidth: number, boardHeight: number): number {
    return this.clamp(
      Math.min(boardWidth, boardHeight) * RPS_BATTLE_CONTROL_ZONE_RADIUS_RATIO,
      RPS_BATTLE_CONTROL_ZONE_MIN_RADIUS,
      RPS_BATTLE_CONTROL_ZONE_MAX_RADIUS
    );
  }

  private addPressure(pressure: RpsBattleFactionCounts, faction: RpsBattleFaction): void {
    if (faction === 'rock') {
      pressure.rock += 1;
    } else if (faction === 'scissors') {
      pressure.scissors += 1;
    } else {
      pressure.paper += 1;
    }
  }

  private uniquePressureLeader(pressure: RpsBattleFactionCounts): RpsBattleFaction | '' {
    let leader: RpsBattleFaction | '' = '';
    let max = 0;
    let tied = false;
    if (pressure.rock > max) {
      leader = 'rock';
      max = pressure.rock;
      tied = false;
    } else if (pressure.rock === max && max > 0) {
      tied = true;
    }
    if (pressure.scissors > max) {
      leader = 'scissors';
      max = pressure.scissors;
      tied = false;
    } else if (pressure.scissors === max && max > 0) {
      tied = true;
    }
    if (pressure.paper > max) {
      leader = 'paper';
      max = pressure.paper;
      tied = false;
    } else if (pressure.paper === max && max > 0) {
      tied = true;
    }
    if (max <= 0 || tied) {
      return '';
    }
    return leader;
  }

  private pressureValue(pressure: RpsBattleFactionCounts, faction: RpsBattleFaction): number {
    if (faction === 'rock') {
      return pressure.rock;
    }
    if (faction === 'scissors') {
      return pressure.scissors;
    }
    return pressure.paper;
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
  }
}
