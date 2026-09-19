export interface MemoryInsets { top: number; bottom: number; left: number; right: number; }
export interface MemoryRect { x: number; y: number; width: number; height: number; }
export interface MemoryCrease extends MemoryRect {}
export interface MemoryLayout {
  x: number; y: number; width: number; height: number; gap: number; body: number;
  contentWidth: number; contentHeight: number; wide: boolean; compact: boolean;
  card: number; cardHeight: number; tileGap: number; pad: number;
  boardHeader: number; boardFooter: number;
  stats: MemoryRect; modes: MemoryRect; board: MemoryRect; tools: MemoryRect; note: MemoryRect;
}
export interface MemoryCardFaceLayout { artwork: number; labelSize: number; labelHeight: number; }
export function memoryCardFaceLayout(width: number, height: number): MemoryCardFaceLayout {
  const labelSize = width >= 58 && height >= 54 ? Math.min(12, width * .135) : 0;
  const labelHeight = labelSize > 0 ? labelSize + 4 : 0;
  return { artwork: Math.max(1, Math.min(width * .8, height - labelHeight - 8)),
    labelSize: labelSize, labelHeight: labelHeight };
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
  // Leave room for fractional vp / physical-pixel rounding at the scroll edge.
  const usableBody = Math.max(1, body - 2);
  const rows = pairs / 2;
  const dense = !wide && pairs >= 10;
  const statsHeight = compact ? 44 : dense ? 48 : 66;
  const modeHeight = compact || dense ? 44 : 50;
  const toolsHeight = compact || dense ? 44 : 48;
  const sectionGap = compact ? 6 : dense ? 8 : 10;
  let noteHeight = wide ? 154 : compact ? 36 : 54;
  const rail = wide ? Math.min(316, Math.max(276, contentWidth * .3)) : contentWidth;
  const tileGap = compact ? 5 : wide ? 10 : 7;
  const pad = compact ? 8 : wide ? 18 : 12;
  const boardHeader = compact ? 30 : dense ? 36 : 50;
  const boardFooter = compact ? 24 : dense ? 28 : 38;
  const boardExtra = boardHeader + boardFooter;
  const widthLimit = wide ? Math.min(540, contentWidth - rail - gap) : Math.min(480, contentWidth);
  const byWidth = (widthLimit - pad * 2 - tileGap * 3) / 4;
  let card = byWidth;
  let cardHeight = Math.round(card * 1.12);
  if (wide) {
    const availableHeight = (usableBody - boardExtra - tileGap * (rows - 1) - pad * 2) / rows;
    card = Math.floor(Math.min(byWidth, Math.max(Math.min(byWidth, 49), availableHeight / 1.12)));
    cardHeight = Math.max(49, Math.min(Math.round(card * 1.12), Math.floor(availableHeight)));
  } else {
    // Keep four full-width columns and their remembered positions. Drop secondary
    // copy before sizing each row from the actual space left above the tool buttons.
    const preferredHeight = Math.max(49, Math.round(card * .82));
    const fixedHeight = statsHeight + modeHeight + toolsHeight + sectionGap * 3 + boardExtra +
      tileGap * (rows - 1) + pad * 2;
    if (usableBody - fixedHeight - noteHeight - sectionGap < preferredHeight * rows) { noteHeight = 0; }
    const availableHeight = usableBody - fixedHeight - (noteHeight > 0 ? noteHeight + sectionGap : 0);
    cardHeight = Math.max(49, Math.min(cardHeight, Math.floor(availableHeight / rows)));
  }
  const boardWidth = card * 4 + tileGap * 3 + pad * 2;
  const boardHeight = cardHeight * rows + tileGap * (rows - 1) + pad * 2 + boardExtra;
  let stats = memoryRect(0, 0, contentWidth, statsHeight);
  let modes = memoryRect(0, stats.height + sectionGap, contentWidth, modeHeight);
  let board = memoryRect((contentWidth - boardWidth) / 2, modes.y + modes.height + sectionGap, boardWidth, boardHeight);
  let tools = memoryRect(0, board.y + board.height + sectionGap, contentWidth, toolsHeight);
  let note = memoryRect(0, tools.y + tools.height + (noteHeight > 0 ? sectionGap : 0), contentWidth, noteHeight);
  let contentHeight = note.y + note.height;
  if (wide) {
    const railHeight = statsHeight + modeHeight + toolsHeight + noteHeight + sectionGap * 3;
    contentHeight = Math.max(boardHeight, railHeight);
    const left = (contentWidth - boardWidth - rail - gap) / 2;
    const side = left + boardWidth + gap;
    const top = (contentHeight - railHeight) / 2;
    board = memoryRect(left, (contentHeight - boardHeight) / 2, boardWidth, boardHeight);
    stats = memoryRect(side, top, rail, statsHeight);
    modes = memoryRect(side, stats.y + stats.height + sectionGap, rail, modeHeight);
    tools = memoryRect(side, modes.y + modes.height + sectionGap, rail, toolsHeight);
    note = memoryRect(side, tools.y + tools.height + sectionGap, rail, noteHeight);
  }
  return { x: pane.x, y: pane.y, width: pane.width, height: pane.height, gap: gap, body: body,
    contentWidth: contentWidth, contentHeight: contentHeight, wide: wide, compact: compact,
    card: card, cardHeight: cardHeight, tileGap: tileGap, pad: pad, boardHeader: boardHeader, boardFooter: boardFooter,
    stats: stats, modes: modes, board: board, tools: tools, note: note };
}
