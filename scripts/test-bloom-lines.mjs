#!/usr/bin/env node
// Execute the real ArkTS rules, progress bridge, page controller and Index gateway.
// Only OS Preferences, ArkUI drawing/timers and audio devices are replaced.
import assert from 'node:assert/strict';
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
const root = new URL('../', import.meta.url);
const read = path => readFileSync(new URL(path, root), 'utf8');
const main = path => read('entry/src/main/ets/' + path);
const plain = value => JSON.parse(JSON.stringify(value));
const clean = text => text.replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export default /gm, '')
  .replace(/^export /gm, '').replace(/^@Observed\s*$/gm, '');
const transpile = text => stripTypeScriptTypes(clean(text), { mode: 'transform' });
let count = 0;
async function test(name, run) { await run(); count++; console.log('PASS ' + name); }
const coreFiles = ['BloomModel', 'BloomRules', 'BloomEngine', 'BloomLayout', 'BloomDrag', 'BloomProgress'];
const coreSource = coreFiles.map(name => main('gamesNext/bloomLines/' + name + '.ets')).join('\n');
const core = vm.runInNewContext(transpile(coreSource) +
  '\n({ BloomEngine, BloomProgress, BloomDrag, bloomDropCell, bloomCellOrigin, bloomCanDrag, bloomPath, bloomReachable, bloomLinesAt, bloomAllLines, bloomConfig, bloomLayout, bloomViewport, bloomMilestone, bloomSettlement })', {});

// The same pure cases are compiled in entry@ohosTest and run here without a device.
vm.runInNewContext(transpile(coreSource + '\n' + read('entry/src/ohosTest/ets/test/BloomLines.test.ets')) +
  '\nbloomLinesTest();', {
  describe: (_name, run) => run(),
  it: (name, _kind, run) => { run(); count++; console.log('PASS ' + name); },
  expect: value => ({ assertEqual: expected => assert.equal(value, expected) }),
  TestType: { FUNCTION: 1 }, Size: { SMALLTEST: 1 }, Level: { LEVEL0: 1 }
});

