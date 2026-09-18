import { KeyCode } from '@kit.InputKit';
import { GLOW_ASSETS, GlowDirection, GlowTile, glowRank } from './GlowModel';
import { GlowPalette as P } from './GlowPalette';

@Component
struct GlowTileView {
  @Prop dark: boolean = false;
  @Prop @Watch('valueChanged') value: number = 2;
  @Prop edge: number = 64;
  @Prop born: boolean = false;
  @State scaleValue: number = 1;

  aboutToAppear(): void {
    this.scaleValue = this.born ? .62 : 1;
  }
  private enter(): void {
    if (!this.born) return;
    this.getUIContext().animateTo({ duration: 160, curve: Curve.EaseOut }, () => { this.scaleValue = 1; });
  }
  valueChanged(): void {
    this.scaleValue = 1.12;
    this.getUIContext().animateTo({ duration: 190, curve: Curve.Friction }, () => { this.scaleValue = 1; });
  }
  build() {
    Stack() {
      Image($rawfile(`${GLOW_ASSETS}tiles/${glowRank(this.value)}_${this.dark ? 'dark' : 'light'}.svg`))
        .width('100%').height('100%').draggable(false).accessibilityLevel('no')
      Text(`${this.value}`).width('88%').height('100%').textAlign(TextAlign.Center)
        .fontSize(this.edge * .40).minFontSize(12).maxFontSize(this.edge * .40).maxLines(1)
        .fontWeight(FontWeight.Bold).fontFamily('monospace').fontColor(P.tileInk(this.value, this.dark))
    }.width(this.edge).height(this.edge).scale({ x: this.scaleValue, y: this.scaleValue })
    .hitTestBehavior(HitTestMode.None).accessibilityLevel('yes').accessibilityText(`${this.value}`)
    .onAppear(() => this.enter())
  }
}

@Component
struct GlowMergeBurst {
  @Prop dark: boolean = false;
  @Prop edge: number = 64;
  @State expanded: boolean = false;
  private enter(): void {
    this.getUIContext().animateTo({ duration: 360, curve: Curve.EaseOut }, () => { this.expanded = true; });
  }
  build() {
    Image($rawfile(P.scene('burst', this.dark))).width(this.edge).height(this.edge)
      .scale({ x: this.expanded ? 1.35 : .65, y: this.expanded ? 1.35 : .65 })
      .opacity(this.expanded ? 0 : .95).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      .onAppear(() => this.enter())
  }
}

@Component
export struct GlowBoard {
  @Prop dark: boolean = false;
  @Prop tiles: GlowTile[] = [];
  @Prop session: string = '';
  @Prop edge: number = 320;
  @Prop cell: number = 68;
  @Prop gap: number = 9;
  @Prop tileInset: number = 12;
  @Prop spawned: number = 0;
  @Prop merged: number[] = [];
  @Prop turn: number = 0;
  @Prop active: boolean = true;
  move: (direction: GlowDirection) => void = () => {};
  private slots: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
  private x(index: number): number { return this.tileInset + (index % 4) * (this.cell + this.gap); }
  private y(index: number): number { return this.tileInset + Math.floor(index / 4) * (this.cell + this.gap); }
  private keyboard(event: KeyEvent): void {
    if (!this.active || event.type !== KeyType.Down) return;
    let direction: GlowDirection | undefined = undefined;
    if (event.keyCode === KeyCode.KEYCODE_DPAD_LEFT || event.keyCode === KeyCode.KEYCODE_A) direction = 'left';
    if (event.keyCode === KeyCode.KEYCODE_DPAD_RIGHT || event.keyCode === KeyCode.KEYCODE_D) direction = 'right';
    if (event.keyCode === KeyCode.KEYCODE_DPAD_UP || event.keyCode === KeyCode.KEYCODE_W) direction = 'up';
    if (event.keyCode === KeyCode.KEYCODE_DPAD_DOWN || event.keyCode === KeyCode.KEYCODE_S) direction = 'down';
    if (direction !== undefined) { this.move(direction); event.stopPropagation(); }
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.slots, (slot: number) => {
        Image($rawfile(`${GLOW_ASSETS}tiles/slot_${this.dark ? 'dark' : 'light'}.svg`))
          .width(this.cell).height(this.cell).position({ x: this.x(slot), y: this.y(slot) })
          .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      }, (slot: number) => `${slot}`)
      ForEach(this.tiles, (tile: GlowTile) => {
        GlowTileView({ dark: this.dark, value: tile.value, edge: this.cell, born: tile.id === this.spawned })
          .position({ x: this.x(tile.index), y: this.y(tile.index) })
      }, (tile: GlowTile) => `${this.session}:${tile.id}`)
      ForEach(this.merged, (index: number) => {
        GlowMergeBurst({ dark: this.dark, edge: this.cell })
          .position({ x: this.x(index), y: this.y(index) })
      }, (index: number) => `${this.turn}:${index}`)
    }.width(this.edge).height(this.edge).borderRadius(26).backgroundColor(P.paper(this.dark))
    .border({ width: 1, color: P.line(this.dark), radius: 26 })
    .shadow({ radius: 16, color: this.dark ? '#22000000' : '#126C7449', offsetY: 7 })
    .focusable(this.active).defaultFocus(true).onKeyEvent((event: KeyEvent) => this.keyboard(event))
    .accessibilityText('2048 棋盘，滑动移动数字，也可使用棋盘外的四个方向按钮')
    .priorityGesture(PanGesture({ direction: PanDirection.All, distance: 12 })
      .onActionEnd((event: GestureEvent) => {
        if (!this.active || Math.max(Math.abs(event.offsetX), Math.abs(event.offsetY)) < 12) return;
        this.move(Math.abs(event.offsetX) > Math.abs(event.offsetY) ?
          event.offsetX > 0 ? 'right' : 'left' : event.offsetY > 0 ? 'down' : 'up');
      }))
  }
}
