export const TYPE_COUNT: number = 3;

export enum GamePhase {
  Setup = 0,
  Countdown = 1,
  Playing = 2,
  Paused = 3,
  Result = 4
}

export enum FieldMode {
  Push = 0,
  Pull = 1
}

export enum GameEventKind {
  None = 0,
  Attack = 1,
  Warning = 2,
  Shrink = 3,
  Snap = 4,
  Win = 5,
  PowerUp = 6
}

export enum PowerUpKind {
  Speed = 0,
  Shield = 1,
  Split = 2
}

export interface FactionInfo {
  id: number;
  label: string;
  emoji: string;
  color: string;
  darkColor: string;
}

export interface NativeGameOptions {
  themeKey: string;
  customLabels: string[];
  counts: number[];
  durationSec: number;
  deathmatch: boolean;
  tournament: boolean;
  bestOf: number;
  winnerPenalty: number;
  godHand: boolean;
  obstacles: boolean;
  shrink: boolean;
  bounty: boolean;
  blackHole: boolean;
  traitor: boolean;
  thanos: boolean;
  lastStand: boolean;
  controlZones: boolean;
  powerUps: boolean;
  teamPowerUps: boolean;
  tenAgainstOne: boolean;
  betting: boolean;
  stake: number;
  notifications: boolean;
}

export interface Entity {
  id: number;
  type: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
  speed: number;
  shield: number;
  alive: boolean;
  rageUntil: number;
}

export interface Obstacle {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface BlackHoleState {
  active: boolean;
  x: number;
  y: number;
  radius: number;
  reach: number;
  nextAt: number;
}

export interface BountyState {
  active: boolean;
  leader: number;
  lastLeader: number;
}

export interface TraitorMark {
  entityId: number;
  fromType: number;
  toType: number;
  startAt: number;
  triggerAt: number;
}

export interface ReviveMark {
  type: number;
  x: number;
  y: number;
  at: number;
}

export interface ThanosState {
  enabled: boolean;
  warned: boolean;
  active: boolean;
  snapped: boolean;
  nextAt: number;
  warningAt: number;
  snapAt: number;
  hideAt: number;
}

export interface ControlZone {
  x: number;
  y: number;
  radius: number;
  owner: number;
  score: number;
}

export interface GameBounds {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

export interface PowerUp {
  id: number;
  kind: PowerUpKind;
  x: number;
  y: number;
  radius: number;
  expiresAt: number;
}

export interface GameSnapshot {
  counts: number[];
  aliveTypes: number;
  timeLeftSec: number;
  status: string;
  eventText: string;
  eventId: number;
  eventKind: GameEventKind;
  winner: number;
  phase: GamePhase;
  bountyActive: boolean;
  bountyLeader: number;
  thanosVisible: boolean;
  thanosText: string;
  heroOverlayVisible: boolean;
  heroOverlayText: string;
  heroOverlaySubText: string;
  rageType: number;
  rageTimeLeftSec: number;
  rageProgress: number;
}

export interface NativeRenderState {
  width: number;
  height: number;
  bounds: GameBounds;
  options: NativeGameOptions;
  entities: Entity[];
  obstacles: Obstacle[];
  zones: ControlZone[];
  powerUps: PowerUp[];
  blackHole: BlackHoleState;
  bountyActive: boolean;
  bountyLeader: number;
  traitorMarks: TraitorMark[];
  lastTime: number;
  rageType: number;
  rageUntil: number;
  handActive: boolean;
  handPull: boolean;
  handX: number;
  handY: number;
}

export const FACTIONS: FactionInfo[] = [
  {
    id: 0,
    label: '石头',
    emoji: '🪨',
    color: '#d95c47',
    darkColor: '#873328'
  },
  {
    id: 1,
    label: '剪刀',
    emoji: '✂️',
    color: '#2c8f7f',
    darkColor: '#176055'
  },
  {
    id: 2,
    label: '布',
    emoji: '✋🏻',
    color: '#4e6edb',
    darkColor: '#263f99'
  }
];

export function defaultOptions(): NativeGameOptions {
  return {
    themeKey: 'rps',
    customLabels: ['', '', ''],
    counts: [7, 7, 7],
    durationSec: 60,
    deathmatch: false,
    tournament: false,
    bestOf: 3,
    winnerPenalty: 5,
    godHand: false,
    obstacles: false,
    shrink: false,
    bounty: false,
    blackHole: false,
    traitor: false,
    thanos: false,
    lastStand: false,
    controlZones: false,
    powerUps: false,
    teamPowerUps: false,
    tenAgainstOne: false,
    betting: false,
    stake: 100,
    notifications: true
  };
}

export function cloneOptions(options: NativeGameOptions): NativeGameOptions {
  return {
    themeKey: options.themeKey,
    customLabels: [
      options.customLabels[0] || '',
      options.customLabels[1] || '',
      options.customLabels[2] || ''
    ],
    counts: [options.counts[0], options.counts[1], options.counts[2]],
    durationSec: options.durationSec,
    deathmatch: options.deathmatch,
    tournament: options.tournament,
    bestOf: options.bestOf,
    winnerPenalty: options.winnerPenalty,
    godHand: options.godHand,
    obstacles: options.obstacles,
    shrink: options.shrink,
    bounty: options.bounty,
    blackHole: options.blackHole,
    traitor: options.traitor,
    thanos: options.thanos,
    lastStand: options.lastStand,
    controlZones: options.controlZones,
    powerUps: options.powerUps,
    teamPowerUps: options.teamPowerUps,
    tenAgainstOne: options.tenAgainstOne,
    betting: options.betting,
    stake: options.stake,
    notifications: options.notifications
  };
}

export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export function beats(a: number, b: number): boolean {
  return (a === 0 && b === 1) || (a === 1 && b === 2) || (a === 2 && b === 0);
}

export function preyType(type: number): number {
  return (type + 1) % TYPE_COUNT;
}

export function predatorType(type: number): number {
  return (type + 2) % TYPE_COUNT;
}
