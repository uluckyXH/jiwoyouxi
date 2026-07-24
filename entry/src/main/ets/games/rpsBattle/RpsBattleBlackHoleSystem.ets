import { RpsBattleBlackHoleState, RpsBattleEntity, RpsBattleShrinkBounds } from './RpsBattleTypes';

export const RPS_BATTLE_BLACK_HOLE_INITIAL_RADIUS: number = 24;
export const RPS_BATTLE_BLACK_HOLE_INITIAL_REACH: number = 82;
export const RPS_BATTLE_BLACK_HOLE_MAX_RADIUS: number = 116;
export const RPS_BATTLE_BLACK_HOLE_MAX_REACH: number = 310;
export const RPS_BATTLE_BLACK_HOLE_MAX_RADIUS_RATIO: number = 0.16;
export const RPS_BATTLE_BLACK_HOLE_MAX_REACH_RATIO: number = 0.42;

export const RPS_BATTLE_BLACK_HOLE_MIN_DELAY_SEC: number = 9;
export const RPS_BATTLE_BLACK_HOLE_MAX_DELAY_SEC: number = 16;
export const RPS_BATTLE_BLACK_HOLE_TRAITOR_MIN_DELAY_SEC: number = 6;
export const RPS_BATTLE_BLACK_HOLE_TRAITOR_MAX_DELAY_SEC: number = 10;
const RPS_BATTLE_BLACK_HOLE_FORCE: number = 280;
const RPS_BATTLE_BLACK_HOLE_GROWTH: number = 1.3;
const RPS_BATTLE_BLACK_HOLE_EDGE_MARGIN: number = 70;
const RPS_BATTLE_BLACK_HOLE_CENTER_SAFE_PADDING: number = 8;
const RPS_BATTLE_BLACK_HOLE_ACTIVATE_ATTEMPTS: number = 8;

export function rpsBattleBlackHoleMaxRadiusForBoard(boardWidth: number, boardHeight: number): number {
  const shortSide = Math.max(1, Math.min(boardWidth, boardHeight));
  return Math.max(
    RPS_BATTLE_BLACK_HOLE_INITIAL_RADIUS,
    Math.min(RPS_BATTLE_BLACK_HOLE_MAX_RADIUS, shortSide * RPS_BATTLE_BLACK_HOLE_MAX_RADIUS_RATIO)
  );
}

export function rpsBattleBlackHoleMaxReachForBoard(boardWidth: number, boardHeight: number): number {
  const shortSide = Math.max(1, Math.min(boardWidth, boardHeight));
  return Math.max(
    RPS_BATTLE_BLACK_HOLE_INITIAL_REACH,
    Math.min(RPS_BATTLE_BLACK_HOLE_MAX_REACH, shortSide * RPS_BATTLE_BLACK_HOLE_MAX_REACH_RATIO)
  );
}

export class RpsBattleBlackHoleSystem {
  private state: RpsBattleBlackHoleState | null = null;

