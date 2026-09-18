import { FrameCallback } from '@kit.ArkUI';

/** One callback after native layout has painted the deal's starting position. */
export class FreecellFrame extends FrameCallback {
  private complete: () => void;
  constructor(complete: () => void) { super(); this.complete = complete; }
  onFrame(_time: number): void {}
  onIdle(_time: number): void { this.complete(); }
}
