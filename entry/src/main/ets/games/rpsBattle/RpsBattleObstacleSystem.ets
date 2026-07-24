import {
  RpsBattleEntity,
  RpsBattleObstacle,
  RpsBattleObstacleState
} from './RpsBattleTypes';

export const RPS_BATTLE_OBSTACLE_SMALL_BOARD_MAX_SHORT_SIDE: number = 360;
export const RPS_BATTLE_OBSTACLE_SMALL_COUNT: number = 2;
export const RPS_BATTLE_OBSTACLE_STANDARD_COUNT: number = 3;
export const RPS_BATTLE_OBSTACLE_SPAWN_ATTEMPTS: number = 24;
export const RPS_BATTLE_OBSTACLE_RESTITUTION: number = 0.82;
export const RPS_BATTLE_OBSTACLE_MIN_RADIUS: number = 28;
export const RPS_BATTLE_OBSTACLE_MAX_SMALL_RADIUS: number = 42;
export const RPS_BATTLE_OBSTACLE_MAX_STANDARD_RADIUS: number = 50;

const RPS_BATTLE_OBSTACLE_EDGE_MARGIN: number = 20;
const RPS_BATTLE_OBSTACLE_HOME_SAFE_MIN_RADIUS: number = 56;
const RPS_BATTLE_OBSTACLE_HOME_SAFE_RATIO: number = 0.18;
const RPS_BATTLE_OBSTACLE_CENTER_SAFE_RATIO: number = 0.12;
const RPS_BATTLE_OBSTACLE_GAP: number = 14;
const RPS_BATTLE_OBSTACLE_EPSILON: number = 0.01;

interface RpsBattleObstacleSafeCircle {
  x: number;
  y: number;
  radius: number;
}

export function rpsBattleObstacleCountForBoard(boardWidth: number, boardHeight: number): number {
  return Math.min(boardWidth, boardHeight) <= RPS_BATTLE_OBSTACLE_SMALL_BOARD_MAX_SHORT_SIDE ?
    RPS_BATTLE_OBSTACLE_SMALL_COUNT : RPS_BATTLE_OBSTACLE_STANDARD_COUNT;
}

export function rpsBattleObstacleHomeSafeRadiusForBoard(boardWidth: number, boardHeight: number): number {
  return Math.max(RPS_BATTLE_OBSTACLE_HOME_SAFE_MIN_RADIUS,
    Math.min(boardWidth, boardHeight) * RPS_BATTLE_OBSTACLE_HOME_SAFE_RATIO);
}

export function rpsBattleObstacleCenterSafeRadiusForBoard(boardWidth: number, boardHeight: number): number {
  return Math.max(34, Math.min(boardWidth, boardHeight) * RPS_BATTLE_OBSTACLE_CENTER_SAFE_RATIO);
}

export function rpsBattleResolveObstacleCollisions(entity: RpsBattleEntity, obstacles: RpsBattleObstacle[]): number {
  let hitCount = 0;
  for (let i = 0; i < obstacles.length; i += 1) {
    if (rpsBattleResolveObstacleCollision(entity, obstacles[i])) {
      hitCount += 1;
    }
  }
  return hitCount;
}

export function rpsBattleResolveObstacleCollision(entity: RpsBattleEntity, obstacle: RpsBattleObstacle): boolean {
  const dx = entity.x - obstacle.x;
  const dy = entity.y - obstacle.y;
  const minimumDistance = entity.radius + obstacle.radius;
  const distanceSq = dx * dx + dy * dy;
  if (distanceSq >= minimumDistance * minimumDistance) {
    return false;
  }

  let normalX = 0;
  let normalY = 0;
  let separation = 0;
  if (distanceSq > RPS_BATTLE_OBSTACLE_EPSILON * RPS_BATTLE_OBSTACLE_EPSILON) {
    const distance = Math.sqrt(distanceSq);
    normalX = dx / distance;
    normalY = dy / distance;
    separation = minimumDistance - distance + RPS_BATTLE_OBSTACLE_EPSILON;
  } else if (Math.abs(entity.vx) >= Math.abs(entity.vy)) {
    normalX = entity.vx >= 0 ? -1 : 1;
    separation = minimumDistance + RPS_BATTLE_OBSTACLE_EPSILON;
  } else {
    normalY = entity.vy >= 0 ? -1 : 1;
    separation = minimumDistance + RPS_BATTLE_OBSTACLE_EPSILON;
  }

  entity.x += normalX * separation;
  entity.y += normalY * separation;
  const normalVelocity = entity.vx * normalX + entity.vy * normalY;
  if (normalVelocity < 0) {
    entity.vx = (entity.vx - normalVelocity * normalX * 2) * RPS_BATTLE_OBSTACLE_RESTITUTION;
    entity.vy = (entity.vy - normalVelocity * normalY * 2) * RPS_BATTLE_OBSTACLE_RESTITUTION;
  }
  return true;
}

