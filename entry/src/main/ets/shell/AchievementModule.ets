export const ACHIEVEMENT_SCHEMA_VERSION: number = 1;

export type AchievementFilter = 'all' | 'unlocked' | 'inProgress';
export type AchievementProgressKind = 'totalSessions' | 'playedGames' | 'favoriteCount' | 'none';
export type AchievementStatus = 'unlocked' | 'inProgress' | 'locked';

export interface AchievementProgress {
  achievementId: string;
  current: number;
  unlockedAt: number;
  notifiedAt: number;
  isLegacyMigrated: boolean;
}

export interface AchievementDefinition {
  id: string;
  groupId: string;
  gameId: string;
  title: string;
  summary: string;
  detail: string;
  placeholderSymbol: string;
  progressKind: AchievementProgressKind;
  target: number;
}

export interface AchievementGroupDefinition {
  id: string;
  title: string;
  gameId: string;
  placeholderSymbol: string;
}

export interface AchievementViewItem {
  definition: AchievementDefinition;
  current: number;
  target: number;
  unlockedAt: number;
  isLegacyMigrated: boolean;
  status: AchievementStatus;
}

export interface AchievementGroupView {
  definition: AchievementGroupDefinition;
  items: AchievementViewItem[];
}

export interface AchievementSummary {
  unlocked: number;
  total: number;
}