  reset(boardWidth: number, boardHeight: number, random: () => number,
    minDelaySec: number = RPS_BATTLE_BLACK_HOLE_MIN_DELAY_SEC,
    maxDelaySec: number = RPS_BATTLE_BLACK_HOLE_MAX_DELAY_SEC): void {
    this.state = {
      active: false,
      x: boardWidth * 0.5,
      y: boardHeight * 0.5,
      radius: RPS_BATTLE_BLACK_HOLE_INITIAL_RADIUS,
      reach: RPS_BATTLE_BLACK_HOLE_INITIAL_REACH,
      nextAtSec: this.randomBetween(random, minDelaySec, maxDelaySec),
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
    this.applyDynamicCaps(boardWidth, boardHeight);
    const marginX = this.edgeMargin(boardWidth);
    const marginY = this.edgeMargin(boardHeight);
    this.state.x = this.clamp(this.state.x, marginX, boardWidth - marginX);
    this.state.y = this.clamp(this.state.y, marginY, boardHeight - marginY);
  }

  update(entities: RpsBattleEntity[], elapsedSec: number, dtSec: number, boardWidth: number, boardHeight: number,
    random: () => number, avoidX: number = -1, avoidY: number = -1, avoidRadius: number = 0,
    safeBounds: RpsBattleShrinkBounds | null = null): RpsBattleEntity[] {
    if (this.state === null) {
      return [];
    }
    if (!this.state.active && elapsedSec >= this.state.nextAtSec) {
      this.activate(boardWidth, boardHeight, random, avoidX, avoidY, avoidRadius, safeBounds);
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
        this.grow(1, boardWidth, boardHeight);
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

  private activate(boardWidth: number, boardHeight: number, random: () => number,
    avoidX: number, avoidY: number, avoidRadius: number, safeBounds: RpsBattleShrinkBounds | null): void {
    if (this.state === null) {
      return;
    }
    const safeLeft = safeBounds === null ? 0 : safeBounds.left;
    const safeTop = safeBounds === null ? 0 : safeBounds.top;
    const safeRight = safeBounds === null ? boardWidth : safeBounds.right;
    const safeBottom = safeBounds === null ? boardHeight : safeBounds.bottom;
    const safeWidth = Math.max(1, safeRight - safeLeft);
    const safeHeight = Math.max(1, safeBottom - safeTop);
    const marginX = Math.min(this.edgeMargin(boardWidth), Math.max(12, safeWidth * 0.32));
    const marginY = Math.min(this.edgeMargin(boardHeight), Math.max(12, safeHeight * 0.32));
    const minX = safeLeft + marginX;
    const maxX = safeRight - marginX;
    const minY = safeTop + marginY;
    const maxY = safeBottom - marginY;
    let x = boardWidth * 0.5;
    let y = boardHeight * 0.5;
    for (let i = 0; i < RPS_BATTLE_BLACK_HOLE_ACTIVATE_ATTEMPTS; i += 1) {
      x = this.randomBetween(random, minX, maxX);
      y = this.randomBetween(random, minY, maxY);
      if (!this.insideAvoidCircle(x, y, avoidX, avoidY, avoidRadius)) {
        break;
      }
    }
    this.state.active = true;
    this.state.x = x;
    this.state.y = y;
    this.state.radius = RPS_BATTLE_BLACK_HOLE_INITIAL_RADIUS;
    this.state.reach = RPS_BATTLE_BLACK_HOLE_INITIAL_REACH;
    this.applyDynamicCaps(boardWidth, boardHeight);
  }

  private grow(swallowedCount: number, boardWidth: number, boardHeight: number): void {
    if (this.state === null || swallowedCount <= 0) {
      return;
    }
    const maxRadius = rpsBattleBlackHoleMaxRadiusForBoard(boardWidth, boardHeight);
    const maxReach = rpsBattleBlackHoleMaxReachForBoard(boardWidth, boardHeight);
    for (let i = 0; i < swallowedCount; i += 1) {
      this.state.radius = Math.min(this.state.radius * RPS_BATTLE_BLACK_HOLE_GROWTH, maxRadius);
      this.state.reach = Math.min(this.state.reach * RPS_BATTLE_BLACK_HOLE_GROWTH, maxReach);
    }
    this.state.swallowed += swallowedCount;
  }

  private applyDynamicCaps(boardWidth: number, boardHeight: number): void {
    if (this.state === null) {
      return;
    }
    this.state.radius = Math.min(this.state.radius, rpsBattleBlackHoleMaxRadiusForBoard(boardWidth, boardHeight));
    this.state.reach = Math.min(this.state.reach, rpsBattleBlackHoleMaxReachForBoard(boardWidth, boardHeight));
  }

  private insideAvoidCircle(x: number, y: number, avoidX: number, avoidY: number, avoidRadius: number): boolean {
    if (avoidRadius <= 0 || avoidX < 0 || avoidY < 0) {
      return false;
    }
    const dx = x - avoidX;
    const dy = y - avoidY;
    const safeRadius = avoidRadius + RPS_BATTLE_BLACK_HOLE_INITIAL_RADIUS +
      RPS_BATTLE_BLACK_HOLE_CENTER_SAFE_PADDING;
    return dx * dx + dy * dy < safeRadius * safeRadius;
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
