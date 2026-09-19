import { AchievementEvent } from '../../shell/AchievementModule';
import { TangramPoint, TangramPose, tangramBounds, tangramCenter, tangramCopy, tangramInside,
  tangramLegal, tangramPolygon, tangramSnap, tangramSolved } from './TangramGeometry';
import { TANGRAM_LEVELS, TANGRAM_WORLD_HEIGHT, tangramLevel, tangramSolution, tangramTarget, tangramTray } from './TangramLevels';

export interface TangramSave {
  version: number; levelId: string; sessionId: string; poses: TangramPose[]; history: TangramPose[][];
  collected: string[]; solved: boolean; guide: boolean; hints: number; moves: number;
  pending: AchievementEvent[];
}

export class TangramEngine {
  levelId: string = TANGRAM_LEVELS[0].id;
  sessionId: string = '';
  poses: TangramPose[] = tangramTray();
  history: TangramPose[][] = [];
  collected: string[] = [];
  solved: boolean = false;
  guide: boolean = true;
  hints: number = 0;
  moves: number = 0;
  pending: AchievementEvent[] = [];
  selected: number = -1;
  hint: TangramPose | undefined = undefined;
  private before: TangramPose[] | undefined = undefined;
  private pointer: TangramPoint | undefined = undefined;
  private origin: TangramPose | undefined = undefined;

  constructor() { this.sessionId = this.newId(); }
  private newId(): string { return `tangram-${Date.now()}-${Math.floor(Math.random() * 0x100000000)}`; }
  target(): TangramPoint[][] { return tangramTarget(this.levelId); }
  private snapshot(): TangramPose[] { return this.poses.map(tangramCopy); }

  start(levelId: string): void {
    this.cancelDrag();
    this.levelId = tangramLevel(levelId).id;
    this.sessionId = this.newId();
    this.poses = tangramTray(); this.history = []; this.solved = false;
    this.guide = tangramLevel(levelId).guide; this.hints = 0; this.moves = 0;
    this.selected = -1; this.hint = undefined;
  }

  begin(p: TangramPoint): boolean {
    if (this.solved || this.before !== undefined) return false;
    let hit = -1;
    const ordered = this.poses.filter((pose: TangramPose): boolean => pose.id !== this.selected);
    const selected = this.poses.find((pose: TangramPose): boolean => pose.id === this.selected);
    if (selected !== undefined) ordered.push(selected);
    for (let i = ordered.length - 1; i >= 0; i--) {
      if (tangramInside(p, tangramPolygon(ordered[i]))) { hit = ordered[i].id; break; }
    }
    if (hit < 0 && this.selected < 0) return false;
    this.before = this.snapshot();
    if (hit >= 0) this.selected = hit;
    if (this.hint !== undefined && this.hint.id !== this.selected) this.hint = undefined;
    const pose = this.poses[this.selected];
    if (hit < 0) {
      const center = tangramCenter(pose);
      pose.x += p.x - center.x; pose.y += p.y - center.y;
      this.clamp(pose);
    }
    this.pointer = { x: p.x, y: p.y }; this.origin = tangramCopy(pose);
    return true;
  }

  drag(p: TangramPoint): void {
    if (this.pointer === undefined || this.origin === undefined) return;
    const pose = this.poses[this.selected];
    pose.x = this.origin.x + p.x - this.pointer.x;
    pose.y = this.origin.y + p.y - this.pointer.y;
    this.clamp(pose);
  }

  end(): boolean {
    if (this.before === undefined) return false;
    const before = this.before;
    this.before = undefined; this.pointer = undefined; this.origin = undefined;
    const original = tangramCopy(this.poses[this.selected]);
    this.poses[this.selected] = tangramSnap(original, this.poses, this.target(), .28);
    this.finish(before);
    return original.x !== this.poses[this.selected].x || original.y !== this.poses[this.selected].y;
  }

