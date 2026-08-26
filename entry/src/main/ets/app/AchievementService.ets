import { common } from '@kit.AbilityKit';
import {
  AchievementApplyResult,
  AchievementEvent,
  AchievementState
} from '../shell/AchievementModule';
import {
  applyAchievementEvent,
  emptyAchievementState,
  normalizeAchievementState
} from '../shell/AchievementEngine';
import { CoopStorage } from './CoopStorage';

export class AchievementService {
  private state: AchievementState = emptyAchievementState();
  private initialized: boolean = false;

  async initialize(context: common.Context): Promise<AchievementState> {
    this.state = await CoopStorage.loadAchievementState(context);
    this.initialized = true;
    return this.currentState();
  }

  async report(context: common.Context, event: AchievementEvent): Promise<AchievementApplyResult> {
    if (!this.initialized) {
      await this.initialize(context);
    }
    const result = applyAchievementEvent(this.state, event);
    this.state = result.state;
    if (result.disposition === 'applied') {
      await CoopStorage.saveAchievementState(context, this.state);
    }
    return {
      state: this.currentState(),
      disposition: result.disposition,
      newlyUnlocked: result.newlyUnlocked.slice()
    };
  }

  currentState(): AchievementState {
    return normalizeAchievementState(this.state);
  }
}