function fixture(mode = 'garden') {
  const e = new core.BloomEngine(mode, 42); e.round.board.fill(-1); return e;
}
function prepareClear(e) {
  e.round.board.fill(-1);
  for (let i = 0; i < 4; i++) e.round.board[i] = 0;
  const from = core.bloomConfig(e.round.mode).size; e.round.board[from] = 0;
  return [from, 4];
}
function fullRound() {
  const e = fixture();
  e.round.board = e.round.board.map((_color, i) => (i % 7 + Math.floor(i / 7) * 2) % 5);
  e.round.board[0] = -1; e.move(1, 0);
  assert.equal(e.round.ended, true); return e;
}
await test('random play: legal paths, exact counts, bounded history and lossless saves in both modes', () => {
  let turns = 0;
  for (const mode of ['garden', 'classic']) for (let seed = 1; seed <= 40; seed++) {
    const e = new core.BloomEngine(mode, seed), size = core.bloomConfig(mode).size;
    for (let step = 0; step < 120 && !e.round.ended; step++) {
      const movable = e.round.board.map((c, i) => c >= 0 && core.bloomReachable(e.round.board, size, i).length ? i : -1).filter(i => i >= 0);
      assert.ok(movable.length, 'a non-full board must have a playable bead');
      const from = movable[(seed + step) % movable.length];
      const empty = core.bloomReachable(e.round.board, size, from);
      const to = empty[(seed * 3 + step * 5) % empty.length];
      const before = e.round.board.filter(c => c >= 0).length;
      const score = e.round.score, moves = e.round.moves;
      const turn = e.move(from, to); turns++;
      assert.equal(turn.valid, true);
      for (let i = 1; i < turn.path.length; i++) {
        const a = turn.path[i - 1], b = turn.path[i];
        assert.equal(Math.abs(a % size - b % size) + Math.abs(Math.floor(a / size) - Math.floor(b / size)), 1);
      }
      assert.equal(e.round.board.filter(c => c >= 0).length, before + turn.spawned.length + turn.refilled.length - turn.removed.length);
      assert.equal(e.round.score, score + turn.removed.length * 2);
      assert.equal(e.round.moves, moves + 1);
      assert.ok(e.history.length <= 20);
      assert.equal(e.round.ended, !e.round.board.includes(-1));
      assert.ok(e.round.board.some(c => c >= 0), 'clear-all must remain playable');
      assert.ok(e.round.board.every((c, i) => c < 0 || core.bloomLinesAt(e.round.board, size, i).length === 0));
      const restored = new core.BloomEngine();
      assert.equal(restored.restore(e.serialize()), true, mode + '/' + seed + '/' + step);
      assert.equal(restored.serialize(), e.serialize());
    }
  }
  assert.ok(turns > 1500); console.log('  verified legal turns: ' + turns);
});
await test('undo keeps only the last 20 moves and a reloaded undone branch cannot farm cleared beads', () => {
  const e = fixture();
  for (let i = 0; i < 25; i++) e.move(...prepareClear(e));
  assert.equal(e.history.length, 20); assert.equal(e.profile.totalCleared, 125);
  for (let i = 0; i < 20; i++) assert.equal(e.undo(), true);
  assert.equal(e.undo(), false); assert.equal(e.round.moves, 5);
  const restored = new core.BloomEngine(); assert.equal(restored.restore(e.serialize()), true);
  for (let i = 0; i < 20; i++) restored.move(...prepareClear(restored));
  assert.equal(restored.profile.totalCleared, 125);
  restored.move(...prepareClear(restored)); assert.equal(restored.profile.totalCleared, 130);
});
await test('malformed saves cannot overwrite a valid in-memory round', () => {
  const e = fixture(); e.move(...prepareClear(e)); const raw = e.serialize();
  const mutations = [
    s => { s.version = 2; }, s => { s.round.mode = 'wrong'; }, s => { s.round.board.pop(); },
    s => { s.round.board[0] = 1.5; }, s => { s.round.next = [1]; }, s => { s.round.seed = 0; },
    s => { s.round.score++; }, s => { s.round.moves = -1; }, s => { s.round.ended = true; },
    s => { s.round.reported = true; }, s => { s.profile.totalCleared = 0; }, s => { s.credited = 0; },
    s => { s.profile.bestGarden = 0; }, s => { s.history[0].session = 'other'; },
    s => { s.history[0].moves = s.round.moves; }, s => { s.history = Array(21).fill(s.history[0]); },
    s => { s.round.board.fill(0); s.round.ended = true; }
  ];
  for (const mutate of mutations) {
    const invalid = JSON.parse(raw); mutate(invalid);
    assert.equal(e.restore(JSON.stringify(invalid)), false); assert.equal(e.serialize(), raw);
  }
});
await test('layout matrix: no overlapping controls, exact cell geometry and scrollable small panes', () => {
  let cases = 0;
  for (const width of [200, 260, 320, 360, 390, 480, 600, 700, 800, 960, 1280, 1800])
    for (const height of [240, 400, 650, 780, 844, 1000, 1400])
      for (const mode of ['garden', 'classic']) {
        const l = core.bloomLayout(width, height, {top:24,bottom:16,left:0,right:0}, [], mode); cases++;
        const parts = ['stats','modes','queue','boardBox','tools','note'].map(k => l[k]).filter(r => r.height > 0);
        for (const r of parts) {
          assert.ok(r.x >= -1e-8 && r.y >= -1e-8);
          assert.ok(r.x + r.width <= l.contentWidth + 1e-8);
          assert.ok(r.y + r.height <= l.contentHeight + 1e-8);
        }
        for (let i = 0; i < parts.length; i++) for (let j = i + 1; j < parts.length; j++) {
          const a = parts[i], b = parts[j];
          const overlap = Math.min(a.x+a.width,b.x+b.width)-Math.max(a.x,b.x) > 1e-6 &&
            Math.min(a.y+a.height,b.y+b.height)-Math.max(a.y,b.y) > 1e-6;
          assert.equal(overlap, false, mode + '/' + width + '/' + height);
        }
        const size = core.bloomConfig(mode).size;
        assert.ok(Math.abs(l.tilePad * 2 + l.cell * size + l.tileGap * (size - 1) - l.board) < 1e-8);
        assert.ok(l.cell > 20);
      }
  console.log('  verified layouts: ' + cases);
});

