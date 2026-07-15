#!/usr/bin/env node

// 石头剪刀布大作战人数配置规则回归测试。
// 只加载 Types + Rules 里的纯函数，覆盖快捷档位、同步/独立人数、上限和时长校验。

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const projectRoot = resolve(import.meta.dirname, '..');
const sourceFiles = [
  'entry/src/main/ets/games/rpsBattle/RpsBattleTypes.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleRules.ets',
  'entry/src/main/ets/games/rpsBattle/RpsBattleModeConfig.ets'
];

function loadRpsBattleRules() {
  const source = sourceFiles
    .map((file) => readFileSync(resolve(projectRoot, file), 'utf8'))
    .join('\n')
    .replace(/^import\s+[\s\S]*?;\n/gm, '')
    .replace(/^export\s+/gm, '');
  const runtimeSource = stripTypeScriptTypes(source, { mode: 'transform' });
  const context = { Math: Math, Number: Number };
  vm.runInNewContext(`${runtimeSource}
globalThis.__rpsBattle = {
  RPS_BATTLE_MIN_COUNT_PER_FACTION,
  RPS_BATTLE_MAX_COUNT_PER_FACTION,
  RPS_BATTLE_MAX_TOTAL_ENTITIES,
  rpsBattleInitialCountForScale,
  rpsBattleCountsFromValue,
  rpsBattleTotalCount,
  rpsBattleClampCount,
  rpsBattleClampCounts,
  rpsBattleCanIncreaseCount,
  rpsBattleCanDecreaseCount,
  rpsBattleStepCount,
  rpsBattleScaleForCounts,
  rpsBattleClampDuration,
  rpsBattleCreateOptions,
  RPS_BATTLE_MODES,
  RPS_BATTLE_MODE_RULES,
  rpsBattleModeByKey,
  rpsBattleModeRulesByKey
};
`, context);
  return context.__rpsBattle;
}

const R = loadRpsBattleRules();
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

function plain(value) {
  return JSON.parse(JSON.stringify(value));
}

function assertPlainEqual(actual, expected) {
  assert.deepEqual(plain(actual), expected);
}

console.log('\n石头剪刀布大作战人数规则测试\n');

test('快捷档位人数正确', () => {
  assert.equal(R.rpsBattleInitialCountForScale('small'), 5);
  assert.equal(R.rpsBattleInitialCountForScale('standard'), 8);
  assert.equal(R.rpsBattleInitialCountForScale('large'), 12);
  assert.equal(R.rpsBattleInitialCountForScale('custom'), 8);
});

test('同步增加会三方一起加', () => {
  const next = R.rpsBattleStepCount({ rock: 8, scissors: 8, paper: 8 }, 'rock', 1, true);
  assertPlainEqual(next, { rock: 9, scissors: 9, paper: 9 });
});

test('同步减少不会低于每方下限', () => {
  const next = R.rpsBattleStepCount({ rock: 3, scissors: 3, paper: 3 }, 'paper', -1, true);
  assertPlainEqual(next, { rock: 3, scissors: 3, paper: 3 });
  assert.equal(R.rpsBattleCanDecreaseCount(next, 'rock', true), false);
});

test('同步增加不会超过 20/20/20', () => {
  const counts = { rock: 20, scissors: 20, paper: 20 };
  const next = R.rpsBattleStepCount(counts, 'scissors', 1, true);
  assertPlainEqual(next, counts);
  assert.equal(R.rpsBattleCanIncreaseCount(counts, 'rock', true), false);
});

test('独立模式只调整选中阵营', () => {
  const next = R.rpsBattleStepCount({ rock: 8, scissors: 8, paper: 8 }, 'paper', 1, false);
  assertPlainEqual(next, { rock: 8, scissors: 8, paper: 9 });
  assert.equal(R.rpsBattleScaleForCounts(next), 'custom');
});

test('独立模式总人数不能超过 60', () => {
  const counts = { rock: 20, scissors: 20, paper: 20 };
  assert.equal(R.rpsBattleCanIncreaseCount(counts, 'paper', false), false);
  assertPlainEqual(R.rpsBattleStepCount(counts, 'paper', 1, false), counts);
});

