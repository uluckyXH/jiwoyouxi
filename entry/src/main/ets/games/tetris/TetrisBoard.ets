import { ActivePiece, BOARD_COLS, BOARD_ROWS, PIECE_COLORS } from './TetrisTypes';
import { cellsOf } from './TetrisRules';
import { TetrisTheme } from './TetrisTheme';

@Component
export struct TetrisBoard {
  @Prop @Watch('requestDraw') board: number[] = [];
  @Prop @Watch('requestDraw') current: ActivePiece = { kind: 0, col: 3, row: 0, rotation: 0 };
  @Prop @Watch('requestDraw') ghostRow: number = 0;
  @Prop @Watch('requestDraw') gameOver: boolean = false;
  @Prop @Watch('requestDraw') cellSize: number = 18;
  @Prop @Watch('requestDraw') clearingRows: number[] = [];
  @Prop @Watch('requestDraw') clearSweepProgress: number = 0;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width(this.boardPixelWidth())
      .height(this.boardPixelHeight())
      .backgroundColor(TetrisTheme.boardBg)
      .onReady(() => {
        this.draw();
      })
  }

  requestDraw(): void {
    this.draw();
  }

  private boardPixelWidth(): number {
    return this.cellSize * BOARD_COLS;
  }

  private boardPixelHeight(): number {
    return this.cellSize * BOARD_ROWS;
  }

  private draw(): void {
    const size = this.cellSize;
    if (size <= 0) {
      return;
    }
    const ctx = this.context;
    ctx.clearRect(0, 0, this.boardPixelWidth(), this.boardPixelHeight());
    this.drawBackground(ctx, size);
    this.drawFixedCells(ctx, size);
    if (this.clearingRows.length > 0) {
      this.drawClearSweep(ctx, size);
    }
    if (!this.gameOver) {
      this.drawGhost(ctx, size);
      this.drawCurrent(ctx, size);
    }
  }

  private drawBackground(ctx: CanvasRenderingContext2D, size: number): void {
    for (let row = 0; row < BOARD_ROWS; row += 1) {
      for (let col = 0; col < BOARD_COLS; col += 1) {
        ctx.fillStyle = row % 2 === 0 ? TetrisTheme.boardBg : TetrisTheme.boardBgAlt;
        ctx.fillRect(col * size, row * size, size, size);
      }
    }
  }

  private drawFixedCells(ctx: CanvasRenderingContext2D, size: number): void {
    for (let row = 0; row < BOARD_ROWS; row += 1) {
      for (let col = 0; col < BOARD_COLS; col += 1) {
        const value = this.board[row * BOARD_COLS + col];
        if (value > 0) {
          this.drawCell(ctx, col * size, row * size, size, PIECE_COLORS[value - 1], true);
        }
      }
    }
  }

  private drawGhost(ctx: CanvasRenderingContext2D, size: number): void {
    const ghost: ActivePiece = {
      kind: this.current.kind,
      col: this.current.col,
      row: this.ghostRow,
      rotation: this.current.rotation
    };
    const cells = cellsOf(ghost);
    for (let i = 0; i < cells.length; i += 1) {
      const cell = cells[i];
      if (cell.row >= 0 && cell.row < BOARD_ROWS && cell.col >= 0 && cell.col < BOARD_COLS) {
        this.drawGhostCell(ctx, cell.col * size, cell.row * size, size);
      }
    }
  }

  private drawCurrent(ctx: CanvasRenderingContext2D, size: number): void {
    const cells = cellsOf(this.current);
    for (let i = 0; i < cells.length; i += 1) {
      const cell = cells[i];
      if (cell.row >= 0 && cell.row < BOARD_ROWS && cell.col >= 0 && cell.col < BOARD_COLS) {
        this.drawCell(ctx, cell.col * size, cell.row * size, size, PIECE_COLORS[this.current.kind], true);
      }
    }
  }

  private drawClearSweep(ctx: CanvasRenderingContext2D, size: number): void {
    const progress = Math.max(0, Math.min(1, this.clearSweepProgress));
    const boardWidth = this.boardPixelWidth();
    const sweepWidth = Math.max(size * 3.1, boardWidth * 0.36);
    const sweepCenter = progress * (boardWidth + sweepWidth) - sweepWidth * 0.5;
    for (let i = 0; i < this.clearingRows.length; i += 1) {
      const row = this.clearingRows[i];
      if (row < 0 || row >= BOARD_ROWS) {
        continue;
      }
      const y = row * size;
      ctx.fillStyle = TetrisTheme.clearSweepGlow;
      ctx.fillRect(0, y, boardWidth, size);
      ctx.fillStyle = 'rgba(255,248,219,0.20)';
      ctx.fillRect(0, y + 1, boardWidth, Math.max(1, size - 2));

      const glowX = Math.max(0, sweepCenter - sweepWidth * 0.62);
      const glowRight = Math.min(boardWidth, sweepCenter + sweepWidth * 0.62);
      const glowWidth = Math.max(0, glowRight - glowX);
      if (glowWidth > 0) {
        ctx.fillStyle = TetrisTheme.clearSweepColor;
        ctx.globalAlpha = 0.28;
        ctx.fillRect(glowX, y + 1, glowWidth, Math.max(1, size - 2));
        ctx.globalAlpha = 1;
      }

      const coreX = Math.max(0, sweepCenter - size * 0.68);
      const coreRight = Math.min(boardWidth, sweepCenter + size * 0.68);
      const coreWidth = Math.max(0, coreRight - coreX);
      if (coreWidth > 0) {
        ctx.fillStyle = TetrisTheme.clearSweepCore;
        ctx.fillRect(coreX, y + 1, coreWidth, Math.max(1, size - 2));
      }
    }
  }

  private drawCell(ctx: CanvasRenderingContext2D, x: number, y: number, size: number, color: string,
    withBorder: boolean): void {
    ctx.fillStyle = color;
    ctx.beginPath();
    roundRectPath(ctx, x + 0.5, y + 0.5, size - 1, size - 1, TetrisTheme.radiusCell);
    ctx.fill();
    this.drawCellHighlight(ctx, x, y, size);
    if (withBorder) {
      ctx.strokeStyle = TetrisTheme.fixedCellBorder;
      ctx.lineWidth = 0.5;
      ctx.stroke();
    }
  }

  private drawCellHighlight(ctx: CanvasRenderingContext2D, x: number, y: number, size: number): void {
    ctx.fillStyle = 'rgba(255,255,255,0.16)';
    ctx.beginPath();
    roundRectPath(ctx, x + 2, y + 2, Math.max(2, size - 4), Math.max(2, size * 0.32), TetrisTheme.radiusCell);
    ctx.fill();
  }

  private drawGhostCell(ctx: CanvasRenderingContext2D, x: number, y: number, size: number): void {
    ctx.fillStyle = TetrisTheme.ghostColor;
    ctx.globalAlpha = 0.46;
    ctx.beginPath();
    roundRectPath(ctx, x + 0.5, y + 0.5, size - 1, size - 1, TetrisTheme.radiusCell);
    ctx.fill();
    ctx.globalAlpha = 1;
  }
}

function roundRectPath(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, height: number,
  radius: number): void {
  const r = Math.min(radius, width / 2, height / 2);
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
