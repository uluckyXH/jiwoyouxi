import { PIECE_COLORS } from './TetrisTypes';
import { TETRIS_SHAPES } from './TetrisRules';
import { TetrisTheme } from './TetrisTheme';
import { CoopTheme } from '../../design/CoopTheme';

const PREVIEW_SLOTS: number[] = [0, 1, 2];
const PIECE_NAMES: string[] = ['I', 'O', 'T', 'S', 'Z', 'J', 'L'];

interface PreviewBounds {
  minRow: number;
  maxRow: number;
  minCol: number;
  maxCol: number;
}

@Component
export struct TetrisHoldPanel {
  @Prop kind: number = -1;
  @Prop holdUsed: boolean = false;
  @Prop isEnabled: boolean = true;
  @Prop panelWidth: number = 64;
  holdAction: () => void = () => {};

  build() {
    Column({ space: 8 }) {
      Text('暂存')
        .fontSize(11)
        .fontColor(CoopTheme.muted)
      if (this.kind >= 0) {
        TetrisPiecePreview({
          kind: this.kind,
          previewSize: this.previewSize()
        })
        Text(PIECE_NAMES[this.kind])
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
      } else {
        Text('H')
          .width(this.previewSize())
          .height(this.previewSize())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('rgba(255,255,255,0.56)')
          .textAlign(TextAlign.Center)
          .backgroundColor(TetrisTheme.boardBg)
          .borderRadius(12)
      }
      Text(this.holdUsed ? '已用' : '可换')
        .fontSize(10)
        .fontColor(this.holdUsed ? CoopTheme.muted : CoopTheme.brandDark)
        .maxLines(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .borderRadius(TetrisTheme.radiusPanel)
    .backgroundColor(TetrisTheme.panelBg)
    .border({ width: 1, color: TetrisTheme.panelBorder })
    .opacity(this.isEnabled && !this.holdUsed ? 1 : 0.72)
    .onClick(() => {
      if (this.isEnabled && !this.holdUsed) {
        this.holdAction();
      }
    })
  }

  private previewSize(): number {
    return Math.max(46, Math.min(56, this.panelWidth - 10));
  }
}

@Component
export struct TetrisNextPanel {
  @Prop queue: number[] = [];
  @Prop panelWidth: number = 66;

  build() {
    Column({ space: 9 }) {
      Text('下个')
        .fontSize(11)
        .fontColor(CoopTheme.muted)
      ForEach(PREVIEW_SLOTS, (slot: number) => {
        Column({ space: 3 }) {
          TetrisPiecePreview({
            kind: this.nextKindAt(slot),
            previewSize: this.previewSize()
          })
          if (slot === 0) {
            Text(PIECE_NAMES[this.nextKindAt(slot)])
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(CoopTheme.ink)
          }
        }
      }, (slot: number) => `next-${slot}-${this.queueKey()}`)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .borderRadius(TetrisTheme.radiusPanel)
    .backgroundColor(TetrisTheme.panelBg)
    .border({ width: 1, color: TetrisTheme.panelBorder })
  }

  private previewSize(): number {
    return Math.max(46, Math.min(56, this.panelWidth - 10));
  }

  private nextKindAt(slot: number): number {
    const kind = this.queue[slot];
    return kind === undefined ? 0 : kind;
  }

  private queueKey(): string {
    return this.queue.join('-');
  }
}

@Component
struct TetrisPiecePreview {
  @Prop @Watch('requestDraw') kind: number = 0;
  @Prop @Watch('requestDraw') previewSize: number = 52;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
    .width(this.previewSize)
    .height(this.previewSize)
    .borderRadius(12)
    .backgroundColor(TetrisTheme.boardBg)
    .onReady(() => {
      this.draw();
    })
  }

  requestDraw(): void {
    this.draw();
  }

  private previewCellSize(): number {
    return Math.max(8, Math.floor((this.previewSize - 14) / 4));
  }

  private draw(): void {
    const ctx = this.context;
    ctx.clearRect(0, 0, this.previewSize, this.previewSize);
    this.drawPreviewGrid(ctx);
    this.drawCenteredPiece(ctx);
  }

  private drawPreviewGrid(ctx: CanvasRenderingContext2D): void {
    const cell = this.previewCellSize();
    const gap = 2;
    const gridSize = cell * 4 + gap * 3;
    const start = (this.previewSize - gridSize) * 0.5;
    ctx.fillStyle = 'rgba(255,255,255,0.10)';
    for (let row = 0; row < 4; row += 1) {
      for (let col = 0; col < 4; col += 1) {
        previewRoundRect(ctx, start + col * (cell + gap), start + row * (cell + gap), cell, cell, 3);
        ctx.fill();
      }
    }
  }

  private drawCenteredPiece(ctx: CanvasRenderingContext2D): void {
    if (this.kind < 0 || this.kind >= TETRIS_SHAPES.length) {
      return;
    }
    const shape = TETRIS_SHAPES[this.kind][0];
    const bounds = this.previewBounds(shape);
    const cell = this.previewCellSize();
    const gap = 2;
    const pieceRows = bounds.maxRow - bounds.minRow + 1;
    const pieceCols = bounds.maxCol - bounds.minCol + 1;
    const pieceWidth = pieceCols * cell + (pieceCols - 1) * gap;
    const pieceHeight = pieceRows * cell + (pieceRows - 1) * gap;
    const startX = (this.previewSize - pieceWidth) * 0.5;
    const startY = (this.previewSize - pieceHeight) * 0.5;
    ctx.fillStyle = PIECE_COLORS[this.kind];
    for (let row = 0; row < 4; row += 1) {
      for (let col = 0; col < 4; col += 1) {
        if (shape[row][col] === 1) {
          const x = startX + (col - bounds.minCol) * (cell + gap);
          const y = startY + (row - bounds.minRow) * (cell + gap);
          previewRoundRect(ctx, x, y, cell, cell, 3);
          ctx.fill();
          this.drawCellHighlight(ctx, x, y, cell);
        }
      }
    }
  }

  private previewBounds(shape: number[][]): PreviewBounds {
    let minRow = 4;
    let maxRow = -1;
    let minCol = 4;
    let maxCol = -1;
    for (let row = 0; row < 4; row += 1) {
      for (let col = 0; col < 4; col += 1) {
        if (shape[row][col] === 1) {
          minRow = Math.min(minRow, row);
          maxRow = Math.max(maxRow, row);
          minCol = Math.min(minCol, col);
          maxCol = Math.max(maxCol, col);
        }
      }
    }
    if (maxRow < 0) {
      return { minRow: 0, maxRow: 0, minCol: 0, maxCol: 0 };
    }
    return { minRow: minRow, maxRow: maxRow, minCol: minCol, maxCol: maxCol };
  }

  private drawCellHighlight(ctx: CanvasRenderingContext2D, x: number, y: number, cell: number): void {
    ctx.fillStyle = 'rgba(255,255,255,0.18)';
    previewRoundRect(ctx, x + 1.5, y + 1.5, Math.max(2, cell - 3), Math.max(2, cell * 0.32), 2);
    ctx.fill();
    ctx.fillStyle = PIECE_COLORS[this.kind];
  }
}

function previewRoundRect(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, height: number,
  radius: number): void {
  const r = Math.min(radius, width / 2, height / 2);
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + width - r, y);
  ctx.arcTo(x + width, y, x + width, y + r, r);
  ctx.lineTo(x + width, y + height - r);
  ctx.arcTo(x + width, y + height, x + width - r, y + height, r);
  ctx.lineTo(x + r, y + height);
  ctx.arcTo(x, y + height, x, y + height - r, r);
  ctx.lineTo(x, y + r);
  ctx.arcTo(x, y, x + r, y, r);
  ctx.closePath();
}
