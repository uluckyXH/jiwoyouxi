#!/usr/bin/env node
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';

const source = readFileSync(new URL('../entry/src/main/ets/gamesNext/fruitMarket/MarketFrameClock.ets', import.meta.url), 'utf8')
  .replace(/^import.*$/gm, '').replace(/^export /gm, '');
function runtime(failure) {
  const handles = [], timers = new Map();
  let nextTimer = 1;
  const context = {
    displaySync: { create() {
      if (failure === 'create') throw new Error('unavailable');
      const handle = { stopped: 0, detached: 0,
        setExpectedFrameRateRange(range) { assert.equal(range.max, 60); },
        on(_type, callback) { this.callback = callback; },
        start() { if (failure === 'start') throw new Error('not supported'); },
        stop() { this.stopped++; }, off() { this.detached++; }
      };
      handles.push(handle); return handle;
    } },
    setInterval(callback, delay) { assert.ok(delay >= 1000 / 60); const id = nextTimer++; timers.set(id, callback); return id; },
    clearInterval(id) { timers.delete(id); }
  };
  vm.runInNewContext(stripTypeScriptTypes(source, { mode: 'transform' }) + '\nglobalThis.clock = new MarketFrameClock();', context);
  return { clock: context.clock, handles, timers };
}
{
  const { clock, handles, timers } = runtime();
  let frames = 0;
  clock.start(() => frames++);
  handles[0].callback(); assert.equal(frames, 1);
  clock.stop(); handles[0].callback(); assert.equal(frames, 1);
  clock.start(() => frames++);
  handles[0].callback(); assert.equal(frames, 1, 'queued frames from a previous run cannot advance a resumed round');
  handles[1].callback(); assert.equal(frames, 2);
  clock.start(() => frames++);
  assert.equal(timers.size, 0, 'supported devices have no competing interval');
  clock.stop(); clock.stop();
  assert.ok(handles.every(handle => handle.stopped === 1 && handle.detached === 1));
  console.log('PASS vsync start, pause, resume and duplicate start clean up callbacks');
}
for (const failure of ['create', 'start']) {
  const { clock, handles, timers } = runtime(failure);
  let frames = 0;
  clock.start(() => frames++);
  assert.equal(timers.size, 1);
  if (failure === 'start') {
    handles[0].callback();
    assert.equal(frames, 0, 'queued callback from failed native startup cannot race the fallback timer');
  }
  const previous = [...timers.values()][0]; previous(); assert.equal(frames, 1);
  clock.start(() => frames++);
  assert.equal(timers.size, 1);
  previous(); assert.equal(frames, 1);
  [...timers.values()][0](); assert.equal(frames, 2);
  clock.stop(); assert.equal(timers.size, 0);
  assert.ok(handles.every(handle => handle.stopped === 1 && handle.detached === 1));
  console.log(`PASS ${failure} failure falls back to one timer and releases it on pause`);
}
