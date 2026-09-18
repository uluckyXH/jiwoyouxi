export interface GlowInsets { top: number; bottom: number; left: number; right: number; }
export interface GlowCrease { x: number; y: number; width: number; height: number; }
export interface GlowLayout {
  x: number; y: number; width: number; height: number; wide: boolean; gap: number;
  board: number; cell: number; tileGap: number; tilePad: number; rail: number; body: number;
}

export function glowLayout(width: number, height: number, insets: GlowInsets,
  crease: GlowCrease = { x: 0, y: 0, width: 0, height: 0 }): GlowLayout {
  let x = Math.max(0, insets.left);
  let y = Math.max(0, insets.top);
  let w = Math.max(1, width - x - Math.max(0, insets.right));
  let h = Math.max(1, height - y - Math.max(0, insets.bottom));
  if (crease.height > 0 && crease.width >= w * .7 && crease.y > y && crease.y < y + h) {
    const top = crease.y - y;
    const bottom = y + h - crease.y - crease.height;
    if (bottom > top) y = crease.y + crease.height;
    h = Math.max(1, Math.max(top, bottom));
  } else if (crease.width > 0 && crease.height >= h * .7 && crease.x > x && crease.x < x + w) {
    const left = crease.x - x;
    const right = x + w - crease.x - crease.width;
    if (right > left) x = crease.x + crease.width;
    w = Math.max(1, Math.max(left, right));
  }
  const gap = w >= 700 ? 24 : 12;
  const wide = w >= 700 || (w >= 580 && w / h > 1.15);
  const body = Math.max(1, h - 72);
  const rail = wide ? Math.min(300, Math.max(228, w * .27)) : Math.max(1, w - gap * 2);
  const maxWidth = Math.max(1, w - gap * 2 - (wide ? rail + gap : 0));
  // Keep the board usable in a short fold pane and let the surrounding Scroll
  // expose the remainder. Normal phones use the full width unless height binds.
  // Portrait: stats 78 + journey 48 + board caption 24 + D-pad 188 + gaps 30.
  // Landscape puts all controls beside the board, leaving only its caption.
  const preferredHeight = body - (wide ? 24 : 368);
  const board = Math.floor(Math.min(560, maxWidth, Math.max(Math.min(272, maxWidth), preferredHeight)));
  const tileGap = board >= 420 ? 12 : board >= 300 ? 9 : 6;
  const tilePad = tileGap + 3;
  const cell = Math.max(1, (board - tilePad * 2 - tileGap * 3) / 4);
  return { x: x, y: y, width: w, height: h, wide: wide, gap: gap, rail: rail,
    body: body, board: board, cell: cell, tileGap: tileGap, tilePad: tilePad };
}
