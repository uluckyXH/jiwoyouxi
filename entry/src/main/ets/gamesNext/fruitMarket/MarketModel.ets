export const MARKET_WIDTH: number = 360;
export const MARKET_HEIGHT: number = 520;
export const MARKET_LEFT: number = 18;
export const MARKET_RIGHT: number = 342;
export const MARKET_FLOOR: number = 493;
export const MARKET_LINE: number = 110;
export const MARKET_STEP: number = 1 / 120;
export const MARKET_DROP_DELAY: number = 0.5;
export const MARKET_OVERFLOW_GRACE: number = 3;
export const MARKET_ASSETS: string = 'gamesNext/fruitMarket/';

export interface MarketFruit {
  name: string;
  radius: number;
  color: string;
  asset: string;
}

export const MARKET_FRUITS: MarketFruit[] = [
  { name: '小葡萄', radius: 13, color: '#9770c3', asset: '00_grape' },
  { name: '蓝莓', radius: 17, color: '#7598ca', asset: '01_blueberry' },
  { name: '橘子', radius: 21, color: '#efac51', asset: '02_orange' },
  { name: '苹果', radius: 26, color: '#e97e66', asset: '03_apple' },
  { name: '桃子', radius: 31, color: '#eea3a2', asset: '04_peach' },
  { name: '哈密瓜', radius: 37, color: '#d6bd7c', asset: '05_melon' },
  { name: '小西瓜', radius: 43, color: '#92bd69', asset: '06_small_watermelon' },
  { name: '西瓜', radius: 50, color: '#63a47b', asset: '07_watermelon' },
  { name: '大西瓜', radius: 58, color: '#458e68', asset: '08_big_watermelon' },
  { name: '鸡冠西瓜', radius: 67, color: '#44a681', asset: '09_rooster_watermelon' },
  { name: '巨型鸡窝西瓜', radius: 77, color: '#e9c36c', asset: '10_giant_watermelon' }
];

export function marketFruitPath(level: number): string {
  return `${MARKET_ASSETS}fruits/${MARKET_FRUITS[level].asset}.svg`;
}

export interface MarketBody {
  id: number;
  level: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  angle: number;
  born: number;
  unlock: number;
}

export interface MarketRound {
  version: number;
  sessionId: string;
  time: number;
  seed: number;
  nextId: number;
  drops: number;
  score: number;
  best: number;
  current: number;
  next: number;
  aim: number;
  readyAt: number;
  highest: number;
  merges: number;
  overflow: number;
  ended: boolean;
  reported: boolean;
  bodies: MarketBody[];
}

export interface MarketMerge {
  x: number;
  y: number;
  level: number;
  points: number;
  time: number;
}

export function marketMergeScore(level: number): number {
  return level >= 0 && level < 10 ? level + 1 + (level === 9 ? 100 : 0) : 0;
}
