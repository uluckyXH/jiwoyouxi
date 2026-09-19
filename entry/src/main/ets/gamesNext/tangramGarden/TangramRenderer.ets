import { TangramEngine } from './TangramEngine';
import { TangramPoint, TangramPose, tangramCenter, tangramInside, tangramPolygon } from './TangramGeometry';
import { TANGRAM_WORLD_HEIGHT } from './TangramLevels';
import { TangramPalette as P } from './TangramPalette';

export interface TangramSegment { a: TangramPoint; b: TangramPoint; }

export function tangramOutline(polygons: TangramPoint[][]): TangramSegment[] {
  const segments: TangramSegment[] = [];
  const vertices: TangramPoint[] = [];
  polygons.forEach((polygon: TangramPoint[]) => polygon.forEach((p: TangramPoint) => vertices.push(p)));
  polygons.forEach((polygon: TangramPoint[]) => polygon.forEach((a: TangramPoint, i: number) => {
    const b = polygon[(i + 1) % polygon.length];
    const dx = b.x - a.x, dy = b.y - a.y, length2 = dx * dx + dy * dy;
    const cuts: number[] = [0, 1];
    vertices.forEach((p: TangramPoint) => {
      const t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / length2;
      if (t > .000001 && t < .999999 && Math.abs((p.x - a.x) * dy - (p.y - a.y) * dx) < 1e-7) cuts.push(t);
    });
    cuts.sort((x: number, y: number): number => x - y);
    for (let j = 1; j < cuts.length; j++) {
      if (cuts[j] - cuts[j - 1] < .000001) continue;
      const t = (cuts[j] + cuts[j - 1]) / 2;
      const outside: TangramPoint = { x: a.x + t * dx + dy * .0001, y: a.y + t * dy - dx * .0001 };
      if (polygons.some((p: TangramPoint[]): boolean => tangramInside(outside, p))) continue;
      segments.push({ a: { x: a.x + cuts[j - 1] * dx, y: a.y + cuts[j - 1] * dy },
        b: { x: a.x + cuts[j] * dx, y: a.y + cuts[j] * dy } });
    }
  }));
  return segments;
}

export class TangramRenderer {
  private levelId: string = '';
  private target: TangramPoint[][] = [];
  private outline: TangramSegment[] = [];

  draw(ctx: CanvasRenderingContext2D, edge: number, engine: TangramEngine, dark: boolean): void {
    if (edge <= 0) return;
    if (this.levelId !== engine.levelId) {
      this.levelId = engine.levelId; this.target = engine.target(); this.outline = tangramOutline(this.target);
    }
    const scale = edge / 8;
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, edge, edge * TANGRAM_WORLD_HEIGHT / 8);
    ctx.setTransform(scale, 0, 0, scale, 0, 0);
    ctx.fillStyle = P.paper(dark); ctx.fillRect(0, 0, 8, TANGRAM_WORLD_HEIGHT);
    ctx.fillStyle = P.soft(dark); ctx.fillRect(0, 6.65, 8, TANGRAM_WORLD_HEIGHT - 6.65);
    ctx.strokeStyle = P.line(dark); ctx.lineWidth = .025;
    ctx.beginPath(); ctx.moveTo(.35, 6.65); ctx.lineTo(7.65, 6.65); ctx.stroke();
    ctx.beginPath(); this.target.forEach((polygon: TangramPoint[]) => this.path(ctx, polygon));
    ctx.fillStyle = P.target(dark); ctx.fill();
    ctx.beginPath();
    this.outline.forEach((s: TangramSegment) => { ctx.moveTo(s.a.x, s.a.y); ctx.lineTo(s.b.x, s.b.y); });
    ctx.strokeStyle = dark ? '#91A181' : '#A6B88A'; ctx.lineWidth = .038; ctx.stroke();
    if (engine.guide && !engine.solved) {
      ctx.beginPath(); this.target.forEach((polygon: TangramPoint[]) => this.path(ctx, polygon));
      ctx.lineWidth = .022; ctx.strokeStyle = dark ? '#829473' : '#B4C19E';
      ctx.setLineDash([.08, .08]); ctx.stroke(); ctx.setLineDash([]);
    }
    if (engine.hint !== undefined) {
      ctx.beginPath(); this.path(ctx, tangramPolygon(engine.hint));
      ctx.fillStyle = dark ? '#CFD99B44' : '#F8D68B88'; ctx.fill();
      ctx.strokeStyle = P.accent(dark); ctx.lineWidth = .065; ctx.setLineDash([.12, .06]); ctx.stroke(); ctx.setLineDash([]);
    }
    engine.poses.filter((p: TangramPose): boolean => p.id !== engine.selected).forEach((p: TangramPose) => this.piece(ctx, p, dark, false));
    const selected = engine.poses.find((p: TangramPose): boolean => p.id === engine.selected);
    if (selected !== undefined) this.piece(ctx, selected, dark, !engine.solved);
    ctx.setTransform(1, 0, 0, 1, 0, 0);
  }

  private path(ctx: CanvasRenderingContext2D, polygon: TangramPoint[]): void {
    ctx.moveTo(polygon[0].x, polygon[0].y);
    for (let i = 1; i < polygon.length; i++) ctx.lineTo(polygon[i].x, polygon[i].y);
    ctx.closePath();
  }

  private piece(ctx: CanvasRenderingContext2D, pose: TangramPose, dark: boolean, selected: boolean): void {
    const polygon = tangramPolygon(pose);
    const center = tangramCenter(pose);
    ctx.save();
    ctx.translate(0, .055); ctx.beginPath(); this.path(ctx, polygon);
    ctx.fillStyle = dark ? '#10171066' : '#9C795A30'; ctx.fill(); ctx.restore();
    ctx.beginPath(); this.path(ctx, polygon);
    ctx.fillStyle = P.piece(pose.id, dark); ctx.fill();
    ctx.lineJoin = 'round'; ctx.lineWidth = selected ? .065 : .026;
    ctx.strokeStyle = selected ? P.accent(dark) : dark ? '#ECDDAD66' : '#7D684555'; ctx.stroke();
    // Small inset edge gives each wooden piece a little depth, with no filters.
    ctx.beginPath(); this.path(ctx, polygon.map((p: TangramPoint): TangramPoint =>
      ({ x: center.x + (p.x - center.x) * .92, y: center.y + (p.y - center.y) * .92 })));
    ctx.lineWidth = .025; ctx.strokeStyle = '#FFFBE63D'; ctx.stroke();
    const size = pose.id < 2 ? .11 : .085;
    ctx.fillStyle = '#514D3E';
    ctx.beginPath(); ctx.arc(center.x - size, center.y - .03, .024, 0, Math.PI * 2);
    ctx.arc(center.x + size, center.y - .03, .024, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = '#514D3E'; ctx.lineWidth = .022;
    ctx.beginPath(); ctx.arc(center.x, center.y + .012, .047, .15, Math.PI - .15); ctx.stroke();
    ctx.fillStyle = '#D5766855';
    ctx.beginPath(); ctx.ellipse(center.x - size - .06, center.y + .045, .047, .025, 0, 0, Math.PI * 2);
    ctx.ellipse(center.x + size + .06, center.y + .045, .047, .025, 0, 0, Math.PI * 2); ctx.fill();
  }
}
