export interface StarInsets { top: number; bottom: number; left: number; right: number; }
export interface StarRect { x: number; y: number; width: number; height: number; }
export interface StarCrease extends StarRect {}
export interface StarLayout {
  x: number; y: number; width: number; height: number; wide: boolean; small: boolean; gap: number;
  contentWidth: number; contentHeight: number; body: number; cell: number; tileGap: number; tilePad: number;
  stats: StarRect; board: StarRect; tools: StarRect; note: StarRect;
}
function starRect(x: number, y: number, width: number, height: number): StarRect {
  return { x: x, y: y, width: width, height: height };
}

export function starUsesCreases(status: number): boolean {
  return status === 3 || status === 13 || status === 21 || status === 22 || status === 23;
}

export function starViewport(width: number, height: number, insets: StarInsets, creases: StarCrease[]): StarRect {
  const safe = starRect(Math.max(0, insets.left), Math.max(0, insets.top),
    Math.max(1, width - Math.max(0, insets.left) - Math.max(0, insets.right)),
    Math.max(1, height - Math.max(0, insets.top) - Math.max(0, insets.bottom)));
  let panes: StarRect[] = [safe];
  creases.forEach((fold: StarCrease) => {
    if (fold.width < 0 || fold.height < 0 || (fold.width === 0 && fold.height === 0)) { return; }
    const split: StarRect[] = [];
    panes.forEach((pane: StarRect) => {
      const left = Math.max(pane.x, fold.x);
      const top = Math.max(pane.y, fold.y);
      const right = Math.min(pane.x + pane.width, fold.x + Math.max(1, fold.width));
      const bottom = Math.min(pane.y + pane.height, fold.y + Math.max(1, fold.height));
      if (right <= left || bottom <= top) { split.push(pane); return; }
      if (right - left >= pane.width * .9 && bottom - top < pane.height) {
        if (top > pane.y) { split.push(starRect(pane.x, pane.y, pane.width, top - pane.y)); }
        if (bottom < pane.y + pane.height) { split.push(starRect(pane.x, bottom, pane.width, pane.y + pane.height - bottom)); }
      } else if (bottom - top >= pane.height * .9 && right - left < pane.width) {
        if (left > pane.x) { split.push(starRect(pane.x, pane.y, left - pane.x, pane.height)); }
        if (right < pane.x + pane.width) { split.push(starRect(right, pane.y, pane.x + pane.width - right, pane.height)); }
      } else { split.push(pane); }
    });
    if (split.length > 0) { panes = split; }
  });
  return panes.reduce((best: StarRect, pane: StarRect): StarRect =>
    pane.width * pane.height > best.width * best.height ? pane : best, panes[0]);
}

export function starLayout(width: number, height: number, insets: StarInsets, creases: StarCrease[] = []): StarLayout {
  const pane = starViewport(width, height, insets, creases);
  const gap = pane.width >= 700 ? 22 : 12;
  const contentWidth = Math.max(1, pane.width - gap * 2);
  const body = Math.max(1, pane.height - 66);
  const wide = contentWidth >= 650;
  const small = contentWidth < 278 || body < 240;
  const rail = wide ? Math.min(320, Math.max(270, contentWidth * .30)) : contentWidth;
  const maxWidth = wide ? contentWidth - rail - gap : contentWidth;
  const boardWidth = Math.floor(Math.min(560, maxWidth, Math.max(278, (body - (wide ? 12 : 218)) * .8)));
  const tileGap = boardWidth >= 420 ? 4 : 2;
  const tilePad = 12;
  const cell = Math.max(1, (boardWidth - tilePad * 2 - tileGap * 7) / 8);
  const boardHeight = cell * 10 + tileGap * 9 + tilePad * 2;
  let stats = starRect(0, 0, contentWidth, 100);
  let board = starRect((contentWidth - boardWidth) / 2, 112, boardWidth, boardHeight);
  let note = starRect(0, board.y + board.height + 8, contentWidth, 36);
  let tools = starRect(0, note.y + note.height + 8, contentWidth, 50);
  let contentHeight = tools.y + tools.height + 8;
  if (wide) {
    const x = (contentWidth - boardWidth - gap - rail) / 2;
    const sideY = Math.max(0, (boardHeight - 428) / 2);
    board = starRect(x, 0, boardWidth, boardHeight);
    stats = starRect(x + boardWidth + gap, sideY, rail, 116);
    note = starRect(stats.x, sideY + 132, rail, 84);
    tools = starRect(stats.x, sideY + 232, rail, 196);
    contentHeight = Math.max(boardHeight, tools.y + tools.height) + 12;
  }
  return { x: pane.x, y: pane.y, width: pane.width, height: pane.height, wide: wide, small: small, gap: gap,
    contentWidth: contentWidth, contentHeight: contentHeight, body: body, cell: cell, tileGap: tileGap, tilePad: tilePad,
    stats: stats, board: board, tools: tools, note: note };
}
