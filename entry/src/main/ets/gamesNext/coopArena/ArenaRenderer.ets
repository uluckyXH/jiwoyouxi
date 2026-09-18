import { hilog } from '@kit.PerformanceAnalysisKit';
import { ArenaArtwork } from './ArenaArtwork';
import { ArenaEngine } from './ArenaEngine';
import { ARENA_COLORS, ARENA_RADIUS, ARENA_INSET } from './ArenaModel';
import { ArenaPalette } from './ArenaPalette';

/** One canvas; SVG images are created once per theme. No per-entity UI or per-frame decoding. */
export class ArenaRenderer {
  private images: Array<ImageBitmap | undefined> = [];
  private ready: boolean[] = [false,false,false];
  private theme: boolean | undefined = undefined;
  private artwork: ArenaArtwork = new ArenaArtwork();
  private waited: number = 0;
  prepare(dark: boolean): void {
    if(this.theme===dark)return;
    this.release(); this.theme=dark;
    for(let f=0;f<3;f+=1) {
      try { this.images.push(new ImageBitmap(`resource://RAWFILE/${ArenaPalette.token(f,dark)}`)); }
      catch (_) { this.images.push(undefined); this.warn(f,'加载失败'); }
    }
  }
  mode(): string { return `SVG ${Number(this.ready[0])+Number(this.ready[1])+Number(this.ready[2])}/3`; }
  private checkImages(): void {
    this.waited+=1;
    for(let f=0;f<3;f+=1) {
      const bitmap=this.images[f];
      if(this.ready[f] || bitmap===undefined)continue;
      const width=bitmap.width, height=bitmap.height;
      if(width>0 && height>0) {
        this.ready[f]=true;
        hilog.info(0,'CoopArenaPerf','%{public}s',`[素材 v2] 图章=${f} SVG就绪=${width}×${height}；按目标直径绘制，接触半径=${ARENA_RADIUS}`);
      } else if(this.waited===120) this.warn(f,'解码未就绪');
    }
  }
  private warn(faction: number, reason: string): void {
    hilog.warn(0,'CoopArenaPerf','%{public}s',`[素材 v2] 图章=${faction} ${reason}，使用矢量图形备用；没有文字圆点`);
  }
  paint(ctx: CanvasRenderingContext2D, engine: ArenaEngine, size: number, dark: boolean,
    skill: number, aimX: number, aimY: number, reduced: boolean, alpha: number = 1): void {
    if(size<=0)return;
    this.prepare(dark); this.checkImages();
    ctx.clearRect(0,0,size,size); ctx.save(); ctx.scale(size/720,size/720);
    const r = engine.round, t = engine.time();
    if (engine.scenario.rule === 'zones') {
      const color = r.owner < 0 ? (dark ? '#c0bb8b' : '#b29b66') : ARENA_COLORS[r.owner];
      ctx.globalAlpha = .15; ctx.fillStyle = color; this.circle(ctx,360,360,100); ctx.fill();
      ctx.globalAlpha = 1; ctx.strokeStyle = color; ctx.lineWidth = 4; ctx.setLineDash([10,8]); ctx.stroke(); ctx.setLineDash([]);
      this.artwork.flag(ctx,354,360,color);
      if (r.capturing>=0 && r.captureTime<1) {
        ctx.strokeStyle=ARENA_COLORS[r.capturing]; ctx.lineWidth=5; ctx.beginPath();
        ctx.arc(360,360,106,-Math.PI/2,-Math.PI/2+Math.PI*2*r.captureTime); ctx.stroke();
      }
    }
    const border = engine.border()+ARENA_INSET;
    if (border > ARENA_INSET) {
      ctx.fillStyle = dark ? '#754d3e55' : '#c5926540';
      ctx.fillRect(0,0,720,border); ctx.fillRect(0,720-border,720,border);
      ctx.fillRect(0,border,border,720-border*2); ctx.fillRect(720-border,border,border,720-border*2);
      ctx.strokeStyle = '#c99169'; ctx.lineWidth = 3; ctx.strokeRect(border,border,720-border*2,720-border*2);
    }
    if (engine.scenario.wind && t >= 18 && t < 25) {
      ctx.strokeStyle = dark ? '#d2c9ab' : '#96845c'; ctx.lineWidth = 3; ctx.setLineDash([12,8]);
      this.circle(ctx,r.windX,r.windY,150); ctx.stroke(); ctx.setLineDash([]);
      ctx.beginPath(); ctx.moveTo(r.windX-34,r.windY-8); ctx.lineTo(r.windX+22,r.windY-8);
      ctx.moveTo(r.windX-22,r.windY+8); ctx.lineTo(r.windX+34,r.windY+8); ctx.stroke();
    }
    for (let i = 0; i < r.entities.length; i += 1) {
      const e = r.entities[i], x=engine.visualX(i,alpha), y=engine.visualY(i,alpha);
      if (e.shield > 0 && e.shieldUntil > t) {
        ctx.strokeStyle = '#dfb768'; ctx.lineWidth = 3; this.circle(ctx,x,y,31); ctx.stroke();
      } else if (e.protectedUntil > t) {
        ctx.globalAlpha = .55; ctx.strokeStyle = ARENA_COLORS[e.faction]; ctx.lineWidth = 2;
        this.circle(ctx,x,y,29); ctx.stroke(); ctx.globalAlpha = 1;
      }
      const bitmap = this.images[e.faction], diameter=ARENA_RADIUS*100/48;
      let drawn=false;
      if (bitmap !== undefined && this.ready[e.faction]) {
        try { ctx.drawImage(bitmap,x-diameter/2,y-diameter/2,diameter,diameter); drawn=true; }
        catch (_) { bitmap.close(); this.images[e.faction]=undefined; this.ready[e.faction]=false; this.warn(e.faction,'绘制失败'); }
      }
      if(!drawn)this.artwork.draw(ctx,e.faction,dark,x,y,diameter);
      if (r.traitorId === e.id && !r.traitorDone) {
        ctx.strokeStyle = '#d69b56'; ctx.lineWidth = 4; this.circle(ctx,x,y,35); ctx.stroke();
        ctx.fillStyle = dark ? '#ffcf82' : '#a46623'; ctx.font = '500 22px sans-serif'; ctx.textAlign='center'; ctx.textBaseline='middle';
        ctx.fillText(`${Math.max(0,Math.ceil(r.traitorAt-t))}`,x,y-39);
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
  release(): void {
    this.images.forEach((img: ImageBitmap | undefined) => { if(img!==undefined)img.close(); });
    this.images=[]; this.ready=[false,false,false]; this.theme=undefined; this.waited=0;
  }
  private circle(ctx: CanvasRenderingContext2D,x: number,y: number,r: number): void { ctx.beginPath(); ctx.arc(x,y,r,0,Math.PI*2); }
}
