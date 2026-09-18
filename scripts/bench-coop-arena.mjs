#!/usr/bin/env node
// Host simulation, NOT HarmonyOS frame-rate data. Useful for bounds, seeds and balancing.
import {readFileSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
import {performance} from 'node:perf_hooks';
const base=new URL('../entry/src/main/ets/gamesNext/coopArena/',import.meta.url);
const src=['ArenaModel.ets','ArenaEngine.ets'].map(f=>readFileSync(new URL(f,base),'utf8')).join('\n')
 .replace(/^import[\s\S]*?;\s*$/gm,'').replace(/^export /gm,'');
const {ArenaEngine,arenaDefaultConfig}=vm.runInNewContext(stripTypeScriptTypes(src,{mode:'transform'})+'\n({ArenaEngine,arenaDefaultConfig})');
const cfg=(mode,seed=71,faction=0,mission=0,count=8)=>({...arenaDefaultConfig(),mode,seed,faction,mission,counts:[count,count,count]});
function command(e,policy=0){
 const f=e.round.config.faction,own=e.round.entities.filter(u=>u.faction===f);
 if(!own.length)return;
 // A simple baseline, not an optimal player. Each policy uses exactly the public skill API.
 const p=own[policy===0?0:Math.floor(own.length/2)];
 e.cast(f,0,360,360);e.cast(f,1,p.x,p.y);
 if(policy===1&&e.time()>22&&e.round.scores[f]+8<Math.max(...e.round.scores)) e.cast(f,2,360,360);
 if(policy===2&&e.time()>10&&own.length<5)e.cast(f,2,p.x,p.y);
}
function run(c,policy=-1){
 const e=new ArenaEngine(c);let steps=0,checks=0,peak=0,scans=0;const start=performance.now();
 while(!e.round.finished&&steps<5500){
  const t=performance.now();if(policy>=0&&steps%30===0)command(e,policy);e.step();
  peak=Math.max(peak,performance.now()-t);checks+=e.checks;scans+=e.scans;steps++;
 }
 if(!e.round.finished)throw Error('round failed to finish');
 return {winner:e.round.winner,won:e.round.won,seconds:e.time(),stars:e.round.stars,steps,ms:performance.now()-start,peak,checks:checks/steps,scans:scans/steps};
}
for(const n of [8,12,20]){
 const r=run(cfg('zones',72391,0,0,n),1);
 console.log(`HOST ${n*3} units: ${r.steps} steps; avg ${(r.ms/r.steps).toFixed(3)}ms/step; peak ${r.peak.toFixed(2)}ms; pairs ${r.checks.toFixed(1)}; AI scans ${r.scans.toFixed(1)}`);
}
const wins=[0,0,0,0];let duration=0;
for(let i=0;i<36;i++){const r=run(cfg('classic',191+i*8171));wins[r.winner<0?3:r.winner]++;duration+=r.seconds;}
console.log(`Classic 36 seeds: rock/scissors/cloth/draw=${wins.join('/')}; mean ${(duration/36).toFixed(1)}s. Sample only, not proof of balance.`);
for(let m=0;m<8;m++){
 const outcomes=[];
 for(let f=0;f<3;f++){
  let best=0;
  for(let p=0;p<3;p++){const r=run(cfg('challenge',1,f,m),p);best=Math.max(best,r.stars);}
  outcomes.push(best);
 }
 console.log(`Challenge ${m+1}: best stars from 3 simple policies per chosen faction = ${outcomes.join('/')}`);
}
console.log('Device graphics, audio latency, frame pacing and thermal load are not measured by this host run.');
