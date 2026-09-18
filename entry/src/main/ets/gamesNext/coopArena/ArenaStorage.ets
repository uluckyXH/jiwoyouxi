import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

/** Serialized writes prevent an older autosave from overwriting a newer pause/restart. */
export class ArenaStorage {
  private queue: Promise<boolean> = Promise.resolve(true);
  lastLoadFailed: boolean = false;

  async load(context: common.Context): Promise<string> {
    this.lastLoadFailed = false;
    try {
      const store = await preferences.getPreferences(context, { name: 'coop_arena_next_v1' });
      const raw = await store.get('round', '');
      return typeof raw === 'string' ? raw : '';
    } catch (error) {
      this.lastLoadFailed = true;
      console.warn(`Coop Arena save load failed: ${error}`);
      return '';
    }
  }

  save(context: common.Context, raw: string): Promise<boolean> {
    this.queue = this.queue.then(async (): Promise<boolean> => {
      try {
        const store = await preferences.getPreferences(context, { name: 'coop_arena_next_v1' });
        await store.put('round', raw);
        await store.flush();
        return true;
      } catch (error) {
        console.warn(`Coop Arena save failed: ${error}`);
        return false;
      }
    });
    return this.queue;
  }
}
