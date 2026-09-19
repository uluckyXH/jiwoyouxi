import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

/** Versioned, isolated storage; writes are serialized to preserve the latest action. */
export class TangramStorage {
  private queue: Promise<boolean> = Promise.resolve(true);

  async load(context: common.Context): Promise<string> {
    const store = await preferences.getPreferences(context, { name: 'tangram_garden_v1' });
    const raw = await store.get('round', '');
    if (typeof raw !== 'string') throw new Error('Tangram save is not a string');
    return raw;
  }

  save(context: common.Context, raw: string): Promise<boolean> {
    this.queue = this.queue.then(async (): Promise<boolean> => {
      try {
        const store = await preferences.getPreferences(context, { name: 'tangram_garden_v1' });
        await store.put('round', raw);
        await store.flush();
        return true;
      } catch (error) {
        console.warn(`Tangram Garden save: ${error}`);
        return false;
      }
    });
    return this.queue;
  }
}
