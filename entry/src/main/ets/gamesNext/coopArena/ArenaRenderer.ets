import { ArenaEngine } from './ArenaEngine';
import { ARENA_COLORS } from './ArenaModel';
import { ArenaPalette } from './ArenaPalette';

/** One canvas; SVG images are created once per theme. No per-entity UI or per-frame decoding. */
export class ArenaRenderer {
  private images: ImageBitmap[] = [];
  private theme: boolean | undefined = undefined;
  paint(ctx: CanvasRenderingContext2D, engine: ArenaEngine, size: number, dark: boolean,
    skill: number, aimX: number, aimY: number, reduced: boolean): void {
    if (this.theme !== dark) {
      this.release(); this.theme = dark;
      for (let f = 0; f < 3; f += 1) this.images.push(new ImageBitmap(`resource://RAWFILE/${ArenaPalette.piece(f,dark)}`));
    }
    ctx.clearRect(0,0,size,size); ctx.save(); ctx.scale(size/720,size/720);
    const r = engine.round, t = engine.time();
    if (engine.scenario.rule === 'zones') {
      const color = r.owner < 0 ? (dark ? '#c0bb8b' : '#b29b66') : ARENA_COLORS[r.owner];
      ctx.globalAlpha = .15; ctx.fillStyle = color; this.circle(ctx,360,360,100); ctx.fill();
      ctx.globalAlpha = 1; ctx.strokeStyle = color; ctx.lineWidth = 4; ctx.setLineDash([10,8]); ctx.stroke(); ctx.setLineDash([]);
      ctx.fillStyle = dark ? '#d2ccb0' : '#857955'; ctx.font = '22vp sans-serif'; ctx.textAlign = 'center';
      ctx.fillText(r.capturing < 0 ? '争夺据点' : r.captureTime<1 ? '正在抢占' : '控制中',360,365);
      if (r.capturing>=0 && r.captureTime<1) {
        ctx.strokeStyle=ARENA_COLORS[r.capturing]; ctx.lineWidth=5; ctx.beginPath();
        ctx.arc(360,360,106,-Math.PI/2,-Math.PI/2+Math.PI*2*r.captureTime); ctx.stroke();
      }
    }
    const border = engine.border();
    if (border > 0) {
      ctx.fillStyle = dark ? '#754d3e55' : '#c5926540';
      ctx.fillRect(0,0,720,border); ctx.fillRect(0,720-border,720,border);
      ctx.fillRect(0,border,border,720-border*2); ctx.fillRect(720-border,border,border,720-border*2);
      ctx.strokeStyle = '#c99169'; ctx.lineWidth = 3; ctx.strokeRect(border,border,720-border*2,720-border*2);
    }
    for (let i = 0; i < engine.obstacles.length; i += 1) {
      const o = engine.obstacles[i]; ctx.fillStyle = dark ? '#795843' : '#d8a275';
      this.circle(ctx,o.x,o.y,o.radius); ctx.fill(); ctx.strokeStyle = dark ? '#b7966e' : '#a8754c'; ctx.lineWidth = 3; ctx.stroke();
      ctx.fillStyle = '#86a96e'; this.circle(ctx,o.x-10,o.y-8,16); ctx.fill(); this.circle(ctx,o.x+9,o.y+5,13); ctx.fill();
    }
    if (engine.scenario.wind && t >= 18 && t < 25) {
      ctx.strokeStyle = dark ? '#d2c9ab' : '#96845c'; ctx.lineWidth = 3; ctx.setLineDash([12,8]);
      this.circle(ctx,r.windX,r.windY,150); ctx.stroke(); ctx.setLineDash([]);
      ctx.font = '22vp sans-serif'; ctx.fillStyle = dark ? '#e1d8b9' : '#7d6d4c';
      ctx.fillText(t < 20 ? `风场 ${(20-t).toFixed(1)}s` : '风场',r.windX,r.windY);
    }
    for (let i = 0; i < r.entities.length; i += 1) {
      const e = r.entities[i];
      if (e.shield > 0 && e.shieldUntil > t) {
        ctx.strokeStyle = '#dfb768'; ctx.lineWidth = 3; this.circle(ctx,e.x,e.y,31); ctx.stroke();
      } else if (e.protectedUntil > t) {
        ctx.globalAlpha = .55; ctx.strokeStyle = ARENA_COLORS[e.faction]; ctx.lineWidth = 2;
        this.circle(ctx,e.x,e.y,29); ctx.stroke(); ctx.globalAlpha = 1;
      }
      const bitmap = this.images[e.faction];
      if (bitmap !== undefined && bitmap.width > 0 && bitmap.height > 0) ctx.drawImage(bitmap,e.x-26,e.y-26,52,52);
      else { ctx.fillStyle = ARENA_COLORS[e.faction]; this.circle(ctx,e.x,e.y,23); ctx.fill();
        ctx.fillStyle = '#25351f'; ctx.font = '22vp sans-serif'; ctx.fillText(['石','剪','布'][e.faction],e.x,e.y+8); }
      if (r.traitorId === e.id && !r.traitorDone) {
        ctx.strokeStyle = '#d69b56'; ctx.lineWidth = 4; this.circle(ctx,e.x,e.y,35); ctx.stroke();
        ctx.fillStyle = dark ? '#ffcf82' : '#a46623'; ctx.font = '24vp sans-serif';
        ctx.fillText(`${Math.max(0,Math.ceil(r.traitorAt-t))}`,e.x,e.y-38);
      }
    }
    if (!reduced) for (let i = 0; i < engine.effects.length; i += 1) {
      const fx = engine.effects[i], progress = Math.min(1,(t-fx.at)/.65);
      ctx.globalAlpha = .6*(1-progress); ctx.strokeStyle = ARENA_COLORS[fx.faction]; ctx.lineWidth = 5*(1-progress)+1;
      this.circle(ctx,fx.x,fx.y,20+progress*engine.radius(fx.kind-1)); ctx.stroke();
    }
    ctx.globalAlpha = 1;
    if (skill >= 0 && aimX >= 0) {
      ctx.strokeStyle = ArenaPalette.accent(dark); ctx.lineWidth = 3;
      ctx.setLineDash([10,7]); this.circle(ctx,aimX,aimY,engine.radius(skill)); ctx.stroke(); ctx.setLineDash([]);
      ctx.globalAlpha = .12; ctx.fillStyle = ArenaPalette.accent(dark); ctx.fill(); ctx.globalAlpha = 1;
      ctx.beginPath(); ctx.moveTo(aimX-12,aimY); ctx.lineTo(aimX+12,aimY); ctx.moveTo(aimX,aimY-12); ctx.lineTo(aimX,aimY+12); ctx.stroke();
    }
    ctx.restore();
  }
  release(): void { this.images.forEach((img: ImageBitmap) => img.close()); this.images = []; this.theme = undefined; }
  private circle(ctx: CanvasRenderingContext2D,x: number,y: number,r: number): void { ctx.beginPath(); ctx.arc(x,y,r,0,Math.PI*2); }
}
