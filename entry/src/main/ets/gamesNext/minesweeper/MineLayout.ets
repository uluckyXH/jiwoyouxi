export interface MineInsets { top: number; bottom: number; left: number; right: number; }
export interface MineCrease { x: number; y: number; width: number; height: number; }

// Shared by the phone controls and the layout budget, so shrinking the chrome
// actually gives that space back to the board. Main touch targets stay 44vp.
export class MineCompactMetrics {
  static readonly header: number = 52;
  static readonly stats: number = 60;
  static readonly difficulty: number = 48;
  static readonly modePadding: number = 2;
  static readonly controlGap: number = 6;
  static readonly sectionGap: number = 10;
  static readonly cardPadding: number = 10;
  static readonly cardContent: number = 88; // padding + title + footer + two gaps
  static readonly cardFrame: number = MineCompactMetrics.cardContent + 4;
  static readonly controls: number = MineCompactMetrics.stats + MineCompactMetrics.difficulty +
    44 + MineCompactMetrics.modePadding * 2 + MineCompactMetrics.controlGap * 2;
}

export interface MineLayout {
  x: number; y: number; width: number; height: number;
  wide: boolean; compact: boolean; gap: number; rail: number; boardAreaWidth: number; bodyHeight: number;
  boardCardWidth: number; boardCardHeight: number;
  cell: number; gridWidth: number; gridHeight: number; scrolls: boolean; scrollX: boolean; scrollY: boolean;
}

export function mineLayout(width: number, height: number, rows: number, cols: number,
  insets: MineInsets, crease: MineCrease = { x: 0, y: 0, width: 0, height: 0 }): MineLayout {
  let x = Math.max(0, insets.left);
  let y = Math.max(0, insets.top);
  let w = Math.max(1, width - x - Math.max(0, insets.right));
  let h = Math.max(1, height - y - Math.max(0, insets.bottom));
  // Classify the full window before choosing a half-fold pane. An unfolded
  // tablet/foldable keeps its large cells even when a crease makes one pane short.
  const compact = Math.min(width, height) < 600;
  if (crease.height > 0 && crease.width >= w * 0.7 && crease.y > y && crease.y < y + h) {
    const top = crease.y - y;
    const bottom = y + h - crease.y - crease.height;
    if (bottom > top) y = crease.y + crease.height;
    h = Math.max(1, Math.max(top, bottom));
  } else if (crease.width > 0 && crease.height >= h * 0.7 && crease.x > x && crease.x < x + w) {
    const left = crease.x - x;
    const right = x + w - crease.x - crease.width;
    if (right > left) x = crease.x + crease.width;
    w = Math.max(1, Math.max(left, right));
  }
  const gap = w >= 700 ? 24 : 12;
  const wide = w >= 700 || (w >= 540 && w / h > 1.2);
  const rail = wide ? Math.min(280, Math.max(w >= 620 ? 248 : 216, w * 0.28)) : w - gap * 2;
  const boardAreaWidth = Math.max(1, w - gap * 2 - (wide ? rail + gap : 0));
  const bodyHeight = Math.max(100, compact ? h - MineCompactMetrics.header - 20 : h - 80 - gap * 2);
  const frame = compact ? MineCompactMetrics.cardFrame : 114;
  const boardHeight = Math.max(100, bodyHeight - (wide ? 0 : compact ?
    MineCompactMetrics.controls + MineCompactMetrics.sectionGap : 214));
  const horizontalFrame = compact ? MineCompactMetrics.cardPadding * 2 + 4 : 28;
  const widthFit = Math.max(1, Math.floor((boardAreaWidth - horizontalFrame) / cols));
  // Quarter-vp steps use the available height without leaving up to a full row
  // of rounding slack on a 16-row phone board. Large-screen sizing is unchanged.
  const heightFit = compact ? Math.floor((boardHeight - frame) / rows * 4) / 4 :
    Math.floor((boardHeight - frame) / rows);
  // Phones fit every column and shrink by difficulty. On very short windows,
  // keep at least 20vp cells and scroll vertically rather than make them illegible.
  const cell = compact ? Math.min(58, widthFit, Math.max(20, heightFit)) :
    Math.max(40, Math.min(58, widthFit, heightFit));
  const gridWidth = cell * cols;
  const gridHeight = cell * rows;
  const boardCardWidth = wide || compact ? Math.min(boardAreaWidth, gridWidth + horizontalFrame) : boardAreaWidth;
  const boardCardHeight = wide ? Math.min(bodyHeight, gridHeight + frame) : compact ?
    gridHeight + frame : Math.max(280, boardHeight);
  const scrollX = gridWidth > boardCardWidth - horizontalFrame;
  const scrollY = gridHeight > boardCardHeight - frame + 4;
  return { x: x, y: y, width: w, height: h, wide: wide, compact: compact, gap: gap, rail: rail,
    boardAreaWidth: boardAreaWidth, bodyHeight: bodyHeight, cell: cell,
    boardCardWidth: boardCardWidth, boardCardHeight: boardCardHeight, gridWidth: gridWidth, gridHeight: gridHeight,
    scrolls: scrollX || scrollY, scrollX: scrollX, scrollY: scrollY };
}

export function sameMineLayout(a: MineLayout, b: MineLayout): boolean {
  // All remaining dimensions are derived from these values. Insets and fold
  // listeners can deliver the same area twice; do not restart the transition.
  return a.x === b.x && a.y === b.y && a.width === b.width && a.height === b.height &&
    a.wide === b.wide && a.compact === b.compact && a.cell === b.cell &&
    a.gridWidth === b.gridWidth && a.gridHeight === b.gridHeight;
}
