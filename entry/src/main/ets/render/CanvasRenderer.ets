import { NativeRenderState, PowerUpKind, TraitorMark, clamp } from '../model/GameTypes';
import { factionInfoForOptions } from '../model/ThemeConfig';

const TRAITOR_DELAY: number = 2000;

export class NativeCanvasRenderer {
  draw(ctx: CanvasRenderingContext2D, state: NativeRenderState): void {
    this.drawBackground(ctx, state);
    this.drawZones(ctx, state);
    this.drawPowerUps(ctx, state);
    this.drawObstacles(ctx, state);
    this.drawBlackHole(ctx, state);
    this.drawEntities(ctx, state);
    this.drawTraitorMarks(ctx, state);
    this.drawHand(ctx, state);
  }

  private drawBackground(ctx: CanvasRenderingContext2D, state: NativeRenderState): void {
    ctx.clearRect(0, 0, state.width, state.height);
    ctx.fillStyle = '#edf5f1';
    ctx.fillRect(0, 0, state.width, state.height);
    ctx.fillStyle = 'rgba(244, 242, 235, 0.95)';
    ctx.fillRect(0, 0, state.width, state.height);
    ctx.strokeStyle = state.options.shrink ? '#d95c47' : 'rgba(23,32,28,0.18)';
    ctx.lineWidth = state.options.shrink ? 4 : 2;
    ctx.strokeRect(
      state.bounds.left,
      state.bounds.top,
      state.bounds.right - state.bounds.left,
      state.bounds.bottom - state.bounds.top
    );
  }

