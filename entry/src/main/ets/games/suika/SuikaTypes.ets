export interface FruitDef {
  name: string;
  radius: number;
  color: string;
}

export interface FruitBody {
  id: number;
  level: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  bornAt: number;
  releasedAt: number;
  mergeLockedUntil: number;
}

export interface SuikaBounds {
  left: number;
  right: number;
  bottom: number;
}

export interface OverflowState {
  isOverflowing: boolean;
  overflowSince: number;
  shouldFinish: boolean;
}

export interface MergeOutcome {
  canMerge: boolean;
  nextLevel: number;
  scoreDelta: number;
  isFinalMerge: boolean;
}

export interface CollisionStepResult {
  fruits: FruitBody[];
  nextId: number;
  scoreDelta: number;
  didMerge: boolean;
  isFinalMerge: boolean;
  mergeLevel: number;
  mergeX: number;
  mergeY: number;
}

export const FRUITS: FruitDef[] = [
  { name: '小葡萄', radius: 13, color: '#8b5cf6' },
  { name: '蓝莓', radius: 17, color: '#3b82f6' },
  { name: '橘子', radius: 21, color: '#f97316' },
  { name: '苹果', radius: 26, color: '#ef4444' },
  { name: '桃子', radius: 31, color: '#fb7185' },
  { name: '哈密瓜', radius: 37, color: '#a3e635' },
  { name: '小西瓜', radius: 43, color: '#22c55e' },
  { name: '西瓜', radius: 50, color: '#16a34a' },
  { name: '大西瓜', radius: 58, color: '#15803d' },
  { name: '鸡冠西瓜', radius: 67, color: '#0f9f5f' },
  { name: '巨型鸡窝西瓜', radius: 77, color: '#047857' }
];
