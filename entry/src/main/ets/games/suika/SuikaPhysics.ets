import { CollisionStepResult, FruitBody, FruitDef, SuikaBounds } from './SuikaTypes';
import { getMergeOutcome } from './SuikaRules';

const GRAVITY: number = 0.38;
const HORIZONTAL_DAMPING: number = 0.988;
const GROUND_BOUNCE: number = 0.12;
const GROUND_FRICTION: number = 0.82;
const SIDE_BOUNCE: number = 0.28;
const WALL_FRICTION: number = 0.82;
const COLLISION_PUSH: number = 0.56;
const VELOCITY_TRANSFER: number = 0.22;
const MERGE_LOCK_MS: number = 220;
const MAX_FALL_SPEED: number = 10;
const VISUAL_ROLL_FACTOR: number = 0.22;
const VISUAL_ROLL_MIN_SPEED: number = 0.18;
const VISUAL_REST_SPEED: number = 0.12;
const VISUAL_SPIN_DAMPING: number = 0.72;
const VISUAL_SPIN_EPSILON: number = 0.003;
const VISUAL_COLLISION_SPIN_MIN_SPEED_SQ: number = 0.36;
const VISUAL_COLLISION_TANGENT_MIN: number = 0.28;
const MAX_VISUAL_SPIN: number = 0.08;

export function integrateFruits(fruits: FruitBody[], fruitDefs: FruitDef[], bounds: SuikaBounds): FruitBody[] {
  const next: FruitBody[] = [];
  for (let i = 0; i < fruits.length; i += 1) {
    const fruit = fruits[i];
    const radius = fruitDefs[fruit.level].radius;
    let x = fruit.x + fruit.vx;
    let y = fruit.y + fruit.vy;
    let vx = fruit.vx * HORIZONTAL_DAMPING;
    let vy = Math.min(MAX_FALL_SPEED, fruit.vy + GRAVITY);

    if (x - radius < bounds.left) {
      x = bounds.left + radius;
      vx = Math.abs(vx) * SIDE_BOUNCE;
      vy *= WALL_FRICTION;
    }
    if (x + radius > bounds.right) {
      x = bounds.right - radius;
      vx = -Math.abs(vx) * SIDE_BOUNCE;
      vy *= WALL_FRICTION;
    }
    if (y + radius > bounds.bottom) {
      y = bounds.bottom - radius;
      vy = -Math.abs(vy) * GROUND_BOUNCE;
      vx *= GROUND_FRICTION;
      if (Math.abs(vy) < 0.18) {
        vy = 0;
      }
      if (Math.abs(vx) < 0.02) {
        vx = 0;
      }
    }
    const visual = updateVisualRoll(fruit, radius, vx, vy);

    next.push({
      id: fruit.id,
      level: fruit.level,
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      visualAngle: visual.angle,
      visualSpin: visual.spin,
      bornAt: fruit.bornAt,
      releasedAt: fruit.releasedAt,
      mergeLockedUntil: fruit.mergeLockedUntil
    });
  }
  return next;
}

