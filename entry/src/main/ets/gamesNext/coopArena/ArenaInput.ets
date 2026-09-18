import { ArenaPoint } from './ArenaModel';

/** First pointer owns a gesture. Layout/pause/cancel always drops the pending command. */
export class ArenaInput {
  skill: number = -1;
  pointer: number = -1;
  x: number = -1;
  y: number = -1;
  arm(skill: number): void { this.cancel(); this.skill = skill; }
  down(id: number,x: number,y: number,size: number): void {
    if (this.skill < 0 || this.pointer >= 0 || !this.inside(x,y,size)) return;
    this.pointer = id; this.x = x*720/size; this.y = y*720/size;
  }
  move(id: number,x: number,y: number,size: number): void {
    if (id !== this.pointer || this.pointer < 0) return;
    this.x = this.inside(x,y,size) ? x*720/size : -1; this.y = y*720/size;
  }
  up(id: number,x: number,y: number,size: number): ArenaPoint | undefined {
    if (id !== this.pointer || this.pointer < 0) return undefined;
    this.pointer = -1; this.x = -1; this.y = -1;
    return this.inside(x,y,size) ? {x:x*720/size,y:y*720/size} : undefined;
  }
  cancel(): void { this.pointer = -1; this.x = -1; this.y = -1; this.skill = -1; }
  private inside(x: number,y: number,size: number): boolean {
    return Number.isFinite(x) && Number.isFinite(y) && size > 0 && x >= 0 && y >= 0 && x <= size && y <= size;
  }
}
