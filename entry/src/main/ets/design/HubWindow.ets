import { common } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import { HubInsets, HubRect, hubInsets } from './HubLayout';

/** Hub-scoped observation. Game pages retain ownership of their own window policies. */
export class HubWindow {
  private host: window.Window | undefined = undefined;
  private disposed: boolean = false;
  private previousOrientation: window.Orientation = window.Orientation.UNSPECIFIED;
  private previousBars: window.SystemBarProperties | undefined = undefined;
  private appContext: common.ApplicationContext | undefined = undefined;
  private environmentId: number = -1;
  private dark: boolean = false;
  private mutations: Promise<void> = Promise.resolve();
  private releasing: Promise<void> = Promise.resolve();
  private toVp: (px: number) => number = (px: number): number => px;
  private changed: (insets: HubInsets, creases: HubRect[]) => void = () => {};
  private onChange = (): void => { this.measure(); };
  private onWindow = (event: window.WindowEventType): void => {
    if (event === window.WindowEventType.WINDOW_SHOWN) this.measure();
  };

  async attach(context: common.Context, toVp: (px: number) => number,
    changed: (insets: HubInsets, creases: HubRect[]) => void): Promise<void> {
    this.toVp = toVp;
    this.changed = changed;
    try {
      const host = await window.getLastWindow(context);
      if (this.disposed) return;
      this.host = host;
      this.appContext = context.getApplicationContext();
      try {
        this.environmentId = this.appContext.on('environment', {
          onConfigurationUpdated: () => this.measure(),
          onMemoryLevel: () => {}
        });
      } catch (_) {}
      this.previousOrientation = host.getPreferredOrientation();
      try { this.previousBars = host.getWindowSystemBarProperties(); } catch (_) {}
      host.on('avoidAreaChange', this.onChange);
      host.on('windowSizeChange', this.onChange);
      host.on('windowEvent', this.onWindow);
      try { display.on('foldStatusChange', this.onChange); } catch (_) {}
      try { display.on('change', this.onChange); } catch (_) {}
      this.mutations = host.setPreferredOrientation(window.Orientation.AUTO_ROTATION).catch(() => {});
      await this.mutations;
      if (this.disposed) return;
      this.updateBars();
      this.measure();
    } catch (error) {
      console.warn(`Hub window: ${error}`);
    }
  }

  setDark(dark: boolean): void {
    if (this.dark === dark) return;
    this.dark = dark;
    this.updateBars();
  }

  private updateBars(): void {
    if (this.host === undefined || this.disposed) return;
    const host = this.host;
    this.mutations = this.mutations.then(async (): Promise<void> => {
      if (this.disposed) return;
      await host.setWindowSystemBarProperties({
        statusBarContentColor: this.dark ? '#FFF2DF' : '#493326',
        navigationBarContentColor: this.dark ? '#FFF2DF' : '#493326'
      }).catch(() => {});
    });
  }

  measure(): void {
    const host = this.host;
    if (host === undefined || this.disposed) return;
    let insets = hubInsets();
    const creases: HubRect[] = [];
    try {
      const system = host.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const nav = host.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const cutout = host.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
      insets = {
        top: this.toVp(Math.max(system.topRect.height, cutout.topRect.height, nav.topRect.height)),
        bottom: this.toVp(Math.max(system.bottomRect.height, cutout.bottomRect.height, nav.bottomRect.height)),
        left: this.toVp(Math.max(system.leftRect.width, cutout.leftRect.width, nav.leftRect.width)),
        right: this.toVp(Math.max(system.rightRect.width, cutout.rightRect.width, nav.rightRect.width))
      };
    } catch (_) {}
    try {
      // API 15 multi-fold status values are checked numerically to keep the API 12 baseline.
      // 11/12 are expanded/closed combinations; 21/22/13/23 contain a half-folded hinge.
      const status = display.getFoldStatus();
      if (display.isFoldable() && status !== display.FoldStatus.FOLD_STATUS_EXPANDED &&
        status !== display.FoldStatus.FOLD_STATUS_FOLDED && status !== display.FoldStatus.FOLD_STATUS_UNKNOWN && status !== 11 && status !== 12) {
        const rect = host.getWindowProperties().windowRect;
        display.getCurrentFoldCreaseRegion().creaseRects.forEach((fold: display.Rect) => {
          creases.push({ x: this.toVp(fold.left - rect.left), y: this.toVp(fold.top - rect.top),
            width: this.toVp(fold.width), height: this.toVp(fold.height) });
        });
      }
    } catch (_) {}
    this.changed(insets, creases);
  }

  release(): Promise<void> {
    if (this.disposed) return this.releasing;
    this.disposed = true;
    const host = this.host;
    this.host = undefined;
    try { display.off('foldStatusChange', this.onChange); } catch (_) {}
    try { display.off('change', this.onChange); } catch (_) {}
    if (this.appContext !== undefined && this.environmentId >= 0) {
      this.appContext.off('environment', this.environmentId).catch(() => {});
      this.environmentId = -1;
    }
    if (host === undefined) return this.releasing;
    try { host.off('avoidAreaChange', this.onChange); } catch (_) {}
    try { host.off('windowSizeChange', this.onChange); } catch (_) {}
    try { host.off('windowEvent', this.onWindow); } catch (_) {}
    // The caller awaits this before mounting a game, including any in-flight window writes.
    this.releasing = this.mutations.then(async (): Promise<void> => {
      await host.setPreferredOrientation(this.previousOrientation).catch(() => {});
      if (this.previousBars !== undefined) {
        await host.setWindowSystemBarProperties(this.previousBars).catch(() => {});
      }
    });
    return this.releasing;
  }
}
