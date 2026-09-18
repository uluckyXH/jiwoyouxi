import { ArenaPalette as P } from './ArenaPalette';

/** Precompiled vector backup: recognizable artwork even while a device decodes an SVG. */
export class ArenaArtwork {
  private rock: Path2D = new Path2D('M15 73 10 49 28 20 59 12 85 33 92 67 73 86 32 89Z');
  private facets: Path2D = new Path2D('M28 20 36 42 60 35 85 33M36 42 18 64M60 35 75 64 92 67');
  private blades: Path2D = new Path2D('M43 51 29 14Q27 7 34 9L55 47M56 50 76 16Q80 10 83 17L66 59');
  private handles: Path2D = new Path2D('M47 58C45 31 4 44 15 70C22 89 48 82 47 58ZM55 59C60 32 96 48 84 71C73 91 50 78 55 59Z');
  private holes: Path2D = new Path2D('M35 55Q21 50 22 64T37 66M66 58Q82 55 78 68T62 65');
  private cloth: Path2D = new Path2D('M17 20Q46 14 78 21L87 78Q55 88 19 84L11 29Z');
  private seam: Path2D = new Path2D('M17 20 25 78Q50 80 79 74M28 30Q48 26 68 30');
  private smile: Path2D = new Path2D('M49 64Q54 69 59 63');
  private flagPath: Path2D = new Path2D('M-15 24V-24Q0-32 13-24T36-24V5Q22 13 10 5T-15 5');
  draw(ctx: CanvasRenderingContext2D, faction: number, dark: boolean, x: number, y: number, size: number): void {
    ctx.save(); ctx.translate(x-size/2,y-size/2); ctx.scale(size/100,size/100);
    ctx.fillStyle=P.teamSurface(faction,dark); ctx.strokeStyle=P.faction(faction,dark); ctx.lineWidth=2;
    ctx.beginPath(); ctx.arc(50,50,47,0,Math.PI*2); ctx.fill(); ctx.stroke();
    ctx.translate(11,10); ctx.scale(.78,.78); ctx.lineCap='round'; ctx.lineJoin='round';
    if(faction===0) {
      this.path(ctx,this.rock,'#88adc1','#33434b',3.5);
      this.path(ctx,this.facets,'','#bbd3df',4);
    } else if(faction===1) {
      this.path(ctx,this.blades,'#f1d6b1','#614a38',3.5);
      this.path(ctx,this.handles,'#e99775','#914e3b',3.5);
      this.path(ctx,this.holes,'#fff0d7','#bd7156',3);
      ctx.fillStyle='#eed4a3'; ctx.beginPath(); ctx.arc(51,50,6,0,Math.PI*2); ctx.fill();
    } else {
      this.path(ctx,this.cloth,'#a4c994','#426348',3.5);
      this.path(ctx,this.seam,'','#dbe4b5',3);
    }
    if(faction!==1) {
      ctx.fillStyle='#334434'; ctx.beginPath(); ctx.ellipse(43,55,2.3,3,0,0,Math.PI*2);
      ctx.ellipse(63,53,2.3,3,0,0,Math.PI*2); ctx.fill();
      this.path(ctx,this.smile,'','#334434',2.5);
    }
    ctx.restore();
  }
  flag(ctx: CanvasRenderingContext2D, x: number, y: number, color: string): void {
    ctx.save(); ctx.translate(x,y); this.path(ctx,this.flagPath,'',color,3); ctx.restore();
  }
  private path(ctx: CanvasRenderingContext2D, path: Path2D, fill: string, stroke: string, width: number): void {
    if(fill.length>0) { ctx.fillStyle=fill; ctx.fill(path); }
    if(stroke.length>0) { ctx.strokeStyle=stroke; ctx.lineWidth=width; ctx.stroke(path); }
  }
}
