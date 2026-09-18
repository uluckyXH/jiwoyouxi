#!/usr/bin/env node
// Run actual page methods against a deterministic clock/native-adapter doubles.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
const base = new URL('../entry/src/main/ets/gamesNext/blockWorkshop/', import.meta.url);
const page = readFileSync(new URL('BlockWorkshopPage.ets', base), 'utf8');
function method(name) {
  const match = new RegExp(`^  private (?:async )?${name}\\(`, 'm').exec(page);
  assert.ok(match, `method ${name}`);
  let start = page.indexOf('{', match.index), depth = 1, end = start + 1;
  for (; depth && end < page.length; end++) {
    if (page[end] === '{') depth++;
    if (page[end] === '}') depth--;
  }
  assert.equal(depth, 0);
  return page.slice(match.index, end);
}
const names = ['boot','now','playing','step','schedule','action','startHold','repeat','endHold','cancelHold',
  'stop','flush','sync','paint','pause','resume','restart','showHelp','closeHelp','exitRequested','windowChanged','relayout','save',
  'saveAndExit','milestones','finish','report'];
const logic = ['BlockModel.ets','BlockEngine.ets','BlockLayout.ets','BlockRenderer.ets']
  .map(name => readFileSync(new URL(name, base), 'utf8')).join('\n');
const harness = `class PageHarness {
  constructor() {
    this.engine = new BlockEngine(42); this.ready = true; this.disposed = false; this.loaded = true;
    this.dialog = ''; this.pageWidth = 390; this.pageHeight = 844;
    this.insets = {top:24,bottom:16,left:0,right:0}; this.crease={x:0,y:0,width:0,height:0};
    this.fold={foldable:false,status:0};
    this.viewport=blockLayout(this.pageWidth,this.pageHeight,this.insets);
    this.timer=-1; this.repeatTimer=-1; this.held=''; this.lastTick=0; this.lastSave=0;
    this.canvasReady=true; this.canvas={}; this.dark=false; this.bestScore=0;
    this.paints=0; this.saves=[]; this.exits=0; this.saving=false; this.saveFailed=false;
    this.sounds={play:()=>{},silence:()=>{}};
    this.renderer={paint:()=>{this.paints++;return true;},invalidate:()=>{}};
    this.performance={logic:()=>{},paint:()=>{},report:()=>{},reset:()=>{}};
    this.context={}; this.storage={load:async()=>'', save:async(_context,raw)=>{this.saves.push(raw);return true;}};
    this.exitToHub=()=>{this.exits++;}; this.scores=[]; this.achievements=[];
    this.recordScore=score=>this.scores.push(score);
    this.reportAchievementEvent=event=>this.achievements.push(event);
  }
  ${names.map(method).join('\n')}
}
globalThis.createPage=()=>new PageHarness();
globalThis.createEngine=seed=>new BlockEngine(seed);
globalThis.createRenderer=()=>new BlockRenderer();
`;
let now = 0, seq = 0;
const timers = new Map();
const context = { console, Date,
  setTimeout: (fn, delay) => { const id = ++seq; timers.set(id, {fn, due:now+delay}); return id; },
  clearTimeout: id => timers.delete(id),
  systemDateTime: {TimeType:{STARTUP:0},getUptime:()=>now*1e6}
};
vm.runInNewContext(stripTypeScriptTypes((logic+'\n'+harness).replace(/^import[\s\S]*?;\s*$/gm,'')
  .replace(/^export /gm,''),{mode:'transform'}),context);