export class RpsBattleObstacleSystem {
  private state: RpsBattleObstacleState | null = null;

  reset(boardWidth: number, boardHeight: number, random: () => number): void {
    const obstacles: RpsBattleObstacle[] = [];
    const targetCount = rpsBattleObstacleCountForBoard(boardWidth, boardHeight);
    for (let i = 0; i < targetCount; i += 1) {
      const obstacle = this.createSafeObstacle(boardWidth, boardHeight, random, obstacles, i);
      if (obstacle !== null) {
        obstacles.push(obstacle);
      }
    }
    this.state = {
      obstacles: obstacles
    };
  }

  clear(): void {
    this.state = null;
  }

  resize(ratioX: number, ratioY: number, boardWidth: number, boardHeight: number): void {
    if (this.state === null) {
      return;
    }
    const shortSide = Math.min(boardWidth, boardHeight);
    const margin = Math.min(RPS_BATTLE_OBSTACLE_EDGE_MARGIN, shortSide * 0.08);
    const maxRadius = Math.max(RPS_BATTLE_OBSTACLE_MIN_RADIUS, shortSide * 0.16);
    const radiusScale = Math.min(ratioX, ratioY);
    for (let i = 0; i < this.state.obstacles.length; i += 1) {
      const obstacle = this.state.obstacles[i];
      obstacle.x *= ratioX;
      obstacle.y *= ratioY;
      obstacle.radius = Math.min(maxRadius, obstacle.radius * radiusScale);
      obstacle.x = this.clamp(obstacle.x, margin + obstacle.radius, boardWidth - margin - obstacle.radius);
      obstacle.y = this.clamp(obstacle.y, margin + obstacle.radius, boardHeight - margin - obstacle.radius);
    }
  }

  resolveEntity(entity: RpsBattleEntity): number {
    if (this.state === null) {
      return 0;
    }
    return rpsBattleResolveObstacleCollisions(entity, this.state.obstacles);
  }

  currentState(): RpsBattleObstacleState | null {
    return this.state;
  }

  snapshot(): RpsBattleObstacleState | null {
    if (this.state === null) {
      return null;
    }
    const obstacles: RpsBattleObstacle[] = [];
    for (let i = 0; i < this.state.obstacles.length; i += 1) {
      const obstacle = this.state.obstacles[i];
      obstacles.push({
        x: obstacle.x,
        y: obstacle.y,
        radius: obstacle.radius
      });
    }
    return {
      obstacles: obstacles
    };
  }

  private createSafeObstacle(boardWidth: number, boardHeight: number, random: () => number,
    existing: RpsBattleObstacle[], index: number): RpsBattleObstacle | null {
    const radius = this.createRadius(boardWidth, boardHeight, random);
    for (let attempt = 0; attempt < RPS_BATTLE_OBSTACLE_SPAWN_ATTEMPTS; attempt += 1) {
      const candidate = this.randomCandidate(boardWidth, boardHeight, radius, random);
      if (this.canPlace(candidate, boardWidth, boardHeight, existing)) {
        return candidate;
      }
    }
    return this.fallbackCandidate(boardWidth, boardHeight, radius, existing, index);
  }

  private createRadius(boardWidth: number, boardHeight: number, random: () => number): number {
    const shortSide = Math.min(boardWidth, boardHeight);
    const isSmall = shortSide <= RPS_BATTLE_OBSTACLE_SMALL_BOARD_MAX_SHORT_SIDE;
    const maxRadius = isSmall ? RPS_BATTLE_OBSTACLE_MAX_SMALL_RADIUS : RPS_BATTLE_OBSTACLE_MAX_STANDARD_RADIUS;
    return this.clamp(shortSide * this.randomBetween(random, 0.095, 0.13), RPS_BATTLE_OBSTACLE_MIN_RADIUS,
      maxRadius);
  }

