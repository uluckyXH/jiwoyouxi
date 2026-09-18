import { MINE_ASSETS, SurveyCell } from './MineModel';
import { MinePalette as P } from './MinePalette';
import { CoopMotion } from '../../design/CoopMotion';

@Component
export struct MineBoard {
  @Prop dark: boolean = false;
  @Prop cells: SurveyCell[] = [];
  @Prop rows: number = 8;
  @Prop cols: number = 8;
  @Prop cellSize: number = 40;
  @Prop locked: boolean = false;
  @Prop lost: boolean = false;
  @Prop @Watch('resetScroll') resetKey: string = '';
  private verticalScroll: Scroller = new Scroller();
  private horizontalScroll: Scroller = new Scroller();
  @State pressedIndex: number = -1;
  tap: (index: number) => void = () => {};
  hold: (index: number) => void = () => {};

  private image(name: string): string { return `${MINE_ASSETS}tiles/${name}_${this.dark ? 'dark' : 'light'}.svg`; }

  resetScroll(): void {
    this.verticalScroll.scrollTo({ xOffset: 0, yOffset: 0 });
    this.horizontalScroll.scrollTo({ xOffset: 0, yOffset: 0 });
  }

  private description(cell: SurveyCell): string {
    const position = `第${Math.floor(cell.index / this.cols) + 1}行，第${cell.index % this.cols + 1}列`;
    if (cell.exploded) return `${position}，触雷位置`;
    if (cell.open && cell.mine) return `${position}，地雷`;
    if (cell.flag) return `${position}，已插旗`;
    if (!cell.open) return `${position}，未翻开，点击操作，长按插旗`;
    return `${position}，${cell.near === 0 ? '空地' : `周围${cell.near}颗雷，点击可尝试连开`}`;
  }

  @Builder
  Cell(cell: SurveyCell) {
    Stack() {
      Image($rawfile(this.image(cell.open ? 'open' : 'closed')))
        .width(this.cellSize).height(this.cellSize).objectFit(ImageFit.Fill).accessibilityLevel('no')
      if (cell.exploded || (this.lost && cell.flag && !cell.mine)) {
        Rect().width(this.cellSize - 4).height(this.cellSize - 5).radius(8)
          .fill(P.dangerBg(this.dark)).accessibilityLevel('no')
      }
      if (cell.open && cell.mine) {
        Image($rawfile(this.image('mine'))).width(this.cellSize * 0.8).height(this.cellSize * 0.8)
          .accessibilityLevel('no')
      } else if (cell.flag) {
        Image($rawfile(this.image('flag'))).width(this.cellSize * 0.88).height(this.cellSize * 0.88)
          .accessibilityLevel('no')
        if (this.lost && !cell.mine) {
          Image($rawfile(P.icon('close', this.dark))).width(this.cellSize * 0.6).height(this.cellSize * 0.6)
            .accessibilityLevel('no')
        }
      } else if (cell.open && cell.near > 0) {
        Text(`${cell.near}`).fontSize(Math.min(26, this.cellSize * 0.48)).fontWeight(FontWeight.Bold)
          .fontColor(P.number(cell.near, this.dark)).fontFamily('monospace').accessibilityLevel('no')
      }
    }.width(this.cellSize).height(this.cellSize)
    .scale({ x: this.pressedIndex === cell.index ? CoopMotion.pressScale : 1,
      y: this.pressedIndex === cell.index ? CoopMotion.pressScale : 1 })
    .animation({ duration: CoopMotion.pressDuration, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      this.pressedIndex = !this.locked && event.type === TouchType.Down ? cell.index : -1;
    })
    .accessibilityLevel('yes').accessibilityText(this.description(cell))
    .gesture(GestureGroup(GestureMode.Exclusive,
      LongPressGesture({ repeat: false, duration: 400 }).onAction(() => {
        if (!this.locked) this.hold(cell.index);
      }),
      TapGesture().onAction(() => { if (!this.locked) this.tap(cell.index); })
    ))
  }

  build() {
    Scroll(this.verticalScroll) {
      Scroll(this.horizontalScroll) {
        Grid() {
          ForEach(this.cells, (cell: SurveyCell) => {
            GridItem() { this.Cell(cell) }
          }, (cell: SurveyCell) => `${this.resetKey}:${cell.index}:${cell.open}:${cell.flag}:${cell.exploded}:${cell.near}:${this.dark}`)
        }.columnsTemplate(`repeat(${this.cols}, 1fr)`).rowsTemplate(`repeat(${this.rows}, 1fr)`)
        .width(this.cellSize * this.cols).height(this.cellSize * this.rows)
        .enableScrollInteraction(false)
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Auto).edgeEffect(EdgeEffect.None)
      .align(Alignment.TopStart).width('100%').height(this.cellSize * this.rows)
    }.scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).edgeEffect(EdgeEffect.None)
    .nestedScroll({ scrollForward: NestedScrollMode.SELF_FIRST, scrollBackward: NestedScrollMode.SELF_FIRST })
    .align(Alignment.TopStart)
    .width('100%').height('100%').clip(true)
  }
}
