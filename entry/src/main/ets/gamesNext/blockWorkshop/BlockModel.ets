export const BLOCK_ASSETS: string = 'gamesNext/blockWorkshop/';
export const BLOCK_COLS: number = 10;
export const BLOCK_ROWS: number = 22;
export const BLOCK_HIDDEN: number = 2;
export const BLOCK_LOCK_MS: number = 500;
export const BLOCK_CLEAR_MS: number = 160;
export const BLOCK_NAMES: string[] = ['长条', '方块', '山形', '右阶', '左阶', '左钩', '右钩'];
export const BLOCK_COLORS: string[] = ['#62b9b5', '#e5b95d', '#ad8bc5', '#87ae69', '#d97b7b', '#749bca', '#d59a61'];
// Local cells in a 4×4 coordinate frame; each entry contains exactly four cells.
export const BLOCK_SHAPES: number[][][] = [
  [[4,5,6,7], [2,6,10,14], [8,9,10,11], [1,5,9,13]],
  [[1,2,5,6], [1,2,5,6], [1,2,5,6], [1,2,5,6]],
  [[1,4,5,6], [1,5,6,9], [4,5,6,9], [1,4,5,9]],
  [[1,2,4,5], [1,5,6,10], [5,6,8,9], [0,4,5,9]],
  [[0,1,5,6], [2,5,6,9], [4,5,9,10], [1,4,5,8]],
  [[0,4,5,6], [1,2,5,9], [4,5,6,10], [1,5,8,9]],
  [[2,4,5,6], [1,5,9,10], [4,5,6,8], [0,1,5,9]]
];
export interface BlockPiece { kind: number; turn: number; x: number; y: number; }
export interface BlockRound {
  version: number; session: string; seed: number; board: number[]; queue: number[]; bag: number[];
  piece: BlockPiece; hold: number; holdUsed: boolean; score: number; best: number; lines: number;
  level: number; combo: number; maxClear: number; lastClear: number; pieces: number;
  phase: string; clearing: number[]; clearLeft: number; fallMs: number; lockMs: number; resets: number;
  elapsed: number; reported: boolean; milestones: number;
}
export interface BlockEvent { name: string; lines: number; }
export function blockSpeed(level: number): number {
  const speeds: number[] = [700, 600, 450, 320, 240, 160, 120, 90, 65, 50];
  return speeds[Math.min(speeds.length - 1, Math.max(0, level - 1))];
}