test('独立模式总数 59 时允许补到 60', () => {
  const next = R.rpsBattleStepCount({ rock: 20, scissors: 19, paper: 20 }, 'scissors', 1, false);
  assertPlainEqual(next, { rock: 20, scissors: 20, paper: 20 });
  assert.equal(R.rpsBattleTotalCount(next), 60);
});

test('数量和时长校验稳定', () => {
  assert.equal(R.rpsBattleClampCount(Number.NaN), 3);
  assertPlainEqual(R.rpsBattleClampCounts({ rock: 99, scissors: -1, paper: 8 }), {
    rock: 20,
    scissors: 3,
    paper: 8
  });
  assert.equal(R.rpsBattleClampDuration(90), 90);
  assert.equal(R.rpsBattleClampDuration(45), 60);
});

test('启动参数使用三方人数并校验时长', () => {
  const options = R.rpsBattleCreateOptions({ rock: 5, scissors: 8, paper: 12 }, 120, 'rock');
  assertPlainEqual(options.initialCounts, { rock: 5, scissors: 8, paper: 12 });
  assert.equal(options.durationSec, 120);
  assert.equal(options.supportFaction, 'rock');
  assert.equal(options.modeKey, 'classic');
  const zonesOptions = R.rpsBattleCreateOptions({ rock: 5, scissors: 8, paper: 12 }, 120, 'rock', 'zones');
  assert.equal(zonesOptions.modeKey, 'zones');
});

test('玩法方案配置包含四个原版入口', () => {
  assert.equal(R.RPS_BATTLE_MODES.length, 4);
  assert.equal(R.RPS_BATTLE_MODE_RULES.length, 4);
  assert.equal(R.rpsBattleModeByKey('classic').name, '经典乱斗');
  assert.equal(R.rpsBattleModeByKey('zones').objective, '占点到100或限时领先');
  assert.deepEqual(plain(R.rpsBattleModeByKey('zones').enabledMechanics), ['中心据点', '黑洞']);
  assert.deepEqual(plain(R.rpsBattleModeByKey('zones').upcomingMechanics), [
    '绝地求生',
    '能量道具',
    '团队道具'
  ]);
  assert.equal(R.rpsBattleModeByKey('zones').mechanicOptions.length, 5);
  assert.equal(R.rpsBattleModeByKey('zones').mechanicOptions[0].key, 'controlZone');
  assert.equal(R.rpsBattleModeByKey('zones').mechanicOptions[0].state, 'core');
  assert.equal(R.rpsBattleModeByKey('zones').mechanicOptions[0].canDisable, false);
  assert.equal(R.rpsBattleModeByKey('zones').mechanicOptions[1].key, 'blackHole');
  assert.equal(R.rpsBattleModeByKey('zones').mechanicOptions[1].state, 'enabled');
  assert.equal(R.rpsBattleModeByKey('zones').mechanicOptions[1].canDisable, false);
  assert.equal(R.rpsBattleModeRulesByKey('classic').hasControlZone, false);
  assert.equal(R.rpsBattleModeRulesByKey('zones').hasControlZone, true);
  assert.equal(R.rpsBattleModeRulesByKey('zones').hasBlackHole, true);
  assert.equal(R.rpsBattleModeRulesByKey('zones').hasLastStand, false);
  assert.equal(R.rpsBattleModeRulesByKey('zones').hasPowerUps, false);
  assert.equal(R.rpsBattleModeRulesByKey('zones').hasTeamPowerUps, false);
  assert.equal(R.rpsBattleModeByKey('traitor').mechanics.includes('叛徒'), true);
  assert.equal(R.rpsBattleModeByKey('equality').subtitle, '响指 · 障碍');
  assert.equal(R.rpsBattleModeByKey('missing').key, 'classic');
  assert.equal(R.rpsBattleModeRulesByKey('missing').key, 'classic');
});

console.log(`\n通过 ${passed} 项，失败 ${failed} 项\n`);

if (failed > 0) {
  process.exit(1);
}