  private drawZones(ctx: CanvasRenderingContext2D, state: NativeRenderState): void {
    for (let i = 0; i < state.zones.length; i += 1) {
      const zone = state.zones[i];
      const color = zone.owner >= 0 ? factionInfoForOptions(state.options, zone.owner).color : '#17201c';
      ctx.beginPath();
      ctx.fillStyle = 'rgba(255,255,255,0.42)';
      ctx.strokeStyle = color;
      ctx.lineWidth = 4;
      ctx.arc(zone.x, zone.y, zone.radius, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = color;
      ctx.font = '700 18vp sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(`${Math.floor(zone.score)}`, zone.x, zone.y);
    }
  }

  private drawPowerUps(ctx: CanvasRenderingContext2D, state: NativeRenderState): void {
    for (let i = 0; i < state.powerUps.length; i += 1) {
      const item = state.powerUps[i];
      let fill = '#20a4f3';
      let label = '⚡';
      if (item.kind === PowerUpKind.Shield) {
        fill = '#f0b429';
        label = '盾';
      } else if (item.kind === PowerUpKind.Split) {
        fill = '#9b5cff';
        label = '×2';
      }
      ctx.beginPath();
      ctx.fillStyle = fill;
      ctx.strokeStyle = 'rgba(255,255,255,0.88)';
      ctx.lineWidth = 2;
      ctx.arc(item.x, item.y, item.radius, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = '#ffffff';
      ctx.font = '700 11vp sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(label, item.x, item.y + 1);
    }
  }

  private drawObstacles(ctx: CanvasRenderingContext2D, state: NativeRenderState): void {
    ctx.fillStyle = 'rgba(23,32,28,0.22)';
    ctx.strokeStyle = 'rgba(23,32,28,0.34)';
    ctx.lineWidth = 2;
    for (let i = 0; i < state.obstacles.length; i += 1) {
      const item = state.obstacles[i];
      ctx.fillRect(item.x - item.width * 0.5, item.y - item.height * 0.5, item.width, item.height);
      ctx.strokeRect(item.x - item.width * 0.5, item.y - item.height * 0.5, item.width, item.height);
    }
  }

  private drawBlackHole(ctx: CanvasRenderingContext2D, state: NativeRenderState): void {
    if (!state.blackHole.active) {
      return;
    }
    ctx.beginPath();
    ctx.fillStyle = 'rgba(31,23,40,0.14)';
    ctx.arc(state.blackHole.x, state.blackHole.y, state.blackHole.reach, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.fillStyle = '#1f1728';
    ctx.arc(state.blackHole.x, state.blackHole.y, state.blackHole.radius, 0, Math.PI * 2);
    ctx.fill();
  }

  private drawEntities(ctx: CanvasRenderingContext2D, state: NativeRenderState): void {
    for (let i = 0; i < state.entities.length; i += 1) {
      const entity = state.entities[i];
      if (!entity.alive) {
        continue;
      }
      const faction = factionInfoForOptions(state.options, entity.type);
      const isTenRage = state.rageType === entity.type && state.rageUntil > state.lastTime;
      const scale = isTenRage ? 1.2 : entity.rageUntil > state.lastTime ? 1.12 : 1;
      if (isTenRage) {
        this.drawRageTrail(ctx, entity.x, entity.y, entity.vx, entity.vy, entity.radius);
      }
      ctx.beginPath();
      ctx.fillStyle = faction.color;
      ctx.strokeStyle = 'rgba(255,255,255,0.82)';
      ctx.lineWidth = 2;
      ctx.arc(entity.x, entity.y, entity.radius * scale, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      if (entity.shield > 0) {
        ctx.beginPath();
        ctx.strokeStyle = '#f0b429';
        ctx.lineWidth = 3;
        ctx.arc(entity.x, entity.y, entity.radius * scale + 5, 0, Math.PI * 2);
        ctx.stroke();
      }
      if (state.bountyActive && state.bountyLeader === entity.type) {
        ctx.beginPath();
        ctx.strokeStyle = 'rgba(240,180,41,0.86)';
        ctx.lineWidth = 3;
        ctx.arc(entity.x, entity.y, entity.radius * scale + 10 + Math.sin(state.lastTime / 180 + entity.id) * 2, 0, Math.PI * 2);
        ctx.stroke();
      }
      ctx.fillStyle = '#ffffff';
      ctx.font = `${Math.max(13, entity.radius * 1.18)}vp sans-serif`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(faction.emoji, entity.x, entity.y + 1);
    }
  }

  private drawRageTrail(ctx: CanvasRenderingContext2D, x: number, y: number, vx: number, vy: number, radius: number): void {
    const speed = Math.max(1, Math.sqrt(vx * vx + vy * vy));
    const nx = vx / speed;
    const ny = vy / speed;
    for (let i = 1; i <= 3; i += 1) {
      ctx.beginPath();
      ctx.fillStyle = i === 1 ? 'rgba(155,92,255,0.45)' : i === 2 ? 'rgba(155,92,255,0.28)' : 'rgba(155,92,255,0.16)';
      ctx.arc(x - nx * i * 9, y - ny * i * 9, radius * (1.08 - i * 0.18), 0, Math.PI * 2);
      ctx.fill();
    }
  }

  private drawTraitorMarks(ctx: CanvasRenderingContext2D, state: NativeRenderState): void {
    for (let i = 0; i < state.traitorMarks.length; i += 1) {
      const mark = state.traitorMarks[i];
      const entity = state.entities.find((item) => item.id === mark.entityId);
      if (entity === undefined || !entity.alive) {
        continue;
      }
      const progress = this.traitorProgress(mark, state.lastTime);
      ctx.beginPath();
      ctx.strokeStyle = '#9b5cff';
      ctx.lineWidth = 4;
      ctx.arc(entity.x, entity.y, entity.radius + 9, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * progress);
      ctx.stroke();
    }
  }

  private traitorProgress(mark: TraitorMark, now: number): number {
    return clamp((now - mark.startAt) / TRAITOR_DELAY, 0, 1);
  }

  private drawHand(ctx: CanvasRenderingContext2D, state: NativeRenderState): void {
    if (!state.handActive || !state.options.godHand) {
      return;
    }
    ctx.beginPath();
    ctx.strokeStyle = state.handPull ? 'rgba(78,110,219,0.5)' : 'rgba(32,164,243,0.5)';
    ctx.lineWidth = 3;
    ctx.arc(state.handX, state.handY, 130, 0, Math.PI * 2);
    ctx.stroke();
  }
}
