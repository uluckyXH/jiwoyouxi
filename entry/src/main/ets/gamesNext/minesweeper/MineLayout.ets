export interface MineInsets { top: number; bottom: number; left: number; right: number; }
export interface MineCrease { x: number; y: number; width: number; height: number; }
export interface MineLayout {
  x: number; y: number; width: number; height: number;
  wide: boolean; compact: boolean; gap: number; rail: number; boardAreaWidth: number; bodyHeight: number;
  boardCardHeight: number;
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
  const bodyHeight = Math.max(100, compact ? h - 76 : h - 80 - gap * 2);
  const frame = compact ? 98 : 114;
  const boardHeight = Math.max(100, bodyHeight - (wide ? 0 : compact ? 200 : 214));
  const widthFit = Math.max(1, Math.floor((boardAreaWidth - 28) / cols));
  const heightFit = Math.floor((boardHeight - frame) / rows);
  // Phones fit every column and shrink by difficulty. On very short windows,
  // keep at least 20vp cells and scroll vertically rather than make them illegible.
  const cell = compact ? Math.min(58, widthFit, Math.max(20, heightFit)) :
    Math.max(40, Math.min(58, widthFit, heightFit));
  const gridWidth = cell * cols;
  const gridHeight = cell * rows;
  const boardCardHeight = wide ? Math.min(bodyHeight, gridHeight + frame) : compact ?
    Math.max(gridHeight + frame, boardHeight) : Math.max(280, boardHeight);
  const scrollX = gridWidth > boardAreaWidth - 28;
  const scrollY = gridHeight > boardCardHeight - frame + 4;
  return { x: x, y: y, width: w, height: h, wide: wide, compact: compact, gap: gap, rail: rail,
    boardAreaWidth: boardAreaWidth, bodyHeight: bodyHeight, cell: cell,
    boardCardHeight: boardCardHeight, gridWidth: gridWidth, gridHeight: gridHeight,
    scrolls: scrollX || scrollY, scrollX: scrollX, scrollY: scrollY };
}
