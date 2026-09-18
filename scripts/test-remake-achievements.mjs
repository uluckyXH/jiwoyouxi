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
let durable, failWrite = false, failRead = false, writes = 0;
const CoopStorage = {
  async loadAchievementState() { if (failRead) throw Error('read unavailable'); return plain(durable); },
  async saveAchievementState(_context, state) { writes++; if (failWrite) return false; durable = plain(state); return true; }
};
const commonFiles = ['shell/AchievementModule.ets', 'shell/GameModule.ets', 'shell/AchievementRegistry.ets',
  'shell/AchievementEngine.ets', 'shell/AchievementNotice.ets', 'shell/AchievementFavoriteEvent.ets', 'app/AchievementService.ets'];
const commonCode = commonFiles.map(read).join('\n') + '\nclass Gateway {' + method(read('pages/Index.ets'), 'reportAchievementEvent') + '\n}';
const common = vm.runInNewContext(stripTypeScriptTypes(clean(commonCode), {mode:'transform'}) + `\n({
  AchievementService,Gateway,emptyAchievementState,applyAchievementEvent,achievementSummaryForState,
  achievementGroupsForState,achievementNoticeItemsForUnlocks,ACHIEVEMENT_DEFINITIONS,
  favoriteAchievementEventAfterPersist,achievementCanonicalGameId})`, {CoopStorage, console});
