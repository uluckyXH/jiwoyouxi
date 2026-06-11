import { FruitBody, FruitDef, MergeOutcome, OverflowState } from './SuikaTypes';

export const START_LEVELS: number[] = [0, 0, 1, 2, 2, 3];
export const RANDOM_MIN_LEVEL: number = 0;
export const RANDOM_MAX_LEVEL: number = 4;
export const MAX_FRUIT_LEVEL: number = 10;
export const FINAL_MERGE_SOURCE_LEVEL: number = 9;
export const FINAL_MERGE_BONUS: number = 100;
export const NEXT_FRUIT_DELAY_MS: number = 500;
export const OVERFLOW_GRACE_MS: number = 3000;
export const OVERFLOW_RELEASE_GRACE_MS: number = 700;

export function getSpawnLevel(spawnIndex: number, randomSource: () => number = Math.random): number {
  if (spawnIndex < START_LEVELS.length) {
    return START_LEVELS[Math.max(0, spawnIndex)];
  }
  const range = RANDOM_MAX_LEVEL - RANDOM_MIN_LEVEL + 1;
  const value = Math.floor(randomSource() * range);
  return RANDOM_MIN_LEVEL + Math.max(0, Math.min(range - 1, value));
}

export function getMergeOutcome(sourceLevel: number): MergeOutcome {
  if (sourceLevel < 0 || sourceLevel >= MAX_FRUIT_LEVEL) {
    return {
      canMerge: false,
      nextLevel: sourceLevel,
      scoreDelta: 0,
      isFinalMerge: false
    };
  }

  const baseScore = sourceLevel + 1;
  const isFinalMerge = sourceLevel === FINAL_MERGE_SOURCE_LEVEL;
  return {
    canMerge: true,
    nextLevel: sourceLevel + 1,
    scoreDelta: isFinalMerge ? baseScore + FINAL_MERGE_BONUS : baseScore,
    isFinalMerge: isFinalMerge
  };
}

export function clampAimX(x: number, left: number, right: number, radius: number): number {
  return Math.max(left + radius, Math.min(right - radius, x));
}

export function resolveOverflowState(
  fruits: FruitBody[],
  fruitDefs: FruitDef[],
  failLineY: number,
  now: number,
  previousOverflowSince: number
): OverflowState {
  let isOverflowing = false;
  for (let i = 0; i < fruits.length; i += 1) {
    const fruit = fruits[i];
    if (now - fruit.releasedAt < OVERFLOW_RELEASE_GRACE_MS) {
      continue;
    }
    const radius = fruitDefs[fruit.level].radius;
    if (fruit.y - radius < failLineY) {
      isOverflowing = true;
      break;
    }
  }

  if (!isOverflowing) {
    return {
      isOverflowing: false,
      overflowSince: 0,
      shouldFinish: false
    };
  }

  const overflowSince = previousOverflowSince === 0 ? now : previousOverflowSince;
  return {
    isOverflowing: true,
    overflowSince: overflowSince,
    shouldFinish: now - overflowSince >= OVERFLOW_GRACE_MS
  };
}

