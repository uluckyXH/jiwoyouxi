import { MemoryMode, MemoryRound, MemoryProfile, MemorySave, MemoryFlip,
  memoryEmptyProfile, memoryMatched } from './MemoryModel';
import { memoryDeal, memorySaveValid } from './MemoryRules';

export class MemoryEngine {
  round: MemoryRound;
  profile: MemoryProfile = memoryEmptyProfile();
  constructor(mode: MemoryMode = 'journey', seed: number = Date.now()) {
    this.round = memoryDeal(mode, 1, seed);
  }
  flip(index: number): MemoryFlip {
    const r = this.round;
    const result: MemoryFlip = { accepted: false, paired: false, complete: false };
    if (r.phase !== 'ready' || !Number.isInteger(index) || index < 0 || index >= r.cards.length ||
      r.matched[index] || index === r.first) { return result; }
    result.accepted = true;
    if (r.first < 0) { r.first = index; return result; }
    r.second = index;
    r.attempts += 1;
    if (r.cards[r.first] !== r.cards[index]) {
      r.phase = 'mismatch';
      r.streak = 0;
      return result;
    }
    result.paired = true;
    r.matched[r.first] = true;
    r.matched[index] = true;
    r.streak += 1;
    r.topStreak = Math.max(r.topStreak, r.streak);
    this.profile.totalPairs += 1;
    this.profile.bestStreak = Math.max(this.profile.bestStreak, r.streak);
    result.complete = memoryMatched(r) === r.pairs;
    r.phase = result.complete ? 'complete' : 'match';
    if (result.complete) {
      this.profile.totalTables += 1;
      const best = this.bestAttempts(r.pairs);
      const next = best === 0 ? r.attempts : Math.min(best, r.attempts);
      if (r.pairs === 6) { this.profile.best6 = next; }
      else if (r.pairs === 8) { this.profile.best8 = next; }
      else if (r.pairs === 10) { this.profile.best10 = next; }
      else { this.profile.best12 = next; }
    }
    return result;
  }
  settle(): boolean {
    const r = this.round;
    if (r.phase !== 'match' && r.phase !== 'mismatch') { return false; }
    r.first = -1;
    r.second = -1;
    r.phase = 'ready';
    return true;
  }
  next(): boolean {
    if (this.round.phase !== 'complete' || !this.round.reported) { return false; }
    this.round = memoryDeal(this.round.mode, this.round.number + 1, this.round.seed);
    return true;
  }
  restart(mode: MemoryMode): void {
    this.round = memoryDeal(mode, 1, this.round.seed);
  }
  bestAttempts(pairs: number = this.round.pairs): number {
    if (pairs === 6) { return this.profile.best6; }
    if (pairs === 8) { return this.profile.best8; }
    if (pairs === 10) { return this.profile.best10; }
    return this.profile.best12;
  }
  snapshot(): MemorySave { return JSON.parse(this.serialize()) as MemorySave; }
  serialize(): string {
    const saved: MemorySave = { version: 1, round: this.round, profile: this.profile };
    return JSON.stringify(saved);
  }
  restore(raw: string): boolean {
    try {
      const saved = JSON.parse(raw) as MemorySave;
      if (!memorySaveValid(saved)) { return false; }
      this.round = saved.round;
      this.profile = saved.profile;
      return true;
    } catch (_) { return false; }
  }
}
