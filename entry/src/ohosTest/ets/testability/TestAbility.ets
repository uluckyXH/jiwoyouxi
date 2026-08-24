import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { abilityDelegatorRegistry } from '@kit.TestKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { Hypium } from '@ohos/hypium';
import testsuite from '../test/List.test';

const ON_DESTROY_ERROR: number = -2;

export default class TestAbility extends UIAbility {
  private abilityDelegator: abilityDelegatorRegistry.AbilityDelegator =
    abilityDelegatorRegistry.getAbilityDelegator();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'RpsBattleTest', 'TestAbility onCreate');
    hilog.info(0x0000, 'RpsBattleTest', 'want: %{public}s', JSON.stringify(want));
    hilog.info(0x0000, 'RpsBattleTest', 'launchParam: %{public}s', JSON.stringify(launchParam));
    const argumentsValue: abilityDelegatorRegistry.AbilityDelegatorArgs =
      abilityDelegatorRegistry.getArguments();
    Hypium.hypiumTest(this.abilityDelegator, argumentsValue, testsuite);
  }

  onDestroy(): void {
    this.abilityDelegator.finishTest('TestAbility ended before the test suite completed.', ON_DESTROY_ERROR, () => {});
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('testability/pages/Index', () => {});
  }
}
