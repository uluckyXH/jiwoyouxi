export interface BloomPoint { x: number; y: number; }
export interface BloomGridGeometry { gridSize: number; cell: number; gap: number; inset: number; }

export function bloomCellOrigin(index: number, grid: BloomGridGeometry): BloomPoint {
  return { x: grid.inset + (index % grid.gridSize) * (grid.cell + grid.gap),
    y: grid.inset + Math.floor(index / grid.gridSize) * (grid.cell + grid.gap) };
}

/** Snap the bead's centre to a cell; margins/outside are cancellation, never a clamped edge move. */
export function bloomDropCell(x: number, y: number, grid: BloomGridGeometry): number {
  const span = grid.gridSize * (grid.cell + grid.gap) - grid.gap;
  if (!Number.isFinite(x) || !Number.isFinite(y) ||
    x < grid.inset || y < grid.inset || x >= grid.inset + span || y >= grid.inset + span) { return -1; }
  const col = Math.floor((x - grid.inset + grid.gap / 2) / (grid.cell + grid.gap));
  const row = Math.floor((y - grid.inset + grid.gap / 2) / (grid.cell + grid.gap));
  return row * grid.gridSize + col;
}

export function bloomCanDrag(active: boolean, color: number, from: number, index: number): boolean {
  return active && color >= 0 && (from < 0 || from === index);
}

/** Only the floating bead reads x/y, so pointer updates need not rebuild the page or run pathfinding. */
@Observed
export class BloomDrag {
  from: number = -1;
  color: number = -1;
  x: number = 0;
  y: number = 0;
  target: number = -1;
  valid: boolean = false;
  private origin: BloomPoint = { x: 0, y: 0 };
  private grid: BloomGridGeometry = { gridSize: 7, cell: 40, gap: 3, inset: 10 };

  begin(from: number, color: number, grid: BloomGridGeometry): void {
    this.grid = grid;
    this.origin = bloomCellOrigin(from, grid);
    this.from = from;
    this.color = color;
    this.x = this.origin.x;
    this.y = this.origin.y;
    this.target = from;
    this.valid = false;
  }

  offset(dx: number, dy: number): void {
    if (this.from < 0 || !Number.isFinite(dx) || !Number.isFinite(dy)) { return; }
    // Pan offsets stay relative to the stationary source cell, not the moving image.
    this.x = this.origin.x + dx;
    this.y = this.origin.y + dy;
    this.target = bloomDropCell(this.x + this.grid.cell / 2, this.y + this.grid.cell / 2, this.grid);
  }

  cancel(): void {
    this.from = -1;
    this.color = -1;
    this.target = -1;
    this.valid = false;
  }
}
