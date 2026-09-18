import { hilog } from '@kit.PerformanceAnalysisKit';

/** Low-volume CPU submission diagnostics. An on-demand board has no meaningful callback FPS. */
export class BlockPerformance {
  private start: number = 0;
  private logicCalls: number = 0;
  private logicMs: number = 0;
  private logicPeak: number = 0;
  private paints: number = 0;
  private paintMs: number = 0;
  private paintPeak: number = 0;

  reset(now: number): void {
    this.start = now; this.logicCalls = 0; this.logicMs = 0; this.logicPeak = 0;
    this.paints = 0; this.paintMs = 0; this.paintPeak = 0;
  }
  logic(ms: number): void {
    this.logicCalls += 1; this.logicMs += ms; this.logicPeak = Math.max(this.logicPeak, ms);
  }
  paint(ms: number): void {
    this.paints += 1; this.paintMs += ms; this.paintPeak = Math.max(this.paintPeak, ms);
  }
  report(now: number, level: number, occupied: number): void {
    if (now - this.start < 5000) return;
    hilog.info(0, 'BlockWorkshopPerf', '%{public}s',
      `[方块工坊 v1 按需汇总] 等级=${level} 固定格=${occupied} ` +
      `逻辑调用=${this.logicCalls} 逻辑平均=${(this.logicMs / Math.max(1, this.logicCalls)).toFixed(3)}ms ` +
      `逻辑峰值=${this.logicPeak.toFixed(3)}ms 实际重画=${this.paints} ` +
      `绘制提交平均=${(this.paintMs / Math.max(1, this.paints)).toFixed(3)}ms ` +
      `绘制峰值=${this.paintPeak.toFixed(3)}ms；按需刷新，不以回调次数冒充呈现帧率`);
    this.reset(now);
  }
}