function method(source, name) {
  const start = source.search(new RegExp('^  (?:private )?(?:async )?' + name + '\\(', 'm'));
  assert.ok(start >= 0, 'method ' + name);
  return source.slice(start, source.indexOf('\n  }', start) + 4);
}
const commonFiles = ['shell/AchievementModule.ets','shell/GameModule.ets','shell/AchievementRegistry.ets',
  'shell/AchievementEngine.ets','shell/AchievementNotice.ets','shell/AchievementFavoriteEvent.ets','app/AchievementService.ets'];
let durable, failAchievements = false;
const gatewaySource = '\nclass Gateway {\n' + method(main('pages/Index.ets'), 'reportAchievementEvent') + '\n}';
const api = vm.runInNewContext(transpile(commonFiles.map(main).join('\n') + gatewaySource) +
  '\n({ Gateway,AchievementService,emptyAchievementState,achievementNoticeItemsForUnlocks,achievementGroupsForState,' +
  'achievementSummaryForState,achievementProgressForState,favoriteAchievementEventForSnapshot,' +
  'ACHIEVEMENT_DEFINITIONS,ACHIEVEMENT_ORIGINAL_GAME_IDS })', {
    console,
    CoopStorage: {
      async loadAchievementState() { return plain(durable); },
      async saveAchievementState(_ctx, state) { if (failAchievements) return false; durable = plain(state); return true; }
    }
  });
