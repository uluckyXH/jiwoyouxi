#!/usr/bin/env node
// Execute SDK-generated parent bindings with tracked property reads. Unlike a
// direct active() call, this catches a child left disabled after a plain field changes.
import assert from 'node:assert/strict';
import {readFileSync,statSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
const root=new URL('../',import.meta.url),dir='entry/src/main/ets/gamesNext/tenGarden/';
const cache='entry/build/default/cache/default/default@CompileArkTS/esmodule/release/'+dir;
const read=p=>readFileSync(new URL(p,root),'utf8');
const compile=s=>stripTypeScriptTypes(s.replace(/^import[^\n]*;\s*$/gm,'').replace(/^export /gm,'')
 .replace(/^@Observed\s*$/gm,'').replace(/@Track\s*/g,''),{mode:'transform'});
assert.ok(statSync(new URL(cache+'TenPage.ts',root)).mtimeMs>=statSync(new URL(dir+'TenPage.ets',root)).mtimeMs,
 'Rebuild the App before testing its generated parent bindings.');
const names='TenEngine,TenGesture,tenLayout,tenReconcileTiles,tenEqual,tenSelect,tenStart,tenSum,tenProfile';
const core=vm.runInNewContext(compile(['TenModel','TenPuzzles','TenRules','TenEngine','TenGesture','TenLayout','TenRenderTile']
 .map(n=>read(dir+n+'.ets')).join('\n'))+'\n({'+names+'})');
let current,sequence=0;
const dirty=new Set();
class Property {
 constructor(value){this.value=value;this.readers=new Set();}
 get(){if(current){this.readers.add(current);current.properties.add(this);}return this.value;}
 set(value){if(Object.is(this.value,value))return;this.value=value;for(const reader of this.readers)dirty.add(reader);}
 reset(value){this.set(value);}
}
class ViewPU {
 children=new Map();
 declareWatch(){}
 observeComponentCreation2(fn){
  const record={id:++sequence,properties:new Set(),run(initial){
   for(const p of this.properties)p.readers.delete(this);this.properties.clear();
   current=this;try{fn(this.id,initial);}finally{current=undefined;}
  }};
  record.run(true);
 }
 static create(){}
 updateStateVarsOfChildByElmtId(id,params){Object.assign(this.children.get(id).params,params);}
 updateDirtyElements(){let rounds=0;while(dirty.size){assert.ok(++rounds<100);const jobs=[...dirty];dirty.clear();for(const job of jobs)job.run(false);}}
}
const child=name=>class {
 constructor(parent,params,_local,id){this.name=name;this.params=params;parent.children.set(id,this);}
};
const native=new Proxy({}, {get:()=>()=>{}}),timers=new Map();
class Ports {play(){}silence(){}release(){}}
const touchTypes={Down:0,Up:1,Move:2,Cancel:3};
const sdk=vm.runInNewContext(compile(read(cache+'TenPage.ts'))+'\n({TenPage})',{
 ...core,ViewPU,ObservedPropertySimplePU:Property,ObservedPropertyObjectPU:Property,
 SynchedPropertySimpleOneWayPU:Property,SynchedPropertyObjectOneWayPU:Property,
 TenStats:child('stats'),TenBoard:child('board'),TenSelection:child('selection'),TenTools:child('tools'),
 Stack:native,__Common__:native,Alignment:{TopStart:0},Curve:{EaseOut:0},TouchType:touchTypes,
 TenAudio:Ports,TenStorage:Ports,TenWindow:Ports,Scroller:Ports,
 setTimeout:fn=>{const id=++sequence;timers.set(id,fn);return id;},clearTimeout:id=>timers.delete(id)
});
function page(){
 dirty.clear();timers.clear();const p=new sdk.TenPage(undefined,{});
 p.loaded=true;p.dialog='';p.sync();p.Note=()=>{};
 p.getUIContext=()=>({animateTo:(_opts,fn)=>fn()});p.PlayArea();
 return p;
}
const state=(p,name)=>[...p.children.values()].find(c=>c.name===name).params;
function touch(p,type,index){
 const point={id:1,x:index%p.gridSize*(p.layout.cell+p.layout.tileGap)+p.layout.cell/2,
  y:Math.floor(index/p.gridSize)*(p.layout.cell+p.layout.tileGap)+p.layout.cell/2};
 p.touch({type,touches:type===touchTypes.Up?[]:[point],changedTouches:[point]});p.rerender();
}
function finish(p){for(const [id,fn] of [...timers]){timers.delete(id);fn();}p.rerender();}
for(const release of ['early','late','cancel']){
 const p=page();assert.equal(state(p,'tools').active,true);
 touch(p,touchTypes.Down,3);touch(p,touchTypes.Move,4);
 assert.equal(state(p,'tools').active,false);assert.equal(p.engine.round.history.length,1);
 if(release==='early')touch(p,touchTypes.Up,4);
 finish(p);
 if(release!=='early'){
  assert.equal(state(p,'tools').active,false,'held finger must not start a new move');
  touch(p,release==='cancel'?touchTypes.Cancel:touchTypes.Up,4);
 }
 assert.equal(p.active(),true);
 assert.equal(state(p,'tools').active,true,release+': rendered undo, hint and more must react to finger release');
 assert.equal(state(p,'board').active,true);
 state(p,'tools').undo();p.rerender();finish(p);assert.equal(p.engine.round.history.length,0);
 state(p,'tools').hint();p.rerender();assert.deepEqual(Array.from(p.hintCells),[3,4]);
}
console.log('PASS SDK-generated parent bindings: undo, hints and menu recover after early/late release and touch cancellation.');
