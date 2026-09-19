#!/usr/bin/env node
// Runs production ArkTS rules, controllers, persistence bridge and achievement gateway.
// Replaces only ArkUI/OS providers; never starts a simulator.
import assert from 'node:assert/strict';
import {readFileSync, existsSync, readdirSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
const root=new URL('../',import.meta.url);
const read=path=>readFileSync(new URL(path,root),'utf8');
const main=path=>read('entry/src/main/ets/'+path);
const clean=text=>text.replace(/^import[\s\S]*?;\s*$/gm,'').replace(/^export default /gm,'').replace(/^export /gm,'').replace(/^@Observed\s*$/gm,'');
const ts=text=>stripTypeScriptTypes(clean(text),{mode:'transform'});
const plain=x=>JSON.parse(JSON.stringify(x));
let passed=0;
async function test(name,fn){await fn();passed++;console.log('PASS '+name);}
const names=['StarModel','StarRules','StarGenerator','StarFallback','StarEngine','StarLayout','StarProgress','StarPreparation','StarPalette'];
const coreSource=names.map(n=>main('gamesNext/starPop/'+n+'.ets')).join('\n');
const exports='StarEngine,StarGenerator,StarProgress,StarPreparation,StarPalette,starFallback,starVerifyPuzzle,starGroup,starGroups,starGravityTiles,starCollapse,starTiles,starRemaining,starValidBoard,starGain,starBonus,starTarget,starColors,starLayout,starViewport,starUsesCreases';
const core=vm.runInNewContext(ts(coreSource)+'\n({'+exports+'})',{setTimeout,clearTimeout});
vm.runInNewContext(ts(coreSource+'\n'+read('entry/src/ohosTest/ets/test/StarPop.test.ets'))+'\nstarPopTest();',{
 describe:(_n,fn)=>fn(),it:(n,_k,fn)=>{fn();passed++;console.log('PASS '+n);},
 expect:v=>({assertEqual:e=>assert.equal(v,e)}),TestType:{FUNCTION:1},Size:{SMALLTEST:1},Level:{LEVEL0:1},setTimeout,clearTimeout
});
function puzzle(seed=42,mode='easy'){
 const g=new core.StarGenerator(seed,mode);while(!g.done&&g.steps<83)g.advance();
 assert.ok(g.done);assert.ok(g.steps<=82);assert.ok(g.result());return g.result();
}
await test('1,000 seeded boards: reachable targets, unique IDs, exact scoring, deterministic generation and lossless saves',()=>{
 let turns=0; const scores={easy:[],classic:[]};
 for(const mode of ['easy','classic'])for(let seed=1;seed<=500;seed++){
  const p=puzzle(seed,mode),e=new core.StarEngine();assert.ok(core.starVerifyPuzzle(p,mode));assert.ok(e.start(mode,p));
  assert.equal(new Set(p.cells).size,core.starColors(mode));
  for(const stage of [1,3,7,11,500])assert.ok(core.starTarget(stage,p.witness)<=p.witness);
  for(const cell of p.path){
   const before=e.serialize(),count=core.starRemaining(e.round.cells),ids=new Set(e.round.ids.filter(id=>id>=0));
   const group=core.starGroup(e.round.cells,cell);assert.ok(group.length>=2);
   const score=e.round.score;const turn=e.pop(cell);assert.ok(turn);turns++;
   assert.equal(e.round.score,score+group.length**2*5);assert.equal(core.starRemaining(e.round.cells),count-group.length);
   assert.ok(core.starValidBoard(e.round.cells,e.round.ids,core.starColors(mode)));
   for(const id of e.round.ids.filter(id=>id>=0))assert.ok(ids.has(id),'no new tiles');
   assert.equal(new Set(e.round.ids.filter(id=>id>=0)).size,core.starRemaining(e.round.cells));
   const restored=new core.StarEngine();assert.ok(restored.restore(e.serialize()),mode+'/'+seed+'/'+cell);assert.equal(restored.serialize(),e.serialize());
   assert.notEqual(before,e.serialize());
  }
  assert.equal(e.round.status,'stageEnd');assert.equal(e.totalScore(),p.witness);scores[mode].push(p.witness);
  if(seed<=10)assert.deepEqual(plain(p),plain(puzzle(seed,mode)));
 }
 console.log('  verified '+turns+' moves; min reachable score easy/classic: '+Math.min(...scores.easy)+'/'+Math.min(...scores.classic));
});
await test('singletons, missing IDs and invalid coordinates cannot change score or progress',()=>{
 const e=new core.StarEngine(),raw=e.serialize();
 for(const cell of [-1,80,3.5,NaN,Infinity])assert.equal(e.pop(cell),undefined);
 assert.equal(e.serialize(),raw);
 const singleton=e.round.cells.findIndex((_c,i)=>core.starGroup(e.round.cells,i).length===1);
 assert.ok(singleton>=0);assert.equal(e.pop(singleton),undefined);assert.equal(e.serialize(),raw);
});
await test('a no-move failure can be undone once, or settled exactly once and restored',()=>{
 let e;
 for(let seed=1;seed<100;seed++){
  e=new core.StarEngine();e.start('classic',puzzle(seed,'classic'));
  while(e.round.status==='playing'){
   const groups=core.starGroups(e.round.cells).sort((a,b)=>a.length-b.length);e.pop(groups[0][0]);
  }
  if(e.round.status==='failed')break;
 }
 assert.equal(e.round.status,'failed');const failed=e.serialize();
 assert.ok(e.undo());assert.equal(e.round.status,'playing');assert.equal(e.canUndo(),false);
 assert.ok(e.restore(failed));assert.ok(e.finish());const raw=e.serialize();assert.equal(e.finish(),false);assert.equal(e.serialize(),raw);
 assert.equal(e.pending.filter(v=>v.type==='sessionEnd').length,1);assert.equal(e.canUndo(),false);
 assert.ok(new core.StarEngine().restore(raw));
 assert.equal(e.start('easy',puzzle(6)),false,'do not discard an unacknowledged settlement');
});
await test('early advance awards only the current remainder bonus and separates mode records',()=>{
 const e=new core.StarEngine();e.start('easy',puzzle(10));
 while(!e.canAdvance())e.pop(e.hint()[0]);
 const expected=e.round.total+e.round.score+core.starBonus(core.starRemaining(e.round.cells));
 assert.ok(e.advance(puzzle(11)));assert.equal(e.round.total,expected);assert.equal(e.round.highWater,0);
 assert.equal(e.round.undoUsed,false);assert.equal(e.canUndo(),false);assert.equal(e.profile.stageEasy,2);
 const high=e.profile.bestEasy;assert.ok(e.start('classic',puzzle(12,'classic')));assert.equal(e.bestScore(),0);
 e.pop(e.hint()[0]);assert.ok(e.bestScore()>0);assert.equal(e.profile.bestEasy,high);
});
await test('corrupt saves and malformed generation proofs are rejected atomically',()=>{
 const e=new core.StarEngine();e.pop(e.hint()[0]);const raw=e.serialize();
 const mutations=[s=>s.version=2,s=>s.round.mode='other',s=>s.round.seed=-1,s=>s.round.stage=0,
  s=>s.round.target++,s=>s.round.witness=0,s=>s.round.score=-1,s=>s.round.moves=NaN,
  s=>s.round.highWater=0,s=>s.round.ids[79]=s.round.ids[78],s=>s.round.cells.pop(),s=>s.round.cells[0]=99,
  s=>s.profile.totalCleared=0,s=>s.profile.maxGroup=81,s=>s.round.undo.moves=99,
  s=>s.round.bonus=1,s=>s.round.status='stageEnd',s=>s.pending[0].gameId='tetris',
  s=>s.pending[0].facts[0].key='fake',s=>s.pending.push(s.pending[0])];
 for(const mutate of mutations){const s=JSON.parse(raw);mutate(s);assert.equal(e.restore(JSON.stringify(s)),false);assert.equal(e.serialize(),raw);}
 for(const data of ['','null','{}','[1]','broken'])assert.equal(e.restore(data),false);
 for(const mutate of [p=>p.seed=-1,p=>p.cells.pop(),p=>p.cells[0]=99,p=>p.path[0]=99,p=>p.witness++,p=>p.path=[]]){
  const p=plain(puzzle());mutate(p);assert.equal(core.starVerifyPuzzle(p,'easy'),false);
 }
});
await test('viewport matrix: no overlapping UI, exact grid bounds, cover screens and all hinges',()=>{
 let cases=0;
 for(const w of [260,302,320,353,377,390,480,600,680,720,820,1024,1366,1920])for(const h of [240,350,480,560,640,780,844,1000,1366]){
  const l=core.starLayout(w,h,{top:24,bottom:16,left:0,right:0});cases++;
  if(l.small)continue;
  const parts=['board','stats','note','tools'].map(k=>l[k]);
  for(const p of parts){assert.ok(p.x>=-1e-6&&p.y>=0);assert.ok(p.x+p.width<=l.contentWidth+1e-6);assert.ok(p.y+p.height<=l.contentHeight+1e-6);}
  for(let i=0;i<parts.length;i++)for(let j=i+1;j<parts.length;j++){
   const a=parts[i],b=parts[j];assert.ok(a.x+a.width<=b.x||b.x+b.width<=a.x||a.y+a.height<=b.y||b.y+b.height<=a.y);
  }
  assert.ok(Math.abs(l.cell*8+l.tileGap*7+24-l.board.width)<1e-7);
  assert.ok(Math.abs(l.cell*10+l.tileGap*9+24-l.board.height)<1e-7);
  assert.ok(l.cell>=29);assert.equal(l.tools.height,l.wide?196:50);
 }
 const safe={top:24,bottom:16,left:0,right:0};
 const vertical=core.starLayout(840,880,safe,[{x:410,y:0,width:20,height:880}]);assert.equal(vertical.width,410);assert.equal(vertical.small,false);
 const horizontal=core.starLayout(840,880,safe,[{x:0,y:430,width:840,height:20}]);assert.equal(horizontal.y,450);assert.equal(horizontal.height,414);
 const triple=core.starLayout(1260,880,safe,[{x:410,y:0,width:20,height:880},{x:830,y:0,width:20,height:880}]);assert.equal(triple.width,410);
 const zero=core.starViewport(800,800,safe,[{x:400,y:0,width:0,height:800}]);assert.equal(zero.width,400);
 console.log('  '+cases+' layouts, plus vertical/horizontal/triple/zero-width hinge cases');
});
function method(source,name){
 const start=source.search(new RegExp('^  (?:private )?(?:async )?'+name+'\\(','m'));assert.ok(start>=0,name);
 const eol=source.indexOf('\n',start);return source.slice(start,source.slice(start,eol).trimEnd().endsWith('}')?eol:source.indexOf('\n  }',start)+4);
}
const commonFiles=['shell/AchievementModule.ets','shell/GameModule.ets','shell/AchievementRegistry.ets','shell/AchievementEngine.ets','shell/AchievementNotice.ets','app/AchievementService.ets'];
let durable,failAchievements=false;
const api=vm.runInNewContext(ts(commonFiles.map(main).join('\n')+'\nclass Gateway {\n'+method(main('pages/Index.ets'),'reportAchievementEvent')+'\n}')+
 '\n({Gateway,AchievementService,emptyAchievementState,achievementNoticeItemsForUnlocks,achievementGroupsForState,achievementRegistryIssues,ACHIEVEMENT_DEFINITIONS})',{
 console,CoopStorage:{async loadAchievementState(){return plain(durable);},async saveAchievementState(_ctx,state){if(failAchievements)return false;durable=plain(state);return true;}}
});
function gateway(){
 durable=plain(api.emptyAchievementState());failAchievements=false;
 const g=new api.Gateway();Object.assign(g,{appContext:{},activeGame:'starPop',achievementService:new api.AchievementService(),notices:[]});
 g.enqueueAchievementNotices=result=>g.notices.push(...api.achievementNoticeItemsForUnlocks(result.newlyUnlocked));return g;
}
function bridge(e,g=gateway()){
 const s={raw:'',failSave:false,failAck:false,writes:0,reports:[],records:[]};
 const p=new core.StarProgress(e,{
  async save(raw){s.writes++;if(s.failSave||s.failAck&&JSON.parse(raw).pending.length===0)return false;s.raw=raw;return true;},
  async report(ev){assert.ok(s.raw.length>0);s.reports.push(plain(ev));return g.reportAchievementEvent(ev);},
  record(score){s.records.push(score);}
 });return {p,s,g};
}
const unlocked=id=>durable.progresses.some(p=>p.achievementId===id&&p.unlockedAt>0);
await test('real moves → durable save → Index gateway → achievement wall and all three SVG medals',async()=>{
 assert.equal(api.achievementRegistryIssues().length,0);
 const e=new core.StarEngine(),{p,g}=bridge(e);assert.ok(await p.flush());assert.equal(g.notices.length,0);
 let rounds=0;
 while(e.profile.totalCleared<100||e.profile.maxGroup<8){
  assert.ok(rounds++<10);
  e.start(rounds%2?'easy':'classic',puzzle(rounds,rounds%2?'easy':'classic'));
  while(e.round.status==='playing'){e.pop(e.hint()[0]);assert.ok(await p.flush());}
  if(e.round.status==='failed'){e.finish();assert.ok(await p.flush());}
 }
 for(const id of ['first','cluster','collector'])assert.ok(unlocked('starPop.'+id));
 assert.equal(g.notices.filter(n=>n.gameId==='starPop').length,3);
 const groups=api.achievementGroupsForState(durable,'all');assert.ok(groups.some(g=>g.definition.gameId==='starPop'));
 for(const d of api.ACHIEVEMENT_DEFINITIONS.filter(d=>d.gameId==='starPop'))assert.ok(existsSync(new URL('entry/src/main/resources/rawfile/'+d.badgeAssetPath,root)));
 assert.ok(await p.flush());assert.equal(g.notices.filter(n=>n.gameId==='starPop').length,3,'no repeated badges');
});
await test('failed board persistence never publishes achievements; retry recovers',async()=>{
 const e=new core.StarEngine(),{p,s}=bridge(e);e.pop(e.hint()[0]);s.failSave=true;
 assert.equal(await p.flush(),false);assert.equal(s.reports.length,0);assert.ok(e.pending.length);
 s.failSave=false;assert.ok(await p.flush());assert.ok(unlocked('starPop.first'));assert.equal(e.pending.length,0);
});
await test('achievement or acknowledgement write failures retain the event across reload without duplicate notices',async()=>{
 const e=new core.StarEngine(),{p,s,g}=bridge(e);e.pop(e.hint()[0]);failAchievements=true;
 assert.equal(await p.flush(),false);assert.ok(e.pending.length);assert.equal(g.notices.length,0);
 failAchievements=false;s.failAck=true;assert.equal(await p.flush(),false);assert.ok(unlocked('starPop.first'));assert.ok(e.pending.length);
 const count=g.notices.length,restored=new core.StarEngine();assert.ok(restored.restore(s.raw));
 assert.ok(await bridge(restored,g).p.flush());assert.equal(restored.pending.length,0);assert.equal(g.notices.length,count);
});
await test('a delayed acknowledgement saves the newer board and preserves its newer milestone',async()=>{
 const e=new core.StarEngine();e.pop(e.hint()[0]);let release;const writes=[];
 const p=new core.StarProgress(e,{async save(raw){writes.push(JSON.parse(raw));return true;},
  report:()=>new Promise(resolve=>release=resolve),record(){}});
 const flushing=p.flush();await new Promise(r=>setImmediate(r));const old=e.pending[0].eventId;
 e.pop(e.hint()[0]);const expected=plain(e.round),newId=e.pending[0].eventId;assert.notEqual(old,newId);
 release(true);assert.ok(await flushing);assert.deepEqual(writes.at(-1).round,expected);assert.equal(e.pending[0].eventId,newId);
});
await test('stages do not inflate completed-session counts; final settlement and reload count once',async()=>{
 const e=new core.StarEngine(),{p,s,g}=bridge(e);const good=core.starFallback('easy');e.start('easy',good);
 for(const cell of good.path)e.pop(cell);assert.ok(await p.flush());assert.equal(durable.completedSessionCount,0);
 e.advance(puzzle(2));assert.ok(await p.flush());assert.equal(durable.completedSessionCount,0);
 for(let seed=1;seed<100;seed++){
  e.start('classic',puzzle(seed,'classic'));
  while(e.round.status==='playing')e.pop(core.starGroups(e.round.cells).sort((a,b)=>a.length-b.length)[0][0]);
  if(e.round.status==='failed')break;
 }
 e.finish();s.failAck=true;assert.equal(await p.flush(),false);assert.equal(durable.completedSessionCount,1);assert.equal(s.records.length,0);
 const r=new core.StarEngine();assert.ok(r.restore(s.raw));const next=bridge(r,g);assert.ok(await next.p.flush());
 assert.equal(durable.completedSessionCount,1);assert.equal(next.s.records.length,1);assert.ok(await next.p.flush());assert.equal(next.s.records.length,1);
});

const pageSource=main('gamesNext/starPop/StarPage.ets');
const pageMethods=['boot','seed','canPlay','preview','clearPreview','tap','completeTurn','later','finishMotion','syncCounters','sync','undo','showHint',
 'present','dialogAction','replaceRound','save','saveAndExit','exitRequested','themeChanged','soundChanged','backgrounded','relayout'];
let timerSeq=0;const timers=new Map();
const rt=vm.runInNewContext(ts(coreSource+'\nclass Page {\n'+pageMethods.map(n=>method(pageSource,n)).join('\n')+'\n}\nclass Board {\n'+method(main('gamesNext/starPop/StarBoard.ets'),'cellFor')+'\n}')+'\n({Page,Board,StarPreparation})',{
 console,Curve:{EaseOut:0,EaseIn:1},setTimeout:fn=>{const id=++timerSeq;timers.set(id,fn);return id;},clearTimeout:id=>timers.delete(id)
});
function controller(){
 timers.clear();const p=new rt.Page();
 Object.assign(p,{engine:new core.StarEngine(),loaded:true,loading:false,disposed:false,skipSave:false,backgroundPaused:false,context:{},
  animationToken:0,animationTimer:-1,saveSequence:0,tiles:[],selected:[],clearing:[],clearScale:1,busy:false,gain:0,dialog:'',saving:false,saveFailed:false,hint:'',
  pageWidth:390,pageHeight:844,insets:{top:24,bottom:16,left:0,right:0},creases:[],pendingMode:'easy',
  layout:core.starLayout(390,844,{top:24,bottom:16,left:0,right:0}),
  audio:{play(){},silence(){},setEnabled(){}},host:{setDark(){}},perf:{logMove(){},layout(){}},
  preparation:{async prepare(mode,seed){return puzzle(seed,mode);},cancel(){}},storage:{async load(){return '';}},progress:{async flush(){return true;}},
  scroller:{scrollTo(){}},exits:0,exitToHub(){this.exits++;},getUIContext(){return {animateTo:(_o,fn)=>fn()};}
 });p.sync();return p;
}
function drain(){let n=0;while(timers.size){assert.ok(n++<90);const [id,fn]=timers.entries().next().value;timers.delete(id);fn();}return n;}
await test('page tap commits once, animates finitely and uses stable IDs at the new positions',()=>{
 const p=controller(),cell=p.engine.hint()[0],id=p.engine.round.ids[cell];p.preview(id);assert.ok(p.selected.length>=2);
 p.tap(id);const raw=p.engine.serialize();assert.ok(p.busy);p.tap(id);assert.equal(p.engine.serialize(),raw);
 assert.equal(drain(),2);assert.equal(p.busy,false);assert.equal(timers.size,0);
 assert.deepEqual(plain(p.tiles),plain(core.starTiles(p.engine.round.cells,p.engine.round.ids)));
 const board=new rt.Board();board.tiles=p.tiles;const survivor=p.tiles[0];assert.equal(board.cellFor(survivor.id),survivor.cell);
 const stale=survivor;board.tiles=p.tiles.map(t=>({...t,cell:t.id===stale.id?79:t.cell}));assert.equal(board.cellFor(stale.id),79);
 assert.match(main('gamesNext/starPop/StarBoard.ets'),/\.translate\(\{ x: \(this\.cellFor\(tile\.id\)/,'native position must subscribe to live array, not a stale ForEach item');
});
await test('empty-column animation falls vertically first, then slides left, with no second scoring pass',()=>{
 const p=controller();p.engine.round.cells.fill(-1);p.engine.round.ids.fill(-1);
 for(const [cell,color] of [[64,0],[72,0],[65,0],[73,0],[57,1],[66,2],[74,2]]){
  p.engine.round.cells[cell]=color;p.engine.round.ids[cell]=cell;
 }
 p.sync();p.tap(64);const raw=p.engine.serialize();
 const tick=()=>{const [id,fn]=timers.entries().next().value;timers.delete(id);fn();};
 tick();assert.equal(p.tiles.find(t=>t.id===57).cell,73,'fall to the bottom of the old column');
 assert.equal(p.engine.serialize(),raw);tick();assert.equal(p.tiles.find(t=>t.id===57).cell,72,'only then move into the empty left column');
 tick();assert.equal(p.busy,false);assert.equal(timers.size,0);assert.equal(p.engine.serialize(),raw);
});
await test('clearing the entire board credits 500 once and next stage restores all 80 tiles',()=>{
 const e=new core.StarEngine();e.round.cells.fill(0);const turn=e.pop(0);
 assert.equal(turn.removedIds.length,80);assert.equal(e.round.bonus,500);assert.equal(e.totalScore(),32500);
 assert.ok(e.advance(puzzle(19)));assert.equal(e.round.total,32500);assert.equal(core.starRemaining(e.round.cells),80);
 assert.equal(e.advance(puzzle(20)),false);assert.equal(e.round.total,32500);
});
await test('resize and background cancel decoration, preserve a committed turn and ignore old timers',()=>{
 const p=controller();p.tap(p.engine.round.ids[p.engine.hint()[0]]);const saved=p.engine.serialize(),stale=[...timers.values()];
 p.pageWidth=820;p.pageHeight=1100;p.relayout();assert.equal(p.engine.serialize(),saved);assert.ok(p.layout.wide);assert.equal(p.busy,false);
 stale.forEach(fn=>fn());assert.equal(timers.size,0);assert.equal(p.engine.serialize(),saved);
 p.backgrounded();assert.equal(p.dialog,'more');p.dialogAction('close');assert.equal(p.backgroundPaused,false);
});
await test('modal, tiny window and pending save block input; hint and preview never change the board',()=>{
 const p=controller(),id=p.engine.round.ids[p.engine.hint()[0]],raw=p.engine.serialize();
 p.showHint();p.preview(id);p.clearPreview();assert.equal(p.engine.serialize(),raw);
 for(const [key,value] of [['dialog','more'],['saving',true],['busy',true]]){p[key]=value;p.tap(id);assert.equal(p.engine.serialize(),raw);p[key]=key==='dialog'?'':false;}
 p.pageWidth=260;p.relayout();p.tap(id);assert.equal(p.engine.serialize(),raw);
});
await test('mode/restart/advance persist before replacing and failed saves cannot discard the current journey',async()=>{
 const p=controller();p.dialogAction('classic');assert.equal(p.dialog,'changeMode');assert.equal(p.engine.round.mode,'easy');
 const raw=p.engine.serialize();p.progress.flush=async()=>false;await p.replaceRound(false);
 assert.equal(p.engine.serialize(),raw);assert.ok(p.saveFailed);assert.equal(p.saving,false);
 p.progress.flush=async()=>true;await p.replaceRound(false);assert.equal(p.engine.round.mode,'classic');assert.equal(p.dialog,'');
 assert.equal(p.engine.round.stage,1);assert.equal(p.engine.round.cells.length,80);
 await p.saveAndExit();assert.equal(p.exits,1);assert.ok(p.skipSave);
});
await test('background during preparation cannot replace the saved board or revive an exited page',async()=>{
 const p=controller();let resolve;let cancelled=0;
 p.preparation={prepare:()=>new Promise(r=>resolve=r),cancel(){cancelled++;resolve?.(undefined);}};
 const raw=p.engine.serialize(),pending=p.replaceRound(false);await new Promise(r=>setImmediate(r));
 p.backgrounded();await pending;assert.equal(p.engine.serialize(),raw);assert.equal(cancelled,1);assert.equal(p.dialog,'more');assert.equal(p.saving,false);
 const q=controller();q.preparation.prepare=()=>new Promise(r=>resolve=r);const next=q.replaceRound(false);await new Promise(r=>setImmediate(r));
 q.disposed=true;resolve(puzzle(77));await next;assert.equal(q.engine.round.stage,1);assert.equal(q.exits,0);
});
await test('load failures and malformed saves never overwrite the original data',async()=>{
 const p=controller();p.loaded=false;let writes=0;p.progress.flush=async()=>{writes++;return true;};
 p.storage.load=async()=>{throw Error('read');};await p.boot();assert.equal(p.dialog,'loadError');assert.equal(p.loaded,false);assert.equal(writes,0);
 p.storage.load=async()=>'{broken';await p.boot();assert.equal(p.dialog,'corrupt');assert.equal(p.loaded,false);assert.equal(writes,0);
 p.dialogAction('leaveUntouched');assert.ok(p.skipSave);assert.equal(p.exits,1);
});
await test('incremental generation yields, cancels and returns only verified puzzles',async()=>{
 timers.clear();const p=new rt.StarPreparation();let finished=false;
 const preparing=p.prepare('easy',8).then(result=>{finished=true;return result;});assert.equal(finished,false);assert.equal(timers.size,1);
 const ticks=drain();assert.ok(ticks>10);const result=await preparing;assert.ok(core.starVerifyPuzzle(result,'easy'));assert.equal(timers.size,0);
 const aborted=p.prepare('classic',9);const stale=[...timers.values()];p.cancel();assert.equal(await aborted,undefined);stale.forEach(fn=>fn());assert.equal(timers.size,0);
});
await test('home appends Star Pop last without changing existing visible games or the hidden Tangram route',()=>{
 const hub=main('pages/HubPage.ets');const source=['shell/GameModule.ets','shell/GameRegistry.ets'].map(main).join('\n')+'\n'+
  ['HOME_GAME_ORDER','HIDDEN_HOME_GAME_IDS'].map(n=>hub.match(new RegExp('const '+n+': string\\[\\] = \\[[\\s\\S]*?\\];'))[0]).join('\n')+
  '\nclass Hub {\n'+method(hub,'homeModules')+'\n}';
 const h=vm.runInNewContext(ts(source)+'\n({Hub,gameLogoPath})');const ids=Array.from(new h.Hub().homeModules(),g=>g.id);
 assert.equal(ids.at(-1),'starPop');assert.deepEqual(ids.slice(0,7),['suikaNext','minesweeperNext','tetrisNext','chicken2048Next','freecellNext','rpsBattleNext','bloomLines']);
 assert.ok(!ids.includes('tangram'));assert.equal(h.gameLogoPath('starPop'),'gamesNext/starPop/scene/logo.svg');
 const index=main('pages/Index.ets');assert.match(index,/activeGame === 'starPop'[\s\S]*?starPopExitRequest/);assert.match(index,/StarPage\(\{/);
});
await test('theme assets, three medal SVGs and seven bounded nonclipping audio clips all exist',()=>{
 const raw='entry/src/main/resources/rawfile/';
 for(const dark of [false,true]){
  for(let c=0;c<5;c++)assert.ok(existsSync(new URL(raw+core.StarPalette.tile(c,dark),root)));
  for(const name of ['frame','sprigs','guide0','guide1','guide2'])assert.ok(existsSync(new URL(raw+core.StarPalette.scene(name,dark),root)));
  for(const name of ['back','sound','muted','undo','hint','more','next','check','close','restart','help','trophy','leaf','spark','expand'])
   for(const tone of ['ink','accent','on'])assert.ok(existsSync(new URL(raw+core.StarPalette.icon(name,dark,tone),root)));
 }
 const audio=new URL(raw+'gamesNext/starPop/audio/',root);assert.equal(readdirSync(audio).length,7);
 for(const name of readdirSync(audio)){
  const b=readFileSync(new URL(name,audio));assert.equal(b.toString('ascii',0,4),'RIFF');assert.equal(b.toString('ascii',8,12),'WAVE');
  assert.equal(b.readUInt16LE(22),1);assert.equal(b.readUInt32LE(24),24000);assert.equal(b.readUInt16LE(34),16);assert.ok(b.length<40000);
  let peak=0;for(let i=44;i+1<b.length;i+=2)peak=Math.max(peak,Math.abs(b.readInt16LE(i)));assert.ok(peak>1000&&peak<28000);
 }
});
console.log('\nStar Pop: '+passed+' test groups passed. Native layout/performance still requires user device testing.');
