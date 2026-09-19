#!/usr/bin/env node
// Real game rules + real page reporters + Index gateway + achievement persistence.
// Only native UI, audio, timers and Preferences are replaced. No simulator is used.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
const root = new URL('../entry/src/main/ets/', import.meta.url);
const read = path => readFileSync(new URL(path, root), 'utf8');
const clean = source => source.replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export /gm, '');
function method(source, name) {
  const start = source.search(new RegExp(`^  private (?:async )?${name}\\(`, 'm'));
  assert.ok(start >= 0, name);
  return source.slice(start, source.indexOf('\n  }', start) + 4);
}
const plain = value => JSON.parse(JSON.stringify(value));
let durable, failWrite = false, failRead = false, writes = 0, persistedFavorites = [];
const CoopStorage = {
  async load() { if (failRead) throw Error('read unavailable'); return {favorites:[...persistedFavorites]}; },
  async loadAchievementState() { if (failRead) throw Error('read unavailable'); return plain(durable); },
  async saveAchievementState(_context, state) { writes++; if (failWrite) return false; durable = plain(state); return true; }
};
const commonFiles = ['shell/AchievementModule.ets', 'shell/GameModule.ets', 'shell/AchievementRegistry.ets',
  'shell/AchievementEngine.ets', 'shell/AchievementNotice.ets', 'shell/AchievementFavoriteEvent.ets', 'app/AchievementService.ets'];
const commonCode = commonFiles.map(read).join('\n') + '\nclass Gateway {' +
  ['reportAchievementEvent','reportFavoriteAchievement','reconcileFavoriteAchievements','refreshAchievementState','tryShowAchievementNotice',
    'suspendAchievementNotices','clearAchievementNoticeTimers','closeGameAnimated']
    .map(name=>method(read('pages/Index.ets'),name)).join('\n') + '\n}';
const common = vm.runInNewContext(stripTypeScriptTypes(clean(commonCode), {mode:'transform'}) + `\n({
  AchievementService,Gateway,emptyAchievementState,applyAchievementEvent,achievementSummaryForState,
  achievementGroupsForState,achievementNoticeItemsForUnlocks,ACHIEVEMENT_DEFINITIONS,isGameHidden,
  favoriteAchievementEventAfterPersist,achievementCanonicalGameId,achievementPrimaryFavoriteCount})`,
  {CoopStorage,console,setTimeout:()=>1,clearTimeout:()=>{},CoopMotion:{achievementNoticeEnterDuration:180,achievementNoticeNormalHoldDuration:2000},Curve:{Friction:0}});
