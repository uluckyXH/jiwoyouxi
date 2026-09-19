import { FrameCallback } from '@kit.ArkUI';

// A single callback after layout, never a persistent animation/frame loop.
export class BloomReflow extends FrameCallback {
  private complete: () => void;
  constructor(complete: () => void) {
    super();
    this.complete = complete;
  }
  onFrame(_time: number): void {}
  onIdle(_time: number): void { this.complete(); }
}
