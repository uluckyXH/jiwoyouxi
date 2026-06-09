export interface MineCell {
  index: number;
  mine: boolean;
  open: boolean;
  flag: boolean;
  neighbor: number;
  boom: boolean;
}

export interface MineDifficulty {
  key: string;
  label: string;
  rows: number;
  cols: number;
  mines: number;
}

export const DIFFICULTIES: MineDifficulty[] = [
  { key: 'easy', label: '简单', rows: 8, cols: 8, mines: 10 },
  { key: 'normal', label: '中等', rows: 13, cols: 10, mines: 25 },
  { key: 'hard', label: '困难', rows: 16, cols: 12, mines: 45 }
];
