import { RpsBattleShrinkBounds, RpsBattleShrinkState } from './RpsBattleTypes';

export const RPS_BATTLE_SHRINK_WARNING_SEC: number = 0;
export const RPS_BATTLE_SHRINK_DELAY_SEC: number = 4;
export const RPS_BATTLE_SHRINK_SPEED: number = 4.5;
export const RPS_BATTLE_SHRINK_MAX_PADDING_RATIO: number = 0.28;

export class RpsBattleShrinkSystem {
  private state: RpsBattleShrinkState | null = null;

  reset(boardWidth: number, boardHeight: number): void {
    const maxPadding = this.maxPaddingForBoard(boardWidth, boardHeight);
    this.state = {
      active: false,
      padding: 0,
      maxPadding: maxPadding,
      progress: 0,
      bounds: this.boundsForPadding(boardWidth, boardHeight, 0)
    };
  }

  clear(): void {
    this.state = null;
  }

  resize(boardWidth: number, boardHeight: number): void {
    if (this.state === null) {
      return;
    }
    const maxPadding = this.maxPaddingForBoard(boardWidth, boardHeight);
    this.state.maxPadding = maxPadding;
    this.state.padding = Math.min(this.state.padding, maxPadding);
    this.state.progress = maxPadding <= 0 ? 0 : this.state.padding / maxPadding;
    this.state.bounds = this.boundsForPadding(boardWidth, boardHeight, this.state.padding);
  }

  update(elapsedSec: number, dtSec: number, boardWidth: number, boardHeight: number): void {
    if (this.state === null) {
      return;
    }
    this.resize(boardWidth, boardHeight);
    if (elapsedSec >= RPS_BATTLE_SHRINK_WARNING_SEC) {
      this.state.active = true;
    }
    if (elapsedSec < RPS_BATTLE_SHRINK_DELAY_SEC) {
      return;
    }
    this.state.padding = Math.min(this.state.maxPadding,
      this.state.padding + Math.max(0, dtSec) * RPS_BATTLE_SHRINK_SPEED);
    this.state.progress = this.state.maxPadding <= 0 ? 0 : this.state.padding / this.state.maxPadding;
    this.state.bounds = this.boundsForPadding(boardWidth, boardHeight, this.state.padding);
  }

  currentBounds(boardWidth: number, boardHeight: number): RpsBattleShrinkBounds {
    if (this.state === null) {
      return {
        left: 0,
        top: 0,
        right: boardWidth,
        bottom: boardHeight
      };
    }
    return this.state.bounds;
  }

  snapshot(): RpsBattleShrinkState | null {
    if (this.state === null) {
      return null;
    }
    return {
      active: this.state.active,
      padding: this.state.padding,
      maxPadding: this.state.maxPadding,
      progress: this.state.progress,
      bounds: {
        left: this.state.bounds.left,
        top: this.state.bounds.top,
        right: this.state.bounds.right,
        bottom: this.state.bounds.bottom
      }
    };
  }

  private maxPaddingForBoard(boardWidth: number, boardHeight: number): number {
    return Math.max(0, Math.min(boardWidth, boardHeight) * RPS_BATTLE_SHRINK_MAX_PADDING_RATIO);
  }

  private boundsForPadding(boardWidth: number, boardHeight: number, padding: number): RpsBattleShrinkBounds {
    const safePadding = Math.max(0, padding);
    return {
      left: Math.min(safePadding, boardWidth * 0.38),
      top: Math.min(safePadding, boardHeight * 0.38),
      right: Math.max(boardWidth - safePadding, boardWidth * 0.62),
      bottom: Math.max(boardHeight - safePadding, boardHeight * 0.62)
    };
  }
}
