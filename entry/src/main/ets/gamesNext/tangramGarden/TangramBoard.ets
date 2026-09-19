import { TangramEngine } from './TangramEngine';
import { TangramPoint } from './TangramGeometry';
import { TANGRAM_WORLD_HEIGHT } from './TangramLevels';
import { TangramPalette as P } from './TangramPalette';
import { TangramRenderer } from './TangramRenderer';

@Component
export struct TangramBoard {
  engine: TangramEngine = new TangramEngine();
  @Prop @Watch('redraw') dark: boolean = false;
  @Prop @Watch('redraw') revision: number = 0;
  @Prop @Watch('redraw') edge: number = 340;
  @Prop @Watch('interactionChanged') active: boolean = true;
  input: (phase: string, p: TangramPoint) => void = () => {};
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private renderer: TangramRenderer = new TangramRenderer();
  private ready: boolean = false;
  private pointerId: number = -1;
  redraw(): void { if (this.ready) this.renderer.draw(this.ctx, this.edge, this.engine, this.dark); }
  interactionChanged(): void { if (!this.active) this.pointerId = -1; }
  private touch(event: TouchEvent): void {
    if (!this.active) return;
    if (event.type === TouchType.Down) {
      // A backgrounded window may omit the final Up. A fresh single-finger Down
      // must replace that stale pointer instead of making the board unresponsive.
      if (event.touches.length !== 1) return;
      this.pointerId = event.touches[0].id;
    }
    const points = event.type === TouchType.Up || event.type === TouchType.Cancel ? event.changedTouches : event.touches;
    const p = points.find((point: TouchObject): boolean => point.id === this.pointerId);
    if (event.type === TouchType.Cancel) {
      this.pointerId = -1; this.input('cancel', { x: 0, y: 0 }); return;
    }
    if (p === undefined) return;
    const phase = event.type === TouchType.Down ? 'begin' : event.type === TouchType.Move ? 'drag' : 'end';
    this.input(phase, { x: p.x * 8 / this.edge, y: p.y * 8 / this.edge });
    if (event.type === TouchType.Up) this.pointerId = -1;
    event.stopPropagation();
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Canvas(this.ctx).width(this.edge).height(this.edge * TANGRAM_WORLD_HEIGHT / 8)
        .onReady(() => { this.ready = true; this.redraw(); })
        .onAreaChange(() => { this.pointerId = -1; this.redraw(); })
        .onTouch((event: TouchEvent) => this.touch(event))
        .accessibilityText('七巧板工作台，点击或拖动彩色拼板；下方提供选板与方向微调按钮')
      Text('拼板小托盘').fontSize(10).fontColor(P.muted(this.dark))
        .position({ x: this.edge * .048, y: this.edge * .838 }).hitTestBehavior(HitTestMode.None)
    }.width(this.edge).height(this.edge * TANGRAM_WORLD_HEIGHT / 8).clip(true).borderRadius(26)
    .border({ width: 2, color: P.wood(this.dark) }).backgroundColor(P.paper(this.dark))
  }
}