function gateway() {
  durable = plain(api.emptyAchievementState()); failAchievements = false;
  const g = new api.Gateway();
  Object.assign(g, { appContext: {}, activeGame: 'bloomLines', achievementService: new api.AchievementService(), notices: [] });
  g.enqueueAchievementNotices = result => g.notices.push(...api.achievementNoticeItemsForUnlocks(result.newlyUnlocked));
  return g;
}
function bridge(e, g = gateway()) {
  const s = { raw: '', reports: [], records: [], failSave: false, failAck: false, writes: 0 };
  const p = new core.BloomProgress(e, {
    async save(raw) {
      s.writes++;
      if (s.failSave || s.failAck && JSON.parse(raw).round.reported) return false;
      s.raw = raw; return true;
    },
    async report(event) {
      assert.equal(event.gameId, 'bloomLines');
      assert.ok(s.raw.length > 0, 'game state must be persisted before reporting');
      s.reports.push(plain(event)); return g.reportAchievementEvent(event);
    },
    record(score) { s.records.push(score); }
  });
  return { p, s, g };
}
const unlocked = id => durable.progresses.some(p => p.achievementId === id && p.unlockedAt > 0);
await test('actual clears → persisted progress → Index → AchievementService → all three new SVG badges', async () => {
  const e = fixture(), {p, g} = bridge(e);
  assert.equal(await p.flush(), true); assert.equal(g.notices.length, 0);
  for (let i = 0; i < 6; i++) {
    if (i === 3) e.reset('classic', 73);
    e.move(...prepareClear(e)); assert.equal(await p.flush(), true);
    if (i === 0) assert.equal(unlocked('bloomLines.first_flower'), true);
    if (i === 2) assert.equal(unlocked('bloomLines.score_30'), true);
    if (i < 5) assert.equal(unlocked('bloomLines.collector'), false);
  }
  assert.equal(unlocked('bloomLines.collector'), true);
  assert.equal(durable.completedSessionCount, 0, 'clearing is not ending a round');
  const state = await new api.AchievementService().initialize({});
  const group = api.achievementGroupsForState(state, 'all').find(g => g.definition.id === 'bloomLines');
  assert.equal(group.items.length, 3);
  assert.ok(group.items.every(item => item.status === 'unlocked'));
  assert.ok(api.ACHIEVEMENT_DEFINITIONS.filter(d => d.gameId === 'bloomLines').every(d =>
    existsSync(new URL('entry/src/main/resources/rawfile/' + d.badgeAssetPath, root))));
  assert.equal(g.notices.length, 3);
});
await test('a game-save failure grants nothing; retry persists before unlocking exactly once', async () => {
  const e = fixture(), {p, s, g} = bridge(e); e.move(...prepareClear(e));
  s.failSave = true; assert.equal(await p.flush(), false);
  assert.equal(s.reports.length, 0); assert.equal(g.notices.length, 0);
  s.failSave = false; assert.equal(await p.flush(), true); assert.equal(g.notices.length, 1);
  assert.equal(await p.flush(), true); assert.equal(g.notices.length, 1);
});
await test('an achievement-write failure retries on resume from the saved game, including after undo', async () => {
  const e = fixture(), {p, s, g} = bridge(e); e.move(...prepareClear(e));
  failAchievements = true; assert.equal(await p.flush(), false);
  assert.equal(unlocked('bloomLines.first_flower'), false); assert.equal(g.notices.length, 0);
  const restored = new core.BloomEngine(); assert.equal(restored.restore(s.raw), true);
  restored.undo(); failAchievements = false;
  const retry = bridge(restored, g); assert.equal(await retry.p.flush(), true);
  assert.equal(unlocked('bloomLines.first_flower'), true);
  restored.move(...prepareClear(restored)); await retry.p.flush();
  assert.equal(restored.profile.totalCleared, 5); assert.equal(g.notices.length, 1);
});
await test('natural game-over reports once; failed acknowledgement and restart do not count it twice', async () => {
  const e = fullRound(), {p, s, g} = bridge(e);
  s.failAck = true; assert.equal(await p.flush(), false);
  assert.equal(durable.completedSessionCount, 1); assert.equal(e.round.reported, false);
  assert.equal(s.records.length, 0);
  const restored = new core.BloomEngine(); assert.equal(restored.restore(s.raw), true);
  const retry = bridge(restored, g); assert.equal(await retry.p.flush(), true);
  assert.equal(restored.round.reported, true); assert.equal(durable.completedSessionCount, 1);
  assert.equal(retry.s.records.length, 1);
  await retry.p.flush(); assert.equal(retry.s.records.length, 1);
  assert.equal(unlocked('global.first_settlement'), true);
});
await test('new games count toward ten rounds and favorites without replacing an original-six requirement', async () => {
  const g = gateway();
  for (let i = 0; i < 10; i++) assert.equal(await bridge(fullRound(), g).p.flush(), true);
  assert.equal(durable.completedSessionCount, 10); assert.equal(unlocked('global.complete_ten_sessions'), true);
  for (const id of api.ACHIEVEMENT_ORIGINAL_GAME_IDS.slice(0, 5)) await g.reportAchievementEvent({
    eventId:id+':end',sessionId:id,gameId:id+'Next',type:'sessionEnd',occurredAt:Date.now(),isOfficial:true,
    facts:[{key:'won',value:1}]
  });
  assert.equal(durable.playedGameIds.length, 6);
  assert.equal(unlocked('global.play_six_games'), false);
  assert.equal(api.achievementProgressForState(durable, 'global.play_six_games').current, 5);
  const last = api.ACHIEVEMENT_ORIGINAL_GAME_IDS[5];
  await g.reportAchievementEvent({eventId:last+':end',sessionId:last,gameId:last+'Next',type:'sessionEnd',
    occurredAt:Date.now(),isOfficial:true,facts:[{key:'score',value:0}]});
  assert.equal(unlocked('global.play_six_games'), true);
  const favorites = api.favoriteAchievementEventForSnapshot(['bloomLines','chicken2048Next','minesweeperNext'],Date.now());
  assert.ok(favorites); await g.reportAchievementEvent(favorites); assert.equal(unlocked('global.favorite_three'), true);
  assert.equal(await g.reportAchievementEvent({eventId:'legacy',sessionId:'legacy',gameId:'chicken2048',
    type:'sessionEnd',occurredAt:Date.now(),isOfficial:true,facts:[]}), false);
});

const pageSource = main('gamesNext/bloomLines/BloomPage.ets');
const pageMethods = ['boot','tap','beginInput','gridGeometry','dragStart','dragUpdate','dragEnd','dragCancel','returnBead',
  'playMove','advancePath','arrived','animateClear','afterClear','animateOpening','later','finishMotion',
  'syncCounters','sync','undo','chooseMode','requestRestart','newRound','present','closeDialog','relayout','backgrounded',
  'save','retrySave','saveAndExit'];
let timerSequence = 0;
const timers = new Map(), frames = [];
const pageRuntime = vm.runInNewContext(transpile(coreSource + '\nclass Page {\n' +
  pageMethods.map(name => method(pageSource, name)).join('\n') + '\n}') + '\n({Page})', {
    console, Curve:{EaseOut:0,Linear:1,EaseInOut:2},
    setTimeout: action => { const id = ++timerSequence; timers.set(id, action); return id; },
    clearTimeout: id => timers.delete(id),
    BloomReflow: class { constructor(action) { this.action = action; } }
  });
