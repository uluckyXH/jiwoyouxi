#!/usr/bin/env node
// Exercise the real page controller with mocked platform boundaries; no UI DSL
// execution or copied controller implementation. Native rendering is manual QA.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const root = resolve(import.meta.dirname, '..');
const folder = 'entry/src/main/ets/gamesNext/glow2048/';
const clean = text => text.replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export /gm, '').replace(/^@Observed\s*/gm, '');
let page = readFileSync(resolve(root, folder, 'GlowPage.ets'), 'utf8');
page = page.slice(0, page.indexOf('  build() {')) + page.slice(page.indexOf('  private async boot()'));
page = clean(page).replace('@Component\nstruct GlowPage', 'class GlowPage')
  .replace(/@(Prop|State)(?:\s+@Watch\('[^']+'\))?\s*/g, '');
const core = ['GlowModel.ets', 'GlowEngine.ets', 'GlowRenderTile.ets', 'GlowLayout.ets', 'GlowReflow.ets'].map(file =>
  clean(readFileSync(resolve(root, folder, file), 'utf8'))).join('\n');
const timers = new Map();
let nextTimer = 1;
class Audio {
  played = []; silent = 0; released = false;
  play(effect) { this.played.push(effect); }
  silence() { this.silent++; }
  release() { this.released = true; }
  setEnabled() {}
}
class Storage {
  snapshots = []; ok = true; raw = ''; failLoad = false;
  async load() { if (this.failLoad) throw Error('load failure'); return this.raw; }
  async save(_context, raw) { this.snapshots.push(raw); return this.ok; }
}
class Window { release() {} setDark() {} }
class Scroll { calls = []; scrollTo(options) { this.calls.push(options); } }
class FrameCallback {}
const sandbox = { console, Scroller: Scroll, FrameCallback, Curve: { EaseOut: 0 }, GlowAudio: Audio, GlowStorage: Storage, GlowWindow: Window,
  setTimeout: fn => { const id = nextTimer++; timers.set(id, fn); return id; }, clearTimeout: id => timers.delete(id) };
vm.createContext(sandbox);
vm.runInContext(stripTypeScriptTypes(core + '\n' + page, { mode: 'transform' }) + '\nglobalThis.Page = GlowPage;', sandbox);

async function make(values = [2, 2, 4, 4]) {
  const controller = new sandbox.Page();
  const finishes = [];
  const frames = [];
  controller.getUIContext = () => ({ animateTo: (options, change) => { change(); if (options.onFinish) finishes.push(options.onFinish); }, postFrameCallback: callback => frames.push(callback) });
  controller.context = {};
  await controller.boot();
  const save = JSON.parse(controller.engine.serialize());
  save.tiles = values.map((value, index) => ({ id: index + 1, index, value })).filter(tile => tile.value > 0);
  save.nextId = Math.max(...save.tiles.map(tile => tile.id)) + 1;
  save.moves = save.nextId - 3;
  assert.equal(controller.engine.restore(JSON.stringify(save)), true);
  controller.sync();
  const scores = [], events = [];
  controller.recordScore = value => scores.push(value);
  controller.reportAchievementEvent = async event => { events.push(event); return true; };
  return { controller, finishes, frames, scores, events };
}
const board = tiles => JSON.stringify(tiles.map(({ id, value, index }) => ({ id, value, index })));
const rendered = page => board(page.tiles);
let passed = 0;
async function test(name, run) { await run(); passed++; console.log(`PASS ${name}`); timers.clear(); }

await test('rapid_input_has_one_pending_direction_and_stale_completions_cannot_replay', async () => {
  const { controller: p, finishes } = await make();
  const start = p.engine.moves;
  p.move('left'); p.move('up'); p.move('down');
  assert.equal(p.engine.moves, start + 1);
  const firstCompletion = finishes.shift();
  firstCompletion();
  assert.equal(p.engine.moves, start + 2);
  const finalBoard = p.engine.serialize();
  firstCompletion();
  assert.equal(p.engine.serialize(), finalBoard);
  finishes.shift()();
  assert.equal(p.busy, false);
  assert.equal(rendered(p), board(p.engine.tiles));
});

await test('downward_merges_update_the_same_objects_used_by_existing_tile_views', async () => {
  const { controller: p, finishes } = await make([2,0,0,0, 2,0,0,0, 4,0,0,0, 4]);
  // A stable-key ForEach keeps these view bindings across both animation phases.
  const bindings = new Map(p.tiles.map(tile => [tile.id, tile]));
  p.move('down');
  for (const motion of p.currentTurn.motions) {
    assert.equal(bindings.get(motion.id).index, motion.to);
  }
  finishes.shift()();
  assert.equal(bindings.get(13).value, 8);
  assert.equal(bindings.get(5).value, 4);
  assert.equal(bindings.get(5).index, 8);
  assert.strictEqual(p.tiles.find(tile => tile.id === 13), bindings.get(13));
  assert.strictEqual(p.tiles.find(tile => tile.id === 5), bindings.get(5));
  assert.equal(p.score, 12);
  assert.equal(p.maxTile, 8);
  assert.equal(rendered(p), board(p.engine.tiles));
  const saved = p.engine.serialize();
  p.relayout();
  assert.equal(p.engine.serialize(), saved);
});

await test('pause_during_slide_displays_and_saves_the_committed_result', async () => {
  const { controller: p, finishes } = await make();
  p.move('left');
  const saved = p.storage.snapshots.at(-1);
  assert.equal(saved, p.engine.serialize());
  p.present('pause');
  assert.equal(p.dialog, 'pause');
  assert.equal(p.busy, false);
  assert.equal(rendered(p), board(p.engine.tiles));
  const snapshot = p.engine.serialize();
  finishes.shift()();
  assert.equal(p.engine.serialize(), snapshot);
  assert.equal(p.dialog, 'pause');
});

await test('resize_during_slide_keeps_session_score_and_board', async () => {
  const { controller: p, finishes } = await make();
  p.move('left');
  const snapshot = p.engine.serialize();
  p.pageWidth = 1280; p.pageHeight = 800; p.relayout();
  assert.equal(p.engine.serialize(), snapshot);
  assert.equal(rendered(p), board(p.engine.tiles));
  assert.equal(p.layout.wide, true);
  assert.equal(p.gain, 0);
  assert.equal(p.merged.length, 0);
  assert.equal(p.spawned, 0);
  finishes.shift()();
  assert.equal(p.engine.serialize(), snapshot);
});

await test('repeated_folding_reflows_all_controls_and_only_latest_frame_resets_scroll', async () => {
  const { controller: p, finishes, frames } = await make();
  p.move('left');
  const round = p.engine.serialize();
  const windows = [
    [1200,900, []], [390,844, []], [1200,900, []],
    [768,1024, [{ x:0, y:490, width:768, height:24 }]],
    [1024,768, [{ x:480, y:0, width:24, height:768 }]],
    [390,844, []], [1280,900, []]
  ];
  for (let cycle=0; cycle<5; cycle++) {
    for (const [width,height,creases] of windows) {
      p.pageWidth=width; p.pageHeight=height; p.creases=creases; p.relayout();
      const l=p.layout;
      assert.ok(l.pad.x >= 0 && l.pad.y >= 0);
      assert.ok(l.pad.x+l.pad.width <= l.contentWidth);
      assert.ok(l.pad.y+l.pad.height <= l.contentHeight);
      assert.equal(p.engine.serialize(), round);
    }
  }
  assert.ok(frames.length > 30);
  const latest=frames.pop();
  for (const frame of frames.splice(0)) frame.onIdle(0);
  assert.equal(p.verticalScroll.calls.length, 0, 'old fold callbacks cannot move the new viewport');
  latest.onIdle(0);
  assert.deepEqual(JSON.parse(JSON.stringify(p.verticalScroll.calls)), [{xOffset:0,yOffset:0,animation:false}]);
  assert.equal(p.horizontalScroll.calls.length, 1);
  assert.equal(p.layout.wide, true);
  assert.equal(p.layout.width, 1280);
  assert.equal(rendered(p), board(p.engine.tiles));
  finishes.shift()();
  assert.equal(p.engine.serialize(), round);
  p.relayout();
  assert.equal(frames.length, 0, 'identical measurements preserve user scrolling');
  p.pageWidth=390; p.relayout();
  p.aboutToDisappear();
  for (const frame of frames) frame.onIdle(0);
  assert.equal(p.verticalScroll.calls.length, 1, 'no scrolling after route exit');
});

await test('background_cancels_pending_input_and_silences_audio', async () => {
  const { controller: p, finishes } = await make();
  p.move('left'); p.move('down');
  p.backgrounded();
  const snapshot = p.engine.serialize();
  assert.equal(p.dialog, 'pause');
  assert.equal(p.queued, undefined);
  assert.ok(p.audio.silent > 0);
  finishes.shift()();
  assert.equal(p.engine.serialize(), snapshot);
  p.move('right');
  assert.equal(p.engine.serialize(), snapshot);
});

await test('fallback_finishes_once_when_native_animation_callback_is_suppressed', async () => {
  const { controller: p, finishes } = await make();
  p.move('left');
  [...timers.values()][0]();
  assert.equal(p.busy, false);
  assert.equal(rendered(p), board(p.engine.tiles));
  const turn = p.turnKey;
  finishes.shift()();
  assert.equal(p.turnKey, turn);
});

await test('2048_interrupted_by_pause_still_offers_continue_once', async () => {
  const { controller: p, finishes, events } = await make([1024, 1024]);
  p.move('left'); p.present('pause');
  assert.equal(p.dialog, 'pause');
  p.closeDialog();
  assert.equal(p.dialog, 'win');
  p.closeDialog();
  assert.equal(p.engine.continued, true);
  assert.equal(p.dialog, '');
  assert.equal(p.score, 2048);
  assert.equal(events.filter(event => event.type === 'milestone').length, 1);
  finishes.shift()();
  assert.equal(events.length, 1);
});

await test('restart_invalidates_old_motion_without_counting_an_unfinished_session', async () => {
  const { controller: p, finishes, scores, events } = await make();
  p.move('left'); p.newRound();
  const snapshot = p.engine.serialize();
  finishes.shift()();
  assert.equal(p.engine.serialize(), snapshot);
  assert.equal(p.engine.moves, 0);
  assert.equal(p.engine.tiles.length, 2);
  assert.equal(scores.length, 1);
  assert.equal(events.filter(event => event.type === 'sessionEnd').length, 0);
});

await test('failed_exit_save_keeps_the_page_open_and_retry_can_leave', async () => {
  const { controller: p } = await make();
  let exits = 0;
  p.exitToHub = () => exits++;
  p.storage.ok = false;
  await p.saveAndExit();
  assert.equal(exits, 0);
  assert.equal(p.dialog, 'exit');
  assert.equal(p.saveFailed, true);
  p.storage.ok = true;
  await p.saveAndExit();
  assert.equal(exits, 1);
  assert.equal(p.skipSave, true);
});

await test('restore_requires_resume_and_load_failure_does_not_overwrite_progress', async () => {
  const { controller: first, finishes } = await make();
  first.move('left'); finishes.shift()();
  const { controller: p } = await make();
  p.storage.raw = first.engine.serialize();
  await p.boot();
  assert.equal(p.dialog, 'resume');
  const snapshot = p.engine.serialize();
  p.move('up');
  assert.equal(p.engine.serialize(), snapshot);
  p.storage.failLoad = true;
  const writes = p.storage.snapshots.length;
  await p.boot();
  assert.equal(p.dialog, 'loadError');
  assert.equal(p.storage.snapshots.length, writes);
});

await test('leaving_during_motion_releases_resources_and_ignores_late_callbacks', async () => {
  const { controller: p, finishes } = await make();
  p.move('left'); p.aboutToDisappear();
  const snapshot = p.engine.serialize();
  assert.equal(p.audio.released, true);
  assert.equal(timers.size, 0);
  finishes.shift()();
  assert.equal(p.engine.serialize(), snapshot);
});
console.log(`\n${passed} controller lifecycle cases passed; platform rendering and gestures remain device QA.`);
