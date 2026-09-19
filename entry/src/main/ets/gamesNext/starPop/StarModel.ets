export const STAR_ID: string = 'starPop';
export const STAR_ASSETS: string = 'gamesNext/starPop/';
export const STAR_LOGO: string = STAR_ASSETS + 'scene/logo.svg';
export const STAR_WIDTH: number = 8;
export const STAR_HEIGHT: number = 10;
export const STAR_COUNT: number = 80;
export const STAR_NAMES: string[] = ['杏黄星星', '蜜桃花朵', '青绿叶子', '晴蓝水滴', '香芋月牙'];
export type StarMode = 'easy' | 'classic';
export type StarStatus = 'playing' | 'stageEnd' | 'failed' | 'finished';
export interface StarTile { id: number; color: number; cell: number; }
export interface StarFall { cells: number[]; ids: number[]; removedIds: number[]; gain: number; }
export interface StarPuzzle { seed: number; cells: number[]; witness: number; path: number[]; }
/** Remaining legal moves and their score, including the final remainder bonus. */
export interface StarPlan { path: number[]; score: number; }
export interface StarUndo {
  cells: number[]; ids: number[]; score: number; moves: number; stageMoves: number;
  hintPlan?: StarPlan;
}
export interface StarRound {
  session: string; seed: number; mode: StarMode; stage: number; target: number; witness: number;
  cells: number[]; ids: number[]; score: number; total: number; moves: number; stageMoves: number;
  highWater: number; undoUsed: boolean; undo: StarUndo | undefined; status: StarStatus; bonus: number;
  bestGroup: number; hintPlan?: StarPlan;
}
export interface StarProfile {
  totalCleared: number; maxGroup: number; bestEasy: number; bestClassic: number;
  stageEasy: number; stageClassic: number;
}
export function starColors(mode: StarMode): number { return mode === 'easy' ? 4 : 5; }
export function starModeTitle(mode: StarMode): string { return mode === 'easy' ? '轻松 · 四色' : '经典 · 五色'; }
export function starBonus(remaining: number): number { return Math.max(0, 500 - 5 * remaining * remaining); }
export function starGain(count: number): number { return count >= 2 ? 5 * count * count : 0; }
export function starTarget(stage: number, witness: number): number {
  const ratios: number[] = [.60, .65, .70, .72, .74, .76, .78, .80, .82, .84, .85];
  return Math.max(100, Math.floor(witness * ratios[Math.min(ratios.length - 1, Math.max(0, stage - 1))] / 50) * 50);
}
