import { EGG_RADIUS, GRAVITY } from './EggSlingPhysics';
import { EggProjectile, PigTarget, SlingBlock, SlingBlockKind } from './EggSlingTypes';

export const BLOCK_HIT_FLASH_FRAMES: number = 10;
export const BLOCK_LIGHT_HIT_SPEED: number = 2.5;
export const BLOCK_HEAVY_HIT_SPEED: number = 6;
export const BLOCK_COLLAPSE_GRAVITY: number = GRAVITY * 0.9;
export const BLOCK_COLLAPSE_BOUNCE: number = 0.18;
export const BLOCK_COLLAPSE_FRICTION: number = 0.74;
export const BLOCK_IMPACT_SCORE: number = 30;
export const BLOCK_HEAVY_IMPACT_SCORE: number = 50;

export interface BlockImpactResult {
  block: SlingBlock;
  egg: EggProjectile;
  scoreDelta: number;
  shouldCollapseGroup: boolean;
  didHit: boolean;
}

export function resolveBlockImpact(egg: EggProjectile, block: SlingBlock): BlockImpactResult {
  if (!block.visible || block.dynamic || block.hp <= 0 || !circleHitsBlock(egg.x, egg.y, EGG_RADIUS, block)) {
    return {
      block: block,
      egg: egg,
      scoreDelta: 0,
      shouldCollapseGroup: false,
      didHit: false
    };
  }

  const impactSpeed = Math.abs(egg.vx) + Math.abs(egg.vy);
  const damage = blockDamageForImpact(impactSpeed, block);
  const nextHp = Math.max(0, block.hp - damage);
  const impactDirection = impactDirectionForEgg(egg, block);
  const hitOffset = Math.min(9, Math.max(3, Math.abs(egg.vx) * 0.65 + Math.abs(egg.vy) * 0.22));
  let nextBlock: SlingBlock = copyBlock(block);
  nextBlock.hp = nextHp;
  nextBlock.hitFrames = BLOCK_HIT_FLASH_FRAMES;
  nextBlock.offsetX = impactDirection * hitOffset;
  nextBlock.offsetY = -Math.min(4, Math.abs(egg.vy) * 0.16);
  nextBlock.rotation = block.rotation + impactDirection * Math.min(0.12, impactSpeed * 0.012);
  nextBlock.angularVelocity = block.angularVelocity + impactDirection * Math.min(0.08, impactSpeed * 0.008);

  if (nextHp <= 0) {
    nextBlock = collapseBlock(nextBlock, egg, impactDirection);
  }

  return {
    block: nextBlock,
    egg: bounceEggFromBlock(egg, block),
    scoreDelta: damage >= 2 ? BLOCK_HEAVY_IMPACT_SCORE : damage * BLOCK_IMPACT_SCORE,
    shouldCollapseGroup: nextHp <= 0,
    didHit: true
  };
}

export function collapseBlock(block: SlingBlock, egg: EggProjectile, fallbackDirection: number): SlingBlock {
  const direction = fallbackDirection === 0 ? 1 : fallbackDirection;
  const isSupport = block.kind === SlingBlockKind.SUPPORT;
  const nextBlock = copyBlock(block);
  nextBlock.hp = 0;
  nextBlock.hitFrames = BLOCK_HIT_FLASH_FRAMES;
  nextBlock.offsetX = 0;
  nextBlock.offsetY = 0;
  nextBlock.vx = egg.vx * (isSupport ? 0.24 : 0.2) + direction * (isSupport ? 1.4 : 1.1);
  nextBlock.vy = Math.min(1.6, egg.vy * 0.16) - 0.7;
  nextBlock.rotation = block.rotation + direction * (isSupport ? 0.18 : 0.05);
  nextBlock.angularVelocity = block.angularVelocity + direction * (isSupport ? 0.16 : 0.09);
  nextBlock.dynamic = true;
  nextBlock.visible = true;
  return nextBlock;
}

