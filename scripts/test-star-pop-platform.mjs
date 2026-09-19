#!/usr/bin/env node
// Real native adapters, with deterministic OS providers in place of a device.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
const dir = new URL('../entry/src/main/ets/gamesNext/starPop/', import.meta.url);
const source = name => readFileSync(new URL(name + '.ets', dir), 'utf8');
const clean = text => text.replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export /gm, '');
const load = (names, api, providers) => vm.runInNewContext(
  stripTypeScriptTypes(clean(names.map(source).join('\n')), {mode:'transform'}) + '\n({' + api + '})', providers);
const quiet = {warn(){}};
const settle = () => new Promise(resolve => setImmediate(resolve));
let count = 0;
async function test(name, run) {await run(); count++; console.log('PASS ' + name);}

function windowSetup() {
  const hostEvents = new Map(), displayEvents = new Map(), readings = [], orientations = [], bars = [];
  const state = {status:2,density:2,rects:[],avoidFail:false,creaseFail:false,backgrounds:0};
  const empty = {topRect:{height:0},bottomRect:{height:0},leftRect:{width:0},rightRect:{width:0}};
  const host = {
    getPreferredOrientation:()=>17, getWindowSystemBarProperties:()=>({statusBarContentColor:'#original'}),
    getWindowProperties:()=>({windowRect:{left:120,top:80,width:1600,height:1200}}),
    getWindowAvoidArea:type=>{
      if(state.avoidFail)throw Error('avoid unavailable');
      return type===0?{...empty,topRect:{height:56}}:type===1?{...empty,bottomRect:{height:40}}:empty;
    },
    on:(e,fn)=>hostEvents.set(e,fn), off:e=>hostEvents.delete(e),
    async setPreferredOrientation(value){orientations.push(value);},
    async setWindowSystemBarProperties(value){bars.push(value);}
  };
  const display = {
    isFoldable:()=>true,getFoldStatus:()=>state.status,
    getCurrentFoldCreaseRegion:()=>{if(state.creaseFail)throw Error('crease unavailable');return {creaseRects:state.rects};},
    on:(e,fn)=>displayEvents.set(e,fn),off:e=>displayEvents.delete(e)
  };
  const window = {
    getLastWindow:async()=>host,Orientation:{UNSPECIFIED:0,AUTO_ROTATION:1},
    WindowEventType:{WINDOW_HIDDEN:0,WINDOW_INACTIVE:1,WINDOW_SHOWN:2},
    AvoidAreaType:{TYPE_SYSTEM:0,TYPE_NAVIGATION_INDICATOR:1,TYPE_CUTOUT:2}
  };
  const {StarWindow} = load(['StarModel','StarLayout','StarWindow'],'StarWindow',{window,display,console:quiet});
  const observer = new StarWindow();
  return {observer,host,window,state,readings,hostEvents,displayEvents,orientations,bars,
    attach:()=>observer.attach({},px=>px/state.density,(insets,creases)=>readings.push({insets,creases}),()=>state.backgrounds++)};
}
await test('density and window offsets convert all hinge rectangles into local vp coordinates',async()=>{
  const t=windowSetup();await t.attach();
  for(const status of [3,13,21,22,23]){
    Object.assign(t.state,{status,rects:[{left:520,top:80,width:20,height:1200},{left:920,top:80,width:20,height:1200}]});
    t.displayEvents.get('foldStatusChange')();
    const latest=t.readings.at(-1);
    assert.equal(latest.creases.length,2);assert.equal(latest.creases[0].x,200);
    assert.equal(latest.creases[0].y,0);assert.equal(latest.creases[0].width,10);
    assert.equal(latest.insets.top,28);assert.equal(latest.insets.bottom,20);
  }
  t.state.density=4;t.hostEvents.get('windowSizeChange')();
  assert.equal(t.readings.at(-1).creases[0].x,100);
  for(const status of [0,1,2,11,12]){
    t.state.status=status;t.displayEvents.get('foldStatusChange')();
    assert.equal(t.readings.at(-1).creases.length,0,'cover or full-open must clear stale hinges');
  }
  const before=t.readings.length;t.displayEvents.get('change')();t.displayEvents.get('foldDisplayModeChange')();
  assert.equal(t.readings.length,before+2);t.observer.release();
});
await test('safe-area failures do not suppress hinge data, and a failed hinge read clears old data',async()=>{
  const t=windowSetup();await t.attach();
  Object.assign(t.state,{status:3,avoidFail:true,rects:[{left:120,top:680,width:1600,height:40}]});
  t.observer.measure();assert.equal(t.readings.at(-1).creases.length,1);
  t.state.avoidFail=false;t.state.creaseFail=true;t.observer.measure();
  assert.equal(t.readings.at(-1).creases.length,0);assert.equal(t.readings.at(-1).insets.top,28);
  t.observer.release();
});
await test('background callbacks, system bar restoration and all event subscriptions stop at exit',async()=>{
  const t=windowSetup();t.observer.setDark(true);await t.attach();
  assert.equal(t.orientations[0],1);assert.ok(t.bars.some(p=>p.statusBarContentColor==='#FFF2DF'));
  t.hostEvents.get('windowEvent')(0);assert.equal(t.state.backgrounds,1);
  const stale=[...t.hostEvents.values(),...t.displayEvents.values()], before=t.readings.length;
  t.observer.release();await Promise.resolve();
  assert.equal(t.hostEvents.size,0);assert.equal(t.displayEvents.size,0);
  assert.equal(t.orientations.at(-1),17);assert.equal(t.bars.at(-1).statusBarContentColor,'#original');
  stale.forEach(fn=>{fn(2);fn(0);});assert.equal(t.readings.length,before);assert.equal(t.state.backgrounds,1);
});
await test('window lookup and orientation promises resolving after exit do not revive the game',async()=>{
  const t=windowSetup();let resolveLookup;
  t.window.getLastWindow=()=>new Promise(resolve=>resolveLookup=resolve);
  const attaching=t.attach();t.observer.release();resolveLookup(t.host);await attaching;
  assert.equal(t.hostEvents.size,0);assert.equal(t.orientations.length,0);
  const r=windowSetup();let resolveOrientation;
  r.host.setPreferredOrientation=value=>{
    r.orientations.push(value);return value===1?new Promise(resolve=>resolveOrientation=resolve):Promise.resolve();
  };
  const pending=r.attach();await settle();r.observer.release();resolveOrientation();await pending;
  assert.equal(r.orientations.at(-1),17);assert.equal(r.hostEvents.size,0);assert.equal(r.readings.length,0);
});

