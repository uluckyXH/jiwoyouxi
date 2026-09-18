export interface MineInsets { top: number; bottom: number; left: number; right: number; }
export interface MineCrease { x: number; y: number; width: number; height: number; }
export interface MineLayout {
  x: number; y: number; width: number; height: number;
  wide: boolean; gap: number; rail: number; boardAreaWidth: number; bodyHeight: number;
  cell: number; gridWidth: number; gridHeight: number; scrolls: boolean;
}

export function mineLayout(width: number, height: number, rows: number, cols: number,
  insets: MineInsets, crease: MineCrease = { x: 0, y: 0, width: 0, height: 0 }): MineLayout {
  let x = Math.max(0, insets.left);
  let y = Math.max(0, insets.top);
  let w = Math.max(1, width - x - Math.max(0, insets.right));
  let h = Math.max(1, height - y - Math.max(0, insets.bottom));
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
  const bodyHeight = Math.max(100, h - 80 - gap * 2);
  const boardHeight = Math.max(100, bodyHeight - (wide ? 0 : 214));
  // Grid scrolls on small windows: never shrink a cell below a 40vp touch target.
  const cell = Math.max(40, Math.min(58, Math.floor(Math.min((boardAreaWidth - 28) / cols, (boardHeight - 114) / rows))));
  const gridWidth = cell * cols;
  const gridHeight = cell * rows;
  return { x: x, y: y, width: w, height: h, wide: wide, gap: gap, rail: rail,
    boardAreaWidth: boardAreaWidth, bodyHeight: bodyHeight, cell: cell,
    gridWidth: gridWidth, gridHeight: gridHeight, scrolls: gridWidth > boardAreaWidth - 28 || gridHeight > boardHeight - 114 };
}
