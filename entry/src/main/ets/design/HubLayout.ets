export interface HubInsets {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

export interface HubRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface HubLayout {
  frame: HubRect;
  navigation: string;
  navigationWidth: number;
  navigationHeight: number;
  padding: number;
  bottomPadding: number;
  gap: number;
  contentWidth: number;
  contentHeight: number;
  columns: number;
  cardWidth: number;
  textScale: number;
  heroHeight: number;
  showOverview: boolean;
  splitDetail: boolean;
  detailWidth: number;
  short: boolean;
}

export function hubInsets(): HubInsets {
  return { top: 24, right: 0, bottom: 16, left: 0 };
}

export function hubCardLogoSize(cardWidth: number): number {
  return cardWidth < 200 ? 32 : 36;
}

export function hubCardStacked(cardWidth: number, textScale: number): boolean {
  // Reserve border, left padding, artwork gap and the independent 44 vp favorite target.
  // Four 12 fp characters per line fit the longest current title in two lines.
  const textWidth = cardWidth - 2 - 12 - hubCardLogoSize(cardWidth) - 6 - 44;
  return textWidth < 52 * Math.max(1, textScale);
}

function positive(value: number, fallback: number): number {
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

/** Window coordinates, in vp. Only pass crease rectangles for a half-folded display. */
export function hubUsableFrame(width: number, height: number, insets: HubInsets, creases: HubRect[]): HubRect {
  const w = positive(width, 390);
  const h = positive(height, 844);
  const left = Math.min(Math.max(0, insets.left), w / 3);
  const right = Math.min(Math.max(0, insets.right), w / 3);
  const top = Math.min(Math.max(0, insets.top), h / 3);
  const bottom = Math.min(Math.max(0, insets.bottom), h / 3);
  let panes: HubRect[] = [{ x: left, y: top, width: w - left - right, height: h - top - bottom }];
  creases.forEach((crease: HubRect) => {
    const next: HubRect[] = [];
    panes.forEach((pane: HubRect) => {
      const x1 = Math.max(pane.x, crease.x);
      const x2 = Math.min(pane.x + pane.width, crease.x + crease.width);
      const y1 = Math.max(pane.y, crease.y);
      const y2 = Math.min(pane.y + pane.height, crease.y + crease.height);
      if (x2 <= x1 || y2 <= y1) {
        next.push(pane);
      } else if (x2 - x1 >= pane.width * 0.7) {
        if (y1 > pane.y) next.push({ x: pane.x, y: pane.y, width: pane.width, height: y1 - pane.y });
        if (y2 < pane.y + pane.height) {
          next.push({ x: pane.x, y: y2, width: pane.width, height: pane.y + pane.height - y2 });
        }
      } else if (y2 - y1 >= pane.height * 0.7) {
        if (x1 > pane.x) next.push({ x: pane.x, y: pane.y, width: x1 - pane.x, height: pane.height });
        if (x2 < pane.x + pane.width) {
          next.push({ x: x2, y: pane.y, width: pane.x + pane.width - x2, height: pane.height });
        }
      } else {
        next.push(pane);
      }
    });
    if (next.length > 0) panes = next;
  });
  // A continuous pane keeps controls reachable even on devices with multiple hinges.
  let largest = panes[0];
  panes.forEach((pane: HubRect) => {
    if (pane.width * pane.height > largest.width * largest.height) largest = pane;
  });
  return largest;
}

export function hubLayout(width: number, height: number, insets: HubInsets = hubInsets(),
  creases: HubRect[] = [], fontScale: number = 1): HubLayout {
  const frame = hubUsableFrame(width, height, insets, creases);
  const short = frame.height < 480;
  const navigation = frame.width >= 1200 && !short ? 'sidebar' :
    (frame.width >= 600 || (frame.width >= 480 && short) ? 'rail' : 'bottom');
  const navigationWidth = navigation === 'sidebar' ? 184 : (navigation === 'rail' ? 80 : 0);
  const navigationHeight = navigation === 'bottom' ? 68 : 0;
  const padding = frame.width < 360 ? 14 : (frame.width < 840 ? 20 : 28);
  const bottomPadding = navigation === 'bottom' ? 0 : padding;
  const gap = frame.width < 600 ? 12 : 16;
  const contentWidth = Math.max(1, Math.min(1280, frame.width - navigationWidth - padding * 2));
  const contentHeight = Math.max(1, frame.height - navigationHeight - padding - bottomPadding);
  const scale = Math.max(1, Math.min(positive(fontScale, 1), 2));
  const minimumCardWidth = (frame.width < 600 ? 148 : 192) * scale;
  const columns = Math.max(1, Math.min(6, Math.floor((contentWidth + gap) / (minimumCardWidth + gap))));
  return {
    frame: frame, navigation: navigation, navigationWidth: navigationWidth, navigationHeight: navigationHeight,
    padding: padding, bottomPadding: bottomPadding, gap: gap, contentWidth: contentWidth, contentHeight: contentHeight,
    columns: columns, textScale: scale, cardWidth: (contentWidth - gap * (columns - 1)) / columns,
    heroHeight: short ? 156 : Math.min(280, Math.max(188, contentWidth / (720 / 448))),
    showOverview: contentWidth >= 850 && !short && scale < 1.5,
    splitDetail: contentWidth >= 760 * scale,
    detailWidth: Math.min(380, contentWidth * 0.4), short: short
  };
}
