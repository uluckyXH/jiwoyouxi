import { common } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import { MineCrease, MineInsets } from './MineLayout';

export class MineWindow {
  private host: window.Window | undefined = undefined;
  private disposed: boolean = false;
  private previous: window.Orientation = window.Orientation.UNSPECIFIED;
  private previousBars: window.SystemBarProperties | undefined = undefined;
  private dark: boolean = false;
  private toVp: (px: number) => number = (px: number): number => px;
  private changed: (insets: MineInsets, crease: MineCrease) => void = () => {};
  private background: () => void = () => {};
  private onAvoid = (): void => { this.measure(); };
  private onFold = (): void => { this.measure(); };
  private onWindow = (event: window.WindowEventType): void => {
    if (event === window.WindowEventType.WINDOW_HIDDEN || event === window.WindowEventType.WINDOW_INACTIVE) {
      this.background();
    }
    if (event === window.WindowEventType.WINDOW_SHOWN) this.measure();
  };

  async attach(context: common.Context, toVp: (px: number) => number,
    changed: (insets: MineInsets, crease: MineCrease) => void, background: () => void): Promise<void> {
    this.toVp = toVp;
    this.changed = changed;
    this.background = background;
    try {
      const host = await window.getLastWindow(context);
      if (this.disposed) return;
      this.host = host;
      this.previous = host.getPreferredOrientation();
      try { this.previousBars = host.getWindowSystemBarProperties(); } catch (_) {}
      host.on('avoidAreaChange', this.onAvoid);
      host.on('windowEvent', this.onWindow);
      try { display.on('foldStatusChange', this.onFold); } catch (_) {}
      await host.setPreferredOrientation(window.Orientation.AUTO_ROTATION);
      // A quick route exit can happen while the orientation request is in flight.
      if (this.disposed) { await host.setPreferredOrientation(this.previous); return; }
      this.applyBars();
      this.measure();
    } catch (error) {
      console.warn(`Fruit Mine window setup: ${error}`);
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

  measure(): void {
    const host = this.host;
    if (this.disposed || host === undefined) return;
    let insets: MineInsets = { top: 24, bottom: 16, left: 0, right: 0 };
    let crease: MineCrease = { x: 0, y: 0, width: 0, height: 0 };
    try {
      const system = host.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const nav = host.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const cutout = host.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
      insets = {
        top: this.toVp(Math.max(system.topRect.height, cutout.topRect.height)),
        bottom: this.toVp(Math.max(system.bottomRect.height, nav.bottomRect.height, cutout.bottomRect.height)),
        left: this.toVp(Math.max(system.leftRect.width, nav.leftRect.width, cutout.leftRect.width)),
        right: this.toVp(Math.max(system.rightRect.width, nav.rightRect.width, cutout.rightRect.width))
      };
      if (display.isFoldable() && display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_HALF_FOLDED) {
        const region = display.getCurrentFoldCreaseRegion();
        const rect = host.getWindowProperties().windowRect;
        if (region.creaseRects.length > 0) {
          const fold = region.creaseRects[0];
          crease = { x: this.toVp(fold.left - rect.left), y: this.toVp(fold.top - rect.top),
            width: this.toVp(fold.width), height: this.toVp(fold.height) };
        }
      }
    } catch (error) {
      console.warn(`Fruit Mine safe area: ${error}`);
    }
    this.changed(insets, crease);
  }

  release(): void {
    this.disposed = true;
    const host = this.host;
    this.host = undefined;
    try { display.off('foldStatusChange', this.onFold); } catch (_) {}
    if (host === undefined) return;
    try {
      host.off('avoidAreaChange', this.onAvoid);
      host.off('windowEvent', this.onWindow);
      host.setPreferredOrientation(this.previous).catch(() => {});
      if (this.previousBars !== undefined) host.setWindowSystemBarProperties(this.previousBars).catch(() => {});
    } catch (_) {}
  }
}
