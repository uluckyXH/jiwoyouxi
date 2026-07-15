import { common } from '@kit.AbilityKit';
import { displaySync } from '@kit.ArkGraphics2D';
import { NativeAudioService } from '../../services/AudioService';
import { RpsBattleTheme } from './RpsBattleTheme';
import { RpsBattleEngine } from './RpsBattleEngine';
import { RpsBattleHud } from './RpsBattleHud';
import { RpsBattlePauseOverlay, RpsBattleResultOverlay } from './RpsBattleOverlay';
import { RpsBattleRenderer } from './RpsBattleRenderer';
import { RpsBattleSetupPanel } from './RpsBattleSetupPanel';
import {
  RPS_BATTLE_DURATION_SEC,
  RpsBattleControlZone,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleModeKey,
  RpsBattlePhase,
  RpsBattleResult,
  RpsBattleScale,
  RpsBattleThemeKey
} from './RpsBattleTypes';
import {
  rpsBattleClampDuration,
  rpsBattleCountsFromValue,
  rpsBattleCreateOptions,
  rpsBattleEmptyCounts,
  rpsBattleInitialCountForScale,
  rpsBattleInitialResult,
  rpsBattleScaleForCounts,
  rpsBattleStepCount
} from './RpsBattleRules';

const RPS_BATTLE_TOP_BAR_CONTENT_PADDING_TOP: number = 34;
const RPS_BATTLE_TOP_BAR_HEIGHT: number = 88;
const RPS_BATTLE_TOP_ACTION_GROUP_WIDTH: number = 114;
const RPS_BATTLE_TOP_ACTION_BUTTON_WIDTH: number = 54;
const RPS_BATTLE_TARGET_FPS: number = 60;
const RPS_BATTLE_MAX_FRAME_DELTA_MS: number = 50;
const RPS_BATTLE_HUD_SYNC_INTERVAL_MS: number = 100;
const RPS_BATTLE_COUNTDOWN_START: number = 3;
const RPS_BATTLE_COUNTDOWN_INTERVAL_MS: number = 1000;
const RPS_BATTLE_BGM_VOLUME: number = 0.38;
const RPS_BATTLE_SFX_VOLUME: number = 0.72;
const RPS_BATTLE_CONVERT_SOUND_INTERVAL_MS: number = 120;
const RPS_BATTLE_ENABLE_PERF_LOG: boolean = true;
const RPS_BATTLE_PERF_LOG_INTERVAL_MS: number = 1000;

