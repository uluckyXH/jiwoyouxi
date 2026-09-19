import { AchievementEvent } from '../../shell/AchievementModule';
import { TenEngine } from './TenEngine';
import { TEN_GAME_ID, TenSave } from './TenModel';

export function tenMilestone(saved: TenSave): AchievementEvent | undefined {
  if (saved.resumeRound !== undefined || saved.profile.totalGroups === 0) return undefined;
  return { gameId: TEN_GAME_ID, type: 'milestone', isOfficial: true, occurredAt: Date.now(),
    sessionId: saved.round.id, eventId: 'ten:progress:' + saved.profile.totalGroups + ':' + saved.profile.totalWins,
    facts: [{ key: 'totalGroups', value: saved.profile.totalGroups }, { key: 'totalWins', value: saved.profile.totalWins }] };
}
export function tenSettlement(saved: TenSave): AchievementEvent | undefined {
  if (saved.resumeRound !== undefined || saved.round.phase !== 'complete' || saved.round.reported) return undefined;
  return { gameId: TEN_GAME_ID, type: 'sessionEnd', isOfficial: true, occurredAt: Date.now(),
    sessionId: saved.round.id, eventId: saved.round.id + ':complete',
    facts: [{ key: 'totalGroups', value: saved.profile.totalGroups }, { key: 'totalWins', value: saved.profile.totalWins },
      { key: 'stage', value: saved.round.stage }, { key: 'won', value: 1 }] };
}
export interface TenProgressPorts {
  save: (raw: string) => Promise<boolean>;
  report: (event: AchievementEvent) => Promise<boolean>;
  record: (wins: number) => void;
}
export class TenProgress {
  private queue: Promise<boolean> = Promise.resolve(true);
  private engine: TenEngine;
  private ports: TenProgressPorts;
  private recordedId: string = '';
  constructor(engine: TenEngine, ports: TenProgressPorts) { this.engine = engine; this.ports = ports; }
  flush(): Promise<boolean> {
    const saved = this.engine.snapshot();
    this.queue = this.queue.then(() => this.commit(saved)).catch(() => false);
    return this.queue;
  }
  private async commit(saved: TenSave): Promise<boolean> {
    if (!await this.ports.save(JSON.stringify(saved))) return false;
    const milestone = tenMilestone(saved);
    if (milestone !== undefined && !await this.ports.report(milestone)) return false;
    const settlement = tenSettlement(saved);
    if (settlement !== undefined) {
      if (!await this.ports.report(settlement)) return false;
      saved.round.reported = true;
      if (!await this.ports.save(JSON.stringify(saved))) return false;
      if (this.engine.round.id === saved.round.id) this.engine.round.reported = true;
      if (this.recordedId !== saved.round.id) {
        this.recordedId = saved.round.id;
        this.ports.record(saved.profile.totalWins);
      }
    }
    return true;
  }
}
