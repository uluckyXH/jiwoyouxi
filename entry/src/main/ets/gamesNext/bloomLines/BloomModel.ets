export const BLOOM_GAME_ID: string = 'bloomLines';
export const BLOOM_ASSETS: string = 'gamesNext/bloomLines/';
export const BLOOM_LOGO: string = BLOOM_ASSETS + 'scene/logo.svg';
export const BLOOM_HINT: string = '直接拖动，或点珠再点空位 · 同色五颗开花';
export const BLOOM_HISTORY_LIMIT: number = 20;
export type BloomMode = 'garden' | 'classic';

export interface BloomConfig {
  mode: BloomMode;
  title: string;
  subtitle: string;
  size: number;
  colors: number;
  batch: number;
  initial: number;
}

export const BLOOM_MODES: BloomConfig[] = [
  { mode: 'garden', title: '轻松', subtitle: '7×7 · 每步 2 颗', size: 7, colors: 5, batch: 2, initial: 5 },
  { mode: 'classic', title: '经典', subtitle: '9×9 · 每步 3 颗', size: 9, colors: 7, batch: 3, initial: 7 }
];
export const BLOOM_COLOR_NAMES: string[] = ['金色小鸡', '绿色叶片', '粉色花朵', '蓝色水滴', '紫色星星', '橙色蝴蝶', '青色爱心'];

export function bloomConfig(mode: BloomMode): BloomConfig {
  return BLOOM_MODES[mode === 'classic' ? 1 : 0];
}

export interface BloomRound {
  session: string;
  mode: BloomMode;
  board: number[];
  next: number[];
  seed: number;
  score: number;
  moves: number;
  cleared: number;
  ended: boolean;
  reported: boolean;
}

export interface BloomProfile {
  bestGarden: number;
  bestClassic: number;
  totalCleared: number;
}

export interface BloomSave {
  version: number;
  round: BloomRound;
  history: BloomRound[];
  profile: BloomProfile;
  credited: number;
}

export interface BloomTurn {
  valid: boolean;
  path: number[];
  color: number;
  afterMove: number[];
  spawnBoard: number[];
  spawned: number[];
  refilled: number[];
  removed: number[];
  gain: number;
  clearFromMove: boolean;
}

export function bloomCloneRound(round: BloomRound): BloomRound {
  return { session: round.session, mode: round.mode, board: round.board.slice(), next: round.next.slice(),
    seed: round.seed, score: round.score, moves: round.moves, cleared: round.cleared,
    ended: round.ended, reported: round.reported };
}

export function bloomEmptyTurn(): BloomTurn {
  return { valid: false, path: [], color: -1, afterMove: [], spawnBoard: [], spawned: [], refilled: [], removed: [],
    gain: 0, clearFromMove: false };
}
