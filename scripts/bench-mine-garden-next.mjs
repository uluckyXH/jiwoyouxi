#!/usr/bin/env node
// Host CPU measurements of the real rules, not a device FPS/GPU benchmark.
import { readFileSync, statSync, readdirSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import { performance } from 'node:perf_hooks';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const root = resolve(import.meta.dirname, '..');
const source = ['MineModel.ets', 'MineEngine.ets'].map(file =>
  readFileSync(resolve(root, 'entry/src/main/ets/gamesNext/minesweeper', file), 'utf8')).join('\n')
  .replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export /gm, '');
const { MineEngine, MINE_LEVELS } = vm.runInNewContext(
  stripTypeScriptTypes(source, { mode: 'transform' }) + '\n({ MineEngine, MINE_LEVELS });');

function measure(name, prepare, run, count = 2000) {
  const times = [];
  for (let i = 0; i < count + 200; i++) {
    const input = prepare(i);
    const start = performance.now();
    run(input);
    const duration = performance.now() - start;
    if (i >= 200) times.push(duration);
  }
  times.sort((a, b) => a - b);
  return { name, samples: count, p50Ms: +times[Math.floor(count * .5)].toFixed(4),
    p95Ms: +times[Math.floor(count * .95)].toFixed(4), maxMs: +times[count - 1].toFixed(4) };
}

const results = [];
for (const level of MINE_LEVELS) {
  const prepare = seed => {
    const engine = new MineEngine();
    engine.reset(level.key, seed + 1);
    return engine;
  };
  results.push(measure(`${level.key}: first reveal / generation + flood`, prepare, engine => {
    engine.open(0);
    assert.equal(engine.cells.filter(cell => cell.mine).length, level.mines);
  }));
  const played = seed => { const engine = prepare(seed); engine.open(0); return engine; };
  results.push(measure(`${level.key}: remaining safe cells to victory`, played, engine => {
    for (const cell of engine.cells) if (!cell.mine && !cell.open) engine.open(cell.index);
    assert.equal(engine.phase, 'won');
  }));
  results.push(measure(`${level.key}: view copy + counters + serialize`, played, engine => {
    engine.copyCells(); engine.flags(); engine.opened(); engine.serialize();
  }));
  const sample = played(34).serialize();
  results.push(measure(`${level.key}: validate + restore`, prepare, engine => assert.equal(engine.restore(sample), true)));
  results.push({ name: `${level.key}: snapshot size`, bytes: Buffer.byteLength(sample), cells: level.rows * level.cols });
}
const audioRoot = resolve(root, 'entry/src/main/resources/rawfile/gamesNext/minesweeper/audio');
const wavFiles = readdirSync(audioRoot).filter(name => name.endsWith('.wav'));
console.log(JSON.stringify({ runtime: process.version, platform: `${process.platform}/${process.arch}`,
  note: 'Host CPU only; timings exclude ArkUI, GPU, audio playback and preferences flush.', results,
  audio: { files: wavFiles.length, bytes: wavFiles.reduce((sum, name) => sum + statSync(resolve(audioRoot, name)).size, 0) }
}, null, 2));
