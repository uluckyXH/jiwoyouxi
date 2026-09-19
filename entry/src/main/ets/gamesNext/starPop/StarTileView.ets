import { STAR_NAMES, STAR_WIDTH } from './StarModel';
import { StarPalette as P } from './StarPalette';
import { StarVisualTile } from './StarScene';

@Component
export struct StarTileView {
  @ObjectLink tile: StarVisualTile;
  @Prop dark: boolean = false;
  @Prop edge: number = 35;
  @Prop gap: number = 2;
  @Prop inset: number = 12;
  tap: (id: number) => void = () => {};
  preview: (id: number) => void = () => {};
  cancelPreview: () => void = () => {};

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Image($rawfile(P.tile(this.tile.color, this.dark))).width('100%').height('100%')
        .draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
    }.width(this.edge).height(this.edge).padding(0).backgroundColor(Color.Transparent)
    .borderRadius(this.edge * .22).clip(true)
    .border({ width: this.tile.selected ? 2 : 0, color: P.accent(this.dark), radius: this.edge * .22 })
    .position({ x: this.inset, y: this.inset })
    .translate({ x: (this.tile.cell % STAR_WIDTH) * (this.edge + this.gap),
      y: Math.floor(this.tile.cell / STAR_WIDTH) * (this.edge + this.gap) })
    .scale({ x: this.tile.scale, y: this.tile.scale }).opacity(this.tile.scale)
    .visibility(this.tile.visible ? Visibility.Visible : Visibility.Hidden)
    .enabled(this.tile.visible).accessibilityLevel(this.tile.visible ? 'yes' : 'no')
    .accessibilityText(STAR_NAMES[this.tile.color] + '，第 ' + (Math.floor(this.tile.cell / STAR_WIDTH) + 1) +
      ' 行，第 ' + (this.tile.cell % STAR_WIDTH + 1) + ' 列，' +
      (this.tile.groupCount >= 2 ? '相连 ' + this.tile.groupCount + ' 块，确认消除' : '落单，暂不可消除'))
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) this.preview(this.tile.id);
      if (event.type === TouchType.Cancel) this.cancelPreview();
    })
    .onClick(() => this.tap(this.tile.id))
  }
}
