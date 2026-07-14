import { RpsBattleTheme } from './RpsBattleTheme';
import { RpsBattleEntity, RpsBattleFactionInfo, RpsBattleThemeKey } from './RpsBattleTypes';
import { rpsBattleThemeFactionInfo } from './RpsBattleThemeConfig';

export class RpsBattleRenderer {
  draw(ctx: CanvasRenderingContext2D, width: number, height: number, entities: RpsBattleEntity[],
    elapsedSec: number, themeKey: RpsBattleThemeKey = 'rps'): void {
    const canvasWidth = Math.max(1, width);
    const canvasHeight = Math.max(1, height);
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);
    this.drawArena(ctx, canvasWidth, canvasHeight);
    this.drawEntities(ctx, entities, elapsedSec, themeKey);
  }

  private drawArena(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    ctx.fillStyle = RpsBattleTheme.arenaBg;
    ctx.fillRect(0, 0, width, height);

    ctx.strokeStyle = RpsBattleTheme.arenaGrid;
    ctx.lineWidth = 1;
    const gap = 42;
    for (let x = gap; x < width; x += gap) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
      ctx.stroke();
    }
    for (let y = gap; y < height; y += gap) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
    }

    ctx.strokeStyle = RpsBattleTheme.arenaLine;
    ctx.lineWidth = 3;
    ctx.strokeRect(1.5, 1.5, width - 3, height - 3);
  }

  private drawEntities(ctx: CanvasRenderingContext2D, entities: RpsBattleEntity[], elapsedSec: number,
    themeKey: RpsBattleThemeKey): void {
    for (let i = 0; i < entities.length; i += 1) {
      const entity = entities[i];
      const faction = rpsBattleThemeFactionInfo(themeKey, entity.faction);
      this.drawEntity(ctx, entity, faction, elapsedSec);
    }
  }

  private drawEntity(ctx: CanvasRenderingContext2D, entity: RpsBattleEntity, faction: RpsBattleFactionInfo,
    elapsedSec: number): void {
    const pulseAge = Math.max(0, 1 - (elapsedSec - entity.convertedAt) / 0.42);
    const radius = entity.radius + pulseAge * 3;
    ctx.beginPath();
    ctx.fillStyle = 'rgba(55,31,18,0.18)';
    ctx.arc(entity.x + 1.5, entity.y + 4, radius * 0.96, 0, Math.PI * 2);
    ctx.fill();

    if (pulseAge > 0) {
      ctx.beginPath();
      ctx.strokeStyle = faction.color;
      ctx.globalAlpha = 0.34 * pulseAge;
      ctx.lineWidth = 4;
      ctx.arc(entity.x, entity.y, radius + 7 * (1 - pulseAge), 0, Math.PI * 2);
      ctx.stroke();
      ctx.globalAlpha = 1;
    }

    ctx.beginPath();
    ctx.fillStyle = faction.color;
    ctx.strokeStyle = 'rgba(255,255,255,0.88)';
    ctx.lineWidth = 2;
    ctx.arc(entity.x, entity.y, radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    ctx.beginPath();
    ctx.fillStyle = 'rgba(255,255,255,0.24)';
    ctx.arc(entity.x - radius * 0.28, entity.y - radius * 0.32, radius * 0.34, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = '#ffffff';
    ctx.font = `700 ${Math.max(14, radius * 1.05)}vp sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(faction.symbol, entity.x, entity.y + 1);
  }
}
