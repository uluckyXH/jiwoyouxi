import { AchievementEvent } from './AchievementModule';
import { CoopAppSnapshot } from './GameModule';
import { achievementPrimaryFavoriteCount } from './AchievementRegistry';

export interface FavoriteSnapshotToggleResult {
  snapshot: CoopAppSnapshot;
  didAddFavorite: boolean;
}

export function favoriteSnapshotAfterToggle(
  snapshot: CoopAppSnapshot,
  gameId: string
): FavoriteSnapshotToggleResult {
  const favorites = snapshot.favorites.slice();
  const favoriteIndex = favorites.indexOf(gameId);
  const didAddFavorite = favoriteIndex < 0;
  if (favoriteIndex >= 0) {
    favorites.splice(favoriteIndex, 1);
  } else {
    favorites.unshift(gameId);
  }
  return {
    snapshot: {
      records: snapshot.records.slice(),
      favorites: favorites.slice(0, 12),
      recent: snapshot.recent.slice(),
      soundEnabled: snapshot.soundEnabled,
      hapticEnabled: snapshot.hapticEnabled,
      appearanceMode: snapshot.appearanceMode,
      achievementSchemaVersion: snapshot.achievementSchemaVersion,
      achievements: snapshot.achievements.slice(),
      recentAchievementEventIds: snapshot.recentAchievementEventIds.slice()
    },
    didAddFavorite: didAddFavorite
  };
}

export function favoriteSnapshotAfterPersist(
  previousSnapshot: CoopAppSnapshot,
  nextSnapshot: CoopAppSnapshot,
  didSave: boolean
): CoopAppSnapshot {
  return didSave ? nextSnapshot : previousSnapshot;
}

export function favoriteAchievementEventAfterPersist(
  didSave: boolean,
  didAddFavorite: boolean,
  favorites: string[],
  occurredAt: number,
  sequence: number
): AchievementEvent | undefined {
  if (!didSave || !didAddFavorite || !Number.isFinite(occurredAt) || occurredAt <= 0 ||
    !Number.isFinite(sequence) || sequence <= 0) {
    return undefined;
  }
  const favoriteCount = achievementPrimaryFavoriteCount(favorites);
  if (favoriteCount <= 0) {
    return undefined;
  }
  const identifier = `favorites:${Math.floor(occurredAt)}:${Math.floor(sequence)}`;
  return {
    eventId: identifier,
    sessionId: identifier,
    gameId: 'global',
    type: 'milestone',
    occurredAt: Math.floor(occurredAt),
    isOfficial: true,
    facts: [{ key: 'favoriteCount', value: favoriteCount }]
  };
}
