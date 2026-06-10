import { MineCell } from './MinesweeperTypes';
import { MinesweeperTheme } from './MinesweeperTheme';

@Component
export struct MinesweeperBoard {
  @Prop cells: MineCell[] = [];
  @Prop cellPx: number = 32;
  @Prop frameWidthPx: number = 360;
  @Prop frameHeightPx: number = 360;
  @Prop boardWidthPx: number = 320;
  @Prop boardHeightPx: number = 320;
  @Prop columnsTemplateValue: string = '1fr';
  @Prop rowsTemplateValue: string = '1fr';
  @Prop revealMines: boolean = false;
  tapCell: (index: number) => void = () => {};

  build() {
    Stack() {
      this.BoardBorder()
      Grid() {
        ForEach(this.cells, (cell: MineCell) => {
          GridItem() {
            this.CellView(cell)
          }
        }, (cell: MineCell) => `${cell.index}-${cell.open}-${cell.flag}-${cell.boom}-${cell.mine}-${cell.neighbor}-${this.revealMines}`)
      }
      .columnsTemplate(this.columnsTemplateValue)
      .rowsTemplate(this.rowsTemplateValue)
      .rowsGap(0)
      .columnsGap(0)
      .width(this.boardWidthPx)
      .height(this.boardHeightPx)
      .padding(0)
      .backgroundColor('rgba(92,58,24,0.22)')
      .position({ x: this.gridX(), y: this.gridY() })
    }
    .width(this.frameWidthPx)
    .height(this.frameHeightPx)
  }

