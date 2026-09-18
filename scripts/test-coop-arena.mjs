#!/usr/bin/env node
// Actual ArkTS rules/layout/input, executed on Node. Device rendering/FPS are separate.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
import { performance } from 'node:perf_hooks';
const base = new URL('../entry/src/main/ets/gamesNext/coopArena/', import.meta.url);
const files = ['ArenaModel.ets','ArenaEngine.ets','ArenaLayout.ets','ArenaInput.ets','ArenaProgress.ets'];
const source = files.map(f => readFileSync(new URL(f,base),'utf8')).join('\n')
  .replace(/^import[\s\S]*?;\s*$/gm,'').replace(/^export /gm,'');
const lib = vm.runInNewContext(stripTypeScriptTypes(source,{mode:'transform'})+
  '\n({ArenaEngine,ArenaInput,arenaLayout,arenaDefaultConfig,arenaProfile,arenaApplyResult,arenaProfileValid,arenaConfigValid,arenaBeats,arenaLeader,arenaHome})');
const {ArenaEngine,ArenaInput,arenaLayout,arenaDefaultConfig,arenaProfile,arenaApplyResult,arenaProfileValid,arenaConfigValid,arenaBeats,arenaLeader}=lib;
const plain = v => JSON.parse(JSON.stringify(v));
const config = (mode='classic',seed=42) => ({...plain(arenaDefaultConfig()),mode,seed});
const tick = (e,n) => { for(let i=0;i<n;i++) e.step(); };
const frozen = (e,units) => {
  e.round.entities=units.map((item,i) => ({...plain(e.round.entities[i]),id:i+1,target:-1,predator:-1,vx:0,vy:0,protectedUntil:1000,...item}));
  e.round.nextId=units.length+1; e.round.readyAt=[[999,999,999],[999,999,999],[999,999,999]];
  e.round.counts=[0,0,0]; for(const p of e.round.entities)e.round.counts[p.faction]++;
};
let passed=0;
function test(name,body){body();passed++;console.log(`PASS ${name}`);}
test('cyclic conversion, unique leaders and ties',()=>{
  for(let f=0;f<3;f++){assert.equal(arenaBeats(f,(f+1)%3),true);assert.equal(arenaBeats(f,(f+2)%3),false);assert.equal(arenaBeats(f,f),false);}
  assert.equal(arenaLeader([5,5,3]),-1);assert.equal(arenaLeader([0,0,0]),-1);assert.equal(arenaLeader([2,5,4]),1);
});
test('configuration rejects missing, fractional, unbounded and unknown values',()=>{
  for(const bad of [undefined,null,{}, {...config(),counts:[21,8,8]}, {...config(),faction:.5}, {...config(),mode:'countries'}, {...config(),seed:NaN}]) assert.equal(arenaConfigValid(bad),false);
  assert.equal(arenaConfigValid(config()),true);
});
test('same seed and commands produce identical trajectories',()=>{
  const a=new ArenaEngine(config('zones')), b=new ArenaEngine(config('zones'));
  for(let i=0;i<1800;i++){if(i%600===0){a.cast(0,0,360,360);b.cast(0,0,360,360);}a.step();b.step();}
  const ra=plain(a.round),rb=plain(b.round);delete ra.session;delete rb.session;assert.deepEqual(ra,rb);
});
test('fixed steps are independent of callback frequency; long stalls cap catch-up',()=>{
  const a=new ArenaEngine(config()),b=new ArenaEngine(config());
  for(let i=0;i<120;i++)a.advance(1000/120);
  for(let i=0;i<60;i++)b.advance(1000/60);
  assert.equal(a.round.tick,60);assert.deepEqual(plain(a.round.entities),plain(b.round.entities));
  assert.equal(a.advance(5000),3);assert.equal(a.round.tick,63);
  assert.equal(a.droppedMs,4950);
  assert.equal(a.advance(NaN),0);assert.equal(a.advance(-1),0);
  assert.equal(a.checks,0);assert.equal(a.scans,0);
});
test('restored round continues deterministically without changing its session',()=>{
  const a=new ArenaEngine(config('zones'));tick(a,870);const b=new ArenaEngine();
  assert.equal(b.restore(a.serialize()),true);tick(a,600);tick(b,600);
  assert.deepEqual(plain(a.round),plain(b.round));
});
test('corrupt saves do not replace a live round',()=>{
  const e=new ArenaEngine(),before=e.serialize();
  for(const raw of ['', 'null', '{}', 'x'.repeat(170000)])assert.equal(e.restore(raw),false);
  const r=plain(e.round);r.entities[0].x=10000;assert.equal(e.restore(JSON.stringify(r)),false);
  r.entities[0].x=100;r.entities[1].id=r.entities[0].id;assert.equal(e.restore(JSON.stringify(r)),false);
  assert.equal(e.serialize(),before);
  for(const patch of [{windLeft:[-1,2,2]},{owner:.5},{counts:[0,0,0]},{won:true}]){
    assert.equal(e.restore(JSON.stringify({...plain(e.round),...patch})),false);
  }
});
test('contact converts the loser, conserving population',()=>{
  const e=new ArenaEngine();frozen(e,[{faction:0,x:100,y:100},{faction:1,x:145,y:100,protectedUntil:0},{faction:2,x:600,y:600}]);
  e.step();assert.equal(e.round.entities[1].faction,0);assert.equal(e.round.entities.length,3);assert.equal(e.round.conversions,1);
});
test('shield absorbs exactly one conversion and grants the short buffer',()=>{
  const e=new ArenaEngine();frozen(e,[{faction:0,x:100,y:100},{faction:1,x:145,y:100,protectedUntil:0,shield:1,shieldUntil:3},{faction:2,x:600,y:600}]);
  e.step();assert.equal(e.round.entities[1].faction,1);assert.equal(e.round.entities[1].shield,0);assert.ok(e.round.entities[1].protectedUntil>e.time());
});
test('empty/outside/cooling-down casts do not consume a charge',()=>{
  const e=new ArenaEngine(config('zones'));const r=e.round;
  assert.equal(e.cast(0,2,0,720),0);assert.equal(r.windLeft[0],2);
  assert.equal(e.cast(0,2,-1,300),0);assert.equal(e.cast(0,2,Infinity,300),0);
  const p=r.entities[0];assert.ok(e.cast(0,2,p.x,p.y)>0);assert.equal(r.windLeft[0],1);
  assert.equal(e.cast(0,2,p.x,p.y),0);assert.equal(r.windLeft[0],1);
  assert.equal(e.cast(0,.5,360,360),0);assert.equal(e.cast(.5,0,360,360),0);
});
test('gather and shield affect only own team and obey recipient limits',()=>{
  const e=new ArenaEngine(config('zones'));
  for(const p of e.round.entities){p.x=340+p.id;p.y=360;}
  assert.equal(e.cast(0,0,360,360),6);
  assert.equal(e.round.entities.filter(p=>p.rallyUntil>0).length,6);
  assert.ok(e.round.entities.filter(p=>p.rallyUntil>0).every(p=>p.faction===0));
  assert.equal(e.cast(0,1,360,360),4);assert.equal(e.round.entities.filter(p=>p.shield===1).length,4);
});
test('only first pointer can release; cancel and outside-up cost nothing',()=>{
  const input=new ArenaInput();input.arm(2);input.down(7,100,100,360);input.down(8,150,150,360);
  assert.equal(input.pointer,7);assert.equal(input.up(8,150,150,360),undefined);
  assert.deepEqual(plain(input.up(7,180,90,360)),{x:360,y:180});
  input.down(7,100,100,360);assert.equal(input.up(7,361,100,360),undefined);
  input.down(7,100,100,360);input.cancel();assert.equal(input.up(7,100,100,360),undefined);assert.equal(input.skill,-1);
});
test('classic timeout tie is not a player win and result freezes',()=>{
  const e=new ArenaEngine();frozen(e,[{faction:0,x:100,y:100},{faction:1,x:600,y:100},{faction:2,x:360,y:600}]);
  e.round.tick=3599;e.step();assert.equal(e.round.finished,true);assert.equal(e.round.winner,-1);assert.equal(e.round.won,false);
  const before=e.serialize();e.advance(500);e.step();assert.equal(e.serialize(),before);
});
test('survival objective takes priority over clearing the arena',()=>{
  const c=config('challenge');c.mission=2;const e=new ArenaEngine(c);
  frozen(e,[{faction:0,x:360,y:360}]);e.step();assert.equal(e.round.finished,false);
  e.round.tick=2699;e.step();assert.equal(e.round.won,true);assert.equal(e.round.tick,2700);assert.equal(e.round.stars,2);
  const failed=new ArenaEngine(c);frozen(failed,[{faction:1,x:360,y:360}]);failed.step();assert.equal(failed.round.finished,true);assert.equal(failed.round.won,false);
});
test('zone claim requires one second; ties stop scoring',()=>{
  const e=new ArenaEngine(config('zones'));frozen(e,[{faction:0,x:360,y:360},{faction:1,x:50,y:50},{faction:2,x:665,y:665}]);
  tick(e,59);assert.equal(e.round.scores[0],0);e.step();assert.ok(e.round.scores[0]>0);
  e.round.entities[0].x=330;e.round.entities[0].y=360;e.round.entities[1].x=390;e.round.entities[1].y=360;
  const score=e.round.scores[0];e.step();assert.equal(e.round.scores[0],score);
});
test('finite reinforcements announce before filling only the deficient team',()=>{
  const e=new ArenaEngine(config('zones'));frozen(e,[{faction:0,x:100,y:100},{faction:1,x:620,y:100},{faction:2,x:360,y:620}]);
  e.round.lowSince=[0,0,0];e.round.tick=239;e.step();assert.ok(e.round.supplyDue.every(n=>n===6));
  e.round.tick=359;e.step();assert.equal(e.round.entities.length,9);assert.deepEqual(plain(e.round.supplyLeft),[1,1,1]);
  assert.deepEqual(plain(e.round.counts),[3,3,3]);
});
test('zone victory is based on score, not remaining population',()=>{
  const e=new ArenaEngine(config('zones'));e.round.tick=5399;e.round.scores=[1,4,2];e.step();
  assert.equal(e.round.finished,true);assert.equal(e.round.winner,1);assert.equal(e.round.won,false);
});
test('natural official results update records once; practice does not',()=>{
  const p=arenaProfile(),e=new ArenaEngine();e.round.finished=true;e.round.won=true;
  assert.equal(arenaApplyResult(p,e.round),true);assert.equal(arenaApplyResult(p,e.round),false);assert.equal(p.rounds,1);assert.equal(p.wins,1);
  const q=new ArenaEngine({...config(),counts:[3,4,5]});q.round.finished=true;q.round.session+='other';arenaApplyResult(p,q.round);assert.equal(p.rounds,1);
  const c=new ArenaEngine({...config('challenge'),mission:3});c.round.session+='challenge';c.round.finished=true;c.round.stars=3;arenaApplyResult(p,c.round);assert.equal(p.stars[3],3);
  assert.equal(arenaProfileValid(p),true);assert.equal(arenaProfileValid({...plain(p),stars:[4,0,0,0,0,0,0,0]}),false);
});
test('phone, cover screen, landscape, tablet and partial-fold panes fit',()=>{
  for(const [w,h] of [[320,568],[360,640],[390,844],[430,932],[640,360],[720,720],[768,1024],[1024,768],[1280,800]]){
    const l=arenaLayout(w,h);assert.equal(l.limited,false,`${w}x${h}`);
    assert.ok(l.board.width>=256);assert.ok(l.board.x>=l.pane.x);assert.ok(l.board.y>=l.pane.y);
    assert.ok(l.board.x+l.board.width<=l.pane.x+l.pane.width+.01);
    assert.ok(l.board.y+l.board.height<=l.pane.y+l.pane.height+.01);
    if(!l.wide) assert.ok(l.board.y+l.board.height+l.gap+l.keys<=l.pane.y+l.pane.height+.01,`${w}x${h} buttons`);
  }
  const half=arenaLayout(1000,1100,undefined,[{x:0,y:520,width:1000,height:20}]);assert.equal(half.limited,false);assert.equal(half.wide,true);
  const partial=arenaLayout(800,844,undefined,[{x:390,y:0,width:20,height:844}]);assert.equal(partial.limited,false);assert.equal(partial.wide,false);
});
test('tiny windows pause; two creases and insets never place the board on a hinge',()=>{
  assert.equal(arenaLayout(260,560).limited,true);
  assert.equal(arenaLayout(390,400).limited,true);
  const creases=[{x:390,y:0,width:16,height:860},{x:810,y:0,width:16,height:860}];
  const l=arenaLayout(1220,860,{top:40,bottom:28,left:16,right:20},creases);
  assert.equal(l.limited,false);
  for(const c of creases) assert.ok(l.board.x+l.board.width<=c.x || l.board.x>=c.x+c.width);
  const irrelevant=arenaLayout(390,844,undefined,[{x:900,y:0,width:10,height:844}]);assert.equal(irrelevant.limited,false);
});
test('all eight challenges finish within their rule limit; effects and history remain bounded',()=>{
  for(let m=0;m<8;m++){
    const c=config('challenge');c.mission=m;const e=new ArenaEngine(c);
    for(let n=0;n<5500&&!e.round.finished;n++){
      if(n%30===0){e.cast(0,0,360,360);const p=e.round.entities.find(p=>p.faction===0);if(p)e.cast(0,1,p.x,p.y);}
      e.step();
    }
    assert.ok(e.round.finished,`mission ${m}`);assert.ok(e.time()<=e.scenario.limit+.02);
    assert.ok(e.effects.length<=24&&e.round.history.length<=123&&e.round.moments.length<=48);
    const restore=new ArenaEngine();assert.ok(restore.restore(e.serialize()),`mission ${m} result restores`);
  }
});
test('changing chosen identity keeps challenge positions, commands and difficulty symmetric',()=>{
  const engines=[0,1,2].map(f=>new ArenaEngine({...config('challenge'),faction:f,mission:4}));
  for(let n=0;n<1800;n++){
    for(let f=0;f<3;f++){
      const e=engines[f];if(n%30===0){e.cast(f,0,360,360);const p=e.round.entities.find(p=>p.faction===f);if(p)e.cast(f,1,p.x,p.y);}
      e.step();
    }
  }
  const norm=(e,f)=>e.round.entities.map(p=>({x:p.x,y:p.y,faction:(p.faction-f+3)%3}));
  assert.deepEqual(plain(norm(engines[0],0)),plain(norm(engines[1],1)));
  assert.deepEqual(plain(norm(engines[0],0)),plain(norm(engines[2],2)));
});
test('intro challenge rewards gathering instead of requiring luck or a specific faction',()=>{
  const active=new ArenaEngine({...config('challenge'),mission:0}),idle=new ArenaEngine({...config('challenge'),mission:0});
  for(let n=0;n<5500;n++){
    if(n%30===0)active.cast(0,0,360,360);active.step();idle.step();
    if(active.round.finished&&idle.round.finished)break;
  }
  assert.equal(active.round.won,true);assert.equal(active.round.stars,3);assert.equal(idle.round.won,false);
});
test('60-unit stress: finite bounded positions and local collision checks',()=>{
  const e=new ArenaEngine({...config('zones',90217),counts:[20,20,20],event:'garden'});
  let checks=0,peak=0;const start=performance.now();
  for(let n=0;n<1800&&!e.round.finished;n++){
    const before=performance.now();e.step();peak=Math.max(peak,performance.now()-before);checks+=e.checks;
    for(const p of e.round.entities)assert.ok(Number.isFinite(p.x)&&Number.isFinite(p.y)&&p.x>=0&&p.x<=720&&p.y>=0&&p.y<=720);
  }
  assert.ok(checks/1800<60*59/2*.65);assert.equal(e.round.entities.length,60);
  console.log(`  HOST ONLY: 60 units / 1800 steps ${(performance.now()-start).toFixed(0)} ms; peak ${peak.toFixed(2)} ms; checks/step ${(checks/1800).toFixed(1)}`);
});
console.log(`\n${passed} rules, layout, persistence and input cases passed. Native UI/audio/FPS require device testing.`);