export function updateBlockMotion(block: SlingBlock, groundY: number): SlingBlock {
  if (!block.visible) {
    return block;
  }

  let nextBlock: SlingBlock = copyBlock(block);
  nextBlock.hitFrames = Math.max(0, block.hitFrames - 1);
  nextBlock.offsetX = block.offsetX * 0.72;
  nextBlock.offsetY = block.offsetY * 0.72;
  nextBlock.rotation = block.rotation + block.angularVelocity;
  nextBlock.angularVelocity = block.angularVelocity * 0.88;

  if (!block.dynamic) {
    if (block.hp <= 0) {
      const bottomExtent = rotatedBottomExtent(block.blockWidth, block.blockHeight, nextBlock.rotation);
      if (nextBlock.y + bottomExtent > groundY) {
        nextBlock.y = groundY - bottomExtent;
      }
      return nextBlock;
    }
    nextBlock.rotation = nextBlock.rotation * 0.92;
    return nextBlock;
  }

  let nextX = block.x + block.vx;
  let nextY = block.y + block.vy;
  let nextVx = block.vx * 0.992;
  let nextVy = block.vy + BLOCK_COLLAPSE_GRAVITY;
  let nextAngularVelocity = nextBlock.angularVelocity;
  let nextDynamic = true;
  const bottomExtent = rotatedBottomExtent(block.blockWidth, block.blockHeight, nextBlock.rotation);

  if (nextY + bottomExtent > groundY) {
    nextY = groundY - bottomExtent;
    nextVy = -Math.abs(nextVy) * BLOCK_COLLAPSE_BOUNCE;
    nextVx *= BLOCK_COLLAPSE_FRICTION;
    nextAngularVelocity *= 0.62;
    if (Math.abs(nextVx) + Math.abs(nextVy) + Math.abs(nextAngularVelocity) < 0.35) {
      nextVx = 0;
      nextVy = 0;
      nextAngularVelocity = 0;
      nextDynamic = false;
      if (block.hp <= 0 && block.kind === SlingBlockKind.SUPPORT && Math.abs(nextBlock.rotation) < 1.05) {
        nextBlock.rotation = (nextBlock.rotation >= 0 ? 1 : -1) * 1.05;
        const restedBottomExtent = rotatedBottomExtent(block.blockWidth, block.blockHeight, nextBlock.rotation);
        nextY = groundY - restedBottomExtent;
      }
    }
  }

  nextBlock.x = nextX;
  nextBlock.y = nextY;
  nextBlock.vx = nextVx;
  nextBlock.vy = nextVy;
  nextBlock.angularVelocity = nextAngularVelocity;
  nextBlock.dynamic = nextDynamic;
  return nextBlock;
}

export function collapseTarget(target: PigTarget, egg: EggProjectile, fallbackDirection: number): PigTarget {
  const direction = fallbackDirection === 0 ? 1 : fallbackDirection;
  return {
    id: target.id,
    groupId: target.groupId,
    x: target.x,
    y: target.y,
    radius: target.radius,
    alive: target.alive,
    vx: egg.vx * 0.16 + direction * 0.7,
    vy: Math.min(1.4, egg.vy * 0.12) - 0.45,
    rotation: target.rotation,
    angularVelocity: target.angularVelocity + direction * 0.06,
    dynamic: true,
    hitFrames: 8,
    visible: target.visible
  };
}