function reset() {
  durable = plain(common.emptyAchievementState()); failWrite = false; failRead = false; writes = 0;
  const gateway = new common.Gateway(); gateway.appContext = {}; gateway.activeGame = 'hub';
  gateway.achievementService = new common.AchievementService(); gateway.notices = [];
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
  return vm.runInNewContext(stripTypeScriptTypes(clean(runtime),{mode:'transform'}), {console,clearTimeout:()=>{}});
}
const mine = loadPage('minesweeper','MineGardenPage',['MineModel','MineEngine'],['settle'],'MineEngine');
const glow = loadPage('glow2048','GlowPage',['GlowModel','GlowEngine'],['boot','reportMilestone','reportEnd'],'GlowEngine,glowMax,GLOW_PLAY_HINT');
const block = loadPage('blockWorkshop','BlockWorkshopPage',['BlockModel','BlockEngine'],['boot','milestones','finish','report'],'BlockEngine');
const fruit = loadPage('fruitMarket','FruitMarketPage',['MarketModel','MarketEngine'],['boot','finish','report'],'MarketEngine');
const freecell = loadPage('warmFreecell','FreecellRoomPage',['FreecellModel','FreecellSession'],['reportWin'],'FreecellSession');
const arena = loadPage('coopArena','CoopArenaPage',['ArenaModel','ArenaEngine','ArenaProgress'],['publishResult'],'ArenaEngine,arenaDefaultConfig,arenaProfile');
function controller(lib, engine, target=gateway) {
  const p = new lib.Page();
  Object.assign(p,{engine,context:{},hostContext:{},loaded:true,ready:true,disposed:false,saving:false,
    reportingSession:'',achievementRequests:[],achievementRetryAt:0,bestScore:0,viewport:{limited:false},
    gameReady:true,booting:false,loading:false,timer:-1,profile:arena.arenaProfile(),scores:[],snapshots:[],events:[],
    audio:{play(){}},sounds:{play(){}},stop(){},start(){},draw(){},paint(){},cancelHold(){},
    sync(){this.phase=engine.phase;this.level=engine.level;this.maxTile=engine.tiles?glow.glowMax(engine.tiles):0;
      this.score=engine.round?.score??engine.score;this.highest=engine.round?.highest;},
    async save(){this.snapshots.push(engine.serialize());return true;},
    storage:{async load(){return '';}}
  });
  p.recordScore = score => p.scores.push(score);
  p.reportAchievementEvent = event => {p.events.push(plain(event));return target.reportAchievementEvent(event);};
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
await test('探雷超过 60 秒或曾经错插旗，不得领取对应成就', async()=>{
  const g=reset();const p=controller(mine,clearMine(60001,true),g);await p.settle();
  assert.equal(unlocked('minesweeper.quick_clear'),false);assert.equal(unlocked('minesweeper.perfect_flags'),false);
  durable=plain(gateway.achievementService.currentState());
});
await test('暖光叠数：真实合并 256 / 1024 / 2048 → 三枚成就',async()=>{
  for(const value of [128,512,1024]) {
    const e=new glow.GlowEngine();e.tiles=[{id:1,index:0,value},{id:2,index:1,value}];e.nextId=3;
    e.move('left');const p=controller(glow,e);p.reportMilestone();await flush();
    assert.ok(unlocked(`chicken2048.reach_${value*2}`));
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
await test('方块工坊：实际完成十次四消，20 行 / 3 级均解锁',async()=>{
  const e=new block.BlockEngine(42),p=controller(block,e);
  for(let round=0;round<10;round++){
    e.round.board.fill(0);
    for(let row=18;row<22;row++)for(let col=0;col<10;col++)if(col!==4)e.round.board[row*10+col]=2;
    e.round.piece={kind:0,turn:1,x:2,y:1};assert.equal(e.command('drop'),true);e.advance(160);
    p.milestones();await flush();
  }
  assert.equal(e.round.lines,40);assert.equal(e.round.level,3);
  expectBadges(['tetris.first_tetris','tetris.twenty_lines','tetris.level_three']);
  while(e.round.phase!=='over') {e.command('drop');e.advance(160);}
  p.finish();p.finish();await flush();assert.equal(e.round.reported,true);
  assert.equal(p.events.filter(e=>e.type==='sessionEnd').length,1);
});
function pair(e,level) {
  e.round.bodies=[130,240].map((x,i)=>({id:e.round.nextId+i,level,x,y:390,vx:0,vy:0,angle:0,born:0,unlock:0}));
  // Radius 43 fruits need to be closer than the two largest fruits.
  if(level===6)e.round.bodies[1].x=200;
  e.round.nextId+=2; e.advance(1/60);assert.equal(e.events.length,1);
}
await test('鸡窝水果摊：真实合并西瓜、最终西瓜、600 分，且新版路由显示解锁提示',async()=>{
  const e=new fruit.MarketEngine(42),p=controller(fruit,e);gateway.activeGame='suikaNext';
  const before=gateway.notices.length;
  pair(e,6);await p.report('watermelon',false);assert.equal(e.round.highest,7);
  for(let i=0;i<6;i++){pair(e,9);if(i===0)await p.report('crown',false);}
  assert.ok(e.round.score>=600);await p.report('score-600',false);
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
await test('庭院擂台：完整固定步长模拟，可真实达成 30 次转化与支持阵营获胜',async()=>{
  let winner,most=0;
  for(let seed=1;seed<=12;seed++){
    const config=plain(arena.arenaDefaultConfig());config.seed=seed;
    const e=new arena.ArenaEngine(config);
    for(let tick=0;tick<5500&&!e.round.finished;tick++)e.step();
    assert.equal(e.round.finished,true);most=Math.max(most,e.round.conversions);
    if(e.round.won&&e.round.conversions>=30){winner=e;break;}
  }
  assert.ok(winner,`expected an actual winning round with 30 conversions, max=${most}`);
  console.log(`  actual round: ${winner.round.conversions} conversions in ${winner.time().toFixed(1)} seconds`);
  const p=controller(arena,winner);await p.publishResult();await p.publishResult();
  expectBadges(['rpsBattle.first_battle','rpsBattle.supporter_wins','rpsBattle.conversion_storm']);
  assert.equal(p.events.length,1);assert.equal(winner.round.reported,true);
});
await test('合集：新版六款各一局、收藏三个不同游戏、累计十局 → 全部 22 枚均可达成并保存',async()=>{
  const event=common.favoriteAchievementEventAfterPersist('suikaNext',true,true,['suikaNext','freecellNext','tetrisNext'],Date.now(),1);
  assert.ok(event);await gateway.reportAchievementEvent(event);
  while(durable.completedSessionCount<10){const p=controller(mine,clearMine());await p.settle();}
  expectBadges(['global.first_settlement','global.play_six_games','global.favorite_three','global.complete_ten_sessions']);
  const summary=common.achievementSummaryForState(durable);assert.equal(summary.total,22);assert.equal(summary.unlocked,22);
  const reloaded=new common.AchievementService();const state=await reloaded.initialize({});assert.equal(common.achievementSummaryForState(state).unlocked,22);
  assert.equal(common.achievementGroupsForState(state,'inProgress').length,0);
});
await test('新旧 ID 归一、同局不同事件 ID、32 条缓存淘汰后重放，都不会重复增加完成局数',async()=>{
  const g=reset();const event={eventId:'same:finish',sessionId:'same',gameId:'minesweeperNext',type:'sessionEnd',occurredAt:Date.now(),isOfficial:true,facts:[{key:'won',value:1}]};
  await g.reportAchievementEvent(event);await g.reportAchievementEvent({...event,eventId:'same:other'});
  for(let i=0;i<40;i++)await g.reportAchievementEvent({...event,eventId:`tile:${i}`,gameId:'chicken2048Next',type:'milestone',facts:[{key:'maxTile',value:256}]});
  await g.reportAchievementEvent(event);assert.equal(durable.completedSessionCount,1);assert.deepEqual(durable.playedGameIds,['minesweeper']);
});
await test('未获胜、缺少关键事实、超出步数/时间/转化边界和非正式事件不会误解锁',async()=>{
  const base={eventId:'boundary',sessionId:'boundary',gameId:'freecellNext',type:'sessionEnd',occurredAt:Date.now(),isOfficial:true};
  const cases=[[[{key:'won',value:0},{key:'moves',value:1},{key:'elapsedSec',value:1}],false,false],
    [[{key:'won',value:1}],false,false],[[{key:'won',value:1},{key:'moves',value:150},{key:'elapsedSec',value:600}],true,true],
    [[{key:'won',value:1},{key:'moves',value:151},{key:'elapsedSec',value:601}],false,false]];
  for(const [facts,efficient,quick] of cases){const r=common.applyAchievementEvent(common.emptyAchievementState(),{...base,facts});assert.equal(unlocked('freecell.efficient_win',r.state),efficient);assert.equal(unlocked('freecell.quick_win',r.state),quick);}
  for(const conversions of [29,30]){const r=common.applyAchievementEvent(common.emptyAchievementState(),{...base,gameId:'rpsBattleNext',facts:[{key:'conversions',value:conversions}]});assert.equal(unlocked('rpsBattle.conversion_storm',r.state),conversions===30);}
  const practice=common.applyAchievementEvent(common.emptyAchievementState(),{...base,isOfficial:false,facts:cases[2][0]});assert.equal(practice.state.completedSessionCount,0);assert.equal(practice.newlyUnlocked.length,0);
  const e=new arena.ArenaEngine({...plain(arena.arenaDefaultConfig()),counts:[3,4,5]});e.round.finished=true;
  const p=controller(arena,e,reset());await p.publishResult();assert.equal(p.events.length,0);
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
    if(lib===block){engine.round.maxClear=4;engine.round.lines=20;engine.round.level=3;engine.round.milestones=7;}
    if(lib===fruit){engine.round.highest=10;engine.round.score=600;engine.round.drops=1;}
    const raw=engine.serialize();p.storage.load=async()=>raw;await p.boot();await flush();
    assert.equal(common.achievementSummaryForState(durable).unlocked,3);assert.equal(durable.completedSessionCount,0);
  }
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
console.log(`\n${count} integration groups passed; all 22 achievements exercised. Native toast appearance remains device QA.`);