  private randomCandidate(boardWidth: number, boardHeight: number, radius: number,
    random: () => number): RpsBattleObstacle {
    const margin = Math.min(RPS_BATTLE_OBSTACLE_EDGE_MARGIN, Math.min(boardWidth, boardHeight) * 0.08);
    return {
      x: this.randomBetween(random, margin + radius, boardWidth - margin - radius),
      y: this.randomBetween(random, margin + radius, boardHeight - margin - radius),
      radius: radius
    };
  }

  private fallbackCandidate(boardWidth: number, boardHeight: number, radius: number,
    existing: RpsBattleObstacle[], index: number): RpsBattleObstacle | null {
    const positions: number[][] = [
      [0.18, 0.56],
      [0.82, 0.58],
      [0.50, 0.18],
      [0.50, 0.84],
      [0.18, 0.80],
      [0.82, 0.16]
    ];
    const start = index % positions.length;
    for (let i = 0; i < positions.length; i += 1) {
      const position = positions[(start + i) % positions.length];
      const candidate: RpsBattleObstacle = {
        x: boardWidth * position[0],
        y: boardHeight * position[1],
        radius: radius
      };
      if (this.canPlace(candidate, boardWidth, boardHeight, existing)) {
        return candidate;
      }
    }
    return null;
  }

  private canPlace(candidate: RpsBattleObstacle, boardWidth: number, boardHeight: number,
    existing: RpsBattleObstacle[]): boolean {
    if (!this.insideBoard(candidate, boardWidth, boardHeight)) {
      return false;
    }
    const safeCircles = this.safeCircles(boardWidth, boardHeight);
    for (let i = 0; i < safeCircles.length; i += 1) {
      if (this.intersectsCircle(candidate, safeCircles[i])) {
        return false;
      }
    }
    for (let i = 0; i < existing.length; i += 1) {
      if (this.intersectsObstacleWithGap(candidate, existing[i])) {
        return false;
      }
    }
    return true;
  }

  private safeCircles(boardWidth: number, boardHeight: number): RpsBattleObstacleSafeCircle[] {
    const homeRadius = rpsBattleObstacleHomeSafeRadiusForBoard(boardWidth, boardHeight);
    const centerRadius = rpsBattleObstacleCenterSafeRadiusForBoard(boardWidth, boardHeight);
    return [
      { x: boardWidth * 0.24, y: boardHeight * 0.28, radius: homeRadius },
      { x: boardWidth * 0.76, y: boardHeight * 0.30, radius: homeRadius },
      { x: boardWidth * 0.50, y: boardHeight * 0.74, radius: homeRadius },
      { x: boardWidth * 0.50, y: boardHeight * 0.50, radius: centerRadius }
    ];
  }

  private insideBoard(obstacle: RpsBattleObstacle, boardWidth: number, boardHeight: number): boolean {
    const margin = Math.min(RPS_BATTLE_OBSTACLE_EDGE_MARGIN, Math.min(boardWidth, boardHeight) * 0.08);
    return obstacle.x - obstacle.radius >= margin &&
      obstacle.x + obstacle.radius <= boardWidth - margin &&
      obstacle.y - obstacle.radius >= margin &&
      obstacle.y + obstacle.radius <= boardHeight - margin;
  }

  private intersectsCircle(obstacle: RpsBattleObstacle, circle: RpsBattleObstacleSafeCircle): boolean {
    const dx = obstacle.x - circle.x;
    const dy = obstacle.y - circle.y;
    const minimumDistance = obstacle.radius + circle.radius;
    return dx * dx + dy * dy < minimumDistance * minimumDistance;
  }

  private intersectsObstacleWithGap(a: RpsBattleObstacle, b: RpsBattleObstacle): boolean {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    const minimumDistance = a.radius + b.radius + RPS_BATTLE_OBSTACLE_GAP;
    return dx * dx + dy * dy < minimumDistance * minimumDistance;
  }

  private randomBetween(random: () => number, min: number, max: number): number {
    if (max <= min) {
      return min;
    }
    return min + Math.max(0, Math.min(1, random())) * (max - min);
  }

  private clamp(value: number, min: number, max: number): number {
    if (max <= min) {
      return min;
    }
    return Math.max(min, Math.min(max, value));
  }
}
