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
  private lastStandMs: number = 0;
  private powerUpMs: number = 0;
  private shrinkMs: number = 0;
  private traitorMs: number = 0;
  private snapMs: number = 0;
  private obstacleMs: number = 0;
  private audioMs: number = 0;
  private hudMs: number = 0;
  private sfxCallCount: number = 0;
  private targetScanCount: number = 0;
  private collisionCheckCount: number = 0;
  private zoneInsideCount: number = 0;
  private blackHoleKillCount: number = 0;
  private lastStandEventCount: number = 0;
  private lastStandReviveCount: number = 0;
  private powerUpPickupCount: number = 0;
  private powerUpTeamEffectCount: number = 0;
  private powerUpActiveCount: number = 0;
  private shrinkPadding: number = 0;
  private traitorMarkCount: number = 0;
  private traitorConversionCount: number = 0;
  private snapRemovedCount: number = 0;
  private obstacleHitCount: number = 0;
  private conversionCount: number = 0;

  constructor(targetFps: number, enabled: boolean) {
    this.targetFps = targetFps;
    this.enabled = enabled;
  }

  collect(scale: RpsBattleScale, lineup: RpsBattleFactionCounts, frameIntervalMs: number, updateMs: number,
    drawMs: number, movementMs: number, targetSearchMs: number, collisionMs: number, conversionMs: number,
    resultMs: number, zoneMs: number, blackHoleMs: number, lastStandMs: number, powerUpMs: number,
    shrinkMs: number, traitorMs: number, snapMs: number, obstacleMs: number, audioMs: number, hudMs: number,
    sfxCalls: number,
    targetScanCount: number, collisionCheckCount: number, zoneInsideCount: number, blackHoleKillCount: number,
    lastStandEventCount: number, lastStandReviveCount: number, powerUpPickupCount: number,
    powerUpTeamEffectCount: number, powerUpActiveCount: number, shrinkPadding: number, traitorMarkCount: number,
    traitorConversionCount: number, snapRemovedCount: number, obstacleHitCount: number, entityCount: number,
    conversionDelta: number, totalConversions: number): void {
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
    this.lastStandMs += lastStandMs;
    this.powerUpMs += powerUpMs;
    this.shrinkMs += shrinkMs;
    this.traitorMs += traitorMs;
    this.snapMs += snapMs;
    this.obstacleMs += obstacleMs;
    this.audioMs += audioMs;
    this.hudMs += hudMs;
    this.sfxCallCount += sfxCalls;
    this.targetScanCount += targetScanCount;
    this.collisionCheckCount += collisionCheckCount;
    this.zoneInsideCount += zoneInsideCount;
    this.blackHoleKillCount += blackHoleKillCount;
    this.lastStandEventCount += lastStandEventCount;
    this.lastStandReviveCount += lastStandReviveCount;
    this.powerUpPickupCount += powerUpPickupCount;
    this.powerUpTeamEffectCount += powerUpTeamEffectCount;
    this.powerUpActiveCount += powerUpActiveCount;
    this.shrinkPadding += shrinkPadding;
    this.traitorMarkCount += traitorMarkCount;
    this.traitorConversionCount += traitorConversionCount;
    this.snapRemovedCount += snapRemovedCount;
    this.obstacleHitCount += obstacleHitCount;
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
        `lastStandMs=${(this.lastStandMs / frames).toFixed(2)}ms ` +
        `powerUpMs=${(this.powerUpMs / frames).toFixed(2)}ms ` +
        `shrinkMs=${(this.shrinkMs / frames).toFixed(2)}ms ` +
        `traitorMs=${(this.traitorMs / frames).toFixed(2)}ms ` +
        `snapMs=${(this.snapMs / frames).toFixed(2)}ms ` +
        `obstacleMs=${(this.obstacleMs / frames).toFixed(2)}ms ` +
        `audio=${(this.audioMs / frames).toFixed(2)}ms ` +
        `hud=${(this.hudMs / frames).toFixed(2)}ms ` +
        `sfx/frame=${(this.sfxCallCount / frames).toFixed(2)} ` +
        `target/frame=${(this.targetScanCount / frames).toFixed(0)} ` +
        `collision/frame=${(this.collisionCheckCount / frames).toFixed(0)} ` +
        `zoneInside/frame=${(this.zoneInsideCount / frames).toFixed(0)} ` +
        `blackHoleKills/frame=${(this.blackHoleKillCount / frames).toFixed(2)} ` +
        `lastStandEvents/frame=${(this.lastStandEventCount / frames).toFixed(2)} ` +
        `lastStandRevives/frame=${(this.lastStandReviveCount / frames).toFixed(2)} ` +
        `powerUpsActive=${(this.powerUpActiveCount / frames).toFixed(2)} ` +
        `powerUpsPicked/frame=${(this.powerUpPickupCount / frames).toFixed(2)} ` +
        `teamPowerUps/frame=${(this.powerUpTeamEffectCount / frames).toFixed(2)} ` +
        `shrinkPadding=${(this.shrinkPadding / frames).toFixed(1)} ` +
        `traitorMarks/frame=${(this.traitorMarkCount / frames).toFixed(2)} ` +
        `traitorConversions/frame=${(this.traitorConversionCount / frames).toFixed(2)} ` +
        `snapRemoved/frame=${(this.snapRemovedCount / frames).toFixed(2)} ` +
        `obstacleHits/frame=${(this.obstacleHitCount / frames).toFixed(2)} ` +
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
    this.lastStandMs = 0;
    this.powerUpMs = 0;
    this.shrinkMs = 0;
    this.traitorMs = 0;
    this.snapMs = 0;
    this.obstacleMs = 0;
    this.audioMs = 0;
    this.hudMs = 0;
    this.sfxCallCount = 0;
    this.targetScanCount = 0;
    this.collisionCheckCount = 0;
    this.zoneInsideCount = 0;
    this.blackHoleKillCount = 0;
    this.lastStandEventCount = 0;
    this.lastStandReviveCount = 0;
    this.powerUpPickupCount = 0;
    this.powerUpTeamEffectCount = 0;
    this.powerUpActiveCount = 0;
    this.shrinkPadding = 0;
    this.traitorMarkCount = 0;
    this.traitorConversionCount = 0;
    this.snapRemovedCount = 0;
    this.obstacleHitCount = 0;
    this.conversionCount = 0;
  }
}
