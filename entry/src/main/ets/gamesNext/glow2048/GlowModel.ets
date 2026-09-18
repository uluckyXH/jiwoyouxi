export const GLOW_ASSETS: string = 'gamesNext/glow2048/';
export const GLOW_PLAY_HINT = '上下左右滑动 · 也可点按方向键';
export const GLOW_LOGO: string = 'app/game_logos/game_icon_chicken2048.svg';
export const GLOW_MAX_TILE: number = 1073741824;
export type GlowDirection = 'left' | 'right' | 'up' | 'down';
export interface GlowTile { id: number; value: number; index: number; }
export interface GlowMotion { id: number; value: number; from: number; to: number; }
export interface GlowTurn {
  moved: boolean; gain: number; motions: GlowMotion[]; tiles: GlowTile[];
  merged: number[]; spawned: number; previousMax: number;
}
export interface GlowSave {
  version: number; session: string; seed: number; nextId: number; tiles: GlowTile[];
  score: number; moves: number; streak: number; bestStreak: number;
  continued: boolean; ended: boolean; reported: boolean;
}
export function glowMax(tiles: GlowTile[]): number {
  return tiles.reduce((max: number, tile: GlowTile) => Math.max(max, tile.value), 0);
}
export function glowClone(tiles: GlowTile[]): GlowTile[] {
  return tiles.map((tile: GlowTile): GlowTile => ({ id: tile.id, value: tile.value, index: tile.index }));
}
export function glowRank(value: number): number { return Math.min(11, Math.max(1, Math.round(Math.log2(value)))); }
export function glowTarget(value: number): number { return Math.min(GLOW_MAX_TILE, Math.max(2048, value * 2)); }
