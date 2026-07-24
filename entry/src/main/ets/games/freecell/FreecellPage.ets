import { common } from '@kit.AbilityKit';
import { CoopViewport } from '../../design/CoopViewport';
import { NativeAudioService } from '../../services/AudioService';
import {
  FREECELL_INTRO_ASSET_BACKGROUND,
  FREECELL_INTRO_ASSET_TITLE,
  FreecellAssetWarmup
} from './FreecellAssetWarmup';
import { FreecellBoard } from './FreecellBoard';
import { FreecellDecor } from './FreecellDecor';
import { FreecellHud } from './FreecellHud';
import { FreecellIntroController } from './FreecellIntroController';
import { FreecellIntroLayer } from './FreecellIntroLayer';
import {
  FREECELL_INTRO_HIDDEN_DEAL_ROUND,
  freecellIntroCanInteract,
  freecellIntroLastDealRound
} from './FreecellIntroRules';
import {
  FREECELL_INTRO_DEALING,
  FREECELL_INTRO_READY,
  FREECELL_INTRO_WAITING_LAYOUT,
  FREECELL_INTRO_WARMING_ASSETS,
  FreecellIntroPhase
} from './FreecellIntroTypes';
import { computeFreecellLayout } from './FreecellLayout';
import { FreecellMotion } from './FreecellMotion';
import { FreecellExitConfirmOverlay, FreecellGuideOverlay } from './FreecellPromptOverlay';
import { FreecellResultOverlay } from './FreecellResultOverlay';
import { FreecellTheme } from './FreecellTheme';
import { FreecellToolbar } from './FreecellToolbar';
import {
  FreecellLayout,
  FreecellLocation,
  FreecellMove,
  FreecellSnapshot,
  FreecellState
} from './FreecellTypes';
import {
  applyMove,
  cloneLocation,
  cloneMove,
  cloneState,
  collectHints,
  createSolvableGame,
  findAutoCompleteMove,
  findSafeFoundationMove,
  findSmartMove,
  gameStateKey,
  getMovableCards,
  hintKey,
  isWon,
  locationMatches,
  randomSeed
} from './FreecellRules';

const DOUBLE_TAP_MS: number = 360;

