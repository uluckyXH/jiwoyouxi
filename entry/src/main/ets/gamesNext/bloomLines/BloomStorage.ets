import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

/** Versioned, isolated storage; writes are serialized to preserve the latest action. */
export class BloomStorage {
  private queue: Promise<boolean> = Promise.resolve(true);

  async load(context: common.Context): Promise<string> {
    const store = await preferences.getPreferences(context, { name: 'bloom_lines_v1' });
    const raw = await store.get('round', '');
    if (typeof raw !== 'string') { throw new Error('Bloom Lines save has an unexpected type.'); }
    return raw;
  }

  save(context: common.Context, raw: string): Promise<boolean> {
    this.queue = this.queue.then(async (): Promise<boolean> => {
      try {
        const store = await preferences.getPreferences(context, { name: 'bloom_lines_v1' });
        await store.put('round', raw);
        await store.flush();
        return true;
      } catch (error) {
        console.warn(`Bloom Lines save: ${error}`);
        return false;
      }
    });
    return this.queue;
  }
}
