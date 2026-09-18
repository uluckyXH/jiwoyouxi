import { ArenaConfig, ArenaEffect, ArenaEntity, ArenaObstacle, ArenaRound, ArenaScenario, ARENA_NAMES, ARENA_MISSION_SEEDS, ARENA_RADIUS, ARENA_INSET,
  arenaBeats, arenaClamp, arenaConfigValid, arenaDefaultConfig, arenaHome, arenaLeader, arenaScenario } from './ArenaModel';

const STEP: number = 1 / 60;
const CELL: number = 72;
const GRID: number = 10;
const COOLDOWNS: number[] = [10,16,12];
const SKILL_RADIUS: number[] = [158,86,115];
export interface ArenaStepTiming {
  steps: number; grid: number; seek: number; move: number; contact: number; rules: number;
}

/** All simulation state is in world units. Display size and theme never reach this class. */
export class ArenaEngine {
  round: ArenaRound;
  scenario: ArenaScenario;
  obstacles: ArenaObstacle[] = [];
  effects: ArenaEffect[] = [];
  sounds: string[] = [];
  checks: number = 0;
  scans: number = 0;
  droppedMs: number = 0;
  contacts: number = 0;
  crowding: number = 0;
  timing: ArenaStepTiming = {steps:0,grid:0,seek:0,move:0,contact:0,rules:0};
  private buckets: number[][] = [];
  private losses: number[] = [];
  private depth: number[] = [];
  private correctionX: number[] = [];
  private correctionY: number[] = [];
  private previousX: number[] = [];
  private previousY: number[] = [];
  private accumulator: number = 0;

