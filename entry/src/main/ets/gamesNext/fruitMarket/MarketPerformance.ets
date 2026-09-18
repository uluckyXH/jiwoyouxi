import systemDateTime from '@ohos.systemDateTime';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MarketEngine } from './MarketEngine';

// Temporary diagnostics: aggregate every five seconds, rate-limit stall details.
export const MARKET_PROFILE: boolean = true;

export function marketNow(): number {
  return systemDateTime.getUptime(systemDateTime.TimeType.STARTUP, true) / 1000000;
}

export class MarketPerformance {
  private start: number = 0;
  private previous: number = 0;
  private previousTotal: number = 0;
  private lastStall: number = -10000;
  private intervals: number[] = [];
  private physics: number = 0;
  private paint: number = 0;
  private total: number = 0;
  private count: number = 0;
  private steps: number = 0;
  private solvedSteps: number = 0;
  private pairs: number = 0;
  private broad: number = 0;
  private passes: number = 0;
  private asleep: number = 0;
  private painted: number = 0;
  private activeCount: number = 0;
  private activePhysics: number = 0;
  private physicsMax: number = 0;
  private paintMax: number = 0;
  private totalMax: number = 0;
  private saveMax: number = 0;
  private width: number = 0;
  private height: number = 0;
  private density: number = 0;

  viewport(width: number, height: number, density: number): void {
    if (width <= 0 || height <= 0 || (width === this.width && height === this.height && density === this.density)) return;
    this.width = width;
    this.height = height;
    this.density = density;
    hilog.info(0x0000, 'FruitMarketPerf', '%{public}s',
      `[水果摊 v4 按需绘制] 画布=${width.toFixed(1)}×${height.toFixed(1)}vp 密度=${density.toFixed(2)} ` +
      `葡萄预期直径=${(26 * width * density / 360).toFixed(1)}px SVG直绘/局部休眠/复用接触配对；` +
      `物理60Hz/最多6轮/最多补2步；回调FPS非GPU帧率，区间耗时含线程抢占等待`);
  }

  begin(bodies: number, clock: string = 'unknown'): void {
    this.reset();
    hilog.info(0x0000, 'FruitMarketPerf', '%{public}s',
      `[开始采样 v4] 水果=${bodies} 回调源=${clock} 每5秒汇总；单次停顿详情最多每2秒一条`);
  }

  reset(): void {
    this.start = 0;
    this.previous = 0;
    this.previousTotal = 0;
    this.intervals = [];
    this.physics = 0;
    this.paint = 0;
    this.total = 0;
    this.count = 0;
    this.steps = 0;
    this.solvedSteps = 0;
    this.pairs = 0;
    this.broad = 0;
    this.passes = 0;
    this.asleep = 0;
    this.painted = 0;
    this.activeCount = 0;
    this.activePhysics = 0;
    this.physicsMax = 0;
    this.paintMax = 0;
    this.totalMax = 0;
    this.saveMax = 0;
  }

  frame(started: number, physicsEnd: number, drawStart: number, drawEnd: number, finished: number,
    engine: MarketEngine, painted: boolean, saveSubmitMs: number): void {
    if (this.start === 0) this.start = started;
    const gap = this.previous > 0 ? started - this.previous : 0;
    if (this.previous > 0) this.intervals.push(gap);
    const physics = physicsEnd - started;
    const paint = drawEnd - drawStart;
    const total = finished - started;
    if ((gap > 80 || physics > 40 || paint > 20 || saveSubmitMs > 10 || total > 50) && started - this.lastStall >= 2000) {
      this.lastStall = started;
      hilog.info(0x0000, 'FruitMarketPerf', '%{public}s',
        `[停顿详情 v4] 水果=${engine.round.bodies.length} 休眠水果=${engine.sleepingBodies} ` +
        `回调间隔=${gap.toFixed(2)}ms 回调外间隙=${Math.max(0, gap - this.previousTotal).toFixed(2)}ms ` +
        `物理=${physics.toFixed(3)}ms 绘制提交=${paint.toFixed(3)}ms 存档提交=${saveSubmitMs.toFixed(3)}ms ` +
        `总回调=${total.toFixed(3)}ms 已重画=${painted} 求解步=${engine.lastSolvedSteps} ` +
        `求解轮=${engine.lastSolverPasses} 窄相检查=${engine.lastPairChecks}`);
    }
    this.previous = started;
    this.previousTotal = total;
    this.physics += physics;
    this.paint += paint;
    this.total += total;
    this.count += 1;
    this.steps += engine.lastSteps;
    this.solvedSteps += engine.lastSolvedSteps;
    this.pairs += engine.lastPairChecks;
    this.broad += engine.lastBroadChecks;
    this.passes += engine.lastSolverPasses;
    if (engine.sleeping) this.asleep += 1;
    if (painted) this.painted += 1;
    if (engine.lastSolvedSteps > 0) {
      this.activeCount += 1;
      this.activePhysics += physics;
    }
    this.physicsMax = Math.max(this.physicsMax, physics);
    this.paintMax = Math.max(this.paintMax, paint);
    this.totalMax = Math.max(this.totalMax, total);
    this.saveMax = Math.max(this.saveMax, saveSubmitMs);
    const elapsed = finished - this.start;
    if (elapsed < 5000) return;
    this.intervals.sort((a: number, b: number): number => a - b);
    const p95 = this.intervals.length > 0 ? this.intervals[Math.floor(this.intervals.length * 0.95)] : elapsed;
    const maximum = this.intervals.length > 0 ? this.intervals[this.intervals.length - 1] : elapsed;
    const slow = this.intervals.filter((interval: number): boolean => interval > 33.4).length;
    hilog.info(0x0000, 'FruitMarketPerf', '%{public}s',
      `[5秒汇总 v4] 水果=${engine.round.bodies.length} 休眠水果=${engine.sleepingBodies} ` +
      `回调FPS=${(1000 * Math.max(0, this.count - 1) / elapsed).toFixed(1)} ` +
      `帧间隔P95=${p95.toFixed(2)}ms 最长间隔=${maximum.toFixed(2)}ms 慢帧=${slow}/${this.intervals.length} ` +
      `物理平均=${(this.physics / this.count).toFixed(3)}ms 活动物理平均=${(this.activePhysics / Math.max(1, this.activeCount)).toFixed(3)}ms ` +
      `物理峰值=${this.physicsMax.toFixed(3)}ms 步/回调=${(this.steps / this.count).toFixed(2)} 求解步/回调=${(this.solvedSteps / this.count).toFixed(2)} ` +
      `求解轮/回调=${(this.passes / this.count).toFixed(2)} 宽相检查/回调=${(this.broad / this.count).toFixed(1)} ` +
      `窄相检查/回调=${(this.pairs / this.count).toFixed(1)} 休眠回调=${this.asleep}/${this.count} 重画回调=${this.painted}/${this.count} ` +
      `绘制提交平均=${(this.paint / this.count).toFixed(3)}ms 绘制峰值=${this.paintMax.toFixed(3)}ms ` +
      `存档提交峰值=${this.saveMax.toFixed(3)}ms 总回调平均=${(this.total / this.count).toFixed(3)}ms 总回调峰值=${this.totalMax.toFixed(3)}ms`);
    this.reset();
  }
}
