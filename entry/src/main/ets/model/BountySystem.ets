import { Entity, GameEventKind, NativeGameOptions, TYPE_COUNT } from './GameTypes';
import { factionEmoji } from './ThemeConfig';

type EventSink = (text: string, now: number, kind: GameEventKind) => void;

const BOUNTY_SHARE: number = 0.54;
const BOUNTY_LEAD: number = 6;

export class BountySystem {
  private enabled: boolean = false;
  private activeState: boolean = false;
  private leaderType: number = -1;
  private lastLeaderType: number = -1;

  reset(enabled: boolean): void {
    this.enabled = enabled;
    this.activeState = false;
    this.leaderType = -1;
    this.lastLeaderType = -1;
  }

  active(): boolean {
    return this.activeState;
  }

  leader(): number {
    return this.leaderType;
  }

  isLeader(type: number): boolean {
    return this.activeState && this.leaderType === type;
  }

  update(now: number, roundStart: number, counts: number[], options: NativeGameOptions, addEvent: EventSink): void {
    if (!this.enabled || !options.bounty) {
      this.activeState = false;
      this.leaderType = -1;
      return;
    }
    const total = counts[0] + counts[1] + counts[2];
    if (total < 12) {
      this.activeState = false;
      this.leaderType = -1;
      return;
    }
    let leader = 0;
    let second = 1;
    for (let type = 0; type < TYPE_COUNT; type += 1) {
      if (counts[type] > counts[leader]) {
        second = leader;
        leader = type;
      } else if (type !== leader && counts[type] > counts[second]) {
        second = type;
      }
    }
    const lead = counts[leader] - counts[second];
    const shouldActivate = counts[leader] / total >= BOUNTY_SHARE && lead >= BOUNTY_LEAD;
    if (!shouldActivate) {
      if (this.activeState && now - roundStart > 1400) {
        addEvent('悬赏解除', now, GameEventKind.PowerUp);
      }
      this.activeState = false;
      this.leaderType = -1;
      return;
    }
    this.activeState = true;
    this.leaderType = leader;
    if (this.lastLeaderType !== leader) {
      this.lastLeaderType = leader;
      addEvent(`${factionEmoji(options, leader)} 成为悬赏头名`, now, GameEventKind.PowerUp);
    }
  }

  applyReward(entity: Entity, now: number, options: NativeGameOptions, addEvent: EventSink): void {
    entity.shield = Math.max(entity.shield, 1);
    entity.rageUntil = Math.max(entity.rageUntil, now + 4600);
    entity.vx *= 1.22;
    entity.vy *= 1.22;
    addEvent(`${factionEmoji(options, entity.type)} 兑现悬赏`, now, GameEventKind.PowerUp);
  }
}