@Component
export struct FreecellPage {
  @Prop bestScore: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  private timer: number = -1;
  private toastTimer: number = -1;
  private autoTimer: number = -1;
  private autoVisited: string[] = [];
  private lastTapCardId: string = '';
  private lastTapAt: number = 0;
  private settled: boolean = false;
  private audioService: NativeAudioService = new NativeAudioService();
  private introController: FreecellIntroController = new FreecellIntroController();
  private introAssets: FreecellAssetWarmup = new FreecellAssetWarmup();
  @State pageWidth: number = CoopViewport.phoneDefaultWidth;
  @State pageHeight: number = CoopViewport.phoneDefaultHeight;
  @State gameState: FreecellState = createSolvableGame(randomSeed());
  @State history: FreecellSnapshot[] = [];
  @State recentMoves: FreecellMove[] = [];
  @State selectedLocation: FreecellLocation | null = null;
  @State hintMarks: FreecellLocation[] = [];
  @State lastHintKey: string = '';
  @State moves: number = 0;
  @State score: number = 0;
  @State elapsed: number = 0;
  @State started: boolean = false;
  @State autoRunning: boolean = false;
  @State toastText: string = '';
  @State toastVisible: boolean = false;
  @State won: boolean = false;
  @State showResultOverlay: boolean = false;
  @State showGuideOverlay: boolean = false;
  @State showExitConfirmOverlay: boolean = false;
  @State layoutReady: boolean = false;
  @State introPhase: FreecellIntroPhase = FREECELL_INTRO_WAITING_LAYOUT;
  @State introDealRound: number = FREECELL_INTRO_HIDDEN_DEAL_ROUND;
  @State introSceneVisible: boolean = false;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      this.audioService.init(context as common.Context);
    }
  }

  aboutToDisappear(): void {
    this.introController.stop();
    this.stopTimer();
    this.stopAutoComplete();
    this.clearToastTimer();
    this.audioService.release();
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(FreecellTheme.pageFallback)
        if (this.layoutReady) {
          FreecellIntroLayer({
            sceneVisible: this.introSceneVisible,
            backgroundReady: () => {
              this.handleIntroAssetReady(FREECELL_INTRO_ASSET_BACKGROUND);
            },
            backgroundFailed: () => {
              this.handleIntroAssetFailed(FREECELL_INTRO_ASSET_BACKGROUND);
            }
          })

          FreecellDecor({
            pageWidth: this.pageWidth,
            pageHeight: this.pageHeight,
            sceneVisible: this.introSceneVisible
          })

          FreecellBoard({
            pageWidth: this.pageWidth,
            pageHeight: this.pageHeight,
            state: this.gameState,
            selectedLocation: this.selectedLocation,
            hintMarks: this.hintMarks,
            introPhase: this.introPhase,
            introDealRound: this.introDealRound,
            interactionEnabled: this.canInteractWithGame(),
            tapSource: (source: FreecellLocation, cardId: string) => {
              this.handleSourceTap(source, cardId);
            },
            tapTarget: (target: FreecellLocation) => {
              this.handleTargetTap(target);
            },
            dropSource: (source: FreecellLocation, target: FreecellLocation) => {
              this.handleDrop(source, target);
            },
            skipIntro: () => {
              this.skipIntroDeal();
            },
            assetReady: (assetId: string) => {
              this.handleIntroAssetReady(assetId);
            },
            assetFailed: (assetId: string) => {
              this.handleIntroAssetFailed(assetId);
            }
          })

          FreecellHud({
            pageWidth: this.pageWidth,
            pageHeight: this.pageHeight,
            bestScore: this.bestScore,
            score: this.score,
            elapsed: this.elapsed,
            moves: this.moves,
            introSceneVisible: this.introSceneVisible,
            actionsEnabled: this.canInteractWithGame(),
            requestExit: () => {
              this.requestExitToHub();
            },
            undo: () => {
              this.undo();
            },
            hint: () => {
              this.showHint();
            },
            openGuide: () => {
              this.openGuide();
            },
            titleReady: () => {
              this.handleIntroAssetReady(FREECELL_INTRO_ASSET_TITLE);
            },
            titleFailed: () => {
              this.handleIntroAssetFailed(FREECELL_INTRO_ASSET_TITLE);
            }
          })

          FreecellToolbar({
            pageWidth: this.pageWidth,
            pageHeight: this.pageHeight,
            autoRunning: this.autoRunning,
            sceneVisible: this.introSceneVisible,
            actionsEnabled: this.canInteractWithGame(),
            newGame: () => {
              this.newGame();
            },
            undo: () => {
              this.undo();
            },
            autoMove: () => {
              this.toggleAutoComplete();
            },
            hint: () => {
              this.showHint();
            }
          })

          if (this.toastVisible) {
            this.ToastView()
          }

          if (this.won && this.showResultOverlay) {
            FreecellResultOverlay({
              score: this.currentScore(),
              moves: this.currentMoves(),
              elapsedText: this.timeText(),
              restartGame: () => {
                this.newGame();
              },
              exitToHub: () => {
                this.exitToHub();
              },
              closeOverlay: () => {
                this.showResultOverlay = false;
              }
            })
          }

          if (this.showGuideOverlay) {
            FreecellGuideOverlay({
              pageWidth: this.pageWidth,
              closeGuide: () => {
                this.closeGuide();
              }
            })
          }

          if (this.showExitConfirmOverlay) {
            FreecellExitConfirmOverlay({
              pageWidth: this.pageWidth,
              cancelExit: () => {
                this.cancelExitConfirm();
              },
              confirmExit: () => {
                this.confirmExitToHub();
              }
            })
          }
        }
      }
      .width(this.pageWidth)
      .height(this.pageHeight)
      .clip(true)
      .backgroundColor(FreecellTheme.pageFallback)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(FreecellTheme.pageFallback)
    .onAreaChange((oldArea, newArea) => {
      this.handlePageAreaChange(newArea);
    })
  }

  private handlePageAreaChange(newArea: Area): void {
    const width = Number.parseFloat(`${newArea.width}`);
    const height = Number.parseFloat(`${newArea.height}`);
    if (!Number.isNaN(width) && !Number.isNaN(height)) {
      const frame = CoopViewport.frame(width, height);
      this.pageWidth = frame.width;
      this.pageHeight = frame.height;
      this.layoutReady = true;
      this.beginIntroIfNeeded();
    }
  }

  @Builder
  ToastView() {
    Text(this.toastText)
      .width(this.toastWidth())
      .padding({ left: 12, right: 12, top: 9, bottom: 9 })
      .borderRadius(8)
      .backgroundColor(FreecellTheme.toastBg)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor('#fff7df')
      .lineHeight(18)
      .textAlign(TextAlign.Center)
      .position({ x: (this.pageWidth - this.toastWidth()) * 0.5, y: this.toastY() })
  }

  private beginIntroIfNeeded(): void {
    if (this.introPhase !== FREECELL_INTRO_WAITING_LAYOUT) {
      return;
    }
    this.introAssets.reset();
    this.introDealRound = FREECELL_INTRO_HIDDEN_DEAL_ROUND;
    this.introPhase = FREECELL_INTRO_WARMING_ASSETS;
    this.introController.startWarmupBudget(() => {
      this.finishIntroAsStatic();
    });
  }

  private handleIntroAssetReady(assetId: string): void {
    if (this.introPhase !== FREECELL_INTRO_WARMING_ASSETS) {
      return;
    }
    if (this.introAssets.markReady(assetId)) {
      this.startIntroDeal();
    }
  }

  private handleIntroAssetFailed(assetId: string): void {
    if (this.introPhase !== FREECELL_INTRO_WARMING_ASSETS) {
      return;
    }
    this.introAssets.markFailed(assetId);
    this.finishIntroAsStatic();
  }

  private startIntroDeal(): void {
    if (this.introPhase !== FREECELL_INTRO_WARMING_ASSETS) {
      return;
    }
    this.introController.stopWarmupBudget();
    this.introPhase = FREECELL_INTRO_DEALING;
    this.revealIntroScene();
    const lastRound = freecellIntroLastDealRound(this.gameState.tableau);
    this.introController.startDeal(lastRound, (round: number) => {
      if (this.introPhase === FREECELL_INTRO_DEALING) {
        this.introDealRound = round;
      }
    }, () => {
      this.completeIntroDeal();
    });
  }

  private completeIntroDeal(): void {
    if (this.introPhase !== FREECELL_INTRO_DEALING) {
      return;
    }
    this.introDealRound = freecellIntroLastDealRound(this.gameState.tableau);
    this.introPhase = FREECELL_INTRO_READY;
  }

  private skipIntroDeal(): void {
    if (this.introPhase === FREECELL_INTRO_DEALING) {
      this.finishIntroAsStatic();
    }
  }

  private finishIntroAsStatic(): void {
    if (this.introPhase === FREECELL_INTRO_READY) {
      return;
    }
    this.introController.stop();
    this.introDealRound = freecellIntroLastDealRound(this.gameState.tableau);
    this.introPhase = FREECELL_INTRO_READY;
    this.revealIntroScene();
  }

  private revealIntroScene(): void {
    if (this.introSceneVisible) {
      return;
    }
    this.getUIContext().animateTo({
      duration: FreecellMotion.sceneRevealDuration,
      curve: Curve.EaseOut
    }, () => {
      this.introSceneVisible = true;
    });
  }

  private canInteractWithGame(): boolean {
    return freecellIntroCanInteract(this.introPhase);
  }

  private handleSourceTap(source: FreecellLocation, cardId: string): void {
    if (!this.canInteractWithGame() || this.won) {
      return;
    }
    this.stopAutoComplete();
    const now = Date.now();
    if (this.lastTapCardId === cardId && now - this.lastTapAt <= DOUBLE_TAP_MS) {
      this.lastTapCardId = '';
      this.smartMove(source);
      return;
    }
    this.lastTapCardId = cardId;
    this.lastTapAt = now;

    if (this.selectedLocation !== null) {
      if (locationMatches(this.selectedLocation, source)) {
        this.smartMove(source);
        return;
      }
      const target = this.sourceAsTarget(source);
      if (target !== null && this.performMove(this.selectedLocation, target)) {
        return;
      }
    }

    const movableCards = getMovableCards(this.gameState, source);
    if (movableCards.length <= 0) {
      this.showToast('这组牌暂时不能整体移动');
      return;
    }
    this.selectedLocation = cloneLocation(source);
    this.hintMarks = [];
    this.lastHintKey = '';
    this.playClick();
  }

  private handleTargetTap(target: FreecellLocation): void {
    if (!this.canInteractWithGame() || this.won) {
      return;
    }
    this.stopAutoComplete();
    if (this.selectedLocation === null) {
      return;
    }
    this.performMove(this.selectedLocation, target);
  }

  private handleDrop(source: FreecellLocation, target: FreecellLocation): void {
    if (!this.canInteractWithGame() || this.won) {
      return;
    }
    this.stopAutoComplete();
    this.performMove(source, target);
  }

  private sourceAsTarget(source: FreecellLocation): FreecellLocation | null {
    if (source.area === 'tableau') {
      return { area: 'tableau', index: source.index };
    }
    if (source.area === 'freecell') {
      return { area: 'freecell', index: source.index };
    }
    return null;
  }

  private smartMove(source: FreecellLocation): void {
    const target = findSmartMove(this.gameState, source);
    if (target === null) {
      this.selectedLocation = cloneLocation(source);
      this.showToast('暂时没有更合适的位置');
      return;
    }
    this.performMove(source, target);
  }

  private performMove(source: FreecellLocation, target: FreecellLocation): boolean {
    if (!this.canInteractWithGame()) {
      return false;
    }
    const nextState = cloneState(this.gameState);
    const before = this.snapshot();
    const move = applyMove(nextState, source, target);
    if (move === null) {
      this.showToast('不能移动到这里');
      return false;
    }

    const history = this.history.slice();
    history.push(before);
    if (history.length > 100) {
      history.shift();
    }
    this.history = history;

    const recent = this.recentMoves.map((item: FreecellMove) => cloneMove(item));
    recent.push(cloneMove(move));
    if (recent.length > 8) {
      recent.shift();
    }
    this.recentMoves = recent;

    this.moves = history.length;
    this.score = this.scoreForState(nextState);
    this.ensureStarted();
    this.gameState = nextState;
    this.selectedLocation = null;
    this.hintMarks = [];
    this.lastHintKey = '';
    this.playClick();
    this.checkWin();
    return true;
  }

  private showHint(): void {
    if (!this.canInteractWithGame() || this.won) {
      return;
    }
    this.stopAutoComplete();
    const hints = collectHints(this.gameState, this.recentMoves, this.lastHintKey);
    this.playHint();
    if (hints.length <= 0) {
      this.hintMarks = [];
      this.lastHintKey = '';
      this.showToast('暂时没有明显可走的牌');
      return;
    }
    const hint = hints[0];
    this.hintMarks = [cloneLocation(hint.source), cloneLocation(hint.target)];
    this.lastHintKey = hintKey(hint);
    this.selectedLocation = null;
    this.showToast('已标出一个可行移动');
  }

  private toggleAutoComplete(): void {
    if (!this.canInteractWithGame() || this.won) {
      return;
    }
    if (this.autoTimer !== -1) {
      this.stopAutoComplete();
      this.showToast('已停止自动推进');
      return;
    }
    this.selectedLocation = null;
    this.hintMarks = [];
    this.lastHintKey = '';
    this.autoVisited = [gameStateKey(this.gameState)];
    this.autoRunning = true;
    this.ensureStarted();
    this.autoCompleteStep(0);
  }

  private autoCompleteStep(movedCount: number): void {
    this.autoTimer = -1;
    if (this.won) {
      this.autoRunning = false;
      return;
    }
    let move = findSafeFoundationMove(this.gameState);
    if (move === null) {
      move = findAutoCompleteMove(this.gameState, this.recentMoves, this.autoVisited);
    }
    if (move === null) {
      this.autoRunning = false;
      this.showToast(movedCount > 0 ? '自动推进已暂停' : '暂无可自动推进的牌');
      return;
    }
    if (!this.performMove(move.source, move.target)) {
      this.autoRunning = false;
      this.showToast(movedCount > 0 ? '自动推进已暂停' : '暂无可自动推进的牌');
      return;
    }
    this.autoVisited.push(gameStateKey(this.gameState));
    if (movedCount >= 220) {
      this.autoRunning = false;
      this.showToast('自动推进已暂停');
      return;
    }
    this.autoTimer = setTimeout(() => {
      this.autoCompleteStep(movedCount + 1);
    }, 150);
  }

  private undo(): void {
    if (!this.canInteractWithGame()) {
      return;
    }
    this.stopAutoComplete();
    if (this.history.length <= 0) {
      this.showToast('没有可撤销的步骤');
      return;
    }
    const history = this.history.slice();
    const previous = history.pop();
    if (previous === undefined) {
      return;
    }
    this.history = history;
    this.gameState = cloneState(previous.state);
    this.moves = previous.moves;
    this.moves = history.length;
    this.score = this.scoreForState(previous.state);
    this.recentMoves = previous.recentMoves.map((item: FreecellMove) => cloneMove(item));
    this.selectedLocation = null;
    this.hintMarks = [];
    this.lastHintKey = '';
    this.won = false;
    this.showResultOverlay = false;
    this.settled = false;
    this.playClick();
  }

  private newGame(): void {
    if (!this.canInteractWithGame()) {
      return;
    }
    this.stopAutoComplete();
    this.stopTimer();
    this.gameState = createSolvableGame(randomSeed());
    this.history = [];
    this.recentMoves = [];
    this.selectedLocation = null;
    this.hintMarks = [];
    this.lastHintKey = '';
    this.moves = 0;
    this.score = 0;
    this.elapsed = 0;
    this.started = false;
    this.won = false;
    this.showResultOverlay = false;
    this.showGuideOverlay = false;
    this.showExitConfirmOverlay = false;
    this.settled = false;
    this.playClick();
  }

  private openGuide(): void {
    if (!this.canInteractWithGame()) {
      return;
    }
    this.stopAutoComplete();
    this.showGuideOverlay = true;
  }

  private closeGuide(): void {
    this.showGuideOverlay = false;
  }

  private requestExitToHub(): void {
    if (!this.hasActiveProgress() || this.won) {
      this.exitToHub();
      return;
    }
    this.stopAutoComplete();
    this.showGuideOverlay = false;
    this.showExitConfirmOverlay = true;
  }

  private cancelExitConfirm(): void {
    this.showExitConfirmOverlay = false;
  }

  private confirmExitToHub(): void {
    this.showExitConfirmOverlay = false;
    this.exitToHub();
  }

  private hasActiveProgress(): boolean {
    return this.started || this.history.length > 0 || this.moves > 0 || this.score > 0;
  }

  private snapshot(): FreecellSnapshot {
    return {
      state: cloneState(this.gameState),
      moves: this.moves,
      score: this.score,
      recentMoves: this.recentMoves.map((item: FreecellMove) => cloneMove(item))
    };
  }

  private checkWin(): void {
    if (!isWon(this.gameState) || this.settled) {
      return;
    }
    this.won = true;
    this.showResultOverlay = true;
    this.settled = true;
    this.stopAutoComplete();
    this.stopTimer();
    this.showGuideOverlay = false;
    this.showExitConfirmOverlay = false;
    this.recordScore(this.currentScore());
  }

  private ensureStarted(): void {
    if (!this.started) {
      this.started = true;
    }
    if (this.timer !== -1) {
      return;
    }
    this.timer = setInterval(() => {
      if (this.started && !this.won && !this.showGuideOverlay && !this.showExitConfirmOverlay) {
        this.elapsed += 1;
        this.gameState = cloneState(this.gameState);
      }
    }, 1000);
  }

  private stopTimer(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  private stopAutoComplete(): void {
    if (this.autoTimer !== -1) {
      clearTimeout(this.autoTimer);
      this.autoTimer = -1;
    }
    this.autoRunning = false;
    this.autoVisited = [];
  }

  private showToast(text: string): void {
    this.toastText = text;
    this.toastVisible = true;
    this.clearToastTimer();
    this.toastTimer = setTimeout(() => {
      this.toastVisible = false;
    }, 1700);
  }

  private clearToastTimer(): void {
    if (this.toastTimer !== -1) {
      clearTimeout(this.toastTimer);
      this.toastTimer = -1;
    }
  }

  private playClick(): void {
    this.audioService.play('freecellClick');
  }

  private playHint(): void {
    this.audioService.play('freecellHint');
  }

  private layout(): FreecellLayout {
    return computeFreecellLayout(this.pageWidth, this.pageHeight);
  }

  private timeText(): string {
    return this.formatTime(this.elapsed);
  }

  private formatTime(seconds: number): string {
    const min = Math.floor(seconds / 60);
    const sec = seconds % 60;
    const minText = min < 10 ? `0${min}` : `${min}`;
    const secText = sec < 10 ? `0${sec}` : `${sec}`;
    return `${minText}:${secText}`;
  }

  private currentMoves(): number {
    return this.history.length;
  }

  private currentScore(): number {
    return this.scoreForState(this.gameState);
  }

  private scoreForState(state: FreecellState): number {
    return (state.foundations.S.length +
      state.foundations.H.length +
      state.foundations.D.length +
      state.foundations.C.length) * 10;
  }

  private toastWidth(): number {
    return Math.min(this.pageWidth * 0.88, 390);
  }

  private toastY(): number {
    return Math.max(80, this.layout().toolbarTop - 46);
  }

}
