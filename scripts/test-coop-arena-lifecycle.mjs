#!/usr/bin/env node
// Runs the actual native page methods with only platform adapters replaced.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
const base=new URL('../entry/src/main/ets/gamesNext/coopArena/',import.meta.url);
const page=readFileSync(new URL('CoopArenaPage.ets',base),'utf8');
function method(name){
  const match=new RegExp(`^  private (?:async )?${name}\\(`,'m').exec(page);assert.ok(match,name);
  let start=page.indexOf('{',match.index),depth=1,end=start+1;
  for(;depth&&end<page.length;end++){if(page[end]==='{')depth++;if(page[end]==='}')depth--;}
  assert.equal(depth,0);return page.slice(match.index,end);
}
const names=[...page.matchAll(/^  private (?:async )?(\w+)\(/gm)].map(m=>m[1]);
const logic=['ArenaModel.ets','ArenaGuide.ets','ArenaEngine.ets','ArenaLayout.ets','ArenaInput.ets','ArenaProgress.ets'].map(n=>readFileSync(new URL(n,base),'utf8')).join('\n');
const harness=`class Page {
 constructor(){
  this.engine=new ArenaEngine();this.configuration=this.engine.round.config;this.profile=arenaProfile();
  this.loaded=true;this.hasRound=true;this.disposed=false;this.dialog='paused';this.remainingCountdown=0;
  this.input=new ArenaInput();this.armed=-1;this.countdown=3;this.message='';
  this.counts=[8,8,8];this.scores=[0,0,0];this.cooldowns=[0,0,0];this.skillAllowed=[false,false,false];this.timeLeft=60;this.windLeft=2;
  this.insets={top:24,bottom:16,left:0,right:0};this.creases=[];this.fold={foldable:false,status:0};
  this.pageWidth=390;this.pageHeight=844;this.viewport=arenaLayout(390,844);this.lastTick=0;this.lastHud=0;this.lastSave=0;this.pixelRatio=1;this.profileCounter=0;this.profileClock=()=>this.now();
  this.canvasReady=true;this.canvas={};this.dark=false;this.soundEnabled=true;this.context={};this.saving=false;this.saveFailed=false;
  this.paints=0;this.played=[];this.saves=[];this.exits=0;this.scoresRecorded=[];this.achievements=[];
  this.clock={running:false,start:(f)=>{this.clock.running=true;this.clock.frame=f;},stop:()=>{this.clock.running=false;}};
  this.perf={frame:()=>{},reset:()=>{},begin:()=>{},finish:()=>{},context:()=>{},saved:()=>{},stall:()=>{}};this.renderer={paint:()=>this.paints++,mode:()=>'SVG 3/3'};
  this.sounds={play:n=>this.played.push(n),silence:()=>this.played.push('silence'),setEnabled:()=>{}};
  this.hostWindow={setDark:()=>{}};
  this.storage={lastLoadFailed:false,load:async()=>'',save:async(_context,raw)=>{this.saves.push(raw);return true;}};
  this.exitToHub=()=>this.exits++;this.recordScore=n=>this.scoresRecorded.push(n);this.reportAchievementEvent=async e=>{this.achievements.push(e);return true;};
  this.updateHud();
 }
 ${names.map(method).join('\n')}
}
globalThis.fresh=()=>new Page();globalThis.makeEngine=c=>new ArenaEngine(c);globalThis.makeConfig=()=>arenaDefaultConfig();
globalThis.saveString=(p,r)=>arenaSave(p,r);
`;
let now=0;
const context={console,Date,TouchType:{Down:0,Move:1,Up:2,Cancel:3},systemDateTime:{TimeType:{STARTUP:0},getUptime:()=>now*1e6}};
vm.runInNewContext(stripTypeScriptTypes((logic+'\n'+harness).replace(/^import[\s\S]*?;\s*$/gm,'').replace(/^export /gm,''),{mode:'transform'}),context);
function fresh(){now=0;return context.fresh();}
function walk(p,ms){for(let n=0;n<ms;n+=20){now+=Math.min(20,ms-n);if(p.clock.running)p.clock.frame();}}
let passed=0;
async function test(name,fn){await fn();passed++;console.log(`PASS ${name}`);}
await test('countdown, one active clock, no simulation before start',async()=>{
 const p=fresh();p.newRound(context.makeConfig());assert.equal(p.dialog,'countdown');walk(p,2900);assert.equal(p.engine.round.tick,0);
 walk(p,120);assert.equal(p.dialog,'play');walk(p,1000);assert.ok(p.engine.round.tick>=59&&p.engine.round.tick<=63);
 const queued=p.clock.frame;p.pause();const state=p.engine.serialize();now+=30000;queued();assert.equal(p.engine.serialize(),state);assert.equal(p.clock.running,false);
 p.resume();walk(p,20);assert.ok(p.engine.round.tick-JSON.parse(state).tick<=2);
});
await test('unchanged HUD keeps the same observable arrays, while real changes update immediately',async()=>{
 const p=fresh();p.updateHud();const counts=p.counts,scores=p.scores,cooldowns=p.cooldowns,skills=p.skillAllowed;
 for(let i=0;i<30;i++)assert.equal(p.updateHud(),false);
 assert.equal(p.counts,counts);assert.equal(p.scores,scores);assert.equal(p.cooldowns,cooldowns);assert.equal(p.skillAllowed,skills);
 p.engine.round.counts[0]+=1;assert.equal(p.updateHud(),true);assert.notEqual(p.counts,counts);assert.equal(p.counts[0],9);
 assert.equal(p.clockText(),'1:00');p.timeLeft=9;assert.equal(p.clockText(),'0:09');
});
await test('changing missions refreshes observable scenery, name and available commands',async()=>{
 const p=fresh();p.newRound({...context.makeConfig(),mode:'challenge',mission:0});
 assert.equal(p.scenario.obstacles,false);assert.equal(p.scenario.skills[1],false);
 p.newRound({...context.makeConfig(),mode:'challenge',mission:3});
 assert.equal(p.scenario.obstacles,true);assert.equal(p.scenario.skills[1],true);assert.equal(p.scenario.name,'绕过花盆');
 await p.save();const q=fresh();q.storage.load=async()=>p.saves.at(-1);await q.boot();assert.equal(q.scenario.obstacles,true);
});
await test('phone-sized folds stay playable after manual resume; world state never resizes',async()=>{
 const p=fresh();p.resume();walk(p,100);
 for(const status of [1,2,3,11,12,13,21,22,23]){
  const before=p.engine.serialize();p.windowChanged(p.insets,[],{foldable:true,status});
  assert.equal(p.viewport.limited,false);assert.equal(p.dialog,'paused');assert.equal(p.engine.serialize(),before);
  p.resume();walk(p,20);assert.ok(p.engine.round.tick>JSON.parse(before).tick);
 }
 p.pageWidth=1000;p.pageHeight=1100;p.relayout();assert.equal(p.viewport.limited,false);
 p.windowChanged(p.insets,[{x:0,y:520,width:1000,height:20}],{foldable:true,status:3});assert.equal(p.viewport.limited,false);
});
await test('tiny pane pauses and cancels targeting; growing needs explicit continue',async()=>{
 const p=fresh();p.newRound({...context.makeConfig(),mode:'zones'});p.remainingCountdown=0;p.resume();p.arm(2);
 p.input.down(1,120,120,p.viewport.board.width);const state=p.engine.serialize();p.pageWidth=250;p.relayout();
 assert.equal(p.viewport.limited,true);assert.equal(p.dialog,'paused');assert.equal(p.armed,-1);assert.equal(p.input.pointer,-1);
 p.resume();walk(p,1000);p.cast(100,100);assert.equal(p.engine.serialize(),state);
 p.pageWidth=390;p.relayout();assert.equal(p.viewport.limited,false);assert.equal(p.clock.running,false);p.resume();assert.equal(p.clock.running,true);
});
await test('help and system back cancel inputs before leaving; never advance hidden round',async()=>{
 const p=fresh();p.newRound({...context.makeConfig(),mode:'zones'});p.remainingCountdown=0;p.resume();p.arm(2);p.exitRequested();
 assert.equal(p.armed,-1);assert.equal(p.dialog,'play');assert.equal(p.exits,0);
 p.showHelp();const state=p.engine.serialize();walk(p,20000);assert.equal(p.engine.serialize(),state);assert.equal(p.dialog,'help');
 p.exitRequested();assert.equal(p.dialog,'paused');assert.equal(p.clock.running,false);assert.equal(p.exits,0);
});
await test('primary pointer selection previews before cast, and cancel never charges',async()=>{
 const p=fresh();p.newRound({...context.makeConfig(),mode:'zones'});p.remainingCountdown=0;p.resume();p.arm(2);
 const unit=p.engine.round.entities[0],size=p.viewport.board.width,x=unit.x*size/720,y=unit.y*size/720;
 const touch=(type,id,x,y)=>p.touch({type,changedTouches:[{id,x,y}]});
 touch(0,7,x,y);assert.equal(p.engine.round.windLeft[0],2);touch(0,8,x,y);touch(2,8,x,y);assert.equal(p.engine.round.windLeft[0],2);
 touch(3,7,x,y);assert.equal(p.armed,-1);assert.equal(p.engine.round.windLeft[0],2);
 p.arm(2);touch(0,7,x,y);touch(2,7,x,y);assert.equal(p.engine.round.windLeft[0],1);assert.equal(p.armed,-1);
});
await test('load failure/corruption never silently overwrites progress',async()=>{
 const p=fresh();p.storage.lastLoadFailed=true;await p.boot();assert.equal(p.dialog,'error');assert.equal(p.loaded,false);await p.save();assert.equal(p.saves.length,0);
 p.storage.lastLoadFailed=false;p.storage.load=async()=>'{broken';await p.boot();assert.equal(p.dialog,'error');assert.equal(p.loaded,false);
 p.exitRequested();assert.equal(p.exits,1);assert.equal(p.saves.length,0);
 const q=fresh();q.storage.load=async()=>'';await q.boot();assert.equal(q.dialog,'setup');assert.equal(q.clock.running,false);
});
await test('restoring a live session opens paused; loading after disposal is ignored',async()=>{
 const p=fresh();p.resume();walk(p,1500);await p.save();const raw=p.saves.at(-1);
 const q=fresh();q.storage.load=async()=>raw;await q.boot();assert.equal(q.dialog,'paused');assert.equal(q.clock.running,false);
 assert.equal(q.engine.round.session,p.engine.round.session);assert.equal(q.engine.round.tick,p.engine.round.tick);
 let resolve;const r=fresh();r.storage.load=()=>new Promise(done=>resolve=done);const pending=r.boot();r.disposed=true;resolve(raw);await pending;
 assert.equal(r.clock.running,false);assert.equal(r.loaded,false);
});
await test('last chosen mode and faction survive returning from setup',async()=>{
 const p=fresh();p.hasRound=false;p.configuration={...context.makeConfig(),mode:'zones',faction:2};await p.save();
 const q=fresh();q.storage.load=async()=>p.saves.at(-1);await q.boot();
 assert.equal(q.dialog,'setup');assert.equal(q.configuration.mode,'zones');assert.equal(q.configuration.faction,2);assert.equal(q.clock.running,false);
});
await test('failed exit save stays paused; retry leaves once saved',async()=>{
 const p=fresh();p.resume();p.storage.save=async()=>false;await p.leave();assert.equal(p.exits,0);assert.equal(p.saveFailed,true);assert.equal(p.dialog,'paused');
 p.storage.save=async()=>true;await p.leave();assert.equal(p.exits,1);assert.equal(p.saveFailed,false);
});
await test('natural result reported once after persistence; reload cannot increment again',async()=>{
 const p=fresh();p.engine.round.finished=true;p.engine.round.won=true;p.engine.round.winner=0;
 await p.publishResult();await p.publishResult();assert.equal(p.scoresRecorded.length,1);assert.equal(p.achievements.length,1);
 assert.equal(p.achievements[0].gameId,'rpsBattle');assert.equal(p.achievements[0].facts.find(f=>f.key==='supportWon').value,1);
 assert.equal(p.profile.rounds,1);const raw=p.saves.at(-1);
 const q=fresh();q.storage.load=async()=>raw;await q.boot();await Promise.resolve();assert.equal(q.dialog,'result');assert.equal(q.achievements.length,0);assert.equal(q.profile.rounds,1);
});
await test('failed result save defers reporting and retry keeps a single local result',async()=>{
 const p=fresh();p.engine.round.finished=true;p.engine.round.won=true;p.storage.save=async()=>false;
 await p.publishResult();assert.equal(p.achievements.length,0);assert.equal(p.engine.round.reported,false);assert.equal(p.profile.rounds,1);
 p.storage.save=async()=>true;await p.publishResult();assert.equal(p.achievements.length,1);assert.equal(p.profile.rounds,1);
});
await test('rejected achievement acknowledgment preserves the result across replay and setup requests',async()=>{
 const p=fresh();p.dialog='result';p.engine.round.finished=true;p.engine.round.won=true;p.engine.round.winner=0;
 p.reportAchievementEvent=async()=>false;const session=p.engine.round.session;
 await p.publishResult();assert.equal(p.engine.round.reported,false);assert.equal(p.saveFailed,true);
 await p.replay();assert.equal(p.engine.round.session,session);assert.equal(p.dialog,'result');
 await p.toSetup();assert.equal(p.hasRound,true);assert.equal(p.dialog,'result');
 p.reportAchievementEvent=async e=>{p.achievements.push(e);return true;};await p.toSetup();
 assert.equal(p.dialog,'setup');assert.equal(p.achievements.length,1);assert.equal(p.profile.rounds,1);
});
await test('practice result and abandoning a running round never award official wins',async()=>{
 const p=fresh();p.newRound({...context.makeConfig(),counts:[3,4,5]});p.engine.round.finished=true;p.engine.round.won=true;
 await p.publishResult();assert.equal(p.achievements.length,0);assert.equal(p.scoresRecorded.length,0);assert.equal(p.profile.rounds,0);
 const q=fresh();q.resume();walk(q,120);q.pause();q.toSetup();await Promise.resolve();assert.equal(q.dialog,'setup');assert.equal(q.achievements.length,0);
});
await test('result sound is emitted after stopping the game clock',async()=>{
 const p=fresh();p.engine.round.tick=3599;p.resume();walk(p,20);assert.equal(p.dialog,'result');
 const last=p.played.at(-1);assert.ok(last==='win'||last==='finish');assert.equal(p.clock.running,false);
});
await test('no effect cast keeps selection and gives a visible, persistent explanation',async()=>{
 const p=fresh();p.newRound({...context.makeConfig(),mode:'zones'});p.remainingCountdown=0;p.resume();p.arm(2);p.cast(0,720);
 assert.equal(p.armed,2);assert.match(p.message,/没有可影响/);walk(p,200);assert.match(p.message,/没有可影响/);assert.equal(p.engine.round.windLeft[0],2);
});
console.log(`\n${passed} lifecycle cases passed. Platform adapters and touch delivery still need device validation.`);
