import { BLOOM_COLOR_NAMES } from './BloomModel';
import { BloomPalette as P } from './BloomPalette';
import { BloomDrag, bloomCanDrag } from './BloomDrag';

@Component
struct BloomHeldBead {
  @ObjectLink drag: BloomDrag;
  @Prop dark: boolean = false;
  @Prop cell: number = 43;
  build() {
    Image($rawfile(P.bead(this.drag.color, this.dark))).width(this.cell).height(this.cell)
      .position({ x: this.drag.x, y: this.drag.y }).scale({ x: 1.12, y: 1.12 })
      .shadow({ radius: 7, color: '#243C432A', offsetY: 4 })
      .draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
  }
}

@Component
struct BloomBurst {
  @Prop dark: boolean = false;
  @Prop edge: number = 48;
  @State expanded: boolean = false;
  private enter(): void {
    this.getUIContext().animateTo({ duration: 330, curve: Curve.EaseOut }, () => { this.expanded = true; });
  }
  build() {
    Image($rawfile(P.scene('burst', this.dark))).width(this.edge).height(this.edge)
      .scale({ x: this.expanded ? 1.35 : .65, y: this.expanded ? 1.35 : .65 })
      .opacity(this.expanded ? 0 : .9).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      .onAppear(() => this.enter())
  }
}

