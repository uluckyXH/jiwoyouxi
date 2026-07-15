import { RpsBattleBlackHoleState, RpsBattleEntity } from './RpsBattleTypes';

export const RPS_BATTLE_BLACK_HOLE_INITIAL_RADIUS: number = 24;
export const RPS_BATTLE_BLACK_HOLE_INITIAL_REACH: number = 82;
export const RPS_BATTLE_BLACK_HOLE_MAX_RADIUS: number = 116;
export const RPS_BATTLE_BLACK_HOLE_MAX_REACH: number = 310;

const RPS_BATTLE_BLACK_HOLE_MIN_DELAY_SEC: number = 9;
const RPS_BATTLE_BLACK_HOLE_MAX_DELAY_SEC: number = 16;
const RPS_BATTLE_BLACK_HOLE_FORCE: number = 280;
const RPS_BATTLE_BLACK_HOLE_GROWTH: number = 1.3;
const RPS_BATTLE_BLACK_HOLE_EDGE_MARGIN: number = 70;

export class RpsBattleBlackHoleSystem {
  private state: RpsBattleBlackHoleState | null = null;

  reset(boardWidth: number, boardHeight: number, random: () => number): void {
    this.state = {
      active: false,
      x: boardWidth * 0.5,
      y: boardHeight * 0.5,
      radius: RPS_BATTLE_BLACK_HOLE_INITIAL_RADIUS,
      reach: RPS_BATTLE_BLACK_HOLE_INITIAL_REACH,
      nextAtSec: this.randomBetween(random, RPS_BATTLE_BLACK_HOLE_MIN_DELAY_SEC, RPS_BATTLE_BLACK_HOLE_MAX_DELAY_SEC),
      swallowed: 0
    };
  }

  clear(): void {
    this.state = null;
  }

  resize(boardWidth: number, boardHeight: number): void {
    if (this.state === null || !this.state.active) {
      return;
    }
    const marginX = this.edgeMargin(boardWidth);
    const marginY = this.edgeMargin(boardHeight);
    this.state.x = this.clamp(this.state.x, marginX, boardWidth - marginX);
    this.state.y = this.clamp(this.state.y, marginY, boardHeight - marginY);
  }

  update(entities: RpsBattleEntity[], elapsedSec: number, dtSec: number, boardWidth: number, boardHeight: number,
    random: () => number): RpsBattleEntity[] {
    if (this.state === null) {
      return [];
    }
    if (!this.state.active && elapsedSec >= this.state.nextAtSec) {
      this.activate(boardWidth, boardHeight, random);
    }
    if (!this.state.active) {
      return [];
    }
    const swallowed: RpsBattleEntity[] = [];
    const state = this.state;
    for (let i = 0; i < entities.length; i += 1) {
      const entity = entities[i];
      const dx = state.x - entity.x;
      const dy = state.y - entity.y;
      const distance = Math.max(1, Math.sqrt(dx * dx + dy * dy));
      const reach = Math.max(1, state.reach);
      if (distance > reach) {
        continue;
      }
      const force = (1 - distance / reach) * RPS_BATTLE_BLACK_HOLE_FORCE;
      entity.vx += dx / distance * force * dtSec;
      entity.vy += dy / distance * force * dtSec;
      if (distance < state.radius + entity.radius * 0.35) {
        swallowed.push(entity);
        this.grow(1);
      }
    }
    return swallowed;
  }

  currentState(): RpsBattleBlackHoleState | null {
    return this.state;
  }

  snapshot(): RpsBattleBlackHoleState | null {
    if (this.state === null) {
      return null;
    }
    return {
      active: this.state.active,
      x: this.state.x,
      y: this.state.y,
      radius: this.state.radius,
      reach: this.state.reach,
      nextAtSec: this.state.nextAtSec,
      swallowed: this.state.swallowed
    };
  }

  private activate(boardWidth: number, boardHeight: number, random: () => number): void {
    if (this.state === null) {
      return;
    }
    const marginX = this.edgeMargin(boardWidth);
    const marginY = this.edgeMargin(boardHeight);
    this.state.active = true;
    this.state.x = this.randomBetween(random, marginX, boardWidth - marginX);
    this.state.y = this.randomBetween(random, marginY, boardHeight - marginY);
    this.state.radius = RPS_BATTLE_BLACK_HOLE_INITIAL_RADIUS;
    this.state.reach = RPS_BATTLE_BLACK_HOLE_INITIAL_REACH;
  }

  private grow(swallowedCount: number): void {
    if (this.state === null || swallowedCount <= 0) {
      return;
    }
    for (let i = 0; i < swallowedCount; i += 1) {
      this.state.radius = Math.min(this.state.radius * RPS_BATTLE_BLACK_HOLE_GROWTH, RPS_BATTLE_BLACK_HOLE_MAX_RADIUS);
      this.state.reach = Math.min(this.state.reach * RPS_BATTLE_BLACK_HOLE_GROWTH, RPS_BATTLE_BLACK_HOLE_MAX_REACH);
    }
    this.state.swallowed += swallowedCount;
  }

  private edgeMargin(size: number): number {
    return Math.min(RPS_BATTLE_BLACK_HOLE_EDGE_MARGIN, Math.max(24, size * 0.22));
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
