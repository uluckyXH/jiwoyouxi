#!/usr/bin/env node

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const projectRoot = resolve(import.meta.dirname, '..');
const sourceFiles = [
  'entry/src/main/ets/games/suika/SuikaTypes.ets',
  'entry/src/main/ets/games/suika/SuikaRules.ets',
  'entry/src/main/ets/games/suika/SuikaPhysics.ets'
];

function loadSuikaRules() {
  const source = sourceFiles
    .map((file) => readFileSync(resolve(projectRoot, file), 'utf8'))
    .join('\n')
    .replace(/^import\s+[^;]+;\n/gm, '')
    .replace(/^export\s+/gm, '');
  const runtimeSource = stripTypeScriptTypes(source, { mode: 'transform' });
  const context = { console: console };
  vm.runInNewContext(`${runtimeSource}
globalThis.__suika = {
  FRUITS,
  START_LEVELS,
  RANDOM_MIN_LEVEL,
  RANDOM_MAX_LEVEL,
  MAX_FRUIT_LEVEL,
  FINAL_MERGE_SOURCE_LEVEL,
  FINAL_MERGE_BONUS,
  OVERFLOW_GRACE_MS,
  OVERFLOW_RELEASE_GRACE_MS,
  getSpawnLevel,
  getMergeOutcome,
  clampAimX,
  resolveOverflowState,
  integrateFruits,
  resolveSuikaCollisions
};
`, context);
  return context.__suika;
}

function makeFruit(level, overrides = {}) {
  return Object.assign({
    id: level + 1,
    level: level,
    x: 100,
    y: 100,
    vx: 0,
    vy: 0,
    bornAt: 0,
    releasedAt: 0,
    mergeLockedUntil: 0
  }, overrides);
}

const api = loadSuikaRules();

{
  const sequence = [];
  for (let i = 0; i < api.START_LEVELS.length; i += 1) {
    sequence.push(api.getSpawnLevel(i, () => 0.99));
  }
  assert.deepEqual(sequence, [0, 0, 1, 2, 2, 3], 'opening spawn sequence should match reference flow');
}

{
  assert.equal(api.getSpawnLevel(api.START_LEVELS.length, () => 0), 0, 'random pool should include level 0');
  assert.equal(api.getSpawnLevel(api.START_LEVELS.length, () => 0.999), 4, 'random pool should cap at level 4');
}

{
  const first = api.getMergeOutcome(0);
  assert.equal(first.canMerge, true, 'level 0 should merge');
  assert.equal(first.nextLevel, 1, 'level 0 should merge into level 1');
  assert.equal(first.scoreDelta, 1, 'level 0 merge should score source level + 1');

  const final = api.getMergeOutcome(9);
  assert.equal(final.canMerge, true, 'level 9 should merge into final fruit');
  assert.equal(final.nextLevel, 10, 'level 9 should merge into level 10');
  assert.equal(final.scoreDelta, 110, 'final merge should add base score and final bonus');
  assert.equal(final.isFinalMerge, true, 'level 9 merge should be marked as final');

  const max = api.getMergeOutcome(10);
  assert.equal(max.canMerge, false, 'level 10 should not continue upgrading');
  assert.equal(max.scoreDelta, 0, 'level 10 collision should not score as a merge');
}

{
  assert.equal(api.clampAimX(0, 20, 200, 30), 50, 'aim should keep current fruit inside left wall');
  assert.equal(api.clampAimX(260, 20, 200, 30), 170, 'aim should keep current fruit inside right wall');
  assert.equal(api.clampAimX(110, 20, 200, 30), 110, 'aim inside bounds should not move');
}

{
  const now = 5000;
  const overFruit = makeFruit(2, {
    y: 90,
    releasedAt: now - api.OVERFLOW_RELEASE_GRACE_MS - 1
  });
  const firstCheck = api.resolveOverflowState([overFruit], api.FRUITS, 100, now, 0);
  assert.equal(firstCheck.isOverflowing, true, 'released fruit above fail line should start overflow');
  assert.equal(firstCheck.overflowSince, now, 'first overflow frame should set timer');
  assert.equal(firstCheck.shouldFinish, false, 'first overflow frame should not finish immediately');

  const finalCheck = api.resolveOverflowState([overFruit], api.FRUITS, 100, now + api.OVERFLOW_GRACE_MS, now);
  assert.equal(finalCheck.shouldFinish, true, 'sustained overflow should finish after grace time');

  const freshFruit = makeFruit(2, {
    y: 90,
    releasedAt: now
  });
  const freshCheck = api.resolveOverflowState([freshFruit], api.FRUITS, 100, now, 0);
  assert.equal(freshCheck.isOverflowing, false, 'freshly dropped fruit should not count before release grace');
}

{
  const result = api.resolveSuikaCollisions([
    makeFruit(2, { id: 1, x: 100, y: 100 }),
    makeFruit(2, { id: 2, x: 112, y: 100 })
  ], api.FRUITS, 1000, 3);
  assert.equal(result.didMerge, true, 'same level overlapping fruits should merge');
  assert.equal(result.scoreDelta, 3, 'level 2 merge should score 3');
  assert.equal(result.fruits.length, 1, 'merge should replace two fruits with one');
  assert.equal(result.fruits[0].level, 3, 'level 2 merge should create level 3');
}

{
  const result = api.resolveSuikaCollisions([
    makeFruit(10, { id: 1, x: 100, y: 100 }),
    makeFruit(10, { id: 2, x: 112, y: 100 })
  ], api.FRUITS, 1000, 3);
  assert.equal(result.didMerge, false, 'two max level fruits should not merge');
  assert.equal(result.scoreDelta, 0, 'max level collision should not add score');
  assert.equal(result.fruits.length, 2, 'max level collision should keep both fruits');
}

console.log('Suika rules tests passed');
