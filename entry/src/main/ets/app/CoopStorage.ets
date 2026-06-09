import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { CoopAppSnapshot, emptySnapshot, GameRecord } from '../shell/GameModule';

const STORE_NAME: string = 'chicken_coop_games';
const SNAPSHOT_KEY: string = 'snapshot';

export class CoopStorage {
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

  static async save(context: common.Context, snapshot: CoopAppSnapshot): Promise<void> {
    try {
      const store = await preferences.getPreferences(context, { name: STORE_NAME });
      await store.put(SNAPSHOT_KEY, JSON.stringify(CoopStorage.sanitize(snapshot)));
      await store.flush();
    } catch (error) {
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
      hapticEnabled: snapshot.hapticEnabled !== false
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
}
