import { fcName, fcRank, fcRankText, fcRed, fcSuit } from './FreecellModel';
import { FCPalette as P } from './FreecellPalette';

@Observed
export class FCCardView {
  id: number = 0;
  x: number = 0;
  y: number = 0;
  dx: number = 0;
  dy: number = 0;
  width: number = 40;
  height: number = 57;
  layer: number = 0;
  visible: boolean = true;
  movable: boolean = false;
  enterX: number = 0;
  enterY: number = 0;
  enterOpacity: number = 1;
  selected: boolean = false;
  hinted: boolean = false;
  constructor(id: number) { this.id = id; }
}

@Component
export struct FCCard {
  @ObjectLink card: FCCardView;
  @Prop dark: boolean = false;
  @Prop active: boolean = true;
  @Prop dragEnabled: boolean = true;
  tap: (id: number) => void = () => {};
  dragStart: (id: number) => void = () => {};
  dragUpdate: (dx: number, dy: number) => void = () => {};
  dragEnd: () => void = () => {};
  dragCancel: () => void = () => {};
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(P.asset('cards/face', this.dark))).width('100%').height('100%').draggable(false).accessibilityLevel('no')
      Row({ space: 2 }) {
        Text(fcRankText(this.card.id)).fontSize(Math.max(14, this.card.width * .25)).fontWeight(FontWeight.Bold)
          .fontColor(fcRed(this.card.id) ? P.red(this.dark) : P.ink(this.dark)).fontFamily('monospace').maxLines(1)
        Image($rawfile(P.asset(`cards/suit_${fcSuit(this.card.id)}`, this.dark)))
          .width(Math.max(10, this.card.width * .17)).height(Math.max(10, this.card.width * .17)).draggable(false)
      }.height(Math.max(20, this.card.width * .34)).position({ x: Math.max(3, this.card.width * .08), y: 0 })
      Image($rawfile(P.asset(fcRank(this.card.id) > 10 ? `cards/royal_${fcRank(this.card.id)}` : `cards/suit_${fcSuit(this.card.id)}`, this.dark)))
        .width(this.card.width * .43).height(this.card.width * .43).draggable(false).accessibilityLevel('no')
        .position({ x: this.card.width * .285, y: this.card.height * .44 })
      if (this.card.width >= 60) {
        Text(fcRankText(this.card.id)).fontSize(this.card.width * .19).fontWeight(FontWeight.Bold)
          .fontColor(fcRed(this.card.id) ? P.red(this.dark) : P.ink(this.dark))
          .rotate({ angle: 180 }).position({ x: this.card.width * .76, y: this.card.height * .76 })
      }
    }.width(this.card.width).height(this.card.height).borderRadius(this.card.width * .11)
    .id(`freecell-card-${this.card.id}`)
    .border({ width: this.card.selected || this.card.hinted ? 2 : 0,
      color: this.card.hinted ? P.gold(this.dark) : P.accent(this.dark), radius: this.card.width * .11 })
    .position({ x: this.card.x + this.card.dx + this.card.enterX,
      y: this.card.y + this.card.dy + this.card.enterY - (this.card.selected ? 3 : 0) })
    .zIndex(this.card.layer + (this.card.selected ? 100 : 0)).opacity(this.card.visible ? this.card.enterOpacity : 0)
    .hitTestBehavior(this.card.visible && this.active ? HitTestMode.Default : HitTestMode.None)
    .accessibilityLevel(this.card.visible ? 'yes' : 'no').accessibilityText(fcName(this.card.id))
    .onClick(() => this.tap(this.card.id))
    .priorityGesture(PanGesture({ fingers: 1, direction: PanDirection.All, distance: 5 }).tag('freecell-drag')
        .onActionStart((event: GestureEvent) => { this.dragStart(this.card.id); this.dragUpdate(event.offsetX, event.offsetY); })
        .onActionUpdate((event: GestureEvent) => this.dragUpdate(event.offsetX, event.offsetY))
        .onActionEnd((event: GestureEvent) => { this.dragUpdate(event.offsetX, event.offsetY); this.dragEnd(); })
        .onActionCancel(() => this.dragCancel()))
    .onGestureJudgeBegin((gesture: GestureInfo, _event: BaseGestureEvent): GestureJudgeResult => {
      // A covered, unordered stack remains a scroll surface; movable cards own
      // their pan immediately, without requiring a stationary long press first.
      return gesture.tag === 'freecell-drag' && (!this.active || !this.dragEnabled || !this.card.movable) ?
        GestureJudgeResult.REJECT : GestureJudgeResult.CONTINUE;
    })
  }
}
