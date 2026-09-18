#!/usr/bin/env node
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';
const root = resolve(import.meta.dirname, '..');
const files = ['HubLayout.ets', 'HubWindow.ets'];
const source = files.map(file => readFileSync(resolve(root, 'entry/src/main/ets/design', file), 'utf8')).join('\n')
  .replace(/^import\s+.*;\n/gm, '').replace(/^export\s+/gm, '');
const code = stripTypeScriptTypes(source, { mode: 'transform' });
const deferred = () => {
  let resolve;
  const promise = new Promise(r => { resolve = r; });
  return { promise, resolve };
};
const tick = () => new Promise(r => setImmediate(r));
function fixture({ delayedLookup = false, delayedOrientation = false } = {}) {
  const lookup = deferred(); const orientation = deferred();
  const calls = []; const listeners = new Map(); const displayListeners = new Map();
  let environment; let foldStatus = 1;
  const oldBars = { statusBarContentColor: '#111111', navigationBarContentColor: '#222222' };
  const rect = (left, top, width, height) => ({ left, top, width, height });
  const host = {
    getPreferredOrientation: () => 5,
    getWindowSystemBarProperties: () => oldBars,
    on: (name, fn) => listeners.set(name, fn), off: (name) => listeners.delete(name),
    setPreferredOrientation: value => {
      calls.push(['orientation', value]);
      return delayedOrientation && value === 1 ? orientation.promise : Promise.resolve();
    },
    setWindowSystemBarProperties: value => { calls.push(['bars', value]); return Promise.resolve(); },
    getWindowProperties: () => ({ windowRect: rect(40, 60, 1200, 900) }),
    getWindowAvoidArea: type => ({
      topRect: rect(0, 0, 1200, type === 2 ? 80 : 48), bottomRect: rect(0, 0, 1200, type === 1 ? 40 : 0),
      leftRect: rect(0, 0, 0, 0), rightRect: rect(0, 0, 0, 0)
    })
  };
  const window = { getLastWindow: () => delayedLookup ? lookup.promise : Promise.resolve(host),
    Orientation: { UNSPECIFIED: 0, AUTO_ROTATION: 1 }, WindowEventType: { WINDOW_SHOWN: 1 },
    AvoidAreaType: { TYPE_SYSTEM: 0, TYPE_NAVIGATION_INDICATOR: 1, TYPE_CUTOUT: 2 } };
  const display = { on: (name, fn) => displayListeners.set(name, fn), off: name => displayListeners.delete(name),
    isFoldable: () => true, getFoldStatus: () => foldStatus,
    FoldStatus: { FOLD_STATUS_EXPANDED: 1, FOLD_STATUS_FOLDED: 2, FOLD_STATUS_UNKNOWN: 0 },
    getCurrentFoldCreaseRegion: () => ({ creaseRects: [rect(640, 60, 24, 900), rect(940, 60, 24, 900)] }) };
  const appContext = { on: (name, callback) => { environment = callback; return 7; },
    off: async (name, id) => { assert.equal(id, 7); environment = undefined; } };
  const app = { getApplicationContext: () => appContext };
  const context = { window, display, console };
  vm.runInNewContext(`${code}\nthis.HubWindowClass = HubWindow;`, context);
  const observer = new context.HubWindowClass();
  const samples = [];
  return { observer, host, calls, samples, listeners, displayListeners, lookup, orientation, oldBars,
    setStatus: value => { foldStatus = value; },
    configurationChanged: () => environment.onConfigurationUpdated(),
    attach: () => observer.attach(app, px => px / 2, (insets, creases) => samples.push({ insets, creases })) };
}
{
  const f = fixture();
  f.observer.setDark(true);
  await f.attach(); await tick();
  assert.equal(f.samples.at(-1).insets.top, 40, 'cutout and system insets are combined and converted to vp');
  assert.equal(f.samples.at(-1).insets.bottom, 20);
  assert.equal(f.samples.at(-1).creases.length, 0, 'flat displays must not be split at their physical folds');
  f.setStatus(3); f.observer.measure();
  assert.equal(f.samples.at(-1).creases.length, 2);
  assert.equal(f.samples.at(-1).creases[0].x, 300, 'screen-space hinges are translated into floating-window coordinates');
  f.setStatus(11); f.observer.measure();
  assert.equal(f.samples.at(-1).creases.length, 0, 'fully expanded triple-fold displays use the whole window');
  f.setStatus(23); f.configurationChanged();
  assert.equal(f.samples.at(-1).creases.length, 2);
  await f.observer.release();
  assert.equal(f.listeners.size, 0); assert.equal(f.displayListeners.size, 0);
  assert.equal(f.calls.at(-2)[1], 5); assert.equal(f.calls.at(-1)[1], f.oldBars);
  const count = f.samples.length; f.observer.measure(); assert.equal(f.samples.length, count);
  const writes = f.calls.length; await f.observer.release(); assert.equal(f.calls.length, writes, 'release is idempotent');
}
{
  const f = fixture({ delayedLookup: true });
  const attaching = f.attach();
  await f.observer.release(); f.lookup.resolve(f.host); await attaching;
  assert.equal(f.calls.length, 0, 'leaving before getLastWindow resolves must not change a game window');
  assert.equal(f.listeners.size, 0);
}
{
  const f = fixture({ delayedOrientation: true });
  const attaching = f.attach(); await tick();
  let released = false;
  const releasing = f.observer.release().then(() => { released = true; });
  await tick(); assert.equal(released, false, 'game entry waits for in-flight hub window writes');
  f.orientation.resolve(); await attaching; await releasing;
  assert.deepEqual(f.calls.filter(call => call[0] === 'orientation').map(call => call[1]), [1, 5]);
  assert.equal(f.calls.at(-1)[1], f.oldBars);
}
console.log('Hub window: safe-area conversion, flat/half/multi-fold states, listener cleanup and async game handoff passed.');
