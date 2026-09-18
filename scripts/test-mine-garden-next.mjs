#!/usr/bin/env node
import assert from 'node:assert/strict';
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const root = resolve(import.meta.dirname, '..');
const files = [
  'entry/src/main/ets/shell/AchievementModule.ets',
  'entry/src/main/ets/shell/GameModule.ets',
  'entry/src/main/ets/shell/GameRegistry.ets',
  'entry/src/main/ets/shell/AchievementRegistry.ets',
  'entry/src/main/ets/gamesNext/minesweeper/MineModel.ets',
  'entry/src/main/ets/gamesNext/minesweeper/MineEngine.ets',
  'entry/src/main/ets/gamesNext/minesweeper/MineLayout.ets',
  'entry/src/ohosTest/ets/test/MineGardenNext.test.ets'
];
const source = files.map(file => readFileSync(resolve(root, file), 'utf8')).join('\n')
  .replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export default /gm, '').replace(/^export /gm, '');
let passed = 0;
const context = {
  console,
  describe: (_name, run) => run(),
  it: (name, _flags, run) => { run(); passed++; console.log(`PASS ${name}`); },
  expect: actual => ({
    assertEqual: expected => assert.equal(actual, expected),
    assertTrue: () => assert.equal(actual, true),
    assertFalse: () => assert.equal(actual, false)
  }),
  TestType: { FUNCTION: 1 }, Size: { SMALLTEST: 2 }, Level: { LEVEL0: 4 }
};
vm.runInNewContext(stripTypeScriptTypes(source, { mode: 'transform' }) + '\nmineGardenNextTest();', context);
const assetRoot = resolve(root, 'entry/src/main/resources/rawfile/gamesNext/minesweeper');
for (const effect of ['open','flood','flag','unflag','tap','blocked','win','lose']) {
  const wav = readFileSync(resolve(assetRoot, `audio/${effect}.wav`));
  assert.equal(wav.toString('ascii', 0, 4), 'RIFF');
  assert.equal(wav.toString('ascii', 8, 12), 'WAVE');
  assert.ok(wav.length > 44);
  let peak = 0;
  for (let i = 44; i < wav.length; i += 2) peak = Math.max(peak, Math.abs(wav.readInt16LE(i)) / 32768);
  assert.ok(peak >= 0.2 && peak < 0.85, `${effect}: audible amplitude with headroom, peak=${peak}`);
}
for (const theme of ['light', 'dark']) {
  for (const tile of ['open', 'closed', 'flag', 'mine']) assert.ok(existsSync(resolve(assetRoot, `tiles/${tile}_${theme}.svg`)));
  for (const layer of ['garden', 'contour', 'fern_left', 'fern_right']) {
    assert.ok(existsSync(resolve(assetRoot, `scene/${layer}_${theme}.svg`)));
  }
}
for (const file of readdirSync(resolve(root, 'entry/src/main/ets/gamesNext/minesweeper'))) {
  const text = readFileSync(resolve(root, 'entry/src/main/ets/gamesNext/minesweeper', file), 'utf8');
  assert.ok(!text.includes('重构中'), `player-facing development wording in ${file}`);
  assert.ok(!text.includes("from '../../games/"), `legacy game dependency in ${file}`);
}
console.log(`\n${passed} pure-logic cases and resource/integration checks passed. Native gestures, audio and UI require device verification.`);