  cancelDrag(): void {
    if (this.before !== undefined) this.poses = this.before;
    this.before = undefined; this.pointer = undefined; this.origin = undefined;
  }

  transform(turn: number, flip: boolean = false): void {
    this.cancelDrag();
    if (this.selected < 0 || this.solved) return;
    const before = this.snapshot(), pose = this.poses[this.selected], center = tangramCenter(pose);
    pose.turn = (pose.turn + turn + 8) % 8;
    if (flip) pose.flip = !pose.flip;
    const moved = tangramCenter(pose);
    pose.x += center.x - moved.x; pose.y += center.y - moved.y;
    this.clamp(pose);
    this.poses[this.selected] = tangramSnap(pose, this.poses, this.target(), .28);
    this.finish(before);
  }

  nudge(dx: number, dy: number): void {
    this.cancelDrag();
    if (this.selected < 0 || this.solved) return;
    const before = this.snapshot(), pose = this.poses[this.selected];
    pose.x += dx; pose.y += dy; this.clamp(pose);
    this.poses[this.selected] = tangramSnap(pose, this.poses, this.target(), .09);
    this.finish(before);
  }

  undo(): boolean {
    this.cancelDrag();
    if (this.solved || this.history.length === 0) return false;
    const previous = this.history.pop();
    if (previous === undefined) return false;
    this.poses = previous; this.hint = undefined; this.moves += 1;
    return true;
  }

  select(id: number): void {
    this.cancelDrag();
    if (Number.isInteger(id) && id >= 0 && id < 7) {
      this.selected = id;
      if (this.hint !== undefined && this.hint.id !== id) this.hint = undefined;
    }
  }

  returnSelected(): void {
    this.cancelDrag();
    if (this.selected < 0 || this.solved) return;
    const before = this.snapshot();
    this.poses[this.selected] = tangramTray()[this.selected];
    this.hint = undefined; this.finish(before);
  }

  placed(): number {
    const target = this.target();
    return this.poses.filter((pose: TangramPose): boolean => tangramLegal(pose, this.poses, target)).length;
  }

  showHint(): boolean {
    this.cancelDrag();
    if (this.solved) return false;
    const target = this.target();
    const solutions = tangramSolution(this.levelId);
    const order = this.selected >= 0 ? [this.selected].concat(this.poses.map((p: TangramPose): number => p.id)
      .filter((id: number): boolean => id !== this.selected)) : this.poses.map((p: TangramPose): number => p.id);
    for (const id of order) {
      if (tangramLegal(this.poses[id], this.poses, target)) continue;
      // Equal triangles may use each other's reference positions.
      for (const reference of solutions) {
        if (!(reference.id === id || (id < 2 && reference.id < 2) || (id >= 3 && id <= 4 && reference.id >= 3 && reference.id <= 4))) continue;
        const candidate = tangramCopy(reference); candidate.id = id;
        if (tangramLegal(candidate, this.poses, target)) {
          this.hint = candidate; this.selected = id; this.hints += 1; return true;
        }
      }
    }
    this.hint = undefined;
    return false;
  }

  toggleGuide(): void { this.cancelDrag(); this.guide = !this.guide; }

  private clamp(pose: TangramPose): void {
    const b = tangramBounds([tangramPolygon(pose)]);
    pose.x += Math.max(.12 - b.x, Math.min(0, 7.88 - b.x - b.width));
    pose.y += Math.max(.12 - b.y, Math.min(0, TANGRAM_WORLD_HEIGHT - .12 - b.y - b.height));
  }

  private finish(before: TangramPose[]): void {
    if (JSON.stringify(before) === JSON.stringify(this.poses)) return;
    this.history.push(before);
    if (this.history.length > 60) this.history.shift();
    this.moves += 1;
    if (this.hint !== undefined && tangramLegal(this.poses[this.hint.id], this.poses, this.target())) this.hint = undefined;
    if (!tangramSolved(this.poses, this.target())) return;
    this.solved = true; this.hint = undefined;
    if (!this.collected.includes(this.levelId)) this.collected.push(this.levelId);
    this.pending.push({ eventId: `${this.sessionId}:complete`, sessionId: this.sessionId, gameId: 'tangram',
      type: 'sessionEnd', occurredAt: Date.now(), isOfficial: true,
      facts: [{ key: 'won', value: 1 }, { key: 'collected', value: this.collected.length }] });
  }

