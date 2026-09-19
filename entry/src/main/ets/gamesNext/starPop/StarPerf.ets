import { hilog } from '@kit.PerformanceAnalysisKit';
import systemDateTime from '@ohos.systemDateTime';
import displaySync from '@ohos.graphics.displaySync';

export function starNow(): number {
  return systemDateTime.getUptime(systemDateTime.TimeType.STARTUP, true) / 1000000;
}

export interface StarMoveTiming {
  logic: number;
  state: number;
  save: number;
  audio: number;
  prepare: number;
  animation: number;
  total: number;
  group: number;
  remaining: number;
  shifts: boolean;
}

/** Short, bounded diagnostics around user actions. No sampling or logging while idle. */
export class StarPerf {
  private visit: string = Date.now().toString(36);
  private entered: number = starNow();
  private moves: number = 0;
  private saves: number = 0;
  private blocked: number = 0;
  private savePeak: number = 0;
  private sync: displaySync.DisplaySync | undefined = undefined;
  private sampleTimer: number = -1;
  private sampleToken: number = 0;
  private sampleName: string = '';
  private sampleStarted: number = 0;
  private previousFrame: number = -1;
  private firstFrame: number = 0;
  private intervals: number[] = [];
  private released: boolean = false;

  event(name: string, detail: string = ''): void {
    this.log(`[${name} v3] ${detail}`);
  }

  duration(name: string, started: number, detail: string = '', threshold: number = 0): void {
    const ms = starNow() - started;
    if (ms >= threshold) this.log(`[${name} v3] 耗时=${ms.toFixed(2)}ms ${detail}`);
  }

  move(t: StarMoveTiming): void {
    this.moves++;
    this.log(`[消除 v3] 次数=${this.moves} 规则=${t.logic.toFixed(2)}ms 同步提交=${t.total.toFixed(2)}ms ` +
      `状态=${t.state.toFixed(2)}ms 存档入队=${t.save.toFixed(2)}ms 音效提交=${t.audio.toFixed(2)}ms ` +
      `位移准备=${t.prepare.toFixed(2)}ms 动画提交=${t.animation.toFixed(2)}ms ` +
      `连块=${t.group} 剩余=${t.remaining} 左靠=${t.shifts}；逐棋子更新，提交含animateTo同步刷新，不含GPU呈现`);
  }

  inputBlocked(reason: string): void {
    this.blocked++;
    if (this.blocked === 1 || this.blocked % 10 === 0) {
      this.log(`[输入拦截 v3] 累计=${this.blocked} 原因=${reason}`);
    }
  }

  saved(started: number, ok: boolean, pending: number): void {
    const ms = starNow() - started;
    this.saves++;
    this.savePeak = Math.max(this.savePeak, ms);
    if (!ok || ms >= 100 || this.saves === 1 || this.saves % 10 === 0) {
      this.log(`[保存链路 v3] 次数=${this.saves} 含排队及成就=${ms.toFixed(2)}ms 峰值=${this.savePeak.toFixed(2)}ms ` +
        `成功=${ok} 待确认事件=${pending}`);
    }
  }

  animationDelay(started: number, planned: number): void {
    const actual = starNow() - started;
    if (actual - planned >= 12) {
      this.log(`[动画调度延迟 v3] 计划=${planned}ms 实际=${actual.toFixed(2)}ms 超时=${(actual - planned).toFixed(2)}ms`);
    }
  }

  layout(width: number, height: number, cell: number, wide: boolean, detail: string = ''): void {
    this.log(`[布局 v3] 可用=${width.toFixed(1)}×${height.toFixed(1)}vp 格=${cell.toFixed(1)}vp 侧栏=${wide} ${detail}`);
  }

  // A requested 60 Hz callback is a JS scheduling probe, never a GPU-presented FPS claim.
  sample(name: string, duration: number = 600): void {
    if (this.released) return;
    this.stopSample('下一动作');
    const token = ++this.sampleToken;
    this.sampleName = name;
    this.sampleStarted = starNow();
    this.previousFrame = -1;
    this.firstFrame = 0;
    this.intervals = [];
    try {
      const sync = displaySync.create();
      this.sync = sync;
      sync.setExpectedFrameRateRange({ min: 30, max: 60, expected: 60 });
      sync.on('frame', () => {
        if (this.released || token !== this.sampleToken) return;
        const now = starNow();
        if (this.previousFrame < 0) this.firstFrame = now - this.sampleStarted;
        else if (this.intervals.length < 120) this.intervals.push(now - this.previousFrame);
        this.previousFrame = now;
      });
      sync.start();
      this.sampleTimer = setTimeout(() => {
        if (token === this.sampleToken) this.stopSample('完成');
      }, duration);
    } catch (_) {
      this.stopSample('不可用');
      this.event('帧采样不可用', '保留操作耗时；不启用定时器模拟帧率');
    }
  }

  stopSample(reason: string): void {
    this.sampleToken++;
    if (this.sampleTimer >= 0) clearTimeout(this.sampleTimer);
    this.sampleTimer = -1;
    const sync = this.sync;
    this.sync = undefined;
    if (sync !== undefined) {
      try { sync.stop(); } catch (_) {}
      try { sync.off('frame'); } catch (_) {}
    }
    if (this.sampleName.length === 0) return;
    const intervals = this.intervals;
    const elapsed = starNow() - this.sampleStarted;
    intervals.sort((a: number, b: number): number => a - b);
    const p95 = intervals.length > 0 ? intervals[Math.ceil(intervals.length * .95) - 1] : 0;
    const peak = intervals.length > 0 ? intervals[intervals.length - 1] : 0;
    this.log(`[短帧采样 v3] 场景=${this.sampleName} 结束=${reason} 时长=${elapsed.toFixed(2)}ms ` +
      `首回调等待=${this.firstFrame.toFixed(2)}ms 间隔数=${intervals.length} 间隔P95=${p95.toFixed(2)}ms ` +
      `最长=${peak.toFixed(2)}ms 超34ms=${intervals.filter((ms: number): boolean => ms > 34).length}；60Hz回调采样，非GPU帧率`);
    this.sampleName = '';
    this.intervals = [];
  }

  release(): void {
    this.stopSample('离开页面');
    this.event('页面释放', `消除=${this.moves} 输入拦截=${this.blocked} 保存=${this.saves}`);
    this.released = true;
  }

  private log(message: string): void {
    if (!this.released) {
      hilog.info(0x0000, 'StarPopPerf', '%{public}s',
        `访问=${this.visit} t=${(starNow() - this.entered).toFixed(1)}ms ${message}`);
    }
  }
}
