#!/usr/bin/env node
// Execute actual ArkTS rules, page lifecycle and achievement gateway with OS/UI providers stubbed.
import assert from 'node:assert/strict';
import {readFileSync, existsSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
const root = new URL('../',import.meta.url);
const read = path => readFileSync(new URL(path,root),'utf8');
const main = path => read('entry/src/main/ets/'+path);
const plain = value => JSON.parse(JSON.stringify(value));
const clean = text => text.replace(/^import[\s\S]*?;\s*$/gm,'').replace(/^export default /gm,'').replace(/^export /gm,'');
const compile = text => stripTypeScriptTypes(clean(text),{mode:'transform'});
const files=['MemoryModel','MemoryRules','MemoryEngine','MemoryLayout','MemoryProgress'];
const source=files.map(name=>main('gamesNext/memoryGarden/'+name+'.ets')).join('\n');
const core=vm.runInNewContext(compile(source)+'\n({MemoryEngine,MemoryProgress,memoryLayout,memoryViewport,memorySaveValid,memoryCardFaceLayout})',{});
let count=0;
async function test(name,run){await run();count++;console.log('PASS '+name);}
vm.runInNewContext(compile(source+'\n'+read('entry/src/ohosTest/ets/test/MemoryGarden.test.ets'))+'\nmemoryGardenTest();',{
 describe:(_name,run)=>run(),it:(name,_kind,run)=>{run();count++;console.log('PASS '+name);},
 expect:value=>({assertEqual:expected=>assert.equal(value,expected)}),TestType:{FUNCTION:1},Size:{SMALLTEST:1},Level:{LEVEL0:1}
});
const mate=(e,a)=>e.round.cards.findIndex((id,i)=>i!==a&&id===e.round.cards[a]);
function match(e){const a=e.round.matched.findIndex(v=>!v);e.flip(a);const result=e.flip(mate(e,a));return result;}
function solve(e){while(e.round.phase!=='complete'){e.settle();match(e);}}
await test('seeded replay: every intermediate flip/match/mismatch restores and every table remains solvable',()=>{
 let flips=0;
 for(const mode of ['journey','easy','normal','focus'])for(let seed=1;seed<=40;seed++){
  const e=new core.MemoryEngine(mode,seed);
  for(let table=0;table<10;table++){
   while(e.round.phase!=='complete'){
    const first=e.round.matched.findIndex(v=>!v);
    if((first+seed)%3===0){
     const wrong=e.round.cards.findIndex((id,i)=>!e.round.matched[i]&&id!==e.round.cards[first]);
     if(wrong>=0){e.flip(first);e.flip(wrong);assert.ok(core.memorySaveValid(e.snapshot()));e.settle();}
    }
    e.flip(first);assert.ok(core.memorySaveValid(e.snapshot()));
    e.flip(mate(e,first));flips+=2;
    const restored=new core.MemoryEngine();assert.equal(restored.restore(e.serialize()),true);assert.equal(restored.serialize(),e.serialize());
    if(e.round.phase!=='complete')e.settle();
   }
   e.round.reported=true;assert.ok(e.next());
  }
 }
 console.log('  verified tables: 1600; matched flips: '+flips);
});
await test('malformed phase, pairing, counters and profile fail atomically',()=>{
 const e=new core.MemoryEngine();match(e);const raw=e.serialize();
 const mutations=[s=>s.version=2,s=>s.round.mode='other',s=>s.round.cards.pop(),s=>s.round.pairs=99,
  s=>s.round.cards[0]=1.2,s=>s.round.matched[0]='false',s=>s.round.matched[s.round.first]=false,
  s=>s.round.second=s.round.first,s=>s.round.seed=0,s=>s.round.attempts=-1,s=>s.round.reported=true,
  s=>s.round.streak=13,s=>s.round.phase='complete',s=>s.profile.totalPairs=0,s=>s.profile.best6=1,
  s=>s.profile.totalTables=10,s=>s.round.number=0,s=>s.round.id='',s=>s.round.phase='mismatch'];
 for(const change of mutations){const s=JSON.parse(raw);change(s);assert.equal(e.restore(JSON.stringify(s)),false);assert.equal(e.serialize(),raw);}
});
await test('layout matrix keeps controls separate and four columns with at least 49vp targets',()=>{
 let checked=0;
 for(const w of [200,260,320,360,390,480,600,800,960,1280,1800])for(const h of [240,400,650,780,844,1000,1400])for(const pairs of [6,8,10,12]){
  const l=core.memoryLayout(w,h,{top:24,bottom:24,left:0,right:0},[],pairs);checked++;
  const boxes=['stats','modes','board','tools','note'].map(key=>l[key]);
  for(const box of boxes){assert.ok(box.x>=-1e-8&&box.y>=0);assert.ok(box.x+box.width<=l.contentWidth+1e-8);assert.ok(box.y+box.height<=l.contentHeight+1e-8);}
  for(let i=0;i<boxes.length;i++)for(let j=i+1;j<boxes.length;j++){
   const a=boxes[i],b=boxes[j];assert.equal(Math.min(a.x+a.width,b.x+b.width)-Math.max(a.x,b.x)>1e-6&&Math.min(a.y+a.height,b.y+b.height)-Math.max(a.y,b.y)>1e-6,false,`${w}/${h}/${pairs}`);
  }
  assert.ok(l.card>=49&&l.cardHeight>=49);assert.equal(l.board.width,l.card*4+l.tileGap*3+l.pad*2);
  assert.equal(l.board.height,l.cardHeight*pairs/2+l.tileGap*(pairs/2-1)+l.pad*2+l.boardHeader+l.boardFooter);
  const face=core.memoryCardFaceLayout(l.card,l.cardHeight);
  assert.ok(face.artwork>0&&face.artwork<=l.card*.8);
  assert.ok(face.artwork+face.labelHeight+8<=l.cardHeight+1e-8,`face fits ${w}/${h}/${pairs}`);
 }
 console.log('  verified layouts: '+checked);
});
await test('phone normal/focus boards fill the content width, with reachable controls and stable columns',()=>{
 for(const [w,h] of [[320,568],[360,780],[377.1,816],[390,844],[414,896],[430,932]]){
  const layouts=[6,8,10,12].map(pairs=>core.memoryLayout(w,h,{top:24,bottom:24,left:0,right:0},[],pairs));
  for(const l of layouts){
   assert.equal(l.board.width,l.contentWidth,`${w}/${h} full width`);
   assert.equal(l.board.x,0);assert.equal(l.card,layouts[0].card);
   if(h>=816)assert.ok(l.tools.y+l.tools.height<=l.body,`${w}/${h} controls fit`);
  }
 }
 const focus=core.memoryLayout(377.1,816,{top:24,bottom:24,left:0,right:0},[],12);
 assert.equal(focus.note.height,0);assert.ok(focus.card>75);assert.ok(focus.cardHeight>=60);
 const roomy=core.memoryLayout(390,1000,{top:24,bottom:24,left:0,right:0},[],12);
 assert.ok(roomy.note.height>0);
});
await test('all phone tables fit above the gesture area with tall status bars and cutouts',()=>{
 for(const [w,h] of [[320,720],[360,720],[360,780],[377.1,816],[390,844],[414,896],[430,932],[600,960]]){
  for(const [top,bottom] of [[24,24],[48,24],[52,34],[64,40]])for(const pairs of [6,8,10,12]){
   const l=core.memoryLayout(w,h,{top,bottom,left:0,right:0},[],pairs);
   assert.ok(l.contentHeight<=l.body-1,`${w}/${h}/${top}/${bottom}/${pairs}: content ${l.contentHeight} > body ${l.body}`);
   assert.ok(l.tools.y+l.tools.height<=l.body-1,'restart and guide remain fully visible');
   assert.ok(l.cardHeight>=49&&l.card>=49,'cards remain large enough to tap');
   assert.ok(l.modes.height>=44&&l.tools.height>=44,'primary controls retain usable targets');
  }
 }
});
await test('focus mode fits safe fold panes and compact tablet sidebars without moving the card order',()=>{
 const insets={top:52,bottom:34,left:0,right:0};
 const phone=core.memoryLayout(390,844,insets,[],12);
 const folded=core.memoryLayout(800,844,insets,[{x:390,y:0,width:20,height:844}],12);
 assert.equal(folded.card,phone.card);assert.equal(folded.cardHeight,phone.cardHeight);
 assert.ok(folded.contentHeight<=folded.body-1);
 for(const [w,h] of [[800,650],[960,650],[1280,800],[1280,900]]){
  const l=core.memoryLayout(w,h,insets,[],12);
  assert.ok(l.wide);assert.ok(l.contentHeight<=l.body-1,`${w}/${h} tablet focus fits`);
  assert.ok(l.board.x+l.board.width<=l.stats.x);
 }
});
function method(source,name){const start=source.search(new RegExp('^  (?:private )?(?:async )?'+name+'\\(','m'));assert.ok(start>=0,name);return source.slice(start,source.indexOf('\n  }',start)+4);}
const appFiles=['shell/AchievementModule.ets','shell/GameModule.ets','shell/AchievementRegistry.ets','shell/AchievementEngine.ets',
 'shell/AchievementNotice.ets','shell/AchievementFavoriteEvent.ets','app/AchievementService.ets'];
let durable,failAchievements=false;
const api=vm.runInNewContext(compile(appFiles.map(main).join('\n')+'\nclass Gateway {\n'+method(main('pages/Index.ets'),'reportAchievementEvent')+'\n}')+
 '\n({Gateway,AchievementService,emptyAchievementState,achievementGroupsForState,achievementNoticeItemsForUnlocks,achievementProgressForState,favoriteAchievementEventForSnapshot,ACHIEVEMENT_ORIGINAL_GAME_IDS,ACHIEVEMENT_DEFINITIONS,achievementRegistryIssues})',{
 console,CoopStorage:{async loadAchievementState(){return plain(durable);},async saveAchievementState(_ctx,state){if(failAchievements)return false;durable=plain(state);return true;}}
});
function gateway(){durable=plain(api.emptyAchievementState());failAchievements=false;const g=new api.Gateway();
 Object.assign(g,{appContext:{},activeGame:'memoryPairs',achievementService:new api.AchievementService(),notices:[]});
 g.enqueueAchievementNotices=result=>g.notices.push(...api.achievementNoticeItemsForUnlocks(result.newlyUnlocked));return g;
}
function bridge(e,g=gateway()){
 const s={raw:'',failSave:false,failAck:false,records:[],reports:[],writes:[]};
 const p=new core.MemoryProgress(e,{
  async save(raw){if(s.failSave||s.failAck&&JSON.parse(raw).round.reported)return false;s.raw=raw;s.writes.push(raw);return true;},
  async report(event){assert.ok(s.raw.length>0);s.reports.push(plain(event));return g.reportAchievementEvent(event);},record(value){s.records.push(value);}
 });return {p,s,g};
}
const unlocked=id=>durable.progresses.some(p=>p.achievementId===id&&p.unlockedAt>0);
await test('actual pair input → saved game → Index → achievements: all three new medals and one completion per table',async()=>{
 const e=new core.MemoryEngine('easy',42),{p,s,g}=bridge(e);
 assert.equal(await p.flush(),true);assert.equal(g.notices.length,0);
 for(let table=0;table<5;table++){
  for(let pair=0;pair<6;pair++){
   match(e);assert.equal(await p.flush(),true);
   assert.equal(unlocked('memoryPairs.first_pair'),true);
   e.settle();
  }
  assert.equal(durable.completedSessionCount,table+1);assert.ok(unlocked('memoryPairs.first_table'));
  assert.equal(unlocked('memoryPairs.collector'),table===4);
  assert.equal(await p.flush(),true);assert.equal(e.next(),true);await p.flush();
 }
 assert.deepEqual(s.records,[1,2,3,4,5]);assert.equal(unlocked('global.first_settlement'),true);
 const state=await new api.AchievementService().initialize({});
 const group=api.achievementGroupsForState(state,'all').find(group=>group.definition.id==='memoryPairs');
 assert.equal(group.definition.id,'memoryPairs');assert.equal(group.items.length,3);assert.ok(group.items.every(i=>i.status==='unlocked'));
 assert.deepEqual(plain(api.achievementRegistryIssues()),[]);
 for(const d of api.ACHIEVEMENT_DEFINITIONS.filter(d=>d.gameId==='memoryPairs'))assert.ok(existsSync(new URL('entry/src/main/resources/rawfile/'+d.badgeAssetPath,root)));
});
await test('save failure grants nothing; retry and stale queued completion snapshots never duplicate records',async()=>{
 const e=new core.MemoryEngine(),{p,s,g}=bridge(e);match(e);s.failSave=true;
 assert.equal(await p.flush(),false);assert.equal(g.notices.length,0);assert.equal(s.reports.length,0);
 s.failSave=false;assert.equal(await p.flush(),true);assert.equal(g.notices.length,1);
 e.settle();solve(e);await Promise.all([p.flush(),p.flush(),p.flush()]);
 assert.equal(durable.completedSessionCount,1);assert.deepEqual(s.records,[1]);assert.ok(e.round.reported);
});
await test('achievement save failure survives a reload and unlocks once when retried',async()=>{
 const e=new core.MemoryEngine(),{p,s,g}=bridge(e);match(e);failAchievements=true;
 assert.equal(await p.flush(),false);assert.equal(unlocked('memoryPairs.first_pair'),false);
 const restored=new core.MemoryEngine();assert.equal(restored.restore(s.raw),true);
 failAchievements=false;const retry=bridge(restored,g);assert.equal(await retry.p.flush(),true);assert.equal(unlocked('memoryPairs.first_pair'),true);
 restored.settle();await retry.p.flush();assert.equal(g.notices.length,1);
});
await test('failed completion acknowledgement blocks next table and retry does not increment global count twice',async()=>{
 const e=new core.MemoryEngine(),{p,s,g}=bridge(e);solve(e);s.failAck=true;
 assert.equal(await p.flush(),false);assert.equal(durable.completedSessionCount,1);assert.equal(e.next(),false);assert.deepEqual(s.records,[]);
 const restored=new core.MemoryEngine();assert.equal(restored.restore(s.raw),true);const retry=bridge(restored,g);
 assert.equal(await retry.p.flush(),true);assert.equal(durable.completedSessionCount,1);assert.equal(restored.next(),true);
 assert.deepEqual(retry.s.records,[1]);
});
await test('ten completed tables and favorites work; original-six milestone still requires the original games',async()=>{
 const e=new core.MemoryEngine('easy'),{p,g}=bridge(e);
 for(let i=0;i<10;i++){solve(e);await p.flush();e.next();}
 assert.equal(durable.completedSessionCount,10);assert.ok(unlocked('global.complete_ten_sessions'));assert.equal(unlocked('global.play_six_games'),false);
 const favorite=api.favoriteAchievementEventForSnapshot(['memoryPairs','bloomLines','chicken2048Next'],Date.now());
 assert.ok(favorite);await g.reportAchievementEvent(favorite);assert.ok(unlocked('global.favorite_three'));
 assert.equal(api.achievementProgressForState(durable,'global.play_six_games')?.current ?? 0,0);
 e.flip(0);e.restart('focus');await p.flush();assert.equal(durable.completedSessionCount,10);
});
await test('home and wall append only the new game; global and all existing visible games keep their order',()=>{
 const registry=vm.runInNewContext(compile(main('shell/GameRegistry.ets'))+'\n({GAME_MODULES,gameLogoPath})',{});
 const hub=main('pages/HubPage.ets');const order=hub.match(/const HOME_GAME_ORDER: string\[\] = \[([\s\S]*?)\];/)[1].match(/'[^']+'/g).map(s=>s.slice(1,-1));
 const baseline=['suikaNext','minesweeperNext','tetrisNext','chicken2048Next','freecellNext','rpsBattleNext','bloomLines','memoryPairs'];
 assert.deepEqual(order.filter(id=>baseline.includes(id)),baseline);
 assert.ok(registry.GAME_MODULES.findIndex(g=>g.id==='memoryPairs')>registry.GAME_MODULES.findIndex(g=>g.id==='bloomLines'));
 assert.equal(registry.gameLogoPath('memoryPairs'),'gamesNext/memoryGarden/scene/logo.svg');
 const groups=plain(api.achievementGroupsForState(api.emptyAchievementState(),'all')).map(g=>g.definition.id);
 const oldGroups=['global','rpsBattle','freecell','minesweeper','chicken2048','tetris','suika','bloomLines','memoryPairs'];
 assert.equal(groups[0],'global');assert.deepEqual(groups.filter(id=>oldGroups.includes(id)),oldGroups);
});

const pageText=main('gamesNext/memoryGarden/MemoryPage.ets');
const names=['boot','tap','sync','cancelTimer','schedulePhase','advance','present','closeDialog','chooseMode','requestRestart','newJourney',
 'relayout','backgrounded','exitRequested','save','retrySave','saveAndExit','aboutToDisappear'];
const timers=new Map(),frames=[];let seq=0;
const pageApi=vm.runInNewContext(compile(source+'\nclass Page {\n'+names.map(n=>method(pageText,n)).join('\n')+'\n}')+'\n({Page})',{
 console,setTimeout:fn=>{const id=++seq;timers.set(id,fn);return id;},clearTimeout:id=>timers.delete(id),
 MemoryReflow:class{constructor(fn){this.fn=fn;}}
});
const tick=()=>new Promise(resolve=>setImmediate(resolve));
function controller(e=new core.MemoryEngine()){
 timers.clear();frames.length=0;const p=new pageApi.Page();const b=bridge(e);const sounds=[];
 Object.assign(p,{engine:e,progress:b.p,context:{},loaded:true,loading:false,disposed:false,skipSave:false,backgroundPaused:false,
  timer:-1,generation:0,saveSequence:0,layoutGeneration:0,returnDialog:'',dialog:'',pendingMode:'journey',saving:false,saveFailed:false,deal:true,
  pageWidth:390,pageHeight:844,insets:{top:24,bottom:24,left:0,right:0},creases:[],layout:core.memoryLayout(390,844,{top:24,bottom:24,left:0,right:0}),
  audio:{play:n=>sounds.push(n),silence(){},release(){}},host:{release(){}},storage:{load:async()=>b.s.raw},
  verticalScroll:{scrollTo:o=>{p.scrollReset=o;}},horizontalScroll:{scrollTo:o=>{p.scrollReset=o;}},
  getUIContext:()=>({postFrameCallback:f=>frames.push(f)}),exitToHub:()=>{p.left=true;}
 });p.sync();return {...b,p,e,sounds};
}
function fire(){const [id,fn]=timers.entries().next().value;timers.delete(id);fn();}
await test('real page rejects rapid third taps; pause freezes a mismatch and resume closes it once',async()=>{
 const {p,e}=controller();const second=e.round.cards.findIndex(id=>id!==e.round.cards[0]);
 p.tap(0);p.tap(second);const third=e.round.cards.findIndex((_,i)=>i!==0&&i!==second);
 p.tap(third);assert.equal(e.round.attempts,1);assert.equal(e.round.second,second);
 const stale=[...timers.values()][0];p.backgrounded();assert.equal(timers.size,0);stale();assert.equal(e.round.phase,'mismatch');
 p.closeDialog();assert.equal(p.dialog,'');fire();await tick();assert.equal(e.round.phase,'ready');assert.equal(e.round.attempts,1);
});
await test('fold/unfold repositions the same table; delayed scroll callbacks cannot reset a newer layout',()=>{
 const {p,e}=controller();p.tap(0);const raw=e.serialize();
 const original=plain(p.layout);p.pageWidth=1280;p.pageHeight=900;p.relayout();
 const expanded=plain(p.layout);assert.equal(expanded.wide,true);
 const old=frames.at(-1);p.pageWidth=360;p.pageHeight=780;p.relayout();old.fn();assert.equal(p.scrollReset,undefined);
 frames.at(-1).fn();assert.equal(p.scrollReset.xOffset,0);
 p.pageWidth=1280;p.pageHeight=900;p.relayout();assert.deepEqual(plain(p.layout),expanded);assert.equal(e.serialize(),raw);
 p.pageWidth=390;p.pageHeight=844;p.relayout();assert.deepEqual(plain(p.layout),original);
});
await test('real page completes once and automatically deals the next table only after persisted acknowledgement',async()=>{
 const {p,e,s}=controller();
 while(e.round.phase!=='complete'){
  const a=e.round.matched.findIndex(v=>!v);p.tap(a);p.tap(mate(e,a));
  if(e.round.phase!=='complete')fire();
 }
 await tick();assert.equal(e.round.number,1);assert.equal(e.round.reported,true);
 fire();await tick();assert.equal(e.round.number,2);assert.equal(e.round.first,-1);assert.deepEqual(s.records,[1]);assert.equal(durable.completedSessionCount,1);
 assert.ok(frames.length>0,'same-size next table must still reset old scroll offsets');
 frames.at(-1).fn();assert.equal(p.scrollReset.yOffset,0);
});
await test('a failed save holds the completed table; inline retry resumes continuous play',async()=>{
 const {p,e,s}=controller();s.failSave=true;
 while(e.round.phase!=='complete'){const a=e.round.matched.findIndex(v=>!v);p.tap(a);p.tap(mate(e,a));if(e.round.phase!=='complete')fire();}
 await tick();assert.equal(p.saveFailed,true);fire();await tick();assert.equal(e.round.number,1);assert.equal(e.round.reported,false);
 s.failSave=false;await p.retrySave();fire();await tick();assert.equal(e.round.number,2);assert.equal(durable.completedSessionCount,1);
});
await test('load errors never save defaults; pending pair reload requires resume and stays exposed',async()=>{
 const {p,e,s}=controller();p.loaded=false;p.storage.load=async()=>{throw Error('unavailable');};await p.boot();
 assert.equal(p.dialog,'loadError');assert.equal(s.writes.length,0);
 p.storage.load=async()=>'{}';await p.boot();assert.equal(p.dialog,'corrupt');assert.equal(s.writes.length,0);
 e.flip(0);e.flip(e.round.cards.findIndex(id=>id!==e.round.cards[0]));p.storage.load=async()=>e.serialize();await p.boot();
 assert.equal(p.dialog,'resume');assert.equal(e.round.phase,'mismatch');assert.equal(timers.size,0);
 p.closeDialog();fire();assert.equal(e.round.attempts,1);assert.equal(e.round.phase,'ready');
});
await test('exit or restart during a pending flip cannot let an old callback affect the new table',async()=>{
 const {p,e}=controller();p.tap(0);p.tap(mate(e,0));const stale=[...timers.values()][0];
 p.requestRestart();await p.newJourney();const raw=e.serialize();stale();assert.equal(e.serialize(),raw);
 p.tap(0);p.tap(mate(e,0));const after=[...timers.values()][0];p.aboutToDisappear();after();await tick();assert.equal(timers.size,0);assert.equal(e.round.phase,'match');
});
await test('save-and-exit stays on the page on failure and leaves after retry',async()=>{
 const {p,s}=controller();p.tap(0);s.failSave=true;await p.saveAndExit();assert.equal(p.left,undefined);assert.equal(p.dialog,'exit');
 s.failSave=false;await p.saveAndExit();assert.equal(p.left,true);assert.equal(p.skipSave,true);
});
const cardSource=main('gamesNext/memoryGarden/MemoryCard.ets');
const cardApi=vm.runInNewContext(compile(source+'\n'+main('design/CoopMotion.ets')+'\nclass Card {\n'+
 ['aboutToAppear','aboutToDisappear','turn','label'].map(n=>method(cardSource,n)).join('\n')+'\n}')+'\n({Card})',{
 Curve:{EaseIn:0,EaseOut:1}
});
await test('card flip midpoints ignore stale animation callbacks and callbacks after removal',()=>{
 const card=new cardApi.Card(),finishes=[];
 Object.assign(card,{slot:0,picture:0,isOpen:false,matched:false,deal:false,epoch:0,
  getUIContext:()=>({animateTo:(options,action)=>{action();if(options.onFinish)finishes.push(options.onFinish);}})});
 card.aboutToAppear();card.isOpen=true;card.turn();const stale=finishes.shift();
 card.isOpen=false;card.turn();stale();assert.equal(card.faceUp,false);
 finishes.shift()();assert.equal(card.angle,0);assert.equal(card.faceUp,false);
 card.isOpen=true;card.turn();card.aboutToDisappear();finishes.shift()();assert.equal(card.faceUp,false);
});
await test('screen-reader labels do not reveal the identity of face-down cards',()=>{
 const card=new cardApi.Card();Object.assign(card,{slot:5,picture:0,isOpen:false,matched:false});
 assert.equal(card.label().includes('小鸡'),false);assert.ok(card.label().includes('第 2 行'));
 card.isOpen=true;assert.ok(card.label().includes('小鸡'));card.matched=true;assert.ok(card.label().includes('已配对'));
});
console.log('\nMemory Garden: '+count+' rule, layout, lifecycle and achievement groups passed.');
