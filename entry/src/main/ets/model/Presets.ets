import { cloneOptions, defaultOptions, NativeGameOptions } from './GameTypes';

export interface NativePreset {
  key: string;
  name: string;
  subtitle: string;
  summary: string;
}

export const PRESETS: NativePreset[] = [
  {
    key: 'classic',
    name: '经典大乱斗',
    subtitle: '死斗清场',
    summary: '三派同场，直到一方霸屏。'
  },
  {
    key: 'zones',
    name: '团队占点',
    subtitle: '据点 · 黑洞 · 绝地',
    summary: '抢占中心据点，弱势方有绝地求生机会。'
  },
  {
    key: 'traitor',
    name: '小心叛徒',
    subtitle: '缩圈 · 黑洞 · 叛徒',
    summary: '边界收缩，叛徒定时改写战局。'
  },
  {
    key: 'equality',
    name: '众生平等',
    subtitle: '响指 · 障碍 · 死斗',
    summary: '随机响指砍半人数，障碍物制造翻盘空间。'
  }
];

export function mobileBaseCount(width: number): number {
  return width > 760 ? 30 : 7;
}

export function presetOptions(key: string, width: number): NativeGameOptions {
  const options = cloneOptions(defaultOptions());
  const count = mobileBaseCount(width);
  options.counts = [count, count, count];

  if (key === 'classic') {
    options.deathmatch = true;
    return options;
  }
  if (key === 'zones') {
    options.controlZones = true;
    options.blackHole = true;
    options.lastStand = true;
    options.powerUps = true;
    options.teamPowerUps = true;
    return options;
  }
  if (key === 'traitor') {
    options.shrink = true;
    options.blackHole = true;
    options.traitor = true;
    options.deathmatch = true;
    return options;
  }
  if (key === 'equality') {
    options.thanos = true;
    options.obstacles = true;
    options.deathmatch = true;
    return options;
  }
  return options;
}