function reset() {
  durable = plain(common.emptyAchievementState()); failWrite = false; failRead = false; writes = 0;
  const gateway = new common.Gateway(); gateway.appContext = {}; gateway.activeGame = 'hub';
  gateway.achievementService = new common.AchievementService(); gateway.notices = [];
  gateway.pendingFavoriteAchievements=[];gateway.snapshotSaveQueue=Promise.resolve(true);persistedFavorites=[];
  gateway.enqueueAchievementNotices = result => gateway.notices.push(...common.achievementNoticeItemsForUnlocks(result.newlyUnlocked));
  return gateway;
}
const gateway = reset();
const flush = () => new Promise(resolve => setImmediate(resolve));
const unlocked = (id, state=durable) => state.progresses.some(p => p.achievementId===id && p.unlockedAt>0);
function expectBadges(ids) { for (const id of ids) assert.ok(unlocked(id), `missing ${id}`); }
function loadPage(folder, pageName, files, methods, exports) {
  const source = files.map(file => read(`gamesNext/${folder}/${file}.ets`)).join('\n');
  const page = read(`gamesNext/${folder}/${pageName}.ets`);
  const runtime = `${source}\nclass Page {${methods.map(name => method(page,name)).join('\n')} }\n({Page,${exports}})`;
  return vm.runInNewContext(stripTypeScriptTypes(clean(runtime),{mode:'transform'}), {console,clearTimeout:()=>{},MARKET_PROFILE:false});
}
const mine = loadPage('minesweeper','MineGardenPage',['MineModel','MineEngine'],['settle'],'MineEngine');
const glow = loadPage('glow2048','GlowPage',['GlowModel','GlowEngine'],['boot','reportMilestone','reportEnd'],'GlowEngine,glowMax,GLOW_PLAY_HINT');
const block = loadPage('blockWorkshop','BlockWorkshopPage',['BlockModel','BlockEngine'],['boot','milestones','finish','report','preserveAchievements','restart','saveAndExit'],'BlockEngine');
const fruit = loadPage('fruitMarket','FruitMarketPage',['MarketModel','MarketEngine'],['boot','frame','finish','report','preserveAchievements','restartRequested','saveAndExit'],'MarketEngine');
const freecell = loadPage('warmFreecell','FreecellRoomPage',['FreecellModel','FreecellSession'],['reportWin'],'FreecellSession');
const arena = loadPage('coopArena','CoopArenaPage',['ArenaModel','ArenaEngine','ArenaProgress'],['publishResult'],'ArenaEngine,arenaDefaultConfig,arenaProfile');
function controller(lib, engine, target=gateway) {
  const p = new lib.Page();
  Object.assign(p,{engine,context:{},hostContext:{},loaded:true,ready:true,disposed:false,saving:false,
    reportingSession:'',achievementRequests:[],achievementRetryAt:0,achievementRetryPending:false,achievementSaveFailed:false,
    bestScore:0,viewport:{limited:false},savingExit:false,exits:0,saveFailed:false,
    gameReady:true,booting:false,loading:false,timer:-1,profile:arena.arenaProfile(),scores:[],snapshots:[],events:[],
    audio:{play(){}},sounds:{play(){},silence(){}},renderer:{add(){},invalidate(){},reset(){}},stop(){},start(){},draw(){},paint(){},cancelHold(){},
    resume(){},pause(){},exitToHub(){this.exits++;},
    dialogMode:'',lastFrame:Date.now(),lastSave:Date.now(),
    sync(){const engine=this.engine;this.phase=engine.phase;this.level=engine.level;this.maxTile=engine.tiles?glow.glowMax(engine.tiles):0;
      this.score=engine.round?.score??engine.score;this.highest=engine.round?.highest;},
    async save(){this.snapshots.push(this.engine.serialize());return true;},
    storage:{async load(){return '';}}
  });
  p.recordScore = score => p.scores.push(score);
  p.reportAchievementEvent = event => {
    assert.ok(event.gameId.endsWith('Next'),`new page must identify its source: ${event.gameId}`);
    p.events.push(plain(event));return target.reportAchievementEvent(event);
  };
  p.sync(); return p;
}
let count=0;
async function test(name, run) {await run();await flush();count++;console.log(`PASS ${name}`);}
function clearMine(elapsed=45000, wrongFlag=false) {
  const e=new mine.MineEngine();e.reset('easy',42);e.open(40);e.advance(elapsed);
  if(wrongFlag){const c=e.cells.find(c=>!c.mine&&!c.open);e.flag(c.index);e.flag(c.index);}
  for(const c of e.cells) if(c.mine)e.flag(c.index);
  for(const c of e.cells) if(!c.mine&&!c.open)e.open(c.index);
  assert.equal(e.phase,'won');return e;
}
await test('庭院探雷：真实开格、十面正确旗、45 秒通关 → 三枚成就', async()=>{
  const p=controller(mine,clearMine());await p.settle();await p.settle();
  expectBadges(['minesweeper.first_clear','minesweeper.quick_clear','minesweeper.perfect_flags']);
  assert.equal(p.events.length,1);assert.equal(p.engine.reported,true);
  assert.equal(JSON.parse(p.snapshots.at(-1)).reported,true);
});
await test('探雷超过 3 分钟不领速通；插错后改正仍可领取正确插旗成就', async()=>{
  const g=reset();const p=controller(mine,clearMine(180001,true),g);await p.settle();
  assert.equal(unlocked('minesweeper.quick_clear'),false);assert.equal(unlocked('minesweeper.perfect_flags'),true);
  durable=plain(gateway.achievementService.currentState());
});
await test('暖光叠数：真实合并 256 / 512 / 1024 → 三枚成就，沿用原勋章 ID',async()=>{
  for(const [value,id] of [[128,256],[256,1024],[512,2048]]) {
    const e=new glow.GlowEngine();e.tiles=[{id:1,index:0,value},{id:2,index:1,value}];e.nextId=3;
    e.move('left');const p=controller(glow,e);p.reportMilestone();await flush();
    assert.ok(unlocked(`chicken2048.reach_${id}`));
  }
});
await test('暖光叠数：堵盘正常结算；主动重开未结束棋盘不计一局',async()=>{
  const e=new glow.GlowEngine();const p=controller(glow,e);e.move('left');await p.reportEnd();assert.equal(p.events.length,0);
  // A legal move fills the last empty cell and makes the engine declare game over.
  e.tiles=[2,4,8,16,32,64,128,256,512,1024,2,4,8,16,32].map((value,index)=>({id:index+1,index,value}));
  e.nextId=16;e.moves=13;e.move('right');assert.equal(e.ended,true);
  const restored=new glow.GlowEngine();assert.equal(restored.restore(e.serialize()),true);
  const q=controller(glow,restored);await q.reportEnd();assert.equal(q.engine.reported,true);
  assert.ok(durable.playedGameIds.includes('chicken2048'));
});
await test('方块工坊：真实逐行消除，在 1 / 5 / 10 行解锁，不需要四消或升级',async()=>{
  const e=new block.BlockEngine(42),p=controller(block,e);
  for(let round=0;round<10;round++){
    e.round.board.fill(0);
    for(let col=0;col<10;col++)if(col!==4)e.round.board[21*10+col]=2;
    e.round.piece={kind:0,turn:1,x:2,y:1};assert.equal(e.command('drop'),true);e.advance(160);
    p.milestones();await flush();
    assert.equal(unlocked('tetris.first_tetris'),round>=0);
    assert.equal(unlocked('tetris.twenty_lines'),round>=4);
    assert.equal(unlocked('tetris.level_three'),round>=9);
  }
  assert.equal(e.round.lines,10);assert.equal(e.round.maxClear,1);assert.equal(e.round.level,1);
  expectBadges(['tetris.first_tetris','tetris.twenty_lines','tetris.level_three']);
  while(e.round.phase!=='over') {e.command('drop');e.advance(160);}
  p.finish();p.finish();await flush();assert.equal(e.round.reported,true);
  assert.equal(p.events.filter(e=>e.type==='sessionEnd').length,1);
});
function pair(p,level) {
  const e=p.engine;
  e.round.bodies=[130,140].map((x,i)=>({id:e.round.nextId+i,level,x,y:390,vx:0,vy:0,angle:0,born:0,unlock:0}));
  e.round.nextId+=2;p.lastFrame=Date.now()-18;p.frame();assert.equal(e.events.length,1);
}
await test('鸡窝水果摊：真实合并经页面帧回调触发 100 分、小西瓜和西瓜，且新版显示通知',async()=>{
  const e=new fruit.MarketEngine(42),p=controller(fruit,e);gateway.activeGame='suikaNext';
  const before=gateway.notices.length;
  pair(p,5);await flush();assert.equal(e.round.highest,6);assert.ok(unlocked('suika.make_watermelon'));assert.equal(unlocked('suika.final_merge'),false);
  pair(p,6);await flush();assert.equal(e.round.highest,7);assert.ok(unlocked('suika.final_merge'));
  while(e.round.score<100){pair(p,3);await flush();}
  assert.ok(e.round.score<110);assert.equal(e.round.highest,7);
  expectBadges(['suika.score_600','suika.make_watermelon','suika.final_merge']);
  assert.ok(gateway.notices.length>before);
  e.round.bodies=[416,264,112].map((y,i)=>({id:e.round.nextId+i,level:10,x:180,y,vx:0,vy:0,angle:0,born:0,unlock:0}));
  e.round.nextId+=3;for(let i=0;i<300&&!e.round.ended;i++)e.advance(1/60);
  assert.equal(e.round.ended,true);p.finish();await flush();assert.equal(e.round.reported,true);gateway.activeGame='hub';
});
await test('暖木牌室：从真实发牌经合法移牌完成一局，三枚成就均解锁',async()=>{
  const e=new freecell.FreecellSession();e.newGame(42);const visited=[e.key()];
  while(!e.won()&&e.moves<150){const move=e.suggestions().find(move=>move.target>=12);assert.ok(move);assert.equal(e.move(move.card,move.target),true);visited.push(e.key());}
  assert.equal(e.won(),true);e.elapsed=300;
  const p=controller(freecell,e);await p.reportWin();
  expectBadges(['freecell.complete_board','freecell.efficient_win','freecell.quick_win']);
  assert.equal(e.reported,true);assert.equal(JSON.parse(p.snapshots[0]).reported,false);
  assert.equal(JSON.parse(p.snapshots.at(-1)).reported,true);
});
await test('庭院擂台：完整固定步长模拟，可真实达成 12 次转阵与小队首胜',async()=>{
  let winner,most=0;
  for(let seed=1;seed<=12;seed++){
    const config=plain(arena.arenaDefaultConfig());config.seed=seed;
    const e=new arena.ArenaEngine(config);
    for(let tick=0;tick<5500&&!e.round.finished;tick++)e.step();
    assert.equal(e.round.finished,true);most=Math.max(most,e.round.conversions);
    if(e.round.won&&e.round.conversions>=12){winner=e;break;}
  }
  assert.ok(winner,`expected an actual winning round with 12 conversions, max=${most}`);
  console.log(`  actual round: ${winner.round.conversions} conversions in ${winner.time().toFixed(1)} seconds`);
  const p=controller(arena,winner);await p.publishResult();await p.publishResult();
  expectBadges(['rpsBattle.first_battle','rpsBattle.supporter_wins','rpsBattle.conversion_storm']);
  assert.equal(p.events.length,1);assert.equal(winner.round.reported,true);
});
await test('合集：原六款各一局、收藏三个不同游戏、累计十局 → 原有 22 枚均可达成并保存',async()=>{
  const event=common.favoriteAchievementEventAfterPersist('suikaNext',true,true,['suikaNext','freecellNext','tetrisNext'],Date.now(),1);
  assert.ok(event);await gateway.reportAchievementEvent(event);
  while(durable.completedSessionCount<10){const p=controller(mine,clearMine());await p.settle();}
  expectBadges(['global.first_settlement','global.play_six_games','global.favorite_three','global.complete_ten_sessions']);
  const summary=common.achievementSummaryForState(durable);assert.equal(summary.total,common.ACHIEVEMENT_DEFINITIONS.filter(item=>!common.isGameHidden(item.gameId)).length);assert.equal(summary.unlocked,22);
  const reloaded=new common.AchievementService();const state=await reloaded.initialize({});assert.equal(common.achievementSummaryForState(state).unlocked,22);
  assert.equal(common.achievementGroupsForState(state,'inProgress').length,0);
});
await test('新版来源归入稳定成就 ID；同局不同事件与缓存淘汰后重放不重复计局',async()=>{
  const g=reset();const event={eventId:'same:finish',sessionId:'same',gameId:'minesweeperNext',type:'sessionEnd',occurredAt:Date.now(),isOfficial:true,facts:[{key:'won',value:1}]};
  await g.reportAchievementEvent(event);await g.reportAchievementEvent({...event,eventId:'same:other'});
  for(let i=0;i<40;i++)await g.reportAchievementEvent({...event,eventId:`tile:${i}`,gameId:'chicken2048Next',type:'milestone',facts:[{key:'maxTile',value:256}]});
  await g.reportAchievementEvent(event);assert.equal(durable.completedSessionCount,1);assert.deepEqual(durable.playedGameIds,['minesweeper']);
});
await test('未获胜、缺少关键事实、超出步数/时间/转化边界和非正式事件不会误解锁',async()=>{
  const base={eventId:'boundary',sessionId:'boundary',gameId:'freecellNext',type:'sessionEnd',occurredAt:Date.now(),isOfficial:true};
  const cases=[[[{key:'won',value:0},{key:'moves',value:1},{key:'elapsedSec',value:1}],false,false],
    [[{key:'won',value:1}],false,false],[[{key:'won',value:1},{key:'moves',value:200},{key:'elapsedSec',value:900}],true,true],
    [[{key:'won',value:1},{key:'moves',value:201},{key:'elapsedSec',value:901}],false,false]];
  for(const [facts,efficient,quick] of cases){const r=common.applyAchievementEvent(common.emptyAchievementState(),{...base,facts});assert.equal(unlocked('freecell.efficient_win',r.state),efficient);assert.equal(unlocked('freecell.quick_win',r.state),quick);}
  for(const conversions of [11,12]){const r=common.applyAchievementEvent(common.emptyAchievementState(),{...base,gameId:'rpsBattleNext',facts:[{key:'conversions',value:conversions}]});assert.equal(unlocked('rpsBattle.conversion_storm',r.state),conversions===12);}
  const practice=common.applyAchievementEvent(common.emptyAchievementState(),{...base,isOfficial:false,facts:cases[2][0]});assert.equal(practice.state.completedSessionCount,0);assert.equal(practice.newlyUnlocked.length,0);
});
await test('六款游戏保存失败均保留未确认结果；重试成功后只确认一次',async()=>{
  const factories=[
    ()=>{const p=controller(mine,clearMine(),reset());return [p,()=>p.settle(),()=>p.engine.reported];},
    ()=>{const e=new glow.GlowEngine();e.ended=true;e.moves=1;const p=controller(glow,e,reset());return[p,()=>p.reportEnd(),()=>e.reported];},
    ()=>{const e=new block.BlockEngine();e.round.phase='over';const p=controller(block,e,reset());return[p,async()=>{p.finish();await flush();},()=>e.round.reported];},
    ()=>{const e=new fruit.MarketEngine();e.round.ended=true;const p=controller(fruit,e,reset());return[p,async()=>{p.finish();await flush();},()=>e.round.reported];},
    ()=>{const e=new freecell.FreecellSession();e.piles=Array.from({length:16},(_,i)=>i<12?[]:Array.from({length:13},(_,j)=>(i-12)*13+j));const p=controller(freecell,e,reset());return[p,()=>p.reportWin(),()=>e.reported];},
    ()=>{const e=new arena.ArenaEngine();e.round.finished=true;const p=controller(arena,e,reset());return[p,()=>p.publishResult(),()=>e.round.reported];}
  ];
  for(const factory of factories){const [p,run,reported]=factory();failWrite=true;await run();assert.equal(reported(),false);assert.equal(durable.completedSessionCount,0);assert.equal(p.scores.length,0);
    failWrite=false;await run();assert.equal(reported(),true);assert.equal(durable.completedSessionCount,1);await run();assert.equal(durable.completedSessionCount,1);assert.equal(p.scores.length,1);}
});
await test('恢复存档补报叠数、方块、水果已达成的里程碑，包括旧版提前标记的方块位',async()=>{
  for(const [lib,engine] of [[glow,new glow.GlowEngine()],[block,new block.BlockEngine()],[fruit,new fruit.MarketEngine()]]){
    const g=reset(),p=controller(lib,engine,g);
    if(lib===glow){engine.tiles=[{id:1,index:0,value:2048},{id:2,index:1,value:2}];engine.nextId=4;engine.moves=1;p.sync();}
    if(lib===block){engine.round.maxClear=1;engine.round.lines=10;engine.round.level=1;engine.round.milestones=7;}
    if(lib===fruit){engine.round.highest=7;engine.round.score=100;engine.round.drops=1;}
    const raw=engine.serialize();p.storage.load=async()=>raw;await p.boot();await flush();
    assert.equal(common.achievementSummaryForState(durable).unlocked,3);assert.equal(durable.completedSessionCount,0);
  }
});
await test('六个旧版与最早乱斗的高分事件全部拒绝，不增加成就、合集局数或提示',async()=>{
  const g=reset();
  const facts=[{key:'score',value:99999},{key:'won',value:1},{key:'supportWon',value:1},{key:'conversions',value:100},
    {key:'totalLines',value:100},{key:'maxClearedLines',value:4},{key:'level',value:10},{key:'maxTile',value:2048},
    {key:'highestMergeLevel',value:10},{key:'moves',value:1},{key:'elapsedSec',value:1},{key:'manualAllMinesFlagged',value:1},{key:'hasEverFlaggedNonMine',value:0}];
  for(const gameId of ['rps','rpsBattle','freecell','minesweeper','chicken2048','tetris','suika'])for(const type of ['sessionEnd','milestone']) {
    assert.equal(await g.reportAchievementEvent({eventId:gameId+type,sessionId:gameId,gameId,type,occurredAt:Date.now(),isOfficial:true,facts}),false);
  }
  assert.equal(writes,0);assert.equal(durable.completedSessionCount,0);assert.equal(durable.progresses.length,0);assert.equal(g.notices.length,0);
  // Inspect the actual root component wiring as well as the shared engine rejection.
  const index=read('pages/Index.ets');
  for(const name of ['RpsBattlePage','FreecellPage','MinesweeperPage','Chicken2048Page','TetrisPage','SuikaPage']){
    const block=index.slice(index.indexOf(name+'({'),index.indexOf('\n          })',index.indexOf(name+'({')));
    assert.ok(block.includes('recordScore:'),name+' still playable');assert.ok(!block.includes('reportAchievementEvent:'),name+' detached');
  }
});
await test('收藏仅统计新版；收藏旧版和重复身份不会触发新的收藏成就',async()=>{
  const old=['rpsBattle','freecell','minesweeper','chicken2048','tetris','suika'];
  assert.equal(common.achievementPrimaryFavoriteCount(old),0);
  assert.equal(common.favoriteAchievementEventAfterPersist('suika',true,true,[...old,'suikaNext','freecellNext','tetrisNext'],Date.now(),1),undefined);
  assert.equal(common.achievementPrimaryFavoriteCount([...old,'suikaNext','suikaNext','tetrisNext']),2);
  const g=reset();const favorites=[...old,'suikaNext','tetrisNext','freecellNext'];
  const event=common.favoriteAchievementEventAfterPersist('freecellNext',true,true,favorites,Date.now(),1);
  assert.ok(event);await g.reportAchievementEvent(event);assert.ok(unlocked('global.favorite_three'));
});
await test('自定义 60 人事件局与不等人数局自然结束也能解锁；未结束、重开不计局',async()=>{
  for(const config of [{counts:[20,20,20],event:'traitor',seed:3032101680},{counts:[3,4,5],event:'garden',seed:8}]) {
    const e=new arena.ArenaEngine({...plain(arena.arenaDefaultConfig()),...config}),p=controller(arena,e,reset());
    await p.publishResult();assert.equal(p.events.length,0);
    for(let i=0;i<3601&&!e.round.finished;i++)e.step();
    assert.equal(e.round.finished,true);await p.publishResult();await p.publishResult();
    assert.equal(p.events.length,1);assert.ok(unlocked('rpsBattle.first_battle'));assert.equal(durable.completedSessionCount,1);
    assert.equal(e.round.reported,true);assert.equal(p.profile.rounds,0,'custom rounds still excluded from competitive records');
    if(config.counts[0]===20)assert.ok(unlocked('rpsBattle.conversion_storm'));
  }
});
await test('新条件边界：99/100 分、5/6/7 级水果和 0/1/4/5/9/10 行分别准确判定',async()=>{
  const base={eventId:'edge',sessionId:'edge',type:'milestone',occurredAt:Date.now(),isOfficial:true};
  for(const score of [99,100]) {
    const r=common.applyAchievementEvent(common.emptyAchievementState(),{...base,gameId:'suikaNext',facts:[{key:'score',value:score}]});
    assert.equal(unlocked('suika.score_600',r.state),score===100);
  }
  for(const level of [5,6,7]) {
    const r=common.applyAchievementEvent(common.emptyAchievementState(),{...base,gameId:'suikaNext',facts:[{key:'highestMergeLevel',value:level}]});
    assert.equal(unlocked('suika.make_watermelon',r.state),level>=6);assert.equal(unlocked('suika.final_merge',r.state),level>=7);
  }
  for(const lines of [0,1,4,5,9,10]) {
    const r=common.applyAchievementEvent(common.emptyAchievementState(),{...base,gameId:'tetrisNext',facts:[{key:'totalLines',value:lines},{key:'maxClearedLines',value:lines?1:0},{key:'level',value:1}]});
    for(const [id,target] of [['first_tetris',1],['twenty_lines',5],['level_three',10]])assert.equal(unlocked('tetris.'+id,r.state),lines>=target);
  }
});
await test('水果与方块：成就保存失败时不覆盖已结束对局，重试再开后只计一次',async()=>{
  for(const lib of [fruit,block]) {
    const e=lib===fruit?new fruit.MarketEngine():new block.BlockEngine();
    const p=controller(lib,e,reset());if(lib===fruit)e.round.ended=true;else e.round.phase='over';
    failWrite=true;p.finish();await flush();assert.equal(e.round.reported,false);
    const restart=()=>lib===fruit?p.restartRequested():p.restart();
    await restart();assert.equal(p.engine,e);assert.equal(p.saveFailed,true);assert.equal(durable.completedSessionCount,0);
    failWrite=false;await restart();assert.notEqual(p.engine,e);assert.equal(e.round.reported,true);assert.equal(durable.completedSessionCount,1);
    assert.equal(p.scores.length,1);
  }
});
await test('水果与方块：结算回执在途中重开不会替换棋盘或重复上报',async()=>{
  for(const lib of [fruit,block]) {
    const e=lib===fruit?new fruit.MarketEngine():new block.BlockEngine(),p=controller(lib,e,reset());
    if(lib===fruit)e.round.ended=true;else e.round.phase='over';
    let acknowledge;const realReport=p.reportAchievementEvent;
    p.reportAchievementEvent=event=>new Promise(resolve=>{acknowledge=async()=>resolve(await realReport(event));});
    p.finish();const restart=()=>lib===fruit?p.restartRequested():p.restart();
    await restart();assert.equal(p.engine,e);assert.equal(e.round.reported,false);
    await acknowledge();await flush();p.reportAchievementEvent=realReport;await restart();
    assert.notEqual(p.engine,e);assert.equal(durable.completedSessionCount,1);assert.equal(p.scores.length,1);
  }
});
await test('水果与方块：未结算的达标里程碑在重开前补报，不增加完成局数',async()=>{
  for(const lib of [fruit,block]) {
    const e=lib===fruit?new fruit.MarketEngine():new block.BlockEngine(),p=controller(lib,e,reset());
    if(lib===fruit){e.round.score=100;e.round.highest=7;p.dialogMode='restart';}
    else {e.round.maxClear=1;e.round.lines=10;}
    const restart=()=>lib===fruit?p.restartRequested():p.restart();
    failWrite=true;await restart();assert.equal(p.engine,e);assert.equal(durable.progresses.length,0);
    failWrite=false;await restart();assert.notEqual(p.engine,e);
    assert.equal(common.achievementSummaryForState(durable).unlocked,3);assert.equal(durable.completedSessionCount,0);
  }
});
await test('水果与方块：保存退出会重试未确认结算，失败时保留当前页',async()=>{
  for(const lib of [fruit,block]) {
    const e=lib===fruit?new fruit.MarketEngine():new block.BlockEngine(),p=controller(lib,e,reset());
    if(lib===fruit)e.round.ended=true;else e.round.phase='over';
    failWrite=true;await p.saveAndExit();assert.equal(p.exits,0);assert.equal(e.round.reported,false);
    failWrite=false;await p.saveAndExit();assert.equal(p.exits,1);assert.equal(e.round.reported,true);assert.equal(durable.completedSessionCount,1);
  }
});
await test('水果合并里程碑写入失败后，正常帧回调限频补报，无需重新合成',async()=>{
  const e=new fruit.MarketEngine(),p=controller(fruit,e,reset());
  failWrite=true;pair(p,5);await flush();assert.equal(p.achievementRetryPending,true);assert.equal(unlocked('suika.make_watermelon'),false);
  const calls=p.events.length;p.frame();await flush();assert.equal(p.events.length,calls,'retry is throttled');
  failWrite=false;p.achievementRetryAt=0;p.frame();await flush();assert.ok(unlocked('suika.make_watermelon'));assert.equal(p.achievementRetryPending,false);
});
await test('方块恢复旧里程碑位时写入失败，继续消行循环仍会补报新门槛',async()=>{
  const e=new block.BlockEngine(),p=controller(block,e,reset());
  e.round.maxClear=1;e.round.lines=10;e.round.milestones=7;
  failWrite=true;p.milestones(true);await flush();assert.equal(e.round.milestones,0);
  const calls=p.events.length;p.milestones();await flush();assert.equal(p.events.length,calls);
  failWrite=false;p.achievementRetryAt=0;p.milestones();await flush();assert.equal(e.round.milestones,7);
  assert.equal(common.achievementSummaryForState(durable).unlocked,3);assert.equal(durable.completedSessionCount,0);
});
await test('收藏成就补报：保存失败后刷新、取消后重试、重启恢复都能补回且不重复通知',async()=>{
  const g=reset();const favorites=['suikaNext','tetrisNext','freecellNext'];
  const event=common.favoriteAchievementEventAfterPersist('freecellNext',true,true,favorites,Date.now(),1);
  failWrite=true;await g.reportFavoriteAchievement(event);assert.equal(g.pendingFavoriteAchievements.length,1);
  // Cancellation after a persisted qualifying snapshot must not erase the pending award.
  persistedFavorites=[];failWrite=false;await g.refreshAchievementState();assert.ok(unlocked('global.favorite_three'));
  assert.equal(g.pendingFavoriteAchievements.length,0);assert.equal(g.notices.length,1);
  await g.refreshAchievementState();assert.equal(g.notices.length,1);
  const h=reset();persistedFavorites=favorites;await h.reconcileFavoriteAchievements();assert.ok(unlocked('global.favorite_three'));
  const savedWrites=writes;await h.reconcileFavoriteAchievements();assert.equal(writes,savedWrites);assert.equal(h.notices.length,1);
  const j=reset();persistedFavorites=['suika','tetris','freecell'];await j.reconcileFavoriteAchievements();assert.equal(durable.progresses.length,0);
});
await test('大厅也显示解锁通知；转场与入场提示期间排队，旧版不会收到新版弹奖',async()=>{
  const g=reset();await g.reportAchievementEvent({eventId:'toast',sessionId:'toast',gameId:'suikaNext',type:'milestone',occurredAt:Date.now(),isOfficial:true,facts:[{key:'score',value:100}]});
  g.achievementNoticeQueue=[...g.notices];g.achievementNoticeMounted=false;g.sceneTransitioning=true;g.entryBadgeMounted=false;
  g.tryShowAchievementNotice();assert.equal(g.achievementNoticeMounted,false);
  g.sceneTransitioning=false;g.entryBadgeMounted=true;g.tryShowAchievementNotice();assert.equal(g.achievementNoticeMounted,false);
  g.entryBadgeMounted=false;g.tryShowAchievementNotice();assert.equal(g.achievementNoticeMounted,true);
  const h=reset();h.activeGame='suika';await h.reportAchievementEvent({eventId:'delayed',sessionId:'delayed',gameId:'suikaNext',type:'milestone',occurredAt:Date.now(),isOfficial:true,facts:[{key:'score',value:100}]});
  assert.equal(h.notices.length,0);assert.ok(unlocked('suika.score_600'));
});
await test('同局多枚成就展示时返回大厅，转场保留当前和剩余提醒',async()=>{
  const g=reset(),items=common.achievementNoticeItemsForUnlocks([
    {achievementId:'global.first_settlement',unlockedAt:1},{achievementId:'rpsBattle.first_battle',unlockedAt:1},
    {achievementId:'rpsBattle.supporter_wins',unlockedAt:1}]);
  g.activeGame='rpsBattleNext';g.sceneTransitioning=false;g.entryBadgeMounted=false;
  g.achievementNotice=items[0];g.achievementNoticeMounted=true;g.achievementNoticeVisible=true;g.achievementNoticeQueue=items.slice(1);
  let finish;g.hideEntryBadge=()=>{};g.getUIContext=()=>({animateTo(options,action){action();finish=options.onFinish;}});
  g.closeGameAnimated();assert.equal(g.activeGame,'hub');assert.equal(g.achievementNoticeMounted,false);assert.equal(g.achievementNoticeQueue.length,3);
  finish();assert.equal(g.achievementNoticeMounted,true);assert.equal(g.achievementNoticeQueue.length,2);
  g.suspendAchievementNotices();g.activeGame='rpsBattle';g.tryShowAchievementNotice();assert.equal(g.achievementNoticeMounted,false);
  g.activeGame='hub';g.tryShowAchievementNotice();assert.equal(g.achievementNoticeMounted,true);
});
await test('历史勋章保留，旧进度按新条件静默迁移且只保存一次',async()=>{
  const g=reset();delete durable.rulesVersion;
  durable.completedSessionCount=4;durable.playedGameIds=['suika'];durable.completedSessionIds=['suika:historical'];
  durable.progresses=[{achievementId:'suika.score_600',current:120,unlockedAt:0},
    {achievementId:'suika.make_watermelon',current:1,unlockedAt:123},
    {achievementId:'tetris.first_tetris',current:2,unlockedAt:0},
    {achievementId:'tetris.twenty_lines',current:8,unlockedAt:0},{achievementId:'tetris.level_three',current:1,unlockedAt:0},
    {achievementId:'chicken2048.reach_1024',current:512,unlockedAt:0},{achievementId:'chicken2048.reach_2048',current:1024,unlockedAt:0}];
  await g.achievementService.initialize({});assert.equal(durable.rulesVersion,2);assert.equal(writes,1);
  expectBadges(['suika.score_600','suika.make_watermelon','suika.final_merge','tetris.first_tetris','tetris.twenty_lines']);
  expectBadges(['chicken2048.reach_1024','chicken2048.reach_2048']);
  assert.equal(unlocked('tetris.level_three'),false);
  assert.equal(durable.progresses.find(p=>p.achievementId==='tetris.level_three').current,8);
  assert.equal(durable.progresses.find(p=>p.achievementId==='suika.make_watermelon').unlockedAt,123);
  assert.equal(durable.progresses.find(p=>p.achievementId==='suika.final_merge').unlockedAt,123);
  assert.equal(durable.completedSessionCount,4);assert.equal(g.notices.length,0);
  const saved=plain(durable);await g.achievementService.refresh({});assert.equal(writes,1);assert.deepEqual(durable,saved);
});
await test('迁移写入失败不确认新事件；重试后保留原勋章与历史局数',async()=>{
  const g=reset();delete durable.rulesVersion;durable.completedSessionCount=2;
  durable.progresses=[{achievementId:'suika.final_merge',current:1,unlockedAt:123}];const before=plain(durable);
  const p=controller(mine,clearMine(),g);failWrite=true;await p.settle();assert.equal(p.engine.reported,false);assert.deepEqual(durable,before);
  failWrite=false;await p.settle();assert.equal(p.engine.reported,true);assert.equal(durable.completedSessionCount,3);
  assert.equal(durable.progresses.find(p=>p.achievementId==='suika.final_merge').unlockedAt,123);
});
await test('暂时无法读取成就存档时，不以空状态覆盖已有成就',async()=>{
  const g=reset();durable.progresses=[{achievementId:'suika.final_merge',current:1,unlockedAt:1}];
  failRead=true;const p=controller(mine,clearMine(),g);await p.settle();assert.equal(writes,0);assert.equal(p.engine.reported,false);
  failRead=false;await p.settle();assert.equal(unlocked('suika.final_merge'),true);assert.equal(p.engine.reported,true);
});
await test('实际存储适配器读取异常/损坏 JSON 会拒绝；显式重置仍能修复损坏存档',async()=>{
  let value='',unavailable=false;
  const preferences={async getPreferences(){if(unavailable)throw Error('IO');return{async get(){return value;},async put(_key,raw){value=raw;},async flush(){}};}};
  const source=commonFiles.filter(p=>p!=='app/AchievementService.ets').map(read).join('\n')+'\n'+read('app/CoopStorage.ets')+'\n'+read('app/AchievementService.ets');
  const api=vm.runInNewContext(stripTypeScriptTypes(clean(source),{mode:'transform'})+'\n({CoopStorage,AchievementService})',{preferences});
  assert.equal((await api.CoopStorage.loadAchievementState({})).completedSessionCount,0);
  unavailable=true;await assert.rejects(()=>api.CoopStorage.loadAchievementState({}));
  unavailable=false;value='{broken';const service=new api.AchievementService();await assert.rejects(()=>service.initialize({}));
  await service.reset({});assert.equal(JSON.parse(value).completedSessionCount,0);
});
console.log(`\n${count} integration groups passed; the original six games' 22 achievements exercised. Native toast appearance remains device QA.`);