  constructor(config: ArenaConfig = arenaDefaultConfig()) {
    const c: ArenaConfig = JSON.parse(JSON.stringify(arenaConfigValid(config) ? config : arenaDefaultConfig())) as ArenaConfig;
    if (c.mode === 'challenge') { c.seed = ARENA_MISSION_SEEDS[c.mission]; c.event = 'none'; c.counts = [8,8,8];
      if (c.mission === 1) { c.counts = [9,9,9]; c.counts[c.faction] = 6; } }
    this.scenario = arenaScenario(c);
    this.round = { version: 1, session: `arena-${Date.now()}-${c.seed}`, config: c, rng: c.seed, tick: 0, nextId: 1,
      entities: [], counts: [0,0,0], scores: [0,0,0], owner: -1, capturing: -1, captureTime: 0,
      readyAt: [[0,0,0],[0,0,0],[0,0,0]], windLeft: [2,2,2], uses: [[0,0,0],[0,0,0],[0,0,0]],
      supplyLeft: [2,2,2], lowSince: [-1,-1,-1], supplyDue: [-1,-1,-1], conversions: 0,
      traitorId: -1, traitorAt: 0, traitorDone: false, windX: 190, windY: 375,
      finished: false, winner: -1, won: false, stars: 0, reason: '', reported: false, moments: [], history: [] };
    for (let i = 0; i < GRID * GRID; i += 1) this.buckets.push([]);
    this.buildObstacles();
    // Interleave initial identities: the contact order is not grouped by faction.
    for (let n = 0; n < Math.max(c.counts[0], c.counts[1], c.counts[2]); n += 1) {
      for (let offset = 0; offset < 3; offset += 1) {
        const f = (c.faction+offset)%3;
        if (n < c.counts[f]) this.spawn(f);
      }
    }
    this.recount(); this.sample();
  }
  time(): number { return this.round.tick * STEP; }
  nextRandom(): number {
    this.round.rng = (Math.imul(this.round.rng, 1664525) + 1013904223) >>> 0;
    return this.round.rng / 4294967296;
  }
  border(): number { return this.scenario.shrink ? Math.min(125, Math.max(0, this.time() - 15) * 3.2) : 0; }
  advance(ms: number, sampleNow?: () => number): number {
    this.checks=0; this.scans=0; this.droppedMs=0; this.contacts=0; this.crowding=0;
    this.timing.steps=0; this.timing.grid=0; this.timing.seek=0; this.timing.move=0; this.timing.contact=0; this.timing.rules=0;
    if (!Number.isFinite(ms) || ms <= 0 || this.round.finished) return 0;
    this.droppedMs=Math.max(0,ms-50);
    this.accumulator += Math.min(50, ms) / 1000;
    let steps = 0, checks = 0, scans = 0, contacts = 0, crowding = 0;
    while (this.accumulator + 0.00000001 >= STEP && steps < 3 && !this.round.finished) {
      this.accumulator -= STEP; this.step(sampleNow); steps += 1;
      checks+=this.checks; scans+=this.scans; contacts+=this.contacts; crowding=Math.max(crowding,this.crowding);
    }
    this.checks=checks; this.scans=scans; this.contacts=contacts; this.crowding=crowding;
    if (steps === 3) this.accumulator = Math.max(0, this.accumulator % STEP);
    return steps;
  }
  resetClock(): void { this.accumulator = 0; this.rememberPositions(); }
  interpolation(): number { return arenaClamp(this.accumulator / STEP,0,1); }
  visualX(index: number, alpha: number): number {
    const x=this.round.entities[index].x, previous=this.previousX[index];
    return previous === undefined ? x : previous+(x-previous)*alpha;
  }
  visualY(index: number, alpha: number): number {
    const y=this.round.entities[index].y, previous=this.previousY[index];
    return previous === undefined ? y : previous+(y-previous)*alpha;
  }
  private rememberPositions(): void {
    const units=this.round.entities;
    this.previousX.length=units.length; this.previousY.length=units.length;
    for(let i=0;i<units.length;i+=1) { this.previousX[i]=units[i].x; this.previousY[i]=units[i].y; }
  }
  step(sampleNow?: () => number): void {
    if (this.round.finished) return;
    this.round.tick += 1; this.checks = 0; this.scans = 0; this.contacts=0; this.crowding=0;
    const t = this.time();
    let mark=sampleNow!==undefined ? sampleNow() : 0;
    this.rememberPositions(); this.rebuild();
    if(sampleNow!==undefined) { const next=sampleNow(); this.timing.grid+=next-mark; mark=next; }
    const units = this.round.entities;
    for (let i = 0; i < units.length; i += 1) {
      if ((this.round.tick + units[i].id) % 6 === 0) this.chooseTargets(i);
    }
    if(sampleNow!==undefined) { const next=sampleNow(); this.timing.seek+=next-mark; mark=next; }
    for (let i = 0; i < units.length; i += 1) this.move(units[i]);
    if(sampleNow!==undefined) { const next=sampleNow(); this.timing.move+=next-mark; mark=next; }
    this.rebuild(); this.collide();
    if(sampleNow!==undefined) { const next=sampleNow(); this.timing.contact+=next-mark; mark=next; }
    this.recount();
    this.events();
    if (this.scenario.rule === 'zones') { this.supply(); this.zone(); }
    if (this.round.tick % 30 === 0) this.computer();
    if (this.round.tick % 60 === 0) this.sample();
    // Retain the bounded effect buffer without allocating a new array every simulation step.
    let kept=0;
    for(let i=0;i<this.effects.length;i+=1) if(t-this.effects[i].at<.65) this.effects[kept++]=this.effects[i];
    this.effects.length=kept;
    this.resolveResult();
    if(sampleNow!==undefined) { this.timing.rules+=sampleNow()-mark; this.timing.steps+=1; }
  }
  skillReady(f: number, skill: number): boolean {
    return !this.round.finished && f >= 0 && f < 3 && skill >= 0 && skill < 3 && this.scenario.skills[skill] &&
      this.round.counts[f] > 0 && this.time() >= this.round.readyAt[f][skill] && (skill !== 2 || this.round.windLeft[f] > 0);
  }
  cast(f: number, skill: number, x: number, y: number): number {
    if (!Number.isInteger(f) || !Number.isInteger(skill) || !Number.isFinite(x) || !Number.isFinite(y) ||
      x < 0 || y < 0 || x > 720 || y > 720 || !this.skillReady(f, skill)) return 0;
    const radius = SKILL_RADIUS[skill], t = this.time();
    const selected = this.round.entities.filter((e: ArenaEntity): boolean => (skill === 2 || e.faction === f) &&
      (e.x - x) * (e.x - x) + (e.y - y) * (e.y - y) <= radius * radius);
    selected.sort((a: ArenaEntity, b: ArenaEntity): number =>
      ((a.x-x)*(a.x-x)+(a.y-y)*(a.y-y)) - ((b.x-x)*(b.x-x)+(b.y-y)*(b.y-y)) || a.id-b.id);
    const limit = Math.min(selected.length, skill === 0 ? 6 : skill === 1 ? 4 : 60);
    if (limit === 0) return 0;
    for (let i = 0; i < limit; i += 1) {
      const e = selected[i];
      if (skill === 0) { e.rallyX = x; e.rallyY = y; e.rallyUntil = t + 4; }
      else if (skill === 1) { e.shield = 1; e.shieldUntil = t + 3; }
      else { const dx = e.x-x, dy = e.y-y, d = Math.max(1,Math.sqrt(dx*dx+dy*dy));
        e.vx += (d > 1 ? dx/d : 1) * 170; e.vy += dy/d * 170; }
    }
    this.round.readyAt[f][skill] = t + COOLDOWNS[skill];
    this.round.uses[f][skill] += 1;
    if (skill === 2) this.round.windLeft[f] -= 1;
    this.effect(skill + 1, f, x, y); this.sound('skill');
    if (f === this.round.config.faction) this.note(`${['集结','护阵','风推'][skill]}影响了 ${limit} 个单位`);
    return limit;
  }
  radius(skill: number): number { return SKILL_RADIUS[arenaClamp(skill,0,2)]; }
  serialize(): string { return JSON.stringify(this.round); }
  restore(raw: string): boolean {
    if (raw.length > 160000) return false;
    try {
      const r = JSON.parse(raw) as ArenaRound;
      if (!this.valid(r)) return false;
      this.round = r; this.scenario = arenaScenario(r.config); this.buildObstacles();
      this.effects = []; this.sounds = []; this.resetClock(); this.recount();
      return true;
    } catch (_) { return false; }
  }
  private spawn(f: number): void {
    if (this.round.entities.length >= 60) return;
    // Chosen squad occupies the same starting sector. Swapping identities cannot change challenge difficulty.
    const home = arenaHome((f-this.round.config.faction+3+this.round.config.seed%3)%3);
    let x = home.x, y = home.y;
    const min=ARENA_INSET+ARENA_RADIUS+this.border(), max=720-min;
    for (let tries = 0; tries < 70; tries += 1) {
      const angle = this.nextRandom() * Math.PI * 2, radius = 95 * Math.sqrt(this.nextRandom());
      x = arenaClamp(home.x + Math.cos(angle) * radius, min, max);
      y = arenaClamp(home.y + Math.sin(angle) * radius, min, max);
      if (this.round.entities.every((e: ArenaEntity): boolean => (e.x-x)*(e.x-x)+(e.y-y)*(e.y-y) > 2809)) break;
    }
    this.round.entities.push({ id: this.round.nextId++, faction: f, x: x, y: y,
      vx: (this.nextRandom()-.5)*45, vy: (this.nextRandom()-.5)*45, protectedUntil: this.time()+1,
      shieldUntil: 0, shield: 0, rallyX: x, rallyY: y, rallyUntil: 0, target: -1, predator: -1 });
  }
  private rebuild(): void {
    for (let b = 0; b < this.buckets.length; b += 1) this.buckets[b].length = 0;
    const units = this.round.entities;
    for (let i = 0; i < units.length; i += 1) {
      const x = arenaClamp(Math.floor(units[i].x / CELL),0,9), y = arenaClamp(Math.floor(units[i].y / CELL),0,9);
      this.buckets[y*GRID+x].push(i);
      this.crowding=Math.max(this.crowding,this.buckets[y*GRID+x].length);
    }
  }
  private chooseTargets(i: number): void {
    const units = this.round.entities, e = units[i];
    const cx = Math.floor(e.x/CELL), cy = Math.floor(e.y/CELL);
    let prey = -1, predator = -1, best = 1e9, danger = 1e9;
    for (let y = Math.max(0,cy-3); y <= Math.min(9,cy+3); y += 1) {
      for (let x = Math.max(0,cx-3); x <= Math.min(9,cx+3); x += 1) {
        const bucket = this.buckets[y*GRID+x];
        for (let p = 0; p < bucket.length; p += 1) {
          const j = bucket[p], other = units[j]; if (e.faction === other.faction) continue;
          this.scans += 1;
          const d = (other.x-e.x)*(other.x-e.x)+(other.y-e.y)*(other.y-e.y);
          if (arenaBeats(e.faction,other.faction) && d < best) { best = d; prey = j; }
          if (arenaBeats(other.faction,e.faction) && d < danger) { danger = d; predator = j; }
        }
      }
    }
    e.target = prey; e.predator = predator;
  }
  private move(e: ArenaEntity): void {
    const t = this.time(), units = this.round.entities;
    const prey = e.target >= 0 ? units[e.target] : undefined;
    const predator = e.predator >= 0 ? units[e.predator] : undefined;
    let tx = 360, ty = 360;
    if (prey !== undefined && arenaBeats(e.faction,prey.faction)) { tx = prey.x; ty = prey.y; }
    if (this.scenario.rule === 'zones' && e.id % 5 < 3) { tx = 360; ty = 360; }
    if (e.rallyUntil > t) { tx = e.rallyX; ty = e.rallyY; }
    let dx = tx-e.x, dy = ty-e.y, d = Math.max(1,Math.sqrt(dx*dx+dy*dy));
    let ax = dx/d * 180, ay = dy/d * 180;
    if (predator !== undefined && arenaBeats(predator.faction,e.faction)) {
      dx = e.x-predator.x; dy = e.y-predator.y; d = Math.max(1,Math.sqrt(dx*dx+dy*dy));
      if (d < 200) { ax += dx/d*900*(1-d/200); ay += dy/d*900*(1-d/200); }
    }
    ax += Math.sin(t*1.4+e.id*2.3)*32; ay += Math.cos(t*1.7+e.id*2.3)*32;
    for (let o = 0; o < this.obstacles.length; o += 1) {
      const wall = this.obstacles[o]; dx = e.x-wall.x; dy = e.y-wall.y; d = Math.max(1,Math.sqrt(dx*dx+dy*dy));
      if (d < wall.radius+85) { ax += dx/d*250; ay += dy/d*250; }
    }
    e.vx = (e.vx+ax*STEP)*.982; e.vy = (e.vy+ay*STEP)*.982;
    const speed = Math.sqrt(e.vx*e.vx+e.vy*e.vy);
    if (speed > 84) { e.vx *= 84/speed; e.vy *= 84/speed; }
    e.x += e.vx*STEP; e.y += e.vy*STEP;
    this.bounds(e);
    if (e.shieldUntil < t) e.shield = 0;
  }
  private bounds(e: ArenaEntity): void {
    const min = ARENA_INSET+ARENA_RADIUS+this.border(), max = 720-min;
    if (e.x < min || e.x > max) { e.x = arenaClamp(e.x,min,max); e.vx *= -.4; }
    if (e.y < min || e.y > max) { e.y = arenaClamp(e.y,min,max); e.vy *= -.4; }
    for (let i = 0; i < this.obstacles.length; i += 1) {
      const o = this.obstacles[i], dx = e.x-o.x, dy = e.y-o.y, d = Math.sqrt(dx*dx+dy*dy), r = o.radius+26;
      if (d < r) { e.x = o.x+(d > .01 ? dx/d : 1)*r; e.y = o.y+(d > .01 ? dy/d : 0)*r; }
    }
  }
  private collide(): void {
    const units = this.round.entities, t = this.time();
    this.losses.length = units.length; this.depth.length = units.length;
    this.correctionX.length=units.length; this.correctionY.length=units.length;
    this.losses.fill(-1); this.depth.fill(0);
    this.correctionX.fill(0); this.correctionY.fill(0);
    const diameter=ARENA_RADIUS*2;
    // Read a single position/faction snapshot. Applying separation inside this scan made the
    // grid stale and let traversal order decide which contacts were seen in a crowded group.
    for (let i = 0; i < units.length; i += 1) {
      const a = units[i], cx = Math.floor(a.x/CELL), cy = Math.floor(a.y/CELL);
      for (let y = Math.max(0,cy-1); y <= Math.min(9,cy+1); y += 1) {
        for (let x = Math.max(0,cx-1); x <= Math.min(9,cx+1); x += 1) {
          const bucket = this.buckets[y*GRID+x];
          for (let p = 0; p < bucket.length; p += 1) {
            const j = bucket[p]; if (j <= i) continue; this.checks += 1;
            const b = units[j], dx = b.x-a.x, dy = b.y-a.y, sq = dx*dx+dy*dy;
            if (sq >= diameter*diameter) continue;
            this.contacts+=1;
            const distance = Math.sqrt(sq), nx = distance > .01 ? dx/distance : (a.id < b.id ? 1 : -1), ny = distance > .01 ? dy/distance : 0;
            const penetration = diameter-distance, shift = penetration*.3;
            this.correctionX[i]-=nx*shift; this.correctionY[i]-=ny*shift;
            this.correctionX[j]+=nx*shift; this.correctionY[j]+=ny*shift;
            if (a.faction === b.faction) continue;
            const loser = arenaBeats(a.faction,b.faction) ? j : i;
            const winner = loser === j ? a.faction : b.faction;
            if (penetration > this.depth[loser]) { this.depth[loser] = penetration; this.losses[loser] = winner; }
          }
        }
      }
    }
    for (let i = 0; i < units.length; i += 1) {
      const e = units[i], dx=this.correctionX[i], dy=this.correctionY[i];
      const length=Math.sqrt(dx*dx+dy*dy), scale=length>13 ? 13/length : 1;
      e.x+=dx*scale; e.y+=dy*scale; this.bounds(e);
      if (this.losses[i] < 0 || e.protectedUntil > t) continue;
      if (e.shield > 0 && e.shieldUntil > t) { e.shield = 0; e.protectedUntil = t+.6; continue; }
      e.faction = this.losses[i]; e.protectedUntil = t+.6; e.rallyUntil = 0; e.target = -1; e.predator = -1;
      this.round.conversions += 1; this.sound('turn');
    }
  }
  private recount(): void {
    this.round.counts.fill(0);
    this.round.entities.forEach((e: ArenaEntity) => { this.round.counts[e.faction] += 1; });
  }
  private zone(): void {
    const pressure = [0,0,0], r = this.round;
    for (let i = 0; i < r.entities.length; i += 1) { const e = r.entities[i];
      if ((e.x-360)*(e.x-360)+(e.y-360)*(e.y-360) <= 10000) pressure[e.faction] += 1; }
    const leader = arenaLeader(pressure);
    if (r.capturing !== leader) { r.capturing = leader; r.captureTime = 0; }
    if (leader < 0) return;
    r.captureTime += STEP;
    if (r.captureTime < 1) return;
    if (r.owner !== leader) { r.owner = leader; this.note(`${ARENA_NAMES[leader]}队夺下了据点`); this.sound('zone'); }
    r.scores[leader] = Math.min(this.scenario.target,r.scores[leader]+(2+Math.min(pressure[leader]-1,3)*.5)*STEP);
  }
  private supply(): void {
    const r = this.round, t = this.time();
    for (let offset = 0; offset < 3; offset += 1) {
      const f = (r.config.faction+offset)%3;
      if (r.counts[f] >= 3) { r.lowSince[f] = -1; r.supplyDue[f] = -1; continue; }
      if (r.supplyLeft[f] <= 0) continue;
      if (r.lowSince[f] < 0) r.lowSince[f] = t;
      if (r.supplyDue[f] < 0 && t-r.lowSince[f] >= 4) { r.supplyDue[f] = t+2; this.note(`${ARENA_NAMES[f]}队援军将在 2 秒后到场`); }
      if (r.supplyDue[f] >= 0 && t >= r.supplyDue[f]) {
        const missing = Math.min(3-r.counts[f],60-r.entities.length);
        if (missing <= 0) continue;
        for (let i = 0; i < missing; i += 1) this.spawn(f);
        r.supplyLeft[f] -= 1; r.supplyDue[f] = -1; r.lowSince[f] = -1;
        this.recount(); this.sound('zone');
      }
    }
  }
  private computer(): void {
    if (this.scenario.rule !== 'zones' && this.round.config.mode !== 'challenge') return;
    const r = this.round;
    if (r.config.mode === 'challenge' && r.config.mission === 0 && r.tick % 180 !== 0) return;
    for (let offset = 1; offset < 3; offset += 1) {
      const f = (r.config.faction+offset)%3;
      this.cast(f,0,360,360);
      const own = r.entities.filter((e: ArenaEntity): boolean => e.faction === f);
      if (own.length > 0) { const e = own[Math.floor(this.nextRandom()*own.length)]; this.cast(f,1,e.x,e.y); }
      if (r.scores[f]+15 < Math.max(r.scores[0],r.scores[1],r.scores[2])) this.cast(f,2,360,360);
    }
  }
  private events(): void {
    const r = this.round, t = this.time();
    if (this.scenario.wind && r.tick === 1080) { r.windX = 180+this.nextRandom()*360; r.windY = 210+this.nextRandom()*300;
      this.note('风场即将在 2 秒后出现'); this.sound('warning'); }
    if (this.scenario.wind && t >= 20 && t < 25) {
      r.entities.forEach((e: ArenaEntity) => {
        const dx = e.x-r.windX, dy = e.y-r.windY, d = Math.max(1,Math.sqrt(dx*dx+dy*dy));
        if (d < 150) { e.vx += dx/d*380*STEP; e.vy += dy/d*380*STEP; }
      });
    }
    if (this.scenario.traitor && r.tick === 1200 && r.entities.length > 0) {
      r.traitorId = r.entities[Math.floor(this.nextRandom()*r.entities.length)].id; r.traitorAt = 23;
      this.note('标记的队员将在 3 秒后换队'); this.sound('warning');
    }
    if (r.traitorId > 0 && !r.traitorDone && t >= r.traitorAt) {
      const e = r.entities.find((item: ArenaEntity): boolean => item.id === r.traitorId);
      if (e !== undefined) { e.faction = (e.faction+1)%3; e.protectedUntil = t+.6; e.rallyUntil = 0;
        r.conversions += 1; this.note(`标记队员加入了${ARENA_NAMES[e.faction]}队`); this.sound('turn'); }
      r.traitorDone = true; this.recount();
    }
    if (this.scenario.shrink && r.tick === 720) { this.note('3 秒后围栏开始收拢'); this.sound('warning'); }
  }
  private resolveResult(): void {
    const r = this.round, s = this.scenario, t = this.time();
    const alive = r.counts.filter((n: number): boolean => n > 0).length;
    let done = false, winner = -1, reason = '';
    if (s.rule === 'survival') {
      if (r.counts[r.config.faction] === 0) { done = true; reason = '队友全部转阵'; }
      else if (t+1e-6 >= s.limit) { done = true; winner = r.config.faction; reason = '成功守住了队友'; }
    } else if (s.rule === 'zones') {
      if (Math.max(r.scores[0],r.scores[1],r.scores[2]) >= s.target) { done = true; winner = arenaLeader(r.scores); reason = '据点目标达成'; }
      else if (t+1e-6 >= s.limit) { done = true; winner = arenaLeader(r.scores); reason = '时间到，按据点分结算'; }
      else if (alive === 0 && r.supplyDue.every((n: number): boolean => n < 0) && r.supplyLeft.every((n: number): boolean => n === 0)) {
        done = true; reason = '场上已没有队员'; }
    } else if (alive <= 1) { done = true; winner = arenaLeader(r.counts); reason = '场上只剩一支小队'; }
    else if (t+1e-6 >= s.limit) { done = true; winner = arenaLeader(r.counts); reason = '时间到，按人数结算'; }
    if (!done) return;
    r.finished = true; r.winner = winner; r.won = winner === r.config.faction; r.reason = winner < 0 ? '领先小队并列，本局平局' : reason;
    if (s.rule === 'survival' && !r.won) r.reason = reason;
    if (r.config.mode === 'challenge' && r.won) {
      r.stars = 1 + (r.uses[r.config.faction][2] <= 1 ? 1 : 0) +
        (s.rule === 'survival' ? (r.counts[r.config.faction] >= 3 ? 1 : 0) : (t <= s.limit*.8 ? 1 : 0));
    }
    this.sample(); this.note(r.won ? '你的小队获胜了' : winner < 0 ? '这局没有分出胜负' : `${ARENA_NAMES[winner]}队获胜`);
    this.sound(r.won ? 'win' : 'finish');
  }
  private buildObstacles(): void {
    this.obstacles = this.scenario.obstacles ? [{x:220,y:330,radius:38},{x:500,y:330,radius:38},{x:360,y:535,radius:38}] : [];
  }
  private sample(): void {
    if (this.round.history.length >= 123) return;
    this.round.history.push({ time: this.time(), counts: this.round.counts.slice(), scores: this.round.scores.slice() });
  }
  private note(text: string): void {
    this.round.moments.push({ time: this.time(), text: text });
    if (this.round.moments.length > 48) this.round.moments.shift();
  }
  private effect(kind: number, f: number, x: number, y: number): void {
    if (this.effects.length >= 24) this.effects.shift();
    this.effects.push({kind:kind,faction:f,x:x,y:y,at:this.time()});
  }
  private sound(name: string): void { if (!this.sounds.includes(name) && this.sounds.length < 8) this.sounds.push(name); }
  private valid(r: ArenaRound): boolean {
    if (r === null || r.version !== 1 || !arenaConfigValid(r.config) || typeof r.session !== 'string' || r.session.length < 1 || r.session.length > 100 ||
      !Number.isInteger(r.tick) || r.tick < 0 || r.tick > 7200 || !Number.isInteger(r.rng) || r.rng < 0 || r.rng > 4294967295 ||
      !Array.isArray(r.entities) || r.entities.length > 60 || !Number.isInteger(r.nextId) || r.nextId < 1 || r.nextId > 120 ||
      typeof r.finished !== 'boolean' || typeof r.won !== 'boolean' || typeof r.reported !== 'boolean' ||
      typeof r.traitorDone !== 'boolean' || typeof r.reason !== 'string' || r.reason.length > 120) return false;
    const triples: number[][] = [r.counts,r.scores,r.windLeft,r.supplyLeft,r.lowSince,r.supplyDue];
    if (!triples.every((a: number[]): boolean => Array.isArray(a) && a.length === 3 && a.every((n: number): boolean => Number.isFinite(n) && n >= -1 && n <= 7200))) return false;
    const scenario = arenaScenario(r.config);
    if (r.tick > scenario.limit*60 || !r.counts.every((n:number):boolean => Number.isInteger(n) && n>=0 && n<=60) ||
      !r.scores.every((n:number):boolean => n>=0 && n<=scenario.target) ||
      !r.windLeft.concat(r.supplyLeft).every((n:number):boolean => Number.isInteger(n) && n>=0 && n<=2)) return false;
    if (!Array.isArray(r.readyAt) || !Array.isArray(r.uses) || r.readyAt.length !== 3 || r.uses.length !== 3 ||
      !r.readyAt.concat(r.uses).every((a: number[]): boolean => Array.isArray(a) && a.length === 3 && a.every((n: number): boolean => Number.isFinite(n) && n >= 0 && n <= 7200))) return false;
    if (![r.owner,r.capturing,r.captureTime,r.conversions,r.traitorId,r.traitorAt,r.windX,r.windY,r.winner,r.stars].every((n: number): boolean => Number.isFinite(n))) return false;
    if (![r.owner,r.capturing,r.winner,r.stars,r.conversions,r.traitorId].every((n:number):boolean => Number.isInteger(n)) ||
      r.owner < -1 || r.owner > 2 || r.capturing < -1 || r.capturing > 2 || r.winner < -1 || r.winner > 2 || r.stars < 0 || r.stars > 3 ||
      r.captureTime<0 || r.captureTime>scenario.limit || r.conversions<0 || r.traitorId < -1 ||
      r.windX<0 || r.windX>720 || r.windY<0 || r.windY>720 || r.traitorAt<0 || r.traitorAt>scenario.limit ||
      r.won !== (r.finished && r.winner===r.config.faction) || (!r.finished && (r.reported || r.stars>0 || r.winner!==-1))) return false;
    if (!r.uses.every((a:number[]):boolean => a.every((n:number):boolean => Number.isInteger(n))) ||
      r.windLeft.some((n:number,f:number):boolean => n+r.uses[f][2]!==2)) return false;
    const ids: Set<number> = new Set<number>();
    const counts: number[] = [0,0,0];
    for (let i = 0; i < r.entities.length; i += 1) {
      const e = r.entities[i];
      if (e === null || ![e.id,e.faction,e.x,e.y,e.vx,e.vy,e.protectedUntil,e.shieldUntil,e.shield,e.rallyX,e.rallyY,e.rallyUntil,e.target,e.predator].every((n: number): boolean => Number.isFinite(n)) ||
        !Number.isInteger(e.id) || e.id < 1 || e.id >= r.nextId || ids.has(e.id) || !Number.isInteger(e.faction) || e.faction < 0 || e.faction > 2 ||
        e.x < 0 || e.y < 0 || e.x > 720 || e.y > 720 || Math.abs(e.vx) > 1000 || Math.abs(e.vy) > 1000 ||
        ![e.protectedUntil,e.shieldUntil,e.rallyUntil].every((n:number):boolean => n>=0 && n<=scenario.limit+20) ||
        (e.shield!==0 && e.shield!==1) || e.rallyX<0 || e.rallyX>720 || e.rallyY<0 || e.rallyY>720 ||
        !Number.isInteger(e.target) || !Number.isInteger(e.predator) || e.target < -1 || e.predator < -1 ||
        e.target >= r.entities.length || e.predator >= r.entities.length) return false;
      ids.add(e.id);
      counts[e.faction]+=1;
    }
    if (counts.some((n:number,f:number):boolean => n!==r.counts[f]) || (r.traitorId>0 && !ids.has(r.traitorId))) return false;
    return Array.isArray(r.moments) && r.moments.length <= 48 && r.moments.every((m): boolean => m !== null && Number.isFinite(m.time) && typeof m.text === 'string' && m.text.length <= 120) &&
      Array.isArray(r.history) && r.history.length <= 123 && r.history.every((h): boolean => h !== null && Number.isFinite(h.time) &&
        Array.isArray(h.counts) && Array.isArray(h.scores) && h.counts.length === 3 && h.scores.length === 3 &&
        h.counts.concat(h.scores).every((n: number): boolean => Number.isFinite(n) && n >= 0 && n <= 120));
  }
}
