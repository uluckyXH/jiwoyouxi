export type RpsBattleFaction = 'rock' | 'scissors' | 'paper';
export type RpsBattleThemeKey = 'rps' | 'colors' | 'countries' | 'brands';
export type RpsBattleScale = 'small' | 'standard' | 'large' | 'custom';
export type RpsBattlePhase = 'setup' | 'countdown' | 'playing' | 'paused' | 'result';
export type RpsBattleFinishReason = 'none' | 'clear' | 'time' | 'draw';

export interface RpsBattleFactionInfo {
  id: RpsBattleFaction;
  label: string;
  symbol: string;
  color: string;
  softColor: string;
  textColor: string;
}

export interface RpsBattleThemePreset {
  key: RpsBattleThemeKey;
  name: string;
  mark: string;
  subtitle: string;
  factions: RpsBattleFactionInfo[];
}

export interface RpsBattleFactionCounts {
  rock: number;
  scissors: number;
  paper: number;
}

export interface RpsBattleOptions {
  supportFaction: RpsBattleFaction;
  initialCounts: RpsBattleFactionCounts;
  durationSec: number;
}

export interface RpsBattleEntity {
  id: number;
  faction: RpsBattleFaction;
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
  convertedAt: number;
}

export interface RpsBattleSnapshot {
  entities: RpsBattleEntity[];
  counts: RpsBattleFactionCounts;
  elapsedSec: number;
  timeLeftSec: number;
  conversions: number;
  result: RpsBattleResult;
}

export interface RpsBattleResult {
  finishReason: RpsBattleFinishReason;
  winner: RpsBattleFaction | '';
  supportFaction: RpsBattleFaction;
  supportWon: boolean;
  counts: RpsBattleFactionCounts;
  elapsedSec: number;
  conversions: number;
  score: number;
}

export interface RpsBattleScaleChoice {
  id: RpsBattleScale;
  label: string;
  count: number;
}

export interface RpsBattleDurationChoice {
  label: string;
  durationSec: number;
}

export const RPS_BATTLE_DURATION_SEC: number = 60;
export const RPS_BATTLE_MIN_COUNT_PER_FACTION: number = 3;
export const RPS_BATTLE_RECOMMENDED_MAX_PER_FACTION: number = 12;
export const RPS_BATTLE_MAX_COUNT_PER_FACTION: number = 20;
export const RPS_BATTLE_MAX_TOTAL_ENTITIES: number = 60;
export const RPS_BATTLE_LOGICAL_FACTIONS: RpsBattleFaction[] = ['rock', 'scissors', 'paper'];

export const RPS_BATTLE_SCALE_CHOICES: RpsBattleScaleChoice[] = [
  { id: 'small', label: '小局', count: 5 },
  { id: 'standard', label: '标准', count: 8 },
  { id: 'large', label: '大局', count: 12 }
];

export const RPS_BATTLE_DURATION_CHOICES: RpsBattleDurationChoice[] = [
  { label: '快速', durationSec: 30 },
  { label: '标准', durationSec: 60 },
  { label: '持久', durationSec: 90 },
  { label: '长局', durationSec: 120 }
];
