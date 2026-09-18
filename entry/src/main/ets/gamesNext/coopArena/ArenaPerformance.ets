import { hilog } from '@kit.PerformanceAnalysisKit';
export interface ArenaPerfScene {
  session: string; label: string; seed: number; faction: number; initial: string; window: string; board: number; density: number;
  fold: number; dark: boolean; reduced: boolean; sound: boolean;
}
export interface ArenaTiming {
  at: number; interval: number; logic: number; paint: number; total: number; save: number;
  steps: number; checks: number; scans: number; dropped: number; count: number; seed: number;
  hud: number; hudChanged: boolean; clock: string; sprites: string; audio: number; elapsed: number;
  rock: number; scissors: number; cloth: number; effects: number; conversions: number; contacts: number; crowding: number;
  sampled: number; grid: number; seek: number; move: number; contact: number; rules: number;
}
/** Aggregates locally. A few bounded lines per five seconds; never a log per unit/contact. */
export class ArenaPerformance {
  private scene: ArenaPerfScene | undefined = undefined;
  private start: number = 0;
  private sequence: number = 0;
  private frames: number = 0;
  private logic: number = 0;
  private paint: number = 0;
  private total: number = 0;
  private peak: number = 0;
  private savePeak: number = 0;
  private saveCompletePeak: number = 0;
  private saveFailures: number = 0;
  private longest: number = 0;
  private slow: number = 0;
  private intervals: number[] = [];
  private steps: number = 0;
  private checks: number = 0;
  private scans: number = 0;
  private dropped: number = 0;
  private hud: number = 0;
  private hudUpdates: number = 0;
  private audio: number = 0;
  private logicPeak: number = 0;
  private paintPeak: number = 0;
  private hudPeak: number = 0;
  private lastDetail: number = -10000;
  private previousTotal: number = 0;
  private externalPeak: number = 0;
  private minCount: number = 60;
  private maxCount: number = 0;
  private effectPeak: number = 0;
  private contacts: number = 0;
  private crowding: number = 0;
  private sampled: number = 0;
  private grid: number = 0;
  private seek: number = 0;
  private move: number = 0;
  private contact: number = 0;
  private rules: number = 0;
  private lastFrame: ArenaTiming | undefined = undefined;

