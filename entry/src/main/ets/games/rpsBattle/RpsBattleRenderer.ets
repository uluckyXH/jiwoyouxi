import { RpsBattleTheme } from './RpsBattleTheme';
import {
  RpsBattleBlackHoleState,
  RpsBattleControlZone,
  RpsBattleEntity,
  RpsBattleFaction,
  RpsBattleFactionInfo,
  RpsBattleThemeKey
} from './RpsBattleTypes';
import { rpsBattleThemeFactionInfo } from './RpsBattleThemeConfig';
import { RPS_BATTLE_CONTROL_ZONE_MAX_SCORE } from './RpsBattleZoneSystem';

export class RpsBattleRenderer {
  draw(ctx: CanvasRenderingContext2D, width: number, height: number, entities: RpsBattleEntity[],
    elapsedSec: number, themeKey: RpsBattleThemeKey = 'rps',
    controlZone: RpsBattleControlZone | null = null,
    blackHole: RpsBattleBlackHoleState | null = null): void {
    const canvasWidth = Math.max(1, width);
    const canvasHeight = Math.max(1, height);
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);
    this.drawArena(ctx, canvasWidth, canvasHeight);
    this.drawControlZone(ctx, controlZone, themeKey);
    this.drawBlackHole(ctx, blackHole, elapsedSec);
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

  private drawBlackHole(ctx: CanvasRenderingContext2D, blackHole: RpsBattleBlackHoleState | null,
    elapsedSec: number): void {
    if (blackHole === null || !blackHole.active) {
      return;
    }
    const pulse = 0.5 + Math.sin(elapsedSec * 5.2) * 0.5;
    ctx.beginPath();
    ctx.strokeStyle = 'rgba(75,48,110,0.22)';
    ctx.fillStyle = 'rgba(75,48,110,0.05)';
    ctx.lineWidth = 2;
    ctx.arc(blackHole.x, blackHole.y, blackHole.reach, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    ctx.beginPath();
    ctx.strokeStyle = `rgba(95,63,138,${0.28 + pulse * 0.18})`;
    ctx.lineWidth = 3;
    ctx.arc(blackHole.x, blackHole.y, blackHole.radius + 10 + pulse * 7, 0, Math.PI * 2);
    ctx.stroke();

    const gradient = ctx.createRadialGradient(
      blackHole.x,
      blackHole.y,
      Math.max(1, blackHole.radius * 0.2),
      blackHole.x,
      blackHole.y,
      blackHole.radius
    );
    gradient.addColorStop(0, 'rgba(24,18,38,0.96)');
    gradient.addColorStop(0.68, 'rgba(72,42,112,0.88)');
    gradient.addColorStop(1, 'rgba(139,92,246,0.36)');
    ctx.beginPath();
    ctx.fillStyle = gradient;
    ctx.strokeStyle = 'rgba(255,255,255,0.42)';
    ctx.lineWidth = 2;
    ctx.arc(blackHole.x, blackHole.y, blackHole.radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = 'rgba(255,255,255,0.78)';
    ctx.font = `700 ${Math.max(12, blackHole.radius * 0.52)}vp sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('●', blackHole.x, blackHole.y + 1);
  }

  private drawControlZone(ctx: CanvasRenderingContext2D, zone: RpsBattleControlZone | null,
    themeKey: RpsBattleThemeKey): void {
    if (zone === null) {
      return;
    }
    const hasOwner = zone.owner !== '';
    const ownerColor = this.factionColor(themeKey, zone.owner, '#7f735f');
    const edgeColor = this.factionColor(themeKey, zone.capturingFaction, 'rgba(86,55,35,0.34)');
    const progress = Math.max(0, Math.min(1, zone.score / RPS_BATTLE_CONTROL_ZONE_MAX_SCORE));

    ctx.beginPath();
    ctx.fillStyle = hasOwner ? this.softZoneFill(ownerColor) : 'rgba(255,255,255,0.44)';
    ctx.strokeStyle = edgeColor;
    ctx.lineWidth = 3;
    ctx.arc(zone.x, zone.y, zone.radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    ctx.beginPath();
    ctx.strokeStyle = 'rgba(255,255,255,0.74)';
    ctx.lineWidth = 7;
    ctx.arc(zone.x, zone.y, zone.radius + 5, 0, Math.PI * 2);
    ctx.stroke();

    if (progress > 0) {
      ctx.beginPath();
      ctx.strokeStyle = ownerColor;
      ctx.lineWidth = 7;
      ctx.lineCap = 'round';
      ctx.arc(zone.x, zone.y, zone.radius + 5, -Math.PI * 0.5, -Math.PI * 0.5 + Math.PI * 2 * progress);
      ctx.stroke();
      ctx.lineCap = 'butt';
    }

    ctx.fillStyle = ownerColor;
    ctx.font = '700 18vp sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(`${Math.floor(zone.score)}`, zone.x, zone.y);
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

  private softZoneFill(color: string): string {
    if (color.length === 7 && color.charAt(0) === '#') {
      const red = Number.parseInt(color.substring(1, 3), 16);
      const green = Number.parseInt(color.substring(3, 5), 16);
      const blue = Number.parseInt(color.substring(5, 7), 16);
      return `rgba(${red},${green},${blue},0.13)`;
    }
    return 'rgba(255,255,255,0.44)';
  }

  private factionColor(themeKey: RpsBattleThemeKey, faction: RpsBattleFaction | '', fallback: string): string {
    if (faction === '') {
      return fallback;
    }
    return rpsBattleThemeFactionInfo(themeKey, faction).color;
  }
}
