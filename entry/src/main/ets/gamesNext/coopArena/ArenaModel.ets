export const ARENA_ASSETS: string = 'gamesNext/coopArena/';
export const ARENA_WORLD: number = 720;
export const ARENA_RADIUS: number = 26;
export const ARENA_NAMES: string[] = ['石头', '剪刀', '布'];
export const ARENA_COLORS: string[] = ['#7099b0', '#e68c69', '#7fac77'];
export const ARENA_SKILLS: string[] = ['集结', '护阵', '风推'];
// Fixed openings calibrated with identical commands under all three chosen identities.
export const ARENA_MISSION_SEEDS: number[] = [72832,78681,73961,75474,76174,77145,77845,78816];
export interface ArenaPoint { x: number; y: number; }
export interface ArenaObstacle { x: number; y: number; radius: number; }
export interface ArenaConfig {
  mode: string; faction: number; mission: number; seed: number; counts: number[]; event: string;
}
export interface ArenaScenario {
  name: string; summary: string; rule: string; limit: number; target: number; skills: boolean[];
  obstacles: boolean; wind: boolean; traitor: boolean; shrink: boolean;
}
export interface ArenaEntity {
  id: number; faction: number; x: number; y: number; vx: number; vy: number;
  protectedUntil: number; shieldUntil: number; shield: number;
  rallyX: number; rallyY: number; rallyUntil: number; target: number; predator: number;
}
export interface ArenaEffect { kind: number; faction: number; x: number; y: number; at: number; }
export interface ArenaMoment { time: number; text: string; }
export interface ArenaSample { time: number; counts: number[]; scores: number[]; }
export interface ArenaRound {
  version: number; session: string; config: ArenaConfig; rng: number; tick: number; nextId: number;
  entities: ArenaEntity[]; counts: number[]; scores: number[]; owner: number; capturing: number; captureTime: number;
  readyAt: number[][]; windLeft: number[]; uses: number[][]; supplyLeft: number[]; lowSince: number[]; supplyDue: number[];
  conversions: number; traitorId: number; traitorAt: number; traitorDone: boolean; windX: number; windY: number;
  finished: boolean; winner: number; won: boolean; stars: number; reason: string; reported: boolean;
  moments: ArenaMoment[]; history: ArenaSample[];
}
export interface ArenaProfile {
  version: number; stars: number[]; rounds: number; wins: number; zoneRounds: number; zoneWins: number;
  lastSession: string; reducedMotion: boolean;
}
export interface ArenaSave { version: number; round: string; profile: ArenaProfile; config?: ArenaConfig; }
export function arenaProfile(): ArenaProfile {
  return { version: 1, stars: [0,0,0,0,0,0,0,0], rounds: 0, wins: 0, zoneRounds: 0, zoneWins: 0,
    lastSession: '', reducedMotion: false };
}
export function arenaBeats(a: number, b: number): boolean { return (a + 1) % 3 === b; }
export function arenaClamp(n: number, low: number, high: number): number { return Math.max(low, Math.min(high, n)); }
export function arenaLeader(values: number[]): number {
  const best = Math.max(values[0], values[1], values[2]);
  return best > 0 && values.filter((v: number): boolean => Math.abs(v - best) < 0.00001).length === 1 ? values.indexOf(best) : -1;
}
export function arenaHome(faction: number): ArenaPoint {
  const angle = -Math.PI / 2 + faction * Math.PI * 2 / 3;
  return { x: 360 + Math.cos(angle) * 235, y: 360 + Math.sin(angle) * 235 };
}
export function arenaDefaultConfig(): ArenaConfig {
  return { mode: 'classic', faction: 0, mission: 0, seed: 1, counts: [8,8,8], event: 'none' };
}
export const ARENA_MISSIONS: ArenaScenario[] = [
  { name: '第一声集合', summary: '集结队友，先拿到 60 据点分', rule: 'zones', limit: 90, target: 60,
    skills: [true,false,false], obstacles: false, wind: false, traitor: false, shrink: false },
  { name: '少数派出击', summary: '以 6 对 9 / 9，夺下据点', rule: 'zones', limit: 90, target: 100,
    skills: [true,true,true], obstacles: false, wind: false, traitor: false, shrink: false },
  { name: '守住这一刻', summary: '守住队友，存活到 45 秒', rule: 'survival', limit: 45, target: 0,
    skills: [false,true,true], obstacles: false, wind: false, traitor: false, shrink: false },
  { name: '绕过花盆', summary: '绕开花盆，抢占中心', rule: 'zones', limit: 90, target: 100,
    skills: [true,true,true], obstacles: true, wind: false, traitor: false, shrink: false },
  { name: '风口上的据点', summary: '留意风场预告，守住优势', rule: 'zones', limit: 90, target: 100,
    skills: [true,true,true], obstacles: false, wind: true, traitor: false, shrink: false },
  { name: '小心换队', summary: '留意换队倒计时，再夺据点', rule: 'zones', limit: 90, target: 100,
    skills: [true,true,true], obstacles: false, wind: false, traitor: true, shrink: false },
  { name: '最后一圈', summary: '边界渐渐收拢，60 秒内领先', rule: 'classic', limit: 60, target: 0,
    skills: [true,true,true], obstacles: false, wind: false, traitor: false, shrink: true },
  { name: '庭院决赛', summary: '穿过花盆，警惕换队', rule: 'zones', limit: 90, target: 100,
    skills: [true,true,true], obstacles: true, wind: false, traitor: true, shrink: false }
];
export function arenaScenario(config: ArenaConfig): ArenaScenario {
  if (config.mode === 'challenge') return ARENA_MISSIONS[config.mission];
  const zones = config.mode === 'zones';
  return { name: zones ? '据点争夺' : '快速乱斗', summary: zones ? '先到 100 据点分，或 90 秒后领先' : '清场获胜，或 60 秒后人数领先',
    rule: zones ? 'zones' : 'classic', limit: zones ? 90 : 60, target: zones ? 100 : 0,
    skills: [zones,zones,zones], obstacles: config.event === 'garden', wind: config.event === 'wind',
    traitor: config.event === 'traitor', shrink: config.event === 'shrink' };
}
export function arenaPractice(config: ArenaConfig): boolean {
  return config.mode !== 'challenge' && (config.event !== 'none' || config.counts[0] !== config.counts[1] || config.counts[1] !== config.counts[2]);
}
export function arenaConfigValid(c: ArenaConfig): boolean {
  return c !== null && c !== undefined && ['classic','zones','challenge'].includes(c.mode) && Number.isInteger(c.faction) && c.faction >= 0 && c.faction < 3 &&
    Number.isInteger(c.mission) && c.mission >= 0 && c.mission < 8 && Number.isInteger(c.seed) && c.seed > 0 && c.seed <= 4294967295 &&
    Array.isArray(c.counts) && c.counts.length === 3 && c.counts.every((n: number): boolean => Number.isInteger(n) && n >= 3 && n <= 20) &&
    ['none','garden','wind','traitor','shrink'].includes(c.event);
}
