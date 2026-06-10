import { EggBoundaryHit, EggBoundaryResult, EggProjectile, EggWorldBounds } from './EggSlingTypes';

export const EGG_RADIUS: number = 15;
export const GRAVITY: number = 0.32;
export const MAX_DRAG_DISTANCE: number = 122;
export const VISUAL_MAX_DRAG_DISTANCE: number = 150;
export const VISUAL_DRAG_OFFSET_RATIO: number = 0.82;
export const LAUNCH_POWER: number = 0.155;
export const GROUND_BOUNCE: number = 0.35;
export const GROUND_FRICTION: number = 0.78;
export const SIDE_BOUNCE: number = 0.56;
export const TOP_BOUNCE: number = 0.42;
export const WALL_FRICTION: number = 0.84;
export const SETTLE_SPEED: number = 0.52;
export const WORLD_SIDE_PADDING: number = 14;
export const WORLD_TOP_BOUND: number = 92;
export const BOUNDARY_FLASH_FRAMES: number = 8;
export const TRAJECTORY_PREVIEW_STEPS: number = 12;
export const TRAJECTORY_PREVIEW_FRAME_STEP: number = 3.2;

export function integrateEgg(egg: EggProjectile): EggProjectile {
  return {
    active: egg.active,
    x: egg.x + egg.vx,
    y: egg.y + egg.vy + GRAVITY,
    vx: egg.vx,
    vy: egg.vy + GRAVITY,
    resting: egg.resting
  };
}

export function clampDragDistance(dx: number, dy: number): [number, number] {
  const distance = Math.sqrt(dx * dx + dy * dy);
  if (distance <= MAX_DRAG_DISTANCE || distance === 0) {
    return [dx, dy];
  }
  const scale = MAX_DRAG_DISTANCE / distance;
  return [dx * scale, dy * scale];
}

export function resolveEggBounds(egg: EggProjectile, bounds: EggWorldBounds): EggBoundaryResult {
  let nextX = egg.x;
  let nextY = egg.y;
  let nextVx = egg.vx;
  let nextVy = egg.vy;
  let hit = EggBoundaryHit.NONE;
  const minX = bounds.left + bounds.radius;
  const maxX = bounds.right - bounds.radius;
  const minY = bounds.top + bounds.radius;
  const maxY = bounds.ground - bounds.radius;

  if (nextX < minX) {
    nextX = minX;
    nextVx = Math.abs(nextVx) * SIDE_BOUNCE;
    nextVy *= WALL_FRICTION;
    hit = EggBoundaryHit.LEFT;
  } else if (nextX > maxX) {
    nextX = maxX;
    nextVx = -Math.abs(nextVx) * SIDE_BOUNCE;
    nextVy *= WALL_FRICTION;
    hit = EggBoundaryHit.RIGHT;
  }

  if (nextY < minY) {
    nextY = minY;
    nextVy = Math.abs(nextVy) * TOP_BOUNCE;
    nextVx *= WALL_FRICTION;
    hit = EggBoundaryHit.TOP;
  } else if (nextY > maxY) {
    nextY = maxY;
    nextVy = -Math.abs(nextVy) * GROUND_BOUNCE;
    nextVx *= GROUND_FRICTION;
    hit = EggBoundaryHit.GROUND;
  }

  return {
    egg: {
      active: egg.active,
      x: nextX,
      y: nextY,
      vx: nextVx,
      vy: nextVy,
      resting: egg.resting
    },
    hit: hit
  };
}

export function hasEggSettled(egg: EggProjectile, bounds: EggWorldBounds): boolean {
  const speed = Math.abs(egg.vx) + Math.abs(egg.vy);
  const isOnGround = egg.y >= bounds.ground - bounds.radius - 0.5;
  return isOnGround && speed < SETTLE_SPEED;
}
