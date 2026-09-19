#!/usr/bin/env node
// Execute the actual adapters with fake native window/display/SoundPool providers.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
const dir=new URL('../entry/src/main/ets/gamesNext/tangramGarden/',import.meta.url);
const source=n=>readFileSync(new URL(n+'.ets',dir),'utf8');
const clean=s=>s.replace(/^import[\s\S]*?;\s*$/gm,'').replace(/^export /gm,'');
const noop=()=>{};
const orientation={UNSPECIFIED:0,AUTO_ROTATION:1,PORTRAIT:2};
let posture=3,avoidFails=false,rect={left:350,top:70,width:3850,height:2975};
const displayEvents=new Map(),windowEvents=new Map();let orientations=[],bars=[];
const zero={left:0,top:0,width:0,height:0};
const host={getPreferredOrientation:()=>2,getWindowSystemBarProperties:()=>({statusBarContentColor:'#old'}),
 on:(e,fn)=>windowEvents.set(e,fn),off:e=>windowEvents.delete(e),async setPreferredOrientation(o){orientations.push(o);},async setWindowSystemBarProperties(p){bars.push(p);},
 getWindowAvoidArea(){if(avoidFails)throw Error('not available');return {topRect:{...zero,height:84},bottomRect:{...zero,height:70},leftRect:zero,rightRect:zero};},getWindowProperties:()=>({windowRect:rect})};
const window={Orientation:orientation,WindowEventType:{WINDOW_HIDDEN:0,WINDOW_INACTIVE:1,WINDOW_SHOWN:2},AvoidAreaType:{TYPE_SYSTEM:0,TYPE_NAVIGATION_INDICATOR:1,TYPE_CUTOUT:2},getLastWindow:async()=>host};
const display={on:(e,f)=>displayEvents.set(e,f),off:e=>displayEvents.delete(e),isFoldable:()=>true,getFoldStatus:()=>posture,
 getCurrentFoldCreaseRegion:()=>({creaseRects:[{left:2222.5,top:70,width:105,height:2975}]})};
const {TangramWindow}=vm.runInNewContext(stripTypeScriptTypes(clean(source('TangramLayout')+'\n'+source('TangramWindow')))+';({TangramWindow})',{window,display,console:{warn:noop}});
let count=0;async function test(name,fn){await fn();console.log(`PASS ${++count}: ${name}`);}
await test('window adapter converts density and offset hinges; folded cover clears old hinge',async()=>{const adapter=new TangramWindow(),seen=[];await adapter.attach({},x=>x/3.5,(insets,creases)=>seen.push({insets,creases}),noop);assert.equal(seen.at(-1).insets.top,24);assert.equal(seen.at(-1).creases[0].x,535);assert.equal(seen.at(-1).creases[0].width,30);posture=2;displayEvents.get('foldStatusChange')();assert.equal(seen.at(-1).creases.length,0);adapter.release();});
await test('safe-area API failure does not suppress hinge data; background callback is delivered',async()=>{posture=3;avoidFails=true;let backgrounds=0,latest;const adapter=new TangramWindow();await adapter.attach({},x=>x/3.5,(insets,creases)=>latest={insets,creases},()=>backgrounds++);assert.equal(latest.creases.length,1);windowEvents.get('windowEvent')(window.WindowEventType.WINDOW_HIDDEN);assert.equal(backgrounds,1);adapter.release();avoidFails=false;});
await test('theme/system bars, preferred orientation and all native listeners restore on exit',async()=>{orientations=[];bars=[];const adapter=new TangramWindow();adapter.setDark(true);await adapter.attach({},x=>x,noop,noop);assert.equal(orientations[0],orientation.AUTO_ROTATION);assert.ok(bars.some(p=>p.statusBarContentColor==='#FFF2DF'));adapter.release();await Promise.resolve();assert.equal(orientations.at(-1),orientation.PORTRAIT);assert.equal(bars.at(-1).statusBarContentColor,'#old');assert.equal(displayEvents.size,0);assert.equal(windowEvents.size,0);});
await test('route disposed before window lookup resolves never registers listeners or changes orientation',async()=>{let resolve;const wait=new Promise(r=>resolve=r);window.getLastWindow=()=>wait;orientations=[];const adapter=new TangramWindow(),pending=adapter.attach({},x=>x,noop,noop);adapter.release();resolve(host);await pending;assert.equal(orientations.length,0);assert.equal(windowEvents.size,0);window.getLastWindow=async()=>host;});
let loadComplete,plays=[],stops=[],open=[],closed=[],released=0,decode=true,playResolve;
const pool={on:(name,fn)=>{if(name==='loadComplete')loadComplete=fn;},async load(fd){if(decode)loadComplete(fd);return fd;},play(id,opts){plays.push({id,opts});return playResolve?new Promise(r=>playResolve(r)):Promise.resolve(id+100);},async stop(id){stops.push(id);},async release(){released++;}};
const context={resourceManager:{async getRawFd(path){open.push(path);return{fd:open.length,offset:0,length:200};},async closeRawFd(path){closed.push(path);}}};
const media={createSoundPool:async()=>pool};const audio={StreamUsage:{STREAM_USAGE_GAME:0},AudioRendererRate:{RENDER_RATE_NORMAL:0}};
const {TangramAudio}=vm.runInNewContext(stripTypeScriptTypes(clean(source('TangramAudio')))+';({TangramAudio})',{media,audio,console:{warn:noop}});
await test('audio waits for decode, respects master mute, throttles duplicate sounds and closes raw descriptors',async()=>{decode=false;const a=new TangramAudio();await a.init(context);a.play('pick');assert.equal(plays.length,0);for(let i=1;i<=6;i++)loadComplete(i);a.setEnabled(false);a.play('pick');assert.equal(plays.length,0);a.setEnabled(true);a.play('pick');a.play('pick');await Promise.resolve();assert.equal(plays.length,1);assert.equal(plays[0].opts.loop,0);a.setEnabled(false);assert.ok(stops.includes(101));await a.release();assert.equal(closed.length,6);assert.equal(released,1);});
await test('audio play resolving after background silence is stopped rather than leaking a late sound',async()=>{decode=true;let resolve;playResolve=r=>resolve=r;const a=new TangramAudio();await a.init(context);a.play('win');a.silence();resolve(999);await Promise.resolve();assert.ok(stops.includes(999));await a.release();playResolve=undefined;});
console.log(`\n${count} tangram device-window/audio adapter groups passed.`);
