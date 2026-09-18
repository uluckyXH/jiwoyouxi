#!/usr/bin/env node
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
const root = resolve(import.meta.dirname, '..');
const dir = 'entry/src/main/ets/gamesNext/warmFreecell/';
const read = file => fs.readFileSync(resolve(root, file), 'utf8');
const clean = source => source.replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export /gm, '').replace(/^@Observed\s*/gm, '');
const source = ['FreecellModel.ets', 'FreecellSession.ets', 'FreecellLayout.ets'].map(name => read(dir + name)).join('\n');
const context = vm.createContext({ console });
const api = vm.runInContext(stripTypeScriptTypes(clean(source)) + '\n({FreecellSession,fcValidPiles,fcCanMove,fcCapacity,fcLocate,fcSuit,fcLayout,fcTarget,fcPileX,fcViewport,fcUsesCreases})', context);
const {FreecellSession,fcValidPiles,fcCanMove,fcCapacity,fcLocate,fcSuit,fcLayout,fcTarget,fcPileX,fcViewport,fcUsesCreases} = api;
const plain = value => JSON.parse(JSON.stringify(value));
let count = 0;
const test = (name, action) => { action(); count++; console.log(`PASS ${name}`); };
function fixture() {
  const piles = Array.from({length:16}, () => []);
  piles[0] = [7,19,5]; piles[2] = [21];
  piles[3] = [0]; piles[4] = [1]; piles[5] = [2]; piles[6] = [3];
  piles[8] = [30]; piles[9] = [31]; piles[10] = [32];
  const used = new Set(piles.flat());
  piles[7] = Array.from({length:52}, (_,i)=>i).filter(i=>!used.has(i));
  return piles;
}
test('100 reproducible seeds conserve all 52 cards and have actual legal completion paths', () => {
  for(let seed=1;seed<=100;seed++) {
    const game = new FreecellSession(); game.newGame(seed);
    const same = new FreecellSession(); same.newGame(seed);
    assert.deepEqual(plain(game.piles), plain(same.piles));
    assert.deepEqual(Array.from(game.piles.slice(0,8), p=>p.length).sort(), [6,6,6,6,7,7,7,7]);
    for(let step=0;step<52;step++) {
      assert(fcValidPiles(game.piles));
      const card = game.piles.slice(0,12).flatMap(p=>p.length ? [p.at(-1)] : []).find(card => fcCanMove(game.piles,card,12+fcSuit(card)));
      assert.notEqual(card, undefined, `seed ${seed}, step ${step}`);
      assert(game.move(card,12+fcSuit(card)));
    }
    assert(game.won()); assert.equal(game.collected(),52); assert.equal(game.moves,52);
  }
});
test('empty destination is excluded from group transport capacity', () => {
  const piles = fixture();
  assert(fcValidPiles(piles)); assert.equal(fcCapacity(piles,2),4); assert.equal(fcCapacity(piles,1),2);
  assert(fcCanMove(piles,7,2)); assert(!fcCanMove(piles,7,1));
  piles[11]=[piles[7].pop()];
  assert.equal(fcCapacity(piles,1),1); assert(!fcCanMove(piles,19,1));
});
test('color, rank, occupied cells, foundation order and covered cards reject illegal moves', () => {
  const p=fixture();
  assert(!fcCanMove(p,7,8)); assert(!fcCanMove(p,7,12)); assert(!fcCanMove(p,7,0));
  assert(!fcCanMove(p,19,2)); assert(!fcCanMove(p,7,-1)); assert(!fcCanMove(p,5,1.5));
  assert(fcCanMove(p,5,11));
  p[0]=[7,5,19]; assert(!fcCanMove(p,7,2));
});
test('undo restores positions and score without resetting elapsed time or completion identity', () => {
  const g=new FreecellSession();g.newGame(8); const before=g.key();
  const move=g.suggestions()[0];g.elapsed=47;assert(g.move(move.card,move.target));g.reported=true;
  assert(g.undo());assert.equal(g.key(),before);assert.equal(g.moves,0);assert.equal(g.elapsed,47);assert(g.reported);
});
test('move count continues past bounded undo history', () => {
  const g=new FreecellSession();g.piles=fixture();
  for(let i=0;i<230;i++) { assert(g.move(5,11)); assert(g.move(5,0)); }
  assert.equal(g.moves,460); assert.equal(g.history.length,200);
  for(let i=0;i<200;i++) assert(g.undo());
  assert.equal(g.moves,260); assert(!g.undo());
});
test('save/restore validates cards, capacities, histories and numeric fields atomically', () => {
  const g=new FreecellSession();g.newGame(98);const move=g.suggestions()[0];g.move(move.card,move.target);g.elapsed=65;
  const restored=new FreecellSession();assert(restored.restore(g.serialize()));assert.equal(restored.key(),g.key());assert.equal(restored.elapsed,65);
  const baseline=restored.serialize();const archive=JSON.parse(g.serialize());
  const corrupt=[null,{}, {...archive,elapsed:-1}, {...archive,moves:1.1}, {...archive,version:99}, {...archive,reported:'yes'}];
  const duplicate=structuredClone(archive);duplicate.piles[0][0]=duplicate.piles[1][0];corrupt.push(duplicate);
  const history=structuredClone(archive);history.history[0].moves=99;corrupt.push(history);
  for(const bad of corrupt) {assert(!restored.restore(JSON.stringify(bad)));assert.equal(restored.serialize(),baseline);}
  assert(!restored.restore('broken'));assert(!restored.restore('x'.repeat(2000001)));
});
test('every suggested move is legal; automatic play never returns a previously visited state', () => {
  const g=new FreecellSession();g.newGame(871);const visited=[g.key()];
  for(let i=0;i<120&&!g.won();i++) {
    for(const m of g.suggestions()) assert(fcCanMove(g.piles,m.card,m.target));
    const m=g.automatic(visited);if(!m)break;
    assert(g.move(m.card,m.target));assert(!visited.includes(g.key()));visited.push(g.key());
  }
});
test('phone, tablet, fold, half-fold and extreme windows keep controls and card hit coordinates valid', () => {
  const insets={top:24,bottom:24,left:0,right:0};
  let samples=0;
  for(const width of [240,280,320,360,412,600,720,840,1024,1280]) for(const height of [280,400,568,720,844,1024]) {
    const folds=[[],[{x:0,y:height/2,width,height:12}],[{x:width/2,y:0,width:10,height}],
      [{x:width/3,y:0,width:8,height},{x:width*2/3,y:0,width:8,height}]];
    for(const creases of folds) {
      const l=fcLayout(width,height,insets,creases);samples++;
      assert(l.card>=32&&l.card<=96);assert(l.board.height>=150);
      for(const r of [l.stats,l.board,l.tools]) {
        assert(r.x>=0&&r.y>=0&&r.width>0&&r.height>0);
        assert(r.x+r.width<=l.width+.01);assert(r.y+r.height<=l.height+.01);
      }
      for(let p=0;p<16;p++) assert.equal(fcTarget(l,fcPileX(l,p)+l.card/2,p<8?l.tableY+4:30),p);
      for(const c of creases) {
        const p=l.frame;
        assert(p.x+p.width<=c.x || p.x>=c.x+c.width || p.y+p.height<=c.y || p.y>=c.y+c.height);
      }
    }
  }
  assert.equal(fcUsesCreases(2),false);assert.equal(fcUsesCreases(3),true);
  console.log(`  ${samples} geometry cases`);
});
test('all synthesized sounds are audible PCM with mixing headroom', () => {
  for(const name of ['tap','slide','home','undo','hint','blocked','deal','win']) {
    const wav=fs.readFileSync(resolve(root,`entry/src/main/resources/rawfile/gamesNext/warmFreecell/audio/${name}.wav`));
    assert.equal(wav.toString('ascii',0,4),'RIFF');assert.equal(wav.toString('ascii',8,12),'WAVE');
    let peak=0,squares=0;
    for(let i=44;i<wav.length;i+=2){const a=wav.readInt16LE(i)/32768;peak=Math.max(peak,Math.abs(a));squares+=a*a;}
    assert(peak>=.3&&peak<.75);assert(Math.sqrt(squares/((wav.length-44)/2))>.05);
  }
});
console.log(`${count} rule, save, assist, layout and audio groups passed.`);

