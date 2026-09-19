import { TEN_DIRECTIONS, TEN_DIRECTION_ICONS } from './TenModel';
import { TenPalette as P } from './TenPalette';
import { TenRenderTile } from './TenRenderTile';
import { TenTileCell } from './TenTileCell';

@Component
export struct TenBoard {
  @Prop dark: boolean = false;
  @Prop gridSize: number = 3;
  @Prop grid: number = 330;
  @Prop cell: number = 106;
  @Prop gap: number = 6;
  @Prop pad: number = 10;
  @Prop windDirection: number = 0;
  @Link tiles: TenRenderTile[];
  @Prop selected: number[] = [];
  @Prop hintCells: number[] = [];
  @Prop active: boolean = true;
  @Prop sceneId: string = '';
  tap: (index: number) => void = () => {};
  touch: (event: TouchEvent) => void = () => {};
  private x(index: number): number { return index % this.gridSize * (this.cell + this.gap); }
  private y(index: number): number { return Math.floor(index / this.gridSize) * (this.cell + this.gap); }
  build() {
    Column() {
      Row({ space: 5 }) {
        Image($rawfile(P.icon('wind', this.dark, 'accent'))).width(18).height(18).accessibilityLevel('no')
        Text('收下后').fontSize(12).fontColor(P.ink(this.dark))
        Image($rawfile(P.icon(TEN_DIRECTION_ICONS[this.windDirection], this.dark, 'accent')))
          .width(19).height(19).accessibilityText('向' + TEN_DIRECTIONS[this.windDirection] + '靠拢')
        Blank()
        Text('下一次').fontSize(11).fontColor(P.muted(this.dark))
        Image($rawfile(P.icon(TEN_DIRECTION_ICONS[(this.windDirection + 1) % 4], this.dark, 'ink')))
          .width(15).height(15).opacity(.7).accessibilityText('向' + TEN_DIRECTIONS[(this.windDirection + 1) % 4])
      }.width('100%').height(44)
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach(Array.from({ length: this.gridSize * this.gridSize }, (_v: number, i: number): number => i), (index: number) => {
          Column().width(this.cell).height(this.cell).borderRadius(Math.min(18, this.cell * .22))
            .backgroundColor(P.soft(this.dark)).opacity(.4).position({ x: this.x(index), y: this.y(index) })
            .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
        }, (index: number): string => '' + index)
        ForEach(this.hintCells, (index: number, order: number) => {
          if (order > 0) {
            Line().width(this.grid).height(this.grid)
              .startPoint([this.x(this.hintCells[order - 1]) + this.cell / 2, this.y(this.hintCells[order - 1]) + this.cell / 2])
              .endPoint([this.x(index) + this.cell / 2, this.y(index) + this.cell / 2])
              .stroke(P.gold(this.dark)).strokeWidth(2).strokeDashArray([3, 3])
              .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
          }
        }, (index: number): string => '' + index)
        ForEach(this.selected, (index: number, order: number) => {
          if (order > 0) {
            Line().width(this.grid).height(this.grid)
              .startPoint([this.x(this.selected[order - 1]) + this.cell / 2, this.y(this.selected[order - 1]) + this.cell / 2])
              .endPoint([this.x(index) + this.cell / 2, this.y(index) + this.cell / 2])
              .stroke(P.accent(this.dark)).strokeWidth(3).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
          }
        }, (index: number): string => '' + index)
        ForEach(this.tiles, (tile: TenRenderTile) => {
          TenTileCell({ tile: tile, dark: this.dark, gridSize: this.gridSize, cell: this.cell, gap: this.gap,
            selected: this.selected, hintCells: this.hintCells, active: this.active, tap: this.tap })
        }, (tile: TenRenderTile): string => this.sceneId + ':' + tile.id)
        // One pointer surface keeps touch coordinates relative to the whole grid.
        // The native tile buttons remain accessible to keyboard and screen-reader activation.
        Row().width(this.grid).height(this.grid).backgroundColor(Color.Transparent)
          .hitTestBehavior(HitTestMode.Block).accessibilityLevel('no').onTouch(this.touch)
      }.width(this.grid).height(this.grid)
    }.width(this.grid + this.pad * 2).height(this.grid + this.pad * 2 + 44).padding(this.pad)
      .backgroundColor(P.paper(this.dark)).borderRadius(26).border({ width: 1, color: P.line(this.dark), radius: 26 })
  }
}
