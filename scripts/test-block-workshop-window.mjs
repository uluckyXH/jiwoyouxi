#!/usr/bin/env node
// Exercise the actual native adapter against display/window doubles, including event ordering.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
const base = new URL('../entry/src/main/ets/gamesNext/blockWorkshop/', import.meta.url);
const source = ['BlockLayout.ets', 'BlockWindow.ets'].map(name => readFileSync(new URL(name, base), 'utf8'))
  .join('\n').replace(/^import.*;\n/gm, '').replace(/^export /gm, '');
const code = stripTypeScriptTypes(source, { mode: 'transform' });
function fixture({ folded = 1, foldable = true, delayed = false } = {}) {
  const listeners = new Map(), native = new Map(), samples = [], writes = [];
  let status = folded, avoidError = false, creaseError = false, lookup;
  const host = {
    getPreferredOrientation: () => 5,
    getWindowSystemBarProperties: () => ({ statusBarContentColor: '#123456' }),
    on: (name, fn) => listeners.set(name, fn), off: name => listeners.delete(name),
    setPreferredOrientation: value => { writes.push(['orientation', value]); return Promise.resolve(); },
    setWindowSystemBarProperties: value => { writes.push(['bars', value]); return Promise.resolve(); },
    getWindowProperties: () => ({ windowRect: { left: 40, top: 60, width: 1200, height: 900 } }),
    getWindowAvoidArea: type => {
      if (avoidError) throw new Error('safe area unavailable');
      return { topRect: { height: type === 2 ? 80 : 48 }, bottomRect: { height: type === 1 ? 40 : 0 },
        leftRect: { width: 0 }, rightRect: { width: 0 } };
    }
  };
  const window = { getLastWindow: () => delayed ? new Promise(resolve => { lookup = resolve; }) : Promise.resolve(host),
    Orientation: { UNSPECIFIED: 0, AUTO_ROTATION: 1 },
    AvoidAreaType: { TYPE_SYSTEM: 0, TYPE_NAVIGATION_INDICATOR: 1, TYPE_CUTOUT: 2 },
    WindowEventType: { WINDOW_SHOWN: 1, WINDOW_HIDDEN: 2, WINDOW_INACTIVE: 3 } };
  const display = { isFoldable: () => foldable, getFoldStatus: () => status,
    on: (name, fn) => native.set(name, fn), off: name => native.delete(name),
    getCurrentFoldCreaseRegion: () => {
      if (creaseError) throw new Error('crease unavailable');
      return { creaseRects: [{ left: 40, top: 500, width: 1200, height: 20 }] };
    }
  };
  const context = { display, window, console: { warn: () => {} } };
  vm.runInNewContext(`${code}\nglobalThis.Observer=BlockWindow;globalThis.layout=blockLayout;`, context);
  const observer = new context.Observer();
  let backgrounds = 0;
  return { observer, listeners, native, samples, writes,
    get backgrounds() { return backgrounds; },
    get last() { return samples.at(-1); },
    get limited() { const s = samples.at(-1); return context.layout(800, 1000, s.insets, s.crease, s.fold).limited; },
    layoutAt: (width, height) => { const s = samples.at(-1); return context.layout(width, height, s.insets, s.crease, s.fold); },
    setStatus: value => { status = value; },
    failReads: () => { avoidError = true; creaseError = true; },
    resolveLookup: () => lookup(host),
    attach: () => observer.attach({}, px => px / 2, (insets, crease, fold) => samples.push({ insets, crease, fold }),
      () => { backgrounds++; })
  };
}
{
  const f = fixture({ foldable: false });await f.attach();
  assert.equal(f.last.fold.foldable, false);assert.equal(f.limited, false);
  assert.equal(f.last.insets.top, 40);assert.equal(f.last.insets.bottom, 20);
  f.listeners.get('windowEvent')(2);assert.equal(f.backgrounds, 1);
  f.observer.release();assert.equal(f.listeners.size, 0);assert.equal(f.native.size, 0);
  assert.equal(f.writes.at(-2)[1], 5);assert.equal(f.writes.at(-1)[1].statusBarContentColor, '#123456');
  console.log('PASS ordinary device uses safe areas and restores orientation/bars on release');
}
{
  const f = fixture({ folded: 2, delayed: true });const pending = f.attach();
  assert.equal(f.last.fold.status, 2);assert.equal(f.limited, false, 'fold status alone cannot block a usable window');
  f.resolveLookup();await pending;
  assert.equal(f.limited, false);assert.equal(f.last.crease.height, 0);
  assert.equal(f.layoutAt(390,844).limited,false);assert.equal(f.layoutAt(250,800).unfold,true);
  f.observer.release();
  console.log('PASS folded startup uses available space before and after async window lookup');
}
{
  const f = fixture();await f.attach();
  assert.equal(f.limited, false);
  f.native.get('foldStatusChange')(2);assert.equal(f.limited, false);
  f.listeners.get('avoidAreaChange')();f.native.get('foldDisplayModeChange')();
  assert.equal(f.last.fold.status, 2, 'a stale getter cannot overwrite the latest event during resize');
  f.native.get('foldStatusChange')(3);
  assert.equal(f.last.crease.x, 0);assert.equal(f.last.crease.y, 220);assert.equal(f.last.crease.height, 10);
  assert.equal(f.limited,false,'a roomy pane remains playable even with a half-fold crease');
  for (const status of [1,2,11,12]) {
    f.native.get('foldStatusChange')(status);
    assert.equal(f.last.crease.width,0,'flat multi-fold panels ignore the closed hinge');
    assert.equal(f.layoutAt(390,844).limited,false);
  }
  f.native.get('foldStatusChange')(1);assert.equal(f.limited, false);assert.equal(f.last.crease.width, 0);
  f.setStatus(2);f.listeners.get('windowEvent')(1);assert.equal(f.last.fold.status,2, 'foreground rechecks missed status');
  assert.equal(f.limited,false);assert.equal(f.layoutAt(250,800).unfold,true);
  const late = f.native.get('foldStatusChange');f.observer.release();const count = f.samples.length;
  late(1);f.observer.measure();assert.equal(f.samples.length, count);
  console.log('PASS fold event ordering, window-local crease conversion, foreground sync and late callbacks');
}
{
  const f = fixture();await f.attach();f.failReads();
  f.native.get('foldStatusChange')(3);assert.equal(f.limited, false);
  assert.equal(f.layoutAt(390,844).limited,false);assert.equal(f.layoutAt(250,800).unfold,true);
  f.native.get('foldStatusChange')(2);assert.equal(f.last.fold.status, 2);assert.equal(f.limited, false);
  f.native.get('foldStatusChange')(1);assert.equal(f.limited, false);f.observer.release();
  console.log('PASS unavailable safe-area/crease services cannot hide folded or unfolded events');
}
{
  const f = fixture({ delayed: true });const pending = f.attach();
  f.observer.release();const count = f.samples.length;f.resolveLookup();await pending;
  assert.equal(f.writes.length, 0);assert.equal(f.samples.length, count);
  assert.equal(f.listeners.size, 0);assert.equal(f.native.size, 0);
  console.log('PASS leaving during window lookup detaches fold callbacks without changing the next page');
}
console.log('\n5 native-adapter cases passed; physical device fold sensors still require device verification.');
