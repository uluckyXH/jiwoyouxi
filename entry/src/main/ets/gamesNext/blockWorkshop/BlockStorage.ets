import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

/** Serialized writes prevent an older autosave from overwriting a newer pause/restart. */
export class BlockStorage {
  private queue: Promise<boolean> = Promise.resolve(true);

  async load(context: common.Context): Promise<string> {
    try {
      const store = await preferences.getPreferences(context, { name: 'block_workshop_next_v1' });
      const raw = await store.get('round', '');
      return typeof raw === 'string' ? raw : '';
    } catch (error) {
      console.warn(`Block Workshop save load failed: ${error}`);
      return '';
    }
  }

  save(context: common.Context, raw: string): Promise<boolean> {
    this.queue = this.queue.then(async (): Promise<boolean> => {
      try {
        const store = await preferences.getPreferences(context, { name: 'block_workshop_next_v1' });
        await store.put('round', raw);
        await store.flush();
        return true;
      } catch (error) {
        console.warn(`Block Workshop save failed: ${error}`);
        return false;
      }
    });
    return this.queue;
  }
}
