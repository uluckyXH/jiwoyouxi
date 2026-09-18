#!/usr/bin/env node
// Exercise the actual page lifecycle methods with native UI/storage adapters stubbed.
// Layout and pause/input behavior are tested here; native fold events and visuals are separate.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';

const base = new URL('../entry/src/main/ets/gamesNext/fruitMarket/', import.meta.url);
const page = readFileSync(new URL('FruitMarketPage.ets', base), 'utf8');
function method(name) {
  const match = new RegExp(`^  private (?:async )?${name}\\(`, 'm').exec(page);
  assert.ok(match, `page method ${name} exists`);
  const start = page.indexOf('{', match.index);
  let depth = 1, end = start + 1;
  for (; depth > 0 && end < page.length; end++) {
    if (page[end] === '{') depth++;
    if (page[end] === '}') depth--;
  }
  assert.equal(depth, 0);
  return page.slice(match.index, end);
}
const methods = ['boot', 'start', 'stop', 'frame', 'touch', 'cancelTouch', 'draw', 'relayout',
  'sync', 'pause', 'resume', 'exitRequested', 'saveAndExit', 'preserveAchievements', 'report'].map(method).join('\n');
const logic = ['MarketModel.ets', 'MarketEngine.ets', 'MarketLayout.ets']
  .map(file => readFileSync(new URL(file, base), 'utf8')).join('\n');
const harness = `
const MARKET_PROFILE = false;
class PageHarness {
  constructor() {
    this.engine = new MarketEngine(123);
    this.insets = { top:24, bottom:20, left:0, right:0 };
    this.crease = { x:0, y:0, width:0, height:0 };
    this.pageWidth = 390; this.pageHeight = 844;
    this.viewport = marketLayout(this.pageWidth, this.pageHeight, this.insets);
    this.gameReady = true; this.disposed = false; this.dialogMode = '';
    this.booting = false; this.backgroundDuringBoot = false; this.helpReturn = '';
    this.hostContext = {}; this.bestScore = 0; this.dark = false;
    this.canvas = {}; this.canvasWidth = 366; this.canvasHeight = 529;
    this.touchId = -1; this.aiming = false;
    this.lastFrame = Date.now(); this.lastSave = Date.now();
    this.starts = 0; this.stops = 0; this.saves = 0; this.exits = 0; this.paints = 0;
    this.savingExit = false; this.saveFailed = false;
    this.achievementRequests=[];this.achievementRetryAt=0;this.achievementRetryPending=false;
    this.reportAchievementEvent=async()=>true;this.recordScore=()=>{};
    this.frameClock = { start: () => { this.starts++; }, stop: () => { this.stops++; } };
    this.sounds = { play: () => {}, silence: () => {} };
    this.renderer = { add: () => {}, draw: () => { this.paints++; return true; } };
    this.storage = { load: async () => '' };
    this.save = async () => { this.saves++; this.saved = this.engine.serialize(); return true; };
    this.exitToHub = () => { this.exits++; };
  }
  ${methods}
}
globalThis.makePage = () => new PageHarness();
`;
const source = (logic + '\n' + harness).replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export /gm, '');
const context = { Date, console, TouchType: { Down: 0, Up: 1, Cancel: 3 } };
vm.runInNewContext(stripTypeScriptTypes(source, { mode: 'transform' }), context);
const folded = { x: 0, y: 412, width: 390, height: 20 };
const unfolded = { x: 0, y: 0, width: 0, height: 0 };

{
  const p = context.makePage();
  p.engine.drop();
  for (let i = 0; i < 60; i++) p.engine.advance(1 / 60);
  p.start();
  p.touch({ type: 0, touches: [{ id: 1, x: 120, y: 100 }] });
  assert.equal(p.aiming, true);
  p.crease = folded; p.relayout();
  assert.equal(p.viewport.limited, true);
  assert.equal(p.dialogMode, 'pause');
  assert.equal(p.aiming, false);
  assert.equal(p.touchId, -1);
  assert.equal(p.saves, 1);
  const paused = p.engine.serialize();
  const paints = p.paints;
  // Even an already queued callback/gesture cannot advance the hidden board.
  p.dialogMode = ''; p.lastFrame = Date.now() - 5000;
  p.start(); p.frame(); p.draw();
  p.touch({ type: 0, touches: [{ id: 2, x: 150, y: 100 }] });
  p.touch({ type: 1, changedTouches: [{ id: 2, x: 150, y: 100 }] });
  assert.equal(p.engine.serialize(), paused);
  assert.equal(p.paints, paints);
  assert.equal(p.starts, 1);
  p.relayout(); assert.equal(p.saves, 1, 'repeated size events do not keep submitting the save');
  p.crease = unfolded; p.relayout();
  assert.equal(p.viewport.limited, false);
  assert.equal(p.dialogMode, 'pause');
  assert.equal(p.starts, 1, 'unfolding does not unexpectedly resume a live pile');
  assert.equal(p.engine.serialize(), paused);
  p.resume(); p.frame();
  assert.equal(p.starts, 2);
  assert.ok(p.engine.round.time - JSON.parse(paused).time < 0.05, 'paused wall time is not replayed');
  console.log('PASS tiny-pane pause preserves the round, cancels input and requires explicit resume');
}

{
  for (const dialog of ['pause', 'help', 'restart', 'resume', 'result']) {
    const p = context.makePage(); p.dialogMode = dialog;
    p.crease = folded; p.relayout();
    p.crease = unfolded; p.relayout();
    assert.equal(p.dialogMode, dialog);
    assert.equal(p.starts, 0);
  }
  const p = context.makePage(); p.start();
  p.pageWidth = 840; p.pageHeight = 1000;
  p.crease = { x:0, y:480, width:840, height:20 };
  const stops = p.stops;
  p.relayout();
  assert.equal(p.viewport.limited, false);
  assert.equal(p.dialogMode, '');
  assert.equal(p.stops, stops);
  assert.equal(p.saves, 0);
  console.log('PASS existing dialogs survive folding and a roomy half-fold keeps playing');
}

{
  for (const hasSave of [false, true]) {
    const p = context.makePage();
    if (hasSave) p.engine.drop();
    const saved = hasSave ? p.engine.serialize() : '';
    p.gameReady = false;
    p.storage.load = async () => saved;
    const loading = p.boot();
    p.crease = folded; p.relayout();
    await loading;
    assert.equal(p.gameReady, true);
    assert.equal(p.dialogMode, hasSave ? 'resume' : 'pause');
    assert.equal(p.starts, 0);
    assert.equal(p.engine.round.time, 0);
    assert.equal(p.engine.round.drops, hasSave ? 1 : 0);
    p.crease = unfolded; p.relayout();
    assert.equal(p.dialogMode, hasSave ? 'resume' : 'pause');
  }
  console.log('PASS folding during initial load or saved-round restore cannot start hidden simulation');
}

{
  const p = context.makePage();
  p.crease = folded; p.relayout();
  p.save = async () => false;
  await p.saveAndExit();
  assert.equal(p.exits, 0);
  assert.equal(p.savingExit, false);
  p.save = async () => true;
  p.dialogMode = 'help';
  const exit = p.saveAndExit.bind(p);
  let pending;
  p.saveAndExit = () => { pending = exit(); return pending; };
  p.exitRequested();
  assert.ok(pending);
  await pending;
  assert.equal(p.exits, 1, 'system back must not open an invisible dialog behind the size prompt');
  console.log('PASS tiny-screen exit honors save failures and remains reachable from system back');
}
console.log('4 page lifecycle cases passed. Native fold/cover-screen verification is still separate.');
