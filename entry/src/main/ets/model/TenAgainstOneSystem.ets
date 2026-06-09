import { beats, Entity, GameEventKind, NativeGameOptions } from './GameTypes';
import { aliveTypeCount, aliveTypeList } from './GameRules';
import { factionEmoji, factionLabel } from './ThemeConfig';

type EventSink = (text: string, now: number, kind: GameEventKind) => void;
type FinishSink = (winner: number, now: number) => void;

const TRIGGER_CHECK_INTERVAL: number = 1000;
const INTRO_PAUSE: number = 1500;
const OVERLAY_DURATION: number = 1900;
const RAGE_DURATION: number = 10000;

export class TenAgainstOneSystem {
  private enabled: boolean = false;
  private triggered: boolean = false;
  private active: boolean = false;
  private underdog: number = -1;
  private majority: number = -1;
  private startAt: number = 0;
  private endAt: number = 0;
  private pauseUntil: number = 0;
  private overlayUntil: number = 0;
  private nextCheckAt: number = 0;
  private emojis: string[] = ['🪨', '✂️', '✋🏻'];
  private labels: string[] = ['石头', '剪刀', '布'];

  reset(enabled: boolean, now: number, options?: NativeGameOptions): void {
    this.enabled = enabled;
    this.triggered = false;
    this.active = false;
    this.underdog = -1;
    this.majority = -1;
    this.startAt = 0;
    this.endAt = 0;
    this.pauseUntil = 0;
    this.overlayUntil = 0;
    this.nextCheckAt = now + TRIGGER_CHECK_INTERVAL;
    if (options !== undefined) {
      this.emojis = [factionEmoji(options, 0), factionEmoji(options, 1), factionEmoji(options, 2)];
      this.labels = [factionLabel(options, 0), factionLabel(options, 1), factionLabel(options, 2)];
    }
  }

  paused(now: number): boolean {
    return this.active && now < this.pauseUntil;
  }

  boost(type: number, now: number): number {
    return this.rageLive(now) && type === this.underdog ? 1.5 : 1;
  }

  rageType(now: number): number {
    return this.rageLive(now) ? this.underdog : -1;
  }

  rageUntil(): number {
    return this.endAt;
  }

  rageTimeLeftSec(now: number): number {
    return this.rageLive(now) ? Math.max(0, (this.endAt - now) / 1000) : 0;
  }

  rageProgress(now: number): number {
    if (!this.rageLive(now)) {
      return 0;
    }
    return Math.max(0, Math.min(1, (this.endAt - now) / RAGE_DURATION));
  }

  overlayVisible(now: number): boolean {
    return this.active && now < this.overlayUntil;
  }

  overlayText(): string {
    if (this.underdog < 0) {
      return '触发了「我要打十个」！';
    }
    return `${this.emojis[this.underdog]} 触发了「我要打十个」！`;
  }

  overlaySubText(now: number): string {
    if (this.paused(now)) {
      return '克制关系短暂反转，准备反杀';
    }
    return '10 秒内只杀不转化';
  }

  tryTrigger(now: number, counts: number[], entities: Entity[], addEvent: EventSink): void {
    if (!this.enabled || this.triggered || this.active || now < this.nextCheckAt) {
      return;
    }
    this.nextCheckAt = now + TRIGGER_CHECK_INTERVAL;
    if (aliveTypeCount(counts) !== 2) {
      return;
    }
    const types = aliveTypeList(counts);
    const first = types[0];
    const second = types[1];
    const underdog = counts[first] <= counts[second] ? first : second;
    const majority = underdog === first ? second : first;
    if (counts[underdog] <= 0 || counts[majority] < counts[underdog] * 10 || !beats(majority, underdog)) {
      return;
    }
    if (Math.random() >= 0.1) {
      return;
    }
    this.trigger(now, underdog, majority, entities, addEvent);
  }

  resolveCollision(a: Entity, b: Entity, now: number, addEvent: EventSink): boolean {
    if (!this.rageLive(now)) {
      return false;
    }
    if (a.type === this.underdog && b.type === this.majority) {
      this.killMajority(b, now, addEvent);
      return true;
    }
    if (b.type === this.underdog && a.type === this.majority) {
      this.killMajority(a, now, addEvent);
      return true;
    }
    return false;
  }

  updateOutcome(now: number, counts: number[], finish: FinishSink, addEvent: EventSink): void {
    if (!this.active || this.underdog < 0 || this.majority < 0) {
      return;
    }
    if (counts[this.majority] <= 0 && counts[this.underdog] > 0) {
      finish(this.underdog, now);
      addEvent('以弱胜强！', now, GameEventKind.Win);
      this.active = false;
      return;
    }
    if (now >= this.endAt) {
      this.active = false;
      addEvent('「我要打十个」结束，克制关系恢复', now, GameEventKind.Warning);
    }
  }

  private rageLive(now: number): boolean {
    return this.active && now >= this.startAt && now < this.endAt;
  }

  private trigger(now: number, underdog: number, majority: number, entities: Entity[], addEvent: EventSink): void {
    this.enabled = true;
    this.triggered = true;
    this.active = true;
    this.underdog = underdog;
    this.majority = majority;
    this.pauseUntil = now + INTRO_PAUSE;
    this.overlayUntil = now + OVERLAY_DURATION;
    this.startAt = this.pauseUntil;
    this.endAt = this.startAt + RAGE_DURATION;
    for (let i = 0; i < entities.length; i += 1) {
      const entity = entities[i];
      if (entity.alive && entity.type === underdog) {
        entity.rageUntil = this.endAt;
      }
    }
    addEvent(`${this.emojis[underdog]} 触发了「我要打十个」`, now, GameEventKind.Warning);
  }

  private killMajority(entity: Entity, now: number, addEvent: EventSink): void {
    entity.alive = false;
    addEvent(`${this.labels[this.underdog]} 暴走反杀 ${this.labels[this.majority]}`, now, GameEventKind.Attack);
  }
}
