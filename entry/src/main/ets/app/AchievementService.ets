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
  private operationQueue: Promise<void> = Promise.resolve();

  initialize(context: common.Context): Promise<AchievementState> {
    return this.enqueue(() => this.refreshNow(context));
  }

  refresh(context: common.Context): Promise<AchievementState> {
    return this.enqueue(() => this.refreshNow(context));
  }

  report(context: common.Context, event: AchievementEvent): Promise<AchievementApplyResult> {
    return this.enqueue(() => this.reportNow(context, event));
  }

  reset(context: common.Context): Promise<AchievementState> {
    return this.enqueue(() => this.resetNow(context));
  }

  currentState(): AchievementState {
    return normalizeAchievementState(this.state);
  }

  private async refreshNow(context: common.Context): Promise<AchievementState> {
    this.state = await CoopStorage.loadAchievementState(context);
    this.initialized = true;
    return this.currentState();
  }

  private async reportNow(context: common.Context, event: AchievementEvent): Promise<AchievementApplyResult> {
    if (!this.initialized) {
      await this.refreshNow(context);
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

  private async resetNow(context: common.Context): Promise<AchievementState> {
    if (!this.initialized) {
      await this.refreshNow(context);
    }
    const resetState = emptyAchievementState();
    const didSave = await CoopStorage.saveAchievementState(context, resetState);
    if (!didSave) {
      throw new Error('Unable to reset achievement state.');
    }
    this.state = resetState;
    return this.currentState();
  }

  private enqueue<T>(operation: () => Promise<T>): Promise<T> {
    const task: Promise<T> = this.operationQueue.then(() => operation());
    this.operationQueue = task.then(() => undefined, () => undefined);
    return task;
  }
}
