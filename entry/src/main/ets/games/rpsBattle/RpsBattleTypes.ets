export type RpsBattleFaction = 'rock' | 'scissors' | 'paper';
export type RpsBattleScale = 'small' | 'standard' | 'large';
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

export interface RpsBattleFactionCounts {
  rock: number;
  scissors: number;
  paper: number;
}

export interface RpsBattleOptions {
  supportFaction: RpsBattleFaction;
  scale: RpsBattleScale;
  initialCount: number;
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

export const RPS_BATTLE_DURATION_SEC: number = 60;
export const RPS_BATTLE_FACTIONS: RpsBattleFactionInfo[] = [
  {
    id: 'rock',
    label: '石头',
    symbol: '✊',
    color: '#d25f45',
    softColor: '#ffe0d8',
    textColor: '#6e2e22'
  },
  {
    id: 'scissors',
    label: '剪刀',
    symbol: '✌',
    color: '#2c8f7f',
    softColor: '#dcf5ee',
    textColor: '#155849'
  },
  {
    id: 'paper',
    label: '布',
    symbol: '✋',
    color: '#4e6edb',
    softColor: '#e3e9ff',
    textColor: '#243f94'
  }
];

export const RPS_BATTLE_SCALE_CHOICES: RpsBattleScaleChoice[] = [
  { id: 'small', label: '小局', count: 5 },
  { id: 'standard', label: '标准', count: 8 },
  { id: 'large', label: '大局', count: 12 }
];
