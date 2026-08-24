import { UIAbility, Want } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, TestRunner } from '@kit.TestKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TEST_TAG: string = 'RpsBattleTest';
const TEST_ABILITY_NAME: string = 'TestAbility';

async function onAbilityCreateCallback(data: UIAbility): Promise<void> {
  hilog.info(0x0000, TEST_TAG, 'Test ability created: %{public}s', JSON.stringify(data));
}

async function onAbilityMonitorError(error: BusinessError): Promise<void> {
  hilog.error(0x0000, TEST_TAG, 'Test ability monitor error: %{public}s', JSON.stringify(error));
}

export default class OpenHarmonyTestRunner implements TestRunner {
  onPrepare(): void {
    hilog.info(0x0000, TEST_TAG, 'Preparing RPS battle native tests.');
  }

  async onRun(): Promise<void> {
    const abilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();
    const argumentsValue = abilityDelegatorRegistry.getArguments();
    const moduleName = argumentsValue.parameters['-m'];
    const monitor: abilityDelegatorRegistry.AbilityMonitor = {
      abilityName: TEST_ABILITY_NAME,
      onAbilityCreate: onAbilityCreateCallback,
      moduleName: moduleName
    };
    abilityDelegator.addAbilityMonitor(monitor, onAbilityMonitorError);
    const want: Want = {
      bundleName: argumentsValue.bundleName,
      abilityName: TEST_ABILITY_NAME,
      moduleName: moduleName
    };
    abilityDelegator.startAbility(want, (error: BusinessError, data: void): void => {
      if (error !== undefined && error.code !== 0) {
        hilog.error(0x0000, TEST_TAG, 'Failed to start test ability: %{public}s', JSON.stringify(error));
        return;
      }
      hilog.info(0x0000, TEST_TAG, 'Test ability started: %{public}s', JSON.stringify(data));
    });
  }
}
