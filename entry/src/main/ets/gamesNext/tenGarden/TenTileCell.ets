import { TenPalette as P } from './TenPalette';
import { TenRenderTile } from './TenRenderTile';

@Component
export struct TenTileCell {
  @ObjectLink tile: TenRenderTile;
  @Prop dark: boolean = false;
  @Prop gridSize: number = 3;
  @Prop cell: number = 106;
  @Prop gap: number = 6;
  @Prop selected: number[] = [];
  @Prop hintCells: number[] = [];
  @Prop active: boolean = true;
  tap: (index: number) => void = () => {};

  build() {
    Button({ type: ButtonType.Normal }) {
      Stack() {
        Image($rawfile(P.scene('tile_leaf', this.dark))).width('100%').height('100%')
          .objectFit(ImageFit.Contain).draggable(false).accessibilityLevel('no')
        Text('' + this.tile.value).fontSize(Math.min(34, this.cell * .48)).fontWeight(FontWeight.Medium)
          .fontColor(this.selected.includes(this.tile.index) ? P.onAccent(this.dark) : P.ink(this.dark))
      }.width('100%').height('100%')
    }.width(this.cell).height(this.cell).padding(0).borderRadius(Math.min(18, this.cell * .22))
    .backgroundColor(this.selected.includes(this.tile.index) ? P.accent(this.dark) : P.paper(this.dark))
    .border({ width: this.selected.includes(this.tile.index) || this.hintCells.includes(this.tile.index) ? 2 : 1,
      color: this.selected.includes(this.tile.index) ? P.accent(this.dark) :
        this.hintCells.includes(this.tile.index) ? P.gold(this.dark) : P.line(this.dark),
      style: !this.selected.includes(this.tile.index) && this.hintCells.includes(this.tile.index) ? BorderStyle.Dashed : BorderStyle.Solid,
      radius: Math.min(18, this.cell * .22) })
    .shadow({ radius: 1, color: this.dark ? '#12101813' : '#143C5736', offsetY: 2 })
    .position({ x: this.tile.index % this.gridSize * (this.cell + this.gap),
      y: Math.floor(this.tile.index / this.gridSize) * (this.cell + this.gap) }).enabled(this.active)
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: .8, y: .8 })))
    .accessibilityText('第 ' + (Math.floor(this.tile.index / this.gridSize) + 1) + ' 行，第 ' + (this.tile.index % this.gridSize + 1) +
      ' 格，数字 ' + this.tile.value + (this.selected.includes(this.tile.index) ? '，已选中' : '') +
      (this.hintCells.includes(this.tile.index) ? '，提示第 ' + (this.hintCells.indexOf(this.tile.index) + 1) + ' 格' : ''))
    .accessibilityDescription('点选相邻数字，凑满十自动收下').onClick(() => this.tap(this.tile.index))
  }
}
