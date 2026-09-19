export interface TangramInsets { top: number; bottom: number; left: number; right: number; }
export interface TangramRect { x: number; y: number; width: number; height: number; }
export interface TangramCrease extends TangramRect {}
function tangramRect(x: number, y: number, width: number, height: number): TangramRect {
  return { x: x, y: y, width: width, height: height };
}

// API 15 multi-hinge statuses are numeric to preserve the API 12 baseline.
export function tangramUsesCreases(status: number): boolean {
  return status === 3 || status === 13 || status === 21 || status === 22 || status === 23;
}

// Split every intersecting hinge before choosing a pane. This also handles
// triple folds and windows whose origin is offset from the display origin.
export function tangramViewport(width: number, height: number, insets: TangramInsets, creases: TangramCrease[]): TangramRect {
  const x = Math.max(0, insets.left);
  const y = Math.max(0, insets.top);
  const safe = tangramRect(x, y, Math.max(1, width - x - Math.max(0, insets.right)),
    Math.max(1, height - y - Math.max(0, insets.bottom)));
  let panes: TangramRect[] = [safe];
  creases.forEach((fold: TangramCrease) => {
    const split: TangramRect[] = [];
    panes.forEach((pane: TangramRect) => {
      const left = Math.max(pane.x, fold.x);
      const top = Math.max(pane.y, fold.y);
      const right = Math.min(pane.x + pane.width, fold.x + fold.width);
      const bottom = Math.min(pane.y + pane.height, fold.y + fold.height);
      if (right <= left || bottom <= top) { split.push(pane); return; }
      if (right - left >= pane.width * .9 && bottom - top < pane.height) {
        if (top > pane.y) split.push(tangramRect(pane.x, pane.y, pane.width, top - pane.y));
        if (bottom < pane.y + pane.height) split.push(tangramRect(pane.x, bottom, pane.width, pane.y + pane.height - bottom));
      } else if (bottom - top >= pane.height * .9 && right - left < pane.width) {
        if (left > pane.x) split.push(tangramRect(pane.x, pane.y, left - pane.x, pane.height));
        if (right < pane.x + pane.width) split.push(tangramRect(right, pane.y, pane.x + pane.width - right, pane.height));
      } else split.push(pane);
    });
    panes = split;
  });
  return panes.reduce((best: TangramRect, pane: TangramRect): TangramRect =>
    pane.width * pane.height > best.width * best.height ? pane : best, panes[0]);
}

export interface TangramLayout {
  x: number; y: number; width: number; height: number; wide: boolean; gap: number;
  contentWidth: number; contentHeight: number; body: number; board: TangramRect; tools: TangramRect;
}

export function tangramLayout(width: number, height: number, insets: TangramInsets,
  creases: TangramCrease[] = []): TangramLayout {
  const pane = tangramViewport(width, height, insets, creases);
  const gap = pane.width >= 700 ? 22 : 12;
  const contentWidth = Math.max(280, pane.width - gap * 2);
  const body = Math.max(1, pane.height - 66);
  const wide = contentWidth >= 620;
  const rail = wide ? Math.min(320, Math.max(260, contentWidth * .32)) : contentWidth;
  // Fit the whole workspace on normal phones and short landscape panes. Truly
  // small windows keep a useful minimum board size and expose scrolling.
  const boardWidth = wide ? Math.min(560, contentWidth - rail - gap, Math.max(216, body * 8 / 10.9)) :
    Math.min(480, contentWidth, Math.max(280, (body - 296) * 8 / 10.9));
  const boardHeight = boardWidth * 10.9 / 8;
  const totalWidth = boardWidth + (wide ? rail + gap : 0);
  const offset = (contentWidth - totalWidth) / 2;
  const board = tangramRect(offset, wide ? 0 : 76, boardWidth, boardHeight);
  const tools = wide ? tangramRect(offset + boardWidth + gap, 0, rail, Math.max(490, boardHeight)) :
    tangramRect(0, 0, contentWidth, boardHeight + 280);
  return { x: pane.x, y: pane.y, width: pane.width, height: pane.height, wide: wide, gap: gap,
    contentWidth: contentWidth, contentHeight: wide ? Math.max(boardHeight, 490) : boardHeight + 306,
    body: body, board: board, tools: tools };
}
