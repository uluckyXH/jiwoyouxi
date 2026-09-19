export interface MemoryInsets { top: number; bottom: number; left: number; right: number; }
export interface MemoryRect { x: number; y: number; width: number; height: number; }
export interface MemoryCrease extends MemoryRect {}
export interface MemoryLayout {
  x: number; y: number; width: number; height: number; gap: number; body: number;
  contentWidth: number; contentHeight: number; wide: boolean; compact: boolean;
  card: number; cardHeight: number; tileGap: number; pad: number;
  stats: MemoryRect; modes: MemoryRect; board: MemoryRect; tools: MemoryRect; note: MemoryRect;
}
function memoryRect(x: number, y: number, width: number, height: number): MemoryRect {
  return { x: x, y: y, width: width, height: height };
}
export function memoryUsesCreases(status: number): boolean {
  return status === 3 || status === 13 || status === 21 || status === 22 || status === 23;
}
export function memoryViewport(width: number, height: number, insets: MemoryInsets, creases: MemoryCrease[]): MemoryRect {
  const safe = memoryRect(Math.max(0, insets.left), Math.max(0, insets.top),
    Math.max(1, width - Math.max(0, insets.left) - Math.max(0, insets.right)),
    Math.max(1, height - Math.max(0, insets.top) - Math.max(0, insets.bottom)));
  let panes: MemoryRect[] = [safe];
  creases.forEach((fold: MemoryCrease) => {
    if (fold.width < 0 || fold.height < 0 || (fold.width === 0 && fold.height === 0)) { return; }
    const split: MemoryRect[] = [];
    panes.forEach((pane: MemoryRect) => {
      const left = Math.max(pane.x, fold.x);
      const top = Math.max(pane.y, fold.y);
      const right = Math.min(pane.x + pane.width, fold.x + Math.max(1, fold.width));
      const bottom = Math.min(pane.y + pane.height, fold.y + Math.max(1, fold.height));
      if (right <= left || bottom <= top) { split.push(pane); return; }
      if (right - left >= pane.width * .9 && bottom - top < pane.height) {
        if (top > pane.y) { split.push(memoryRect(pane.x, pane.y, pane.width, top - pane.y)); }
        if (bottom < pane.y + pane.height) { split.push(memoryRect(pane.x, bottom, pane.width, pane.y + pane.height - bottom)); }
      } else if (bottom - top >= pane.height * .9 && right - left < pane.width) {
        if (left > pane.x) { split.push(memoryRect(pane.x, pane.y, left - pane.x, pane.height)); }
        if (right < pane.x + pane.width) { split.push(memoryRect(right, pane.y, pane.x + pane.width - right, pane.height)); }
      } else { split.push(pane); }
    });
    if (split.length > 0) { panes = split; }
  });
  return panes.reduce((best: MemoryRect, pane: MemoryRect): MemoryRect =>
    pane.width * pane.height > best.width * best.height ? pane : best, panes[0]);
}
export function memoryLayout(width: number, height: number, insets: MemoryInsets,
  creases: MemoryCrease[] = [], pairs: number = 6): MemoryLayout {
  const pane = memoryViewport(width, height, insets, creases);
  const gap = pane.width >= 720 ? 22 : 12;
  const contentWidth = Math.max(264, pane.width - gap * 2);
  const wide = contentWidth >= 720;
  const compact = pane.height < 700;
  const body = Math.max(1, pane.height - 74);
  const rows = pairs / 2;
  const statsHeight = compact ? 56 : 66;
  const modeHeight = 50;
  const toolsHeight = 48;
  const noteHeight = wide ? 154 : compact ? 36 : 54;
  const rail = wide ? Math.min(316, Math.max(276, contentWidth * .3)) : contentWidth;
  const tileGap = wide ? 10 : 7;
  const pad = wide ? 18 : 12;
  const boardExtra = 88;
  const otherHeight = wide ? 0 : statsHeight + modeHeight + toolsHeight + noteHeight + 40;
  const widthLimit = wide ? Math.min(540, contentWidth - rail - gap) : Math.min(480, contentWidth);
  const byWidth = (widthLimit - pad * 2 - tileGap * 3) / 4;
  const byHeight = (body - otherHeight - boardExtra - tileGap * (rows - 1) - pad * 2) / rows / 1.12;
  const minimum = Math.min(byWidth, wide ? 62 : 49);
  const card = Math.floor(Math.min(byWidth, Math.max(minimum, byHeight)));
  const cardHeight = Math.round(card * 1.12);
  const boardWidth = card * 4 + tileGap * 3 + pad * 2;
  const boardHeight = cardHeight * rows + tileGap * (rows - 1) + pad * 2 + boardExtra;
  let stats = memoryRect(0, 0, contentWidth, statsHeight);
  let modes = memoryRect(0, stats.height + 10, contentWidth, modeHeight);
  let board = memoryRect((contentWidth - boardWidth) / 2, modes.y + modes.height + 10, boardWidth, boardHeight);
  let tools = memoryRect(0, board.y + board.height + 10, contentWidth, toolsHeight);
  let note = memoryRect(0, tools.y + tools.height + 10, contentWidth, noteHeight);
  let contentHeight = note.y + note.height;
  if (wide) {
    const railHeight = statsHeight + modeHeight + toolsHeight + noteHeight + 36;
    contentHeight = Math.max(boardHeight, railHeight);
    const left = (contentWidth - boardWidth - rail - gap) / 2;
    const side = left + boardWidth + gap;
    const top = (contentHeight - railHeight) / 2;
    board = memoryRect(left, (contentHeight - boardHeight) / 2, boardWidth, boardHeight);
    stats = memoryRect(side, top, rail, statsHeight);
    modes = memoryRect(side, stats.y + stats.height + 12, rail, modeHeight);
    tools = memoryRect(side, modes.y + modes.height + 12, rail, toolsHeight);
    note = memoryRect(side, tools.y + tools.height + 12, rail, noteHeight);
  }
  return { x: pane.x, y: pane.y, width: pane.width, height: pane.height, gap: gap, body: body,
    contentWidth: contentWidth, contentHeight: contentHeight, wide: wide, compact: compact,
    card: card, cardHeight: cardHeight, tileGap: tileGap, pad: pad,
    stats: stats, modes: modes, board: board, tools: tools, note: note };
}
