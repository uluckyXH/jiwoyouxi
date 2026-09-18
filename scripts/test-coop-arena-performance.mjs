#!/usr/bin/env node
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
const base=new URL('../entry/src/main/ets/gamesNext/coopArena/',import.meta.url);
const src=['ArenaModel.ets','ArenaGuide.ets','ArenaEngine.ets','ArenaPerformance.ets'].map(f=>readFileSync(new URL(f,base),'utf8'))
 .join('\n').replace(/^import[\s\S]*?;\s*$/gm,'').replace(/^export /gm,'');
const logs=[];
const lib=vm.runInNewContext(stripTypeScriptTypes(src,{mode:'transform'})+'\n({ArenaEngine,ArenaPerformance,arenaDefaultConfig,arenaSceneLabel,arenaLiveNotice})',
 {hilog:{info:(_domain,tag,_format,text)=>{assert.equal(tag,'CoopArenaPerf');logs.push(text);}}});
const scene={session:'arena-test',label:'据点争夺 / 花盆迷阵',seed:789,initial:'20/20/20',window:'390×844',board:366,density:3.5,fold:2,dark:false,reduced:false,sound:true};
function frame(at,patch={}){
 return {at,interval:20,logic:1,paint:1,total:3,save:.2,steps:1,checks:100,scans:30,dropped:0,count:60,seed:789,
  hud:.4,hudChanged:false,clock:'DisplaySync',sprites:'SVG 3/3',audio:.1,elapsed:at/1000,rock:20,scissors:20,cloth:20,
  effects:2,conversions:12,contacts:20,crowding:8,sampled:0,grid:0,seek:0,move:0,contact:0,rules:0,...patch};
}
const plain=r=>{const result=JSON.parse(JSON.stringify(r));delete result.session;return result;};
let passed=0;
function test(name,run){logs.length=0;run();passed++;console.log(`PASS ${name}`);}
test('phase sampling does not change a dense round, random choices or saved results',()=>{
 const config={...lib.arenaDefaultConfig(),mode:'zones',counts:[20,20,20],event:'garden',seed:37827};
 const a=new lib.ArenaEngine(config),b=new lib.ArenaEngine(config);let now=0,reads=0;
 const clock=()=>{reads++;now+=.01;return now;};
 for(let i=1;i<=1200;i++){
  const ms=i%17===0?40:16;a.advance(ms);b.advance(ms,i%11===0?clock:undefined);
  if(i%11!==0){assert.equal(b.timing.steps,0);assert.equal(b.timing.contact,0);}
 }
 assert.ok(reads>0&&reads<1200);assert.deepEqual(plain(a.round),plain(b.round));
 assert.equal(a.contacts,b.contacts);assert.equal(a.crowding,b.crowding);
});
test('sampled catch-up steps aggregate once; zero-step callbacks never repeat old phase costs',()=>{
 const e=new lib.ArenaEngine();let now=0;
 assert.equal(e.advance(50,()=>{now+=1;return now;}),3);assert.equal(e.timing.steps,3);
 for(const part of ['grid','seek','move','contact','rules'])assert.equal(e.timing[part],3);
 e.advance(0,()=>{throw Error('clock should not be read');});assert.equal(e.timing.steps,0);assert.equal(e.timing.seek,0);
 e.advance(1,()=>{throw Error('there is no simulation step yet');});assert.equal(e.timing.steps,0);
});
test('dense-scene logs aggregate correct FPS, phase denominators and bounded line sizes',()=>{
 const p=new lib.ArenaPerformance();p.begin(0,scene);
 for(let i=1;i<=250;i++)p.frame(frame(i*20,{count:i<101?24:60,hudChanged:i%5===0,
  sampled:i%11===0?1:0,grid:i%11===0?.1:0,seek:i%11===0?.2:0,move:i%11===0?.3:0,contact:i%11===0?.4:0,rules:i%11===0?.5:0}));
 assert.equal(logs.length,4,'one context and three periodic lines, never one per unit');
 assert.match(logs[0],/密度=3.50/);assert.match(logs[1],/回调FPS=50.0/);assert.match(logs[1],/单位=24–60/);
 assert.match(logs[1],/间隔P95=20.00ms/);assert.match(logs[1],/慢帧=0\/250/);
 assert.match(logs[2],/抽样步=22/);assert.match(logs[2],/寻敌=0.200ms/);assert.match(logs[2],/碰撞含重建=0.400ms/);
 assert.match(logs[3],/UI更新=50\/250/);assert.match(logs[3],/最密格=8/);
 for(const line of logs){assert.ok(Buffer.byteLength(line,'utf8')<3000);assert.doesNotMatch(line,/NaN|Infinity|undefined/);}
});
test('pause flushes short samples once and resumed FPS excludes time in the background',()=>{
 const p=new lib.ArenaPerformance();p.begin(0,scene);for(let i=1;i<=10;i++)p.frame(frame(i*20));p.finish('暂停');
 const n=logs.length;p.finish('退出');assert.equal(logs.length,n);assert.match(logs[1],/采样=0.20s/);
 p.begin(100000,scene);for(let i=1;i<=10;i++)p.frame(frame(100000+i*20));p.finish('暂停');
 const summaries=logs.filter(s=>s.includes('[采样结束'));assert.equal(summaries.length,2);
 for(const summary of summaries)assert.match(summary,/回调FPS=50.0/);
});
test('stutter detail is rate limited and long pauses have a distinct diagnostic',()=>{
 const p=new lib.ArenaPerformance();p.begin(0,scene);
 for(let i=1;i<=100;i++)p.frame(frame(i*50,{interval:50,logic:26,total:30}));
 assert.equal(logs.filter(s=>s.startsWith('[停顿详情')).length,3);
 p.stall(620);assert.match(logs.at(-1),/长停顿 v3.*620.00ms.*自动暂停/);
});
test('theme/layout changes end the old window before the new context; save timing includes async completion',()=>{
 const p=new lib.ArenaPerformance();p.begin(0,scene);for(let i=1;i<=10;i++)p.frame(frame(i*20));
 p.saved(160,true,scene.session);p.saved(20,false,scene.session);p.context({...scene,dark:true,board:640});
 const load=logs.find(s=>s.startsWith('[场景负载'));assert.match(load,/存档完成峰值含排队=160.000ms/);assert.match(load,/存档失败=1/);
 assert.match(logs.at(-1),/场景变化 v3.*战场=640.0vp.*主题=深色/);
 const n=logs.length;p.context({...scene,dark:true,board:640});assert.equal(logs.length,n);
 // A queued old-round completion may be reported, but must not be charged to a new round.
 p.begin(1000,{...scene,session:'new-round'});p.saved(180,true,scene.session);
 for(let i=1;i<=10;i++)p.frame(frame(1000+i*20));p.finish('结算');
 assert.match(logs.at(-1),/存档完成峰值含排队=0.000ms.*存档失败=0/);
});
test('log scene names identify challenge combinations rather than the unused custom-event field',()=>{
 assert.match(lib.arenaSceneLabel({...lib.arenaDefaultConfig(),mode:'challenge',mission:7,event:'none'}),/挑战8.*花盆迷阵\+临阵换队/);
 assert.match(lib.arenaSceneLabel({...lib.arenaDefaultConfig(),event:'shrink'}),/围栏收拢/);
});
test('event explanations follow the actual warning/active/end phases and do not persist after an event',()=>{
 const c=lib.arenaDefaultConfig();const wind=new lib.ArenaEngine({...c,event:'wind'});
 for(const [tick,pattern] of [[1080,/2 秒/],[1200,/生效中/],[1500,/^$/]]){
  wind.round.tick=tick;wind.events();assert.match(lib.arenaLiveNotice(wind.round,wind.scenario),pattern);
 }
 const turn=new lib.ArenaEngine({...c,event:'traitor'});turn.round.tick=1200;turn.events();
 assert.match(lib.arenaLiveNotice(turn.round,turn.scenario),/3 秒后换队/);turn.round.tick=1380;turn.events();
 assert.equal(turn.round.traitorDone,true);assert.match(lib.arenaLiveNotice(turn.round,turn.scenario),/已换队/);
 turn.round.tick=1560;assert.equal(lib.arenaLiveNotice(turn.round,turn.scenario),'');
 const shrink=new lib.ArenaEngine({...c,event:'shrink'});shrink.round.tick=720;assert.match(lib.arenaLiveNotice(shrink.round,shrink.scenario),/3 秒/);
 shrink.round.tick=900;assert.match(lib.arenaLiveNotice(shrink.round,shrink.scenario),/开始收拢/);
});
console.log(`\n${passed} profiling/logging cases passed; these do not measure native presented FPS.`);
