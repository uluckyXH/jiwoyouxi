#!/usr/bin/env node
// Run the actual ArkTS engine, pointer controller, page lifecycle and achievement gateway; no emulator.
import assert from 'node:assert/strict';
import {readFileSync,existsSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
const root=new URL('../',import.meta.url);
const read=p=>readFileSync(new URL(p,root),'utf8');
const main=p=>read('entry/src/main/ets/'+p);
const plain=v=>JSON.parse(JSON.stringify(v));
const clean=s=>s.replace(/^import[\s\S]*?;\s*$/gm,'').replace(/^export default /gm,'').replace(/^export /gm,'')
 .replace(/^@Observed\s*$/gm,'').replace(/@Track\s+/g,'');
const compile=s=>stripTypeScriptTypes(clean(s),{mode:'transform'});
const source=['TenModel','TenPuzzles','TenRules','TenEngine','TenLayout','TenGesture','TenProgress','TenRenderTile'].map(n=>main('gamesNext/tenGarden/'+n+'.ets')).join('\n');
const names='TenEngine,TenProgress,TenGesture,TenRenderTile,tenReconcileTiles,tenLayout,tenViewport,tenHit,tenSelect,tenValidPath,tenHasMove,tenSum,tenProfile,tenShift,tenPuzzle,TEN_PUZZLES';
const core=vm.runInNewContext(compile(source)+'\n({'+names+'})',{});
let count=0;
async function test(name,run){await run();count++;console.log('PASS '+name);}
vm.runInNewContext(compile(source+'\n'+read('entry/src/ohosTest/ets/test/TenGarden.test.ets'))+'\ntenGardenTest();',{
 describe:(_n,fn)=>fn(),it:(name,_kind,fn)=>{fn();count++;console.log('PASS '+name);},
 expect:value=>({assertEqual:expected=>assert.equal(value,expected)}),TestType:{FUNCTION:1},Size:{SMALLTEST:1},Level:{LEVEL0:1}
});
function solve(e){for(const step of e.puzzle.solution.slice(e.round.history.length))assert.ok(e.submit(step.cells));}
function paths(e){const found=[];function walk(path,sum){if(sum===10){found.push(path);return;}
 const last=path.at(-1);for(const next of [last-e.puzzle.size,last+1,last+e.puzzle.size,last-1]){
  if(next<0||next>=e.round.board.length||!e.round.board[next]||path.includes(next))continue;
  if(Math.abs(last%e.puzzle.size-next%e.puzzle.size)+Math.abs(Math.floor(last/e.puzzle.size)-Math.floor(next/e.puzzle.size))!==1)continue;
  if(sum+e.round.board[next]<=10)walk([...path,next],sum+e.round.board[next]);
 }}
 for(let i=0;i<e.round.board.length;i++)if(e.round.board[i])walk([i],e.round.board[i]);return found;
}
await test('257 boards replay through every intermediate save, preserving IDs, mass and non-refill invariants',()=>{
 assert.equal(core.TEN_PUZZLES.length,64);assert.equal(new Set(core.TEN_PUZZLES.map(p=>p.values.join(','))).size,64);
 let states=0;
 for(let stage=1;stage<=257;stage++){
  const e=new core.TenEngine(stage);
  for(const step of e.puzzle.solution){
   const sum=e.round.board.reduce((a,b)=>a+b,0), ids=e.round.ids.filter(Boolean), values=e.round.board.filter(Boolean).length;
   assert.ok(e.submit(step.cells));assert.equal(e.round.board.reduce((a,b)=>a+b,0),sum-10);
   assert.equal(e.round.board.filter(Boolean).length,values-step.cells.length);
   assert.ok(e.round.ids.filter(Boolean).every(id=>ids.includes(id)));
   assert.equal(new Set(e.round.ids.filter(Boolean)).size,e.round.ids.filter(Boolean).length);
   const restored=new core.TenEngine();assert.ok(restored.restore(e.serialize()));assert.equal(restored.serialize(),e.serialize());states++;
  }
  const raw=e.serialize();assert.equal(e.rewind(),false);assert.equal(e.restart(),false);assert.equal(e.serialize(),raw);
  e.round.reported=true;assert.ok(e.next());assert.equal(core.tenProfile(e.round).totalWins,stage);
 }
 assert.deepEqual(plain(core.tenPuzzle(2)),plain(core.tenPuzzle(258)));
 console.log('  verified saved states: '+states+'; orientations: 256 plus intro');
});
await test('malformed and forged saves fail atomically without replacing the playable round',()=>{
 const e=new core.TenEngine(2);e.submit(e.puzzle.solution[0].cells);const raw=e.serialize();
 const mutations=[s=>s.version=2,s=>s.round.stage=0,s=>s.round.stage=1.5,s=>s.round.stage=1e9,
  s=>s.round.id='',s=>s.round.history[0].cells=[0,0],s=>s.round.credited=0,s=>s.round.credited=13,
  s=>s.round.ids[0]=999,s=>s.round.board[0]=999,s=>s.round.phase='complete',s=>s.round.reported=true,
  s=>s.round.hints=-1,s=>s.round.undos=NaN,s=>s.profile.totalGroups++,s=>s.profile.totalWins++,s=>s.profile.totalChallenges++,
  s=>delete s.round,s=>s.round.history=[null],s=>s.round.board='no',s=>s.profile=null];
 for(const change of mutations){const save=JSON.parse(raw);change(save);assert.equal(e.restore(JSON.stringify(save)),false);assert.equal(e.serialize(),raw);}
 for(const bad of ['null','[]','false','{','{}']){assert.equal(e.restore(bad),false);assert.equal(e.serialize(),raw);}
});
await test('move availability agrees with an independent enumeration, including disconnected endgames',()=>{
 let seed=0x191024,deadEnds=0,states=0;
 const random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed;};
 for(let stage=1;stage<=257;stage++){
  const e=new core.TenEngine(stage);
  while(e.round.phase==='playing'){
   const choices=paths(e),raw=e.serialize();
   assert.equal(e.hasMove(),choices.length>0);assert.equal(e.serialize(),raw);states++;
   if(choices.length===0){
    deadEnds++;const hint=e.hint();assert.ok(hint&&hint.rewind>0);
    assert.ok(e.rewind());assert.ok(e.hasMove(),'undo returns to the preceding playable board');
    assert.ok(e.restore(raw));assert.ok(e.applyHint(hint));assert.ok(e.hasMove());
    while(e.round.phase==='playing'){const h=e.hint();assert.ok(h&&h.rewind===0);assert.ok(e.applyHint(h));assert.ok(e.submit(h.path));}
    break;
   }
   assert.ok(e.submit(choices[random()%choices.length]));
  }
 }
 assert.ok(deadEnds>100);console.log(`  checked ${states} board states and ${deadEnds} recoverable dead ends`);
});
await test('review saves validate both boards, retain older v1 saves and reject forged progress atomically',()=>{
 const e=new core.TenEngine(4);e.submit(e.puzzle.solution[0].cells);const primary=e.serialize();
 e.previous();e.submit(e.puzzle.solution[0].cells);const reviewing=e.serialize();
 const restored=new core.TenEngine();assert.ok(restored.restore(reviewing));assert.equal(restored.serialize(),reviewing);
 assert.equal(restored.resumeStage(),4);
 for(const mutate of [s=>s.resumeRound=null,s=>s.resumeRound.board[0]=99,s=>s.resumeRound.stage=s.round.stage,
  s=>s.resumeRound.history[0].cells=[-1,999],s=>s.resumeRound.id=s.round.id,s=>s.profile.totalGroups++,
  s=>s.round.stage=5,s=>delete s.resumeRound]){
  const forged=JSON.parse(reviewing);mutate(forged);assert.equal(restored.restore(JSON.stringify(forged)),false);
  assert.equal(restored.serialize(),reviewing);
 }
 assert.ok(restored.restore(primary));assert.equal(restored.resumeStage(),0);assert.equal(restored.serialize(),primary);
});
await test('retained tile views follow all four winds and undo across every certified board',()=>{
 let moved=0;
 for(let stage=1;stage<=257;stage++){
  const e=new core.TenEngine(stage);let views=core.tenReconcileTiles([],e.tiles());
  function reconcile(){
   const retained=new Map(views.map(tile=>[tile.id,tile]));
   const positions=new Map(views.map(tile=>[tile.id,tile.index]));
   views=core.tenReconcileTiles(views,e.tiles());
   assert.deepEqual(plain(views),plain(e.tiles()));
   for(const view of views){
    if(retained.has(view.id)){
     assert.equal(view,retained.get(view.id),'ForEach must keep the same observable object');
     if(positions.get(view.id)!==view.index)moved++;
    }
    assert.equal(e.round.board[view.index],view.value);
    assert.equal(e.round.ids[view.index],view.id);
   }
  }
  for(const step of e.puzzle.solution){
   assert.ok(e.submit(step.cells));reconcile();
   if(e.round.phase==='playing'){assert.ok(e.rewind());reconcile();assert.ok(e.submit(step.cells));reconcile();}
  }
  assert.equal(views.length,0);
 }
 assert.ok(moved>10000);console.log('  verified retained-view position changes: '+moved);
});
await test('alternate legal routes can return to a certified state; hints declare rewind and never auto-clear',()=>{
 let rewinds=0;
 for(let stage=2;stage<34;stage++){
  const e=new core.TenEngine(stage), alternate=paths(e).find(p=>p.join(',')!==e.puzzle.solution[0].cells.join(','));
  assert.ok(alternate);e.submit(alternate);const hint=e.hint();assert.ok(hint);
  const before=e.round.history.length,credit=e.round.credited;rewinds+=hint.rewind;
  assert.ok(e.applyHint(hint));assert.equal(e.round.history.length,before-hint.rewind);
  assert.equal(e.round.credited,credit);assert.ok(core.tenValidPath(e.round.board,hint.path,6));
  assert.ok(e.submit(hint.path));assert.equal(core.tenProfile(e.round).totalGroups,2+(stage-2)*12+e.round.credited);
  while(e.round.phase==='playing'){const h=e.hint();assert.ok(e.applyHint(h));assert.ok(e.submit(h.path));}
 }
 assert.ok(rewinds>0);
 const e=new core.TenEngine();assert.equal(e.applyHint({rewind:2,path:[3,4]}),false);
});
await test('every certified hint and 1028 seeded off-route games point to existing adjacent numbers totalling ten',()=>{
 let certified=0,branchHints=0,rewinds=0,seed=0x10c0ffee;
 const random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed;};
 function validate(e){
  const raw=e.serialize(),hint=e.hint();assert.ok(hint);assert.equal(e.serialize(),raw,'requesting a hint never changes the board');
  const depth=e.round.history.length,credit=e.round.credited,undos=e.round.undos;
  assert.ok(Number.isInteger(hint.rewind)&&hint.rewind>=0&&hint.rewind<=depth);
  for(const bad of [{rewind:hint.rewind+1,path:hint.path},{rewind:hint.rewind,path:[-1,999]},
    {rewind:hint.rewind,path:[hint.path[0],hint.path[0]]}]){
   assert.equal(e.applyHint(bad),false);assert.equal(e.serialize(),raw,'a stale or invalid hint is atomic');
  }
  const restored=new core.TenEngine();assert.ok(restored.restore(raw));
  assert.deepEqual(plain(restored.hint()),plain(hint),'restoring cannot change the promised route');
  assert.ok(restored.applyHint(hint));assert.equal(restored.round.history.length,depth-hint.rewind);
  assert.equal(restored.round.credited,credit);assert.equal(restored.round.undos,undos+hint.rewind);
  assert.ok(core.tenValidPath(restored.round.board,hint.path,restored.puzzle.size));
  assert.equal(core.tenSum(restored.round.board,hint.path),10);
  const views=core.tenReconcileTiles(core.tenReconcileTiles([],e.tiles()),restored.tiles());
  for(const i of hint.path){
   assert.ok(restored.round.board[i]>0&&restored.round.ids[i]>0);
   const tile=views.find(t=>t.index===i);assert.ok(tile);assert.equal(tile.value,restored.round.board[i]);
  }
  rewinds+=hint.rewind>0?1:0;return {restored,hint};
 }
 for(let stage=1;stage<=257;stage++){
  const reference=new core.TenEngine(stage);
  for(const step of reference.puzzle.solution){
   const {hint}=validate(reference);assert.equal(hint.rewind,0);certified++;
   assert.ok(reference.submit(step.cells));
  }
  assert.equal(reference.hint(),undefined);
  for(let trial=0;trial<4;trial++){
   const e=new core.TenEngine(stage),depth=1+random()%11;
   for(let i=0;i<depth&&e.round.phase==='playing';i++){
    const choices=paths(e);if(choices.length===0)break;
    assert.ok(e.submit(choices[random()%choices.length]));
    if(e.round.phase==='playing'&&random()%5===0)e.rewind();
   }
   if(e.round.phase==='complete'){assert.equal(e.hint(),undefined);continue;}
   const {restored,hint}=validate(e);branchHints++;assert.ok(restored.submit(hint.path));
   let guard=0;
   while(restored.round.phase==='playing'){
    const next=restored.hint();assert.ok(next);assert.equal(next.rewind,0);
    assert.ok(restored.applyHint(next));assert.ok(restored.submit(next.path));assert.ok(++guard<=12);
   }
  }
 }
 assert.equal(certified,3074);assert.ok(branchHints>1000);assert.ok(rewinds>500);
 console.log(`  hint audit: ${certified} certified states, ${branchHints} off-route states, ${rewinds} confirmed rewinds`);
});
await test('pointer sampling handles fast swipes, partial-path backtracking and cancellation',()=>{
 const board=[1,2,3,4],g=new core.TenGesture();
 g.begin(25,25,[],2,106,6);g.move(81,25,board,2,106,6);g.move(81,81,board,2,106,6);
 const end=g.end(25,81,board,2,106,6);assert.equal(end.commit,true);assert.deepEqual(plain(end.path),[0,1,3,2]);
 assert.equal(g.end(25,81,board,2,106,6).commit,false);
 g.begin(25,25,[3],2,106,6);g.move(81,25,board,2,106,6);assert.deepEqual(plain(g.cancel()),[3]);
 const intro=core.tenPuzzle(1).values;
 g.begin(50,250,[],3,306,6);const fast=g.end(256,250,intro,3,306,6);
 assert.deepEqual(plain(fast.path),[6,7,8]);assert.ok(fast.commit);
 g.begin(50,250,[],3,306,6);g.move(150,250,intro,3,306,6);
 assert.deepEqual(plain(g.move(50,250,intro,3,306,6)),[6]);
 g.begin(50,150,[],3,306,6);assert.deepEqual(plain(g.end(50,150,intro,3,306,6)),{path:[3],commit:false});
 g.begin(150,150,[3],3,306,6);assert.deepEqual(plain(g.end(150,150,intro,3,306,6)),{path:[3,4],commit:false});
});
await test('layout matrix keeps native controls separate, covers readable phones and adapts every hinge independently',()=>{
 let layouts=0;
 for(const w of [200,280,320,360,377.1,390,430,600,800,960,1280,1800])for(const h of [240,360,568,780,844,900,1200])for(const size of [3,6]){
  const l=core.tenLayout(w,h,{top:52,bottom:34,left:0,right:0},[],size), boxes=['board','stats','selection','tools','note'].map(k=>l[k]);layouts++;
  for(const box of boxes){assert.ok(box.x>=-1e-8&&box.y>=0);assert.ok(box.x+box.width<=l.contentWidth+1e-8);assert.ok(box.y+box.height<=l.contentHeight+1e-8);}
  for(let i=0;i<boxes.length;i++)for(let j=i+1;j<boxes.length;j++){
   const a=boxes[i],b=boxes[j];assert.ok(Math.min(a.x+a.width,b.x+b.width)-Math.max(a.x,b.x)<1e-7||Math.min(a.y+a.height,b.y+b.height)-Math.max(a.y,b.y)<1e-7);
  }
  assert.ok(l.cell+l.tileGap>=44);assert.equal(l.tools.height,l.wide?64:48);
  if(w>=320&&w<=430&&h>=780)assert.ok(l.contentHeight<=l.body,`${w}/${h}: controls fit`);
  for(let i=0;i<size*size;i++){
   const x=(i%size+.5)*(l.cell+l.tileGap)-l.tileGap/2,y=(Math.floor(i/size)+.5)*(l.cell+l.tileGap)-l.tileGap/2;
   assert.equal(core.tenHit(x,y,l.grid,size,l.tileGap),i);
  }
 }
 const safe={top:24,bottom:24,left:0,right:0};
 for(const hinges of [[{x:390,y:0,width:20,height:844}],[{x:390,y:0,width:20,height:844},{x:790,y:0,width:20,height:844}]]){
  const folded=core.tenLayout(hinges.length===1?800:1200,844,safe,hinges),phone=core.tenLayout(390,844,safe);
  assert.equal(folded.grid,phone.grid);assert.equal(folded.wide,false);
 }
 assert.equal(core.tenViewport(800,1200,safe,[{x:0,y:590,width:800,height:20}]).height,566);
 for(const [x,y] of [[-1,0],[1,999],[NaN,0],[Infinity,2]])assert.equal(core.tenHit(x,y,300,6,6),-1);
 console.log('  verified layouts: '+layouts);
});
function method(source,name){const start=source.search(new RegExp('^  (?:private )?(?:async )?'+name+'\\(','m'));assert.ok(start>=0,name);return source.slice(start,source.indexOf('\n  }',start)+4);}
const appFiles=['shell/AchievementModule.ets','shell/GameModule.ets','shell/AchievementRegistry.ets','shell/AchievementEngine.ets','shell/AchievementNotice.ets','shell/AchievementFavoriteEvent.ets','app/AchievementService.ets'];
let durable,failAchievements=false;
const api=vm.runInNewContext(compile(appFiles.map(main).join('\n')+'\nclass Gateway {\n'+method(main('pages/Index.ets'),'reportAchievementEvent')+'\n}')+
 '\n({Gateway,AchievementService,emptyAchievementState,achievementGroupsForState,achievementNoticeItemsForUnlocks,achievementProgressForState,favoriteAchievementEventForSnapshot,ACHIEVEMENT_DEFINITIONS,achievementRegistryIssues})',{
 console,CoopStorage:{async loadAchievementState(){return plain(durable);},async saveAchievementState(_ctx,state){if(failAchievements)return false;durable=plain(state);return true;}}
});
function gateway(){durable=plain(api.emptyAchievementState());failAchievements=false;const g=new api.Gateway();Object.assign(g,{appContext:{},activeGame:'tenGarden',achievementService:new api.AchievementService(),notices:[]});g.enqueueAchievementNotices=result=>g.notices.push(...api.achievementNoticeItemsForUnlocks(result.newlyUnlocked));return g;}
function bridge(e,g=gateway()){
 const s={raw:'',failSave:false,failAck:false,records:[],reports:[],writes:[]};
 const p=new core.TenProgress(e,{
  async save(raw){if(s.failSave||s.failAck&&JSON.parse(raw).round.reported)return false;s.raw=raw;s.writes.push(raw);return true;},
  async report(event){assert.ok(s.raw.length>0);s.reports.push(plain(event));return g.reportAchievementEvent(event);},record:n=>s.records.push(n)
 });return {p,s,g};
}
const unlocked=id=>durable.progresses.some(p=>p.achievementId===id&&p.unlockedAt>0);
await test('real moves → save → Index → wall unlock all three medals; only final clears count completed games',async()=>{
 const e=new core.TenEngine(),{p,s}=bridge(e);await p.flush();assert.equal(unlocked('tenGarden.first'),false);
 for(const step of e.puzzle.solution){assert.ok(e.submit(step.cells));await p.flush();}
 assert.ok(unlocked('tenGarden.first'));assert.ok(unlocked('tenGarden.clear'));assert.equal(unlocked('tenGarden.collector'),false);
 assert.equal(durable.completedSessionCount,1);assert.ok(unlocked('global.first_settlement'));assert.ok(e.next());await p.flush();
 for(let i=0;i<e.puzzle.solution.length;i++){assert.ok(e.submit(e.puzzle.solution[i].cells));await p.flush();assert.equal(unlocked('tenGarden.collector'),i>=9);}
 assert.deepEqual(s.records,[1,2]);assert.equal(durable.completedSessionCount,2);
 const groups=plain(api.achievementGroupsForState(durable,'all'));assert.equal(groups.at(-1).definition.id,'tenGarden');
 assert.equal(groups.at(-1).items.length,3);assert.ok(groups.at(-1).items.every(i=>i.status==='unlocked'));
 assert.deepEqual(plain(api.achievementRegistryIssues()),[]);
 for(const d of api.ACHIEVEMENT_DEFINITIONS.filter(d=>d.gameId==='tenGarden'))assert.ok(existsSync(new URL('entry/src/main/resources/rawfile/'+d.badgeAssetPath,root)));
});
await test('save failure never grants achievements; retries and queued stale settlements are idempotent',async()=>{
 const e=new core.TenEngine(),{p,s,g}=bridge(e);e.submit([3,4]);s.failSave=true;
 assert.equal(await p.flush(),false);assert.equal(s.reports.length,0);assert.equal(g.notices.length,0);
 s.failSave=false;assert.ok(await p.flush());e.rewind();await p.flush();e.submit([3,4]);await p.flush();
 assert.equal(g.notices.filter(n=>n.achievementIds.includes('tenGarden.first')).length,1);
 e.submit([6,7,8]);await Promise.all([p.flush(),p.flush(),p.flush()]);
 assert.equal(durable.completedSessionCount,1);assert.deepEqual(s.records,[1]);assert.ok(e.round.reported);
});
await test('achievement persistence and completion acknowledgement failures survive reload without double awards',async()=>{
 const e=new core.TenEngine(),{p,s,g}=bridge(e);e.submit([3,4]);failAchievements=true;
 assert.equal(await p.flush(),false);assert.equal(unlocked('tenGarden.first'),false);
 const restored=new core.TenEngine();assert.ok(restored.restore(s.raw));failAchievements=false;const retry=bridge(restored,g);
 assert.ok(await retry.p.flush());assert.ok(unlocked('tenGarden.first'));
 restored.submit([6,7,8]);retry.s.failAck=true;assert.equal(await retry.p.flush(),false);assert.equal(restored.next(),false);
 assert.equal(durable.completedSessionCount,1);const loaded=new core.TenEngine();assert.ok(loaded.restore(retry.s.raw));
 const again=bridge(loaded,g);assert.ok(await again.p.flush());assert.equal(durable.completedSessionCount,1);assert.ok(loaded.next());
});
await test('reviewing cleared stages persists both games without duplicate milestones, wins or notices',async()=>{
 const e=new core.TenEngine(),{p,s,g}=bridge(e);solve(e);await p.flush();assert.ok(e.next());
 e.submit(e.puzzle.solution[0].cells);await p.flush();
 const primary=e.serialize(),reports=s.reports.length,notices=g.notices.length,profile=plain(e.profile());
 assert.ok(e.previous());await p.flush();solve(e);await p.flush();
 assert.deepEqual(plain(e.profile()),profile);assert.equal(s.reports.length,reports);assert.equal(g.notices.length,notices);
 assert.equal(durable.completedSessionCount,1);assert.deepEqual(s.records,[1]);
 const loaded=new core.TenEngine();assert.ok(loaded.restore(s.raw));const resumed=bridge(loaded,g);
 assert.ok(loaded.next());assert.equal(loaded.serialize(),primary);assert.ok(loaded.rewind());await resumed.p.flush();
 assert.equal(durable.completedSessionCount,1);solve(loaded);await resumed.p.flush();
 assert.equal(durable.completedSessionCount,2);assert.ok(loaded.round.reported);
});
await test('ten clears count globally, original-six condition remains stable, and home/wall order only appends',async()=>{
 const e=new core.TenEngine(),{p,g}=bridge(e);
 for(let i=0;i<10;i++){solve(e);await p.flush();e.next();}
 assert.equal(durable.completedSessionCount,10);assert.ok(unlocked('global.complete_ten_sessions'));assert.equal(unlocked('global.play_six_games'),false);
 await g.reportAchievementEvent(api.favoriteAchievementEventForSnapshot(['tenGarden','starPop','memoryPairs'],Date.now()));assert.ok(unlocked('global.favorite_three'));
 const hub=main('pages/HubPage.ets'),order=hub.match(/const HOME_GAME_ORDER: string\[\] = \[([\s\S]*?)\];/)[1].match(/'[^']+'/g).map(s=>s.slice(1,-1));
 assert.deepEqual(order,['suikaNext','minesweeperNext','tetrisNext','chicken2048Next','freecellNext','rpsBattleNext','tangram','bloomLines','memoryPairs','starPop','tenGarden']);
 const registry=vm.runInNewContext(compile(main('shell/GameRegistry.ets'))+'\n({GAME_MODULES,gameLogoPath})',{});
 assert.equal(registry.GAME_MODULES.at(-1).id,'tenGarden');assert.equal(registry.gameLogoPath('tenGarden'),'gamesNext/tenGarden/scene/logo.svg');
 const groups=plain(api.achievementGroupsForState(api.emptyAchievementState(),'all')).map(g=>g.definition.id);
 assert.deepEqual(groups.slice(-4),['bloomLines','memoryPairs','starPop','tenGarden']);assert.equal(groups[0],'global');
});
const pageText=main('gamesNext/tenGarden/TenPage.ets');
const pageNames=['boot','active','setSelection','tap','collectIfReady','touch','cancelGesture','collect','undo','hint','showHint','sync','cancelAnimation','animateBoard','advance','changeStage','present','closeDialog','confirmDialog','relayout','backgrounded','exitRequested','save','retrySave','saveAndExit','aboutToDisappear'];
const timers=new Map(),frames=[];let seq=0;
const touchTypes={Down:0,Up:1,Move:2,Cancel:3};
const pageApi=vm.runInNewContext(compile(source+'\nclass Page {\n'+pageNames.map(n=>method(pageText,n)).join('\n')+'\n}')+'\n({Page})',{
 console,setTimeout:fn=>{const id=++seq;timers.set(id,fn);return id;},clearTimeout:id=>timers.delete(id),Curve:{EaseOut:0},TouchType:touchTypes,
 TenReflow:class{constructor(fn){this.fn=fn;}}
});
const tick=()=>new Promise(resolve=>setImmediate(resolve));
function controller(e=new core.TenEngine()){
 timers.clear();frames.length=0;const p=new pageApi.Page(),b=bridge(e),sounds=[];
 Object.assign(p,{engine:e,progress:b.p,context:{},pointerInput:new core.TenGesture(),pointer:-1,gestureCommitted:false,pendingHint:undefined,
  loaded:true,loading:false,disposed:false,skipSave:false,backgroundPaused:false,backgroundGeneration:0,timer:-1,generation:0,saveSequence:0,layoutGeneration:0,
  returnDialog:'',dialog:'',saving:false,saveFailed:false,animating:false,touching:false,selected:[],hintCells:[],receipt:'',tiles:[],
  pageWidth:390,pageHeight:844,insets:{top:24,bottom:24,left:0,right:0},creases:[],layout:core.tenLayout(390,844,{top:24,bottom:24,left:0,right:0},[],e.puzzle.size),
  audio:{play:n=>sounds.push(n),silence(){},release(){}},host:{release(){}},storage:{load:async()=>b.s.raw,save:async(_ctx,raw)=>{b.s.raw=raw;return true;}},
  reportAchievementEvent:ev=>b.g.reportAchievementEvent(ev),recordScore:n=>b.s.records.push(n),
  verticalScroll:{scrollTo:o=>{p.scrollReset=o;}},horizontalScroll:{scrollTo:o=>{p.scrollReset=o;}},
  getUIContext:()=>({postFrameCallback:f=>frames.push(f),animateTo:(_options,action)=>action()}),exitToHub:()=>{p.left=true;}
 });p.sync();return {...b,p,e,sounds};
}
function fire(){const entry=timers.entries().next().value;if(entry){const [id,fn]=entry;timers.delete(id);fn();}}
function pointer(p,type,index){
 const x=index%p.gridSize*(p.layout.cell+p.layout.tileGap)+p.layout.cell/2;
 const y=Math.floor(index/p.gridSize)*(p.layout.cell+p.layout.tileGap)+p.layout.cell/2;
 const point={id:1,x,y};p.touch({type,touches:type===touchTypes.Up?[]:[point],changedTouches:[point]});
}
await test('after compaction, visible numbers, selected cells and the calculated sum agree through rewind and restore',async()=>{
 const {p,e}=controller(new core.TenEngine(2));const initialHandles=new Map(p.tiles.map(tile=>[tile.id,tile]));
 for(const step of e.puzzle.solution.slice(0,2)){for(const cell of step.cells)p.tap(cell);fire();}
 const moving=initialHandles.get(3);assert.equal(p.tiles.find(t=>t.id===3),moving);assert.equal(moving.index,0);
 function selectVisiblePair(){
  const seven=p.tiles.find(a=>a.value===7&&p.tiles.some(b=>b.value===1&&Math.abs(a.index%6-b.index%6)+Math.abs(Math.floor(a.index/6)-Math.floor(b.index/6))===1));
  assert.ok(seven);const one=p.tiles.find(b=>b.value===1&&Math.abs(seven.index%6-b.index%6)+Math.abs(Math.floor(seven.index/6)-Math.floor(b.index/6))===1);
  p.setSelection([]);p.tap(seven.index);p.tap(one.index);
  assert.deepEqual(plain(p.selected.map(i=>p.round.board[i])),[7,1]);assert.equal(core.tenSum(p.round.board,p.selected),8);
  assert.deepEqual(plain(p.selected.map(i=>p.tiles.find(t=>t.index===i).value)),[7,1]);
 }
 selectVisiblePair();p.undo();fire();selectVisiblePair();
 p.selected=[];const raw=e.serialize();assert.ok(e.restore(raw));p.sync();selectVisiblePair();
 p.pageWidth=1280;p.pageHeight=900;p.relayout();selectVisiblePair();
 p.present('restart');p.confirmDialog();assert.deepEqual(plain(p.tiles),plain(e.tiles()));
 await tick();
});
await test('tile and pointer taps automatically collect exactly ten; invalid picks and undo never duplicate awards',async()=>{
 const {p,e,g,sounds}=controller();p.tap(4);p.tap(7);
 assert.deepEqual(plain(p.selected),[4]);assert.equal(e.round.history.length,0);
 p.tap(4);p.tap(3);assert.equal(e.round.history.length,0);p.tap(4);
 assert.equal(e.round.history.length,1);assert.equal(p.receipt,'2 + 8');assert.equal(p.selected.length,0);
 p.tap(6);p.tap(7);p.tap(8);assert.equal(e.round.history.length,1);
 await tick();assert.equal(g.notices.filter(n=>n.achievementIds.includes('tenGarden.first')).length,1);
 fire();p.undo();fire();
 pointer(p,touchTypes.Down,3);pointer(p,touchTypes.Up,3);assert.equal(e.round.history.length,0);
 pointer(p,touchTypes.Down,4);pointer(p,touchTypes.Up,4);
 assert.equal(e.round.history.length,1);assert.equal(e.round.credited,1);assert.equal(p.pointer,-1);
 await tick();assert.equal(g.notices.filter(n=>n.achievementIds.includes('tenGarden.first')).length,1);
 assert.equal(sounds.filter(n=>n==='collect').length,2);
});
await test('drag collects before lifting and consumes that gesture through animation; hints only mark a route',async()=>{
 const {p,e}=controller();p.hint();assert.deepEqual(plain(p.hintCells),[3,4]);
 assert.equal(p.selected.length,0);assert.equal(e.round.history.length,0);
 pointer(p,touchTypes.Down,3);pointer(p,touchTypes.Move,4);
 assert.equal(e.round.history.length,1);assert.equal(p.hintCells.length,0);assert.equal(p.gestureCommitted,true);
 fire();assert.equal(p.active(),false);assert.equal(p.touching,true);
 pointer(p,touchTypes.Move,6);pointer(p,touchTypes.Move,8);p.tap(6);p.hint();p.undo();
 assert.equal(e.round.history.length,1);assert.equal(p.selected.length,0);
 pointer(p,touchTypes.Up,8);assert.equal(p.touching,false);assert.equal(p.gestureCommitted,false);assert.equal(p.active(),true);
 p.hint();assert.deepEqual(plain(p.hintCells),[6,7,8]);assert.equal(e.round.history.length,1);
 pointer(p,touchTypes.Down,6);pointer(p,touchTypes.Move,8);
 assert.equal(e.round.phase,'complete');assert.equal(e.round.history.length,2);assert.equal(p.receipt,'3 + 4 + 3');
 pointer(p,touchTypes.Up,8);fire();await tick();assert.equal(p.dialog,'complete');assert.equal(durable.completedSessionCount,1);
});
await test('a fresh touch recovers a lost release without carrying old cell indices into a new gesture',()=>{
 const {p,e}=controller();pointer(p,touchTypes.Down,3);pointer(p,touchTypes.Move,4);fire();
 assert.equal(p.active(),false);assert.equal(p.gestureCommitted,true);
 pointer(p,touchTypes.Down,6);pointer(p,touchTypes.Up,6);
 assert.equal(p.active(),true);assert.equal(p.gestureCommitted,false);assert.deepEqual(plain(p.selected),[6]);
 assert.equal(e.round.history.length,1);p.undo();fire();assert.equal(e.round.history.length,0);
});
await test('a dead-end page exposes recovery; undo, a confirmed hint and restart all remain usable',async()=>{
 const e=new core.TenEngine(2);
 while(e.hasMove()){assert.ok(e.submit(paths(e)[0]));if(e.round.phase==='complete')break;}
 assert.equal(e.round.phase,'playing');assert.ok(e.round.history.length>0);
 const {p}=controller(e),raw=e.serialize(),depth=e.round.history.length;
 assert.equal(p.stuck,true);assert.equal(p.active(),true);
 p.undo();fire();assert.equal(p.stuck,false);assert.equal(e.round.history.length,depth-1);
 assert.ok(e.restore(raw));p.sync();p.hint();assert.equal(p.dialog,'hintRewind');
 assert.ok(p.rewind>0);p.confirmDialog();assert.equal(p.stuck,false);assert.ok(core.tenValidPath(e.round.board,p.hintCells,6));
 while(e.round.phase==='playing'){
  for(const cell of p.hintCells.slice())p.tap(cell);fire();
  if(e.round.phase==='playing')p.hint();
 }
 assert.equal(p.dialog,'complete');await tick();
 assert.ok(e.restore(raw));p.sync();p.present('restart');p.confirmDialog();
 assert.equal(p.stuck,false);assert.equal(e.round.history.length,0);assert.equal(p.active(),true);
});
await test('previous-stage confirmation preserves current progress, supports nested review and restores undo',async()=>{
 const {p,e}=controller(new core.TenEngine(4));
 for(const path of e.puzzle.solution.slice(0,2)){for(const i of path.cells)p.tap(i);fire();}
 const raw=e.serialize();p.present('previous');p.closeDialog();p.confirmDialog();await tick();assert.equal(e.serialize(),raw);
 p.present('previous');await p.changeStage(true);
 assert.equal(p.round.stage,3);assert.equal(p.resumeStage,4);assert.equal(p.selected.length,0);assert.equal(p.stuck,false);
 p.confirmDialog();await tick();assert.equal(p.round.stage,3,'late confirmation cannot go back twice');
 p.present('previous');await p.changeStage(true);assert.equal(p.round.stage,2);assert.equal(p.resumeStage,4);
 p.present('more');await p.changeStage(false);assert.equal(p.resumeStage,0);assert.equal(e.serialize(),raw);
 p.undo();fire();assert.equal(e.round.history.length,1);assert.equal(p.active(),true);
});
await test('stage navigation is cancelled by failed persistence, backgrounding or a dismissed prompt',async()=>{
 const {p,e,s}=controller(new core.TenEngine(2));const raw=e.serialize();
 s.failSave=true;p.present('previous');await p.changeStage(true);assert.equal(e.serialize(),raw);assert.equal(p.saveFailed,true);
 s.failSave=false;await p.retrySave();assert.equal(p.saveFailed,false);
 const pending=p.changeStage(true);p.backgrounded();await pending;
 assert.equal(e.serialize(),raw);assert.equal(p.dialog,'pause');assert.equal(p.saving,false);
 p.closeDialog();p.present('previous');p.closeDialog();await p.changeStage(true);assert.equal(e.serialize(),raw);
});
await test('returning from background allows stage review from the pause menu without losing the original board',async()=>{
 const {p,e}=controller(new core.TenEngine(2));
 for(const i of e.puzzle.solution[0].cells)p.tap(i);fire();const original=e.serialize();
 p.backgrounded();assert.equal(p.dialog,'pause');
 p.present('previous');await p.changeStage(true);
 assert.equal(p.round.stage,1,'the enabled previous-stage button in the pause menu must work');
 assert.equal(p.dialog,'pause');assert.equal(p.active(),false);
 const review=e.serialize(),interrupted=p.changeStage(false);p.backgrounded();await interrupted;
 assert.equal(e.serialize(),review,'a new background event must still cancel an in-flight navigation');
 await p.changeStage(false);assert.equal(e.serialize(),original);assert.equal(p.dialog,'pause');
 p.closeDialog();assert.equal(p.active(),true);
});
await test('finishing a review can resume a completed primary stage without hiding its next-stage dialog',async()=>{
 const {p,e}=controller(new core.TenEngine(2));solve(e);p.sync();await p.save();
 const raw=e.serialize();p.present('previous');await p.changeStage(true);assert.equal(p.resumeStage,2);
 solve(e);p.sync();p.dialog='complete';await p.advance();
 assert.equal(e.serialize(),raw);assert.equal(p.dialog,'complete');assert.equal(p.resumeStage,0);
 await p.advance();assert.equal(p.round.stage,3);assert.equal(p.dialog,'');assert.equal(p.active(),true);
});
await test('cancelling or folding after auto-collect keeps the committed board and discards old indices',async()=>{
 for(const cancel of ['cancel','fold']){
  const {p,e}=controller();p.tap(6);pointer(p,touchTypes.Down,3);pointer(p,touchTypes.Move,4);
  assert.equal(e.round.history.length,1);const board=plain(e.round.board),ids=plain(e.round.ids);
  if(cancel==='fold'){p.pageWidth=1280;p.pageHeight=900;p.relayout();}
  else p.touch({type:touchTypes.Cancel,touches:[],changedTouches:[]});
  assert.equal(p.pointer,-1);assert.equal(p.gestureCommitted,false);assert.equal(p.selected.length,0);
  assert.deepEqual(plain(e.round.board),board);assert.deepEqual(plain(e.round.ids),ids);
  pointer(p,touchTypes.Up,4);fire();await tick();assert.equal(e.round.history.length,1);assert.equal(e.round.credited,1);
 }
});
await test('real page blocks duplicate collects while moving; pause cancels stale animation without reverting engine',async()=>{
 const {p,e}=controller();p.tap(3);p.tap(4);const stale=[...timers.values()][0];p.collect();p.tap(6);
 assert.equal(e.round.history.length,1);assert.equal(p.selected.length,0);
 p.backgrounded();assert.equal(timers.size,0);stale();assert.equal(p.dialog,'pause');assert.equal(e.round.history.length,1);
 p.closeDialog();p.tap(6);p.tap(7);p.tap(8);await tick();fire();assert.equal(p.dialog,'complete');assert.equal(durable.completedSessionCount,1);
 await p.advance();assert.equal(e.round.stage,2);assert.equal(p.dialog,'');assert.ok(frames.length>0);
});
await test('fold and multi-touch cancel only transient selection; stale reflow cannot move a newer layout',()=>{
 const {p,e}=controller();p.tap(3);const raw=e.serialize(),original=plain(p.layout);
 const x=p.layout.cell/2,y=p.layout.cell*2.5+p.layout.tileGap*2;
 p.touch({type:0,touches:[{id:1,x,y}],changedTouches:[]});p.touch({type:2,touches:[{id:1,x:x+p.layout.cell,y}],changedTouches:[]});
 p.pageWidth=1280;p.pageHeight=900;p.relayout();assert.equal(p.touching,false);assert.deepEqual(plain(p.selected),[3]);assert.equal(e.serialize(),raw);
 const old=frames.at(-1);p.pageWidth=390;p.pageHeight=844;p.relayout();old.fn();assert.equal(p.scrollReset,undefined);
 frames.at(-1).fn();assert.equal(p.scrollReset.yOffset,0);assert.deepEqual(plain(p.layout),original);
 p.touch({type:0,touches:[{id:1,x,y}],changedTouches:[]});p.touch({type:0,touches:[{id:1,x,y},{id:2,x,y}],changedTouches:[]});
 assert.equal(p.pointer,-1);p.touch({type:1,touches:[],changedTouches:[{id:1,x,y}]});assert.equal(e.serialize(),raw);
});
await test('hint rewind confirmation, cancellation, undo and restart keep a single persistence queue',async()=>{
 const {p,e}=controller(new core.TenEngine(2));const other=paths(e).find(path=>path.join(',')!==e.puzzle.solution[0].cells.join(','));
 p.selected=other;p.collect();fire();p.hint();assert.equal(p.dialog,'hintRewind');const raw=e.serialize();
 p.closeDialog();assert.equal(e.serialize(),raw);p.hint();p.confirmDialog();assert.equal(p.dialog,'');assert.equal(e.round.history.length,0);
 assert.equal(p.selected.length,0);assert.equal(p.hintCells.length>1,true);
 for(const cell of p.hintCells.slice())p.tap(cell);
 assert.equal(e.round.history.length,1);assert.equal(p.hintCells.length,0);fire();p.undo();fire();await tick();const progress=p.progress,id=e.round.id;
 p.present('restart');p.confirmDialog();assert.equal(p.progress,progress);assert.equal(e.round.id,id);assert.equal(e.round.credited,1);await tick();
 assert.equal(JSON.parse(p.progress===progress?p.engine.serialize():'{}').round.history.length,0);
});
await test('hint confirmation can run only once; a dismissed prompt cannot reset the board',async()=>{
 const {p,e}=controller(new core.TenEngine(2));
 for(const i of e.puzzle.solution[0].cells)p.tap(i);fire();
 const other=paths(e).find(path=>path.join(',')!==e.puzzle.solution[1].cells.join(','));assert.ok(other);
 for(const i of other)p.tap(i);fire();p.hint();assert.equal(p.dialog,'hintRewind');assert.equal(p.rewind,1);
 const before=e.serialize();p.closeDialog();assert.equal(p.pendingHint,undefined);
 p.confirmDialog();assert.equal(e.serialize(),before,'a delayed confirm after cancel must do nothing');
 p.hint();p.confirmDialog();const after=e.serialize(),hint=plain(p.hintCells);
 assert.equal(e.round.history.length,1);assert.ok(core.tenValidPath(e.round.board,hint,6));
 p.confirmDialog();assert.equal(e.serialize(),after,'double confirmation must not restart');assert.deepEqual(plain(p.hintCells),hint);
 await tick();
});
await test('requesting a hint cancels a partial drag, so its later release cannot replace the hint selection',async()=>{
 const {p,e}=controller();pointer(p,touchTypes.Down,6);pointer(p,touchTypes.Move,7);
 assert.deepEqual(plain(p.selected),[6,7]);assert.equal(p.touching,true);
 const before=plain(e.round.board);p.hint();assert.equal(p.pointer,-1);assert.equal(p.touching,false);
 assert.deepEqual(plain(p.hintCells),[3,4]);assert.equal(p.selected.length,0);
 pointer(p,touchTypes.Up,8);assert.equal(e.round.history.length,0);assert.deepEqual(plain(e.round.board),before);
 assert.equal(p.selected.length,0);assert.deepEqual(plain(p.hintCells),[3,4]);
 await tick();
});
await test('failed completion save blocks next level; retry and leaving during motion persist one outcome',async()=>{
 const {p,e,s}=controller();s.failSave=true;
 p.tap(3);p.tap(4);fire();p.tap(6);p.tap(7);p.tap(8);fire();await tick();
 assert.equal(p.saveFailed,true);await p.advance();assert.equal(e.round.stage,1);
 s.failSave=false;await p.retrySave();await p.advance();assert.equal(e.round.stage,2);assert.deepEqual(s.records,[1]);
 p.selected=e.puzzle.solution[0].cells.slice();p.collect();const stale=[...timers.values()][0];p.aboutToDisappear();stale();await tick();
 assert.equal(timers.size,0);assert.equal(e.round.history.length,1);assert.equal(JSON.parse(s.raw).round.history.length,1);
});
await test('load/corrupt errors never overwrite saves; restart is explicit and backgrounded boot stays paused',async()=>{
 const {p,e,s}=controller();p.loaded=false;p.storage.load=async()=>{throw Error('unavailable');};await p.boot();
 assert.equal(p.dialog,'loadError');assert.equal(s.writes.length,0);
 p.storage.load=async()=>'{}';await p.boot();assert.equal(p.dialog,'corrupt');assert.equal(s.writes.length,0);
 p.confirmDialog();await tick();assert.equal(p.engine.round.stage,1);assert.equal(p.loaded,true);assert.equal(p.dialog,'');
 const q=controller();q.p.loaded=false;q.p.backgroundPaused=true;q.p.storage.load=async()=>'';await q.p.boot();assert.equal(q.p.dialog,'pause');
 q.p.closeDialog();assert.equal(q.p.active(),true);
});
await test('save-and-exit failure remains recoverable; success closes and suppresses a redundant save',async()=>{
 const {p,s}=controller();p.tap(3);s.failSave=true;await p.saveAndExit();assert.equal(p.left,undefined);assert.equal(p.dialog,'exit');
 s.failSave=false;await p.saveAndExit();assert.equal(p.left,true);assert.equal(p.skipSave,true);
});
await test('2400 mixed play actions preserve playable state, visible numbers, progress and saved recovery',async()=>{
 let seed=0x191048,actions=0;
 const random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed;};
 for(let run=0;run<30;run++){
  const {p,e}=controller(new core.TenEngine(run%5+1));let previous=plain(e.profile());
  for(let action=0;action<80;action++){
   if(p.dialog==='complete')await p.advance();
   else if(p.dialog.length>0)p.closeDialog();
   else {
    const choice=random()%10;
    if(choice<3){
     p.setSelection([]);const moves=paths(e);
     if(moves.length){
      const path=moves[random()%moves.length];
      if(choice===0){for(const i of path)p.tap(i);}
      else {
       pointer(p,touchTypes.Down,path[0]);for(const i of path.slice(1))pointer(p,touchTypes.Move,i);
       if(choice===1)fire();pointer(p,touchTypes.Up,path.at(-1));
      }
     }else{p.hint();if(p.dialog==='hintRewind')p.confirmDialog();}
    }else if(choice===3)p.undo();
    else if(choice===4){p.hint();if(p.dialog==='hintRewind'){if(random()%2)p.confirmDialog();else p.closeDialog();}}
    else if(choice===5){
     p.backgrounded();p.present('help');p.closeDialog();
     if(p.round.stage>1){p.present('previous');await p.changeStage(true);}p.closeDialog();
    }else if(choice===6){
     if(p.resumeStage>0){p.present('more');await p.changeStage(false);}
     else if(p.round.stage>1){p.present('previous');await p.changeStage(true);}
    }else if(choice===7){p.present('restart');p.confirmDialog();}
    else if(choice===8){p.present('more');p.present('help');p.closeDialog();p.closeDialog();}
    else{const raw=e.serialize();assert.ok(e.restore(raw));p.sync();p.confirmDialog();assert.equal(e.serialize(),raw);}
   }
   while(timers.size)fire();await p.save();
   const profile=plain(e.profile());
   assert.ok(profile.totalGroups>=previous.totalGroups&&profile.totalWins>=previous.totalWins);previous=profile;
   const restored=new core.TenEngine();assert.ok(restored.restore(e.serialize()));assert.equal(restored.serialize(),e.serialize());
   assert.deepEqual(plain(p.tiles),plain(e.tiles()));assert.deepEqual(plain(p.round.board),plain(e.round.board));
   assert.equal(p.round.history.length,e.round.history.length);assert.equal(p.pointer,-1);assert.equal(p.gestureCommitted,false);
   assert.ok(core.tenSum(p.round.board,p.selected)>=0&&core.tenSum(p.round.board,p.selected)<10);
   if(p.dialog===''){assert.equal(p.active(),true);assert.equal(p.round.phase,'playing');}
   if(p.hintCells.length)assert.ok(core.tenValidPath(p.round.board,p.hintCells,p.gridSize));
   actions++;
  }
 }
 assert.equal(actions,2400);console.log('  mixed actions verified: '+actions);
});
console.log('\nTen Garden: '+count+' rule, layout, input, lifecycle and achievement groups passed.');
