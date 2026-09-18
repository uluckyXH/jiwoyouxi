import { hilog } from '@kit.PerformanceAnalysisKit';
import { MarketEngine } from './MarketEngine';
import { MarketBody, MarketMerge, MARKET_FLOOR, MARKET_FRUITS, MARKET_LINE, marketFruitPath } from './MarketModel';
import { MarketPalette } from './MarketPalette';

/** Use ArkUI's default vp coordinates for both the SVG source and the canvas. */
export function createMarketCanvas(): CanvasRenderingContext2D {
  return new CanvasRenderingContext2D(new RenderingContextSettings(true));
}

export class MarketRenderer {
  private images: Array<ImageBitmap | undefined> = [];
  private prepared: boolean = false;
  private effects: MarketMerge[] = [];
  private disposed: boolean = false;
  private lastEngine: MarketEngine | undefined = undefined;
  private lastVersion: number = -1;
  private lastWidth: number = 0;
  private lastHeight: number = 0;
  private lastDark: boolean = false;
  private lastAiming: boolean = false;
  private lastReady: boolean = false;
  private lastWarning: number = -1;
  private awaitingImages: boolean = true;

  /** Canvas has its own SVG loader. Artwork must never gate gameplay startup. */
  prepare(): void {
    this.lastVersion = -1; // Canvas can be recreated during a fold/rotation.
    if (this.prepared || this.disposed) return;
    this.prepared = true;
    for (let i = 0; i < MARKET_FRUITS.length; i += 1) {
      try {
        this.images.push(new ImageBitmap(`resource://RAWFILE/${marketFruitPath(i)}`));
      } catch (error) {
        this.images.push(undefined);
        hilog.warn(0x0000, 'FruitMarketPerf', '%{public}s',
          `[绘制回退] SVG加载失败 等级=${i} ${JSON.stringify(error)}`);
      }
    }
  }

  add(events: MarketMerge[]): void { this.effects = this.effects.concat(events).slice(-20); }
  reset(): void { this.effects = []; this.lastVersion = -1; }

  draw(ctx: CanvasRenderingContext2D, engine: MarketEngine, width: number, height: number,
    dark: boolean, aiming: boolean): boolean {
    if (this.disposed || width <= 0 || height <= 0) return false;
    const ready = engine.canDrop();
    const warning = engine.round.overflow > 0 ? Math.max(1, Math.ceil(3 - engine.round.overflow)) : 0;
    if (this.awaitingImages && this.prepared) {
      this.awaitingImages = this.images.some((image: ImageBitmap | undefined): boolean =>
        image !== undefined && (image.width <= 0 || image.height <= 0));
      // Paint once when the last pending SVG becomes available.
      if (!this.awaitingImages) this.lastVersion = -1;
    }
    if (engine.sleeping && !this.awaitingImages && this.effects.length === 0 && this.lastEngine === engine &&
      this.lastVersion === engine.visualVersion && this.lastWidth === width && this.lastHeight === height &&
      this.lastDark === dark && this.lastAiming === aiming && this.lastReady === ready && this.lastWarning === warning) {
      return false;
    }
    this.lastEngine = engine;
    this.lastVersion = engine.visualVersion;
    this.lastWidth = width;
    this.lastHeight = height;
    this.lastDark = dark;
    this.lastAiming = aiming;
    this.lastReady = ready;
    this.lastWarning = warning;
    ctx.clearRect(0, 0, width, height);
    ctx.save();
    ctx.scale(width / 360, height / 520);
    const round = engine.round;
    const danger = round.overflow > 0;
    ctx.strokeStyle = danger ? MarketPalette.danger(dark) : (dark ? '#827154' : '#cbbb96');
    ctx.lineWidth = danger ? 1.8 : 1;
    ctx.setLineDash([4, 5]);
    ctx.beginPath(); ctx.moveTo(27, MARKET_LINE); ctx.lineTo(333, MARKET_LINE); ctx.stroke();
    ctx.setLineDash([]);
    if (danger) {
      ctx.fillStyle = MarketPalette.danger(dark);
      ctx.font = 'bold 11px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(`快合成消掉高处水果 · ${Math.max(1, Math.ceil(3 - round.overflow))} 秒`, 180, MARKET_LINE - 9);
    }
    if (engine.canDrop() && !round.ended) {
      const radius = MARKET_FRUITS[round.current].radius;
      const targetY = engine.landingY();
      ctx.globalAlpha = aiming ? 0.65 : 0.25;
      ctx.strokeStyle = MarketPalette.accent(dark);
      ctx.setLineDash([3, 6]);
      ctx.beginPath(); ctx.moveTo(round.aim, 65 + radius); ctx.lineTo(round.aim, targetY); ctx.stroke();
      ctx.setLineDash([]);
      ctx.beginPath(); ctx.ellipse(round.aim, Math.min(MARKET_FLOOR - 2, targetY + radius),
        radius * 0.75, 3, 0, 0, Math.PI * 2); ctx.stroke();
      ctx.globalAlpha = 1;
      this.fruit(ctx, round.current, round.aim, 59, radius, 0);
    }
    round.bodies.forEach((body: MarketBody) => {
      const radius = MARKET_FRUITS[body.level].radius;
      if (body.y + radius > MARKET_FLOOR - 12) {
        ctx.fillStyle = dark ? '#00000028' : '#76683f15';
        ctx.beginPath(); ctx.ellipse(body.x, MARKET_FLOOR - 1, radius * 0.75, 3, 0, 0, Math.PI * 2); ctx.fill();
      }
      const age = round.time - body.born;
      const pulse = age < 0.22 ? 1 + Math.sin(age / 0.22 * Math.PI) * 0.045 : 1;
      this.fruit(ctx, body.level, body.x, body.y, radius * pulse, body.angle);
    });
    if (this.effects.length > 0) {
      this.effects = this.effects.filter((effect: MarketMerge): boolean => round.time - effect.time < 0.65);
    }
    this.effects.forEach((effect: MarketMerge) => this.effect(ctx, effect, round.time, dark));
    ctx.restore();
    return true;
  }