function audioSetup() {
  let loaded;
  const state={decoded:true,playPending:undefined,releasePending:undefined};
  const plays=[],stops=[],opened=[],closed=[],pools=[];
  const pool={
    on:(name,fn)=>{if(name==='loadComplete')loaded=fn;},
    async load(id){if(state.decoded)loaded(id);return id;},
    play(id,options){plays.push({id,options});return state.playPending?state.playPending():Promise.resolve(id+100);},
    async stop(id){stops.push(id);}, async release(){pools.push('released');}
  };
  const context={resourceManager:{
    async getRawFd(path){opened.push(path);return {fd:opened.length,offset:0,length:100};},
    async closeRawFd(path){closed.push(path);}
  }};
  const media={createSoundPool:async size=>{assert.equal(size,4);return pool;}};
  const audio={StreamUsage:{STREAM_USAGE_GAME:0},AudioRendererRate:{RENDER_RATE_NORMAL:0}};
  const {StarAudio}=load(['StarModel','StarAudio'],'StarAudio',{media,audio,console:quiet});
  return {adapter:new StarAudio(),state,plays,stops,opened,closed,pools,context,pool,media,
    finishDecode:()=>{for(let i=1;i<=opened.length;i++)loaded(i);}};
}
await test('sounds wait for decode, obey global mute, throttle rapid duplicate effects and use clear volume',async()=>{
  const t=audioSetup();t.state.decoded=false;await t.adapter.init(t.context);
  assert.equal(t.opened.length,7);assert.equal(t.closed.length,0);
  t.adapter.play('tap');assert.equal(t.plays.length,0);
  t.finishDecode();t.adapter.setEnabled(false);t.adapter.play('tap');assert.equal(t.plays.length,0);
  t.adapter.setEnabled(true);t.adapter.play('tap');t.adapter.play('tap');await Promise.resolve();
  assert.equal(t.plays.length,1);assert.equal(t.plays[0].options.loop,0);
  assert.equal(t.plays[0].options.leftVolume,.9);
  t.adapter.setEnabled(false);assert.ok(t.stops.includes(101));
  await t.adapter.release();assert.equal(t.closed.length,7);assert.equal(new Set(t.closed).size,7);
  assert.equal(t.pools.length,1);t.adapter.play('end');assert.equal(t.plays.length,1);
});
await test('a play promise finishing after pause is stopped and audio creation finishing after exit is released',async()=>{
  const t=audioSetup();await t.adapter.init(t.context);let finish;
  t.state.playPending=()=>new Promise(resolve=>finish=resolve);
  t.adapter.play('pop');t.adapter.silence();finish(999);await Promise.resolve();
  assert.ok(t.stops.includes(999));await t.adapter.release();
  const r=audioSetup();let create;
  r.media.createSoundPool=()=>new Promise(resolve=>create=resolve);
  const pending=r.adapter.init(r.context);await r.adapter.release();create(r.pool);await pending;
  assert.equal(r.pools.length,1);assert.equal(r.opened.length,0);
});
await test('a raw descriptor arriving after disposal is closed without being decoded',async()=>{
  const t=audioSetup();let resolveFd;
  t.context.resourceManager.getRawFd=path=>{
    t.opened.push(path);return new Promise(resolve=>resolveFd=resolve);
  };
  const pending=t.adapter.init(t.context);await settle();await t.adapter.release();
  resolveFd({fd:1,offset:0,length:100});await pending;
  assert.equal(t.opened.length,1);assert.deepEqual(t.closed,t.opened);assert.equal(t.pools.length,1);
});

