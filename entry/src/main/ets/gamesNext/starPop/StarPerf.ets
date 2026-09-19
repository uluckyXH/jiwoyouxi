import { hilog } from '@kit.PerformanceAnalysisKit';
/** Action timings, not a frame-rate claim; no idle sampling timer. */
export class StarPerf {
  private count: number = 0;
  private total: number = 0;
  private peak: number = 0;
  logMove(ms: number, group: number, remaining: number): void {
    this.count++; this.total += ms; this.peak = Math.max(this.peak, ms);
    if (this.count % 10 === 0 || ms >= 16) {
      hilog.info(0x0000, 'StarPopPerf', '%{public}s', `[消除逻辑 v1] 次数=${this.count} 本次=${ms}ms 平均=${(this.total / this.count).toFixed(2)}ms 峰值=${this.peak}ms 连块=${group} 剩余=${remaining}；原生短动画，静止无帧循环；不含GPU耗时`);
    }
  }
  layout(width: number, height: number, cell: number, wide: boolean): void {
    hilog.info(0x0000, 'StarPopPerf', '%{public}s', `[布局 v1] 可用=${width.toFixed(1)}×${height.toFixed(1)}vp 格=${cell.toFixed(1)}vp 侧栏=${wide}；80格，按实际可用区域适配`);
  }
}