  @Builder
  BoardBorder() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile('games/minesweeper/board_border_v3_edge_top_mid.png'))
        .width(this.frameWidthPx)
        .height(this.topEdgeHeight())
        .objectFit(ImageFit.Fill)
        .position({ x: 0, y: 0 })
      Image($rawfile('games/minesweeper/board_border_v3_edge_bottom_mid.png'))
        .width(this.frameWidthPx)
        .height(this.bottomEdgeHeight())
        .objectFit(ImageFit.Fill)
        .position({ x: 0, y: this.frameHeightPx - this.bottomEdgeHeight() })
      Image($rawfile('games/minesweeper/board_border_v3_edge_left_mid.png'))
        .width(this.leftEdgeWidth())
        .height(this.frameHeightPx)
        .objectFit(ImageFit.Fill)
        .position({ x: 0, y: 0 })
      Image($rawfile('games/minesweeper/board_border_v3_edge_right_mid.png'))
        .width(this.rightEdgeWidth())
        .height(this.frameHeightPx)
        .objectFit(ImageFit.Fill)
        .position({ x: this.frameWidthPx - this.rightEdgeWidth(), y: 0 })
      Image($rawfile('games/minesweeper/board_border_v3_corner_top_left.png'))
        .width(this.topLeftCornerWidth())
        .height(this.topLeftCornerHeight())
        .objectFit(ImageFit.Fill)
        .position({ x: 0, y: 0 })
      Image($rawfile('games/minesweeper/board_border_v3_corner_top_right.png'))
        .width(this.topRightCornerWidth())
        .height(this.topRightCornerHeight())
        .objectFit(ImageFit.Fill)
        .position({ x: this.frameWidthPx - this.topRightCornerWidth(), y: 0 })
      Image($rawfile('games/minesweeper/board_border_v3_corner_bottom_left.png'))
        .width(this.bottomLeftCornerWidth())
        .height(this.bottomLeftCornerHeight())
        .objectFit(ImageFit.Fill)
        .position({ x: 0, y: this.frameHeightPx - this.bottomLeftCornerHeight() })
      Image($rawfile('games/minesweeper/board_border_v3_corner_bottom_right.png'))
        .width(this.bottomRightCornerWidth())
        .height(this.bottomRightCornerHeight())
        .objectFit(ImageFit.Fill)
        .position({ x: this.frameWidthPx - this.bottomRightCornerWidth(), y: this.frameHeightPx - this.bottomRightCornerHeight() })
      Image($rawfile('games/minesweeper/board_border_v3_edge_top_mid.png'))
        .width(this.horizontalCoverWidth())
        .height(this.topEdgeHeight())
        .objectFit(ImageFit.Fill)
        .position({ x: this.horizontalCoverX(), y: 0 })
      Image($rawfile('games/minesweeper/board_border_v3_edge_bottom_mid.png'))
        .width(this.horizontalCoverWidth())
        .height(this.bottomEdgeHeight())
        .objectFit(ImageFit.Fill)
        .position({ x: this.horizontalCoverX(), y: this.frameHeightPx - this.bottomEdgeHeight() })
      Image($rawfile('games/minesweeper/board_border_v3_edge_left_mid.png'))
        .width(this.leftEdgeWidth())
        .height(this.verticalCoverHeight())
        .objectFit(ImageFit.Fill)
        .position({ x: 0, y: this.verticalCoverY() })
      Image($rawfile('games/minesweeper/board_border_v3_edge_right_mid.png'))
        .width(this.rightEdgeWidth())
        .height(this.verticalCoverHeight())
        .objectFit(ImageFit.Fill)
        .position({ x: this.frameWidthPx - this.rightEdgeWidth(), y: this.verticalCoverY() })
    }
    .width(this.frameWidthPx)
    .height(this.frameHeightPx)
    .shadow({
      radius: Math.round(16 * this.borderScale()),
      color: 'rgba(68,38,14,0.34)',
      offsetX: 0,
      offsetY: Math.round(7 * this.borderScale())
    })
  }

  @Builder
  CellView(cell: MineCell) {
    Stack({ alignContent: Alignment.Center }) {
      this.CellTile(cell)
      if (this.shouldShowNumber(cell)) {
        Text(`${cell.neighbor}`)
          .width('100%')
          .height('100%')
          .fontSize(Math.max(11, this.cellPx * 0.44))
          .fontWeight(FontWeight.Bold)
          .fontColor(MinesweeperTheme.numberColor(cell.neighbor))
          .textAlign(TextAlign.Center)
          .shadow({
            radius: Math.max(1, this.cellPx * 0.04),
            color: 'rgba(255,247,222,0.72)',
            offsetX: 0,
            offsetY: 1
          })
      }
    }
    .width('100%')
    .height(this.cellPx)
    .onClick(() => {
      this.tapCell(cell.index);
    })
  }

  @Builder
  CellTile(cell: MineCell) {
    if ((cell.open || this.revealMines) && cell.mine) {
      this.TileImage('games/minesweeper/tile_mine.png')
    } else if (!cell.open && cell.flag) {
      this.TileImage('games/minesweeper/tile_flag.png')
    } else if (cell.open && cell.neighbor > 0) {
      this.TileImage('games/minesweeper/tile_open_inset.png')
    } else if (cell.open) {
      this.TileImage('games/minesweeper/tile_open_plain.png')
    } else {
      this.TileImage('games/minesweeper/tile_hay_cover.png')
    }
  }

  @Builder
  TileImage(path: string) {
    Image($rawfile(path))
      .width('106%')
      .height('106%')
      .objectFit(ImageFit.Fill)
  }

  private shouldShowNumber(cell: MineCell): boolean {
    return cell.open && !cell.mine && cell.neighbor > 0;
  }

  private borderScale(): number {
    return Math.max(0.32, Math.min(0.46, this.frameWidthPx / 1021));
  }

  private gridX(): number {
    return Math.max(0, Math.round((this.frameWidthPx - this.boardWidthPx) * 0.5));
  }

  private gridY(): number {
    return Math.max(0, Math.round((this.frameHeightPx - this.boardHeightPx) * 0.5));
  }

  private topLeftCornerWidth(): number {
    return Math.round(248 * this.borderScale());
  }

  private topLeftCornerHeight(): number {
    return Math.round(187 * this.borderScale());
  }

  private topRightCornerWidth(): number {
    return Math.round(247 * this.borderScale());
  }

  private topRightCornerHeight(): number {
    return Math.round(185 * this.borderScale());
  }

  private bottomLeftCornerWidth(): number {
    return Math.round(240 * this.borderScale());
  }

  private bottomLeftCornerHeight(): number {
    return Math.round(191 * this.borderScale());
  }

  private bottomRightCornerWidth(): number {
    return Math.round(244 * this.borderScale());
  }

  private bottomRightCornerHeight(): number {
    return Math.round(191 * this.borderScale());
  }

  private topEdgeHeight(): number {
    return Math.round(79 * this.borderScale());
  }

  private bottomEdgeHeight(): number {
    return Math.round(77 * this.borderScale());
  }

  private leftEdgeWidth(): number {
    return Math.round(65 * this.borderScale());
  }

  private rightEdgeWidth(): number {
    return Math.round(64 * this.borderScale());
  }

  private horizontalCoverX(): number {
    return Math.round(Math.max(this.topLeftCornerWidth(), this.bottomLeftCornerWidth()) * 0.54);
  }

  private horizontalCoverWidth(): number {
    return Math.max(1, this.frameWidthPx - this.horizontalCoverX() * 2);
  }

  private verticalCoverY(): number {
    return Math.round(Math.max(this.topLeftCornerHeight(), this.topRightCornerHeight()) * 0.56);
  }

  private verticalCoverHeight(): number {
    return Math.max(1, this.frameHeightPx - this.verticalCoverY() * 2);
  }
}