function controller(e = fixture()) {
  timers.clear(); frames.length = 0;
  const p = new pageRuntime.Page();
  Object.assign(p, {
    engine:e,loaded:true,loading:false,disposed:false,skipSave:false,backgroundPaused:false,context:{},
    animationToken:0,animationTimer:-1,currentTurn:undefined,returnDialog:'',layoutGeneration:0,saveSequence:0,
    selected:-1,drag:new core.BloomDrag(),reachable:[],gain:0,turn:0,busy:false,dialog:'',saving:false,saveFailed:false,hint:'',
    movingColor:-1,movingX:0,movingY:0,trail:[],born:[],birthScale:1,clearing:[],clearScale:1,pendingMode:'garden',
    pageWidth:390,pageHeight:844,insets:{top:24,bottom:16,left:0,right:0},creases:[],
    layout:core.bloomLayout(390,844,{top:24,bottom:16,left:0,right:0}),
    audio:{play(){},silence(){}}, storage:{async load(){return '';}},
    progress:{async flush(){return true;}}, exits:0,records:[],scrolls:[],
    verticalScroll:{scrollTo:opts=>p.scrolls.push(['v',opts])},horizontalScroll:{scrollTo:opts=>p.scrolls.push(['h',opts])},
    getUIContext(){return {animateTo:(_options,action)=>action(),postFrameCallback:cb=>frames.push(cb.action)};},
    exitToHub(){this.exits++;}, recordScore(score){this.records.push(score);}
  });
  p.sync(); return p;
}
function drainTimers() {
  let ticks=0;
  while(timers.size) {
    assert.ok(ticks++ < 200, 'effects must stop without an idle animation loop');
    const [id,action]=timers.entries().next().value;timers.delete(id);action();
  }
}
await test('real page input: one legal move through the entire movement/clear/refill animation', async () => {
  const e=fixture();prepareClear(e);const p=controller(e);
  p.tap(7);assert.equal(p.selected,7);p.tap(4);assert.equal(e.round.moves,1);assert.equal(p.busy,true);
  p.tap(8);assert.equal(e.round.moves,1);
  drainTimers();assert.equal(p.busy,false);assert.deepEqual(plain(p.board),plain(e.round.board));
  assert.equal(p.movingColor,-1);assert.equal(p.clearing.length,0);assert.equal(timers.size,0);
});
await test('folding while a bead travels cancels stale effects, retains the result and resets both scroll axes', () => {
  const e=fixture();e.round.board[0]=0;const p=controller(e);
  p.tap(0);p.tap(48);const committed=e.serialize();
  const stale=[...timers.values()];p.pageWidth=1280;p.pageHeight=900;p.relayout();
  assert.equal(timers.size,0);stale.forEach(action=>action());
  assert.equal(e.serialize(),committed);assert.equal(p.busy,false);assert.deepEqual(plain(p.board),plain(e.round.board));
  p.pageWidth=360;p.relayout();p.pageWidth=1280;p.relayout();
  frames.forEach(action=>action());
  assert.equal(p.scrolls.length,2,'only the newest layout generation resets scroll');
  assert.equal(p.layout.wide,true);assert.equal(p.movingColor,-1);
});
await test('backgrounding in the middle of clearing leaves a saved final board and no live timers', () => {
  const e=fixture();prepareClear(e);const p=controller(e);p.tap(7);p.tap(4);
  p.arrived();p.backgrounded();drainTimers();
  assert.equal(p.dialog,'pause');assert.equal(p.backgroundPaused,true);assert.equal(p.busy,false);
  assert.deepEqual(plain(p.board),plain(e.round.board));assert.equal(e.round.score,10);
});
await test('load failures and corrupt data never overwrite the existing save', async () => {
  for(const raw of ['broken','{"version":1}']) {
    const p=controller();p.loaded=false;let writes=0;p.progress.flush=async()=>{writes++;return true;};
    p.storage.load=async()=>raw;await p.boot();assert.equal(p.dialog,'corrupt');assert.equal(p.loaded,false);assert.equal(writes,0);
  }
  const p=controller();p.loaded=false;p.storage.load=async()=>{throw Error('offline storage');};
  await p.boot();assert.equal(p.dialog,'loadError');assert.equal(p.loaded,false);
});
await test('save-and-exit and restart preserve a round on failure; backgrounded restart stays paused', async () => {
  const e=fixture();e.round.board[0]=0;e.move(0,1);const p=controller(e),before=e.serialize();
  p.progress.flush=async()=>false;await p.saveAndExit();assert.equal(p.exits,0);assert.equal(p.dialog,'exit');
  await p.newRound();assert.equal(e.serialize(),before);assert.equal(p.saveFailed,true);
  p.progress.flush=async()=>true;p.backgroundPaused=true;p.pendingMode='classic';
  await p.newRound();assert.equal(e.round.mode,'classic');assert.equal(p.dialog,'pause');
  assert.equal(p.busy,false);assert.equal(timers.size,0);
  p.closeDialog();await p.saveAndExit();assert.equal(p.exits,1);
});