@Component
export struct RpsBattlePage {
  @Prop bestScore: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};

  private engine: RpsBattleEngine | null = null;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private renderer: RpsBattleRenderer = new RpsBattleRenderer();
  private audioService: NativeAudioService = new NativeAudioService();
  private displaySyncDriver: displaySync.DisplaySync | null = null;
  private displaySyncRunning: boolean = false;
  private displaySyncFrameHandler: ((info: displaySync.IntervalInfo) => void) | null = null;
  private hudTimer: number = -1;
  private countdownTimer: number = -1;
  private lastTickAt: number = 0;
  private lastFrameTimestamp: number = 0;
  private lastConvertSoundAt: number = 0;
  private runtimeElapsedSec: number = 0;
  private hasRecordedResult: boolean = false;
  private audioReady: boolean = false;
  private pendingBgm: boolean = false;
  private disposed: boolean = false;
  private perfWindowStartedAt: number = 0;
  private perfFrameCount: number = 0;
  private perfFrameIntervalMs: number = 0;
  private perfMaxFrameIntervalMs: number = 0;
  private perfUpdateMs: number = 0;
  private perfDrawMs: number = 0;
  private perfMovementMs: number = 0;
  private perfTargetSearchMs: number = 0;
  private perfCollisionMs: number = 0;
  private perfConversionMs: number = 0;
  private perfResultMs: number = 0;
  private perfZoneMs: number = 0;
  private perfBlackHoleMs: number = 0;
  private perfAudioMs: number = 0;
  private perfHudMs: number = 0;
  private perfSfxCallCount: number = 0;
  private perfTargetScanCount: number = 0;
  private perfCollisionCheckCount: number = 0;
  private perfZoneInsideCount: number = 0;
  private perfBlackHoleKillCount: number = 0;
  private perfConversionCount: number = 0;

  @State pageWidth: number = 390;
  @State pageHeight: number = 760;
  @State phase: RpsBattlePhase = 'setup';
  @State selectedThemeKey: RpsBattleThemeKey = 'rps';
  @State selectedModeKey: RpsBattleModeKey = 'classic';
  @State selectedFaction: RpsBattleFaction = 'rock';
  @State selectedScale: RpsBattleScale = 'standard';
  @State lineupCounts: RpsBattleFactionCounts = rpsBattleCountsFromValue(8);
  @State syncCounts: boolean = true;
  @State advancedLineupOpen: boolean = false;
  @State durationSec: number = RPS_BATTLE_DURATION_SEC;
  @State counts: RpsBattleFactionCounts = rpsBattleEmptyCounts();
  @State elapsedSec: number = 0;
  @State timeLeftSec: number = RPS_BATTLE_DURATION_SEC;
  @State conversions: number = 0;
  @State controlZone: RpsBattleControlZone | null = null;
  @State countdownValue: number = RPS_BATTLE_COUNTDOWN_START;
  @State result: RpsBattleResult = rpsBattleInitialResult('rock');

  aboutToAppear(): void {
    this.disposed = false;
    this.audioService.setBgmVolume(RPS_BATTLE_BGM_VOLUME);
    this.audioService.setSfxVolume(RPS_BATTLE_SFX_VOLUME);
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      this.audioService.init(context as common.Context).then(() => {
        if (this.disposed) {
          return;
        }
        this.audioReady = true;
        if (this.pendingBgm || this.phase === 'playing') {
          this.playBattleBgm();
        }
      });
    }
  }

  aboutToDisappear(): void {
    this.disposed = true;
    this.stopCountdown();
    this.stopHudLoop();
    this.releaseLoopDriver();
    this.audioService.pauseBgm();
    this.audioService.release();
  }

  build() {
    Stack() {
      this.BackgroundLayer()
      if (this.phase === 'setup') {
        this.SetupLayer()
      } else {
        this.PlayLayer()
      }
      this.TopBar()
      if (this.phase === 'paused') {
        RpsBattlePauseOverlay({
          resumeGame: () => {
            this.resumeGame();
          },
          restartGame: () => {
            this.startGame();
          },
          exitToHub: () => {
            this.leaveToHub();
          }
        })
        .zIndex(20)
      }
      if (this.phase === 'result') {
        RpsBattleResultOverlay({
          result: this.result,
          themeKey: this.selectedThemeKey,
          restartGame: () => {
            this.startGame();
          },
          backToSetup: () => {
            this.backToSetup();
          },
          exitToHub: () => {
            this.leaveToHub();
          }
        })
        .zIndex(20)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(RpsBattleTheme.pageBg)
    .onAreaChange((oldArea, newArea) => {
      const width = Number.parseFloat(`${newArea.width}`);
      const height = Number.parseFloat(`${newArea.height}`);
      if (!Number.isNaN(width) && !Number.isNaN(height)) {
        this.pageWidth = Math.max(280, width);
        this.pageHeight = Math.max(420, height);
        this.resizeEngine();
      }
    })
  }

  @Builder
  BackgroundLayer() {
    Stack() {
      Rect()
        .width('100%')
        .height('100%')
        .fill(RpsBattleTheme.pageBg)
      Rect()
        .width('100%')
        .height('100%')
        .fill(RpsBattleTheme.pageShade)
    }
    .width('100%')
    .height('100%')
    .zIndex(0)
  }

  @Builder
  SetupLayer() {
    Scroll() {
      Column() {
        RpsBattleSetupPanel({
          selectedThemeKey: this.selectedThemeKey,
          selectedModeKey: this.selectedModeKey,
          selectedFaction: this.selectedFaction,
          selectedScale: this.selectedScale,
          lineupCounts: this.lineupCounts,
          syncCounts: this.syncCounts,
          advancedLineupOpen: this.advancedLineupOpen,
          durationSec: this.durationSec,
          selectTheme: (themeKey: RpsBattleThemeKey) => {
            this.selectedThemeKey = themeKey;
          },
          selectMode: (modeKey: RpsBattleModeKey) => {
            this.selectedModeKey = modeKey;
          },
          selectFaction: (faction: RpsBattleFaction) => {
            this.selectedFaction = faction;
          },
          selectScale: (scale: RpsBattleScale) => {
            this.selectedScale = scale;
            this.lineupCounts = rpsBattleCountsFromValue(rpsBattleInitialCountForScale(scale));
          },
          selectDuration: (durationSec: number) => {
            this.durationSec = rpsBattleClampDuration(durationSec);
          },
          toggleSyncCounts: () => {
            this.syncCounts = !this.syncCounts;
          },
          toggleAdvancedLineup: () => {
            this.advancedLineupOpen = !this.advancedLineupOpen;
          },
          stepFactionCount: (faction: RpsBattleFaction, step: number) => {
            this.lineupCounts = rpsBattleStepCount(this.lineupCounts, faction, step, this.syncCounts);
            this.selectedScale = rpsBattleScaleForCounts(this.lineupCounts);
          },
          startGame: () => {
            this.startGame();
          }
        })
        .width(this.panelWidth())
        Blank()
          .height(16)
      }
      .width('100%')
      .constraintSize({ minHeight: '100%' })
      .padding({ left: 16, right: 16, top: RPS_BATTLE_TOP_BAR_HEIGHT + 24, bottom: 16 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .zIndex(1)
  }

  @Builder
  PlayLayer() {
    Column({ space: 10 }) {
      RpsBattleHud({
        themeKey: this.selectedThemeKey,
        counts: this.counts,
        timeLeftSec: this.timeLeftSec,
        supportFaction: this.selectedFaction,
        conversions: this.conversions,
        controlZone: this.controlZone
      })
      .width(this.boardWidth())

      this.ArenaView()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 12, right: 12, top: RPS_BATTLE_TOP_BAR_HEIGHT + 14, bottom: 12 })
    .alignItems(HorizontalAlign.Center)
    .zIndex(1)
  }

  @Builder
  ArenaView() {
    Stack({ alignContent: Alignment.Center }) {
      Canvas(this.context)
        .width(this.boardWidth())
        .height(this.boardHeight())
        .backgroundColor(RpsBattleTheme.arenaBg)
        .borderRadius(10)
        .border({ width: 2, color: RpsBattleTheme.arenaLine })
        .shadow({
          radius: 12,
          color: 'rgba(86,55,35,0.12)',
          offsetX: 0,
          offsetY: 5
        })
        .onReady(() => {
          this.drawFrame();
        })
      if (this.phase === 'countdown') {
        this.CountdownOverlay()
      }
    }
    .width(this.boardWidth())
    .height(this.boardHeight())
  }

  @Builder
  CountdownOverlay() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 4 }) {
        Text('开战')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.muted)
          .maxLines(1)
        Text(`${this.countdownValue}`)
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .height(76)
          .textAlign(TextAlign.Center)
      }
      .width(132)
      .height(126)
      .justifyContent(FlexAlign.Center)
      .borderRadius(18)
      .backgroundColor('rgba(255,248,232,0.82)')
      .border({ width: 1, color: RpsBattleTheme.panelLine })
      .shadow({
        radius: 18,
        color: 'rgba(42,26,16,0.18)',
        offsetX: 0,
        offsetY: 7
      })
    }
    .width(this.boardWidth())
    .height(this.boardHeight())
    .backgroundColor('rgba(247,239,217,0.22)')
  }

  @Builder
  TopBar() {
    Row({ space: 8 }) {
      this.TopBarButton('大厅', false, 66, () => {
        this.leaveToHub();
      })
      Text('石头剪刀布大作战')
        .width('100%')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.topButtonText)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .layoutWeight(1)
      if (this.phase === 'countdown' || this.phase === 'playing' || this.phase === 'paused') {
        Row({ space: 6 }) {
          this.TopBarButton('重开', false, RPS_BATTLE_TOP_ACTION_BUTTON_WIDTH, () => {
            this.startGame();
          })
          if (this.phase === 'playing' || this.phase === 'paused') {
            this.TopBarButton(this.phase === 'paused' ? '继续' : '暂停', this.phase === 'playing',
              RPS_BATTLE_TOP_ACTION_BUTTON_WIDTH, () => {
              if (this.phase === 'paused') {
                this.resumeGame();
              } else {
                this.pauseGame();
              }
            })
          }
        }
        .width(RPS_BATTLE_TOP_ACTION_GROUP_WIDTH)
        .height(36)
        .justifyContent(FlexAlign.End)
      } else {
        Blank()
          .width(RPS_BATTLE_TOP_ACTION_GROUP_WIDTH)
          .height(36)
      }
    }
    .position({ x: 0, y: 0 })
    .width('100%')
    .height(RPS_BATTLE_TOP_BAR_HEIGHT)
    .zIndex(5)
    .padding({ left: 12, right: 12, top: RPS_BATTLE_TOP_BAR_CONTENT_PADDING_TOP })
    .backgroundColor(RpsBattleTheme.topBarBg)
  }

  @Builder
  TopBarButton(label: string, primary: boolean, widthValue: number, action: () => void) {
    Row() {
      Text(label)
        .width('100%')
        .fontSize(this.topBarButtonFontSize(label, widthValue))
        .fontWeight(FontWeight.Bold)
        .fontColor(primary ? RpsBattleTheme.primaryButtonText : RpsBattleTheme.topButtonText)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
      .width(widthValue)
      .height(36)
      .borderRadius(8)
      .backgroundColor(primary ? RpsBattleTheme.primaryButtonBg : RpsBattleTheme.topButtonBg)
      .border({ width: 1, color: RpsBattleTheme.topButtonLine })
      .onClick(() => {
        action();
      })
  }

  private startGame(): void {
    this.stopCountdown();
    this.stopLoop();
    this.stopHudLoop();
    this.pendingBgm = false;
    this.audioService.pauseBgm();
    const options = rpsBattleCreateOptions(
      this.lineupCounts,
      this.durationSec,
      this.selectedFaction,
      this.selectedModeKey
    );
    this.engine = new RpsBattleEngine(this.boardWidth(), this.boardHeight(), options);
    this.hasRecordedResult = false;
    this.runtimeElapsedSec = 0;
    this.elapsedSec = 0;
    this.timeLeftSec = options.durationSec;
    this.conversions = 0;
    this.controlZone = null;
    this.countdownValue = RPS_BATTLE_COUNTDOWN_START;
    this.result = rpsBattleInitialResult(this.selectedFaction);
    this.phase = 'countdown';
    this.syncHudFromEngine(0);
    this.drawFrame();
    this.lastTickAt = Date.now();
    this.lastConvertSoundAt = 0;
    this.startCountdown();
  }

  private topBarButtonFontSize(label: string, widthValue: number): number {
    if (widthValue <= RPS_BATTLE_TOP_ACTION_BUTTON_WIDTH && label.length >= 2) {
      return 13;
    }
    return 14;
  }

  private startLoop(): void {
    if (this.displaySyncRunning) {
      return;
    }
    if (this.displaySyncDriver === null) {
      this.displaySyncDriver = displaySync.create();
      this.displaySyncDriver.setExpectedFrameRateRange({
        min: RPS_BATTLE_TARGET_FPS,
        max: RPS_BATTLE_TARGET_FPS,
        expected: RPS_BATTLE_TARGET_FPS
      });
    }
    if (this.displaySyncFrameHandler === null) {
      this.displaySyncFrameHandler = (info: displaySync.IntervalInfo): void => {
        this.step(info.timestamp);
      };
      this.displaySyncDriver.on('frame', this.displaySyncFrameHandler);
    }
    this.lastFrameTimestamp = 0;
    this.displaySyncDriver.start();
    this.displaySyncRunning = true;
  }

  private stopLoop(): void {
    if (this.displaySyncDriver !== null && this.displaySyncRunning) {
      this.displaySyncDriver.stop();
    }
    this.displaySyncRunning = false;
    this.lastFrameTimestamp = 0;
  }

  private releaseLoopDriver(): void {
    this.stopLoop();
    if (this.displaySyncDriver !== null) {
      if (this.displaySyncFrameHandler !== null) {
        this.displaySyncDriver.off('frame', this.displaySyncFrameHandler);
      } else {
        this.displaySyncDriver.off('frame');
      }
    }
    this.displaySyncFrameHandler = null;
    this.displaySyncDriver = null;
  }

  private startCountdown(): void {
    this.stopCountdown();
    this.countdownTimer = setInterval(() => {
      if (this.phase !== 'countdown') {
        this.stopCountdown();
        return;
      }
      if (this.countdownValue > 1) {
        this.countdownValue -= 1;
        return;
      }
      this.stopCountdown();
      this.beginBattle();
    }, RPS_BATTLE_COUNTDOWN_INTERVAL_MS);
  }

  private stopCountdown(): void {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = -1;
    }
  }

  private beginBattle(): void {
    if (this.phase !== 'countdown' || this.engine === null) {
      return;
    }
    this.runtimeElapsedSec = 0;
    this.elapsedSec = 0;
    this.timeLeftSec = this.engine.timeLeftSec(0);
    this.conversions = this.engine.conversionCount();
    this.phase = 'playing';
    this.lastTickAt = Date.now();
    this.lastFrameTimestamp = 0;
    this.lastConvertSoundAt = 0;
    this.resetPerformanceStats(this.lastTickAt);
    this.playBattleBgm();
    this.startLoop();
    this.startHudLoop();
  }

  private startHudLoop(): void {
    if (this.hudTimer !== -1) {
      return;
    }
    this.hudTimer = setInterval(() => {
      if (this.phase !== 'playing') {
        return;
      }
      this.syncHudFromEngine(this.runtimeElapsedSec);
    }, RPS_BATTLE_HUD_SYNC_INTERVAL_MS);
  }

  private stopHudLoop(): void {
    if (this.hudTimer !== -1) {
      clearInterval(this.hudTimer);
      this.hudTimer = -1;
    }
  }

  private step(frameTimestamp: number = 0): void {
    if (this.phase !== 'playing' || this.engine === null) {
      return;
    }
    const now = Date.now();
    const frameIntervalMs = this.resolveFrameIntervalMs(frameTimestamp, now);
    const dt = Math.max(0.001, Math.min(RPS_BATTLE_MAX_FRAME_DELTA_MS / 1000, frameIntervalMs / 1000));
    this.lastTickAt = now;
    this.runtimeElapsedSec += dt;
    const previousConversions = this.engine.conversionCount();
    const updateStartedAt = Date.now();
    const result = this.engine.update(dt, this.runtimeElapsedSec);
    const updateMs = Date.now() - updateStartedAt;
    const currentConversions = this.engine.conversionCount();
    let audioMs = 0;
    let sfxCalls = 0;
    if (currentConversions > previousConversions) {
      const audioStartedAt = Date.now();
      if (this.playConvertSound()) {
        sfxCalls = 1;
      }
      audioMs = Date.now() - audioStartedAt;
    }
    const drawStartedAt = Date.now();
    this.drawFrame();
    const drawMs = Date.now() - drawStartedAt;
    let hudMs = 0;
    if (result.finishReason !== 'none') {
      const hudStartedAt = Date.now();
      this.syncHudFromEngine(result.elapsedSec);
      hudMs = Date.now() - hudStartedAt;
      this.collectPerformanceStats(
        frameIntervalMs,
        updateMs,
        drawMs,
        this.engine.lastStepMovementMs(),
        this.engine.lastStepTargetSearchMs(),
        this.engine.lastStepCollisionMs(),
        this.engine.lastStepConversionMs(),
        this.engine.lastStepResultMs(),
        this.engine.lastStepZoneMs(),
        this.engine.lastStepBlackHoleMs(),
        audioMs,
        hudMs,
        sfxCalls,
        this.engine.lastStepTargetScanCount(),
        this.engine.lastStepCollisionCheckCount(),
        this.engine.lastStepZoneInsideCount(),
        this.engine.lastStepBlackHoleKillCount(),
        this.engine.entityCount(),
        currentConversions - previousConversions,
        currentConversions
      );
      this.finishGame(result);
      return;
    }
    this.collectPerformanceStats(
      frameIntervalMs,
      updateMs,
      drawMs,
      this.engine.lastStepMovementMs(),
      this.engine.lastStepTargetSearchMs(),
      this.engine.lastStepCollisionMs(),
      this.engine.lastStepConversionMs(),
      this.engine.lastStepResultMs(),
      this.engine.lastStepZoneMs(),
      this.engine.lastStepBlackHoleMs(),
      audioMs,
      hudMs,
      sfxCalls,
      this.engine.lastStepTargetScanCount(),
      this.engine.lastStepCollisionCheckCount(),
      this.engine.lastStepZoneInsideCount(),
      this.engine.lastStepBlackHoleKillCount(),
      this.engine.entityCount(),
      currentConversions - previousConversions,
      currentConversions
    );
  }

  private syncHudFromEngine(elapsedSec: number): void {
    if (this.engine === null) {
      return;
    }
    this.counts = this.engine.counts();
    this.elapsedSec = elapsedSec;
    this.timeLeftSec = this.engine.timeLeftSec(elapsedSec);
    this.conversions = this.engine.conversionCount();
    this.controlZone = this.engine.controlZoneSnapshot();
  }

  private finishGame(result: RpsBattleResult): void {
    this.stopCountdown();
    this.stopLoop();
    this.stopHudLoop();
    this.pendingBgm = false;
    this.audioService.pauseBgm();
    if (result.winner !== '') {
      this.audioService.play('win', 0.9);
    }
    this.result = result;
    this.phase = 'result';
    if (!this.hasRecordedResult && result.score > 0) {
      this.recordScore(result.score);
      this.hasRecordedResult = true;
    }
  }

  private pauseGame(): void {
    if (this.phase !== 'playing') {
      return;
    }
    this.stopLoop();
    this.stopHudLoop();
    this.pendingBgm = false;
    this.audioService.pauseBgm();
    this.phase = 'paused';
  }

  private resumeGame(): void {
    if (this.phase !== 'paused') {
      return;
    }
    this.phase = 'playing';
    this.lastTickAt = Date.now();
    this.resetPerformanceStats(this.lastTickAt);
    this.playBattleBgm();
    this.startLoop();
    this.startHudLoop();
  }

  private backToSetup(): void {
    this.stopCountdown();
    this.stopLoop();
    this.stopHudLoop();
    this.pendingBgm = false;
    this.audioService.pauseBgm();
    this.engine = null;
    this.runtimeElapsedSec = 0;
    this.counts = rpsBattleEmptyCounts();
    this.elapsedSec = 0;
    this.timeLeftSec = this.durationSec;
    this.conversions = 0;
    this.controlZone = null;
    this.countdownValue = RPS_BATTLE_COUNTDOWN_START;
    this.result = rpsBattleInitialResult(this.selectedFaction);
    this.phase = 'setup';
  }

  private leaveToHub(): void {
    this.stopCountdown();
    this.stopLoop();
    this.stopHudLoop();
    this.pendingBgm = false;
    this.audioService.pauseBgm();
    this.exitToHub();
  }

  private resizeEngine(): void {
    if (this.engine === null) {
      return;
    }
    this.engine.resize(this.boardWidth(), this.boardHeight());
    this.syncHudFromEngine(this.runtimeElapsedSec);
    this.drawFrame();
  }

  private drawFrame(): void {
    if (this.engine === null) {
      this.renderer.draw(this.context, this.boardWidth(), this.boardHeight(), [], this.runtimeElapsedSec,
        this.selectedThemeKey, null);
      return;
    }
    this.renderer.draw(
      this.context,
      this.boardWidth(),
      this.boardHeight(),
      this.engine.entitiesForRender(),
      this.runtimeElapsedSec,
      this.selectedThemeKey,
      this.engine.controlZoneForRender(),
      this.engine.blackHoleForRender()
    );
  }

  private collectPerformanceStats(frameIntervalMs: number, updateMs: number, drawMs: number,
    movementMs: number, targetSearchMs: number, collisionMs: number, conversionMs: number, resultMs: number,
    zoneMs: number, blackHoleMs: number, audioMs: number, hudMs: number, sfxCalls: number,
    targetScanCount: number, collisionCheckCount: number, zoneInsideCount: number, blackHoleKillCount: number,
    entityCount: number, conversionDelta: number, totalConversions: number): void {
    if (!RPS_BATTLE_ENABLE_PERF_LOG) {
      return;
    }
    const now = Date.now();
    if (this.perfWindowStartedAt === 0) {
      this.perfWindowStartedAt = now;
    }
    this.perfFrameCount += 1;
    this.perfFrameIntervalMs += frameIntervalMs;
    this.perfMaxFrameIntervalMs = Math.max(this.perfMaxFrameIntervalMs, frameIntervalMs);
    this.perfUpdateMs += updateMs;
    this.perfDrawMs += drawMs;
    this.perfMovementMs += movementMs;
    this.perfTargetSearchMs += targetSearchMs;
    this.perfCollisionMs += collisionMs;
    this.perfConversionMs += conversionMs;
    this.perfResultMs += resultMs;
    this.perfZoneMs += zoneMs;
    this.perfBlackHoleMs += blackHoleMs;
    this.perfAudioMs += audioMs;
    this.perfHudMs += hudMs;
    this.perfSfxCallCount += sfxCalls;
    this.perfTargetScanCount += targetScanCount;
    this.perfCollisionCheckCount += collisionCheckCount;
    this.perfZoneInsideCount += zoneInsideCount;
    this.perfBlackHoleKillCount += blackHoleKillCount;
    this.perfConversionCount += conversionDelta;
    const elapsed = now - this.perfWindowStartedAt;
    if (elapsed < RPS_BATTLE_PERF_LOG_INTERVAL_MS) {
      return;
    }
    const frames = Math.max(1, this.perfFrameCount);
    const elapsedMs = Math.max(1, elapsed);
    console.info(
      `RpsBattlePerf loop=displaySync targetFps=${RPS_BATTLE_TARGET_FPS} ` +
        `scale=${this.selectedScale} lineup=${this.lineupCounts.rock}/${this.lineupCounts.scissors}/${this.lineupCounts.paper} ` +
        `entities=${entityCount} frames=${frames} ` +
        `fps=${(frames * 1000 / elapsedMs).toFixed(1)} ` +
        `interval=${(this.perfFrameIntervalMs / frames).toFixed(1)}ms ` +
        `maxInterval=${this.perfMaxFrameIntervalMs.toFixed(0)}ms ` +
        `update=${(this.perfUpdateMs / frames).toFixed(2)}ms ` +
        `draw=${(this.perfDrawMs / frames).toFixed(2)}ms ` +
        `move=${(this.perfMovementMs / frames).toFixed(2)}ms ` +
        `targetMs=${(this.perfTargetSearchMs / frames).toFixed(2)}ms ` +
        `collisionMs=${(this.perfCollisionMs / frames).toFixed(2)}ms ` +
        `convertMs=${(this.perfConversionMs / frames).toFixed(2)}ms ` +
        `resultMs=${(this.perfResultMs / frames).toFixed(2)}ms ` +
        `zoneMs=${(this.perfZoneMs / frames).toFixed(2)}ms ` +
        `blackHoleMs=${(this.perfBlackHoleMs / frames).toFixed(2)}ms ` +
        `audio=${(this.perfAudioMs / frames).toFixed(2)}ms ` +
        `hud=${(this.perfHudMs / frames).toFixed(2)}ms ` +
        `sfx/frame=${(this.perfSfxCallCount / frames).toFixed(2)} ` +
        `target/frame=${(this.perfTargetScanCount / frames).toFixed(0)} ` +
        `collision/frame=${(this.perfCollisionCheckCount / frames).toFixed(0)} ` +
        `zoneInside/frame=${(this.perfZoneInsideCount / frames).toFixed(0)} ` +
        `blackHoleKills/frame=${(this.perfBlackHoleKillCount / frames).toFixed(2)} ` +
        `conversions/frame=${(this.perfConversionCount / frames).toFixed(2)} ` +
        `totalConversions=${totalConversions}`
    );
    this.resetPerformanceStats(now);
  }

  private resetPerformanceStats(startedAt: number = 0): void {
    this.perfWindowStartedAt = startedAt;
    this.perfFrameCount = 0;
    this.perfFrameIntervalMs = 0;
    this.perfMaxFrameIntervalMs = 0;
    this.perfUpdateMs = 0;
    this.perfDrawMs = 0;
    this.perfMovementMs = 0;
    this.perfTargetSearchMs = 0;
    this.perfCollisionMs = 0;
    this.perfConversionMs = 0;
    this.perfResultMs = 0;
    this.perfZoneMs = 0;
    this.perfBlackHoleMs = 0;
    this.perfAudioMs = 0;
    this.perfHudMs = 0;
    this.perfSfxCallCount = 0;
    this.perfTargetScanCount = 0;
    this.perfCollisionCheckCount = 0;
    this.perfZoneInsideCount = 0;
    this.perfBlackHoleKillCount = 0;
    this.perfConversionCount = 0;
  }

  private resolveFrameIntervalMs(frameTimestamp: number, now: number): number {
    if (frameTimestamp <= 0 || this.lastFrameTimestamp <= 0) {
      this.lastFrameTimestamp = frameTimestamp;
      return Math.max(0, now - this.lastTickAt);
    }
    const rawInterval = Math.max(0, frameTimestamp - this.lastFrameTimestamp);
    this.lastFrameTimestamp = frameTimestamp;
    if (rawInterval > 1000000) {
      return Math.min(RPS_BATTLE_MAX_FRAME_DELTA_MS, rawInterval / 1000000);
    }
    if (rawInterval > 1000) {
      return Math.min(RPS_BATTLE_MAX_FRAME_DELTA_MS, rawInterval / 1000);
    }
    return Math.min(RPS_BATTLE_MAX_FRAME_DELTA_MS, rawInterval);
  }

  private playBattleBgm(): void {
    if (!this.audioReady) {
      this.pendingBgm = true;
      return;
    }
    this.pendingBgm = false;
    this.audioService.setBgmVolume(RPS_BATTLE_BGM_VOLUME);
    this.audioService.playBgm();
  }

  private playConvertSound(): boolean {
    const now = Date.now();
    if (now - this.lastConvertSoundAt < RPS_BATTLE_CONVERT_SOUND_INTERVAL_MS) {
      return false;
    }
    this.lastConvertSoundAt = now;
    this.audioService.play('attack', 0.46);
    return true;
  }

  private panelWidth(): number {
    return Math.min(430, Math.max(280, this.pageWidth - 32));
  }

  private boardWidth(): number {
    return Math.min(430, Math.max(280, this.pageWidth - 24));
  }

  private boardHeight(): number {
    return Math.max(250, this.pageHeight - RPS_BATTLE_TOP_BAR_HEIGHT - 122);
  }

}
