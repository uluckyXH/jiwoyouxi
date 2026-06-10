#!/usr/bin/env node

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const projectRoot = resolve(import.meta.dirname, '..');
const sourceFiles = [
  'entry/src/main/ets/games/eggSling/EggSlingTypes.ets',
  'entry/src/main/ets/games/eggSling/EggSlingPhysics.ets',
  'entry/src/main/ets/games/eggSling/EggSlingCollision.ets'
];

function loadEggSlingPhysics() {
  const source = sourceFiles
    .map((file) => readFileSync(resolve(projectRoot, file), 'utf8'))
    .join('\n')
    .replace(/^import\s+[^;]+;\n/gm, '')
    .replace(/^export\s+/gm, '');
  const runtimeSource = stripTypeScriptTypes(source, { mode: 'transform' });
  const context = { console: console };
  vm.runInNewContext(`${runtimeSource}
globalThis.__eggSling = {
  SlingBlockKind,
  resolveBlockImpact,
  collapseBlock,
  updateBlockMotion,
  collapseTarget,
  updateTargetMotion
};
`, context);
  return context.__eggSling;
}

function makeBlock(kind, overrides = {}) {
  const block = {
    id: 1,
    groupId: 1,
    kind: kind,
    x: 100,
    y: 100,
    blockWidth: kind === 'beam' ? 76 : 16,
    blockHeight: kind === 'beam' ? 14 : 58,
    hp: 1,
    maxHp: 1,
    color: '#d2691e',
    hitFrames: 0,
    offsetX: 0,
    offsetY: 0,
    vx: 0,
    vy: 0,
    rotation: 0,
    angularVelocity: 0,
    dynamic: false,
    visible: true
  };
  return Object.assign(block, overrides);
}

function makeEgg(overrides = {}) {
  return Object.assign({
    active: true,
    x: 93,
    y: 100,
    vx: 5.8,
    vy: 0.2,
    resting: false
  }, overrides);
}

function makeTarget(overrides = {}) {
  return Object.assign({
    id: 1,
    groupId: 1,
    x: 120,
    y: 70,
    radius: 18,
    alive: true,
    vx: 0,
    vy: 0,
    rotation: 0,
    angularVelocity: 0,
    dynamic: false,
    hitFrames: 0,
    visible: true
  }, overrides);
}

function rotatedBottomExtent(block) {
  return Math.abs(Math.sin(block.rotation)) * block.blockWidth * 0.5 +
    Math.abs(Math.cos(block.rotation)) * block.blockHeight * 0.5;
}

function updateBlockForFrames(api, block, frames, groundY) {
  let current = block;
  for (let i = 0; i < frames; i += 1) {
    current = api.updateBlockMotion(current, groundY);
  }
  return current;
}

function updateTargetForFrames(api, target, frames, groundY) {
  let current = target;
  for (let i = 0; i < frames; i += 1) {
    current = api.updateTargetMotion(current, groundY);
  }
  return current;
}

const api = loadEggSlingPhysics();
const groundY = 180;

{
  const support = makeBlock(api.SlingBlockKind.SUPPORT);
  const result = api.resolveBlockImpact(makeEgg(), support);
  assert.equal(result.didHit, true, 'support should register a collision');
  assert.equal(result.shouldCollapseGroup, true, 'support should collapse when hit hard enough');
  assert.equal(result.block.dynamic, true, 'collapsed support should become dynamic');
  assert.equal(result.block.hp, 0, 'collapsed support hp should be zero');
}

{
  const support = makeBlock(api.SlingBlockKind.SUPPORT);
  const collapsed = api.resolveBlockImpact(makeEgg(), support).block;
  const settled = updateBlockForFrames(api, collapsed, 260, groundY);
  assert.equal(settled.hp, 0, 'settled collapsed support should remain broken');
  assert.ok(Math.abs(settled.rotation) > 0.2, 'settled collapsed support should not stand upright again');
  assert.ok(settled.y + rotatedBottomExtent(settled) <= groundY + 0.5, 'settled support should not penetrate ground');
}

{
  const beam = makeBlock(api.SlingBlockKind.BEAM, {
    x: 110,
    y: 90,
    hp: 2,
    maxHp: 2,
    color: '#9ca3af'
  });
  const collapsed = api.collapseBlock(beam, makeEgg({ vx: 7.5, vy: 1.2 }), 1);
  const settled = updateBlockForFrames(api, collapsed, 240, groundY);
  assert.equal(settled.color, '#9ca3af', 'collapsed block should keep its material color');
  assert.ok(settled.y + rotatedBottomExtent(settled) <= groundY + 0.5, 'settled beam should not penetrate ground');
}

{
  const target = makeTarget();
  const collapsedTarget = api.collapseTarget(target, makeEgg({ vx: 6.2, vy: 0.8 }), 1);
  assert.equal(collapsedTarget.dynamic, true, 'target should become dynamic when its support collapses');
  const afterFall = updateTargetForFrames(api, collapsedTarget, 120, groundY);
  assert.ok(afterFall.y > target.y + 20, 'collapsed target should fall instead of floating at spawn height');
  assert.ok(afterFall.y + afterFall.radius <= groundY + 0.5, 'collapsed target should not penetrate ground');
}

console.log('EggSling physics tests passed');
