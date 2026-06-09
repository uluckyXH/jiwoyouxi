import { Entity, NativeGameOptions } from './GameTypes';
import { factionEmoji, factionLabel } from './ThemeConfig';

export interface BattleReportPoint {
  timeSec: number;
  counts: number[];
  label: string;
}

export interface NativeBattleReport {
  title: string;
  textLines: string[];
  mvpLines: string[];
  points: BattleReportPoint[];
}

interface InitialEntity {
  id: number;
  type: number;
}

interface ImpactRecord {
  id: number;
  type: number;
  count: number;
}

export class BattleReportRecorder {
  private options: NativeGameOptions | null = null;
  private startAt: number = 0;
  private startCounts: number[] = [0, 0, 0];
  private finalCounts: number[] = [0, 0, 0];
  private finalWinner: number = -1;
  private finalReason: string = '';
  private durationSec: number = 0;
  private initialEntities: InitialEntity[] = [];
  private aliveIds: number[] = [];
  private convertedIds: number[] = [];
  private impacts: ImpactRecord[] = [];
  private eliminated: boolean[] = [false, false, false];
  private notableEvents: string[] = [];
  private points: BattleReportPoint[] = [];
  private lastPointAt: number = 0;

  reset(options: NativeGameOptions, now: number, entities: Entity[], counts: number[]): void {
    this.options = options;
    this.startAt = now;
    this.startCounts = [counts[0], counts[1], counts[2]];
    this.finalCounts = [counts[0], counts[1], counts[2]];
    this.finalWinner = -1;
    this.finalReason = '';
    this.durationSec = 0;
    this.initialEntities = [];
    this.aliveIds = [];
    this.convertedIds = [];
    this.impacts = [];
    this.eliminated = [false, false, false];
    this.notableEvents = [];
    this.points = [];
    this.lastPointAt = 0;
    for (let i = 0; i < entities.length; i += 1) {
      this.initialEntities.push({ id: entities[i].id, type: entities[i].type });
    }
    this.recordPoint(now, counts, '开局');
  }

  recordTimeline(now: number, counts: number[]): void {
    if (now - this.lastPointAt >= 1000) {
      this.recordPoint(now, counts, '');
    }
    this.recordEliminations(now, counts);
  }

  recordEvent(text: string, now: number, counts: number[], important: boolean): void {
    if (important) {
      this.notableEvents.push(`${this.elapsed(now)}s，${text}`);
      this.recordPoint(now, counts, text);
    }
  }

  recordConversion(winnerId: number, winnerType: number, loserId: number, now: number, counts: number[]): void {
    if (this.convertedIds.indexOf(loserId) < 0) {
      this.convertedIds.push(loserId);
    }
    let found = false;
    for (let i = 0; i < this.impacts.length; i += 1) {
      if (this.impacts[i].id === winnerId) {
        this.impacts[i].count += 1;
        this.impacts[i].type = winnerType;
        found = true;
        break;
      }
    }
    if (!found) {
      this.impacts.push({ id: winnerId, type: winnerType, count: 1 });
    }
    this.recordTimeline(now, counts);
  }

  recordFinish(winner: number, reason: string, now: number, counts: number[], entities: Entity[]): void {
    this.finalWinner = winner;
    this.finalReason = reason;
    this.finalCounts = [counts[0], counts[1], counts[2]];
    this.durationSec = this.elapsed(now);
    this.aliveIds = [];
    for (let i = 0; i < entities.length; i += 1) {
      if (entities[i].alive) {
        this.aliveIds.push(entities[i].id);
      }
    }
    this.recordPoint(now, counts, '结算');
  }

