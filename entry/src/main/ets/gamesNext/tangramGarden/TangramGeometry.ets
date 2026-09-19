export interface TangramPoint { x: number; y: number; }
export interface TangramPose { id: number; x: number; y: number; turn: number; flip: boolean; }
export interface TangramBounds { x: number; y: number; width: number; height: number; }

// Unit areas: 2 + 2 + 1 + .5 + .5 + 1 + 1 = 8. Rotations are exact 45° steps.
export function tangramShape(id: number): TangramPoint[] {
  if (id < 2) return [{ x: 0, y: 0 }, { x: 2, y: 0 }, { x: 0, y: 2 }];
  if (id === 2) return [{ x: 0, y: 0 }, { x: 1, y: 1 }, { x: -1, y: 1 }];
  if (id < 5) return [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 0, y: 1 }];
  if (id === 5) return [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 1 }, { x: 0, y: 1 }];
  return [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 2, y: 1 }, { x: 1, y: 1 }];
}

export function tangramCopy(pose: TangramPose): TangramPose {
  return { id: pose.id, x: pose.x, y: pose.y, turn: pose.turn, flip: pose.flip };
}

export function tangramPolygon(pose: TangramPose): TangramPoint[] {
  const angle = pose.turn * Math.PI / 4;
  const c = Math.cos(angle), s = Math.sin(angle);
  const points = tangramShape(pose.id).map((p: TangramPoint): TangramPoint => {
    const x = pose.flip ? -p.x : p.x;
    return { x: pose.x + x * c - p.y * s, y: pose.y + x * s + p.y * c };
  });
  return pose.flip ? points.reverse() : points;
}

function tangramCross(a: TangramPoint, b: TangramPoint, p: TangramPoint): number {
  return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
}

export function tangramArea(points: TangramPoint[]): number {
  let sum = 0;
  for (let i = 0; i < points.length; i++) {
    const p = points[i], q = points[(i + 1) % points.length];
    sum += p.x * q.y - q.x * p.y;
  }
  return Math.abs(sum) / 2;
}

// Sutherland–Hodgman: both polygons are convex, clockwise on a downward-y canvas.
export function tangramIntersection(subject: TangramPoint[], clip: TangramPoint[]): TangramPoint[] {
  let output = subject;
  for (let i = 0; i < clip.length && output.length > 0; i++) {
    const a = clip[i], b = clip[(i + 1) % clip.length];
    const input = output;
    output = [];
    let previous = input[input.length - 1];
    let prevCross = tangramCross(a, b, previous);
    for (const current of input) {
      const cross = tangramCross(a, b, current);
      if ((cross >= -1e-9) !== (prevCross >= -1e-9)) {
        const t = prevCross / (prevCross - cross);
        output.push({ x: previous.x + (current.x - previous.x) * t, y: previous.y + (current.y - previous.y) * t });
      }
      if (cross >= -1e-9) output.push(current);
      previous = current;
      prevCross = cross;
    }
  }
  return output;
}

export function tangramOverlap(a: TangramPoint[], b: TangramPoint[]): number {
  return tangramArea(tangramIntersection(a, b));
}

export function tangramInside(p: TangramPoint, polygon: TangramPoint[]): boolean {
  return polygon.every((a: TangramPoint, i: number): boolean => tangramCross(a, polygon[(i + 1) % polygon.length], p) >= -1e-8);
}

export function tangramBounds(polygons: TangramPoint[][]): TangramBounds {
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  polygons.forEach((polygon: TangramPoint[]) => polygon.forEach((p: TangramPoint) => {
    minX = Math.min(minX, p.x); minY = Math.min(minY, p.y);
    maxX = Math.max(maxX, p.x); maxY = Math.max(maxY, p.y);
  }));
  return { x: minX, y: minY, width: maxX - minX, height: maxY - minY };
}

export function tangramCenter(pose: TangramPose): TangramPoint {
  const polygon = tangramPolygon(pose);
  return { x: polygon.reduce((sum: number, p: TangramPoint): number => sum + p.x, 0) / polygon.length,
    y: polygon.reduce((sum: number, p: TangramPoint): number => sum + p.y, 0) / polygon.length };
}

export function tangramCoverage(polygon: TangramPoint[], target: TangramPoint[][]): number {
  return target.reduce((sum: number, p: TangramPoint[]): number => sum + tangramOverlap(polygon, p), 0);
}

export function tangramSolved(poses: TangramPose[], target: TangramPoint[][]): boolean {
  if (poses.length !== 7 || new Set(poses.map((p: TangramPose): number => p.id)).size !== 7 ||
    poses.some((p: TangramPose): boolean => !Number.isInteger(p.id) || p.id < 0 || p.id > 6 ||
      !Number.isInteger(p.turn) || !Number.isFinite(p.x + p.y) || typeof p.flip !== 'boolean')) return false;
  const polygons = poses.map(tangramPolygon);
  let outside = 0, overlap = 0;
  for (let i = 0; i < polygons.length; i++) {
    outside += Math.max(0, tangramArea(polygons[i]) - tangramCoverage(polygons[i], target));
    for (let j = 0; j < i; j++) overlap += tangramOverlap(polygons[i], polygons[j]);
  }
  // Small numerical tolerance, not a visual-distance shortcut. Snapping provides precision.
  return outside < .008 && overlap < .004;
}

export function tangramLegal(pose: TangramPose, poses: TangramPose[], target: TangramPoint[][]): boolean {
  const polygon = tangramPolygon(pose);
  if (tangramArea(polygon) - tangramCoverage(polygon, target) > .001) return false;
  return poses.every((other: TangramPose): boolean => other.id === pose.id || tangramOverlap(polygon, tangramPolygon(other)) < .001);
}

export function tangramSnap(pose: TangramPose, poses: TangramPose[], target: TangramPoint[][], radius: number): TangramPose {
  const original = tangramPolygon(pose);
  let best = tangramCopy(pose), distance = radius * radius;
  // Match vertices of the silhouette subdivision OR already placed pieces. The
  // latter also supports valid alternate dissections, not just reference slots.
  const anchors = target.concat(poses.filter((p: TangramPose): boolean => p.id !== pose.id).map(tangramPolygon));
  for (const polygon of anchors) {
    for (const anchor of polygon) {
      for (const vertex of original) {
        const dx = anchor.x - vertex.x, dy = anchor.y - vertex.y, d = dx * dx + dy * dy;
        if (d > distance) continue;
        const candidate = tangramCopy(pose);
        candidate.x += dx; candidate.y += dy;
        if (tangramLegal(candidate, poses, target)) { best = candidate; distance = d; }
      }
    }
  }
  return best;
}
