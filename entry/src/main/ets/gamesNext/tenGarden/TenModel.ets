export const TEN_GAME_ID: string = 'tenGarden';
export const TEN_ASSETS: string = 'gamesNext/tenGarden/';
export const TEN_LOGO: string = TEN_ASSETS + 'scene/logo.svg';
export const TEN_DIRECTIONS: string[] = ['下', '左', '上', '右'];
export const TEN_DIRECTION_ICONS: string[] = ['down', 'left', 'up', 'right'];
export interface TenPath { cells: number[]; }
export interface TenPuzzleTemplate { values: number[]; steps: number[][]; }
export interface TenPuzzle { key: string; size: number; values: number[]; solution: TenPath[]; direction: number; }
export interface TenRound {
  id: string; stage: number; board: number[]; ids: number[]; history: TenPath[];
  credited: number; phase: string; reported: boolean; undos: number; hints: number;
}
export interface TenProfile { totalGroups: number; totalWins: number; totalChallenges: number; }
export interface TenSave { version: number; round: TenRound; profile: TenProfile; }
export interface TenHint { rewind: number; path: number[]; }
export interface TenTileView { id: number; value: number; index: number; }
export function tenInteger(value: number, min: number, max: number): boolean {
  return typeof value === 'number' && Number.isInteger(value) && value >= min && value <= max;
}
export function tenProfile(round: TenRound): TenProfile {
  const wins = round.stage - 1 + (round.phase === 'complete' ? 1 : 0);
  return { totalGroups: (round.stage > 1 ? 2 + (round.stage - 2) * 12 : 0) + round.credited,
    totalWins: wins, totalChallenges: Math.max(0, wins - 1) };
}
