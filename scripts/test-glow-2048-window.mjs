#!/usr/bin/env node
// Exercise the actual window observer against deterministic platform events.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';
const root = resolve(import.meta.dirname, '..');
const folder = 'entry/src/main/ets/gamesNext/glow2048/';
const source = ['GlowLayout.ets','GlowWindow.ets'].map(file => readFileSync(resolve(root,folder,file),'utf8')).join('\n')
  .replace(/^import[\s\S]*?;\s*$/gm,'').replace(/^export /gm,'');
function setup() {
  const hostEvents = new Map(), displayEvents = new Map(), readings = [];
  let status=2, density=2, rects=[], avoidFailure=false, creaseFailure=false, background=0;
  const rect = { left:120, top:80, width:1600, height:1200 };
  const empty = { topRect:{height:0},bottomRect:{height:0},leftRect:{width:0},rightRect:{width:0} };
  const host = {
    getPreferredOrientation: () => 17,
    getWindowSystemBarProperties: () => ({statusBarContentColor:'#123456'}),
    getWindowProperties: () => ({windowRect:rect}),
    getWindowAvoidArea: type => {
      if(avoidFailure) throw Error('avoid area unavailable');
      return type===0 ? {...empty,topRect:{height:56}} : type===1 ? {...empty,bottomRect:{height:40}} : empty;
    },
    on: (event,callback) => hostEvents.set(event,callback),
    off: (event,callback) => { assert.equal(hostEvents.get(event),callback);hostEvents.delete(event); },
    setPreferredOrientation: async () => {},
    setWindowSystemBarProperties: async () => {}
  };
  const display = {
    isFoldable: () => true, getFoldStatus: () => status,
    getCurrentFoldCreaseRegion: () => { if(creaseFailure) throw Error('crease unavailable'); return {creaseRects:rects}; },
    on: (event,callback) => displayEvents.set(event,callback),
    off: (event,callback) => { assert.equal(displayEvents.get(event),callback);displayEvents.delete(event); }
  };
  const sandbox = { console:{warn:()=>{}}, display, window:{
    Orientation:{UNSPECIFIED:0,AUTO_ROTATION:1},
    WindowEventType:{WINDOW_HIDDEN:0,WINDOW_INACTIVE:1,WINDOW_SHOWN:2},
    AvoidAreaType:{TYPE_SYSTEM:0,TYPE_NAVIGATION_INDICATOR:1,TYPE_CUTOUT:2},
    getLastWindow:async()=>host
  }};
  vm.createContext(sandbox);
  vm.runInContext(stripTypeScriptTypes(source,{mode:'transform'})+'\nglobalThis.Observer=GlowWindow;',sandbox);
  const observer = new sandbox.Observer();
  return {
    observer, hostEvents, displayEvents, readings, sandbox,
    attach: () => observer.attach({},px=>px/density,(insets,creases)=>readings.push(JSON.parse(JSON.stringify({insets,creases}))),()=>background++),
    set: values => {
      status=values.status??status; density=values.density??density; rects=values.rects??rects;
      avoidFailure=values.avoidFailure??avoidFailure; creaseFailure=values.creaseFailure??creaseFailure;
    },
    background:()=>background
  };
}
let passed=0;
async function test(name,run){await run();passed++;console.log(`PASS ${name}`);}
await test('window_size_display_mode_and_density_events_refresh_local_coordinates',async()=>{
  const t=setup();await t.attach();
  assert.deepEqual([...t.hostEvents.keys()].sort(),['avoidAreaChange','windowEvent','windowSizeChange']);
  assert.deepEqual([...t.displayEvents.keys()].sort(),['change','foldDisplayModeChange','foldStatusChange']);
  t.set({status:3,rects:[{left:120,top:680,width:1600,height:40}]});
  t.displayEvents.get('foldStatusChange')();
  assert.deepEqual(t.readings.at(-1),{insets:{top:28,bottom:20,left:0,right:0},creases:[{x:0,y:300,width:800,height:20}]});
  t.set({density:4});t.hostEvents.get('windowSizeChange')();
  assert.equal(t.readings.at(-1).creases[0].y,150);
  assert.equal(t.readings.at(-1).insets.top,14);
  const count=t.readings.length;
  t.displayEvents.get('change')();t.displayEvents.get('foldDisplayModeChange')();
  assert.equal(t.readings.length,count+2);
});
await test('every_half_fold_hinge_is_read_and_opening_or_closing_clears_old_hinges',async()=>{
  const t=setup();await t.attach();
  for(const status of [3,13,21,22,23]){
    t.set({status,rects:[{left:520,top:80,width:20,height:1200},{left:920,top:80,width:20,height:1200}]});
    t.displayEvents.get('foldStatusChange')();
    assert.equal(t.readings.at(-1).creases.length,2);
  }
  for(const status of [0,1,2,11,12]){
    t.set({status});t.displayEvents.get('foldStatusChange')();
    assert.deepEqual(t.readings.at(-1).creases,[]);
  }
});
await test('unavailable_safe_area_does_not_suppress_hinges_and_failed_hinges_do_not_linger',async()=>{
  const t=setup();await t.attach();
  t.set({status:3,rects:[{left:120,top:680,width:1600,height:40}],avoidFailure:true});
  t.observer.measure();assert.equal(t.readings.at(-1).creases.length,1);
  t.set({avoidFailure:false,creaseFailure:true});
  t.observer.measure();assert.deepEqual(t.readings.at(-1).creases,[]);
  assert.equal(t.readings.at(-1).insets.top,28);
});
await test('background_notifications_and_listener_cleanup_remain_scoped_to_the_game',async()=>{
  const t=setup();await t.attach();
  t.hostEvents.get('windowEvent')(0);assert.equal(t.background(),1);
  const stale=[...t.hostEvents.values(),...t.displayEvents.values()];
  const count=t.readings.length;t.observer.release();
  assert.equal(t.hostEvents.size,0);assert.equal(t.displayEvents.size,0);
  stale.forEach(callback=>{callback(2);callback(0);});t.observer.measure();
  assert.equal(t.background(),1);
  assert.equal(t.readings.length,count);
});
await test('late_window_attachment_after_exit_installs_no_listeners',async()=>{
  const t=setup();let resolveWindow;
  t.sandbox.window.getLastWindow=()=>new Promise(resolve=>resolveWindow=resolve);
  const pending=t.attach();t.observer.release();resolveWindow({});await pending;
  assert.equal(t.hostEvents.size,0);assert.equal(t.displayEvents.size,0);assert.equal(t.readings.length,0);
});
console.log(`\n${passed} window-observer cases passed. Hardware crease reporting still needs device verification.`);
