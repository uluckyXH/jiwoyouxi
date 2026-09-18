#!/usr/bin/env node
// Exercises the actual renderer against delayed/rejected platform SVGs, not a copy of its logic.
import assert from 'node:assert/strict';
import {readFileSync, readdirSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
const base=new URL('../entry/src/main/ets/gamesNext/coopArena/',import.meta.url);
const assets=new URL('../entry/src/main/resources/rawfile/',import.meta.url);
const source=['ArenaModel.ets','ArenaEngine.ets','ArenaPalette.ets','ArenaArtwork.ets','ArenaRenderer.ets']
 .map(f=>readFileSync(new URL(f,base),'utf8')).join('\n').replace(/^import[\s\S]*?;\s*$/gm,'').replace(/^export /gm,'');
const images=[],paths=[],logs=[];
let pending=false,reject=false;
class Bitmap {
 constructor(url){
  if(reject)throw Error('decoder unavailable');
  this.url=url;this.closed=0;this.reads=0;this.pending=pending;
  const svg=readFileSync(new URL(url.replace('resource://RAWFILE/',''),assets),'utf8');
  this.w=Number(/<svg[^>]*\bwidth="(\d+)"/.exec(svg)?.[1]);
  this.h=Number(/<svg[^>]*\bheight="(\d+)"/.exec(svg)?.[1]);images.push(this);
 }
 get width(){this.reads++;return this.pending?0:this.w;}
 get height(){this.reads++;return this.pending?0:this.h;}
 close(){this.closed++;}
}
const lib=vm.runInNewContext(stripTypeScriptTypes(source,{mode:'transform'})+'\nconst P=ArenaPalette;\n({ArenaEngine,ArenaRenderer})',{
 ImageBitmap:Bitmap,Path2D:class {constructor(path){this.path=path;paths.push(this);}},
 hilog:{info:(_,tag,fmt,text)=>logs.push(text),warn:(_,tag,fmt,text)=>logs.push(text)}
});
function canvas(){
 const calls=[];let depth=0;const state=[];
 const ctx=new Proxy({calls,fail:undefined,globalAlpha:1,check:()=>assert.equal(depth,0)}, {
  get(target,key){
   if(key in target)return target[key];
   return (...args)=>{
    calls.push([key,...args]);
    if(key==='save'){depth++;state.push(target.globalAlpha);}
    if(key==='restore'){depth--;target.globalAlpha=state.pop();}
    if(key==='drawImage'&&args[0]===target.fail)throw Error('native draw failed');
   };
  }
 });return ctx;
}
const paint=(r,c,e=new lib.ArenaEngine(),dark=false,alpha=1)=>r.paint(c,e,360,dark,-1,-1,-1,false,alpha);
let passed=0;
function test(name,run){pending=false;reject=false;run();passed++;console.log(`PASS ${name}`);}
test('every bundled SVG has intrinsic dimensions; art remains vector and text-free',()=>{
 const root=new URL('gamesNext/coopArena/',assets);
 for(const folder of ['factions','tokens','icons','scene'])for(const file of readdirSync(new URL(folder+'/',root))){
  const xml=readFileSync(new URL(folder+'/'+file,root),'utf8');
  assert.match(xml,/<svg[^>]+width="[\d.]+"[^>]+height="[\d.]+"[^>]+viewBox="0 0 [\d.]+ [\d.]+"/,file);
  assert.doesNotMatch(xml,/<(?:text|filter|script|foreignObject)\b/,file);
 }
});
test('delayed SVGs render recognizable vector shapes without letter circles',()=>{
 pending=true;const r=new lib.ArenaRenderer(),c=canvas();paint(r,c);
 assert.equal(r.mode(),'SVG 0/3');assert.ok(c.calls.some(call=>call[0]==='fill'&&call[1]?.path));
 assert.equal(c.calls.filter(call=>call[0]==='fillText').length,0);c.check();assert.equal(c.globalAlpha,1);
 const allocated=paths.length;paint(r,c);assert.equal(paths.length,allocated,'paths must not be parsed per entity/frame');
});
test('decoded SVGs become available without restart; dimensions are cached once ready',()=>{
 pending=true;const r=new lib.ArenaRenderer(),c=canvas();paint(r,c);const used=images.slice(-3);
 used.forEach(b=>b.pending=false);c.calls.length=0;paint(r,c);
 assert.equal(r.mode(),'SVG 3/3');assert.equal(c.calls.filter(call=>call[0]==='drawImage').length,24);
 const reads=used.map(b=>b.reads);for(let i=0;i<8;i++)paint(r,c);
 assert.deepEqual(used.map(b=>b.reads),reads,'native bitmap dimensions should not be queried for each unit');
 c.check();
});
test('visible token rim matches the physical diameter at phone and tablet scale',()=>{
 const r=new lib.ArenaRenderer(),e=new lib.ArenaEngine();
 for(const size of [280,360,640]){
  const c=canvas();r.paint(c,e,size,false,-1,-1,-1,false,1);
  const call=c.calls.find(call=>call[0]==='drawImage');assert.ok(call);
  assert.ok(Math.abs(call[4]*.96-52)<1e-8);
  assert.ok(Math.abs(call[2]+call[4]/2-e.round.entities[0].x)<1e-8);
  assert.ok(c.calls.some(call=>call[0]==='scale'&&call[1]===size/720));c.check();
 }
});
test('rendered positions interpolate, while exact physics positions remain untouched',()=>{
 const r=new lib.ArenaRenderer(),e=new lib.ArenaEngine(),c=canvas();e.advance(25);const saved=e.serialize();
 paint(r,c,e,false,e.interpolation());const call=c.calls.find(call=>call[0]==='drawImage');
 assert.ok(Math.abs(call[2]+call[4]/2-e.visualX(0,.5))<1e-8);assert.equal(e.serialize(),saved);
});
test('a rejected draw falls back to artwork and warns only once for that bitmap',()=>{
 const r=new lib.ArenaRenderer(),c=canvas();r.prepare(false);const used=images.slice(-3);c.fail=used[0];
 const n=logs.length;paint(r,c);paint(r,c);
 assert.equal(used[0].closed,1);assert.equal(r.mode(),'SVG 2/3');
 assert.equal(logs.slice(n).filter(s=>s.includes('绘制失败')).length,1);
 assert.ok(c.calls.some(call=>call[0]==='fill'&&call[1]?.path));assert.equal(c.calls.some(call=>call[0]==='fillText'),false);c.check();
});
test('theme changes release old graphics once; a decoder failure stays playable',()=>{
 const r=new lib.ArenaRenderer(),c=canvas();paint(r,c);const old=images.slice(-3);paint(r,c,undefined,true);
 old.forEach(b=>assert.equal(b.closed,1));const current=images.slice(-3);r.release();r.release();current.forEach(b=>assert.equal(b.closed,1));
 reject=true;const q=new lib.ArenaRenderer();assert.doesNotThrow(()=>paint(q,c));assert.equal(q.mode(),'SVG 0/3');c.check();
});
test('unready images log a bounded diagnostic and never hide play behind a loading modal',()=>{
 pending=true;const r=new lib.ArenaRenderer(),c=canvas(),e=new lib.ArenaEngine(),n=logs.length;
 for(let i=0;i<180;i++){c.calls.length=0;paint(r,c,e);c.check();}
 assert.equal(logs.slice(n).filter(s=>s.includes('解码未就绪')).length,3);
 assert.equal(c.calls.some(call=>call[0]==='fillText'),false);
});
console.log(`\n${passed} renderer/asset regression cases passed. Native SVG decode and presented FPS still require device QA.`);
