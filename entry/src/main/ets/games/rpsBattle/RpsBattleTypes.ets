export type RpsBattleFaction = 'rock' | 'scissors' | 'paper';
export type RpsBattleThemeKey = 'rps' | 'colors' | 'countries' | 'brands';
export type RpsBattleModeKey = 'classic' | 'zones' | 'traitor' | 'equality';
export type RpsBattleMechanicKey =
  'baseChase' | 'conversion' | 'controlZone' | 'blackHole' | 'lastStand' | 'powerUps' | 'teamPowerUps' |
  'shrink' | 'traitor' | 'snap' | 'obstacles';
export type RpsBattleMechanicState = 'core' | 'enabled' | 'upcoming';
export type RpsBattleScale = 'small' | 'standard' | 'large' | 'custom';
export type RpsBattlePhase = 'setup' | 'countdown' | 'playing' | 'paused' | 'result';
export type RpsBattleFinishReason = 'none' | 'clear' | 'time' | 'draw' | 'zone';
export type RpsBattleLastStandEventKind = 'split' | 'reviveMark' | 'revive';
export type RpsBattlePowerUpKind = 'speed' | 'shield' | 'split';

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

export interface RpsBattleModePreset {
  key: RpsBattleModeKey;
  name: string;
  icon: string;
  subtitle: string;
  objective: string;
  mechanics: string[];
  enabledMechanics: string[];
  upcomingMechanics: string[];
  mechanicOptions: RpsBattleMechanicOption[];
}

export interface RpsBattleMechanicOption {
  key: RpsBattleMechanicKey;
  label: string;
  summary: string;
  state: RpsBattleMechanicState;
  defaultEnabled: boolean;
  canDisable: boolean;
}

export interface RpsBattleMechanicSelection {
  baseChase?: boolean;
  conversion?: boolean;
  controlZone?: boolean;
  blackHole?: boolean;
  lastStand?: boolean;
  powerUps?: boolean;
  teamPowerUps?: boolean;
  shrink?: boolean;
  traitor?: boolean;
  snap?: boolean;
  obstacles?: boolean;
}

export interface RpsBattleModeRules {
  key: RpsBattleModeKey;
  hasControlZone: boolean;
  hasBlackHole: boolean;
  hasLastStand: boolean;
  hasPowerUps: boolean;
  hasTeamPowerUps: boolean;
}

export interface RpsBattleFactionCounts {
  rock: number;
  scissors: number;
  paper: number;
}

export interface RpsBattleOptions {
  modeKey: RpsBattleModeKey;
  mechanics: RpsBattleMechanicSelection;
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
  shield: number;
  speedBoostUntilSec: number;
  convertedAt: number;
}

export interface RpsBattleSnapshot {
  entities: RpsBattleEntity[];
  counts: RpsBattleFactionCounts;
  controlZone: RpsBattleControlZone | null;
  blackHole: RpsBattleBlackHoleState | null;
  lastStand: RpsBattleLastStandState | null;
  powerUps: RpsBattlePowerUpState | null;
  elapsedSec: number;
  timeLeftSec: number;
  conversions: number;
  result: RpsBattleResult;
}

export interface RpsBattleControlZone {
  x: number;
  y: number;
  radius: number;
  owner: RpsBattleFaction | '';
  capturingFaction: RpsBattleFaction | '';
  score: number;
  pressure: RpsBattleFactionCounts;
}

export interface RpsBattleBlackHoleState {
  active: boolean;
  x: number;
  y: number;
  radius: number;
  reach: number;
  nextAtSec: number;
  swallowed: number;
}

export interface RpsBattlePowerUp {
  id: number;
  kind: RpsBattlePowerUpKind;
  x: number;
  y: number;
  radius: number;
  expiresAtSec: number;
}

export interface RpsBattlePowerUpPickup {
  collectorId: number;
  faction: RpsBattleFaction;
  kind: RpsBattlePowerUpKind;
  x: number;
  y: number;
  isTeam: boolean;
}

export interface RpsBattlePowerUpPulse {
  faction: RpsBattleFaction;
  kind: RpsBattlePowerUpKind;
  x: number;
  y: number;
  startedAtSec: number;
  isTeam: boolean;
}

export interface RpsBattlePowerUpState {
  items: RpsBattlePowerUp[];
  pulses: RpsBattlePowerUpPulse[];
  spawnedCount: number;
  pickedCount: number;
  teamEffectCount: number;
}

export interface RpsBattleReviveMark {
  faction: RpsBattleFaction;
  x: number;
  y: number;
  createdAtSec: number;
  dueAtSec: number;
}

export interface RpsBattleLastStandPulse {
  faction: RpsBattleFaction;
  x: number;
  y: number;
  startedAtSec: number;
  kind: RpsBattleLastStandEventKind;
}

export interface RpsBattleSpawnRequest {
  faction: RpsBattleFaction;
  x: number;
  y: number;
  speedScale: number;
  eventKind: RpsBattleLastStandEventKind;
}

export interface RpsBattleLastStandState {
  reviveMarks: RpsBattleReviveMark[];
  pulses: RpsBattleLastStandPulse[];
  splitCount: number;
  reviveCount: number;
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
