import { STAR_NAMES, StarTile } from './StarModel';
import { StarPalette as P } from './StarPalette';

/** Stable tile identities: short native transforms, with no JavaScript animation loop. */
@Component
export struct StarBoard {
  @Prop dark: boolean = false;
  @Prop tiles: StarTile[] = [];
  @Prop selected: number[] = [];
  @Prop groupCounts: number[] = [];
  @Prop clearing: number[] = [];
  @Prop clearScale: number = 1;
  @Prop boardWidth: number = 320;
  @Prop boardHeight: number = 395;
  @Prop cell: number = 35;
  @Prop gap: number = 2;
  @Prop inset: number = 12;
  @Prop active: boolean = true;
  @Prop roundKey: string = '';
  @Prop gain: number = 0;
  tap: (id: number) => void = () => {};
  preview: (id: number) => void = () => {};
  cancelPreview: () => void = () => {};
  private cellFor(id: number): number {
    // ForEach retains its creation argument for stable keys. Read the live @Prop
    // array here so native position observers follow surviving tiles after a collapse.
    const tile = this.tiles.find((item: StarTile): boolean => item.id === id);
    return tile === undefined ? 0 : tile.cell;
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(P.scene('frame', this.dark))).width('100%').height('100%').objectFit(ImageFit.Fill)
        .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      ForEach(this.tiles, (tile: StarTile) => {
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Stack() {
            Image($rawfile(P.tile(tile.color, this.dark))).width('100%').height('100%')
              .draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
            if (this.selected.includes(tile.id)) {
              Column().width('96%').height('96%').border({ width: 2, color: P.accent(this.dark), radius: this.cell * .21 })
                .borderRadius(this.cell * .21).hitTestBehavior(HitTestMode.None)
            }
          }.width('100%').height('100%')
        }.width(this.cell).height(this.cell).padding(0).backgroundColor(Color.Transparent)
        .borderRadius(this.cell * .22).clip(true)
        .position({ x: this.inset, y: this.inset })
        .translate({ x: (this.cellFor(tile.id) % 8) * (this.cell + this.gap), y: Math.floor(this.cellFor(tile.id) / 8) * (this.cell + this.gap) })
        .scale({ x: this.clearing.includes(tile.id) ? this.clearScale : 1, y: this.clearing.includes(tile.id) ? this.clearScale : 1 })
        .opacity(this.clearing.includes(tile.id) ? this.clearScale : 1)
        .enabled(this.active).accessibilityText(STAR_NAMES[tile.color] + '，第 ' + (Math.floor(this.cellFor(tile.id) / 8) + 1) + ' 行，第 ' + (this.cellFor(tile.id) % 8 + 1) + ' 列，' +
          (this.groupCounts[tile.id] >= 2 ? '相连 ' + this.groupCounts[tile.id] + ' 块，确认消除' : '落单，暂不可消除'))
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) this.preview(tile.id);
          if (event.type === TouchType.Cancel) this.cancelPreview();
        })
        .onClick(() => this.tap(tile.id))
      }, (tile: StarTile) => this.roundKey + ':' + tile.id)
      if (this.gain > 0) {
        Text('+' + this.gain).fontSize(24).fontWeight(FontWeight.Bold).fontColor(P.accent(this.dark))
          .padding({ left: 18, right: 18, top: 8, bottom: 8 }).backgroundColor(P.paper(this.dark)).borderRadius(24)
          .position({ x: this.boardWidth / 2 - 50, y: this.boardHeight / 2 - 25 })
          .width(100).textAlign(TextAlign.Center).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      }
    }.width(this.boardWidth).height(this.boardHeight).clip(true).borderRadius(23)
  }
}
