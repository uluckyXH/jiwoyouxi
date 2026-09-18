#!/usr/bin/env node
// Golden trajectories captured before the v4 hot-loop optimization. No native FPS claims.
import assert from 'node:assert/strict';
import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
const base = new URL('../entry/src/main/ets/gamesNext/coopArena/', import.meta.url);
const fixture = new URL('fixtures/coop-arena-v3-trajectories.json', import.meta.url);
const record = process.argv.find(v => v.startsWith('--record-baseline='));
const engineSource = record ? readFileSync(record.slice('--record-baseline='.length), 'utf8') : readFileSync(new URL('ArenaEngine.ets', base), 'utf8');
const source = (readFileSync(new URL('ArenaModel.ets', base), 'utf8') + '\n' + engineSource)
  .replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export /gm, '');
const { ArenaEngine, arenaDefaultConfig } = vm.runInNewContext(stripTypeScriptTypes(source, { mode: 'transform' }) + '\n({ArenaEngine,arenaDefaultConfig})');
const cases = [];
for (const faction of [0, 1, 2]) cases.push({ ...arenaDefaultConfig(), seed: 3032101680, counts: [20,20,20], event: 'traitor', faction });
for (const count of [8, 12, 20]) for (const event of ['none','garden','wind','traitor','shrink']) {
  cases.push({ ...arenaDefaultConfig(), mode: 'zones', seed: 72391 + count, counts: [count,count,count], event });
}
for (let mission = 0; mission < 8; mission++) for (let faction = 0; faction < 3; faction++) {
  cases.push({ ...arenaDefaultConfig(), mode: 'challenge', mission, faction });
}
function run(config) {
  let engine = new ArenaEngine(config);
  const hash = createHash('sha256');
  const checkpoint = () => {
    const round = JSON.parse(engine.serialize()); delete round.session;
    hash.update(JSON.stringify({ round, effects: engine.effects, sounds: engine.sounds }));
  };
  checkpoint();
  for (let n = 0; n < 5500 && !engine.round.finished; n++) {
    if (n % 30 === 0) {
      const f = config.faction, own = engine.round.entities.find(e => e.faction === f);
      engine.cast(f, 0, 360, 360);
      if (own) {
        engine.cast(f, 1, own.x, own.y);
        if (n === 900 || n === 2100) engine.cast(f, 2, own.x, own.y);
      }
    }
    engine.step();
    if (n % 60 === 0 || engine.round.finished) checkpoint();
    // Exercise restoring old-format saves in the middle of an active scene as well.
    if (n === 749 && !engine.round.finished) {
      const restored = new ArenaEngine(); assert.equal(restored.restore(engine.serialize()), true); engine = restored;
    }
    engine.sounds.length = 0;
  }
  assert.equal(engine.round.finished, true);
  return { config, digest: hash.digest('hex'), tick: engine.round.tick, winner: engine.round.winner, stars: engine.round.stars };
}
const expected = record ? [] : JSON.parse(readFileSync(fixture, 'utf8')).cases;
const results = cases.map((config, i) => {
  const result = run(config);
  if (!record) assert.deepEqual(JSON.parse(JSON.stringify(result)), expected[i], `trajectory ${i + 1}: ${config.mode}/${config.event}, ${config.counts}, faction ${config.faction}, mission ${config.mission}`);
  console.log(`${record ? 'RECORD' : 'PASS'} trajectory ${i + 1}/${cases.length}: ${config.mode}/${config.event}, ${config.counts.reduce((a,b)=>a+b)} units, faction ${config.faction}, mission ${config.mission + 1}`);
  return result;
});
if (record) writeFileSync(fixture, JSON.stringify({ baseline: '64f40e7', description: 'Unmodified v3 engine; one-second checkpoints, input commands and mid-round save restore; session ID excluded.', cases: results }, null, 2) + '\n');
else { assert.equal(expected.length, results.length); console.log(`\n${results.length} exact pre-optimization trajectories passed.`); }
