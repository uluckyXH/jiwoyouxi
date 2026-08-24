import { CoopAppSnapshot, GameRecord } from './GameModule';
import {
  ACHIEVEMENT_SCHEMA_VERSION,
  AchievementDefinition,
  AchievementFilter,
  AchievementGroupView,
  AchievementProgress,
  AchievementStatus,
  AchievementSummary,
  AchievementViewItem
} from './AchievementModule';
import {
  ACHIEVEMENT_DEFINITIONS,
  ACHIEVEMENT_GROUPS,
  ACHIEVEMENT_PRIMARY_GAME_IDS
} from './AchievementRegistry';

function isPrimaryGameId(gameId: string): boolean {
  return ACHIEVEMENT_PRIMARY_GAME_IDS.includes(gameId);
}

function normalizedCount(value: number): number {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.max(0, Math.floor(value));
}

function progressFor(snapshot: CoopAppSnapshot, achievementId: string): AchievementProgress | undefined {
  return snapshot.achievements.find((item: AchievementProgress) => item.achievementId === achievementId);
}

function progressValueForDefinition(snapshot: CoopAppSnapshot, definition: AchievementDefinition): number {
  if (definition.progressKind === 'totalSessions') {
    let total = 0;
    snapshot.records.forEach((record: GameRecord) => {
      if (isPrimaryGameId(record.gameId)) {
        total += normalizedCount(record.playCount);
      }
    });
    return total;
  }

  if (definition.progressKind === 'playedGames') {
    const playedGameIds: string[] = [];
    snapshot.records.forEach((record: GameRecord) => {
      if (isPrimaryGameId(record.gameId) && normalizedCount(record.playCount) > 0 &&
        !playedGameIds.includes(record.gameId)) {
        playedGameIds.push(record.gameId);
      }
    });
    return playedGameIds.length;
  }

  if (definition.progressKind === 'favoriteCount') {
    const favoriteGameIds: string[] = [];
    snapshot.favorites.forEach((gameId: string) => {
      if (isPrimaryGameId(gameId) && !favoriteGameIds.includes(gameId)) {
        favoriteGameIds.push(gameId);
      }
    });
    return favoriteGameIds.length;
  }

  return 0;
}

function maxProgress(definition: AchievementDefinition, previous: number, current: number): number {
  if (definition.target <= 0) {
    return normalizedCount(previous);
  }
  return Math.min(definition.target, Math.max(normalizedCount(previous), normalizedCount(current)));
}

function isRegisteredAchievementId(achievementId: string): boolean {
  return ACHIEVEMENT_DEFINITIONS.some((definition: AchievementDefinition) => definition.id === achievementId);
}

function copyProgress(progress: AchievementProgress): AchievementProgress {
  return {
    achievementId: progress.achievementId,
    current: normalizedCount(progress.current),
    unlockedAt: normalizedCount(progress.unlockedAt),
    notifiedAt: normalizedCount(progress.notifiedAt),
    isLegacyMigrated: progress.isLegacyMigrated === true
  };
}

export function synchronizeAchievementProgress(snapshot: CoopAppSnapshot, occurredAt: number): CoopAppSnapshot {
  const achievements: AchievementProgress[] = [];
  const isLegacyMigration = snapshot.achievementSchemaVersion < ACHIEVEMENT_SCHEMA_VERSION;
  ACHIEVEMENT_DEFINITIONS.forEach((definition: AchievementDefinition) => {
    const previous = progressFor(snapshot, definition.id);
    const current = progressValueForDefinition(snapshot, definition);
    const nextCurrent = maxProgress(definition, previous === undefined ? 0 : previous.current, current);
    let unlockedAt = previous === undefined ? 0 : normalizedCount(previous.unlockedAt);
    let isLegacyMigrated = previous !== undefined && previous.isLegacyMigrated === true;
    if (definition.target > 0 && nextCurrent >= definition.target && unlockedAt === 0) {
      unlockedAt = normalizedCount(occurredAt);
      isLegacyMigrated = isLegacyMigration;
    }
    achievements.push({
      achievementId: definition.id,
      current: nextCurrent,
      unlockedAt: unlockedAt,
      notifiedAt: previous === undefined ? 0 : normalizedCount(previous.notifiedAt),
      isLegacyMigrated: isLegacyMigrated
    });
  });

  snapshot.achievements.forEach((progress: AchievementProgress) => {
    if (!isRegisteredAchievementId(progress.achievementId)) {
      achievements.push(copyProgress(progress));
    }
  });

  return {
    records: snapshot.records.slice(),
    favorites: snapshot.favorites.slice(),
    recent: snapshot.recent.slice(),
    soundEnabled: snapshot.soundEnabled,
    hapticEnabled: snapshot.hapticEnabled,
    appearanceMode: snapshot.appearanceMode,
    achievementSchemaVersion: ACHIEVEMENT_SCHEMA_VERSION,
    achievements: achievements,
    recentAchievementEventIds: snapshot.recentAchievementEventIds.slice()
  };
}

export function achievementSummaryForSnapshot(snapshot: CoopAppSnapshot): AchievementSummary {
  let unlocked = 0;
  ACHIEVEMENT_DEFINITIONS.forEach((definition: AchievementDefinition) => {
    const progress = progressFor(snapshot, definition.id);
    if (progress !== undefined && progress.unlockedAt > 0) {
      unlocked += 1;
    }
  });
  return {
    unlocked: unlocked,
    total: ACHIEVEMENT_DEFINITIONS.length
  };
}

function viewItemFor(snapshot: CoopAppSnapshot, definition: AchievementDefinition): AchievementViewItem {
  const progress = progressFor(snapshot, definition.id);
  const current = progress === undefined ? 0 : normalizedCount(progress.current);
  const unlockedAt = progress === undefined ? 0 : normalizedCount(progress.unlockedAt);
  let status: AchievementStatus = 'locked';
  if (unlockedAt > 0) {
    status = 'unlocked';
  } else if (definition.target > 0) {
    status = 'inProgress';
  }
  return {
    definition: definition,
    current: current,
    target: definition.target,
    unlockedAt: unlockedAt,
    isLegacyMigrated: progress !== undefined && progress.isLegacyMigrated === true,
    status: status
  };
}

function matchesFilter(item: AchievementViewItem, filter: AchievementFilter): boolean {
  if (filter === 'all') {
    return true;
  }
  if (filter === 'unlocked') {
    return item.status === 'unlocked';
  }
  return item.status !== 'unlocked';
}

export function achievementGroupsForSnapshot(
  snapshot: CoopAppSnapshot,
  filter: AchievementFilter
): AchievementGroupView[] {
  const groups: AchievementGroupView[] = [];
  ACHIEVEMENT_GROUPS.forEach((group) => {
    const items: AchievementViewItem[] = [];
    ACHIEVEMENT_DEFINITIONS.forEach((definition: AchievementDefinition) => {
      if (definition.groupId === group.id) {
        const item = viewItemFor(snapshot, definition);
        if (matchesFilter(item, filter)) {
          items.push(item);
        }
      }
    });
    if (items.length > 0) {
      groups.push({
        definition: group,
        items: items
      });
    }
  });
  return groups;
}

export function achievementViewItemFor(
  snapshot: CoopAppSnapshot,
  achievementId: string
): AchievementViewItem | undefined {
  const definition = ACHIEVEMENT_DEFINITIONS.find((item: AchievementDefinition) => item.id === achievementId);
  if (definition === undefined) {
    return undefined;
  }
  return viewItemFor(snapshot, definition);
}
