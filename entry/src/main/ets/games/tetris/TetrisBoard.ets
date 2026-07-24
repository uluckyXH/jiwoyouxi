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
    const width = this.boardPixelWidth();
    const height = this.boardPixelHeight();
    ctx.fillStyle = TetrisTheme.boardBg;
    ctx.fillRect(0, 0, width, height);

    for (let row = 0; row < BOARD_ROWS; row += 1) {
      ctx.fillStyle = row % 2 === 0 ? 'rgba(255,221,168,0.025)' : TetrisTheme.boardBgAlt;
      ctx.fillRect(0, row * size, width, size);
    }

    ctx.fillStyle = TetrisTheme.boardCellSoftLine;
    for (let col = 1; col < BOARD_COLS; col += 1) {
      ctx.fillRect(col * size - 0.5, 0, 1, height);
    }
    for (let row = 1; row < BOARD_ROWS; row += 1) {
      ctx.fillRect(0, row * size - 0.5, width, 1);
    }

    ctx.fillStyle = TetrisTheme.boardCellBorder;
    ctx.fillRect(0, 0, width, 1);
    ctx.fillRect(0, height - 1, width, 1);
    ctx.fillRect(0, 0, 1, height);
    ctx.fillRect(width - 1, 0, 1, height);

    ctx.fillStyle = 'rgba(255,220,157,0.055)';
    ctx.fillRect(0, 0, width, Math.floor(height * 0.18));
    ctx.fillStyle = 'rgba(20,8,4,0.12)';
    ctx.fillRect(0, Math.floor(height * 0.74), width, Math.ceil(height * 0.26));
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
    const gap = Math.max(1, Math.floor(size * 0.08));
    const cell = Math.max(4, size - gap * 2);
    const radius = Math.max(4, Math.floor(size * 0.22));
    const bodyX = x + gap;
    const bodyY = y + gap;
    const shadowOffset = Math.max(1, Math.floor(size * 0.11));

    ctx.fillStyle = 'rgba(30,10,4,0.38)';
    ctx.beginPath();
    roundRectPath(ctx, bodyX + 0.5, bodyY + shadowOffset, cell - 1, cell - 0.5, radius);
    ctx.fill();

    ctx.fillStyle = color;
    ctx.beginPath();
    roundRectPath(ctx, bodyX + 0.5, bodyY + 0.5, cell - 1, cell - 1, radius);
    ctx.fill();
    this.drawCellHighlight(ctx, bodyX, bodyY, cell, radius);
    this.drawCellShade(ctx, bodyX, bodyY, cell, radius);
    if (withBorder) {
      ctx.strokeStyle = TetrisTheme.fixedCellBorder;
      ctx.lineWidth = Math.max(0.7, size * 0.035);
      ctx.beginPath();
      roundRectPath(ctx, bodyX + 0.5, bodyY + 0.5, cell - 1, cell - 1, radius);
      ctx.stroke();
    }
  }

  private drawCellHighlight(ctx: CanvasRenderingContext2D, x: number, y: number, size: number,
    radius: number): void {
    ctx.fillStyle = 'rgba(255,255,255,0.24)';
    ctx.beginPath();
    roundRectPath(ctx, x + 2, y + 2, Math.max(2, size - 4), Math.max(2, size * 0.34), radius * 0.72);
    ctx.fill();

    ctx.fillStyle = 'rgba(255,255,255,0.34)';
    ctx.beginPath();
    roundRectPath(ctx, x + 3, y + 3, Math.max(2, size * 0.38), Math.max(2, size * 0.13), radius * 0.45);
    ctx.fill();
  }

  private drawCellShade(ctx: CanvasRenderingContext2D, x: number, y: number, size: number,
    radius: number): void {
    ctx.fillStyle = 'rgba(55,16,7,0.20)';
    ctx.beginPath();
    roundRectPath(ctx, x + 1.5, y + size * 0.62, Math.max(2, size - 3), Math.max(2, size * 0.32), radius * 0.72);
    ctx.fill();
  }

  private drawGhostCell(ctx: CanvasRenderingContext2D, x: number, y: number, size: number): void {
    const gap = Math.max(1, Math.floor(size * 0.08));
    const cell = Math.max(4, size - gap * 2);
    const radius = Math.max(4, Math.floor(size * 0.22));
    ctx.fillStyle = TetrisTheme.ghostColor;
    ctx.globalAlpha = 0.72;
    ctx.beginPath();
    roundRectPath(ctx, x + gap + 0.5, y + gap + 0.5, cell - 1, cell - 1, radius);
    ctx.fill();
    ctx.strokeStyle = 'rgba(255,238,209,0.48)';
    ctx.lineWidth = Math.max(0.7, size * 0.03);
    ctx.stroke();
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
