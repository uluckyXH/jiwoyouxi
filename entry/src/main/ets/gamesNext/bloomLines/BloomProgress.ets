import { AchievementEvent } from '../../shell/AchievementModule';
import { BLOOM_GAME_ID, BloomSave } from './BloomModel';
import { BloomEngine } from './BloomEngine';

export function bloomMilestone(saved: BloomSave): AchievementEvent | undefined {
  const total = saved.profile.totalCleared;
  if (total === 0) { return undefined; }
  const best = Math.max(saved.profile.bestGarden, saved.profile.bestClassic);
  return { eventId: `bloom:progress:${total}:${best}`, sessionId: saved.round.session,
    gameId: BLOOM_GAME_ID, type: 'milestone', occurredAt: Date.now(), isOfficial: true,
    facts: [{ key: 'totalCleared', value: total }, { key: 'bestScore', value: best }] };
}

export function bloomSettlement(saved: BloomSave): AchievementEvent | undefined {
  const round = saved.round;
  if (!round.ended || round.reported || round.moves === 0) { return undefined; }
  return { eventId: `${round.session}:end`, sessionId: round.session, gameId: BLOOM_GAME_ID,
    type: 'sessionEnd', occurredAt: Date.now(), isOfficial: true,
    facts: [{ key: 'totalCleared', value: saved.profile.totalCleared },
      { key: 'bestScore', value: Math.max(saved.profile.bestGarden, saved.profile.bestClassic) },
      { key: 'score', value: round.score }, { key: 'moves', value: round.moves }] };
}

export interface BloomProgressPorts {
  save: (raw: string) => Promise<boolean>;
  report: (event: AchievementEvent) => Promise<boolean>;
  record: (score: number) => void;
}

/** The same commit path is used by play, resume, retry, restart and exit. */
export class BloomProgress {
  private queue: Promise<boolean> = Promise.resolve(true);
  private engine: BloomEngine;
  private ports: BloomProgressPorts;

  constructor(engine: BloomEngine, ports: BloomProgressPorts) { this.engine = engine; this.ports = ports; }

  flush(): Promise<boolean> {
    this.queue = this.queue.then(() => this.commit()).catch(() => false);
    return this.queue;
  }

  private async commit(): Promise<boolean> {
    const saved = this.engine.snapshot();
    if (!await this.ports.save(JSON.stringify(saved))) { return false; }
    const milestone = bloomMilestone(saved);
    if (milestone !== undefined && !await this.ports.report(milestone)) { return false; }
    const settlement = bloomSettlement(saved);
    if (settlement === undefined) { return true; }
    if (!await this.ports.report(settlement)) { return false; }
    // Keep an unacknowledged round retryable if saving the acknowledgement fails.
    saved.round.reported = true;
    if (!await this.ports.save(JSON.stringify(saved))) { return false; }
    if (this.engine.round.session === saved.round.session) { this.engine.round.reported = true; }
    this.ports.record(saved.round.score);
    return true;
  }
}
