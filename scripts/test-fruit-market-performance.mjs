#!/usr/bin/env node
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';

const source = readFileSync(new URL('../entry/src/main/ets/gamesNext/fruitMarket/MarketPerformance.ets', import.meta.url), 'utf8')
  .replace(/^import.*$/gm, '').replace(/^export /gm, '');
const logs = [];
const context = { hilog: { info(_domain, tag, format, message) {
  assert.equal(tag, 'FruitMarketPerf');
  assert.equal(format, '%{public}s', 'diagnostic values must remain visible when copied from HiLog');
  logs.push(message);
} } };
vm.runInNewContext(stripTypeScriptTypes(source, { mode: 'transform' }) +
  '\nglobalThis.performance = new MarketPerformance();', context);
const perf = context.performance;
const engine = { round: { bodies: { length: 20 } }, lastSteps: 1, lastSolvedSteps: 1,
  lastPairChecks: 128, sleeping: false, sleepingBodies: 0, lastBroadChecks: 30, lastSolverPasses: 6 };
function frame(start, physicsEnd, drawStart, end, count, steps, solved, pairs, asleep, painted = true, save = 0) {
  Object.assign(engine, {lastSteps:steps,lastSolvedSteps:solved,lastPairChecks:pairs,sleeping:asleep,
    sleepingBodies:asleep?count:0});
  engine.round.bodies.length=count;
  perf.frame(start,physicsEnd,drawStart,end,end+save,engine,painted,save);
}
perf.viewport(360, 520, 3.5); perf.viewport(360, 520, 3.5);
assert.equal(logs.length, 1, 'never repeat viewport logs every frame');
assert.match(logs[0], /葡萄预期直径=91.0px/);
perf.begin(20);
for (let i = 0; i < 660; i++) {
  const time = 1000 + i * 1000 / 60;
  frame(time, time + 2, time + 2.5, time + 5.5, 20, 1, 1, 128, false);
}
const summaries = logs.filter(line => line.startsWith('[5秒汇总 v4]'));
assert.equal(summaries.length, 2, '660 frames produce two summaries, not 660 log writes');
for (const summary of summaries) {
  assert.match(summary, /水果=20/);
  assert.match(summary, /物理平均=2.000ms/);
  assert.match(summary, /绘制提交平均=3.000ms/);
  assert.match(summary, /活动物理平均=2.000ms/);
  assert.match(summary, /步\/回调=1.00 求解步\/回调=1.00/);
  assert.match(summary, /休眠回调=0\//);
  assert.match(summary, /慢帧=0\//);
  assert.match(summary, /帧间隔P95=16.67ms/);
}
console.log('PASS public searchable tag, density diagnostics and five-second aggregation');
perf.begin(30);
const before = logs.length;
frame(50000, 50002, 50003, 50004, 30, 1, 0, 0, true);
assert.equal(logs.length, before, 'pause/resume must not count time spent in the background');
perf.reset();
frame(100000, 100010, 100011, 106000, 30, 2, 2, 256, false);
assert.equal(logs.length, before + 2, 'even one long first frame reports without an empty-percentile crash');
assert.match(logs.at(-1), /最长间隔=6000.00ms/);
assert.ok(!logs.at(-1).includes('NaN'));
console.log('PASS pause reset and stalled first-frame diagnostics');

// Mixed windows must not disguise an expensive active solver with many sleeping frames.
perf.begin(15);
for (let i = 0; i < 360; i++) {
  const time = 200000 + i * 1000 / 60;
  const active = i % 2 === 0;
  const cost = active ? 10 : 0.2;
  frame(time, time + cost, time + cost, time + cost + 1, 15, 1, active ? 1 : 0, active ? 200 : 0, !active);
}
assert.match(logs.at(-1), /活动物理平均=10.000ms/);
assert.match(logs.at(-1), /物理峰值=10.000ms/);
assert.match(logs.at(-1), /求解步\/回调=0.50/);
console.log('PASS active solver cost stays separate from idle/sleeping callbacks');

perf.begin(36, 'DisplaySync');
for (let i = 0; i < 360; i++) {
  const time = 300000 + i * 1000 / 60;
  frame(time,time+.1,time+.1,time+.2,36,1,0,0,true,false,i === 20 ? 12 : 0);
}
const idle = logs.filter(line => line.startsWith('[5秒汇总 v4]')).at(-1);
assert.match(idle, /重画回调=0\//);
assert.match(idle, /休眠水果=36/);
assert.match(idle, /绘制峰值=0.100ms/);
assert.match(idle, /存档提交峰值=12.000ms/);
const stallBefore = logs.filter(line => line.startsWith('[停顿详情 v4]')).length;
perf.begin(36);
for (let i=0;i<20;i++) {
  const time=400000+i*100;
  frame(time,time+.2,time+.2,time+.3,36,1,0,0,true,false);
}
const stalls = logs.filter(line => line.startsWith('[停顿详情 v4]')).slice(stallBefore);
assert.equal(stalls.length, 1, 'rate limit stall details while keeping aggregate counters');
assert.match(stalls[0], /回调间隔=100.00ms 回调外间隙=99.70ms/);
console.log('PASS skipped paints, submission peaks and rate-limited external callback gaps');