function dragTo(p, from, to, extraX=0, extraY=0) {
  const grid=p.gridGeometry(), origin=core.bloomCellOrigin(from,grid), target=core.bloomCellOrigin(to,grid);
  p.dragUpdate(from,target.x-origin.x+extraX,target.y-origin.y+extraY);
}
await test('unselected beads drag immediately, follow total offsets exactly and commit only on release', () => {
  const e=fixture();e.round.board[0]=0;const p=controller(e),before=e.serialize();
  const origin=core.bloomCellOrigin(0,p.gridGeometry());
  assert.equal(p.selected,-1);p.dragStart(0,4,2);
  assert.equal(p.drag.from,0);assert.equal(p.drag.x,origin.x+4);assert.equal(p.drag.y,origin.y+2);
  p.dragUpdate(0,18,20);p.dragUpdate(0,26,24);
  assert.equal(p.drag.x,origin.x+26);assert.equal(p.drag.y,origin.y+24,'offsets must not accumulate');
  assert.equal(e.serialize(),before);assert.equal(timers.size,0,'finger movement must not use a delayed animation');
  dragTo(p,0,48,2,-1);const point={x:p.drag.x,y:p.drag.y};assert.equal(p.drag.valid,true);
  p.dragEnd(0);assert.equal(e.round.moves,1);assert.equal(p.drag.from,-1);
  assert.equal(p.movingX,point.x);assert.equal(p.movingY,point.y,'handoff starts exactly where the hand released');
  assert.equal(p.trail.length,0,'drag must not replay the route from its original cell');
  p.dragEnd(0);assert.equal(e.round.moves,1,'a repeated up event cannot commit twice');
  drainTimers();assert.deepEqual(plain(p.board),plain(e.round.board));assert.equal(p.busy,false);
});
await test('drag uses the same legal path and clear rules, then reaches the real achievement wall', async () => {
  const e=fixture();prepareClear(e);const p=controller(e),progress=bridge(e);
  p.progress=progress.p;p.dragStart(7,3,0);dragTo(p,7,4);assert.equal(p.drag.valid,true);
  p.dragEnd(7);await progress.p.flush();
  assert.equal(e.round.score,10);assert.equal(e.profile.totalCleared,5);
  assert.equal(unlocked('bloomLines.first_flower'),true);drainTimers();
  assert.equal(e.round.moves,1);assert.deepEqual(plain(p.board),plain(e.round.board));
});
await test('unreachable and occupied drops return without consuming a turn, RNG, preview or achievements', () => {
  for(const target of [1,48]) {
    const e=fixture();e.round.board.fill(1);e.round.board[0]=0;e.round.board[48]=-1;
    const p=controller(e),before=e.serialize();p.dragStart(0,3,0);dragTo(p,0,target);
    assert.equal(p.drag.valid,false);p.dragEnd(0);
    assert.equal(e.serialize(),before);assert.equal(p.busy,true);drainTimers();
    assert.equal(e.serialize(),before);assert.deepEqual(plain(p.board),plain(e.round.board));
    assert.equal(p.movingColor,-1);assert.equal(p.selected,0);
  }
});
await test('dropping outside or cancelling a drag never clamps it into an edge cell', () => {
  for(const cancelled of [false,true]) {
    const e=fixture();e.round.board[0]=0;const p=controller(e),before=e.serialize();
    p.dragStart(0,3,0);p.dragUpdate(0,-100,200);assert.equal(p.drag.target,-1);
    if(cancelled)p.dragCancel(0);else p.dragEnd(0);
    drainTimers();assert.equal(e.serialize(),before);assert.equal(p.drag.from,-1);
    assert.deepEqual(plain(p.board),plain(e.round.board));
  }
});
await test('a new touch interrupts previous move/clear effects and stale callbacks cannot disturb it', () => {
  const e=fixture();e.round.board[0]=0;e.round.board[6]=1;const p=controller(e);
  p.tap(0);p.tap(1);assert.equal(p.busy,true);
  const stale=[...timers.values()];p.dragStart(6,4,0);assert.equal(p.drag.from,6);
  assert.equal(p.busy,false);dragTo(p,6,p.reachable[p.reachable.length-1]);assert.equal(p.drag.valid,true);p.dragEnd(6);
  const liveTimer=p.animationTimer;stale.forEach(action=>action());
  assert.equal(p.animationTimer,liveTimer);assert.equal(e.round.moves,2);
  drainTimers();assert.deepEqual(plain(p.board),plain(e.round.board));assert.equal(timers.size,0);
});
await test('folding, backgrounding and opening a dialog cancel a held bead without moving it', () => {
  for(const action of ['fold','background','help']) {
    const e=fixture();e.round.board[0]=0;const p=controller(e),before=e.serialize();
    p.dragStart(0,3,0);dragTo(p,0,48);
    if(action==='fold'){p.pageWidth=1280;p.pageHeight=900;p.relayout();}
    else if(action==='background')p.backgrounded();
    else p.present('help');
    p.dragUpdate(0,300,300);p.dragEnd(0);drainTimers();
    assert.equal(p.drag.from,-1);assert.equal(e.serialize(),before);
    assert.deepEqual(plain(p.board),plain(e.round.board));
  }
});
await test('tap selection still works; empty cells yield the pan to scrolling and blocked input cannot start a drag', () => {
  const e=fixture();e.round.board[0]=0;const p=controller(e);
  assert.equal(core.bloomCanDrag(true,-1,-1,1),false);
  assert.equal(core.bloomCanDrag(true,0,-1,0),true);
  assert.equal(core.bloomCanDrag(false,0,-1,0),false);
  assert.equal(core.bloomCanDrag(true,0,1,0),false);
  p.dragStart(1,5,0);assert.equal(p.drag.from,-1);
  p.dialog='help';p.dragStart(0,5,0);assert.equal(p.drag.from,-1);p.dialog='';
  p.tap(0);assert.equal(p.selected,0);p.tap(0);assert.equal(p.selected,-1);
  p.tap(0);p.tap(1);drainTimers();assert.equal(e.round.moves,1);
});

