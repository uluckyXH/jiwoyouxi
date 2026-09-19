export const MEMORY_GAME_ID: string = 'memoryPairs';
export const MEMORY_ASSETS: string = 'gamesNext/memoryGarden/';
export const MEMORY_LOGO: string = MEMORY_ASSETS + 'scene/logo.svg';
export const MEMORY_HINT: string = '翻开两张，找一对小伙伴';
export type MemoryMode = 'journey' | 'easy' | 'normal' | 'focus';
export type MemoryPhase = 'ready' | 'mismatch' | 'match' | 'complete';
export interface MemoryModeInfo { id: MemoryMode; title: string; subtitle: string; }
export const MEMORY_MODES: MemoryModeInfo[] = [
  { id: 'journey', title: '漫游', subtitle: '6 → 12 对' },
  { id: 'easy', title: '轻松', subtitle: '固定 6 对' },
  { id: 'normal', title: '标准', subtitle: '固定 8 对' },
  { id: 'focus', title: '专注', subtitle: '固定 12 对' }
];
export const MEMORY_PICTURES: string[] = [
  '小鸡', '花朵', '盆栽', '茶杯', '风铃', '草莓', '蜜蜂', '蘑菇',
  '叶子', '水壶', '云朵', '蝴蝶', '茶壶', '桃子', '月亮', '橡果'
];
export interface MemoryRound {
  id: string;
  mode: MemoryMode;
  number: number;
  pairs: number;
  seed: number;
  cards: number[];
  matched: boolean[];
  first: number;
  second: number;
  phase: MemoryPhase;
  attempts: number;
  streak: number;
  topStreak: number;
  reported: boolean;
}
export interface MemoryProfile {
  totalPairs: number;
  totalTables: number;
  bestStreak: number;
  best6: number;
  best8: number;
  best10: number;
  best12: number;
}
export interface MemorySave { version: number; round: MemoryRound; profile: MemoryProfile; }
export interface MemoryFlip { accepted: boolean; paired: boolean; complete: boolean; }

export function memoryPairCount(mode: MemoryMode, number: number): number {
  if (mode === 'easy') { return 6; }
  if (mode === 'normal') { return 8; }
  if (mode === 'focus') { return 12; }
  return 6 + Math.min(3, Math.floor((Math.max(1, number) - 1) / 2)) * 2;
}
export function memoryModeTitle(mode: MemoryMode): string {
  return MEMORY_MODES.find((item: MemoryModeInfo) => item.id === mode)?.title ?? '漫游';
}
export function memoryMatched(round: MemoryRound): number {
  return round.matched.filter((matched: boolean) => matched).length / 2;
}
export function memoryOpen(round: MemoryRound, index: number): boolean {
  return round.matched[index] || index === round.first || index === round.second;
}
export function memoryEmptyProfile(): MemoryProfile {
  return { totalPairs: 0, totalTables: 0, bestStreak: 0, best6: 0, best8: 0, best10: 0, best12: 0 };
}
