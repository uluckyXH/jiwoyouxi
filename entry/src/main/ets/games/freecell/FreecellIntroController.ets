import { FreecellMotion } from './FreecellMotion';

export class FreecellIntroController {
  private warmupTimer: number = -1;
  private dealTimer: number = -1;

  startWarmupBudget(onTimeout: () => void): void {
    this.stopWarmupBudget();
    this.warmupTimer = setTimeout(() => {
      this.warmupTimer = -1;
      onTimeout();
    }, FreecellMotion.assetWarmupBudget);
  }

  stopWarmupBudget(): void {
    if (this.warmupTimer !== -1) {
      clearTimeout(this.warmupTimer);
      this.warmupTimer = -1;
    }
  }

  startDeal(lastRound: number, onRound: (round: number) => void, onComplete: () => void): void {
    this.stopDeal();
    this.dealTimer = setTimeout(() => {
      this.advanceDealRound(0, Math.max(0, lastRound), onRound, onComplete);
    }, FreecellMotion.dealStartDelay);
  }

  stopDeal(): void {
    if (this.dealTimer !== -1) {
      clearTimeout(this.dealTimer);
      this.dealTimer = -1;
    }
  }

  stop(): void {
    this.stopWarmupBudget();
    this.stopDeal();
  }

  private advanceDealRound(
    round: number,
    lastRound: number,
    onRound: (round: number) => void,
    onComplete: () => void
  ): void {
    onRound(round);
    if (round >= lastRound) {
      this.dealTimer = setTimeout(() => {
        this.dealTimer = -1;
        onComplete();
      }, FreecellMotion.dealCardDuration);
      return;
    }
    this.dealTimer = setTimeout(() => {
      this.advanceDealRound(round + 1, lastRound, onRound, onComplete);
    }, FreecellMotion.dealRoundInterval);
  }
}
