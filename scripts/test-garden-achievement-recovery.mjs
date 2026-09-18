#!/usr/bin/env node
// Execute real game input handlers, rules, page save/retry/restart methods, Index
// gateway, AchievementService, and Preferences adapters. Only platform IO, UI,
// audio and timers are replaced. This does not claim native rendering coverage.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
const root = new URL('../entry/src/main/ets/', import.meta.url);
const read = path => readFileSync(new URL(path, root), 'utf8');
const clean = source => source.replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export /gm, '').replace(/^@Observed\s*/gm, '');
const plain = value => JSON.parse(JSON.stringify(value));
function method(source, name) {
  const start = source.search(new RegExp(`^  private (?:async )?${name}\\(`, 'm'));
  assert.ok(start >= 0, `real method ${name} must exist`);
  const lineEnd = source.indexOf('\n', start);
  const oneLine = source.slice(start, lineEnd);
  return oneLine.endsWith('}') ? oneLine : source.slice(start, source.indexOf('\n  }', start) + 4);
}
const noop = () => {};
const drain = () => new Promise(resolve => setImmediate(resolve));
let stores, failAchievements, failGame, failRead, holdAchievement, writes;
function resetStorage() {
  stores = new Map(); failAchievements = false; failGame = false; failRead = false;
  holdAchievement = undefined; writes = [];
}
resetStorage();
// put/flush remain separate; only a successful flush reaches the durable map.
const preferences = { async getPreferences(_context, { name }) {
  const pending = new Map();
  const durable = () => {
    if (!stores.has(name)) stores.set(name, new Map());
    return stores.get(name);
  };
  return {
    async get(key, fallback) {
      if (key === 'achievement_state' && failRead) throw Error('injected achievement read failure');
      return durable().get(key) ?? fallback;
    },
    async put(key, value) { pending.set(key, value); },
    async flush() {
      const achievement = pending.has('achievement_state');
      if (achievement && holdAchievement) await holdAchievement;
      if (achievement ? failAchievements : failGame) throw Error('injected write failure');
      for (const [key, value] of pending) { durable().set(key, value); writes.push({ name, key, value }); }
      pending.clear();
    }
  };
}};
const runtime = { console: { log: console.log, warn: noop }, preferences,
  Curve: { EaseOut: 0 }, clearTimeout: noop, setTimeout: () => 1 };
const commonFiles = ['shell/AchievementModule.ets', 'shell/GameModule.ets', 'shell/AchievementRegistry.ets',
  'shell/AchievementEngine.ets', 'shell/AchievementNotice.ets', 'app/CoopStorage.ets', 'app/AchievementService.ets'];
const common = vm.runInNewContext(stripTypeScriptTypes(clean(commonFiles.map(read).join('\n') +
  '\nclass Gateway {\n' + method(read('pages/Index.ets'), 'reportAchievementEvent') + '\n}'), { mode: 'transform' }) +
  '\n({Gateway,AchievementService,CoopStorage,emptyAchievementState,achievementGroupsForState,achievementNoticeItemsForUnlocks})', runtime);
function gateway() {
  const g = new common.Gateway();
  Object.assign(g, { appContext: {}, activeGame: 'hub', achievementService: new common.AchievementService(), notices: [] });
  g.enqueueAchievementNotices = result => g.notices.push(...common.achievementNoticeItemsForUnlocks(result.newlyUnlocked));
  return g;
}
function pageLib(folder, pageName, files, methods, exports) {
  const source = files.map(file => read(`gamesNext/${folder}/${file}.ets`)).join('\n');
  const controller = read(`gamesNext/${folder}/${pageName}.ets`);
  return vm.runInNewContext(stripTypeScriptTypes(clean(source + '\nclass Page {\n' +
    methods.map(name => method(controller, name)).join('\n') + '\n}'), { mode: 'transform' }) +
    `\n({Page,${exports}})`, { ...runtime });
}
const mine = pageLib('minesweeper', 'MineGardenPage', ['MineModel', 'MineEngine', 'MineStorage'],
  ['boot', 'act', 'settle', 'sync', 'defaultMessage', 'newRound', 'save', 'retrySave', 'saveAndExit'], 'MineEngine,MineStorage');
