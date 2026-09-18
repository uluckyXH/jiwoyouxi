import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { normalizePlayDays } from '../design/PlayActivity';
import {
  CoopAppSnapshot,
  emptySnapshot,
  GameRecord,
  normalizeAppearanceMode
} from '../shell/GameModule';
import { AchievementState, LegacyAchievementProgress } from '../shell/AchievementModule';
import { emptyAchievementState, normalizeAchievementState } from '../shell/AchievementEngine';

const STORE_NAME: string = 'chicken_coop_games';
const SNAPSHOT_KEY: string = 'snapshot';
const ACHIEVEMENT_STATE_KEY: string = 'achievement_state';

export class CoopStorage {
  static async loadPlayDays(context: common.Context): Promise<number[]> {
    try {
      const store = await preferences.getPreferences(context, { name: STORE_NAME });
      const raw = await store.get('play_days', '[]');
      return typeof raw === 'string' ? normalizePlayDays(JSON.parse(raw) as number[]) : [];
    } catch (_) {
      return [];
    }
  }

  static async savePlayDays(context: common.Context, days: number[]): Promise<boolean> {
    try {
      const store = await preferences.getPreferences(context, { name: STORE_NAME });
      const raw = await store.get('play_days', '[]');
      let previous: number[] = [];
      try {
        if (typeof raw === 'string') previous = normalizePlayDays(JSON.parse(raw) as number[]);
      } catch (_) {}
      // Daily activity is append-only, including after a temporary startup read failure.
      await store.put('play_days', JSON.stringify(normalizePlayDays(previous.concat(days))));
      await store.flush();
      return true;
    } catch (_) {
      return false;
    }
  }

  static async load(context: common.Context): Promise<CoopAppSnapshot> {
    try {
      const store = await preferences.getPreferences(context, { name: STORE_NAME });
      const raw = await store.get(SNAPSHOT_KEY, '');
      if (typeof raw === 'string' && raw.length > 0) {
        return CoopStorage.sanitize(JSON.parse(raw) as CoopAppSnapshot);
      }
    } catch (error) {
      return emptySnapshot();
    }
    return emptySnapshot();
  }

  static async save(context: common.Context, snapshot: CoopAppSnapshot): Promise<boolean> {
    try {
      const store = await preferences.getPreferences(context, { name: STORE_NAME });
      await store.put(SNAPSHOT_KEY, JSON.stringify(CoopStorage.sanitize(snapshot)));
      await store.flush();
      return true;
    } catch (error) {
      return false;
    }
  }

  static async loadAchievementState(context: common.Context): Promise<AchievementState> {
    try {
      const store = await preferences.getPreferences(context, { name: STORE_NAME });
      const raw = await store.get(ACHIEVEMENT_STATE_KEY, '');
      if (typeof raw === 'string' && raw.length > 0) {
        return normalizeAchievementState(JSON.parse(raw) as AchievementState);
      }
    } catch (error) {
      // A failed read is not an empty account; never overwrite existing badges.
      throw new Error('Unable to load achievement state.');
    }
    return emptyAchievementState();
  }

  static async saveAchievementState(context: common.Context, state: AchievementState): Promise<boolean> {
    try {
      const store = await preferences.getPreferences(context, { name: STORE_NAME });
      await store.put(ACHIEVEMENT_STATE_KEY, JSON.stringify(normalizeAchievementState(state)));
      await store.flush();
      return true;
    } catch (error) {
      return false;
    }
  }

  private static sanitize(snapshot: CoopAppSnapshot): CoopAppSnapshot {
    const fallback = emptySnapshot();
    if (snapshot === undefined || snapshot === null) {
      return fallback;
    }
    const records: GameRecord[] = [];
    if (Array.isArray(snapshot.records)) {
      snapshot.records.forEach((item: GameRecord) => {
        if (item !== undefined && typeof item.gameId === 'string') {
          records.push({
            gameId: item.gameId,
            highScore: Number.isFinite(item.highScore) ? Math.max(0, Math.floor(item.highScore)) : 0,
            playCount: Number.isFinite(item.playCount) ? Math.max(0, Math.floor(item.playCount)) : 0,
            lastPlayedAt: Number.isFinite(item.lastPlayedAt) ? Math.max(0, item.lastPlayedAt) : 0
          });
        }
      });
    }
    return {
      records: records,
      favorites: CoopStorage.stringArray(snapshot.favorites),
      recent: CoopStorage.stringArray(snapshot.recent),
      soundEnabled: snapshot.soundEnabled !== false,
      hapticEnabled: snapshot.hapticEnabled !== false,
      appearanceMode: normalizeAppearanceMode(snapshot.appearanceMode),
      achievementSchemaVersion: CoopStorage.schemaVersion(snapshot.achievementSchemaVersion),
      achievements: CoopStorage.achievementProgresses(snapshot.achievements),
      recentAchievementEventIds: CoopStorage.stringArray(snapshot.recentAchievementEventIds).slice(0, 32)
    };
  }

  private static stringArray(value: string[]): string[] {
    const result: string[] = [];
    if (!Array.isArray(value)) {
      return result;
    }
    value.forEach((item: string) => {
      if (typeof item === 'string' && !result.includes(item)) {
        result.push(item);
      }
    });
    return result;
  }

  private static schemaVersion(value: number): number {
    if (!Number.isFinite(value)) {
      return 0;
    }
    return Math.max(0, Math.floor(value));
  }

  private static achievementProgresses(value: LegacyAchievementProgress[]): LegacyAchievementProgress[] {
    const result: LegacyAchievementProgress[] = [];
    if (!Array.isArray(value)) {
      return result;
    }
    value.forEach((item: LegacyAchievementProgress) => {
      if (item === undefined || typeof item.achievementId !== 'string' || item.achievementId.length === 0) {
        return;
      }
      if (result.some((progress: LegacyAchievementProgress) => progress.achievementId === item.achievementId)) {
        return;
      }
      result.push({
        achievementId: item.achievementId,
        current: Number.isFinite(item.current) ? Math.max(0, Math.floor(item.current)) : 0,
        unlockedAt: Number.isFinite(item.unlockedAt) ? Math.max(0, Math.floor(item.unlockedAt)) : 0,
        notifiedAt: Number.isFinite(item.notifiedAt) ? Math.max(0, Math.floor(item.notifiedAt)) : 0,
        isLegacyMigrated: item.isLegacyMigrated === true
      });
    });
    return result;
  }
}
