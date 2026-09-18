import { common } from '@kit.AbilityKit';
import { audio } from '@kit.AudioKit';
import { media } from '@kit.MediaKit';
import { BLOCK_ASSETS } from './BlockModel';

const EFFECTS: string[] = ['move', 'rotate', 'hold', 'drop', 'lock', 'clear', 'four', 'level', 'finish', 'tap'];

/** Own pool: no old-game sound changes, no BGM startup, no external media. */
export class BlockAudio {
  private pool: media.SoundPool | undefined = undefined;
  private ids: Map<string, number> = new Map<string, number>();
  private ready: Set<number> = new Set<number>();
  private streams: number[] = [];
  private context: common.Context | undefined = undefined;
  private openPaths: Set<string> = new Set<string>();
  private epoch: number = 0;
  private enabled: boolean = true;
  private disposed: boolean = false;
  private lastPlayed: Map<string, number> = new Map<string, number>();

  async init(context: common.Context): Promise<void> {
    this.context = context;
    try {
      const pool = await media.createSoundPool(6, {
        usage: audio.StreamUsage.STREAM_USAGE_GAME, rendererFlags: 0
      });
      if (this.disposed) { await pool.release(); return; }
      this.pool = pool;
      pool.on('loadComplete', (id: number) => { this.ready.add(id); });
      for (let i = 0; i < EFFECTS.length && !this.disposed; i += 1) {
        const path = `${BLOCK_ASSETS}audio/${EFFECTS[i]}.wav`;
        try {
          const fd = await context.resourceManager.getRawFd(path);
          this.openPaths.add(path);
          if (this.disposed) { await this.closePath(path); break; }
          // load() returns an ID before decoding completes; retain the raw descriptor
          // until releasing this game's pool, rather than closing it mid-decode.
          const id = await pool.load(fd.fd, fd.offset, fd.length);
          this.ids.set(EFFECTS[i], id);
        } catch (error) {
          console.warn(`Block Workshop sound unavailable: ${EFFECTS[i]} ${error}`);
        }
      }
    } catch (error) {
      console.warn(`Block Workshop audio init failed: ${error}`);
    }
  }

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
    if (!enabled) this.silence();
  }

  play(name: string): void {
    const pool = this.pool;
    const id = this.ids.get(name);
    const now = Date.now();
    if (this.disposed || !this.enabled || pool === undefined || id === undefined || !this.ready.has(id) ||
      now - (this.lastPlayed.get(name) ?? 0) < (name === 'move' ? 90 : 70)) return;
    this.lastPlayed.set(name, now);
    const epoch = this.epoch;
    pool.play(id, { loop: 0, rate: audio.AudioRendererRate.RENDER_RATE_NORMAL,
      leftVolume: 0.55, rightVolume: 0.55, priority: 1 }).then((stream: number) => {
      if (this.disposed || !this.enabled || epoch !== this.epoch) {
        pool.stop(stream).catch(() => {});
      } else {
        this.streams.push(stream);
        if (this.streams.length > 16) this.streams.shift();
      }
    }).catch((error: Error) => console.warn(`Block Workshop sound play failed: ${error}`));
  }

  silence(): void {
    this.epoch += 1;
    const pool = this.pool;
    if (pool !== undefined) this.streams.forEach((id: number) => { pool.stop(id).catch(() => {}); });
    this.streams = [];
  }

  private async closePath(path: string): Promise<void> {
    if (!this.openPaths.has(path) || this.context === undefined) return;
    this.openPaths.delete(path);
    try { await this.context.resourceManager.closeRawFd(path); } catch (_) {}
  }

  async release(): Promise<void> {
    this.disposed = true;
    this.silence();
    const pool = this.pool;
    this.pool = undefined;
    if (pool !== undefined) {
      try { await pool.release(); } catch (_) {}
    }
    const paths: string[] = Array.from(this.openPaths);
    for (let i = 0; i < paths.length; i += 1) await this.closePath(paths[i]);
    this.ids.clear();
    this.ready.clear();
  }
}
