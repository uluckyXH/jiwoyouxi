#!/usr/bin/env node
// Host CPU benchmark only: this does not measure device frame rate or GPU cost.
// Optional first argument: an earlier MarketEngine.ets to compare in the same run.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import { performance } from 'node:perf_hooks';

const root = resolve(import.meta.dirname, '../entry/src/main/ets/gamesNext/fruitMarket');
async function load(path) {
  const source = (readFileSync(resolve(root, 'MarketModel.ets'), 'utf8') + '\n' + readFileSync(path, 'utf8'))
    .replace(/^import[\s\S]*?;\s*$/gm, '');
  return (await import('data:text/javascript;base64,' + Buffer.from(stripTypeScriptTypes(source, { mode: 'transform' })).toString('base64'))).MarketEngine;
}
function fixture(Engine, count) {
  const engine = new Engine(731);
  engine.round.nextId = count + 1;
  // Small, non-merging fruit isolates sustained contact-solver cost. Twelve columns
  // fit the crate; locked merges keep the workload equal between implementations.
  for (let i = 0; i < count; i++) engine.round.bodies.push({ id: i + 1, level: 0,
    x: 31 + (i % 12) * 26, y: 480 - Math.floor(i / 12) * 25,
    vx: (i % 5 - 2) * 8, vy: 0, angle: 0, born: 0, unlock: 1e9 });
  return engine;
}
function sample(Engine, count) {
  const engine = fixture(Engine, count);
  const start = performance.now();
  for (let frame = 0; frame < 600; frame++) engine.advance(1 / 60);
  const ms = (performance.now() - start) / 600;
  assert.equal(engine.round.ended, false, 'benchmark must not time an ended/idle game');
  assert.equal(engine.round.bodies.length, count);
  for (const body of engine.round.bodies) {
    assert.ok(Number.isFinite(body.x) && Number.isFinite(body.y));
    assert.ok(body.x >= 31 && body.x <= 329 && body.y <= 480);
  }
  return ms;
}
const current = await load(resolve(root, 'MarketEngine.ets'));
const before = process.argv[2] ? await load(resolve(process.argv[2])) : undefined;
for (const count of [24, 64, 120]) {
  sample(current, count);
  if (before) sample(before, count);
  const now = [], was = [];
  for (let run = 0; run < 5; run++) {
    if (before) was.push(sample(before, count));
    now.push(sample(current, count));
  }
  const median = values => values.sort((a, b) => a - b)[2];
  const next = median(now), previous = before ? median(was) : undefined;
  console.log(JSON.stringify({ fruits: count, framesPerSample: 600, medianOf: 5,
    currentMsPerFrame: +next.toFixed(4), previousMsPerFrame: previous && +previous.toFixed(4),
    reductionPercent: previous && +(100 * (1 - next / previous)).toFixed(1) }));
}
