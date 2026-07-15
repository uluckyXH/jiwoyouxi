#!/usr/bin/env node

// 石头剪刀布大作战团队占点规则回归测试。
// 覆盖中心据点 owner、僵持、不涨分、100 分胜利和快照隔离。

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const projectRoot = resolve(import.meta.dirname, '..');
const sourceFiles = [
  'entry/src/main/ets/games/rpsBattle/RpsBattleTypes.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleRules.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleZoneSystem.ets'
];

function loadRpsBattleZoneSystem() {
  const source = sourceFiles
    .map((file) => readFileSync(resolve(projectRoot, file), 'utf8'))
    .join('\n')
    .replace(/^import\s+[\s\S]*?;\n/gm, '')
    .replace(/^export\s+/gm, '');
  const runtimeSource = stripTypeScriptTypes(source, { mode: 'transform' });
  const context = { Math: Math, Number: Number };
  vm.runInNewContext(`${runtimeSource}
globalThis.__rpsBattleZone = {
  RPS_BATTLE_CONTROL_ZONE_MAX_SCORE,
  RpsBattleZoneSystem
};
`, context);
  return context.__rpsBattleZone;
}

const Z = loadRpsBattleZoneSystem();
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

function plain(value) {
  return JSON.parse(JSON.stringify(value));
}

console.log('\n石头剪刀布大作战团队占点规则测试\n');

test('初始化中心据点位置和半径', () => {
  const system = new Z.RpsBattleZoneSystem();
  system.reset(400, 300);
  const zone = system.snapshot();
  assert.equal(zone.x, 200);
  assert.equal(zone.y, 150);
  assert.equal(zone.radius, 45);
  assert.equal(zone.owner, '');
  assert.equal(zone.capturingFaction, '');
  assert.equal(zone.score, 0);
});

test('唯一最多阵营占点并按人数涨分', () => {
  const system = new Z.RpsBattleZoneSystem();
  system.reset(400, 300);
  const inside = system.update([
    entity(1, 'rock', 200, 150),
    entity(2, 'rock', 210, 150),
    entity(3, 'paper', 220, 150)
  ], 1);
  const zone = system.snapshot();
  assert.equal(inside, 3);
  assert.equal(zone.owner, 'rock');
  assert.equal(zone.capturingFaction, 'rock');
  assertApprox(zone.score, 5.6);
  assert.deepEqual(plain(zone.pressure), { rock: 2, scissors: 0, paper: 1 });
});

test('僵持时不切换 owner 且不涨分', () => {
  const system = new Z.RpsBattleZoneSystem();
  system.reset(400, 300);
  system.update([
    entity(1, 'rock', 200, 150),
    entity(2, 'rock', 210, 150)
  ], 1);
  const before = system.snapshot().score;
  system.update([
    entity(3, 'rock', 200, 150),
    entity(4, 'scissors', 210, 150)
  ], 1);
  const zone = system.snapshot();
  assert.equal(zone.owner, 'rock');
  assert.equal(zone.capturingFaction, '');
  assertApprox(zone.score, before);
});

test('无人进入据点时不涨分', () => {
  const system = new Z.RpsBattleZoneSystem();
  system.reset(400, 300);
  system.update([entity(1, 'paper', 200, 150)], 1);
  const before = system.snapshot().score;
  const inside = system.update([], 1);
  const zone = system.snapshot();
  assert.equal(inside, 0);
  assert.equal(zone.owner, 'paper');
  assert.equal(zone.capturingFaction, '');
  assertApprox(zone.score, before);
});

test('据点满分后返回胜者', () => {
  const system = new Z.RpsBattleZoneSystem();
  system.reset(400, 300);
  system.update([
    entity(1, 'paper', 200, 150),
    entity(2, 'paper', 210, 150),
    entity(3, 'paper', 220, 150)
  ], 12);
  const zone = system.snapshot();
  assert.equal(zone.score, Z.RPS_BATTLE_CONTROL_ZONE_MAX_SCORE);
  assert.equal(system.finishWinner(), 'paper');
});

test('快照不反向修改系统状态', () => {
  const system = new Z.RpsBattleZoneSystem();
  system.reset(400, 300);
  system.update([entity(1, 'scissors', 200, 150)], 1);
  const snapshot = system.snapshot();
  snapshot.score = 0;
  snapshot.pressure.scissors = 99;
  const next = system.snapshot();
  assert.equal(next.owner, 'scissors');
  assertApprox(next.score, 2.8);
  assert.equal(next.pressure.scissors, 1);
});

console.log(`\n通过 ${passed} 项，失败 ${failed} 项\n`);

if (failed > 0) {
  process.exit(1);
}
