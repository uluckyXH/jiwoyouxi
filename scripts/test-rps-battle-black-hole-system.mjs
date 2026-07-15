#!/usr/bin/env node

// 石头剪刀布大作战黑洞规则回归测试。
// 覆盖黑洞延迟激活、吸引、吞噬、成长和快照隔离。

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const projectRoot = resolve(import.meta.dirname, '..');
const sourceFiles = [
  'entry/src/main/ets/games/rpsBattle/RpsBattleTypes.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleBlackHoleSystem.ets'
];

function loadRpsBattleBlackHoleSystem() {
  const source = sourceFiles
    .map((file) => readFileSync(resolve(projectRoot, file), 'utf8'))
    .join('\n')
    .replace(/^import\s+[\s\S]*?;\n/gm, '')
    .replace(/^export\s+/gm, '');
  const runtimeSource = stripTypeScriptTypes(source, { mode: 'transform' });
  const context = { Math: Math, Number: Number };
  vm.runInNewContext(`${runtimeSource}
globalThis.__rpsBattleBlackHole = {
  RPS_BATTLE_BLACK_HOLE_INITIAL_RADIUS,
  RPS_BATTLE_BLACK_HOLE_INITIAL_REACH,
  RPS_BATTLE_BLACK_HOLE_MAX_RADIUS,
  RPS_BATTLE_BLACK_HOLE_MAX_REACH,
  RpsBattleBlackHoleSystem
};
`, context);
  return context.__rpsBattleBlackHole;
}

const B = loadRpsBattleBlackHoleSystem();
let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    passed += 1;
    console.log(`  ✓ ${name}`);
  } catch (error) {
    failed += 1;
    console.log(`  ✗ ${name}`);
    console.log(`      ${error.message}`);
  }
}

function queuedRandom(values) {
  let index = 0;
  return () => {
    const value = values[Math.min(index, values.length - 1)];
    index += 1;
    return value;
  };
}

function entity(id, faction, x, y) {
  return {
    id,
    faction,
    x,
    y,
    vx: 0,
    vy: 0,
    radius: 14,
    convertedAt: 0
  };
}

function assertApprox(actual, expected, tolerance = 0.000001) {
  assert.equal(Math.abs(actual - expected) <= tolerance, true, `${actual} not close to ${expected}`);
}

console.log('\n石头剪刀布大作战黑洞规则测试\n');

test('重置后黑洞未激活并设置首次出现时间', () => {
  const system = new B.RpsBattleBlackHoleSystem();
  system.reset(400, 300, queuedRandom([0]));
  const state = system.snapshot();
  assert.equal(state.active, false);
  assert.equal(state.x, 200);
  assert.equal(state.y, 150);
  assert.equal(state.radius, B.RPS_BATTLE_BLACK_HOLE_INITIAL_RADIUS);
  assert.equal(state.reach, B.RPS_BATTLE_BLACK_HOLE_INITIAL_REACH);
  assert.equal(state.nextAtSec, 9);
  assert.equal(state.swallowed, 0);
});

test('未到出现时间时不影响单位', () => {
  const system = new B.RpsBattleBlackHoleSystem();
  system.reset(400, 300, queuedRandom([1]));
  const item = entity(1, 'rock', 240, 150);
  const swallowed = system.update([item], 10, 1, 400, 300, queuedRandom([0.5, 0.5]));
  assert.equal(swallowed.length, 0);
  assert.equal(system.snapshot().active, false);
  assert.equal(item.vx, 0);
});

test('到时间后激活并吸引单位', () => {
  const system = new B.RpsBattleBlackHoleSystem();
  system.reset(400, 300, queuedRandom([0]));
  const item = entity(1, 'rock', 240, 150);
  const swallowed = system.update([item], 9, 1, 400, 300, queuedRandom([0.5, 0.5]));
  const state = system.snapshot();
  assert.equal(state.active, true);
  assert.equal(state.x, 200);
  assert.equal(state.y, 150);
  assert.equal(swallowed.length, 0);
  assert.equal(item.vx < 0, true);
  assertApprox(item.vy, 0);
});

test('进入核心范围会被吞噬并推动黑洞成长', () => {
  const system = new B.RpsBattleBlackHoleSystem();
  system.reset(400, 300, queuedRandom([0]));
  const item = entity(1, 'paper', 210, 150);
  const swallowed = system.update([item], 9, 1, 400, 300, queuedRandom([0.5, 0.5]));
  const state = system.snapshot();
  assert.equal(swallowed.length, 1);
  assert.equal(swallowed[0].id, 1);
  assertApprox(state.radius, B.RPS_BATTLE_BLACK_HOLE_INITIAL_RADIUS * 1.3);
  assertApprox(state.reach, B.RPS_BATTLE_BLACK_HOLE_INITIAL_REACH * 1.3);
  assert.equal(state.swallowed, 1);
});

test('吞噬后同帧立即扩大吸引范围', () => {
  const system = new B.RpsBattleBlackHoleSystem();
  system.reset(400, 300, queuedRandom([0]));
  const coreItem = entity(1, 'paper', 200, 150);
  const edgeItem = entity(2, 'rock', 290, 150);
  const swallowed = system.update([coreItem, edgeItem], 9, 1, 400, 300, queuedRandom([0.5, 0.5]));
  assert.equal(swallowed.length, 1);
  assert.equal(edgeItem.vx < 0, true);
});

test('成长不会超过上限', () => {
  const system = new B.RpsBattleBlackHoleSystem();
  system.reset(400, 300, queuedRandom([0]));
  const entities = [];
  for (let i = 0; i < 20; i += 1) {
    entities.push(entity(i + 1, 'scissors', 200, 150));
  }
  system.update(entities, 9, 1, 400, 300, queuedRandom([0.5, 0.5]));
  const state = system.snapshot();
  assert.equal(state.radius, B.RPS_BATTLE_BLACK_HOLE_MAX_RADIUS);
  assert.equal(state.reach, B.RPS_BATTLE_BLACK_HOLE_MAX_REACH);
  assert.equal(state.swallowed, 20);
});

test('快照不反向修改系统状态', () => {
  const system = new B.RpsBattleBlackHoleSystem();
  system.reset(400, 300, queuedRandom([0]));
  system.update([], 9, 1, 400, 300, queuedRandom([0.5, 0.5]));
  const snapshot = system.snapshot();
  snapshot.active = false;
  snapshot.swallowed = 99;
  const next = system.snapshot();
  assert.equal(next.active, true);
  assert.equal(next.swallowed, 0);
});

console.log(`\n通过 ${passed} 项，失败 ${failed} 项\n`);

if (failed > 0) {
  process.exit(1);
}
