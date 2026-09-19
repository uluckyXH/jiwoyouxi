#!/usr/bin/env node
// Build the App first. Execute SDK-compiled ArkUI cell bindings with deterministic
// native property sinks; retained nodes behave like keyed ForEach children.
// This checks bindings and click closures, not device scheduling or GPU animation.
import assert from 'node:assert/strict';
import {readFileSync,statSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
const root=new URL('../',import.meta.url),dir='entry/src/main/ets/gamesNext/tenGarden/';
const cache='entry/build/default/cache/default/default@CompileArkTS/esmodule/release/'+dir;
const read=p=>readFileSync(new URL(p,root),'utf8');
const compile=s=>stripTypeScriptTypes(s.replace(/^import[^\n]*;\s*$/gm,'').replace(/^export /gm,'')
 .replace(/^@Observed\s*$/gm,'').replace(/@Track\s*/g,''),{mode:'transform'});
assert.ok(statSync(new URL(cache+'TenTileCell.ts',root)).mtimeMs>=statSync(new URL(dir+'TenTileCell.ets',root)).mtimeMs,
 'Rebuild the App before checking the generated bindings.');
const core=vm.runInNewContext(compile(['TenModel','TenPuzzles','TenRules','TenEngine','TenRenderTile','TenLayout','TenPalette']
 .map(n=>read(dir+n+'.ets')).join('\n'))+'\n({TenEngine,tenReconcileTiles,tenHit,TenPalette})');
class Property {
 constructor(value){this.value=value;}
 get(){return this.value;}
 set(value){this.value=value;}
 reset(value){this.value=value;}
}
let capture;
class ViewPU {
 callbacks=[];records={};
 observeComponentCreation2(fn,type){
  const run=initial=>{capture=this.records[type.name]??={};fn(0,initial);capture=undefined;};
  this.callbacks.push(run);run(true);
 }
 updateDirtyElements(){for(const run of this.callbacks)run(false);}
}
const native=name=>new Proxy({name},{get:(target,key)=>key==='name'?target.name:
 (...args)=>{if(capture&&key!=='pop')capture[key]=args;}});
const effects={combine(){return this;}};
const sdk=vm.runInNewContext(compile(read(cache+'TenTileCell.ts'))+'\n({TenTileCell})',{
 ViewPU,SynchedPropertyNesedObjectPU:Property,SynchedPropertySimpleOneWayPU:Property,SynchedPropertyObjectOneWayPU:Property,
 Button:native('Button'),Stack:native('Stack'),Image:native('Image'),Text:native('Text'),
 ButtonType:{Normal:'normal'},ImageFit:{Contain:'contain'},FontWeight:{Medium:'medium'},
 BorderStyle:{Dashed:'dashed',Solid:'solid'},TransitionEffect:{OPACITY:effects,scale:()=>effects},P:core.TenPalette
});
let frames=0,tilesChecked=0;
for(const dark of [false,true])for(const cell of [46,78]){
 const e=new core.TenEngine(2),nodes=new Map(),clicks=[];
 let views=[],firstClick;
 const gap=6,grid=cell*6+gap*5;
 function frame(){
  views=core.tenReconcileTiles(views,e.tiles());
  const ids=new Set(views.map(tile=>tile.id));
  for(const id of nodes.keys())if(!ids.has(id))nodes.delete(id);
  const selected=views.filter(tile=>tile.value===7||tile.value===1).map(tile=>tile.index);
  const hint=e.hint(),hintCells=hint&&hint.rewind===0?hint.path:[];
  for(const tile of views){
   let node=nodes.get(tile.id);
   if(!node){
    node=new sdk.TenTileCell(undefined,{tile,dark,gridSize:6,cell,gap,selected,hintCells,active:true,tap:i=>clicks.push(i)});
    node.initialRender();nodes.set(tile.id,node);
   }else{
    // ForEach preserves its original item handle; don't replace it to mask stale snapshots.
    node.dark=dark;node.cell=cell;node.selected=selected;node.hintCells=hintCells;node.rerender();
   }
   const button=node.records.Button,text=node.records.Text;
   const position=button.position[0],number=Number(text.create[0]);
   const hit=core.tenHit(position.x+cell/2,position.y+cell/2,grid,6,gap);
   assert.equal(hit,tile.index);assert.equal(e.round.ids[hit],tile.id);assert.equal(e.round.board[hit],number);
   assert.equal(button.backgroundColor[0],selected.includes(hit)?core.TenPalette.accent(dark):core.TenPalette.paper(dark));
   assert.equal(button.border[0].style,hintCells.includes(hit)&&!selected.includes(hit)?'dashed':'solid');
   assert.equal(button.border[0].color,selected.includes(hit)?core.TenPalette.accent(dark):
    hintCells.includes(hit)?core.TenPalette.gold(dark):core.TenPalette.line(dark));
   assert.equal(button.accessibilityText[0].includes('提示第'),hintCells.includes(hit));
   assert.ok(button.accessibilityText[0].includes('数字 '+number));
   button.onClick[0]();assert.equal(clicks.at(-1),hit);
   tilesChecked++;
  }
  frames++;
 }
 frame();firstClick=nodes.get(3).records.Button.onClick[0];
 for(const step of e.puzzle.solution.slice(0,2)){e.submit(step.cells);frame();}
 assert.equal(nodes.get(3).tile.index,0);firstClick();assert.equal(clicks.at(-1),0,'old click closure follows the moved tile');
 e.rewind();frame();assert.equal(nodes.get(3).tile.index,2);
 e.submit(e.puzzle.solution[1].cells);frame();
 const raw=e.serialize();assert.ok(e.restore(raw));frame();
 e.restart();frame();assert.equal(nodes.get(3).tile.index,2);
 for(const step of e.puzzle.solution){e.submit(step.cells);frame();}
 assert.equal(nodes.size,0);
}
console.log(`PASS SDK-compiled cell bindings: ${frames} frames, ${tilesChecked} visible tiles; values, positions, selection, hints, hit tests and captured clicks agree.`);
