export interface ArenaInsets { top: number; bottom: number; left: number; right: number; }
export interface ArenaRect { x: number; y: number; width: number; height: number; }
export interface ArenaLayout {
  pane: ArenaRect; board: ArenaRect; panel: ArenaRect; wide: boolean; compact: boolean;
  limited: boolean; gap: number; header: number; stats: number; keys: number;
}
function splitArenaPanes(panes: ArenaRect[], crease: ArenaRect): ArenaRect[] {
  const result: ArenaRect[] = [];
  for (let i = 0; i < panes.length; i += 1) {
    const p = panes[i];
    const ow = Math.max(0,Math.min(p.x+p.width,crease.x+crease.width)-Math.max(p.x,crease.x));
    const oh = Math.max(0,Math.min(p.y+p.height,crease.y+crease.height)-Math.max(p.y,crease.y));
    if (crease.height >= 0 && crease.width > 0 && ow >= p.width*.7 && crease.y > p.y && crease.y < p.y+p.height) {
      result.push({x:p.x,y:p.y,width:p.width,height:crease.y-p.y});
      result.push({x:p.x,y:crease.y+crease.height,width:p.width,height:Math.max(0,p.y+p.height-crease.y-crease.height)});
    } else if (crease.width >= 0 && crease.height > 0 && oh >= p.height*.7 && crease.x > p.x && crease.x < p.x+p.width) {
      result.push({x:p.x,y:p.y,width:crease.x-p.x,height:p.height});
      result.push({x:crease.x+crease.width,y:p.y,width:Math.max(0,p.x+p.width-crease.x-crease.width),height:p.height});
    } else result.push(p);
  }
  return result.filter((p: ArenaRect): boolean => p.width > 0 && p.height > 0);
}
function arenaPaneLayout(p: ArenaRect): ArenaLayout {
  const compact = p.height < 600, gap = compact ? 8 : 12;
  const wide = p.width >= 700 || (p.width >= 520 && p.width/p.height > 1.35);
  const rail = p.width >= 860 ? 304 : p.width >= 700 ? 268 : 232;
  const header = compact ? 44 : 52, stats = compact ? 44 : 64, keys = compact ? 104 : 112;
  const size = Math.max(1,Math.min(640,wide ? p.height-gap*2 : p.height-header-stats-keys-gap*4,
    wide ? p.width-rail-gap*3 : p.width-gap*2));
  const total = size + rail + gap;
  const bx = wide ? p.x+(p.width-total)/2 : p.x+(p.width-size)/2;
  const by = wide ? p.y+(p.height-size)/2 : p.y+header+stats+gap*2;
  return { pane:p,board:{x:bx,y:by,width:size,height:size},
    panel:wide ? {x:bx+size+gap,y:p.y+gap,width:rail,height:p.height-gap*2} :
      {x:p.x+gap,y:p.y,width:p.width-gap*2,height:p.height},
    wide:wide,compact:compact,limited:size<256 || p.width<280 || p.height<250,
    gap:gap,header:header,stats:stats,keys:keys };
}
/** Insets and creases are window-local vp; folded status is deliberately not a playability gate. */
export function arenaLayout(width: number, height: number, insets: ArenaInsets = {top:24,bottom:16,left:0,right:0},
  creases: ArenaRect[] = []): ArenaLayout {
  let panes: ArenaRect[] = [{x:insets.left,y:insets.top,width:Math.max(1,width-insets.left-insets.right),
    height:Math.max(1,height-insets.top-insets.bottom)}];
  for (let i = 0; i < creases.length; i += 1) panes = splitArenaPanes(panes,creases[i]);
  let best = arenaPaneLayout(panes[0]);
  for (let i = 1; i < panes.length; i += 1) {
    const candidate = arenaPaneLayout(panes[i]);
    if (candidate.board.width > best.board.width || (candidate.board.width === best.board.width &&
      candidate.pane.width*candidate.pane.height > best.pane.width*best.pane.height)) best = candidate;
  }
  return best;
}
export function arenaWorldPoint(x: number, y: number, size: number): ArenaRect {
  return { x:x*720/size,y:y*720/size,width:0,height:0 };
}
