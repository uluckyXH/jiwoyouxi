export interface TenInsets { top: number; bottom: number; left: number; right: number; }
export interface TenRect { x: number; y: number; width: number; height: number; }
export interface TenCrease extends TenRect {}
export interface TenLayout {
  x: number; y: number; width: number; height: number; gap: number; body: number;
  contentWidth: number; contentHeight: number; wide: boolean; grid: number; cell: number; tileGap: number; pad: number;
  board: TenRect; stats: TenRect; selection: TenRect; tools: TenRect; note: TenRect;
}
function tenRect(x: number, y: number, width: number, height: number): TenRect {
  return { x: x, y: y, width: width, height: height };
}
export function tenUsesCreases(status: number): boolean {
  return status === 3 || status === 13 || status === 21 || status === 22 || status === 23;
}
export function tenViewport(width: number, height: number, insets: TenInsets, creases: TenCrease[]): TenRect {
  const safe = tenRect(Math.max(0, insets.left), Math.max(0, insets.top),
    Math.max(1, width - Math.max(0, insets.left) - Math.max(0, insets.right)),
    Math.max(1, height - Math.max(0, insets.top) - Math.max(0, insets.bottom)));
  let panes: TenRect[] = [safe];
  creases.forEach((fold: TenCrease) => {
    if (fold.width < 0 || fold.height < 0 || (fold.width === 0 && fold.height === 0)) { return; }
    const split: TenRect[] = [];
    panes.forEach((pane: TenRect) => {
      const left = Math.max(pane.x, fold.x);
      const top = Math.max(pane.y, fold.y);
      const right = Math.min(pane.x + pane.width, fold.x + Math.max(1, fold.width));
      const bottom = Math.min(pane.y + pane.height, fold.y + Math.max(1, fold.height));
      if (right <= left || bottom <= top) { split.push(pane); return; }
      if (right - left >= pane.width * .9 && bottom - top < pane.height) {
        if (top > pane.y) { split.push(tenRect(pane.x, pane.y, pane.width, top - pane.y)); }
        if (bottom < pane.y + pane.height) { split.push(tenRect(pane.x, bottom, pane.width, pane.y + pane.height - bottom)); }
      } else if (bottom - top >= pane.height * .9 && right - left < pane.width) {
        if (left > pane.x) { split.push(tenRect(pane.x, pane.y, left - pane.x, pane.height)); }
        if (right < pane.x + pane.width) { split.push(tenRect(right, pane.y, pane.x + pane.width - right, pane.height)); }
      } else { split.push(pane); }
    });
    if (split.length > 0) { panes = split; }
  });
  return panes.reduce((best: TenRect, pane: TenRect): TenRect =>
    pane.width * pane.height > best.width * best.height ? pane : best, panes[0]);
}
export function tenLayout(width: number, height: number, insets: TenInsets,
  creases: TenCrease[] = [], size: number = 6): TenLayout {
  const pane = tenViewport(width, height, insets, creases);
  const gap = pane.width >= 760 ? 22 : 12;
  const contentWidth = Math.max(292, pane.width - gap * 2);
  const wide = contentWidth >= 740;
  const body = Math.max(1, pane.height - 74);
  const rail = Math.min(316, Math.max(284, contentWidth * .29));
  const tileGap = contentWidth < 330 ? 4 : 6;
  const pad = wide ? 14 : 10;
  const minimumGrid = size * 42 + (size - 1) * tileGap;
  // Reserve room for the action row on ordinary phones. Very short windows scroll;
  // we never make the numeric targets smaller merely to avoid scrolling.
  const limit = wide ? Math.min(600, contentWidth - rail - gap) :
    Math.min(520, contentWidth, Math.max(minimumGrid + pad * 2, body - 290));
  const grid = wide ? Math.max(Math.min(minimumGrid, limit - pad * 2),
    Math.min(limit - pad * 2, body - 44 - pad * 2)) : limit - pad * 2;
  const boardWidth = grid + pad * 2;
  const boardHeight = boardWidth + 44;
  let stats = tenRect(0, 0, contentWidth, 64);
  let board = tenRect((contentWidth - boardWidth) / 2, 76, boardWidth, boardHeight);
  let selection = tenRect(0, board.y + board.height + 10, contentWidth, 64);
  let tools = tenRect(0, selection.y + selection.height + 10, contentWidth, 48);
  let note = tenRect(0, tools.y + tools.height + 10, contentWidth, 28);
  let contentHeight = note.y + note.height;
  if (wide) {
    const noteHeight = Math.max(48, Math.min(170, body - 392));
    const sideHeight = 392 + noteHeight;
    contentHeight = Math.max(boardHeight, sideHeight);
    const left = (contentWidth - boardWidth - rail - gap) / 2;
    const side = left + boardWidth + gap;
    const top = (contentHeight - sideHeight) / 2;
    board = tenRect(left, (contentHeight - boardHeight) / 2, boardWidth, boardHeight);
    stats = tenRect(side, top, rail, 64);
    selection = tenRect(side, stats.y + stats.height + 12, rail, 128);
    tools = tenRect(side, selection.y + selection.height + 12, rail, 64);
    note = tenRect(side, tools.y + tools.height + 12, rail, noteHeight);
  }
  return { x: pane.x, y: pane.y, width: pane.width, height: pane.height, gap: gap, body: body,
    contentWidth: contentWidth, contentHeight: contentHeight, wide: wide, grid: grid,
    cell: (grid - tileGap * (size - 1)) / size, tileGap: tileGap, pad: pad,
    board: board, stats: stats, selection: selection, tools: tools, note: note };
}
export function tenHit(x: number, y: number, grid: number, size: number, gap: number): number {
  if (!Number.isFinite(x) || !Number.isFinite(y) || x < 0 || y < 0 || x >= grid || y >= grid) return -1;
  const pitch = (grid + gap) / size;
  return Math.min(size - 1, Math.floor((y + gap / 2) / pitch)) * size +
    Math.min(size - 1, Math.floor((x + gap / 2) / pitch));
}
