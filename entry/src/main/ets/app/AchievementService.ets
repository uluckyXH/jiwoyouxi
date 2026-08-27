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
    return this.refresh(context);
  }

  async refresh(context: common.Context): Promise<AchievementState> {
    this.state = await CoopStorage.loadAchievementState(context);
    this.initialized = true;
    return this.currentState();
  }

  async report(context: common.Context, event: AchievementEvent): Promise<AchievementApplyResult> {
    if (!this.initialized) {
      await this.initialize(context);
    }
    const result = applyAchievementEvent(this.state, event);
    if (result.disposition === 'applied') {
      const didSave = await CoopStorage.saveAchievementState(context, result.state);
      if (!didSave) {
        throw new Error('Unable to persist achievement state.');
      }
    }
    this.state = result.state;
    return {
      state: this.currentState(),
      disposition: result.disposition,
      newlyUnlocked: result.newlyUnlocked.slice()
    };
  }

  async reset(context: common.Context): Promise<AchievementState> {
    if (!this.initialized) {
      await this.initialize(context);
    }
    const resetState = emptyAchievementState();
    const didSave = await CoopStorage.saveAchievementState(context, resetState);
    if (!didSave) {
      throw new Error('Unable to reset achievement state.');
    }
    this.state = resetState;
    return this.currentState();
  }

  currentState(): AchievementState {
    return normalizeAchievementState(this.state);
  }
}
