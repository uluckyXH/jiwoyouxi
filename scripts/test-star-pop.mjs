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
const clean=text=>text.replace(/^import[\s\S]*?;\s*$/gm,'').replace(/^export default /gm,'').replace(/^export /gm,'').replace(/^@Observed\s*$/gm,'').replace(/@Track\s+/g,'');
const ts=text=>stripTypeScriptTypes(clean(text),{mode:'transform'});
const plain=x=>JSON.parse(JSON.stringify(x));
let passed=0;
async function test(name,fn){await fn();passed++;console.log('PASS '+name);}
const names=['StarModel','StarRules','StarPlanner','StarGenerator','StarFallback','StarEngine','StarLayout','StarProgress','StarPreparation','StarHintSearch','StarPalette','StarScene'];
const coreSource=names.map(n=>main('gamesNext/starPop/'+n+'.ets')).join('\n');
const exports='StarEngine,StarPlanner,StarGenerator,StarProgress,StarPreparation,StarHintSearch,StarPalette,StarScene,StarVisualTile,starValidPlan,starFallback,starVerifyPuzzle,starGroup,starGroups,starGravityTiles,starCollapse,starTiles,starRemaining,starValidBoard,starGain,starBonus,starTarget,starColors,starLayout,starViewport,starUsesCreases';
const clock={starNow:()=>Date.now()};
const core=vm.runInNewContext(ts(coreSource)+'\n({'+exports+'})',{setTimeout,clearTimeout,...clock});
vm.runInNewContext(ts(coreSource+'\n'+read('entry/src/ohosTest/ets/test/StarPop.test.ets'))+'\nstarPopTest();',{
 describe:(_n,fn)=>fn(),it:(n,_k,fn)=>{fn();passed++;console.log('PASS '+n);},
 expect:v=>({assertEqual:e=>assert.equal(v,e)}),TestType:{FUNCTION:1},Size:{SMALLTEST:1},Level:{LEVEL0:1},setTimeout,clearTimeout,...clock
});
function puzzle(seed=42,mode='easy'){
 const g=new core.StarGenerator(seed,mode);while(!g.done&&g.steps<83)g.advance();
 assert.ok(g.done);assert.ok(g.steps<=82);assert.ok(g.result());return g.result();
}
await test('1,000 seeded boards: actual hints always pass, including other tiles in the same group and reload after every move',()=>{
 let turns=0; const scores={easy:[],classic:[]};
 for(const mode of ['easy','classic'])for(let seed=1;seed<=500;seed++){
  const p=puzzle(seed,mode);let e=new core.StarEngine();assert.ok(core.starVerifyPuzzle(p,mode));assert.ok(e.start(mode,p));
  assert.equal(new Set(p.cells).size,core.starColors(mode));
  for(const stage of [1,3,7,11,500])assert.ok(core.starTarget(stage,p.witness)<=p.witness);
  e.round.stage=[1,3,7,11,500][seed%5];e.round.target=core.starTarget(e.round.stage,p.witness);
  for(let step=0;e.round.status==='playing';step++){
   assert.ok(step<40);assert.ok(e.hintIsWinning(),mode+'/'+seed+'/'+step);
   const suggested=e.hint();assert.ok(suggested.includes(p.path[step]));
   const cell=suggested.at(-1);
   const before=e.serialize(),count=core.starRemaining(e.round.cells),ids=new Set(e.round.ids.filter(id=>id>=0));
   const group=core.starGroup(e.round.cells,cell);assert.ok(group.length>=2);
   const score=e.round.score;const turn=e.pop(cell);assert.ok(turn);turns++;
   assert.equal(e.round.score,score+group.length**2*5);assert.equal(core.starRemaining(e.round.cells),count-group.length);
   assert.ok(core.starValidBoard(e.round.cells,e.round.ids,core.starColors(mode)));
   for(const id of e.round.ids.filter(id=>id>=0))assert.ok(ids.has(id),'no new tiles');
   assert.equal(new Set(e.round.ids.filter(id=>id>=0)).size,core.starRemaining(e.round.cells));
   const restored=new core.StarEngine();assert.ok(restored.restore(e.serialize()),mode+'/'+seed+'/'+cell);assert.equal(restored.serialize(),e.serialize());
   assert.notEqual(before,e.serialize());
   e=restored;
  }
  assert.equal(e.round.status,'stageEnd');assert.equal(e.totalScore(),p.witness);scores[mode].push(p.witness);
  if(seed<=10)assert.deepEqual(plain(p),plain(puzzle(seed,mode)));
 }
 console.log('  verified '+turns+' moves; min reachable score easy/classic: '+Math.min(...scores.easy)+'/'+Math.min(...scores.classic));
});
function plan(cells){
 const solver=new core.StarPlanner(cells);while(!solver.done&&solver.steps<82)solver.advance();
 assert.ok(solver.done);const result=solver.result();assert.ok(core.starValidPlan(cells,result));return result;
}
await test('regression: easy seed 12, target 1100, old largest-only hint fails at 1025 but route hints reach 1910',()=>{
 const p=puzzle(12),old=new core.StarEngine();old.start('easy',p);
 while(old.round.status==='playing')old.pop(core.starGroups(old.round.cells).sort((a,b)=>b.length-a.length)[0][0]);
 assert.equal(old.round.target,1100);assert.equal(old.totalScore(),1025);assert.equal(old.round.status,'failed');
 const fixed=new core.StarEngine();fixed.start('easy',p);
 while(fixed.round.status==='playing')fixed.pop(fixed.hint()[0]);
 assert.equal(fixed.totalScore(),1910);assert.equal(fixed.round.status,'stageEnd');
 assert.equal(fixed.round.target,1100,'no hidden target reduction');
});
await test('hints survive an off-route move, undo, reload and the next stage without changing rewards or IDs',()=>{
 const e=new core.StarEngine();e.start('easy',puzzle(12));const first=plain(e.hint()),original=plain(e.round);
 const other=core.starGroups(e.round.cells).find(group=>!first.includes(group[0]));assert.ok(other);
 e.pop(other[0]);assert.equal(e.round.hintPlan,undefined);assert.equal(e.hintIsWinning(),false);
 const restored=new core.StarEngine();assert.ok(restored.restore(e.serialize()));assert.ok(restored.undo());
 assert.deepEqual(plain(restored.round.cells),original.cells);assert.deepEqual(plain(restored.round.ids),original.ids);
 assert.deepEqual(plain(restored.hint()),first);assert.ok(restored.hintIsWinning());
 while(restored.round.status==='playing')restored.pop(restored.hint().at(-1));
 assert.equal(restored.round.status,'stageEnd');const total=restored.totalScore();
 assert.ok(restored.advance(puzzle(13)));assert.equal(restored.totalScore(),total);assert.equal(restored.round.score,0);
 assert.deepEqual(plain(restored.round.hintPlan.path),plain(puzzle(13).path));
 while(restored.round.status==='playing')restored.pop(restored.hint()[0]);assert.equal(restored.round.status,'stageEnd');
});
await test('legacy saves and damaged optional plans preserve the board, then safely rebuild a route when requested',()=>{
 const e=new core.StarEngine();e.start('easy',puzzle(12));e.pop(e.hint()[0]);const saved=plain(e.snapshot());
 const malformed=[undefined,null,[],{},'bad',{path:[],score:0},{path:[80],score:999},
  {path:Array(41).fill(1),score:0},{path:e.round.hintPlan.path,score:e.round.hintPlan.score+1},
  {path:[1.2],score:100},{path:[null],score:100}];
 for(const bad of malformed){
  const raw=plain(saved);raw.round.hintPlan=bad;raw.round.undo.hintPlan=bad;
  const r=new core.StarEngine();assert.ok(r.restore(JSON.stringify(raw)));assert.equal(r.round.hintPlan,undefined);
  assert.equal(r.round.undo.hintPlan,undefined);assert.deepEqual(plain(r.round.cells),saved.round.cells);
  assert.equal(r.round.target,saved.round.target);assert.equal(r.round.score,saved.round.score);
  const before=plain(r.snapshot());assert.ok(r.applyHintPlan(plan(r.round.cells)));assert.ok(r.hintIsWinning());
  delete before.round.hintPlan;const after=plain(r.snapshot());delete after.round.hintPlan;assert.deepEqual(after,before);
  const verified=r.serialize();assert.equal(r.applyHintPlan({path:[80],score:99999}),false);assert.equal(r.serialize(),verified);
  while(r.round.status==='playing')r.pop(r.hint()[0]);assert.equal(r.round.status,'stageEnd');
 }
});
await test('after independent moves, every claimed winning plan really passes; no false guarantee for a stranded board',()=>{
 let wins=0,references=0;
 for(const mode of ['easy','classic'])for(let seed=1;seed<=60;seed++){
  const e=new core.StarEngine();e.start(mode,puzzle(seed,mode));
  for(let i=0;i<8&&e.round.status==='playing';i++)e.pop(core.starGroups(e.round.cells).sort((a,b)=>a.length-b.length)[0][0]);
  if(e.round.status!=='playing')continue;
  const before=e.serialize(),result=plan(e.round.cells);
  assert.equal(e.serialize(),before,'planner never changes the live board');assert.ok(e.applyHintPlan(result));
  const expected=e.round.score+result.score,winning=e.hintIsWinning();
  if(winning)wins++;else references++;
  while(e.round.status==='playing')e.pop(e.hint()[0]);assert.equal(e.round.score+e.round.bonus,expected);
  assert.equal(e.round.status,winning?'stageEnd':'failed');
 }
 assert.ok(wins>0);assert.ok(references>0);console.log('  detours: '+wins+' verified winning routes, '+references+' reference routes (not falsely marked as passing)');
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
const pageMethods=['boot','beginLoadFeedback','endLoadFeedback','preparePuzzle','seed','canPlay','preview','clearPreview','tap',
 'completeTurn','later','finishMotion','syncCounters','sync','undo','showHint','cancelHint','present','dialogAction','replaceRound','save',
 'persist','reportProgress','saveAndExit','leavePage','exitRequested','dialogChanged','themeChanged','soundChanged',
 'backgrounded','relayout','aboutToDisappear'];
let timerSeq=0;const timers=new Map();
const rt=vm.runInNewContext(ts(coreSource+'\nclass Page {\n'+pageMethods.map(n=>method(pageSource,n)).join('\n')+'\n}')+'\n({Page,StarPreparation,StarHintSearch})',{
 console,...clock,Curve:{EaseOut:0,EaseIn:1},setTimeout:fn=>{const id=++timerSeq;timers.set(id,fn);return id;},clearTimeout:id=>timers.delete(id)
});
function controller(){
 timers.clear();const p=new rt.Page();
 Object.assign(p,{engine:new core.StarEngine(),loaded:true,loading:false,disposed:false,leaving:false,skipSave:false,backgroundPaused:false,context:{},
  loadFeedbackTimer:-1,loadFeedbackToken:0,loadFeedback:'',hintToken:0,findingHint:false,hintSearch:new rt.StarHintSearch(),
  animationToken:0,animationTimer:-1,saveSequence:0,tiles:[],selected:[],previewCount:0,scene:new core.StarScene(),tileViews:[],busy:false,gain:0,dialog:'',saving:false,saveFailed:false,hint:'',
  pageWidth:390,pageHeight:844,insets:{top:24,bottom:16,left:0,right:0},creases:[],pendingMode:'easy',
  layout:core.starLayout(390,844,{top:24,bottom:16,left:0,right:0}),
  audio:{play(){},silence(){},setEnabled(){},release(){}},host:{setDark(){},release(){}},
  perf:{move(){},layout(){},event(){},duration(){},saved(){},inputBlocked(){},animationDelay(){},sample(){},stopSample(){},release(){}},
  preparation:{async prepare(mode,seed){return puzzle(seed,mode);},cancel(){}},storage:{async load(){return '';}},progress:{async flush(){return true;}},
  scroller:{scrollTo(){}},exits:0,exitToHub(){this.exits++;},getUIContext(){return {animateTo:(_o,fn)=>fn()};}
 });p.sync();return p;
}
function drain(){let n=0;while(timers.size){assert.ok(n++<90);const [id,fn]=timers.entries().next().value;timers.delete(id);fn();}return n;}
await test('cached page hints stay immediate, and playing the highlighted stable IDs passes the regression board',async()=>{
 const p=controller();p.engine.start('easy',puzzle(12));p.sync();
 while(p.engine.round.status==='playing'){
  const before=p.engine.serialize();await p.showHint();assert.equal(p.findingHint,false);assert.equal(timers.size,0);
  assert.match(p.hint,/过关路线/);assert.ok(p.previewCount>=2);assert.equal(p.engine.serialize(),before);
  const selected=plain(p.selected);await p.showHint();assert.deepEqual(plain(p.selected),selected);
  p.tap(selected.at(-1));drain();await Promise.resolve();
 }
 assert.equal(p.engine.round.status,'stageEnd');assert.equal(p.engine.totalScore(),1910);assert.equal(p.dialog,'stageEnd');
});
await test('old-save hint search yields, caches a valid plan and preserves target, score and board',async()=>{
 const p=controller();p.engine.start('easy',puzzle(12));p.sync();delete p.engine.round.hintPlan;
 const saved=p.engine.serialize(),pending=p.showHint();assert.ok(p.findingHint);assert.ok(p.canPlay());assert.equal(timers.size,1);
 assert.ok(drain()>10);await pending;assert.equal(p.findingHint,false);assert.equal(timers.size,0);assert.match(p.hint,/过关路线/);
 const snapshot=plain(p.engine.snapshot());delete snapshot.round.hintPlan;assert.deepEqual(snapshot,JSON.parse(saved));
 const route=p.engine.serialize();await p.showHint();assert.equal(p.engine.serialize(),route);assert.equal(timers.size,0);
 const restored=new core.StarEngine();assert.ok(restored.restore(route));assert.ok(restored.hintIsWinning());
});
await test('a stranded board is labelled reference only, without claiming it is impossible or lowering its target',async()=>{
 const p=controller();const r=p.engine.round;r.hintPlan=undefined;r.cells.fill(-1);r.ids.fill(-1);
 for(const cell of [72,73]){r.cells[cell]=0;r.ids[cell]=cell;}p.sync();
 const target=r.target,pending=p.showHint();drain();await pending;
 assert.equal(p.engine.hintIsWinning(),false);assert.match(p.hint,/参考走法/);assert.match(p.hint,/暂未找到达标路线/);
 assert.doesNotMatch(p.hint,/不可能|无法过关|可试试撤销/);assert.equal(r.target,target);assert.deepEqual(plain(p.selected),[72,73]);
});
await test('hint searches cannot publish stale highlights after touch, undo, fold, modal, background, replacement or exit',async()=>{
 const actions=[p=>p.preview(p.tiles[0].id),p=>p.tap(p.engine.round.ids[p.engine.hint()[0]]),p=>p.undo(),
  p=>{p.pageWidth=820;p.relayout();},p=>p.present('help'),p=>p.backgrounded(),p=>p.exitRequested(),
  p=>p.leavePage(),p=>p.aboutToDisappear(),p=>p.replaceRound(false)];
 for(const action of actions){
  const p=controller();p.engine.pop(p.engine.hint()[0]);p.sync();delete p.engine.round.hintPlan;
  const pending=p.showHint(),stale=[...timers.values()];assert.ok(p.findingHint);
  await action(p);const before=p.engine.serialize(),selected=plain(p.selected),text=p.hint;
  await pending;stale.forEach(fn=>fn());drain();
  assert.equal(p.findingHint,false);assert.equal(p.engine.serialize(),before);assert.deepEqual(plain(p.selected),selected);
  assert.equal(p.hint,text);assert.equal(timers.size,0);
 }
});
await test('cancelling one hint and requesting another cannot clear or replace the newer result',async()=>{
 const p=controller();delete p.engine.round.hintPlan;
 const first=p.showHint(),stale=[...timers.values()];p.clearPreview();const next=p.showHint();
 await first;assert.ok(p.findingHint);stale.forEach(fn=>fn());assert.equal(timers.size,1);
 drain();await next;assert.match(p.hint,/过关路线/);assert.equal(p.findingHint,false);assert.equal(timers.size,0);
});
await test('hint planning snapshots the input, stays bounded and reports cancellation without leaving timers',async()=>{
 timers.clear();const search=new rt.StarHintSearch(),cells=puzzle(12).cells,expected=plan(cells),timings=[];
 const pending=search.search(cells,t=>timings.push(t));cells.fill(-1);const ticks=drain();
 assert.deepEqual(plain(await pending),plain(expected));assert.ok(ticks>10&&ticks<=82);
 assert.equal(timings.length,1);assert.equal(timings[0].slices,ticks);assert.equal(timings[0].cancelled,false);
 const aborted=search.search(puzzle(1).cells,t=>timings.push(t)),stale=[...timers.values()];search.cancel();
 assert.equal(await aborted,undefined);stale.forEach(fn=>fn());assert.equal(timings[1].cancelled,true);assert.equal(timers.size,0);
});
await test('page tap commits once, animates finitely and uses stable IDs at the new positions',()=>{
 const p=controller(),cell=p.engine.hint()[0],id=p.engine.round.ids[cell];p.preview(id);assert.ok(p.selected.length>=2);
 p.tap(id);const raw=p.engine.serialize();assert.ok(p.busy);p.tap(id);assert.equal(p.engine.serialize(),raw);
 assert.equal(drain(),2);assert.equal(p.busy,false);assert.equal(timers.size,0);
 assert.deepEqual(plain(p.tiles),plain(core.starTiles(p.engine.round.cells,p.engine.round.ids)));
 for(const tile of p.tiles){assert.equal(p.scene.tiles[tile.id].cell,tile.cell);assert.equal(p.scene.tiles[tile.id].visible,true);}
 assert.equal(p.tileViews,p.scene.tiles);
 assert.match(main('gamesNext/starPop/StarTileView.ets'),/@ObjectLink tile: StarVisualTile/);
 assert.doesNotMatch(main('gamesNext/starPop/StarBoard.ets'),/\.find\(|\.includes\(|cellFor/);
});
await test('empty-column animation falls vertically first, then slides left, with no second scoring pass',()=>{
 const p=controller();p.engine.round.cells.fill(-1);p.engine.round.ids.fill(-1);
 for(const [cell,color] of [[64,0],[72,0],[65,0],[73,0],[57,1],[66,2],[74,2]]){
  p.engine.round.cells[cell]=color;p.engine.round.ids[cell]=cell;
 }
 p.sync();p.tap(64);const raw=p.engine.serialize();
 const tick=()=>{const [id,fn]=timers.entries().next().value;timers.delete(id);fn();};
 tick();assert.equal(p.tiles.find(t=>t.id===57).cell,73,'fall to the bottom of the old column');
 assert.equal(p.scene.tiles[57].cell,73);
 assert.equal(p.engine.serialize(),raw);tick();assert.equal(p.tiles.find(t=>t.id===57).cell,72,'only then move into the empty left column');
 assert.equal(p.scene.tiles[57].cell,72);
 tick();assert.equal(p.busy,false);assert.equal(timers.size,0);assert.equal(p.engine.serialize(),raw);
});
await test('visual changes touch only affected tile fields and keep node identities through all animation stages',()=>{
 const scene=new core.StarScene(),tiles=Array.from({length:80},(_,id)=>({id,color:id%4,cell:id})),counts=Array(80).fill(2);
 assert.equal(scene.restore('round:1',tiles,counts),true);const refs=[...scene.tiles],writes=[];
 for(const tile of scene.tiles)for(const key of ['cell','color','visible','selected','scale','groupCount']){
  let value=tile[key];Object.defineProperty(tile,key,{get:()=>value,set:next=>{writes.push([tile.id,key]);value=next;}});
 }
 assert.equal(scene.restore('round:1',tiles,counts),false);assert.equal(writes.length,0,'unchanged state causes no observable writes');
 scene.select([3,4,5,6]);assert.deepEqual(writes,[[3,'selected'],[4,'selected'],[5,'selected'],[6,'selected']]);
 writes.length=0;scene.select([3,4,5,6]);assert.equal(writes.length,0,'same preview causes no writes');
 scene.shrink([3,4]);assert.deepEqual(writes,[[3,'scale'],[4,'scale']]);
 writes.length=0;scene.hide([3,4]);assert.deepEqual(writes,[[3,'visible'],[4,'visible']]);
 writes.length=0;assert.equal(scene.place([{...tiles[1],cell:9},tiles[2]]),1);assert.deepEqual(writes,[[1,'cell']]);
 for(let id=0;id<80;id++)assert.equal(scene.tiles[id],refs[id],'no tile object recreation');
});
await test('reflow, undo, partial-save restore and a new round reconcile all visual tiles without stale position or color',()=>{
 const p=controller(),refs=[...p.scene.tiles];p.tap(p.engine.round.ids[p.engine.hint()[0]]);
 p.pageWidth=820;p.relayout();const visible=plain(p.scene.tiles.filter(t=>t.visible).map(t=>({id:t.id,color:t.color,cell:t.cell}))).sort((a,b)=>a.id-b.id);
 assert.deepEqual(visible,plain(p.tiles).sort((a,b)=>a.id-b.id));assert.ok(p.scene.tiles.every((t,id)=>t===refs[id]&&t.scale===1));
 const saved=p.engine.serialize(),q=controller();q.engine.restore(saved);q.sync();q.undo();
 assert.equal(q.scene.tiles.filter(t=>t.visible).length,80);
 for(const tile of q.tiles){const live=q.scene.tiles[tile.id];assert.equal(live.color,tile.color);assert.equal(live.cell,tile.cell);assert.equal(live.visible,true);}
 const old=q.scene.tiles[0];q.engine.start('classic',puzzle(91,'classic'));q.sync();assert.notEqual(q.scene.tiles[0],old);
 assert.equal(q.tileViews,q.scene.tiles);assert.ok(q.scene.tiles.every(t=>t.visible&&t.scale===1&&!t.selected));
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
await test('quick re-entry restores the same board without ever showing a loading dialog',async()=>{
 const p=controller();p.engine.pop(p.engine.hint()[0]);const saved=p.engine.serialize();
 p.loaded=false;p.storage.load=async()=>saved;
 const seen=[];let dialog='';Object.defineProperty(p,'dialog',{get:()=>dialog,set:v=>{seen.push(v);dialog=v;}});
 const loading=p.boot(),stale=[...timers.values()];assert.equal(p.dialog,'');assert.equal(p.canPlay(),false);
 await loading;assert.equal(p.loaded,true);assert.equal(p.dialog,'');assert.equal(p.engine.serialize(),saved);
 assert.ok(!seen.includes('loading'));assert.equal(p.loadFeedback,'');assert.equal(timers.size,0);
 stale.forEach(fn=>fn());assert.equal(p.loadFeedback,'');
 assert.match(pageSource,/@State @Watch\('dialogChanged'\) dialog: string = ''/);
});
await test('slow reading uses only inline feedback and dismisses it on completion or failure',async()=>{
 const p=controller(),raw=p.engine.serialize();p.loaded=false;let resolve;
 p.storage.load=()=>new Promise(r=>resolve=r);const pending=p.boot();
 const [id,fn]=timers.entries().next().value;timers.delete(id);fn();
 assert.ok(p.loadFeedback.length>0);assert.equal(p.dialog,'');assert.equal(p.canPlay(),false);
 resolve(raw);await pending;assert.equal(p.loadFeedback,'');assert.equal(p.dialog,'');assert.equal(timers.size,0);
 p.loaded=false;p.storage.load=async()=>{throw Error('read');};await p.boot();
 assert.equal(p.dialog,'loadError');assert.equal(p.loadFeedback,'');assert.equal(timers.size,0);
});
await test('exit during a pending restore invalidates late replies before the page is unmounted',async()=>{
 const p=controller();p.loaded=false;let resolve,writes=0;const raw=p.engine.serialize();
 p.storage.load=()=>new Promise(r=>resolve=r);p.progress.flush=async()=>{writes++;return true;};
 const pending=p.boot(),stale=[...timers.values()];p.exitRequested();
 assert.equal(p.exits,1);assert.equal(p.disposed,false);assert.equal(p.leaving,true);assert.equal(timers.size,0);
 resolve(raw);await pending;stale.forEach(fn=>fn());
 assert.equal(p.loaded,false);assert.equal(writes,0);assert.equal(p.loadFeedback,'');assert.equal(p.engine.serialize(),raw);
});
await test('background-cancelled first-board preparation never saves the constructor fallback',async()=>{
 const p=controller();p.loaded=false;let resolve,writes=0;
 p.storage.load=async()=>'';p.progress.flush=async()=>{writes++;return true;};
 p.preparation={prepare:()=>new Promise(r=>resolve=r),cancel(){resolve?.(undefined);}};
 const pending=p.boot();await new Promise(r=>setImmediate(r));p.backgrounded();await pending;
 assert.equal(p.loaded,false);assert.equal(writes,0);assert.equal(p.dialog,'more');assert.equal(timers.size,0);
 p.preparation.prepare=async()=>puzzle(99);p.dialogAction('close');await new Promise(r=>setImmediate(r));
 assert.equal(p.loaded,true);assert.equal(p.engine.round.seed,99);assert.equal(p.dialog,'');
});
await test('restored round-end panels and storage errors remain visible until acted on',async()=>{
 const p=controller();for(const cell of core.starFallback('easy').path)p.engine.pop(cell);
 const raw=p.engine.serialize();assert.equal(p.engine.round.status,'stageEnd');
 p.loaded=false;p.storage.load=async()=>raw;await p.boot();assert.equal(p.dialog,'stageEnd');
 assert.equal(p.loadFeedback,'');assert.equal(timers.size,0);
});
await test('disappearance cancels pending feedback and animation, then releases profiling',async()=>{
 const p=controller();let released=0,resolve;p.perf.release=()=>released++;
 p.loaded=false;p.storage.load=()=>new Promise(r=>resolve=r);const pending=p.boot(),stale=[...timers.values()];
 p.aboutToDisappear();resolve(p.engine.serialize());await pending;stale.forEach(fn=>fn());
 assert.equal(released,1);assert.equal(p.loaded,false);assert.equal(p.loadFeedback,'');assert.equal(timers.size,0);
});
await test('incremental generation yields, cancels and returns only verified puzzles',async()=>{
 timers.clear();const p=new rt.StarPreparation();let finished=false;const timings=[];
 const preparing=p.prepare('easy',8,t=>timings.push(t)).then(result=>{finished=true;return result;});assert.equal(finished,false);assert.equal(timers.size,1);
 const ticks=drain();assert.ok(ticks>10);const result=await preparing;assert.ok(core.starVerifyPuzzle(result,'easy'));assert.equal(timers.size,0);
 assert.equal(timings.length,1);assert.equal(timings[0].slices,ticks);assert.equal(timings[0].cancelled,false);assert.ok(timings[0].peak<=timings[0].compute);
 const aborted=p.prepare('classic',9,t=>timings.push(t));const stale=[...timers.values()];p.cancel();assert.equal(await aborted,undefined);stale.forEach(fn=>fn());assert.equal(timers.size,0);
 assert.equal(timings.length,2);assert.equal(timings[1].cancelled,true);
});
await test('home preserves the Star Pop order and appends Ten Garden while Tangram stays hidden',()=>{
 const hub=main('pages/HubPage.ets');const source=['shell/GameModule.ets','shell/GameRegistry.ets'].map(main).join('\n')+'\n'+
  ['HOME_GAME_ORDER','HIDDEN_HOME_GAME_IDS'].map(n=>hub.match(new RegExp('const '+n+': string\\[\\] = \\[[\\s\\S]*?\\];'))[0]).join('\n')+
  '\nclass Hub {\n'+method(hub,'homeModules')+'\n}';
 const h=vm.runInNewContext(ts(source)+'\n({Hub,gameLogoPath})');const ids=Array.from(new h.Hub().homeModules(),g=>g.id);
 assert.deepEqual(ids,['suikaNext','minesweeperNext','tetrisNext','chicken2048Next','freecellNext','rpsBattleNext','bloomLines','memoryPairs','starPop','tenGarden']);
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