function storageSetup() {
  const state={raw:'',failRead:false,failWrite:false}, writes=[];
  const preferences={async getPreferences(_context, options){
    assert.equal(options.name,'star_pop_v1');
    return {
      async get(key){assert.equal(key,'round');if(state.failRead)throw Error('read');return state.raw;},
      async put(_key,raw){if(state.failWrite)throw Error('write');state.raw=raw;writes.push(raw);},
      async flush(){}
    };
  }};
  const {StarStorage}=load(['StarStorage'],'StarStorage',{preferences,console:quiet});
  return {adapter:new StarStorage(),state,writes};
}
await test('isolated storage serializes rapid writes and recovers its queue after a failure',async()=>{
  const t=storageSetup();
  assert.deepEqual(await Promise.all([t.adapter.save({},'one'),t.adapter.save({},'two'),t.adapter.save({},'three')]),[true,true,true]);
  assert.deepEqual(t.writes,['one','two','three']);assert.equal(await t.adapter.load({}),'three');
  t.state.failWrite=true;assert.equal(await t.adapter.save({},'failed'),false);
  t.state.failWrite=false;assert.equal(await t.adapter.save({},'retry'),true);assert.equal(await t.adapter.load({}),'retry');
});
await test('storage read failures and unexpected values are rejected without writing an empty game',async()=>{
  const t=storageSetup();t.state.raw=17;await assert.rejects(()=>t.adapter.load({}));
  t.state.failRead=true;await assert.rejects(()=>t.adapter.load({}));
  assert.equal(t.writes.length,0);
});
function perfSetup() {
  const logs=[], timers=new Map(), syncs=[];
  const state={now:10,seq:0,fail:false};
  const displaySync={create(){
    if(state.fail)throw Error('unsupported');
    const sync={running:false,callback:undefined,range:undefined,
      setExpectedFrameRateRange(range){this.range=range;},on(_name,callback){this.callback=callback;},
      off(){this.callback=undefined;},start(){this.running=true;},stop(){this.running=false;}};
    syncs.push(sync);return sync;
  }};
  const {StarPerf,starNow}=load(['StarPerf'],'StarPerf,starNow',{
    systemDateTime:{TimeType:{STARTUP:1},getUptime:()=>state.now*1000000},displaySync,
    hilog:{info(_domain,tag,_format,message){assert.equal(tag,'StarPopPerf');logs.push(message);}},
    setTimeout(fn,delay){const id=++state.seq;timers.set(id,{fn,delay});return id;},
    clearTimeout:id=>timers.delete(id)
  });
  return {perf:new StarPerf(),starNow,state,logs,timers,syncs,
    frame(ms){state.now+=ms;syncs.at(-1)?.callback?.();},
    end(){const [id,timer]=timers.entries().next().value;timers.delete(id);timer.fn();}};
}
await test('profiling samples only around actions and aggregates callback gaps without logging every frame',()=>{
  const t=perfSetup();assert.equal(t.timers.size,0);assert.equal(t.syncs.length,0);assert.equal(t.starNow(),10);
  t.perf.sample('消除');assert.equal(t.timers.size,1);assert.equal([...t.timers.values()][0].delay,600);
  assert.equal(t.syncs[0].range.expected,60);
  for(const ms of [16,16,16,60,16])t.frame(ms);
  assert.equal(t.logs.length,0,'frames must only accumulate numbers');t.end();
  assert.equal(t.timers.size,0);assert.equal(t.syncs[0].running,false);assert.equal(t.syncs[0].callback,undefined);
  assert.equal(t.logs.length,1);assert.match(t.logs[0],/间隔P95=60.00ms/);assert.match(t.logs[0],/超34ms=1/);
  assert.match(t.logs[0],/非GPU帧率/);assert.match(t.logs[0],/访问=/);
});
await test('resize or exit stops old sampling and late frame/timer callbacks cannot restart it',()=>{
  const t=perfSetup();t.perf.sample('进入');const oldFrame=t.syncs[0].callback,oldTimer=[...t.timers.values()][0].fn;
  t.frame(16);t.perf.sample('重排');const live=t.syncs[1];assert.equal(t.syncs[0].running,false);
  const before=t.logs.length;oldFrame();oldTimer();assert.equal(t.logs.length,before);assert.equal(t.timers.size,1);
  assert.equal(live.running,true);const staleFrame=live.callback,staleTimer=[...t.timers.values()][0].fn;
  t.perf.release();const released=t.logs.length;assert.equal(t.timers.size,0);assert.equal(live.running,false);
  staleFrame();staleTimer();t.perf.sample('不应复活');t.perf.event('迟到回执');
  assert.equal(t.timers.size,0);assert.equal(t.logs.length,released);assert.equal(t.syncs.length,2);
});
await test('profiling is bounded and unsupported frame providers do not add a timer loop',()=>{
  const t=perfSetup();t.perf.sample('边界');for(let i=0;i<200;i++)t.frame(1);t.end();
  assert.match(t.logs[0],/间隔数=120/);t.state.fail=true;t.perf.sample('不可用');
  assert.equal(t.timers.size,0);assert.ok(t.logs.some(line=>line.includes('帧采样不可用')));
});
await test('normal saves and blocked taps are rate-limited, but slow operations and failures are retained',()=>{
  const t=perfSetup();for(let i=0;i<9;i++){t.perf.saved(0,true,0);t.perf.inputBlocked('动画');}
  assert.equal(t.logs.length,2);t.perf.saved(0,true,0);t.perf.inputBlocked('动画');assert.equal(t.logs.length,4);
  t.state.now=210;t.perf.saved(0,true,1);assert.match(t.logs.at(-1),/含排队及成就=210.00ms/);
  t.perf.saved(210,false,1);assert.match(t.logs.at(-1),/成功=false/);
  const before=t.logs.length;t.perf.animationDelay(100,110);assert.equal(t.logs.length,before);
  t.perf.animationDelay(60,110);assert.match(t.logs.at(-1),/超时=40.00ms/);
});
console.log('\nStar Pop: ' + count + ' platform adapter groups passed; physical-device behavior remains manual QA.');