function tick(ms) {
  const target=now+ms;
  for (let budget=0; budget<10000; budget++) {
    const first=[...timers.entries()].sort((a,b)=>a[1].due-b[1].due)[0];
    if (!first || first[1].due>target) { now=target; return; }
    now=first[1].due; timers.delete(first[0]); first[1].fn();
  }
  throw new Error('timer loop');
}
function fresh() { timers.clear();now=0;return context.createPage(); }
{
  const p=fresh(); p.resume();
  const y=p.engine.round.piece.y;
  tick(700); assert.equal(p.engine.round.piece.y,y+1);
  assert.equal(timers.size,1,'only one game clock');
  const x=p.engine.round.piece.x;
  p.startHold('left'); assert.equal(p.engine.round.piece.x,x-1);
  tick(179); assert.equal(p.engine.round.piece.x,x-1);
  tick(1); assert.equal(p.engine.round.piece.x,x-2);
  p.endHold('right'); assert.equal(p.held,'left','unrelated finger-up does not cancel current key');
  p.endHold('left'); assert.equal(timers.size,1);
  const saved=p.engine.serialize(); tick(60); assert.equal(p.engine.round.piece.x,JSON.parse(saved).piece.x);
  console.log('PASS one clock, immediate response, delayed repeat and matching release');
}
{
  const p=fresh();p.resume();p.startHold('down');
  const queued=[...timers.values()].map(t=>t.fn);
  p.pause();assert.equal(timers.size,0);assert.equal(p.held,'');
  const state=p.engine.serialize();tick(30000);queued.forEach(fn=>fn());
  assert.equal(p.engine.serialize(),state);assert.equal(timers.size,0);
  p.resume();tick(10);assert.ok(p.engine.round.elapsed-JSON.parse(state).elapsed<20);
  console.log('PASS pause cancels both timers, ignores queued work and never replays background time');
}
{
  const p=fresh();p.resume();p.startHold('left');
  p.crease={x:0,y:415,width:390,height:14};p.relayout();
  assert.equal(p.viewport.limited,true);assert.equal(p.dialog,'paused');assert.equal(timers.size,0);
  const state=p.engine.serialize();p.action('drop');p.resume();tick(1000);assert.equal(p.engine.serialize(),state);
  p.crease={x:0,y:0,width:0,height:0};p.relayout();
  assert.equal(p.viewport.limited,false);assert.equal(p.dialog,'paused');assert.equal(timers.size,0);
  p.resume();assert.equal(timers.size,1);
  p.pageWidth=1000;p.pageHeight=1100;p.relayout();p.startHold('left');
  p.crease={x:0,y:520,width:1000,height:20};p.relayout();
  assert.equal(p.viewport.limited,false);assert.equal(p.dialog,'');assert.equal(p.held,'');
  assert.equal(timers.size,1,'roomy fold keeps the game clock but cancels held input');
  console.log('PASS tiny fold pane pauses without data loss and unfolding needs explicit resume');
}
{
  const p=fresh(); p.resume();p.showHelp();
  assert.equal(p.dialog,'help');assert.equal(p.helpReturn,'paused');assert.equal(timers.size,0);
  const before=p.engine.serialize();p.action('drop');assert.equal(p.engine.serialize(),before);
  p.engine.round.best=1234;p.restart();assert.equal(p.engine.round.best,1234);assert.equal(p.engine.round.score,0);
  assert.equal(p.dialog,'');assert.equal(timers.size,1);
  console.log('PASS help freezes input and restart retains best score with only one new timer');
}
{
  for (const status of [1,2,3,11,12,13,21,22,23]) {
    const p=fresh();p.resume();p.startHold('down');
    p.windowChanged(p.insets,p.crease,{foldable:true,status});
    assert.equal(p.viewport.limited,false);assert.equal(p.viewport.unfold,false);
    assert.equal(p.dialog,'');assert.equal(p.held,'');assert.equal(timers.size,1);
    const elapsed=p.engine.round.elapsed;tick(700);
    assert.ok(p.engine.round.elapsed>elapsed,'a phone-sized folded display keeps playing');
    p.startHold('down');
    const queued=[...timers.values()].map(t=>t.fn);
    p.pageWidth=250;p.relayout();
    assert.equal(p.viewport.limited,true);
    assert.equal(p.viewport.unfold,![1,11].includes(status));
    assert.equal(p.dialog,'paused');assert.equal(p.held,'');assert.equal(timers.size,0);
    const state=p.engine.serialize();p.action('drop');p.resume();queued.forEach(fn=>fn());tick(5000);
    assert.equal(p.engine.serialize(),state,'an undersized window blocks input and queued ticks');
    p.pageWidth=390;p.relayout();assert.equal(p.viewport.limited,false);
    assert.equal(p.dialog,'paused');assert.equal(timers.size,0);
    p.resume();assert.equal(timers.size,1);
  }
  console.log('PASS phone-sized folds remain playable; only undersized windows pause and require manual resume');
}
{
  const p=fresh();p.resume();p.showHelp();const state=p.engine.serialize();
  p.fold={foldable:true,status:3};p.crease={x:0,y:420,width:390,height:0};p.relayout();
  assert.equal(p.dialog,'help');assert.equal(p.viewport.unfold,true);assert.equal(timers.size,0);
  p.fold.status=1;p.crease={x:0,y:0,width:0,height:0};p.relayout();
  assert.equal(p.dialog,'help');p.exitRequested();assert.equal(p.dialog,'paused');
  assert.equal(p.engine.serialize(),state);assert.equal(timers.size,0);
  console.log('PASS folding a help sheet retains the sheet, then returns to a paused board');
}
{
  const p=fresh();p.dialog='loading';p.ready=false;p.loaded=false;
  let resolve;p.storage.load=()=>new Promise(done=>{resolve=done;});
  const task=p.boot();p.fold={foldable:true,status:2};p.relayout();resolve('');await task;
  assert.equal(p.viewport.limited,false);assert.equal(p.dialog,'ready');assert.equal(timers.size,0);
  p.resume();assert.equal(timers.size,1);
  const q=fresh();q.dialog='loading';q.ready=false;q.loaded=false;
  let complete;q.storage.load=()=>new Promise(done=>{complete=done;});
  const loading=q.boot();q.pageWidth=250;q.fold={foldable:true,status:12};q.relayout();complete('');await loading;
  assert.equal(q.viewport.unfold,true);assert.equal(q.dialog,'ready');q.resume();assert.equal(timers.size,0);
  q.pageWidth=390;q.relayout();
  assert.equal(q.fold.status,12,'resizing is sufficient; full expansion is not required');
  assert.equal(q.dialog,'ready');assert.equal(timers.size,0);q.resume();assert.equal(timers.size,1);
  console.log('PASS folded startup permits a phone-sized window and gates only an undersized one during loading');
}
{
  const p=fresh(); p.dialog='loading';p.ready=false;p.loaded=false;
  let loaded; p.storage.load=()=>new Promise(resolve=>{loaded=resolve;});
  const task=p.boot(); p.pause(); loaded('');await task;
  assert.equal(p.dialog,'ready');assert.equal(timers.size,0);
  const saved=p.engine.serialize(); const q=fresh(); q.dialog='loading';q.loaded=false;q.ready=false;
  q.storage.load=async()=>saved;await q.boot();assert.equal(q.dialog,'paused');assert.equal(timers.size,0);
  console.log('PASS fresh and restored sessions cannot start moving during async loading');
}
{
  const p=fresh();p.engine.command('drop');p.resume();
  p.pause();await Promise.resolve();
  let complete;p.storage.save=()=>new Promise(resolve=>{complete=resolve;});
  const out=p.saveAndExit();assert.equal(p.saving,true);assert.equal(p.exits,0);
  await p.saveAndExit();assert.equal(p.exits,0);complete(false);await out;
  assert.equal(p.saving,false);assert.equal(p.saveFailed,true);assert.equal(p.exits,0);
  p.storage.save=async()=>true;await p.saveAndExit();assert.equal(p.exits,1);
  console.log('PASS failed exit save stays in game, retry exits only after save success');
}
{
  const p=fresh();p.resume();
  p.engine.round.maxClear=4;p.engine.round.lines=40;p.engine.round.level=3;
  p.milestones();p.milestones();assert.equal(p.achievements.length,3);
  p.engine.round.phase='over';p.engine.round.score=700;p.engine.round.best=700;p.finish();p.finish();
  assert.equal(p.scores.join(','),'700');assert.equal(p.achievements.length,4);
  assert.equal(p.achievements[3].gameId,'tetris');assert.equal(p.achievements[3].type,'sessionEnd');
  assert.equal(timers.size,0);
  const raw=p.engine.serialize();const q=fresh();q.storage.load=async()=>raw;await q.boot();
  assert.equal(q.dialog,'over');assert.equal(q.scores.length,0);assert.equal(q.achievements.length,0);
  console.log('PASS milestones, score and result report once across repeated finish and reload');
}
{
  const p=fresh();p.resume();p.startHold('left');const callbacks=[...timers.values()].map(t=>t.fn);
  p.disposed=true;p.stop();const raw=p.engine.serialize();const draws=p.paints;
  callbacks.forEach(fn=>fn());assert.equal(p.engine.serialize(),raw);assert.equal(p.paints,draws);assert.equal(timers.size,0);
  console.log('PASS route disposal cancels input and queued drawing');
}
{
  const calls=[];const ctx=new Proxy({globalAlpha:1},{get:(target,key)=>key in target?target[key]:(...args)=>calls.push([key,...args])});
  const r=context.createRenderer(),e=context.createEngine(12);
  assert.equal(r.paint(ctx,e,250,false),true);const count=calls.length;
  for(let i=0;i<100;i++)assert.equal(r.paint(ctx,e,250,false),false);
  assert.equal(calls.length,count,'no Canvas submissions for an unchanged board');
  e.command('left');assert.equal(r.paint(ctx,e,250,false),true);
  assert.equal(r.paint(ctx,e,250,true),true);assert.equal(r.paint(ctx,e,300,true),true);
  e.round.phase='clearing';e.round.clearLeft=80;e.round.clearing=[21];e.round.lastClear=4;e.revision++;
  assert.equal(r.paint(ctx,e,300,true),true);assert.equal(ctx.globalAlpha,1);
  assert.ok(calls.length<2500,'bounded small-grid drawing, including overlays');
  assert.ok(calls.filter(call=>['fillRect','strokeRect'].includes(call[0])).every(call=>call.slice(1).every(Number.isFinite)));
  console.log('PASS unchanged board draws nothing, changes/theme/resize draw once, alpha is restored');
}
console.log('\n12 lifecycle/render cases passed; native gesture dispatch/audio/GPU behavior remain device checks.');
