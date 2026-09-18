import { FCCard, FCCardView } from './FreecellCard';
import { FCLayout, fcLayout, fcPileX } from './FreecellLayout';
import { FCPalette as P } from './FreecellPalette';

@Component
export struct FreecellBoard {
  @Link cards: FCCardView[];
  @Prop dark: boolean = false;
  @Prop layout: FCLayout = fcLayout(390, 844, { top: 24, bottom: 16, left: 0, right: 0 });
  @Prop surfaceHeight: number = 400;
  @Prop session: string = '';
  @Prop hintTarget: number = -1;
  @Prop active: boolean = true;
  @Prop dragEnabled: boolean = true;
  @Prop @Watch('cancel') revision: number = 0;
  tap: (id: number) => void = () => {};
  target: (pile: number) => void = () => {};
  dragStart: (id: number) => boolean = () => false;
  dragUpdate: (dx: number, dy: number) => void = () => {};
  dragEnd: (id: number, dx: number, dy: number) => void = () => {};
  dragCancel: () => void = () => {};
  private vertical: Scroller = new Scroller();
  private horizontal: Scroller = new Scroller();
  private slots: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
  @State dragging: number = -1;
  private dx: number = 0;
  private dy: number = 0;
  private startX: number = 0;
  private startY: number = 0;
  private originX: number = 0;
  private originY: number = 0;
  private scrollTimer: number = -1;
  aboutToDisappear(): void { this.cancel(); }
  cancel(): void {
    this.stopScroll();
    if (this.dragging < 0) return;
    this.dragging = -1;
    this.dragCancel();
  }
  private stopScroll(): void { if (this.scrollTimer >= 0) clearInterval(this.scrollTimer); this.scrollTimer = -1; }
  private begin(id: number): void {
    if (!this.active || !this.dragStart(id)) return;
    this.dragging = id; this.dx = 0; this.dy = 0;
    this.startX = this.horizontal.currentOffset().xOffset; this.startY = this.vertical.currentOffset().yOffset;
    this.originX = this.cards[id].x; this.originY = this.cards[id].y;
    this.stopScroll();
    this.scrollTimer = setInterval(() => {
      const x = this.originX + this.dx - this.startX + this.layout.card / 2;
      const y = this.originY + this.dy - this.startY + 12;
      const currentX = this.horizontal.currentOffset().xOffset;
      const currentY = this.vertical.currentOffset().yOffset;
      const maxX = Math.max(0, this.layout.surfaceWidth - this.layout.board.width);
      const maxY = Math.max(0, this.surfaceHeight - this.layout.board.height);
      // Never push a scroller past its boundary. Repeated outward requests can
      // fight its rebound while a card is held over the top foundation slots.
      const vx = x < 24 ? -Math.min(6, Math.max(0, currentX)) :
        x > this.layout.board.width - 24 ? Math.min(6, Math.max(0, maxX - currentX)) : 0;
      const vy = y < 26 ? -Math.min(7, Math.max(0, currentY)) :
        y > this.layout.board.height - 26 ? Math.min(7, Math.max(0, maxY - currentY)) : 0;
      if (vx !== 0) this.horizontal.scrollBy(vx, 0);
      if (vy !== 0) this.vertical.scrollBy(0, vy);
      if (vx !== 0 || vy !== 0) this.update(this.dx, this.dy);
    }, 32);
  }
  private update(dx: number, dy: number): void {
    if (this.dragging < 0) return;
    this.dx = dx; this.dy = dy;
    this.dragUpdate(dx + this.horizontal.currentOffset().xOffset - this.startX,
      dy + this.vertical.currentOffset().yOffset - this.startY);
  }
  private end(): void {
    if (this.dragging < 0) return;
    this.stopScroll();
    const id = this.dragging; this.dragging = -1;
    this.dragEnd(id, this.dx + this.horizontal.currentOffset().xOffset - this.startX,
      this.dy + this.vertical.currentOffset().yOffset - this.startY);
  }
  @Builder
  Slot(pile: number) {
    Image($rawfile(P.asset(pile >= 12 ? `cards/slot_${pile - 12}` : 'cards/empty', this.dark)))
      .id(`freecell-slot-${pile}`)
      .width(this.layout.card).height(this.layout.cardHeight).draggable(false)
      .position({ x: fcPileX(this.layout, pile), y: pile < 8 ? this.layout.tableY : 22 })
      .border({ width: this.hintTarget === pile ? 2 : 0, color: P.gold(this.dark), radius: 8 })
      .accessibilityText(pile < 8 ? `第${pile + 1}列` : pile < 12 ? `第${pile - 7}个空当` : `${['黑桃', '红桃', '方块', '梅花'][pile - 12]}归位`)
      .onClick(() => this.target(pile))
  }
  build() {
    Scroll(this.horizontal) {
      Scroll(this.vertical) {
        Stack({ alignContent: Alignment.TopStart }) {
          Image($rawfile(P.asset('scene/seal', this.dark))).width(120).height(135).draggable(false)
            .position({ x: (this.layout.surfaceWidth - 120) / 2,
              y: Math.max(this.layout.tableY + this.layout.cardHeight, this.layout.board.height - 154) })
            .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
          Text('空 当').fontSize(10).letterSpacing(2).fontColor(P.muted(this.dark)).position({ x: this.layout.inset, y: 5 })
          Text('同花色 A → K').fontSize(10).fontColor(P.muted(this.dark))
            .position({ x: fcPileX(this.layout, 12), y: 5 })
          ForEach(this.slots, (pile: number) => { this.Slot(pile) }, (pile: number) => `${pile}`)
          ForEach(this.cards, (card: FCCardView) => {
            FCCard({ card: card, dark: this.dark, active: this.active, dragEnabled: this.dragEnabled, tap: this.tap,
              dragStart: (id: number) => this.begin(id),
              dragUpdate: (dx: number, dy: number) => { if (this.dragging === card.id) this.update(dx, dy); },
              dragEnd: () => { if (this.dragging === card.id) this.end(); },
              dragCancel: () => { if (this.dragging === card.id) this.cancel(); } })
          }, (card: FCCardView) => `${this.session}:${card.id}`)
        }.width(this.layout.surfaceWidth).height(this.surfaceHeight)
      }.width(this.layout.surfaceWidth).height(this.layout.board.height).scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.None)
      .enableScrollInteraction(this.dragging < 0)
      .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
      .scrollBar(this.surfaceHeight > this.layout.board.height + 1 ? BarState.Auto : BarState.Off).align(Alignment.TopStart)
    }.width(this.layout.board.width).height(this.layout.board.height).scrollable(ScrollDirection.Horizontal)
    .edgeEffect(EdgeEffect.None)
    .enableScrollInteraction(this.dragging < 0)
    .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
    .scrollBar(this.layout.surfaceWidth > this.layout.board.width + 1 ? BarState.Auto : BarState.Off)
    .align(Alignment.TopStart).clip(true).borderRadius(20)
    .backgroundColor(P.felt(this.dark)).border({ width: 1, color: P.line(this.dark), radius: 20 })
  }
}
