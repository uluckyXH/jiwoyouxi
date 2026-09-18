import { common } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import { BlockCrease, BlockFold, BlockInsets } from './BlockLayout';

export class BlockWindow {
  private host: window.Window | undefined = undefined;
  private disposed: boolean = false;
  private previous: window.Orientation = window.Orientation.UNSPECIFIED;
  private previousBars: window.SystemBarProperties | undefined = undefined;
  private dark: boolean = false;
  private toVp: (px: number) => number = (px: number): number => px;
  private fold: BlockFold = { foldable: false, status: 0 };
  private insets: BlockInsets = { top: 24, bottom: 16, left: 0, right: 0 };
  private changed: (insets: BlockInsets, crease: BlockCrease, fold: BlockFold) => void = () => {};
  private background: () => void = () => {};
  private onAvoid = (): void => { this.measure(); };
  private onFold = (status: display.FoldStatus): void => {
    // The event is authoritative: a resize can arrive before getFoldStatus catches up.
    if (this.disposed) return;
    this.fold = { foldable: true, status: status };
    this.measure();
  };
  private onDisplayMode = (): void => { this.measure(); };
  private onWindow = (event: window.WindowEventType): void => {
    if (event === window.WindowEventType.WINDOW_HIDDEN || event === window.WindowEventType.WINDOW_INACTIVE) {
      this.background();
    }
    if (event === window.WindowEventType.WINDOW_SHOWN) this.measure(true);
  };

  async attach(context: common.Context, toVp: (px: number) => number,
    changed: (insets: BlockInsets, crease: BlockCrease, fold: BlockFold) => void,
    background: () => void): Promise<void> {
    this.toVp = toVp;
    this.changed = changed;
    this.background = background;
    this.measure(true);
    try { display.on('foldStatusChange', this.onFold); } catch (_) {}
    try { display.on('foldDisplayModeChange', this.onDisplayMode); } catch (_) {}
    try {
      const host = await window.getLastWindow(context);
      if (this.disposed) return;
      this.host = host;
      this.previous = host.getPreferredOrientation();
      try { this.previousBars = host.getWindowSystemBarProperties(); } catch (_) {}
      host.on('avoidAreaChange', this.onAvoid);
      host.on('windowEvent', this.onWindow);
      // Publish safe areas before waiting for the orientation change.
      this.measure();
      await host.setPreferredOrientation(window.Orientation.AUTO_ROTATION);
      // A quick route exit can happen while the orientation request is in flight.
      if (this.disposed) { await host.setPreferredOrientation(this.previous); return; }
      this.applyBars();
      this.measure();
    } catch (error) {
      console.warn(`Block Workshop window setup: ${error}`);
    }
  }

  setDark(dark: boolean): void {
    this.dark = dark;
    this.applyBars();
  }

  private applyBars(): void {
    const host = this.host;
    if (host === undefined || this.disposed) return;
    host.setWindowSystemBarProperties({ statusBarContentColor: this.dark ? '#FFF2DF' : '#3A4338',
      navigationBarContentColor: this.dark ? '#FFF2DF' : '#3A4338' }).then(() => {
        if (this.disposed && this.previousBars !== undefined) {
          host.setWindowSystemBarProperties(this.previousBars).catch(() => {});
        }
      }).catch(() => {});
  }

  measure(refreshFold: boolean = false): void {
    if (this.disposed) return;
    if (refreshFold) {
      try {
        const foldable = display.isFoldable();
        this.fold = { foldable: foldable, status: foldable ? display.getFoldStatus() : 0 };
      } catch (_) { /* Retain the last known fold status if the display service is unavailable. */ }
    }
    const host = this.host;
    let crease: BlockCrease = { x: 0, y: 0, width: 0, height: 0 };
    if (host === undefined) { this.changed(this.insets, crease, this.fold); return; }
    try {
      const system = host.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const nav = host.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const cutout = host.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
      this.insets = {
        top: this.toVp(Math.max(system.topRect.height, cutout.topRect.height)),
        bottom: this.toVp(Math.max(system.bottomRect.height, nav.bottomRect.height, cutout.bottomRect.height)),
        left: this.toVp(Math.max(system.leftRect.width, nav.leftRect.width, cutout.leftRect.width)),
        right: this.toVp(Math.max(system.rightRect.width, nav.rightRect.width, cutout.rightRect.width))
      };
    } catch (error) {
      console.warn(`Block Workshop safe area: ${error}`);
    }
    // Read crease geometry independently; layout decides playability from available space.
    try {
      if (this.fold.foldable && [3, 13, 21, 22, 23].includes(this.fold.status)) {
        const region = display.getCurrentFoldCreaseRegion();
        const rect = host.getWindowProperties().windowRect;
        if (region.creaseRects.length > 0) {
          const fold = region.creaseRects[0];
          crease = { x: this.toVp(fold.left - rect.left), y: this.toVp(fold.top - rect.top),
            width: this.toVp(fold.width), height: this.toVp(fold.height) };
        }
      }
    } catch (error) {
      console.warn(`Block Workshop crease: ${error}`);
    }
    this.changed(this.insets, crease, this.fold);
  }

  release(): void {
    this.disposed = true;
    const host = this.host;
    this.host = undefined;
    try { display.off('foldStatusChange', this.onFold); } catch (_) {}
    try { display.off('foldDisplayModeChange', this.onDisplayMode); } catch (_) {}
    if (host === undefined) return;
    try {
      host.off('avoidAreaChange', this.onAvoid);
      host.off('windowEvent', this.onWindow);
      host.setPreferredOrientation(this.previous).catch(() => {});
      if (this.previousBars !== undefined) host.setWindowSystemBarProperties(this.previousBars).catch(() => {});
    } catch (_) {}
  }
}