  release(): void {
    this.disposed = true;
    this.images.forEach((item: ImageBitmap | undefined) => { if (item !== undefined) item.close(); });
    this.images = [];
    this.effects = [];
  }

  private fruit(ctx: CanvasRenderingContext2D, level: number, x: number, y: number,
    radius: number, angle: number): void {
    const bitmap = this.images[level];
    // Each SVG has an 84-unit circular body, with leaves outside the collider.
    const size = radius * 200 / 84;
    ctx.save();
    ctx.translate(x, y); ctx.rotate(angle);
    let painted = false;
    if (bitmap !== undefined && bitmap.width > 0 && bitmap.height > 0) {
      try {
        ctx.drawImage(bitmap, -size / 2, -size * 103 / 200, size, size);
        painted = true;
      } catch (error) {
        bitmap.close();
        this.images[level] = undefined;
        hilog.warn(0x0000, 'FruitMarketPerf', '%{public}s',
          `[绘制回退] SVG绘制失败，改用可玩数字水果 等级=${level} ${JSON.stringify(error)}`);
      }
    }
    if (!painted) this.fallbackFruit(ctx, level, radius);
    ctx.restore();
  }

  /** Visible, level-labelled fruit keeps a round playable if a device rejects an SVG. */
  private fallbackFruit(ctx: CanvasRenderingContext2D, level: number, radius: number): void {
    ctx.fillStyle = MARKET_FRUITS[level].color;
    ctx.strokeStyle = '#493627';
    ctx.lineWidth = Math.max(1, radius * 0.025);
    ctx.beginPath(); ctx.arc(0, 0, radius, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
    ctx.fillStyle = '#ffffff55';
    ctx.beginPath(); ctx.ellipse(-radius * 0.28, -radius * 0.4, radius * 0.25, radius * 0.12,
      -0.5, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#493627';
    ctx.font = `bold ${Math.max(10, radius * 0.7)}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(`${level + 1}`, 0, radius * 0.12);
  }

  private effect(ctx: CanvasRenderingContext2D, effect: MarketMerge, now: number, dark: boolean): void {
    const age = (now - effect.time) / 0.65;
    const radius = MARKET_FRUITS[effect.level].radius;
    ctx.save();
    ctx.globalAlpha = Math.max(0, 1 - age);
    ctx.strokeStyle = MARKET_FRUITS[effect.level].color;
    ctx.lineWidth = 2 * (1 - age);
    ctx.beginPath(); ctx.arc(effect.x, effect.y, radius * (0.7 + age * 0.7), 0, Math.PI * 2); ctx.stroke();
    for (let i = 0; i < 8; i += 1) {
      const angle = i * Math.PI / 4;
      const distance = radius * (0.5 + age) + 8;
      const x = effect.x + Math.cos(angle) * distance;
      const y = effect.y + Math.sin(angle) * distance + age * age * 20;
      ctx.fillStyle = i % 2 === 0 ? '#e8bc65' : MARKET_FRUITS[effect.level].color;
      ctx.beginPath(); ctx.arc(x, y, 2.5 * (1 - age), 0, Math.PI * 2); ctx.fill();
    }
    ctx.fillStyle = MarketPalette.ink(dark);
    ctx.font = 'bold 15px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(`+${effect.points}`, effect.x, effect.y - radius - 9 - age * 24);
    ctx.restore();
  }
}