export function updateTargetMotion(target: PigTarget, groundY: number): PigTarget {
  if (!target.visible) {
    return target;
  }

  let nextX = target.x;
  let nextY = target.y;
  let nextVx = target.vx;
  let nextVy = target.vy;
  let nextRotation = target.rotation + target.angularVelocity;
  let nextAngularVelocity = target.angularVelocity * 0.88;
  let nextDynamic = target.dynamic;

  if (target.dynamic) {
    nextX = target.x + target.vx;
    nextY = target.y + target.vy;
    nextVx = target.vx * 0.992;
    nextVy = target.vy + BLOCK_COLLAPSE_GRAVITY;
    if (nextY + target.radius > groundY) {
      nextY = groundY - target.radius;
      nextVy = -Math.abs(nextVy) * 0.16;
      nextVx *= 0.72;
      nextAngularVelocity *= 0.62;
      if (Math.abs(nextVx) + Math.abs(nextVy) + Math.abs(nextAngularVelocity) < 0.32) {
        nextVx = 0;
        nextVy = 0;
        nextAngularVelocity = 0;
        nextDynamic = false;
      }
    }
  }

  return {
    id: target.id,
    groupId: target.groupId,
    x: nextX,
    y: nextY,
    radius: target.radius,
    alive: target.alive,
    vx: nextVx,
    vy: nextVy,
    rotation: nextRotation,
    angularVelocity: nextAngularVelocity,
    dynamic: nextDynamic,
    hitFrames: Math.max(0, target.hitFrames - 1),
    visible: target.visible
  };
}

export function circleHitsBlock(x: number, y: number, radius: number, block: SlingBlock): boolean {
  if (!block.visible || block.dynamic) {
    return false;
  }
  const left = block.x - block.blockWidth * 0.5;
  const right = block.x + block.blockWidth * 0.5;
  const top = block.y - block.blockHeight * 0.5;
  const bottom = block.y + block.blockHeight * 0.5;
  const cx = Math.max(left, Math.min(right, x));
  const cy = Math.max(top, Math.min(bottom, y));
  const dx = x - cx;
  const dy = y - cy;
  return dx * dx + dy * dy <= radius * radius;
}

function blockDamageForImpact(impactSpeed: number, block: SlingBlock): number {
  if (block.kind === SlingBlockKind.SUPPORT && impactSpeed >= 1.2) {
    return impactSpeed >= 4.5 ? 2 : 1;
  }
  if (impactSpeed < BLOCK_LIGHT_HIT_SPEED) {
    return 0;
  }
  if (impactSpeed >= BLOCK_HEAVY_HIT_SPEED) {
    return 2;
  }
  return 1;
}

function rotatedBottomExtent(width: number, height: number, rotation: number): number {
  const halfWidth = width * 0.5;
  const halfHeight = height * 0.5;
  return Math.abs(Math.sin(rotation)) * halfWidth + Math.abs(Math.cos(rotation)) * halfHeight;
}

function impactDirectionForEgg(egg: EggProjectile, block: SlingBlock): number {
  if (egg.x < block.x) {
    return -1;
  }
  if (egg.x > block.x) {
    return 1;
  }
  return egg.vx >= 0 ? 1 : -1;
}

function bounceEggFromBlock(egg: EggProjectile, block: SlingBlock): EggProjectile {
  const horizontalOverlap = Math.abs(egg.x - block.x) / Math.max(1, block.blockWidth * 0.5);
  const verticalOverlap = Math.abs(egg.y - block.y) / Math.max(1, block.blockHeight * 0.5);
  let nextVx = egg.vx;
  let nextVy = egg.vy;

  if (horizontalOverlap > verticalOverlap) {
    nextVx = -egg.vx * 0.46;
    nextVy = egg.vy * 0.72;
  } else {
    nextVx = egg.vx * 0.72;
    nextVy = -egg.vy * 0.42;
  }

  return {
    active: egg.active,
    x: egg.x,
    y: egg.y,
    vx: nextVx,
    vy: nextVy,
    resting: egg.resting
  };
}

function copyBlock(block: SlingBlock): SlingBlock {
  return {
    id: block.id,
    groupId: block.groupId,
    kind: block.kind,
    x: block.x,
    y: block.y,
    blockWidth: block.blockWidth,
    blockHeight: block.blockHeight,
    hp: block.hp,
    maxHp: block.maxHp,
    color: block.color,
    hitFrames: block.hitFrames,
    offsetX: block.offsetX,
    offsetY: block.offsetY,
    vx: block.vx,
    vy: block.vy,
    rotation: block.rotation,
    angularVelocity: block.angularVelocity,
    dynamic: block.dynamic,
    visible: block.visible
  };
}