export function resolveSuikaCollisions(
  fruits: FruitBody[],
  fruitDefs: FruitDef[],
  now: number,
  nextId: number
): CollisionStepResult {
  const next: FruitBody[] = fruits.slice();
  for (let i = 0; i < next.length; i += 1) {
    for (let j = i + 1; j < next.length; j += 1) {
      const a = next[i];
      const b = next[j];
      const ar = fruitDefs[a.level].radius;
      const br = fruitDefs[b.level].radius;
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const dist = Math.max(0.01, Math.sqrt(dx * dx + dy * dy));
      const target = ar + br;
      if (dist >= target) {
        continue;
      }

      if (a.level === b.level && now >= a.mergeLockedUntil && now >= b.mergeLockedUntil) {
        const outcome = getMergeOutcome(a.level);
        if (outcome.canMerge) {
          const mergeX = (a.x + b.x) * 0.5;
          const mergeY = (a.y + b.y) * 0.5;
          const merged: FruitBody = {
            id: nextId,
            level: outcome.nextLevel,
            x: mergeX,
            y: mergeY,
            vx: (a.vx + b.vx) * 0.18,
            vy: Math.min(-1.15, (a.vy + b.vy) * 0.12 - 0.8),
            visualAngle: normalizeAngle((a.visualAngle + b.visualAngle) * 0.5),
            visualSpin: clampVisualSpin((a.visualSpin + b.visualSpin) * 0.32 + (a.vx - b.vx) * 0.018),
            bornAt: now,
            releasedAt: now,
            mergeLockedUntil: now + MERGE_LOCK_MS
          };
          const kept: FruitBody[] = [];
          for (let k = 0; k < next.length; k += 1) {
            if (k !== i && k !== j) {
              kept.push(next[k]);
            }
          }
          kept.push(merged);
          return {
            fruits: kept,
            nextId: nextId + 1,
            scoreDelta: outcome.scoreDelta,
            didMerge: true,
            isFinalMerge: outcome.isFinalMerge,
            mergeLevel: outcome.nextLevel,
            mergeX: mergeX,
            mergeY: mergeY
          };
        }
      }

      const overlap = (target - dist) * COLLISION_PUSH;
      const nx = dx / dist;
      const ny = dy / dist;
      const arWeight = br / (ar + br);
      const brWeight = ar / (ar + br);
      const relativeVx = b.vx - a.vx;
      const relativeVy = b.vy - a.vy;
      a.x -= nx * overlap * arWeight;
      a.y -= ny * overlap * arWeight;
      b.x += nx * overlap * brWeight;
      b.y += ny * overlap * brWeight;

      const avx = a.vx;
      const avy = a.vy;
      a.vx = a.vx * 0.65 + b.vx * VELOCITY_TRANSFER - nx * 0.14;
      a.vy = a.vy * 0.65 + b.vy * VELOCITY_TRANSFER - ny * 0.14;
      b.vx = b.vx * 0.65 + avx * VELOCITY_TRANSFER + nx * 0.14;
      b.vy = b.vy * 0.65 + avy * VELOCITY_TRANSFER + ny * 0.14;
      const relativeSpeedSq = relativeVx * relativeVx + relativeVy * relativeVy;
      const tangentImpulse = relativeVx * -ny + relativeVy * nx;
      if (relativeSpeedSq >= VISUAL_COLLISION_SPIN_MIN_SPEED_SQ &&
        Math.abs(tangentImpulse) >= VISUAL_COLLISION_TANGENT_MIN) {
        const spinKick = clampVisualSpin(tangentImpulse * 0.014);
        a.visualSpin = clampVisualSpin(a.visualSpin - spinKick);
        b.visualSpin = clampVisualSpin(b.visualSpin + spinKick);
      }
      next[i] = a;
      next[j] = b;
    }
  }

  return {
    fruits: next,
    nextId: nextId,
    scoreDelta: 0,
    didMerge: false,
    isFinalMerge: false,
    mergeLevel: -1,
    mergeX: 0,
    mergeY: 0
  };
}

interface VisualRollState {
  angle: number;
  spin: number;
}

function updateVisualRoll(fruit: FruitBody, radius: number, vx: number, vy: number): VisualRollState {
  if (Math.abs(vx) < VISUAL_REST_SPEED && Math.abs(vy) < VISUAL_REST_SPEED) {
    return {
      angle: fruit.visualAngle,
      spin: 0
    };
  }
  const rollDelta = Math.abs(vx) >= VISUAL_ROLL_MIN_SPEED ? (vx / Math.max(10, radius)) * VISUAL_ROLL_FACTOR : 0;
  let spin = clampVisualSpin(fruit.visualSpin * VISUAL_SPIN_DAMPING);
  if (Math.abs(spin) < VISUAL_SPIN_EPSILON) {
    spin = 0;
  }
  return {
    angle: normalizeAngle(fruit.visualAngle + rollDelta + spin),
    spin: spin
  };
}

function clampVisualSpin(value: number): number {
  return Math.max(-MAX_VISUAL_SPIN, Math.min(MAX_VISUAL_SPIN, value));
}

function normalizeAngle(value: number): number {
  const fullTurn = Math.PI * 2;
  if (value > fullTurn || value < -fullTurn) {
    return value % fullTurn;
  }
  return value;
}
