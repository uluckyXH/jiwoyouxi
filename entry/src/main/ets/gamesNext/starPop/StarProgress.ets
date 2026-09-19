import { AchievementEvent } from '../../shell/AchievementModule';
import { StarEngine } from './StarEngine';

export interface StarProgressPorts {
  save: (raw: string) => Promise<boolean>;
  report: (event: AchievementEvent) => Promise<boolean>;
  record: (score: number) => void;
}

/** Persist before publishing; acknowledgements save fresh state, never an older board. */
export class StarProgress {
  private queue: Promise<boolean> = Promise.resolve(true);
  private engine: StarEngine;
  private ports: StarProgressPorts;
  constructor(engine: StarEngine, ports: StarProgressPorts) { this.engine = engine; this.ports = ports; }
  flush(): Promise<boolean> {
    this.queue = this.queue.then(() => this.commit()).catch(() => false);
    return this.queue;
  }
  private async commit(): Promise<boolean> {
    const saved = this.engine.snapshot();
    if (!await this.ports.save(JSON.stringify(saved))) return false;
    const acknowledged: string[] = [];
    let allReported = true;
    for (let i = 0; i < saved.pending.length; i++) {
      const e = saved.pending[i];
      if (!await this.ports.report(e)) { allReported = false; break; }
      acknowledged.push(e.eventId);
    }
    if (acknowledged.length === 0) return allReported;
    const latest = this.engine.snapshot();
    latest.pending = latest.pending.filter((e: AchievementEvent): boolean => !acknowledged.includes(e.eventId));
    if (!await this.ports.save(JSON.stringify(latest))) return false;
    this.engine.pending = this.engine.pending.filter((e: AchievementEvent): boolean => !acknowledged.includes(e.eventId));
    saved.pending.forEach((e: AchievementEvent) => {
      if (e.type === 'sessionEnd' && acknowledged.includes(e.eventId)) {
        const score = e.facts.find((f): boolean => f.key === 'score');
        if (score !== undefined) this.ports.record(score.value);
      }
    });
    return allReported;
  }
}
