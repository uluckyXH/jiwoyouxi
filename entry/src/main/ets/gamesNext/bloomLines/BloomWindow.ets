import { common } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import { BloomCrease, BloomInsets, bloomUsesCreases } from './BloomLayout';

export class BloomWindow {
  private host: window.Window | undefined = undefined;
  private disposed: boolean = false;
  private previous: window.Orientation = window.Orientation.UNSPECIFIED;
  private previousBars: window.SystemBarProperties | undefined = undefined;
  private dark: boolean = false;
  private toVp: (px: number) => number = (px: number): number => px;
  private changed: (insets: BloomInsets, creases: BloomCrease[]) => void = () => {};
  private background: () => void = () => {};
  private onChange = (): void => { this.measure(); };
  private onWindow = (event: window.WindowEventType): void => {
    if (this.disposed) return;
    if (event === window.WindowEventType.WINDOW_HIDDEN || event === window.WindowEventType.WINDOW_INACTIVE) {
      this.background();
    }
    if (event === window.WindowEventType.WINDOW_SHOWN) this.measure();
  };

  async attach(context: common.Context, toVp: (px: number) => number,
    changed: (insets: BloomInsets, creases: BloomCrease[]) => void, background: () => void): Promise<void> {
    this.toVp = toVp;
    this.changed = changed;
    this.background = background;
    try {
      const host = await window.getLastWindow(context);
      if (this.disposed) return;
      this.host = host;
      this.previous = host.getPreferredOrientation();
      try { this.previousBars = host.getWindowSystemBarProperties(); } catch (_) {}
      host.on('avoidAreaChange', this.onChange);
      host.on('windowSizeChange', this.onChange);
      host.on('windowEvent', this.onWindow);
      try { display.on('foldStatusChange', this.onChange); } catch (_) {}
      try { display.on('foldDisplayModeChange', this.onChange); } catch (_) {}
      try { display.on('change', this.onChange); } catch (_) {}
      await host.setPreferredOrientation(window.Orientation.AUTO_ROTATION);
      // A quick route exit can happen while the orientation request is in flight.
      if (this.disposed) { await host.setPreferredOrientation(this.previous); return; }
      this.applyBars();
      this.measure();
    } catch (error) {
      console.warn(`Bloom Lines window setup: ${error}`);
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
    let insets: BloomInsets = { top: 24, bottom: 16, left: 0, right: 0 };
    const creases: BloomCrease[] = [];
    try {
      const system = host.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const nav = host.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const cutout = host.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
      insets = {
        top: this.toVp(Math.max(system.topRect.height, cutout.topRect.height, nav.topRect.height)),
        bottom: this.toVp(Math.max(system.bottomRect.height, nav.bottomRect.height, cutout.bottomRect.height)),
        left: this.toVp(Math.max(system.leftRect.width, nav.leftRect.width, cutout.leftRect.width)),
        right: this.toVp(Math.max(system.rightRect.width, nav.rightRect.width, cutout.rightRect.width))
      };
    } catch (error) {
      console.warn(`Bloom Lines safe area: ${error}`);
    }
    // Read hinges independently: an unavailable avoid-area API must not suppress
    // folding updates, and a failed reading must clear an old hinge.
    try {
      if (display.isFoldable() && bloomUsesCreases(display.getFoldStatus())) {
        const region = display.getCurrentFoldCreaseRegion();
        const rect = host.getWindowProperties().windowRect;
        region.creaseRects.forEach((fold: display.Rect) => {
          creases.push({ x: this.toVp(fold.left - rect.left), y: this.toVp(fold.top - rect.top),
            width: this.toVp(fold.width), height: this.toVp(fold.height) });
        });
      }
    } catch (error) {
      console.warn(`Bloom Lines fold area: ${error}`);
    }
    this.changed(insets, creases);
  }

  release(): void {
    this.disposed = true;
    const host = this.host;
    this.host = undefined;
    try { display.off('foldStatusChange', this.onChange); } catch (_) {}
    try { display.off('foldDisplayModeChange', this.onChange); } catch (_) {}
    try { display.off('change', this.onChange); } catch (_) {}
    if (host === undefined) return;
    try { host.off('avoidAreaChange', this.onChange); } catch (_) {}
    try { host.off('windowSizeChange', this.onChange); } catch (_) {}
    try { host.off('windowEvent', this.onWindow); } catch (_) {}
    try {
      host.setPreferredOrientation(this.previous).catch(() => {});
      if (this.previousBars !== undefined) host.setWindowSystemBarProperties(this.previousBars).catch(() => {});
    } catch (_) {}
  }
}