// Exercise the real page methods with deterministic time and native service doubles.
const page = read(dir+'FreecellRoomPage.ets');
const fields = page.slice(page.indexOf('  private engine:'),page.indexOf('  aboutToAppear():'));
const methods = page.slice(page.indexOf('  private async boot()'),page.lastIndexOf('}'));
const view = read(dir+'FreecellCard.ets').split('@Component')[0];
let now=10000,nextTimer=0;const timers=new Map();
const runTimers=ms=>{now+=ms;for(const [id,task] of [...timers])if(task.at<=now){timers.delete(id);task.fn();}};
const harnessContext=vm.createContext({console, Curve:{EaseOut:'easeOut'}, Date:class extends Date {static now(){return now;}},
  setTimeout:(fn,ms)=>{const id=++nextTimer;timers.set(id,{fn,at:now+ms});return id;},clearTimeout:id=>timers.delete(id),
  Scroller:class{},FreecellAudio:class{play(){}silence(){}setEnabled(){}},FreecellWindow:class{setDark(){}},
  FreecellFrame:class {constructor(run){this.run=run;}onIdle(){this.run();}},
  FreecellStorage:class{async save(){return true;}async load(){return '';}}
});
const harnessSource = `${source}\n${view}\nclass PageHarness {${fields.replace(/@State /g,'')}\n${methods}\ngetUIContext(){return {animateTo:(_options,run)=>run(),postFrameCallback:frame=>setTimeout(()=>frame.onIdle(0),16),postDelayedFrameCallback:(frame,delay)=>setTimeout(()=>frame.onIdle(0),delay)};}\n}\n({PageHarness,FreecellSession,fcValidPiles})`;
const {PageHarness}=vm.runInContext(stripTypeScriptTypes(clean(harnessSource)),harnessContext);
const createPage=()=>{const p=new PageHarness();p.context={};p.loaded=true;p.dialog='';p.sync();p.recordScore=()=>{};p.reportAchievementEvent=async()=>true;return p;};
test('pause and resize during movement discard stale callbacks without losing the move',()=>{
  const p=createPage();const m=p.engine.suggestions()[0];assert(p.move(m.card,m.target));const key=p.engine.key();
  p.present('pause');runTimers(900);assert.equal(p.engine.key(),key);assert.equal(p.dialog,'pause');assert(!p.busy);
  p.pageWidth=1024;p.pageHeight=768;p.relayout();assert.equal(p.engine.key(),key);assert(!p.automatic);
  for(const c of p.cards)assert(c.dx===0&&c.dy===0&&Number.isFinite(c.x)&&Number.isFinite(c.y));
});
test('manual tap stops auto even while its previous movement is animating',()=>{
  const p=createPage();p.automatic=true;const m=p.engine.suggestions()[0];p.move(m.card,m.target);
  const id=p.engine.piles.find(p=>p.length)?.at(-1);p.tap(id);assert(!p.automatic);runTimers(300);assert(!p.automatic);
});
test('fold transition cancels an uncommitted drag and restores all card offsets',()=>{
  const p=createPage();const id=p.engine.piles[0].at(-1);const before=p.engine.key();
  assert(p.beginDrag(id));p.drag(90,150);assert(p.cards[id].dx===90);
  p.pageWidth=600;p.pageHeight=440;p.relayout();assert(!p.dragging);assert.equal(p.engine.key(),before);
  for(const c of p.cards)assert.equal(c.dx+c.dy,0);
});
test('undo during a moving animation reverses the logical commit once',()=>{
  const p=createPage();const before=p.engine.key();const m=p.engine.suggestions()[0];p.move(m.card,m.target);p.undo();
  runTimers(1000);assert.equal(p.engine.key(),before);assert.equal(p.engine.moves,0);
});
test('timer pauses in guide and background, resumes without charging paused wall time',()=>{
  const p=createPage();p.started=true;p.clockMark=now;now+=2500;p.tick();assert.equal(p.elapsed,2);
  p.present('help');now+=70000;p.tick();assert.equal(p.elapsed,2);p.closePanel();now+=1200;p.tick();assert.equal(p.elapsed,3);
  p.backgrounded();now+=90000;p.tick();assert.equal(p.elapsed,3);
});
test('new round invalidates a queued tap and auto timer',()=>{
  const p=createPage();const m=p.engine.suggestions()[0];p.move(m.card,m.target);p.queuedCard=9;p.automatic=true;p.scheduleAuto();
  const old=p.engine.session;p.newGame(false);runTimers(2000);assert.notEqual(p.engine.session,old);assert.equal(p.engine.moves,0);assert.equal(p.queuedCard,-1);assert(!p.automatic);
});
test('fresh deal paints its starting pose before spreading cards and unlocks when finished',()=>{
  const p=createPage();p.deal();assert(p.busy);assert(p.cards.every(c=>c.enterOpacity===0));
  assert(p.cards.some(c=>c.enterX!==0||c.enterY!==0));runTimers(16);
  assert(p.cards.every(c=>c.enterOpacity===0));runTimers(280);
  assert(p.cards.every(c=>c.enterOpacity===1&&c.enterX===0&&c.enterY===0));assert(p.busy);
  runTimers(590);assert(!p.busy);assert(!p.dealing);
});
test('unstarted gesture cancellation cannot erase the deal starting pose',()=>{
  const p=createPage();p.deal();const poses=p.cards.map(c=>[c.enterX,c.enterY,c.enterOpacity]);p.cancelDrag();
  assert.deepEqual(p.cards.map(c=>[c.enterX,c.enterY,c.enterOpacity]),poses);p.present('pause');
});
test('late initial layout restages the deal; pause invalidates all delayed frame callbacks',()=>{
  const p=createPage();p.deal();const old=p.dealEpoch;p.pageWidth=707;p.pageHeight=773;p.relayout();
  assert(p.dealEpoch>old);assert(p.dealing);assert(p.cards.every(c=>c.enterOpacity===0));
  runTimers(16);p.present('pause');runTimers(280);runTimers(590);
  assert(!p.busy);assert(!p.dealing);assert.equal(p.dialog,'pause');assert(p.cards.every(c=>c.enterOpacity===1));
});
test('dragging a movable card commits its drop and a late cancel cannot undo the result',()=>{
  const p=createPage();const m=p.engine.suggestions().find(m=>m.target>=12);assert(m);
  assert(p.cards[m.card].movable);const card=p.cards[m.card];assert(p.beginDrag(m.card));
  const dx=fcPileX(p.layout,m.target)-card.x;const dy=22-card.y;p.drag(dx,dy);p.drop(m.card,dx,dy);
  const key=p.engine.key();assert.equal(p.engine.moves,1);assert(p.busy);p.cancelDrag();
  assert.equal(p.engine.key(),key);assert(p.busy);runTimers(210);assert(!p.busy);
});
const asyncTest = async (name, action) => { await action(); count++; console.log(`PASS ${name}`); };
await asyncTest('restoring an untouched hand still deals, while an active save offers resume',async()=>{
  const p=createPage();const raw=p.engine.serialize();p.storage.load=async()=>raw;await p.boot();
  assert(p.dealing);assert.equal(p.dialog,'');p.present('pause');
  const q=createPage();const m=q.engine.suggestions()[0];q.engine.move(m.card,m.target);
  const moved=q.engine.serialize();q.storage.load=async()=>moved;await q.boot();
  assert.equal(q.dialog,'resume');assert(!q.dealing);assert.equal(q.engine.moves,1);
});
const wonPage = () => {
  const p=createPage();
  p.engine.piles=Array.from({length:16}, (_,pile)=>pile>=12 ? Array.from({length:13},(_,rank)=>(pile-12)*13+rank) : []);
  p.engine.moves=52;p.engine.elapsed=91;p.sync();return p;
};
await asyncTest('victory is saved before acknowledgement and concurrent reports count once',async()=>{
  const p=wonPage();const archives=[];const events=[];let scores=0;
  p.storage.save=async(_context,raw)=>{archives.push(JSON.parse(raw));return true;};
  p.reportAchievementEvent=async event=>{events.push(event);assert.equal(archives[0].reported,false);return true;};
  p.recordScore=score=>{assert.equal(score,520);scores++;};
  await Promise.all([p.reportWin(),p.reportWin()]);await p.reportWin();
  assert.equal(events.length,1);assert.equal(scores,1);assert(p.engine.reported);assert(!p.saving);
  assert.equal(archives.at(-1).reported,true);
});
await asyncTest('failed victory save or acknowledgement remains retryable with the same event identity',async()=>{
  const p=wonPage();const events=[];let scores=0;
  p.storage.save=async()=>false;p.reportAchievementEvent=async e=>{events.push(e);return false;};p.recordScore=()=>scores++;
  await p.reportWin();assert.equal(events.length,0);assert(!p.engine.reported);assert(p.saveFailed);assert(!p.saving);
  p.storage.save=async()=>true;await p.reportWin();assert.equal(events.length,1);assert(!p.engine.reported);assert(p.saveFailed);
  p.reportAchievementEvent=async e=>{events.push(e);return true;};await p.reportWin();
  assert.equal(events[0].eventId,events[1].eventId);assert.equal(scores,1);assert(p.engine.reported);assert(!p.saveFailed);
});
await asyncTest('folding during the final movement keeps the won board and shows its result',async()=>{
  const p=wonPage();p.engine.piles[0]=[p.engine.piles[15].pop()];p.engine.moves=51;p.sync();
  assert(p.move(51,15));assert(p.busy);p.pageWidth=720;p.pageHeight=772;p.relayout();
  assert.equal(p.dialog,'win');assert(p.engine.won());assert(!p.busy);runTimers(900);
  assert.equal(p.dialog,'win');assert.equal(p.engine.moves,52);
});
console.log(`${count} total checks passed; native rendering, gestures and device sound need device verification.`);
