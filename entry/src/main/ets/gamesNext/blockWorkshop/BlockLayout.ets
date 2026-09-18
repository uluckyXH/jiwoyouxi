export interface BlockInsets { top: number; bottom: number; left: number; right: number; }
export interface BlockCrease { x: number; y: number; width: number; height: number; }
export interface BlockFold { foldable: boolean; status: number; }
export interface BlockLayout {
  x: number; y: number; width: number; height: number; gap: number; wide: boolean; compact: boolean;
  header: number; stats: number; keys: number; body: number; rail: number; cell: number;
  boardWidth: number; boardHeight: number; limited: boolean; halfFoldPane: boolean; unfold: boolean;
  contentWidth: number; spaciousControls: boolean; keyGap: number; ornamentHeight: number;
}

/** Window-local dimensions in vp; the board always keeps square cells. */
export function blockLayout(width: number, height: number, insets: BlockInsets,
  crease: BlockCrease = { x: 0, y: 0, width: 0, height: 0 },
  fold: BlockFold = { foldable: false, status: 0 }): BlockLayout {
  let x = insets.left;
  let y = insets.top;
  let w = Math.max(1, width - insets.left - insets.right);
  let h = Math.max(1, height - insets.top - insets.bottom);
  let half = false;
  const overlapW = Math.max(0, Math.min(x + w, crease.x + crease.width) - Math.max(x, crease.x));
  const overlapH = Math.max(0, Math.min(y + h, crease.y + crease.height) - Math.max(y, crease.y));
  if (crease.height >= 0 && crease.width > 0 && overlapW >= w * 0.7 && crease.y > y && crease.y < y + h) {
    const before = crease.y - y;
    const after = Math.max(0, y + h - crease.y - crease.height);
    if (after > before) { y = crease.y + crease.height; h = after; } else h = before;
    half = true;
  } else if (crease.width >= 0 && crease.height > 0 && overlapH >= h * 0.7 && crease.x > x && crease.x < x + w) {
    const before = crease.x - x;
    const after = Math.max(0, x + w - crease.x - crease.width);
    if (after > before) { x = crease.x + crease.width; w = after; } else w = before;
    half = true;
  }
  const wide = w >= 680 || (fold.foldable && w >= 600) || (w >= 520 && w / h > 1.25);
  const compact = h < 620;
  const spaciousControls = wide && w >= 600 && h >= 520;
  const gap = compact ? 8 : 12;
  const header = compact ? 48 : 56;
  const stats = compact ? 42 : 72;
  const keyGap = spaciousControls ? 12 : 8;
  const keys = spaciousControls ? (h >= 720 ? 172 : 156) : compact ? 96 : 108;
  const rail = spaciousControls ? Math.min(380, Math.max(280, Math.round(w * 0.44))) :
    wide ? Math.min(280, Math.max(210, w * 0.3)) : compact ? 68 : 76;
  const contentWidth = Math.min(960, w);
  const body = Math.min(wide ? 656 : h, Math.max(1, h - header - (wide ? gap * 2 : stats + keys + gap * 4)));
  const boardSpace = contentWidth - gap * 3 - rail - 16;
  const cell = Math.max(1, Math.min(32, (body - 16) / 20, boardSpace / 10));
  // A folded cover display or one open panel can still have phone-sized usable space.
  // Apply the same playability limits to every window, after safe areas and crease avoidance.
  const limited = w < 280 || h < 250 || cell < 10;
  // Fold status only selects the explanation when space really is insufficient.
  // Numeric multi-fold values keep this path compatible with the API 12 build target.
  const unfold = limited && fold.foldable && (half || [2, 3, 12, 13, 21, 22, 23].includes(fold.status));
  // Four previews, five gaps and a flexible spacer; the drawing never forces scrolling.
  const ornamentHeight = !wide && !compact && body >= 380 ? Math.min(112, body - 290) : 0;
  return { x: x, y: y, width: w, height: h, gap: gap, wide: wide, compact: compact,
    header: header, stats: stats, keys: keys, body: body, rail: rail, cell: cell,
    boardWidth: cell * 10, boardHeight: cell * 20,
    limited: limited,
    halfFoldPane: half, unfold: unfold,
    contentWidth: wide ? cell * 10 + 16 + rail + gap * 3 : contentWidth,
    spaciousControls: spaciousControls, keyGap: keyGap, ornamentHeight: ornamentHeight };
}