await test('SVG resources, same Home/scene logo, color-pattern variants and audible unclipped samples are bundled', () => {
  const assets=new URL('entry/src/main/resources/rawfile/gamesNext/bloomLines/',root);
  const files=readdirSync(assets,{recursive:true}).filter(file=>/\.(svg|wav)$/.test(file));
  const svgFiles=files.filter(file=>file.endsWith('.svg'));
  assert.equal(svgFiles.length,139);
  for(const path of svgFiles) {
    const svg=readFileSync(new URL(path,assets),'utf8');
    assert.match(svg,/<svg/);assert.match(svg,/viewBox=/);assert.doesNotMatch(svg,/<(?:script|image|text)\b|https?:\/\/(?!www\.w3\.org)/);
  }
  const sounds=files.filter(file=>file.endsWith('.wav'));assert.equal(sounds.length,7);
  for(const path of sounds) {
    const bytes=readFileSync(new URL(path,assets));
    assert.equal(bytes.toString('ascii',0,4),'RIFF');assert.equal(bytes.readUInt16LE(22),1);
    assert.equal(bytes.readUInt32LE(24),24000);assert.equal(bytes.readUInt16LE(34),16);
    let peak=0;for(let i=44;i<bytes.length;i+=2)peak=Math.max(peak,Math.abs(bytes.readInt16LE(i)));
    assert.ok(peak>9000&&peak<30000,path+' has a useful signal level without clipping');
  }
  assert.match(main('pages/HubPage.ets'),/'bloomLines'/);
  assert.match(main('shell/GameRegistry.ets'),/bloomLines.*gamesNext\/bloomLines\/scene\/logo.svg/);
  assert.match(pageSource,/\$rawfile\(BLOOM_LOGO\)/);
});
console.log('\nBloom Lines: ' + count + ' checks passed.');