  begin(now: number, scene: ArenaPerfScene): void {
    if(this.scene?.session!==scene.session)this.sequence=0;
    this.scene=scene; this.reset(now); this.describe('采样开始');
  }
  context(scene: ArenaPerfScene): void {
    if(JSON.stringify(scene)===JSON.stringify(this.scene))return;
    // Keep different themes/windows/effect settings in separate measurement windows.
    this.finish('场景变化'); this.scene=scene; this.describe('场景变化');
  }
  reset(now: number): void { this.clear(now); this.lastDetail=-10000; this.previousTotal=0; }
  private clear(now: number): void {
    this.start=now; this.frames=0; this.logic=0; this.paint=0; this.total=0; this.peak=0; this.savePeak=0;
    this.longest=0; this.slow=0; this.intervals.length=0; this.steps=0; this.checks=0; this.scans=0; this.dropped=0;
    this.hud=0; this.hudUpdates=0; this.audio=0; this.logicPeak=0; this.paintPeak=0; this.hudPeak=0; this.externalPeak=0;
    this.minCount=60; this.maxCount=0; this.effectPeak=0; this.contacts=0; this.crowding=0;
    this.sampled=0; this.grid=0; this.seek=0; this.move=0; this.contact=0; this.rules=0;
    this.saveCompletePeak=0; this.saveFailures=0; this.lastFrame=undefined;
  }
  private describe(reason: string): void {
    const s=this.scene; if(s===undefined)return;
    this.log(`[${reason} v4] 局=${s.session} 场景=${s.label} 种子=${s.seed} 我方=${['石头','剪刀','布'][s.faction]} 开局石/剪/布=${s.initial} `+
      `窗口=${s.window}vp 战场=${s.board.toFixed(1)}vp 密度=${s.density.toFixed(2)} 折叠状态=${s.fold} 主题=${s.dark ? '深色' : '浅色'} `+
      `效果=${s.reduced ? '轻量' : '柔和'} 音效=${s.sound ? '开' : '关'}；连续网格索引，逻辑60Hz，约每11次回调抽样拆分；请复制同一局连续日志`);
  }
  frame(f: ArenaTiming): void {
    // A settings change can end a partial window between callbacks. Do not charge paused time.
    if(this.frames===0 && this.lastFrame===undefined && this.start<f.at-f.interval)this.start=f.at-f.interval;
    this.lastFrame=f;
    this.frames+=1; this.logic+=f.logic; this.paint+=f.paint; this.total+=f.total; this.peak=Math.max(this.peak,f.total);
    this.hud+=f.hud; if(f.hudChanged)this.hudUpdates+=1; this.audio+=f.audio;
    this.logicPeak=Math.max(this.logicPeak,f.logic); this.paintPeak=Math.max(this.paintPeak,f.paint); this.hudPeak=Math.max(this.hudPeak,f.hud);
    const outside=Math.max(0,f.interval-this.previousTotal); this.externalPeak=Math.max(this.externalPeak,outside);
    if((f.interval>45 || f.total>24) && f.at-this.lastDetail>=2000) {
      this.lastDetail=f.at;
      this.log(`[停顿详情 v4] 局=${this.scene?.session ?? f.seed} t=${f.elapsed.toFixed(1)}s 单位=${f.count} 特效=${f.effects} `+
        `间隔=${f.interval.toFixed(2)}ms 回调外间隙=${outside.toFixed(2)}ms 逻辑=${f.logic.toFixed(3)}ms `+
        `绘制提交=${f.paint.toFixed(3)}ms UI提交=${f.hud.toFixed(3)}ms 音效提交=${f.audio.toFixed(3)}ms 存档提交=${f.save.toFixed(3)}ms `+
        `总回调=${f.total.toFixed(3)}ms 补步=${f.steps} 接触=${f.contacts} 最密格=${f.crowding} 素材=${f.sprites}`);
    }
    this.previousTotal=f.total;
    this.steps+=f.steps; this.checks+=f.checks; this.scans+=f.scans; this.dropped+=f.dropped;
    this.minCount=Math.min(this.minCount,f.count); this.maxCount=Math.max(this.maxCount,f.count); this.effectPeak=Math.max(this.effectPeak,f.effects);
    this.contacts+=f.contacts; this.crowding=Math.max(this.crowding,f.crowding);
    this.sampled+=f.sampled; this.grid+=f.grid; this.seek+=f.seek; this.move+=f.move; this.contact+=f.contact; this.rules+=f.rules;
    this.savePeak=Math.max(this.savePeak,f.save); this.longest=Math.max(this.longest,f.interval); if(f.interval>33.4)this.slow++;
    if(this.intervals.length<640)this.intervals.push(f.interval);
    if(f.at-this.start>=5000)this.flush('5秒汇总');
  }
  saved(ms: number, ok: boolean, session: string): void {
    if(this.scene?.session===session) {
      this.saveCompletePeak=Math.max(this.saveCompletePeak,ms); if(!ok)this.saveFailures+=1;
    }
    if(!ok || ms>=100)this.log(`[存档完成 v4] 局=${session} 含排队总耗时=${ms.toFixed(2)}ms 成功=${ok}`);
  }
  stall(interval: number): void {
    this.log(`[长停顿 v4] 局=${this.scene?.session ?? '未知'} 回调间隔=${interval.toFixed(2)}ms；对局自动暂停，未继续追补`);
  }
  finish(reason: string): void { this.flush(`采样结束·${reason}`); }
  private flush(reason: string): void {
    const f=this.lastFrame;
    if(f===undefined)return;
    const span=f.at-this.start;
    if(this.frames<2 || span<=0) { this.clear(f.at); return; }
    this.sequence+=1;
    const id=`局=${this.scene?.session ?? f.seed} 段=${this.sequence}`;
    this.intervals.sort((a:number,b:number):number=>a-b);
    const p95=this.intervals[Math.min(this.intervals.length-1,Math.floor(this.intervals.length*.95))]??0;
    this.log(`[${reason} v4] ${id} 场景=${this.scene?.label ?? '未知'} t=${f.elapsed.toFixed(1)}s `+
      `采样=${(span/1000).toFixed(2)}s 单位=${this.minCount}–${this.maxCount} 时钟=${f.clock} 素材=${f.sprites} `+
      `回调FPS=${(this.frames*1000/span).toFixed(1)} 间隔P95=${p95.toFixed(2)}ms 最长间隔=${this.longest.toFixed(2)}ms 慢帧=${this.slow}/${this.frames} `+
      `逻辑平均/峰值=${(this.logic/this.frames).toFixed(3)}/${this.logicPeak.toFixed(3)}ms `+
      `逻辑摊销/步=${(this.steps>0 ? this.logic/this.steps : 0).toFixed(3)}ms `+
      `绘制提交平均/峰值=${(this.paint/this.frames).toFixed(3)}/${this.paintPeak.toFixed(3)}ms `+
      `总回调平均/峰值=${(this.total/this.frames).toFixed(3)}/${this.peak.toFixed(3)}ms 回调外间隙峰值=${this.externalPeak.toFixed(2)}ms；回调FPS不是GPU呈现帧率`);
    const divisor=Math.max(1,this.sampled);
    this.log(`[模拟拆分 v4] ${id} 抽样步=${this.sampled} 抽样每步平均：建网格=${(this.grid/divisor).toFixed(3)}ms `+
      `寻敌=${(this.seek/divisor).toFixed(3)}ms 移动=${(this.move/divisor).toFixed(3)}ms `+
      `碰撞含重建=${(this.contact/divisor).toFixed(3)}ms 事件技能计分=${(this.rules/divisor).toFixed(3)}ms；`+
      `步/回调=${(this.steps/this.frames).toFixed(2)} 候选配对/回调=${(this.checks/this.frames).toFixed(1)} `+
      `实际接触/回调=${(this.contacts/this.frames).toFixed(1)} 寻敌检查/回调=${(this.scans/this.frames).toFixed(1)} 丢弃追补=${this.dropped.toFixed(1)}ms`);
    this.log(`[场景负载 v4] ${id} 当前石/剪/布=${f.rock}/${f.scissors}/${f.cloth} 转阵累计=${f.conversions} `+
      `最密格=${this.crowding} 特效峰值=${this.effectPeak} UI更新=${this.hudUpdates}/${this.frames} `+
      `UI提交平均/峰值=${(this.hud/this.frames).toFixed(3)}/${this.hudPeak.toFixed(3)}ms 音效提交平均=${(this.audio/this.frames).toFixed(3)}ms `+
      `存档提交峰值=${this.savePeak.toFixed(3)}ms 存档完成峰值含排队=${this.saveCompletePeak.toFixed(3)}ms 存档失败=${this.saveFailures}`);
    this.clear(f.at);
  }
  private log(text: string): void { hilog.info(0,'CoopArenaPerf','%{public}s',text); }
}
