import { StarPalette as P } from './StarPalette';
import { StarVisualTile } from './StarScene';
import { StarTileView } from './StarTileView';

/** Stable tile identities: short native transforms, with no JavaScript animation loop. */
@Component
export struct StarBoard {
  @Prop dark: boolean = false;
  @Link tiles: StarVisualTile[];
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
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(P.scene('frame', this.dark))).width('100%').height('100%').objectFit(ImageFit.Fill)
        .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      ForEach(this.tiles, (tile: StarVisualTile) => {
        StarTileView({ tile: tile, dark: this.dark, edge: this.cell, gap: this.gap, inset: this.inset,
          tap: this.tap, preview: this.preview, cancelPreview: this.cancelPreview })
      }, (tile: StarVisualTile) => this.roundKey + ':' + tile.id)
      if (this.gain > 0) {
        Text('+' + this.gain).fontSize(24).fontWeight(FontWeight.Bold).fontColor(P.accent(this.dark))
          .padding({ left: 18, right: 18, top: 8, bottom: 8 }).backgroundColor(P.paper(this.dark)).borderRadius(24)
          .position({ x: this.boardWidth / 2 - 50, y: this.boardHeight / 2 - 25 })
          .width(100).textAlign(TextAlign.Center).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      }
    }.width(this.boardWidth).height(this.boardHeight).clip(true).borderRadius(23).enabled(this.active)
  }
}
