export interface PigTarget {
  id: number;
  groupId: number;
  x: number;
  y: number;
  radius: number;
  alive: boolean;
}

export enum SlingBlockKind {
  SUPPORT = 'support',
  BEAM = 'beam'
}

export interface SlingBlock {
  id: number;
  groupId: number;
  kind: SlingBlockKind;
  x: number;
  y: number;
  blockWidth: number;
  blockHeight: number;
  hp: number;
  maxHp: number;
  color: string;
  hitFrames: number;
  offsetX: number;
  offsetY: number;
  vx: number;
  vy: number;
  rotation: number;
  angularVelocity: number;
  dynamic: boolean;
  visible: boolean;
}

export interface EggProjectile {
  active: boolean;
  x: number;
  y: number;
  vx: number;
  vy: number;
  resting: boolean;
}

export interface EggWorldBounds {
  left: number;
  right: number;
  top: number;
  ground: number;
  radius: number;
}

export enum EggBoundaryHit {
  NONE = 'none',
  LEFT = 'left',
  RIGHT = 'right',
  TOP = 'top',
  GROUND = 'ground'
}

export interface EggBoundaryResult {
  egg: EggProjectile;
  hit: EggBoundaryHit;
}
