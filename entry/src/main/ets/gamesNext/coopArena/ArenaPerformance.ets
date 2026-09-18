import { hilog } from '@kit.PerformanceAnalysisKit';
export interface ArenaTiming {
  at: number; interval: number; logic: number; paint: number; total: number; save: number;
  steps: number; checks: number; scans: number; dropped: number; count: number; seed: number;
}
export class ArenaPerformance {
  private start: number = 0;
  private frames: number = 0;
  private logic: number = 0;
  private paint: number = 0;
  private total: number = 0;
  private peak: number = 0;
  private savePeak: number = 0;
  private longest: number = 0;
  private slow: number = 0;
  private intervals: number[] = [];
  private steps: number = 0;
  private checks: number = 0;
  private scans: number = 0;
  private dropped: number = 0;
  reset(now: number): void {
    this.start=now; this.frames=0; this.logic=0; this.paint=0; this.total=0; this.peak=0; this.savePeak=0;
    this.longest=0; this.slow=0; this.intervals=[]; this.steps=0; this.checks=0; this.scans=0; this.dropped=0;
  }
  frame(f: ArenaTiming): void {
    this.frames+=1; this.logic+=f.logic; this.paint+=f.paint; this.total+=f.total; this.peak=Math.max(this.peak,f.total);
    this.steps+=f.steps; this.checks+=f.checks; this.scans+=f.scans; this.dropped+=f.dropped;
    this.savePeak=Math.max(this.savePeak,f.save); this.longest=Math.max(this.longest,f.interval); if(f.interval>33.4)this.slow++;
    if(this.intervals.length<640)this.intervals.push(f.interval);
    if(f.at-this.start<5000)return;
    this.intervals.sort((a:number,b:number):number=>a-b);
    const p95=this.intervals[Math.min(this.intervals.length-1,Math.floor(this.intervals.length*.95))]??0;
    hilog.info(0,'CoopArenaPerf','%{public}s',`[鸡窝乱斗 v1 / 5秒汇总] 单位=${f.count} 种子=${f.seed} 回调FPS=${(this.frames*1000/(f.at-this.start)).toFixed(1)} `+
      `间隔P95=${p95.toFixed(2)}ms 最长间隔=${this.longest.toFixed(2)}ms 慢帧=${this.slow}/${this.frames} `+
      `逻辑平均=${(this.logic/this.frames).toFixed(3)}ms 绘制提交平均=${(this.paint/this.frames).toFixed(3)}ms `+
      `总回调平均=${(this.total/this.frames).toFixed(3)}ms 总回调峰值=${this.peak.toFixed(3)}ms 存档提交峰值=${this.savePeak.toFixed(3)}ms `+
      `步/回调=${(this.steps/this.frames).toFixed(2)} 配对/回调=${(this.checks/this.frames).toFixed(1)} 寻敌检查/回调=${(this.scans/this.frames).toFixed(1)} `+
      `丢弃追补=${this.dropped.toFixed(1)}ms；回调FPS不是GPU呈现帧率`);
    this.reset(f.at);
  }
}
