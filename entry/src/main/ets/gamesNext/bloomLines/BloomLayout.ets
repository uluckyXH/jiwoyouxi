import { BloomMode, bloomConfig } from './BloomModel';

export interface BloomInsets { top: number; bottom: number; left: number; right: number; }
export interface BloomRect { x: number; y: number; width: number; height: number; }
export interface BloomCrease extends BloomRect {}
export interface BloomLayout {
  x: number; y: number; width: number; height: number;
  wide: boolean; compact: boolean; gap: number; body: number;
  contentWidth: number; contentHeight: number;
  board: number; cell: number; tileGap: number; tilePad: number;
  stats: BloomRect; modes: BloomRect; queue: BloomRect; boardBox: BloomRect; tools: BloomRect; note: BloomRect;
}

function bloomRect(x: number, y: number, width: number, height: number): BloomRect {
  return { x: x, y: y, width: width, height: height };
}

export function bloomUsesCreases(status: number): boolean {
  return status === 3 || status === 13 || status === 21 || status === 22 || status === 23;
}

export function bloomViewport(width: number, height: number, insets: BloomInsets, creases: BloomCrease[]): BloomRect {
  const safe = bloomRect(Math.max(0, insets.left), Math.max(0, insets.top),
    Math.max(1, width - Math.max(0, insets.left) - Math.max(0, insets.right)),
    Math.max(1, height - Math.max(0, insets.top) - Math.max(0, insets.bottom)));
  let panes: BloomRect[] = [safe];
  creases.forEach((fold: BloomCrease) => {
    if (fold.width < 0 || fold.height < 0 || (fold.width === 0 && fold.height === 0)) { return; }
    const split: BloomRect[] = [];
    panes.forEach((pane: BloomRect) => {
      const left = Math.max(pane.x, fold.x);
      const top = Math.max(pane.y, fold.y);
      const right = Math.min(pane.x + pane.width, fold.x + Math.max(1, fold.width));
      const bottom = Math.min(pane.y + pane.height, fold.y + Math.max(1, fold.height));
      if (right <= left || bottom <= top) { split.push(pane); return; }
      if (right - left >= pane.width * .9 && bottom - top < pane.height) {
        if (top > pane.y) { split.push(bloomRect(pane.x, pane.y, pane.width, top - pane.y)); }
        if (bottom < pane.y + pane.height) { split.push(bloomRect(pane.x, bottom, pane.width, pane.y + pane.height - bottom)); }
      } else if (bottom - top >= pane.height * .9 && right - left < pane.width) {
        if (left > pane.x) { split.push(bloomRect(pane.x, pane.y, left - pane.x, pane.height)); }
        if (right < pane.x + pane.width) { split.push(bloomRect(right, pane.y, pane.x + pane.width - right, pane.height)); }
      } else { split.push(pane); }
    });
    if (split.length > 0) { panes = split; }
  });
  return panes.reduce((best: BloomRect, pane: BloomRect): BloomRect =>
    pane.width * pane.height > best.width * best.height ? pane : best, panes[0]);
}

export function bloomLayout(width: number, height: number, insets: BloomInsets,
  creases: BloomCrease[] = [], mode: BloomMode = 'garden'): BloomLayout {
  const pane = bloomViewport(width, height, insets, creases);
  const size = bloomConfig(mode).size;
  const gap = pane.width >= 700 ? 20 : 12;
  const contentWidth = Math.max(size === 9 ? 260 : 240, pane.width - gap * 2);
  const wide = contentWidth >= 680;
  const compact = pane.height < 720;
  const body = Math.max(1, pane.height - 74);
  const statsHeight = compact ? 56 : 68;
  const modeHeight = compact ? 46 : 52;
  const queueHeight = compact ? 54 : 62;
  const toolHeight = compact ? 48 : 52;
  const boardExtra = 66;
  const noteHeight = compact ? 0 : wide ? 86 : 24;
  const rail = wide ? Math.min(310, Math.max(260, contentWidth * .3)) : contentWidth;
  const maxWidth = wide ? contentWidth - rail - gap : contentWidth;
  const extra = statsHeight + modeHeight + queueHeight + toolHeight + boardExtra + noteHeight + 52;
  const minimum = Math.min(maxWidth, size === 9 ? 304 : 280);
  const preferred = body - (wide ? boardExtra : extra);
  const board = Math.floor(Math.min(size === 9 ? 608 : 532, maxWidth, Math.max(minimum, preferred)));
  const tileGap = board >= 420 ? 5 : 3;
  const tilePad = board >= 420 ? 14 : 10;
  const cell = (board - tilePad * 2 - tileGap * (size - 1)) / size;
  let stats = bloomRect(0, 0, contentWidth, statsHeight);
  let modes = bloomRect(0, stats.height + 10, contentWidth, modeHeight);
  let queue = bloomRect(0, modes.y + modes.height + 10, contentWidth, queueHeight);
  let boardBox = bloomRect((contentWidth - board) / 2, queue.y + queue.height + 10, board, board + boardExtra);
  let tools = bloomRect(0, boardBox.y + boardBox.height + 10, contentWidth, toolHeight);
  let note = bloomRect(0, tools.y + tools.height + 12, contentWidth, noteHeight);
  let contentHeight = note.y + note.height;
  if (wide) {
    const sideHeight = statsHeight + modeHeight + queueHeight + toolHeight + noteHeight + 40;
    contentHeight = Math.max(board + boardExtra, sideHeight);
    const boardX = (contentWidth - board - rail - gap) / 2;
    const sideX = boardX + board + gap;
    const sideY = (contentHeight - sideHeight) / 2;
    boardBox = bloomRect(boardX, (contentHeight - board - boardExtra) / 2, board, board + boardExtra);
    stats = bloomRect(sideX, sideY, rail, statsHeight);
    modes = bloomRect(sideX, stats.y + stats.height + 10, rail, modeHeight);
    queue = bloomRect(sideX, modes.y + modes.height + 10, rail, queueHeight);
    tools = bloomRect(sideX, queue.y + queue.height + 10, rail, toolHeight);
    note = bloomRect(sideX, tools.y + tools.height + 10, rail, noteHeight);
  }
  return { x: pane.x, y: pane.y, width: pane.width, height: pane.height, wide: wide, compact: compact,
    gap: gap, body: body, contentWidth: contentWidth, contentHeight: contentHeight,
    board: board, cell: cell, tileGap: tileGap, tilePad: tilePad,
    stats: stats, modes: modes, queue: queue, boardBox: boardBox, tools: tools, note: note };
}

export function sameBloomLayout(first: BloomLayout, second: BloomLayout): boolean {
  return JSON.stringify(first) === JSON.stringify(second);
}
