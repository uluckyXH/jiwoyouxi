import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'WorldOfRPSNative', 'EntryAbility created');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'WorldOfRPSNative', 'EntryAbility destroyed');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      const mainWindow = windowStage.getMainWindowSync();
      mainWindow.setWindowLayoutFullScreen(true);
    } catch (error) {
      hilog.warn(DOMAIN, 'WorldOfRPSNative', 'Failed to enable fullscreen: %{public}s', JSON.stringify(error));
    }
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'WorldOfRPSNative', 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'WorldOfRPSNative', 'Content loaded');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'WorldOfRPSNative', 'Window stage destroyed');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'WorldOfRPSNative', 'App foreground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'WorldOfRPSNative', 'App background');
  }
}