  summary(): NativeBattleReport {
    const options = this.options;
    if (options === null) {
      return {
        title: '本局战报',
        textLines: ['还没有完成对局。'],
        mvpLines: ['暂无数据。'],
        points: []
      };
    }

    const title = this.finalWinner >= 0
      ? `${factionEmoji(options, this.finalWinner)} ${factionLabel(options, this.finalWinner)} 战报`
      : '本局战报';
    const mode = options.deathmatch ? '死斗模式' : `${options.durationSec}s 限时`;
    const textLines: string[] = [];
    textLines.push(`本局 ${mode}，${this.lineupText(options, this.startCounts)}。`);
    const highlights = this.notableEvents.slice(0, 5);
    for (let i = 0; i < highlights.length; i += 1) {
      textLines.push(highlights[i]);
    }
    if (this.finalWinner >= 0) {
      textLines.push(`最终 ${factionEmoji(options, this.finalWinner)} ${factionLabel(options, this.finalWinner)} 获胜，耗时 ${this.durationSec.toFixed(1)}s，原因：${this.finalReason}。`);
    } else {
      textLines.push(`最终无人获胜，耗时 ${this.durationSec.toFixed(1)}s。`);
    }

    return {
      title: title,
      textLines: textLines,
      mvpLines: this.mvpLines(options),
      points: this.points
    };
  }

  private recordEliminations(now: number, counts: number[]): void {
    const options = this.options;
    if (options === null) {
      return;
    }
    for (let type = 0; type < 3; type += 1) {
      if (counts[type] === 0 && !this.eliminated[type]) {
        this.eliminated[type] = true;
        this.notableEvents.push(`${this.elapsed(now)}s，${factionEmoji(options, type)} ${factionLabel(options, type)} 阵营归零。`);
        this.recordPoint(now, counts, `${factionLabel(options, type)}归零`);
      }
    }
  }

  private recordPoint(now: number, counts: number[], label: string): void {
    this.lastPointAt = now;
    this.points.push({
      timeSec: this.elapsed(now),
      counts: [counts[0], counts[1], counts[2]],
      label: label
    });
    if (this.points.length > 80) {
      this.points.shift();
    }
  }

  private mvpLines(options: NativeGameOptions): string[] {
    const lines: string[] = [];
    const king = this.conversionKing();
    if (king === null) {
      lines.push('转化王：本局没有有效转化。');
    } else {
      lines.push(`转化王：${factionEmoji(options, king.type)} #${king.id}，转化 ${king.count} 次。`);
    }

    const survivor = this.survivorLine(options);
    lines.push(survivor);

    if (this.finalWinner >= 0) {
      const start = this.startCounts[this.finalWinner];
      const finalCount = this.finalCounts[this.finalWinner];
      if (start < Math.max(this.startCounts[0], this.startCounts[1], this.startCounts[2]) && finalCount > start) {
        lines.push(`逆转：${factionEmoji(options, this.finalWinner)} 从 ${start} 人打到 ${finalCount} 人。`);
      }
    }
    return lines;
  }

  private conversionKing(): ImpactRecord | null {
    if (this.impacts.length === 0) {
      return null;
    }
    let best = this.impacts[0];
    for (let i = 1; i < this.impacts.length; i += 1) {
      if (this.impacts[i].count > best.count) {
        best = this.impacts[i];
      }
    }
    return best;
  }

  private survivorLine(options: NativeGameOptions): string {
    const survivorCounts = [0, 0, 0];
    let total = 0;
    for (let i = 0; i < this.initialEntities.length; i += 1) {
      const item = this.initialEntities[i];
      if (this.convertedIds.indexOf(item.id) >= 0) {
        continue;
      }
      if (this.aliveIds.length > 0 && this.aliveIds.indexOf(item.id) < 0) {
        continue;
      }
      survivorCounts[item.type] += 1;
      total += 1;
    }
    if (total <= 0) {
      return '全程幸存：无人从开局活到最后。';
    }
    let type = 0;
    for (let i = 1; i < 3; i += 1) {
      if (survivorCounts[i] > survivorCounts[type]) {
        type = i;
      }
    }
    return `全程幸存：${total} 个，最多来自 ${factionEmoji(options, type)} ${factionLabel(options, type)}。`;
  }

  private lineupText(options: NativeGameOptions, counts: number[]): string {
    return `${factionEmoji(options, 0)}×${counts[0]} vs ${factionEmoji(options, 1)}×${counts[1]} vs ${factionEmoji(options, 2)}×${counts[2]}`;
  }

  private elapsed(now: number): number {
    return Number(((now - this.startAt) / 1000).toFixed(1));
  }
}
