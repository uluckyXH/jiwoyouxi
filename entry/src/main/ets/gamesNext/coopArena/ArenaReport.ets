import { ArenaEngine } from './ArenaEngine';
import { ArenaRound, ArenaMoment, ArenaSample, ARENA_NAMES, ARENA_COLORS, arenaPractice } from './ArenaModel';
import { ArenaPalette as P } from './ArenaPalette';
import { ArenaAction } from './ArenaControls';

@Component
export struct ArenaReport {
  @Prop @Watch('paint') dark: boolean = false;
  @Prop round: ArenaRound = new ArenaEngine().round;
  @Prop saveFailed: boolean = false;
  @Prop busy: boolean = false;
  retry: () => void = () => {};
  next: () => void = () => {};
  setup: () => void = () => {};
  save: () => void = () => {};
  private canvas: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private chartWidth: number = 280;
  private ready: boolean = false;
  private paint(): void {
    if (!this.ready) return;
    const ctx = this.canvas, w = this.chartWidth, h = 116, data = this.round.history;
    ctx.clearRect(0,0,w,h); ctx.strokeStyle = P.line(this.dark); ctx.lineWidth = 1;
    for (let y = 12; y <= 104; y += 46) { ctx.beginPath(); ctx.moveTo(4,y); ctx.lineTo(w-4,y); ctx.stroke(); }
    const max = Math.max(1,...data.map((s: ArenaSample): number => Math.max(s.counts[0],s.counts[1],s.counts[2])));
    const end = Math.max(1,this.round.tick/60);
    for (let f = 0; f < 3; f += 1) {
      ctx.strokeStyle = ARENA_COLORS[f]; ctx.lineWidth = 2; ctx.setLineDash(f===0 ? [] : f===1 ? [6,3] : [2,3]); ctx.beginPath();
      for (let i = 0; i < data.length; i += 1) {
        const x = 4+(w-8)*data[i].time/end, y = 104-92*data[i].counts[f]/max;
        if (i === 0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
      }
      ctx.stroke();
    }
    ctx.setLineDash([]);
  }
  build() {
    Column({space:12}) {
      Scroll() {
        Column({space:14}) {
          Image($rawfile(this.round.winner >= 0 ? P.piece(this.round.winner,this.dark) : P.scene('mark',this.dark)))
            .width(80).height(72).objectFit(ImageFit.Contain).draggable(false).accessibilityLevel('no')
          Text(this.round.won ? '这一局，漂亮！' : this.round.winner < 0 ? '势均力敌，再来一局' : `${ARENA_NAMES[this.round.winner]}队赢下了这局`)
            .fontSize(23).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).textAlign(TextAlign.Center)
          Text(`${this.round.reason} · ${Math.ceil(this.round.tick/60)} 秒`).fontSize(13).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
          if (this.round.config.mode === 'challenge') {
            Row({space:10}) {
              ForEach([1,2,3], (i: number) => {
                Image($rawfile(P.icon('star',this.dark))).width(28).height(28).draggable(false)
                  .opacity(i<=this.round.stars ? 1 : .25).accessibilityText(i<=this.round.stars ? '获得一星' : '未获得')
              })
              Text(`${this.round.stars} / 3`).fontSize(18).fontColor(P.accent(this.dark))
            }
          }
          ForEach([0,1,2], (f: number) => {
            Row({space:8}) {
              Image($rawfile(P.piece(f,this.dark))).width(30).height(30).draggable(false).accessibilityLevel('no')
              Text(`${ARENA_NAMES[f]}${f===this.round.config.faction ? ' · 你' : ''}`).fontSize(14).fontColor(P.faction(f,this.dark)).layoutWeight(1)
              Text(`${this.round.counts[f]} 人`).fontSize(15).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
              if (this.round.scores.some((s: number): boolean => s>0)) {
                Text(`${Math.floor(this.round.scores[f])} 分`).fontSize(13).fontColor(P.muted(this.dark)).width(62).textAlign(TextAlign.End)
              }
            }.width('100%').padding(10).borderRadius(16).backgroundColor(P.soft(this.dark))
          })
          Column({space:6}) {
            Text('这一局，小队如何壮大').fontSize(15).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
            Canvas(this.canvas).width('100%').height(116).onReady(() => { this.ready=true; this.paint(); })
              .onAreaChange((oldArea:Area,area:Area) => { this.chartWidth=Number(area.width); this.paint(); })
              .accessibilityText(`人数走势，结束时石头 ${this.round.counts[0]} 人，剪刀 ${this.round.counts[1]} 人，布 ${this.round.counts[2]} 人`)
            Text('石头：实线   剪刀：长虚线   布：点线').fontSize(10).fontColor(P.muted(this.dark))
          }.width('100%').alignItems(HorizontalAlign.Start)
          Text(`发生了 ${this.round.conversions} 次转阵 · 你使用了 ${this.round.uses[this.round.config.faction].reduce((a:number,b:number):number => a+b,0)} 次指挥`)
            .fontSize(12).lineHeight(20).fontColor(P.muted(this.dark))
          ForEach(this.round.moments.slice(-5), (m: ArenaMoment) => {
            Text(`${Math.floor(m.time)}s  ${m.text}`).width('100%').fontSize(12).lineHeight(19).fontColor(P.muted(this.dark))
          })
          if (arenaPractice(this.round.config)) {
            Text('自由练习已结束：不计正式战绩，成就照常记录。').fontSize(12).fontColor(P.muted(this.dark))
          }
          if (this.saveFailed) {
            ArenaAction({label:'记录暂未保存，点此重试',icon:'save',dark:this.dark,primary:false,action:this.save})
          }
          if (this.round.won && this.round.config.mode==='challenge' && this.round.config.mission<7) {
            ArenaAction({label:'下一关',icon:'play',dark:this.dark,active:!this.busy,action:this.next})
          }
          ArenaAction({label:this.busy ? '保存记录中…' : this.round.config.mode==='challenge' ? '再挑战一次' : '再来一局',icon:'restart',dark:this.dark,active:!this.busy,action:this.retry})
          ArenaAction({label:'返回庭院，换个玩法',icon:'home',primary:false,dark:this.dark,active:!this.busy,action:this.setup})
        }.width('100%').padding({bottom:8})
      }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').height('100%').padding(18).borderRadius(24).backgroundColor(P.surface(this.dark))
  }
}