  acknowledge(eventId: string): void { this.pending = this.pending.filter((e: AchievementEvent): boolean => e.eventId !== eventId); }

  serialize(): string {
    const save: TangramSave = { version: 1, levelId: this.levelId, sessionId: this.sessionId,
      poses: this.before === undefined ? this.snapshot() : this.before.map(tangramCopy), history: this.history,
      collected: this.collected, solved: this.solved, guide: this.guide, hints: this.hints, moves: this.moves, pending: this.pending };
    return JSON.stringify(save);
  }

  restore(raw: string): boolean {
    if (raw.length === 0) return true;
    if (raw.length > 200000) return false;
    try {
      const save = JSON.parse(raw) as TangramSave;
      if (save.version !== 1 || !TANGRAM_LEVELS.some((l): boolean => l.id === save.levelId) ||
        typeof save.sessionId !== 'string' || !save.sessionId.startsWith('tangram-') || save.sessionId.length > 100 ||
        !this.validPoses(save.poses) || !Array.isArray(save.history) || save.history.length > 60 ||
        !save.history.every((poses: TangramPose[]): boolean => this.validPoses(poses)) ||
        !Array.isArray(save.collected) || save.collected.length > TANGRAM_LEVELS.length ||
        !save.collected.every((id: string): boolean => TANGRAM_LEVELS.some((l): boolean => l.id === id)) ||
        new Set(save.collected).size !== save.collected.length || typeof save.solved !== 'boolean' || typeof save.guide !== 'boolean' ||
        !Number.isInteger(save.moves) || save.moves < 0 || !Number.isInteger(save.hints) || save.hints < 0 ||
        !Array.isArray(save.pending) || !save.pending.every((event: AchievementEvent): boolean => this.validEvent(event, save.collected.length)) ||
        (save.solved && (!save.collected.includes(save.levelId) || !tangramSolved(save.poses, tangramTarget(save.levelId))))) return false;
      this.cancelDrag();
      this.levelId = save.levelId; this.sessionId = save.sessionId; this.poses = save.poses; this.history = save.history;
      this.collected = save.collected; this.solved = save.solved; this.guide = save.guide; this.hints = save.hints;
      this.moves = save.moves; this.pending = save.pending; this.selected = -1; this.hint = undefined;
      return true;
    } catch (_) { return false; }
  }

  private validPoses(poses: TangramPose[]): boolean {
    return Array.isArray(poses) && poses.length === 7 && poses.every((p: TangramPose, index: number): boolean =>
      p !== null && p.id === index && Number.isFinite(p.x) && Number.isFinite(p.y) && p.x >= -3 && p.x <= 11 &&
      p.y >= -3 && p.y <= 14 && Number.isInteger(p.turn) && p.turn >= 0 && p.turn < 8 && typeof p.flip === 'boolean');
  }

  private validEvent(e: AchievementEvent, collected: number): boolean {
    return e !== null && e.gameId === 'tangram' && e.type === 'sessionEnd' && e.isOfficial === true &&
      typeof e.sessionId === 'string' && e.sessionId.startsWith('tangram-') && e.eventId === `${e.sessionId}:complete` &&
      Number.isFinite(e.occurredAt) && Array.isArray(e.facts) && e.facts.length === 2 &&
      e.facts[0].key === 'won' && e.facts[0].value === 1 && e.facts[1].key === 'collected' &&
      Number.isInteger(e.facts[1].value) && e.facts[1].value >= 1 && e.facts[1].value <= collected;
  }
}
