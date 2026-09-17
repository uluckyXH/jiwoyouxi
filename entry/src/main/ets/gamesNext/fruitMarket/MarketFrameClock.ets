import displaySync from '@ohos.graphics.displaySync';

/** One render per display frame; no background timer competing with the compositor. */
export class MarketFrameClock {
  private sync: displaySync.DisplaySync | undefined = undefined;
  private timer: number = -1;
  private running: boolean = false;
  private generation: number = 0;

  start(frame: () => void): void {
    this.stop();
    this.running = true;
    const generation = this.generation;
    try {
      const sync = displaySync.create();
      this.sync = sync;
      sync.setExpectedFrameRateRange({ min: 30, max: 60, expected: 60 });
      sync.on('frame', () => { if (this.running && generation === this.generation) frame(); });
      sync.start();
    } catch (_) {
      this.releaseSync();
      this.generation += 1;
      const fallbackGeneration = this.generation;
      this.timer = setInterval(() => {
        if (this.running && fallbackGeneration === this.generation) frame();
      }, 1000 / 60);
    }
  }

  stop(): void {
    this.running = false;
    this.generation += 1;
    if (this.timer !== -1) { clearInterval(this.timer); this.timer = -1; }
    this.releaseSync();
  }

  private releaseSync(): void {
    const sync = this.sync;
    this.sync = undefined;
    if (sync === undefined) return;
    try { sync.stop(); } catch (_) {}
    try { sync.off('frame'); } catch (_) {}
  }
}