@Component
export struct BloomBoard {
  @ObjectLink drag: BloomDrag;
  @Prop dark: boolean = false;
  @Prop board: number[] = [];
  @Prop gridSize: number = 7;
  @Prop edge: number = 340;
  @Prop cell: number = 43;
  @Prop gap: number = 3;
  @Prop inset: number = 10;
  @Prop selected: number = -1;
  @Prop reachable: number[] = [];
  @Prop active: boolean = true;
  @Prop title: string = '小院慢游';
  @Prop hint: string = '';
  @Prop failed: boolean = false;
  @Prop movingColor: number = -1;
  @Prop movingX: number = 0;
  @Prop movingY: number = 0;
  @Prop movingScale: number = 1.06;
  @Prop trail: number[] = [];
  @Prop born: number[] = [];
  @Prop birthScale: number = 1;
  @Prop clearing: number[] = [];
  @Prop clearScale: number = 1;
  @Prop turn: number = 0;
  tap: (index: number) => void = () => {};
  dragStart: (index: number, dx: number, dy: number) => void = () => {};
  dragUpdate: (index: number, dx: number, dy: number) => void = () => {};
  dragEnd: (index: number) => void = () => {};
  dragCancel: (index: number) => void = () => {};
  private x(index: number): number { return this.inset + (index % this.gridSize) * (this.cell + this.gap); }
  private y(index: number): number { return this.inset + Math.floor(index / this.gridSize) * (this.cell + this.gap); }
  private beadScale(index: number): number {
    if (this.clearing.includes(index)) { return this.clearScale; }
    if (this.born.includes(index)) { return this.birthScale; }
    return index === this.selected ? 1.08 : 1;
  }
  private label(index: number): string {
    const position = '第 ' + (Math.floor(index / this.gridSize) + 1) + ' 行，第 ' + (index % this.gridSize + 1) + ' 列';
    if (this.board[index] >= 0) {
      return position + '，' + BLOOM_COLOR_NAMES[this.board[index]] + (index === this.selected ? '，已选中' : '');
    }
    return position + '，空位' + (this.reachable.includes(index) ? '，可以移动到这里' : '');
  }
  build() {
    Column() {
      Row({ space: 6 }) {
        Image($rawfile(P.icon('flower', this.dark, 'accent'))).width(17).height(17).accessibilityLevel('no')
        Text(this.title).fontSize(14).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark)).layoutWeight(1)
        Text('空位 ' + this.board.filter((color: number) => color < 0).length).fontSize(11).fontColor(P.muted(this.dark))
      }.width('100%').height(38).padding({ left: 14, right: 14 })
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach(this.board, (_color: number, index: number) => {
          Button({ type: ButtonType.Normal }) {
            Stack() {
              Image($rawfile(P.scene('slot', this.dark))).width('100%').height('100%').accessibilityLevel('no')
              if (this.reachable.includes(index) || this.trail.includes(index)) {
                Circle().width(this.cell * .13).height(this.cell * .13).fill(P.accent(this.dark))
                  .opacity(this.trail.includes(index) ? .65 : .23).accessibilityLevel('no')
              }
              if (this.board[index] >= 0) {
                Image($rawfile(P.bead(this.board[index], this.dark))).width('98%').height('98%')
                  .scale({ x: this.beadScale(index), y: this.beadScale(index) })
                  .opacity(this.drag.from === index ? 0 : this.clearing.includes(index) ? this.clearScale : 1)
                  .draggable(false).accessibilityLevel('no')
              }
              if (this.drag.target === index && this.drag.from !== index) {
                Rect().width('100%').height('100%').radius(this.cell * .27).fill(Color.Transparent)
                  .stroke(this.drag.valid ? P.accent(this.dark) : P.danger(this.dark)).strokeWidth(2)
                  .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
              }
            }.width('100%').height('100%')
          }.width(this.cell).height(this.cell).padding(0).backgroundColor(Color.Transparent).borderRadius(this.cell * .27)
          .border({ width: this.selected === index ? 1.5 : 0, color: P.accent(this.dark), radius: this.cell * .27 })
          .position({ x: this.x(index), y: this.y(index) }).accessibilityText(this.label(index))
          .onClick(() => { if (this.active) { this.tap(index); } })
          .priorityGesture(PanGesture({ fingers: 1, direction: PanDirection.All, distance: 3 }).tag('bloom-drag')
            .onActionStart((event: GestureEvent) => this.dragStart(index, event.offsetX, event.offsetY))
            .onActionUpdate((event: GestureEvent) => this.dragUpdate(index, event.offsetX, event.offsetY))
            .onActionEnd((event: GestureEvent) => {
              this.dragUpdate(index, event.offsetX, event.offsetY);
              this.dragEnd(index);
            })
            .onActionCancel(() => this.dragCancel(index)))
          .onGestureJudgeBegin((gesture: GestureInfo, _event: BaseGestureEvent): GestureJudgeResult => {
            // Empty cells remain scroll surfaces on compact/half-fold panes.
            return gesture.tag === 'bloom-drag' && !bloomCanDrag(this.active, this.board[index], this.drag.from, index) ?
              GestureJudgeResult.REJECT : GestureJudgeResult.CONTINUE;
          })
        }, (_color: number, index: number) => '' + index)
        if (this.movingColor >= 0) {
          Image($rawfile(P.bead(this.movingColor, this.dark))).width(this.cell).height(this.cell)
            .position({ x: this.movingX, y: this.movingY })
            .scale({ x: this.movingScale, y: this.movingScale }).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
        }
        ForEach(this.clearing, (index: number) => {
          BloomBurst({ dark: this.dark, edge: this.cell }).position({ x: this.x(index), y: this.y(index) })
        }, (index: number) => '' + this.turn + ':' + index)
        if (this.drag.from >= 0) {
          BloomHeldBead({ drag: this.drag, dark: this.dark, cell: this.cell }).zIndex(10)
        }
      }.width(this.edge).height(this.edge)
      Text(this.hint).fontSize(10).maxLines(1).minFontSize(8).maxFontSize(10)
        .fontColor(this.failed ? P.danger(this.dark) : P.muted(this.dark))
        .width('100%').height(28).textAlign(TextAlign.Center).padding({ left: 10, right: 10 })
    }.width(this.edge).height(this.edge + 66).backgroundColor(P.paper(this.dark)).borderRadius(27)
    .border({ width: 1, color: P.line(this.dark), radius: 27 })
    .shadow({ radius: 10, color: this.dark ? '#18000000' : '#0E6C7449', offsetY: 4 })
  }
}
