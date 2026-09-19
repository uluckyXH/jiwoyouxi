import { tenHit } from './TenLayout';
import { tenSelect, tenSum } from './TenRules';

export interface TenGestureResult { path: number[]; commit: boolean; }
/** Input only: never mutates the board. Long pointer moves are sampled at quarter-cell intervals. */
export class TenGesture {
  private before: number[] = [];
  private path: number[] = [];
  private startX: number = 0;
  private startY: number = 0;
  private lastX: number = 0;
  private lastY: number = 0;
  private start: number = -1;
  private dragging: boolean = false;
  private down: boolean = false;
  begin(x: number, y: number, selected: number[], size: number, grid: number, gap: number): void {
    this.before = selected.slice();
    this.path = selected.slice();
    this.startX = this.lastX = x;
    this.startY = this.lastY = y;
    this.start = tenHit(x, y, grid, size, gap);
    this.dragging = false;
    this.down = true;
  }
  move(x: number, y: number, board: number[], size: number, grid: number, gap: number): number[] {
    if (!this.down || !Number.isFinite(x) || !Number.isFinite(y)) return this.path.slice();
    if (!this.dragging && Math.hypot(x - this.startX, y - this.startY) < 6) return this.path.slice();
    if (!this.dragging) {
      this.dragging = true;
      this.path = this.start >= 0 && board[this.start] > 0 ? [this.start] : [];
    }
    const distance = Math.hypot(x - this.lastX, y - this.lastY);
    const steps = Math.min(128, Math.max(1, Math.ceil(distance / (grid / size / 4))));
    for (let s = 1; s <= steps; s += 1) {
      const i = tenHit(this.lastX + (x - this.lastX) * s / steps,
        this.lastY + (y - this.lastY) * s / steps, grid, size, gap);
      if (i >= 0 && (this.path.length === 0 || this.path[this.path.length - 1] !== i)) {
        this.path = tenSelect(board, this.path, i, size);
        if (tenSum(board, this.path) === 10) break;
      }
    }
    this.lastX = x;
    this.lastY = y;
    return this.path.slice();
  }
  end(x: number, y: number, board: number[], size: number, grid: number, gap: number): TenGestureResult {
    if (!this.down) return { path: this.before.slice(), commit: false };
    this.move(x, y, board, size, grid, gap);
    const path = this.dragging ? this.path.slice() : tenSelect(board, this.before, this.start, size);
    this.down = false;
    return { path: path, commit: this.dragging && tenSum(board, path) === 10 };
  }
  cancel(): number[] { this.down = false; return this.before.slice(); }
}
