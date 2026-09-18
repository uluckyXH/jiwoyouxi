#!/usr/bin/env node
// Host CPU rule benchmark. Excludes ArkUI, GPU and sound playback.
import assert from 'node:assert/strict';
import {readFileSync,readdirSync,statSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import {performance} from 'node:perf_hooks';
import vm from 'node:vm';
const base=new URL('../entry/src/main/ets/gamesNext/blockWorkshop/',import.meta.url);
const source=['BlockModel.ets','BlockEngine.ets'].map(name=>readFileSync(new URL(name,base),'utf8')).join('\n')
 .replace(/^import[\s\S]*?;\s*$/gm,'').replace(/^export /gm,'');
const {BlockEngine}=vm.runInNewContext(stripTypeScriptTypes(source,{mode:'transform'})+'\n({BlockEngine});');
function sample(name,prepare,run,count=5000){
 const times=[];
 for(let i=0;i<count+300;i++){
  const e=prepare(i),start=performance.now();run(e);const elapsed=performance.now()-start;
  if(i>=300)times.push(elapsed);
 }
 times.sort((a,b)=>a-b);
 return {name,samples:count,p50Ms:+times[Math.floor(count*.5)].toFixed(4),p95Ms:+times[Math.floor(count*.95)].toFixed(4),maxMs:+times[count-1].toFixed(4)};
}
const fresh=seed=>new BlockEngine(seed);
const dense=seed=>{const e=fresh(seed);for(let row=3;row<22;row++)for(let x=0;x<10;x++)if(x!==4)e.round.board[row*10+x]=1+(row+x)%7;e.round.piece={kind:0,turn:1,x:2,y:1};return e;};
const four=seed=>{const e=fresh(seed);for(let row=18;row<22;row++)for(let x=0;x<10;x++)if(x!==4)e.round.board[row*10+x]=1;e.round.piece={kind:0,turn:1,x:2,y:1};return e;};
const data=[
 sample('gravity + ghost on fresh board',fresh,e=>{e.advance(200);e.ghostY();}),
 sample('move + rotate + ghost',fresh,e=>{e.command('left');e.command('rotate');e.ghostY();}),
 sample('dense board: collision probes + ghost',dense,e=>{e.command('left');e.command('rotate');e.ghostY();}),
 sample('four-line drop, score, compact, next spawn',four,e=>{e.command('drop');e.advance(160);assert.equal(e.round.lines,4);assert.equal(e.round.phase,'falling');}),
 sample('dense board: serialize + validate + restore',dense,e=>{const raw=e.serialize();assert.equal(fresh(1).restore(raw),true);})
];
const audio=new URL('../entry/src/main/resources/rawfile/gamesNext/blockWorkshop/audio/',import.meta.url);
const files=readdirSync(audio).filter(n=>n.endsWith('.wav'));
console.log(JSON.stringify({runtime:process.version,platform:`${process.platform}/${process.arch}`,
 note:'Host CPU only. This is not HarmonyOS device FPS, GPU rendering or audio performance.',results:data,
 audio:{files:files.length,bytes:files.reduce((s,n)=>s+statSync(new URL(n,audio)).size,0)}},null,2));
