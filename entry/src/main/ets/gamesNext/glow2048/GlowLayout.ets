export interface GlowInsets { top: number; bottom: number; left: number; right: number; }
export interface GlowRect { x: number; y: number; width: number; height: number; }
export interface GlowCrease extends GlowRect {}
export interface GlowLayout {
  x: number; y: number; width: number; height: number; wide: boolean; compact: boolean; gap: number;
  board: number; cell: number; tileGap: number; tilePad: number; rail: number; body: number;
  contentWidth: number; contentHeight: number; buttonEdge: number;
  stats: GlowRect; journey: GlowRect; boardBox: GlowRect; pad: GlowRect;
  restart: GlowRect; help: GlowRect; note: GlowRect;
}

function glowRect(x: number, y: number, width: number, height: number): GlowRect {
  return { x: x, y: y, width: width, height: height };
}

// API 15 multi-hinge statuses are numeric to preserve the API 12 baseline.
export function glowUsesCreases(status: number): boolean {
  return status === 3 || status === 13 || status === 21 || status === 22 || status === 23;
}

// Split every intersecting hinge before choosing a pane. This also handles
// triple folds and windows whose origin is offset from the display origin.
export function glowViewport(width: number, height: number, insets: GlowInsets, creases: GlowCrease[]): GlowRect {
  const x = Math.max(0, insets.left);
  const y = Math.max(0, insets.top);
  const safe = glowRect(x, y, Math.max(1, width - x - Math.max(0, insets.right)),
    Math.max(1, height - y - Math.max(0, insets.bottom)));
  let panes: GlowRect[] = [safe];
  creases.forEach((fold: GlowCrease) => {
    const split: GlowRect[] = [];
    panes.forEach((pane: GlowRect) => {
      const left = Math.max(pane.x, fold.x);
      const top = Math.max(pane.y, fold.y);
      const right = Math.min(pane.x + pane.width, fold.x + fold.width);
      const bottom = Math.min(pane.y + pane.height, fold.y + fold.height);
      if (right <= left || bottom <= top) { split.push(pane); return; }
      if (right - left >= pane.width * .9 && bottom - top < pane.height) {
        if (top > pane.y) split.push(glowRect(pane.x, pane.y, pane.width, top - pane.y));
        if (bottom < pane.y + pane.height) split.push(glowRect(pane.x, bottom, pane.width, pane.y + pane.height - bottom));
      } else if (bottom - top >= pane.height * .9 && right - left < pane.width) {
        if (left > pane.x) split.push(glowRect(pane.x, pane.y, left - pane.x, pane.height));
        if (right < pane.x + pane.width) split.push(glowRect(right, pane.y, pane.x + pane.width - right, pane.height));
      } else split.push(pane);
    });
    panes = split;
  });
  return panes.reduce((best: GlowRect, pane: GlowRect): GlowRect =>
    pane.width * pane.height > best.width * best.height ? pane : best, panes[0]);
}

export function glowLayout(width: number, height: number, insets: GlowInsets,
  creases: GlowCrease[] = []): GlowLayout {
  const pane = glowViewport(width, height, insets, creases);
  const gap = pane.width >= 700 ? 24 : 12;
  const body = Math.max(1, pane.height - 72);
  // Extra-small windows can scroll horizontally as well as vertically. Controls
  // retain their touch area instead of being squeezed outside their container.
  const contentWidth = Math.max(240, pane.width - gap * 2);
  const wide = contentWidth >= 552 && (pane.width >= 700 || pane.height < 580);
  const compact = body < (wide ? 600 : 520);
  const buttonEdge = compact ? 56 : 60;
  const padEdge = buttonEdge * 3 + 8;
  const statsHeight = compact ? 64 : 78;
  const journeyHeight = compact ? 36 : 44;
  const rail = wide ? Math.min(300, Math.max(228, contentWidth * .30)) : contentWidth;
  const maxWidth = wide ? contentWidth - rail - gap : contentWidth;
  const besideTools = contentWidth >= 280;
  const deckHeight = besideTools ? padEdge : padEdge + 58;
  const portraitExtra = statsHeight + journeyHeight + 24 + deckHeight + 30;
  const preferred = body - (wide ? 24 : portraitExtra);
  const board = Math.floor(Math.min(560, maxWidth, Math.max(Math.min(256, maxWidth), preferred)));
  const tileGap = board >= 420 ? 12 : board >= 300 ? 9 : 6;
  const tilePad = tileGap + 3;
  const cell = Math.max(1, (board - tilePad * 2 - tileGap * 3) / 4);
  let stats = glowRect(0, 0, contentWidth, statsHeight);
  let journey = glowRect(0, statsHeight + 10, contentWidth, journeyHeight);
  let boardBox = glowRect((contentWidth - board) / 2, journey.y + journey.height + 10, board, board + 24);
  let pad = glowRect(0, boardBox.y + boardBox.height + 10, padEdge, padEdge);
  let restart = glowRect(padEdge + 12, pad.y + (padEdge - 140) / 2, contentWidth - padEdge - 12, 64);
  let help = glowRect(restart.x, restart.y + 76, restart.width, 64);
  let note = glowRect(0, 0, 0, 0);
  let contentHeight = pad.y + deckHeight;
  if (!wide && !besideTools) {
    pad.x = (contentWidth - padEdge) / 2;
    restart = glowRect(0, pad.y + padEdge + 10, (contentWidth - 10) / 2, 48);
    help = glowRect(restart.width + 10, restart.y, restart.width, 48);
  }
  if (wide) {
    const spacing = compact ? 8 : 12;
    const toolsHeight = compact ? 44 : 48;
    const sideHeight = statsHeight + journeyHeight + padEdge + toolsHeight + spacing * 3 + (compact ? 0 : 92);
    contentHeight = Math.max(board + 24, sideHeight);
    const boardX = (contentWidth - board - gap - rail) / 2;
    const sideX = boardX + board + gap;
    const sideY = (contentHeight - sideHeight) / 2;
    boardBox = glowRect(boardX, (contentHeight - board - 24) / 2, board, board + 24);
    stats = glowRect(sideX, sideY, rail, statsHeight);
    journey = glowRect(sideX, stats.y + statsHeight + spacing, rail, journeyHeight);
    pad = glowRect(sideX + (rail - padEdge) / 2, journey.y + journeyHeight + spacing, padEdge, padEdge);
    restart = glowRect(sideX, pad.y + padEdge + spacing, (rail - 8) / 2, toolsHeight);
    help = glowRect(sideX + restart.width + 8, restart.y, restart.width, toolsHeight);
    if (!compact) note = glowRect(sideX, restart.y + toolsHeight + 16, rail, 76);
  }
  return { x: pane.x, y: pane.y, width: pane.width, height: pane.height, wide: wide, compact: compact,
    gap: gap, rail: rail, body: body, board: board, cell: cell, tileGap: tileGap, tilePad: tilePad,
    contentWidth: contentWidth, contentHeight: contentHeight, buttonEdge: buttonEdge,
    stats: stats, journey: journey, boardBox: boardBox, pad: pad, restart: restart, help: help, note: note };
}

export function sameGlowLayout(first: GlowLayout, second: GlowLayout): boolean {
  return JSON.stringify(first) === JSON.stringify(second);
}