const glow = pageLib('glow2048', 'GlowPage', ['GlowModel', 'GlowEngine', 'GlowRenderTile', 'GlowStorage'],
  ['boot', 'move', 'finishMotion', 'sync', 'reportMilestone', 'reportEnd', 'preserveAchievements', 'newRound', 'save', 'retrySave', 'saveAndExit'],
  'GlowEngine,GlowStorage,glowMax');
const freecell = pageLib('warmFreecell', 'FreecellRoomPage', ['FreecellModel', 'FreecellSession', 'FreecellStorage'],
  ['boot', 'canPlay', 'move', 'newGame', 'save', 'reportWin', 'saveAndExit'], 'FreecellSession,FreecellStorage');
const kinds = ['mine', 'glow', 'freecell'];
const configs = {
  mine: { lib: mine, Engine: mine.MineEngine, Storage: mine.MineStorage, store: 'mine_garden_next_v1', route: 'minesweeperNext',
    restart: p => p.newRound('normal'), retry: p => p.retrySave(), report: p => p.settle(),
    badges: ['minesweeper.first_clear', 'minesweeper.quick_clear', 'minesweeper.perfect_flags'] },
  glow: { lib: glow, Engine: glow.GlowEngine, Storage: glow.GlowStorage, store: 'glow_2048_next_v1', route: 'chicken2048Next',
    restart: p => p.newRound(), retry: p => p.retrySave(), report: p => p.reportEnd(),
    badges: ['chicken2048.reach_256', 'chicken2048.reach_1024', 'chicken2048.reach_2048'] },
  freecell: { lib: freecell, Engine: freecell.FreecellSession, Storage: freecell.FreecellStorage, store: 'warm_freecell_next_v1', route: 'freecellNext',
    restart: p => p.newGame(false), retry: p => p.reportWin(), report: p => p.reportWin(),
    badges: ['freecell.complete_board', 'freecell.efficient_win', 'freecell.quick_win'] }
};
function page(kind, g = gateway()) {
  const c = configs[kind], p = new c.lib.Page();
  Object.assign(p, { engine: new c.Engine(), storage: new c.Storage(), gateway: g, context: {},
    loaded: true, loading: false, disposed: false, saving: false, saveFailed: false, achievementSaveFailed: false,
    reportingSession: '', dialog: '', returnDialog: '', returnMode: '', phase: 'ready', flagMode: false, viewport: { scrolls: false },
    tiles: [], sessionKey: '', merged: [], animationToken: 0, settleTimer: -1, turnKey: 0, busy: false,
    skipSave: false, skipExitSave: false, scores: [], events: [], exited: 0, revision: 0,
    audio: { play: noop, silence: noop }, captureTime: noop, syncClock: noop, relayout: noop,
    stopAuto: noop, clearIntent: noop, cancelDrag: noop, deal: noop,
    getUIContext: () => ({ animateTo: (_options, change) => change() }) });
  if (kind === 'freecell') {
    p.sync = noop; p.finishMotion = noop; p.scheduleFinish = () => { p.busy = false; };
    p.present = mode => { p.dialog = mode; };
  }
  p.exitToHub = () => { p.exited++; };
  p.recordScore = score => p.scores.push(score);
  p.reportAchievementEvent = event => { p.events.push(plain(event)); return g.reportAchievementEvent(event); };
  g.activeGame = c.route;
  p.sync(); return p;
}
const state = () => common.CoopStorage.loadAchievementState({});
const rawRound = kind => stores.get(configs[kind].store)?.get('round');
const isUnlocked = (s, id) => s.progresses.some(p => p.achievementId === id && p.unlockedAt > 0);
async function expectWall(kind, expected = [true, true, true]) {
  // Read with a new service instance, then use the same projection as the wall.
  const fresh = new common.AchievementService();
  const s = await fresh.initialize({});
  const items = common.achievementGroupsForState(s, 'all').flatMap(g => g.items);
  configs[kind].badges.forEach((id, index) => {
    assert.equal(isUnlocked(s, id), expected[index], id);
    const item = items.find(item => item.id === id || item.definition?.id === id);
    assert.ok(item, `${id} must be visible on the achievement wall`);
    assert.equal(item.status === 'unlocked', expected[index], `${id} wall status`);
  });
  return s;
}
async function playMine(p, { level = 'easy', elapsed = 180000, flags = true, corrected = false } = {}) {
  p.engine.reset(level, 42); p.sync();
  p.act(Math.floor(p.level.rows / 2) * p.level.cols + Math.floor(p.level.cols / 2), false);
  p.engine.advance(elapsed);
  if (corrected) {
    const safe = p.engine.cells.find(c => !c.mine && !c.open); assert.ok(safe);
    p.act(safe.index, true); p.act(safe.index, true);
  }
  if (flags) for (const cell of p.engine.cells) if (cell.mine) p.act(cell.index, true);
  for (const cell of p.engine.cells) if (!cell.mine && !cell.open) p.act(cell.index, false);
  assert.equal(p.engine.phase, 'won'); await drain();
}
async function mergeGlow(p, value = 1024, direction = 'down') {
  p.engine.tiles = [0, ['left', 'right'].includes(direction) ? 1 : 4].map((index, i) => ({ id: i + 1, index, value: value / 2 }));
  p.engine.nextId = 3; p.engine.moves = 0; p.sync();
  p.move(direction); p.finishMotion(true); await drain();
  assert.equal(glow.glowMax(p.engine.tiles), value);
}
async function endGlow(p) {
  p.engine.tiles = [2,4,8,16,32,64,128,256,512,1024,2,4,8,16,32].map((value,index) => ({id:index+1,index,value}));
  p.engine.nextId = 16; p.engine.moves = 13; p.sync();
  p.move('right'); p.finishMotion(true); assert.equal(p.engine.ended, true); await drain();
}
async function winFreecell(p, { elapsed = 900, finalMoves } = {}) {
  p.engine.newGame(42); p.engine.elapsed = elapsed;
  for (let step = 0; step < 52; step++) {
    const move = p.engine.suggestions().find(m => m.target >= 12); assert.ok(move, `legal foundation move ${step}`);
    if (step === 51 && finalMoves !== undefined) p.engine.moves = finalMoves - 1;
    assert.equal(p.move(move.card, move.target), true);
  }
  assert.equal(p.engine.won(), true); await drain();
}
async function finish(kind, p) {
  if (kind === 'mine') await playMine(p);
  else if (kind === 'glow') await endGlow(p);
  else await winFreecell(p);
}
let count = 0;
async function test(name, action) {
  resetStorage(); await action(); await drain(); count++; console.log(`PASS ${name}`);
}
await test('探雷三种难度：通过实际点击和插旗通关，3 分钟边界及改正错旗均可领取三枚成就', async () => {
  for (const level of ['easy', 'normal', 'hard']) {
    resetStorage(); const p = page('mine'); await playMine(p, { level, corrected: true });
    await expectWall('mine'); assert.equal(p.engine.reported, true);
    assert.equal(p.events.length, 1); assert.equal(p.gateway.notices.length, 4); // three badges + first completion
    const snapshots = writes.filter(w => w.name === configs.mine.store).map(w => JSON.parse(w.value));
    assert.ok(snapshots.some(s => s.phase === 'won' && !s.reported));
    assert.equal(snapshots.at(-1).reported, true);
  }
});
await test('探雷未达标不会误领：超过 3 分钟、通关自动补旗和踩雷', async () => {
  const p = page('mine'); await playMine(p, { elapsed: 180001, flags: false });
  await expectWall('mine', [true, false, false]);
  resetStorage(); const q = page('mine'); q.engine.reset('easy', 42); q.sync(); q.act(40, false);
  q.act(q.engine.cells.find(c => c.mine).index, false); await drain();
  assert.equal(q.engine.phase, 'lost'); await expectWall('mine', [false, false, false]);
  assert.equal((await state()).completedSessionCount, 1);
});
await test('2048：四个方向均经真实移动回调触发 256 / 512 / 1024 成就，无需结束本局', async () => {
  for (const direction of ['left', 'right', 'up', 'down']) for (const [i, value] of [256,512,1024].entries()) {
    resetStorage(); const p = page('glow'); await mergeGlow(p, value, direction);
    await expectWall('glow', [true, i >= 1, i >= 2]);
    assert.equal((await state()).completedSessionCount, 0);
    assert.equal(p.events.length, 1); assert.equal(p.gateway.notices.length, i + 1);
  }
});
await test('2048：低于 256 或无效滑动均不产生达标成就', async () => {
  const p = page('glow'); await mergeGlow(p, 128); await expectWall('glow', [false, false, false]);
  assert.equal(p.events.length, 0);
  p.engine.tiles = [{id:1,index:0,value:128}]; p.sync(); p.move('left'); p.finishMotion(true); await drain();
  assert.equal(p.events.length, 0);
});
await test('接龙：从真实发牌逐步合法归位，通过页面移牌触发三枚成就', async () => {
  const p = page('freecell'); await winFreecell(p); await expectWall('freecell');
  assert.equal(p.engine.moves, 52); assert.equal(p.engine.reported, true);
  assert.equal(p.events.length, 1); assert.equal(p.gateway.notices.length, 4);
});
await test('接龙：200 步和 15 分钟含边界；超出不解锁；未通关不结算', async () => {
  for (const [moves, elapsed, expected] of [[200,900,[true,true,true]], [201,901,[true,false,false]]]) {
    resetStorage(); const p = page('freecell'); await winFreecell(p, { finalMoves:moves, elapsed });
    await expectWall('freecell', expected);
  }
  resetStorage(); const p = page('freecell'); await p.reportWin();
  assert.equal(p.events.length, 0); assert.equal((await state()).completedSessionCount, 0);
});
for (const kind of kinds) {
  await test(`${kind}：成就保存失败 → 实际重开被保护 → 实际重试入口补报 → 再开新局不重复结算`, async () => {
    const c = configs[kind], p = page(kind); failAchievements = true; await finish(kind, p);
    const session = p.engine.session;
    assert.equal(p.engine.reported, false); assert.equal(p.saveFailed, true); assert.equal(p.scores.length, 0);
    assert.equal(JSON.parse(rawRound(kind)).reported, false);
    await c.restart(p); await drain(); assert.equal(p.engine.session, session);
    await p.save(); assert.equal(p.saveFailed, true, 'background game saves must not erase the retry warning');
    assert.equal((await state()).completedSessionCount, 0);
    failAchievements = false; await c.retry(p); await drain(); await expectWall(kind);
    assert.equal(p.engine.reported, true); assert.equal(p.saveFailed, false);
    assert.equal(JSON.parse(rawRound(kind)).reported, true);
    await c.report(p); await c.retry(p); assert.equal(p.scores.length, 1);
    assert.equal((await state()).completedSessionCount, 1);
    await c.restart(p); await drain(); assert.notEqual(p.engine.session, session);
    assert.equal((await state()).completedSessionCount, 1);
  });
  await test(`${kind}：成就失败时保存退出保留结果，恢复存储后退出可补报`, async () => {
    const p = page(kind); failAchievements = true; await finish(kind, p);
    const session = p.engine.session; await p.saveAndExit(); assert.equal(p.exited, 0);
    assert.equal(p.engine.session, session); assert.equal(JSON.parse(rawRound(kind)).reported, false);
    failAchievements = false; await p.saveAndExit(); assert.equal(p.exited, 1);
    assert.equal((await state()).completedSessionCount, 1); await expectWall(kind);
  });
  await test(`${kind}：进度存储也失败时不提前确认，存储恢复后可以完成上报`, async () => {
    const p = page(kind); failGame = true; await finish(kind, p);
    assert.equal(p.engine.reported, false); assert.equal(p.events.length, 0); assert.equal(p.saveFailed, true);
    failGame = false; await configs[kind].retry(p); await drain();
    assert.equal(p.engine.reported, true); assert.equal((await state()).completedSessionCount, 1);
  });
  await test(`${kind}：回执尚未完成时点重开不能覆盖结果，重复回调只计一次`, async () => {
    let release; holdAchievement = new Promise(resolve => { release = resolve; });
    const p = page(kind); await finish(kind, p); const session = p.engine.session;
    await configs[kind].restart(p); assert.equal(p.engine.session, session); assert.equal(p.engine.reported, false);
    release(); holdAchievement = undefined; await drain(); assert.equal(p.engine.reported, true);
    await configs[kind].report(p); assert.equal((await state()).completedSessionCount, 1);
    assert.equal(p.scores.length, 1);
  });
  await test(`${kind}：未确认存档重新进游戏可补报，再次恢复仍只计一局`, async () => {
    failAchievements = true; const p = page(kind); await finish(kind, p); p.disposed = true;
    const session = p.engine.session; failAchievements = false;
    const restored = page(kind); await restored.boot(); await drain();
    assert.equal(restored.engine.session, session); assert.equal(restored.engine.reported, true);
    await expectWall(kind); assert.equal((await state()).completedSessionCount, 1);
    const again = page(kind); await again.boot(); await drain();
    assert.equal(again.engine.session, session); assert.equal((await state()).completedSessionCount, 1);
  });
}
await test('2048 未结束里程碑写入失败：重开不丢徽章，重试可解锁但不增加完成局数', async () => {
  const p = page('glow'); failAchievements = true; await mergeGlow(p);
  const session = p.engine.session; assert.equal(p.saveFailed, true);
  await p.newRound(); assert.equal(p.engine.session, session);
  failAchievements = false; await p.retrySave(); await expectWall('glow'); assert.equal(p.saveFailed, false);
  await p.newRound(); assert.notEqual(p.engine.session, session);
  assert.equal((await state()).completedSessionCount, 0);
});
await test('2048 已确认结算重新进入：里程碑恢复失败仍能通过重试补报，不重复计局', async () => {
  const p = page('glow'); await endGlow(p); assert.equal(p.engine.reported, true);
  failAchievements = true;
  const restored = page('glow'); await restored.boot(); await drain();
  assert.equal(restored.engine.reported, true); assert.equal(restored.saveFailed, true);
  assert.equal(restored.events.length, 1);
  failAchievements = false; await restored.retrySave();
  assert.equal(restored.events.length, 2); assert.equal(restored.saveFailed, false);
  assert.equal((await state()).completedSessionCount, 1);
});
await test('成就读取异常：禁止以空白覆盖已有勋章，读取恢复后继续补报', async () => {
  const g = gateway(); const first = page('glow', g); await mergeGlow(first);
  const before = stores.get('chicken_coop_games').get('achievement_state');
  failRead = true; const p = page('mine'); await playMine(p);
  assert.equal(p.engine.reported, false); assert.equal(stores.get('chicken_coop_games').get('achievement_state'), before);
  failRead = false; await p.retrySave(); await expectWall('mine'); await expectWall('glow');
});
await test('旧版来源被拒绝且六个旧路由不再绑定网关；六个重构路由均保留网关', async () => {
  const g = gateway();
  for (const id of ['rpsBattle','freecell','minesweeper','chicken2048','tetris','suika']) {
    assert.equal(await g.reportAchievementEvent({eventId:`legacy:${id}`,sessionId:`legacy:${id}`,gameId:id,
      type:'sessionEnd',occurredAt:Date.now(),isOfficial:true,facts:[]}), false);
  }
  assert.equal((await state()).completedSessionCount, 0);
  const source = read('pages/Index.ets');
  for (const [component, expected] of [['RpsBattlePage',false],['FreecellPage',false],['MinesweeperPage',false],
    ['Chicken2048Page',false],['TetrisPage',false],['SuikaPage',false],['CoopArenaPage',true],['FreecellRoomPage',true],
    ['MineGardenPage',true],['GlowPage',true],['BlockWorkshopPage',true],['FruitMarketPage',true]]) {
    const start = source.indexOf(`          ${component}({`); assert.ok(start >= 0, component);
    const props = source.slice(start, source.indexOf('\n          })', start));
    assert.equal(props.includes('reportAchievementEvent:'), expected, component);
  }
});
console.log(`\n${count} recovery/integration groups passed. Actual ArkUI rendering is outside this code test.`);
