export interface FCInsets { top: number; bottom: number; left: number; right: number; }
export interface FCRect { x: number; y: number; width: number; height: number; }
export interface FCCrease extends FCRect {}
export interface FCLayout {
  frame: FCRect; width: number; height: number; wide: boolean;
  stats: FCRect; board: FCRect; tools: FCRect;
  card: number; cardHeight: number; gap: number; inset: number; fan: number; tableY: number; surfaceWidth: number;
}
export function fcRect(x: number, y: number, width: number, height: number): FCRect { return { x: x, y: y, width: width, height: height }; }
export function fcUsesCreases(status: number): boolean { return status === 3 || status === 13 || status === 21 || status === 22 || status === 23; }
export function fcViewport(w: number, h: number, insets: FCInsets, creases: FCCrease[]): FCRect {
  const safe = fcRect(insets.left, insets.top, Math.max(1, w - insets.left - insets.right), Math.max(1, h - insets.top - insets.bottom));
  let panes: FCRect[] = [safe];
  creases.forEach((fold: FCCrease) => {
    const next: FCRect[] = [];
    panes.forEach((p: FCRect) => {
      const x1 = Math.max(p.x, fold.x); const y1 = Math.max(p.y, fold.y);
      const x2 = Math.min(p.x + p.width, fold.x + fold.width); const y2 = Math.min(p.y + p.height, fold.y + fold.height);
      if (x2 <= x1 || y2 <= y1) { next.push(p); return; }
      // Conservative exclusion also handles short cutouts intersecting a pane.
      if (fold.width >= fold.height) {
        if (y1 > p.y) next.push(fcRect(p.x, p.y, p.width, y1 - p.y));
        if (y2 < p.y + p.height) next.push(fcRect(p.x, y2, p.width, p.y + p.height - y2));
      } else {
        if (x1 > p.x) next.push(fcRect(p.x, p.y, x1 - p.x, p.height));
        if (x2 < p.x + p.width) next.push(fcRect(x2, p.y, p.x + p.width - x2, p.height));
      }
    });
    if (next.length > 0) panes = next;
  });
  return panes.reduce((a: FCRect, b: FCRect) => b.width * b.height > a.width * a.height ? b : a, panes[0]);
}
export function fcLayout(w: number, h: number, insets: FCInsets, folds: FCCrease[] = []): FCLayout {
  const frame = fcViewport(w, h, insets, folds);
  const width = Math.max(308, Math.min(1240, frame.width));
  const height = Math.max(388, frame.height - 64);
  const wide = width >= 880;
  const rail = wide ? 248 : width;
  const boardWidth = wide ? Math.min(920, width - rail - 24) : width;
  const cardGap = boardWidth >= 640 ? 8 : 4;
  const inset = boardWidth >= 640 ? 16 : 12;
  const boardHeight = wide ? height - 12 : height - 226;
  const widthFit = Math.min(96, Math.max(32, (boardWidth - inset * 2 - cardGap * 7) / 8));
  // On a normally unfolded screen, leave room for seven exposed ranks rather
  // than spending the extra width on excessively tall cards. Short half-fold
  // panes keep legible cards and scroll instead of shrinking without a limit.
  const heightFit = boardHeight >= 320 ? Math.max(widthFit * .78, (boardHeight - 64) / 4.88) : widthFit;
  const card = Math.max(32, Math.min(widthFit, heightFit));
  const centeredInset = (boardWidth - card * 8 - cardGap * 7) / 2;
  return { frame: frame, width: width, height: height, wide: wide,
    stats: fcRect(wide ? boardWidth + 24 : 12, wide ? 20 : 0, wide ? rail : width - 24, 62),
    board: fcRect(0, wide ? 0 : 72, boardWidth, Math.max(150, boardHeight)),
    tools: fcRect(wide ? boardWidth + 24 : 12, wide ? 106 : 82 + Math.max(150, boardHeight), wide ? rail : width - 24, wide ? height - 120 : 144),
    card: card, cardHeight: card * 1.42, gap: cardGap, inset: Math.max(inset, centeredInset), fan: Math.max(20, Math.min(36, card * .34)),
    tableY: card * 1.42 + 48, surfaceWidth: Math.max(boardWidth, card * 8 + cardGap * 7 + inset * 2) };
}
export function fcPileX(layout: FCLayout, pile: number): number {
  const column = pile < 8 ? pile : pile - 8;
  return layout.inset + column * (layout.card + layout.gap);
}
export function fcCardY(layout: FCLayout, pile: number, index: number): number {
  return pile < 8 ? layout.tableY + index * layout.fan : 22;
}
export function fcTarget(layout: FCLayout, x: number, y: number): number {
  if (x < layout.inset - 3 || x > layout.surfaceWidth - layout.inset + 3 || y < 0) return -1;
  const column = Math.min(7, Math.max(0, Math.floor((x - layout.inset + layout.gap / 2) / (layout.card + layout.gap))));
  return y < layout.tableY - 12 ? column + 8 : column;
}
