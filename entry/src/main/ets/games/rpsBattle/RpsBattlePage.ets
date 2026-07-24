import { common } from '@kit.AbilityKit';
import { displaySync } from '@kit.ArkGraphics2D';
import { NativeAudioService } from '../../services/AudioService';
import { RpsBattleCountdownOverlay } from './RpsBattleCountdownOverlay';
import { RpsBattleTheme } from './RpsBattleTheme';
import { RpsBattleEngine } from './RpsBattleEngine';
import { RpsBattleHud } from './RpsBattleHud';
import { RpsBattlePauseOverlay, RpsBattleResultOverlay } from './RpsBattleOverlay';
import { RpsBattlePerformanceLogger } from './RpsBattlePerformanceLogger';
import { RpsBattleRenderer } from './RpsBattleRenderer';
import { RpsBattleSetupScreen } from './RpsBattleSetupScreen';
import { RpsBattleTopBar } from './RpsBattleTopBar';
import {
  RPS_BATTLE_DURATION_SEC,
  RpsBattleControlZone,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleMechanicKey,
  RpsBattleMechanicSelection,
  RpsBattleModeKey,
  RpsBattlePhase,
  RpsBattleResult,
  RpsBattleScale,
  RpsBattleSnapPhase,
  RpsBattleSnapState,
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
import {
  rpsBattleDefaultMechanicSelection,
  rpsBattleToggleMechanicSelection
} from './RpsBattleModeConfig';

const RPS_BATTLE_TOP_BAR_HEIGHT: number = 88;
const RPS_BATTLE_TARGET_FPS: number = 60;
const RPS_BATTLE_MAX_FRAME_DELTA_MS: number = 50;
const RPS_BATTLE_HUD_SYNC_INTERVAL_MS: number = 100;
const RPS_BATTLE_COUNTDOWN_START: number = 3;
const RPS_BATTLE_COUNTDOWN_INTERVAL_MS: number = 1000;
const RPS_BATTLE_BGM_VOLUME: number = 0.38;
const RPS_BATTLE_SFX_VOLUME: number = 0.72;
const RPS_BATTLE_CONVERT_SOUND_INTERVAL_MS: number = 120;
const RPS_BATTLE_SNAP_WARNING_SOUND_VOLUME: number = 0.56;
const RPS_BATTLE_SNAP_RESOLVED_SOUND_VOLUME: number = 0.72;
const RPS_BATTLE_ENABLE_PERF_LOG: boolean = true;

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
  private performanceLogger: RpsBattlePerformanceLogger = new RpsBattlePerformanceLogger(
    RPS_BATTLE_TARGET_FPS,
    RPS_BATTLE_ENABLE_PERF_LOG
  );
  private displaySyncDriver: displaySync.DisplaySync | null = null;
  private displaySyncRunning: boolean = false;
  private displaySyncFrameHandler: ((info: displaySync.IntervalInfo) => void) | null = null;
  private hudTimer: number = -1;
  private countdownTimer: number = -1;
  private lastTickAt: number = 0;
  private lastFrameTimestamp: number = 0;
  private lastConvertSoundAt: number = 0;
  private lastSnapPhase: RpsBattleSnapPhase | '' = '';
  private runtimeElapsedSec: number = 0;
  private hasRecordedResult: boolean = false;
  private audioReady: boolean = false;
  private pendingBgm: boolean = false;
  private disposed: boolean = false;

  @State pageWidth: number = 390;
  @State pageHeight: number = 760;
  @State phase: RpsBattlePhase = 'setup';
  @State selectedThemeKey: RpsBattleThemeKey = 'rps';
  @State selectedModeKey: RpsBattleModeKey = 'classic';
  @State selectedMechanics: RpsBattleMechanicSelection = rpsBattleDefaultMechanicSelection('classic');
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
  @State isDeathmatch: boolean = false;
  @State snap: RpsBattleSnapState | null = null;
  @State countdownValue: number = RPS_BATTLE_COUNTDOWN_START;
  @State result: RpsBattleResult = rpsBattleInitialResult('rock');
  @State pausedFromPhase: RpsBattlePhase = 'playing';
  @State exitConfirmationPending: boolean = false;

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
      RpsBattleTopBar({
        phase: this.phase,
        requestExit: () => {
          this.requestExitToHub();
        },
        restartGame: () => {
          this.startGame();
        },
        pauseGame: () => {
          this.requestPause();
        },
        resumeGame: () => {
          this.resumeGame();
        }
      })
      .position({ x: 0, y: 0 })
      .zIndex(5)
      if (this.phase === 'paused') {
        RpsBattlePauseOverlay({
          exitConfirmationPending: this.exitConfirmationPending,
          resumeGame: () => {
            this.resumeGame();
          },
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
      if (this.phase === 'result') {
        RpsBattleResultOverlay({
          result: this.result,
          themeKey: this.selectedThemeKey,
          modeKey: this.selectedModeKey,
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
    RpsBattleSetupScreen({
      contentWidth: this.panelWidth(),
      selectedThemeKey: this.selectedThemeKey,
      selectedModeKey: this.selectedModeKey,
      mechanicSelection: this.selectedMechanics,
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
        this.selectedMechanics = rpsBattleDefaultMechanicSelection(modeKey);
      },
      toggleMechanic: (mechanicKey: RpsBattleMechanicKey) => {
        this.selectedMechanics = rpsBattleToggleMechanicSelection(
          this.selectedModeKey,
          this.selectedMechanics,
          mechanicKey
        );
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
        controlZone: this.controlZone,
        isDeathmatch: this.isDeathmatch,
        elapsedSec: this.elapsedSec,
        snap: this.snap
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
          color: RpsBattleTheme.boardShadowColor,
          offsetX: 0,
          offsetY: 5
        })
        .onReady(() => {
          this.drawFrame();
        })
      if (this.phase === 'countdown') {
        RpsBattleCountdownOverlay({
          boardWidth: this.boardWidth(),
          boardHeight: this.boardHeight(),
          countdownValue: this.countdownValue
        })
      }
    }
    .width(this.boardWidth())
    .height(this.boardHeight())
  }

  private startGame(): void {
    this.stopCountdown();
    this.stopLoop();
    this.stopHudLoop();
    this.pendingBgm = false;
    this.audioService.pauseBgm();
    this.pausedFromPhase = 'playing';
    this.exitConfirmationPending = false;
    const options = rpsBattleCreateOptions(
      this.lineupCounts,
      this.durationSec,
      this.selectedFaction,
      this.selectedModeKey,
      this.selectedMechanics
    );
    this.engine = new RpsBattleEngine(this.boardWidth(), this.boardHeight(), options);
    this.hasRecordedResult = false;
    this.runtimeElapsedSec = 0;
    this.elapsedSec = 0;
    this.timeLeftSec = options.durationSec;
    this.conversions = 0;
    this.controlZone = null;
    this.isDeathmatch = this.engine.isDeathmatch();
    this.snap = null;
    this.countdownValue = RPS_BATTLE_COUNTDOWN_START;
    this.result = rpsBattleInitialResult(this.selectedFaction);
    this.phase = 'countdown';
    this.syncHudFromEngine(0);
    this.drawFrame();
    this.lastTickAt = Date.now();
    this.lastConvertSoundAt = 0;
    this.lastSnapPhase = '';
    this.startCountdown();
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
    this.isDeathmatch = this.engine.isDeathmatch();
    this.phase = 'playing';
    this.lastTickAt = Date.now();
    this.lastFrameTimestamp = 0;
    this.lastConvertSoundAt = 0;
    this.performanceLogger.reset(this.lastTickAt);
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
    const audioStartedAt = Date.now();
    let audioMs = 0;
    let sfxCalls = 0;
    if (currentConversions > previousConversions) {
      if (this.playConvertSound()) {
        sfxCalls = 1;
      }
    }
    if (this.playSnapSound()) {
      sfxCalls += 1;
    }
    if (sfxCalls > 0) {
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
      this.performanceLogger.collect(
        this.selectedScale,
        this.lineupCounts,
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
        this.engine.lastStepLastStandMs(),
        this.engine.lastStepPowerUpMs(),
        this.engine.lastStepShrinkMs(),
        this.engine.lastStepTraitorMs(),
        this.engine.lastStepSnapMs(),
        this.engine.lastStepObstacleMs(),
        audioMs,
        hudMs,
        sfxCalls,
        this.engine.lastStepTargetScanCount(),
        this.engine.lastStepCollisionCheckCount(),
        this.engine.lastStepZoneInsideCount(),
        this.engine.lastStepBlackHoleKillCount(),
        this.engine.lastStepLastStandEventCount(),
        this.engine.lastStepLastStandReviveCount(),
        this.engine.lastStepPowerUpPickupCount(),
        this.engine.lastStepPowerUpTeamEffectCount(),
        this.engine.lastStepPowerUpActiveCount(),
        this.engine.lastStepShrinkPadding(),
        this.engine.lastStepTraitorMarkCount(),
        this.engine.lastStepTraitorConversionCount(),
        this.engine.lastStepSnapRemovedCount(),
        this.engine.lastStepObstacleHitCount(),
        this.engine.entityCount(),
        currentConversions - previousConversions,
        currentConversions
      );
      this.finishGame(result);
      return;
    }
    this.performanceLogger.collect(
      this.selectedScale,
      this.lineupCounts,
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
      this.engine.lastStepLastStandMs(),
      this.engine.lastStepPowerUpMs(),
      this.engine.lastStepShrinkMs(),
      this.engine.lastStepTraitorMs(),
      this.engine.lastStepSnapMs(),
      this.engine.lastStepObstacleMs(),
      audioMs,
      hudMs,
      sfxCalls,
      this.engine.lastStepTargetScanCount(),
      this.engine.lastStepCollisionCheckCount(),
      this.engine.lastStepZoneInsideCount(),
      this.engine.lastStepBlackHoleKillCount(),
      this.engine.lastStepLastStandEventCount(),
      this.engine.lastStepLastStandReviveCount(),
      this.engine.lastStepPowerUpPickupCount(),
      this.engine.lastStepPowerUpTeamEffectCount(),
      this.engine.lastStepPowerUpActiveCount(),
      this.engine.lastStepShrinkPadding(),
      this.engine.lastStepTraitorMarkCount(),
      this.engine.lastStepTraitorConversionCount(),
      this.engine.lastStepSnapRemovedCount(),
      this.engine.lastStepObstacleHitCount(),
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
    this.isDeathmatch = this.engine.isDeathmatch();
    this.snap = this.engine.snapSnapshot();
  }

  private finishGame(result: RpsBattleResult): void {
    this.stopCountdown();
    this.stopLoop();
    this.stopHudLoop();
    this.pendingBgm = false;
    this.audioService.pauseBgm();
    this.exitConfirmationPending = false;
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

  private requestPause(): void {
    this.exitConfirmationPending = false;
    this.pauseGame();
  }

  private requestExitToHub(): void {
    if (this.phase === 'setup' || this.phase === 'result') {
      this.leaveToHub();
      return;
    }
    this.exitConfirmationPending = true;
    if (this.phase === 'countdown') {
      this.stopCountdown();
      this.pausedFromPhase = 'countdown';
      this.phase = 'paused';
      return;
    }
    this.pauseGame();
  }

  private pauseGame(): void {
    if (this.phase !== 'playing') {
      return;
    }
    this.stopLoop();
    this.stopHudLoop();
    this.pendingBgm = false;
    this.audioService.pauseBgm();
    this.pausedFromPhase = 'playing';
    this.phase = 'paused';
  }

  private resumeGame(): void {
    if (this.phase !== 'paused') {
      return;
    }
    this.exitConfirmationPending = false;
    if (this.pausedFromPhase === 'countdown') {
      this.phase = 'countdown';
      this.startCountdown();
      return;
    }
    this.phase = 'playing';
    this.lastTickAt = Date.now();
    this.performanceLogger.reset(this.lastTickAt);
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
    this.pausedFromPhase = 'playing';
    this.exitConfirmationPending = false;
    this.engine = null;
    this.runtimeElapsedSec = 0;
    this.counts = rpsBattleEmptyCounts();
    this.elapsedSec = 0;
    this.timeLeftSec = this.durationSec;
    this.conversions = 0;
    this.controlZone = null;
    this.isDeathmatch = false;
    this.snap = null;
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
    this.exitConfirmationPending = false;
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
        this.selectedThemeKey, null, null, null, null, null, null, null, null);
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
      this.engine.blackHoleForRender(),
      this.engine.powerUpsForRender(),
      this.engine.lastStandForRender(),
      this.engine.shrinkForRender(),
      this.engine.traitorForRender(),
      this.engine.snapForRender(),
      this.engine.obstaclesForRender()
    );
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

  private playSnapSound(): boolean {
    if (this.engine === null) {
      return false;
    }
    const snap = this.engine.snapForRender();
    const phase: RpsBattleSnapPhase | '' = snap === null ? '' : snap.phase;
    if (phase === this.lastSnapPhase) {
      return false;
    }
    this.lastSnapPhase = phase;
    if (phase === 'warning') {
      this.audioService.play('warning', RPS_BATTLE_SNAP_WARNING_SOUND_VOLUME);
      return true;
    }
    if (phase === 'resolved') {
      this.audioService.play('power', RPS_BATTLE_SNAP_RESOLVED_SOUND_VOLUME);
      return true;
    }
    return false;
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
