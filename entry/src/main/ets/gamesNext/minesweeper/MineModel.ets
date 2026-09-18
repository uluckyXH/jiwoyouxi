export const MINE_ASSETS: string = 'gamesNext/minesweeper/';

export interface MineLevel {
  key: string;
  name: string;
  caption: string;
  rows: number;
  cols: number;
  mines: number;
}

export const MINE_LEVELS: MineLevel[] = [
  { key: 'easy', name: '初探', caption: '庭院小径', rows: 8, cols: 8, mines: 10 },
  { key: 'normal', name: '进阶', caption: '林间漫步', rows: 13, cols: 10, mines: 25 },
  { key: 'hard', name: '挑战', caption: '深林寻踪', rows: 16, cols: 12, mines: 45 }
];

export interface SurveyCell {
  index: number;
  mine: boolean;
  open: boolean;
  flag: boolean;
  near: number;
  exploded: boolean;
}

export interface MineSave {
  version: number;
  level: string;
  phase: string;
  seed: number;
  session: string;
  elapsedMs: number;
  cells: SurveyCell[];
  flagMode: boolean;
  everWrongFlag: boolean;
  manualAllFlags: boolean;
  reported: boolean;
  bestTimes: number[];
}

export function mineLevel(key: string): MineLevel {
  const found = MINE_LEVELS.find((level: MineLevel) => level.key === key);
  return found === undefined ? MINE_LEVELS[0] : found;
}

export function mineNeighbors(index: number, rows: number, cols: number): number[] {
  const result: number[] = [];
  const row = Math.floor(index / cols);
  const col = index % cols;
  for (let dy = -1; dy <= 1; dy += 1) {
    for (let dx = -1; dx <= 1; dx += 1) {
      const y = row + dy;
      const x = col + dx;
      if ((dx !== 0 || dy !== 0) && x >= 0 && x < cols && y >= 0 && y < rows) result.push(y * cols + x);
    }
  }
  return result;
}

export function mineTime(milliseconds: number): string {
  const seconds = Math.floor(Math.max(0, milliseconds) / 1000);
  const minutes = Math.floor(seconds / 60);
  return `${minutes < 10 ? '0' : ''}${minutes}:${seconds % 60 < 10 ? '0' : ''}${seconds % 60}`;
}
