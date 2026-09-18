import { BlockEngine } from './BlockEngine';
import { BLOCK_COLORS, BLOCK_SHAPES, BLOCK_HIDDEN, BLOCK_CLEAR_MS } from './BlockModel';

/** Draws only changed board revisions. No SVG decoding or per-cell UI state in the hot path. */
export class BlockRenderer {
  private revision: number = -1;
  private size: number = 0;
  private theme: boolean = false;

  invalidate(): void { this.revision = -1; }

  paint(ctx: CanvasRenderingContext2D, engine: BlockEngine, width: number, dark: boolean): boolean {
    if (width <= 0 || (this.revision === engine.revision && this.size === width && this.theme === dark)) return false;
    this.revision = engine.revision;
    this.size = width;
    this.theme = dark;
    const unit = width / 10;
    const height = unit * 20;
    ctx.clearRect(0, 0, width, height);
    // The paper/grid is a static SVG Image beneath this transparent Canvas.
    // Only moving blocks and the brief clear effect enter the drawing hot path.
    const round = engine.round;
    for (let row = 2; row < 22; row += 1) {
      for (let col = 0; col < 10; col += 1) {
        const kind = round.board[row * 10 + col];
        if (kind > 0) this.tile(ctx, col * unit, (row - 2) * unit, unit, kind - 1, false, dark);
      }
    }
    if (round.phase === 'falling') {
      const p = round.piece;
      const ghost = engine.ghostY();
      const cells = BLOCK_SHAPES[p.kind][p.turn];
      for (let i = 0; i < 4; i += 1) {
        const x = (p.x + cells[i] % 4) * unit;
        const gy = ghost + Math.floor(cells[i] / 4) - BLOCK_HIDDEN;
        if (gy >= 0) this.tile(ctx, x, gy * unit, unit, p.kind, true, dark);
        const y = p.y + Math.floor(cells[i] / 4) - BLOCK_HIDDEN;
        if (y >= 0) this.tile(ctx, x, y * unit, unit, p.kind, false, dark);
      }
    }
    if (round.phase === 'clearing') {
      const progress = 1 - round.clearLeft / BLOCK_CLEAR_MS;
      ctx.globalAlpha = 0.25 + Math.sin(progress * Math.PI) * 0.65;
      ctx.fillStyle = round.lastClear === 4 ? '#ffe1a0' : '#fffce4';
      for (let i = 0; i < round.clearing.length; i += 1) {
        const row = round.clearing[i] - 2;
        if (row >= 0) ctx.fillRect(0, row * unit + unit * progress * 0.35, width, unit * (1 - progress * 0.7));
      }
      ctx.globalAlpha = 1;
    }
    return true;
  }

  private tile(ctx: CanvasRenderingContext2D, x: number, y: number, unit: number,
    kind: number, ghost: boolean, dark: boolean): void {
    const inset = Math.max(1, unit * 0.055);
    const edge = unit - inset * 2;
    if (ghost) {
      ctx.globalAlpha = dark ? 0.7 : 0.65;
      ctx.strokeStyle = BLOCK_COLORS[kind];
      ctx.lineWidth = Math.max(1, unit * 0.075);
      ctx.strokeRect(x + inset + 1, y + inset + 1, edge - 2, edge - 2);
      ctx.globalAlpha = 1;
      return;
    }
    ctx.fillStyle = BLOCK_COLORS[kind];
    ctx.fillRect(x + inset, y + inset, edge, edge);
    ctx.fillStyle = '#ffffff';
    ctx.globalAlpha = 0.28;
    ctx.fillRect(x + inset + 1, y + inset + 1, edge - 2, Math.max(1, unit * 0.1));
    ctx.globalAlpha = 0.12;
    ctx.fillStyle = '#16231b';
    ctx.fillRect(x + inset + 1, y + unit - inset - Math.max(1, unit * 0.1), edge - 2, Math.max(1, unit * 0.1));
    ctx.globalAlpha = 1;
  }
}
