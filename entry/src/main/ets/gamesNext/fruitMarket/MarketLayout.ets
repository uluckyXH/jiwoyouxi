export interface MarketInsets {
  top: number;
  bottom: number;
  left: number;
  right: number;
}

export interface MarketCrease {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface MarketLayout {
  x: number;
  y: number;
  width: number;
  height: number;
  wide: boolean;
  railWidth: number;
  boardWidth: number;
  boardHeight: number;
  bodyHeight: number;
  gap: number;
  halfFoldPane: boolean;
  limited: boolean;
}

/** Fold coordinates are window-local vp. A half-folded screen uses the larger unobstructed pane. */
export function marketLayout(width: number, height: number, insets: MarketInsets,
  crease: MarketCrease = { x: 0, y: 0, width: 0, height: 0 }): MarketLayout {
  let x = insets.left;
  let y = insets.top;
  let w = Math.max(1, width - insets.left - insets.right);
  let h = Math.max(1, height - insets.top - insets.bottom);
  let halfFoldPane = false;
  const overlapWidth = Math.max(0, Math.min(x + w, crease.x + crease.width) - Math.max(x, crease.x));
  const overlapHeight = Math.max(0, Math.min(y + h, crease.y + crease.height) - Math.max(y, crease.y));
  if (crease.height > 0 && overlapWidth >= w * 0.7 && crease.y > y && crease.y < y + h) {
    const above = crease.y - y;
    const below = y + h - crease.y - crease.height;
    if (below > above) y = crease.y + crease.height;
    h = Math.max(1, Math.max(above, below));
    halfFoldPane = true;
  } else if (crease.width > 0 && overlapHeight >= h * 0.7 && crease.x > x && crease.x < x + w) {
    const left = crease.x - x;
    const right = x + w - crease.x - crease.width;
    if (right > left) x = crease.x + crease.width;
    w = Math.max(1, Math.max(left, right));
    halfFoldPane = true;
  }
  const gap = w >= 700 ? 24 : 12;
  const wide = w >= 700 || (w >= 540 && w / h > 1.2);
  const contentWidth = Math.max(1, w - gap * 2);
  const bodyHeight = Math.max(1, h - 64 - 30 - gap * 2);
  const railWidth = wide ? Math.min(280, Math.max(190, w * 0.29)) : contentWidth;
  const boardMaxWidth = Math.max(1, wide ? contentWidth - railWidth - gap : contentWidth);
  const boardMaxHeight = Math.max(1, bodyHeight - (wide ? 0 : 108));
  const boardWidth = Math.min(620, boardMaxWidth, boardMaxHeight * 360 / 520);
  // Apply the stronger minimum only to a pane split by a half-fold crease.
  // Ordinary phones keep their existing portrait/landscape layout, including 320×480.
  const limited = w < 280 || h < 260 || (!wide && boardWidth < 140) || (halfFoldPane && boardWidth < 180);
  return { x: x, y: y, width: w, height: h, wide: wide, railWidth: railWidth,
    boardWidth: boardWidth, boardHeight: boardWidth * 520 / 360, bodyHeight: bodyHeight, gap: gap,
    halfFoldPane: halfFoldPane, limited: limited };
}
