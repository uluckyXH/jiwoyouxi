import { AchievementEvent } from '../../shell/AchievementModule';
import { MemoryEngine } from './MemoryEngine';
import { MEMORY_GAME_ID, MemorySave } from './MemoryModel';

export function memoryMilestone(saved: MemorySave): AchievementEvent | undefined {
  if (saved.profile.totalPairs === 0) { return undefined; }
  return { gameId: MEMORY_GAME_ID, type: 'milestone', isOfficial: true, occurredAt: Date.now(),
    sessionId: saved.round.id, eventId: 'memory:progress:' + saved.profile.totalPairs + ':' + saved.profile.totalTables,
    facts: [{ key: 'totalPairs', value: saved.profile.totalPairs }, { key: 'totalTables', value: saved.profile.totalTables }] };
}
export function memorySettlement(saved: MemorySave): AchievementEvent | undefined {
  if (saved.round.phase !== 'complete' || saved.round.reported) { return undefined; }
  return { gameId: MEMORY_GAME_ID, type: 'sessionEnd', isOfficial: true, occurredAt: Date.now(),
    sessionId: saved.round.id, eventId: saved.round.id + ':complete',
    facts: [{ key: 'totalPairs', value: saved.profile.totalPairs }, { key: 'totalTables', value: saved.profile.totalTables },
      { key: 'pairs', value: saved.round.pairs }, { key: 'attempts', value: saved.round.attempts }] };
}
export interface MemoryProgressPorts {
  save: (raw: string) => Promise<boolean>;
  report: (event: AchievementEvent) => Promise<boolean>;
  record: (tables: number) => void;
}
export class MemoryProgress {
  private queue: Promise<boolean> = Promise.resolve(true);
  private engine: MemoryEngine;
  private ports: MemoryProgressPorts;
  private recordedId: string = '';
  constructor(engine: MemoryEngine, ports: MemoryProgressPorts) { this.engine = engine; this.ports = ports; }
  flush(): Promise<boolean> {
    // Capture on enqueue: no old save or acknowledgement may overwrite a newer flip.
    const saved = this.engine.snapshot();
    this.queue = this.queue.then(() => this.commit(saved)).catch(() => false);
    return this.queue;
  }
  private async commit(saved: MemorySave): Promise<boolean> {
    if (!await this.ports.save(JSON.stringify(saved))) { return false; }
    const milestone = memoryMilestone(saved);
    if (milestone !== undefined && !await this.ports.report(milestone)) { return false; }
    const settlement = memorySettlement(saved);
    if (settlement !== undefined) {
      if (!await this.ports.report(settlement)) { return false; }
      saved.round.reported = true;
      if (!await this.ports.save(JSON.stringify(saved))) { return false; }
      if (this.engine.round.id === saved.round.id) { this.engine.round.reported = true; }
      if (this.recordedId !== saved.round.id) {
        this.recordedId = saved.round.id;
        this.ports.record(saved.profile.totalTables);
      }
    }
    return true;
  }
}
