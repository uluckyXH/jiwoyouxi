import { RpsBattleFactionCounts, RpsBattleScale } from './RpsBattleTypes';

const RPS_BATTLE_PERF_LOG_INTERVAL_MS: number = 1000;

export class RpsBattlePerformanceLogger {
  private targetFps: number;
  private enabled: boolean;
  private windowStartedAt: number = 0;
  private frameCount: number = 0;
  private frameIntervalMs: number = 0;
  private maxFrameIntervalMs: number = 0;
  private updateMs: number = 0;
  private drawMs: number = 0;
  private movementMs: number = 0;
  private targetSearchMs: number = 0;
  private collisionMs: number = 0;
  private conversionMs: number = 0;
  private resultMs: number = 0;
  private zoneMs: number = 0;
  private blackHoleMs: number = 0;
  private audioMs: number = 0;
  private hudMs: number = 0;
  private sfxCallCount: number = 0;
  private targetScanCount: number = 0;
  private collisionCheckCount: number = 0;
  private zoneInsideCount: number = 0;
  private blackHoleKillCount: number = 0;
  private conversionCount: number = 0;

  constructor(targetFps: number, enabled: boolean) {
    this.targetFps = targetFps;
    this.enabled = enabled;
  }

  collect(scale: RpsBattleScale, lineup: RpsBattleFactionCounts, frameIntervalMs: number, updateMs: number,
    drawMs: number, movementMs: number, targetSearchMs: number, collisionMs: number, conversionMs: number,
    resultMs: number, zoneMs: number, blackHoleMs: number, audioMs: number, hudMs: number, sfxCalls: number,
    targetScanCount: number, collisionCheckCount: number, zoneInsideCount: number, blackHoleKillCount: number,
    entityCount: number, conversionDelta: number, totalConversions: number): void {
    if (!this.enabled) {
      return;
    }
    const now = Date.now();
    if (this.windowStartedAt === 0) {
      this.windowStartedAt = now;
    }
    this.frameCount += 1;
    this.frameIntervalMs += frameIntervalMs;
    this.maxFrameIntervalMs = Math.max(this.maxFrameIntervalMs, frameIntervalMs);
    this.updateMs += updateMs;
    this.drawMs += drawMs;
    this.movementMs += movementMs;
    this.targetSearchMs += targetSearchMs;
    this.collisionMs += collisionMs;
    this.conversionMs += conversionMs;
    this.resultMs += resultMs;
    this.zoneMs += zoneMs;
    this.blackHoleMs += blackHoleMs;
    this.audioMs += audioMs;
    this.hudMs += hudMs;
    this.sfxCallCount += sfxCalls;
    this.targetScanCount += targetScanCount;
    this.collisionCheckCount += collisionCheckCount;
    this.zoneInsideCount += zoneInsideCount;
    this.blackHoleKillCount += blackHoleKillCount;
    this.conversionCount += conversionDelta;
    const elapsed = now - this.windowStartedAt;
    if (elapsed < RPS_BATTLE_PERF_LOG_INTERVAL_MS) {
      return;
    }
    const frames = Math.max(1, this.frameCount);
    const elapsedMs = Math.max(1, elapsed);
    console.info(
      `RpsBattlePerf loop=displaySync targetFps=${this.targetFps} ` +
        `scale=${scale} lineup=${lineup.rock}/${lineup.scissors}/${lineup.paper} ` +
        `entities=${entityCount} frames=${frames} ` +
        `fps=${(frames * 1000 / elapsedMs).toFixed(1)} ` +
        `interval=${(this.frameIntervalMs / frames).toFixed(1)}ms ` +
        `maxInterval=${this.maxFrameIntervalMs.toFixed(0)}ms ` +
        `update=${(this.updateMs / frames).toFixed(2)}ms ` +
        `draw=${(this.drawMs / frames).toFixed(2)}ms ` +
        `move=${(this.movementMs / frames).toFixed(2)}ms ` +
        `targetMs=${(this.targetSearchMs / frames).toFixed(2)}ms ` +
        `collisionMs=${(this.collisionMs / frames).toFixed(2)}ms ` +
        `convertMs=${(this.conversionMs / frames).toFixed(2)}ms ` +
        `resultMs=${(this.resultMs / frames).toFixed(2)}ms ` +
        `zoneMs=${(this.zoneMs / frames).toFixed(2)}ms ` +
        `blackHoleMs=${(this.blackHoleMs / frames).toFixed(2)}ms ` +
        `audio=${(this.audioMs / frames).toFixed(2)}ms ` +
        `hud=${(this.hudMs / frames).toFixed(2)}ms ` +
        `sfx/frame=${(this.sfxCallCount / frames).toFixed(2)} ` +
        `target/frame=${(this.targetScanCount / frames).toFixed(0)} ` +
        `collision/frame=${(this.collisionCheckCount / frames).toFixed(0)} ` +
        `zoneInside/frame=${(this.zoneInsideCount / frames).toFixed(0)} ` +
        `blackHoleKills/frame=${(this.blackHoleKillCount / frames).toFixed(2)} ` +
        `conversions/frame=${(this.conversionCount / frames).toFixed(2)} ` +
        `totalConversions=${totalConversions}`
    );
    this.reset(now);
  }

  reset(startedAt: number = 0): void {
    this.windowStartedAt = startedAt;
    this.frameCount = 0;
    this.frameIntervalMs = 0;
    this.maxFrameIntervalMs = 0;
    this.updateMs = 0;
    this.drawMs = 0;
    this.movementMs = 0;
    this.targetSearchMs = 0;
    this.collisionMs = 0;
    this.conversionMs = 0;
    this.resultMs = 0;
    this.zoneMs = 0;
    this.blackHoleMs = 0;
    this.audioMs = 0;
    this.hudMs = 0;
    this.sfxCallCount = 0;
    this.targetScanCount = 0;
    this.collisionCheckCount = 0;
    this.zoneInsideCount = 0;
    this.blackHoleKillCount = 0;
    this.conversionCount = 0;
  }
}
