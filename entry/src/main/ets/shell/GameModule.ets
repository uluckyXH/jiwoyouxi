import { ACHIEVEMENT_SCHEMA_VERSION, LegacyAchievementProgress } from './AchievementModule';

export interface GameModule {
  id: string;
  title: string;
  subtitle: string;
  icon: string;
  tags: string[];
  accent: string;
  highScoreLabel: string;
}

export interface GameRecord {
  gameId: string;
  highScore: number;
  playCount: number;
  lastPlayedAt: number;
}

export interface CoopAppSnapshot {
  records: GameRecord[];
  favorites: string[];
  recent: string[];
  soundEnabled: boolean;
  hapticEnabled: boolean;
  appearanceMode: string;
  achievementSchemaVersion: number;
  achievements: LegacyAchievementProgress[];
  recentAchievementEventIds: string[];
}

export const APPEARANCE_LIGHT: string = 'light';
export const APPEARANCE_DARK: string = 'dark';
export const APPEARANCE_SYSTEM: string = 'system';

export function normalizeAppearanceMode(value: string | undefined): string {
  return value === APPEARANCE_LIGHT || value === APPEARANCE_DARK ? value : APPEARANCE_SYSTEM;
}

// Keep the saved preference separate from the current system-resolved palette.
export function isDarkAppearance(mode: string, systemDark: boolean): boolean {
  const preference = normalizeAppearanceMode(mode);
  return preference === APPEARANCE_SYSTEM ? systemDark : preference === APPEARANCE_DARK;
}

export function emptySnapshot(): CoopAppSnapshot {
  return {
    records: [],
    favorites: [],
    recent: [],
    soundEnabled: true,
    hapticEnabled: true,
    appearanceMode: APPEARANCE_SYSTEM,
    achievementSchemaVersion: ACHIEVEMENT_SCHEMA_VERSION,
    achievements: [],
    recentAchievementEventIds: []
  };
}
