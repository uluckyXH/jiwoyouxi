import { CoopViewport } from '../../design/CoopViewport';
import { TetrisBoard } from './TetrisBoard';
import { TetrisControlPanel } from './TetrisControl';
import { TetrisStatsPanel, TetrisStatusPanel } from './TetrisHud';
import { TetrisExitConfirmOverlay, TetrisPauseOverlay, TetrisResultOverlay } from './TetrisOverlay';
import { TetrisHoldPanel, TetrisNextPanel } from './TetrisPreview';
import {
  ActivePiece,
  BOARD_COLS,
  BOARD_ROWS,
  LOCK_DELAY_MS,
  MAX_LOCK_RESETS,
  TETRIS_PHASE_CLEARING,
  TETRIS_PHASE_FALLING,
  TETRIS_PHASE_GAME_OVER,
  TETRIS_PHASE_LOCKING,
  TETRIS_PHASE_PAUSED,
  TETRIS_PHASE_SPAWNING
} from './TetrisTypes';
import {
  clearLines,
  collides,
  comboScore,
  createEmptyBoard,
  ghostPiece,
  hardDropScore,
  isGrounded,
  lineScore,
  lockPiece,
  shifted,
  shuffleBag,
  softDropScore,
  spawnPiece,
  speedDelayForLevel,
  speedLevelForLines,
  tryRotate
} from './TetrisRules';
import { TetrisTheme } from './TetrisTheme';

@Component
export struct TetrisPage {
  @Prop bestScore: number = 0;
  @Prop @Watch('onSessionChanged') session: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};

  private dropTimer: number = -1;
  private lockTimer: number = -1;
  private clearTimer: number = -1;
  private bag: number[] = [];
  private previousPhase: number = TETRIS_PHASE_FALLING;
  private exitConfirmPhase: number = TETRIS_PHASE_FALLING;

  @State pageWidth: number = CoopViewport.phoneDefaultWidth;
  @State pageHeight: number = CoopViewport.phoneDefaultHeight;
  @State phase: number = TETRIS_PHASE_SPAWNING;
  @State board: number[] = createEmptyBoard();
  @State current: ActivePiece = spawnPiece(0);
  @State ghostRow: number = 18;
  @State nextQueue: number[] = [];
  @State holdKind: number = -1;
  @State holdUsed: boolean = false;
  @State score: number = 0;
  @State lines: number = 0;
  @State level: number = 1;
  @State combo: number = 0;
  @State lastClear: number = 0;
  @State lockResetCount: number = 0;
  @State clearingRows: number[] = [];
  @State clearSweepProgress: number = 0;
  @State exitConfirmVisible: boolean = false;

  aboutToAppear(): void {
    this.restart();
  }

  aboutToDisappear(): void {
    this.stopTimers();
  }

  onSessionChanged(): void {
    this.restart();
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Stack() {
        Image($rawfile('games/tetris/backgrounds/bg.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
        Column({ space: 12 }) {
          this.TopBar()
          Column() {
            this.GameMainArea()
          }
          .margin({ top: this.gameAreaTopMargin() })
          TetrisControlPanel({
            disabled: !this.canAcceptInput(),
            panelWidth: this.controlPanelWidth(),
            panelHeight: this.controlPanelHeight(),
            buttonWidth: this.controlButtonWidth(),
            buttonHeight: this.controlButtonHeight(),
            buttonGap: this.controlButtonGap(),
            rotateButtonSize: this.rotateButtonSize(),
            moveLeft: () => {
              this.moveHorizontal(-1);
            },
            moveRight: () => {
              this.moveHorizontal(1);
            },
            softDrop: () => {
              this.softDrop();
            },
            hardDrop: () => {
              this.hardDrop();
            },
            rotatePiece: () => {
              this.rotatePiece();
            }
          })
          .margin({ top: this.controlPanelTopMargin() })
          Blank()
        }
        .width('100%')
        .height('100%')

        if (this.phase === TETRIS_PHASE_PAUSED) {
          TetrisPauseOverlay({
            pageWidth: this.pageWidth,
            resumeGame: () => {
              this.resumeGame();
            },
            restartGame: () => {
              this.restart();
            }
          })
        }

        if (this.phase === TETRIS_PHASE_GAME_OVER) {
          TetrisResultOverlay({
            pageWidth: this.pageWidth,
            score: this.score,
            bestScore: this.bestScore,
            lines: this.lines,
            level: this.level,
            restartGame: () => {
              this.restart();
            },
            exitToHub: () => {
              this.leaveToHub();
            }
          })
        }

        if (this.exitConfirmVisible) {
          TetrisExitConfirmOverlay({
            pageWidth: this.pageWidth,
            cancelExit: () => {
              this.cancelExitConfirm();
            },
            confirmExit: () => {
              this.leaveToHub();
            }
          })
        }
      }
      .width(this.pageWidth)
      .height(this.pageHeight)
      .clip(true)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fff8ea')
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
    }
  }

  @Builder
  TopBar() {
    Row({ space: 10 }) {
      Stack({ alignContent: Alignment.Center }) {
        Text('← 大厅')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(TetrisTheme.topButtonText)
          .textAlign(TextAlign.Center)
      }
      .width(70)
      .height(34)
      .borderRadius(18)
      .backgroundColor(TetrisTheme.topBarBg)
      .linearGradient(TetrisTheme.topButtonGradient)
      .border({ width: 2, color: TetrisTheme.topButtonBorder })
      .shadow({
        radius: 10,
        color: 'rgba(106,61,27,0.20)',
        offsetX: 0,
        offsetY: 4
      })
      .onClick(() => {
        this.requestLeaveToHub();
      })

      Column({ space: 4 }) {
        Text('俄罗斯方块')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4B1F14')
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Row({ space: 4 }) {
          Text('🏆')
            .fontSize(15)
            .height(18)
            .textAlign(TextAlign.Center)
          Text(`最高 ${Math.max(this.bestScore, this.score)}`)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#553123')
            .textAlign(TextAlign.Center)
            .maxLines(1)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .height(54)
      .layoutWeight(1)

      Stack({ alignContent: Alignment.Center }) {
        Row({ space: 4 }) {
          Text(this.phase === TETRIS_PHASE_PAUSED ? '▶' : 'Ⅱ')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(TetrisTheme.pauseButtonText)
            .textAlign(TextAlign.Center)
          Text(this.phase === TETRIS_PHASE_PAUSED ? '继续' : '暂停')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(TetrisTheme.pauseButtonText)
            .textAlign(TextAlign.Center)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .width(70)
      .height(34)
      .borderRadius(18)
      .backgroundColor('#F25F83')
      .linearGradient(TetrisTheme.pauseButtonGradient)
      .border({ width: 2, color: TetrisTheme.pauseButtonBorder })
      .shadow({
        radius: 10,
        color: 'rgba(140,38,54,0.26)',
        offsetX: 0,
        offsetY: 4
      })
      .onClick(() => {
        this.togglePause();
      })
    }
    .width('100%')
    .height(112)
    .padding({ left: 14, right: 14, top: 30 })
  }

  @Builder
  GameMainArea() {
    Row({ space: 7 }) {
      Column({ space: 7 }) {
        TetrisHoldPanel({
          kind: this.holdKind,
          holdUsed: this.holdUsed,
          isEnabled: this.canAcceptInput(),
          panelWidth: this.leftPanelWidth(),
          holdAction: () => {
            this.holdPiece();
          }
        })
        TetrisStatsPanel({
          score: this.score,
          lines: this.lines,
          level: this.level
        })
      }
      .width(this.leftPanelWidth())

      this.BoardFrame()

      Column({ space: 7 }) {
        TetrisNextPanel({
          queue: this.nextQueue,
          panelWidth: this.rightPanelWidth()
        })
        TetrisStatusPanel({
          phase: this.phase,
          holdUsed: this.holdUsed,
          lastClear: this.lastClear,
          combo: this.combo,
          lockResetCount: this.lockResetCount
        })
      }
      .width(this.rightPanelWidth())
    }
    .width('100%')
    .padding({ left: 7, right: 7 })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  BoardFrame() {
    Stack() {
      Stack() {
        TetrisBoard({
          board: this.board,
          current: this.current,
          ghostRow: this.ghostRow,
          gameOver: this.phase === TETRIS_PHASE_GAME_OVER || this.phase === TETRIS_PHASE_CLEARING,
          cellSize: this.cellSize(),
          clearingRows: this.clearingRows,
          clearSweepProgress: this.clearSweepProgress
        })
      }
      .width(this.boardPixelWidth() + 12)
      .height(this.boardPixelHeight() + 12)
      .padding(6)
      .backgroundColor(TetrisTheme.boardInsetBg)
      .border({ width: 2, color: TetrisTheme.boardInsetBorder })
      .borderRadius(TetrisTheme.radiusBoard + 2)
      .clip(true)
      Text('')
        .width(5)
        .height(this.boardPixelHeight() + 18)
        .borderRadius(4)
        .backgroundColor('rgba(255,211,144,0.18)')
        .linearGradient(TetrisTheme.boardLeftEdgeGradient)
        .position({ x: 1, y: -3 })
      Text('')
        .width(5)
        .height(this.boardPixelHeight() + 18)
        .borderRadius(4)
        .backgroundColor('rgba(72,29,13,0.22)')
        .linearGradient(TetrisTheme.boardRightEdgeGradient)
        .position({ x: this.boardPixelWidth() + 6, y: -3 })
    }
    .padding(9)
    .backgroundColor(TetrisTheme.boardFrameBg)
    .linearGradient(TetrisTheme.boardFrameGradient)
    .border({ width: 2, color: TetrisTheme.boardFrameBorder })
    .borderRadius(24)
    .shadow({
      radius: 26,
      color: 'rgba(53,24,10,0.28)',
      offsetX: 0,
      offsetY: 12
    })
  }

  private restart(): void {
    this.stopTimers();
    this.exitConfirmVisible = false;
    this.bag = [];
    this.board = createEmptyBoard();
    this.nextQueue = [];
    this.holdKind = -1;
    this.holdUsed = false;
    this.score = 0;
    this.lines = 0;
    this.level = 1;
    this.combo = 0;
    this.lastClear = 0;
    this.lockResetCount = 0;
    this.clearingRows = [];
    this.clearSweepProgress = 0;
    this.phase = TETRIS_PHASE_SPAWNING;
    this.ensureNextQueue();
    this.spawnNextPiece();
  }

  private spawnNextPiece(): void {
    this.phase = TETRIS_PHASE_SPAWNING;
    const next = spawnPiece(this.takeNextKind());
    this.current = next;
    this.holdUsed = false;
    this.lockResetCount = 0;
    if (collides(this.board, next)) {
      this.finishGame();
      return;
    }
    this.refreshGhost();
    this.phase = TETRIS_PHASE_FALLING;
    this.scheduleDrop();
  }

  private ensureNextQueue(): void {
    const queue = this.nextQueue.slice();
    while (queue.length < 5) {
      queue.push(this.drawKind());
    }
    this.nextQueue = queue;
  }

  private takeNextKind(): number {
    this.ensureNextQueue();
    const queue = this.nextQueue.slice();
    const next = queue.shift();
    this.nextQueue = queue;
    this.ensureNextQueue();
    return next === undefined ? this.drawKind() : next;
  }

  private drawKind(): number {
    if (this.bag.length === 0) {
      this.bag = shuffleBag();
    }
    const next = this.bag.shift();
    return next === undefined ? 0 : next;
  }

  private moveHorizontal(dx: number): void {
    if (!this.canAcceptInput()) {
      return;
    }
    const next = shifted(this.current, dx, 0);
    if (collides(this.board, next)) {
      return;
    }
    this.current = next;
    this.refreshGhost();
    this.afterLateralAction();
  }

  private rotatePiece(): void {
    if (!this.canAcceptInput()) {
      return;
    }
    const rotated = tryRotate(this.board, this.current);
    if (rotated === null) {
      return;
    }
    this.current = rotated;
    this.refreshGhost();
    this.afterLateralAction();
  }

  private softDrop(): void {
    if (!this.canAcceptInput()) {
      return;
    }
    const next = shifted(this.current, 0, 1);
    if (!collides(this.board, next)) {
      this.current = next;
      this.score += softDropScore(1);
      this.refreshGhost();
      this.clearLockTimer();
      this.lockResetCount = 0;
      this.phase = TETRIS_PHASE_FALLING;
      if (isGrounded(this.board, this.current)) {
        this.startLocking(false);
      } else {
        this.scheduleDrop();
      }
      return;
    }
    if (isGrounded(this.board, this.current)) {
      this.startLocking(false);
    }
  }

  private hardDrop(): void {
    if (!this.canAcceptInput()) {
      return;
    }
    const ghost = ghostPiece(this.board, this.current);
    const moved = Math.max(0, ghost.row - this.current.row);
    this.current = ghost;
    this.ghostRow = ghost.row;
    this.score += hardDropScore(moved);
    this.lockAndSpawn();
  }

  private holdPiece(): void {
    if (!this.canAcceptInput() || this.holdUsed) {
      return;
    }
    const currentKind = this.current.kind;
    const incomingKind = this.holdKind < 0 ? this.takeNextKind() : this.holdKind;
    const incoming = spawnPiece(incomingKind);
    if (collides(this.board, incoming)) {
      return;
    }
    this.holdKind = currentKind;
    this.current = incoming;
    this.holdUsed = true;
    this.clearLockTimer();
    this.refreshGhost();
    this.phase = TETRIS_PHASE_FALLING;
    this.scheduleDrop();
  }

  private afterLateralAction(): void {
    if (isGrounded(this.board, this.current)) {
      this.startLocking(true);
      return;
    }
    this.clearLockTimer();
    this.lockResetCount = 0;
    this.phase = TETRIS_PHASE_FALLING;
    this.scheduleDrop();
  }

  private autoDrop(): void {
    this.dropTimer = -1;
    if (this.phase !== TETRIS_PHASE_FALLING) {
      return;
    }
    const next = shifted(this.current, 0, 1);
    if (!collides(this.board, next)) {
      this.current = next;
      this.refreshGhost();
      if (isGrounded(this.board, this.current)) {
        this.startLocking(false);
      } else {
        this.scheduleDrop();
      }
      return;
    }
    this.startLocking(false);
  }

  private startLocking(allowReset: boolean): void {
    this.clearDropTimer();
    if (this.phase === TETRIS_PHASE_LOCKING) {
      if (allowReset && this.lockResetCount < MAX_LOCK_RESETS) {
        this.lockResetCount += 1;
        this.scheduleLock();
      }
      return;
    }
    this.phase = TETRIS_PHASE_LOCKING;
    this.lockResetCount = 0;
    this.scheduleLock();
  }

  private scheduleDrop(): void {
    this.clearDropTimer();
    if (this.phase !== TETRIS_PHASE_FALLING) {
      return;
    }
    this.dropTimer = setTimeout(() => {
      this.autoDrop();
    }, speedDelayForLevel(this.level));
  }

  private scheduleLock(): void {
    this.clearLockTimer();
    if (this.phase !== TETRIS_PHASE_LOCKING) {
      return;
    }
    this.lockTimer = setTimeout(() => {
      this.lockAndSpawn();
    }, LOCK_DELAY_MS);
  }

  private lockAndSpawn(): void {
    if (this.phase === TETRIS_PHASE_GAME_OVER) {
      return;
    }
    this.clearDropTimer();
    this.clearLockTimer();
    const locked = lockPiece(this.board, this.current);
    const fullRows = this.fullRowsOf(locked);
    this.board = locked;
    if (fullRows.length > 0) {
      this.startClearing(fullRows);
      return;
    }
    this.lastClear = 0;
    this.combo = 0;
    this.spawnNextPiece();
  }

  private fullRowsOf(board: number[]): number[] {
    const rows: number[] = [];
    for (let row = 0; row < BOARD_ROWS; row += 1) {
      let full = true;
      for (let col = 0; col < BOARD_COLS; col += 1) {
        if (board[row * BOARD_COLS + col] === 0) {
          full = false;
          break;
        }
      }
      if (full) {
        rows.push(row);
      }
    }
    return rows;
  }

  private startClearing(rows: number[]): void {
    this.phase = TETRIS_PHASE_CLEARING;
    this.clearingRows = rows;
    this.clearSweepProgress = 0;
    this.getUIContext().animateTo({
      duration: TetrisTheme.clearSweepDurationMs,
      curve: Curve.EaseOut,
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Normal
    }, () => {
      this.clearSweepProgress = 1;
    });
    this.clearTimer = setTimeout(() => {
      this.clearTimer = -1;
      this.finishClearing();
    }, TetrisTheme.clearSweepDurationMs);
  }

  private finishClearing(): void {
    if (this.phase !== TETRIS_PHASE_CLEARING) {
      return;
    }
    const result = clearLines(this.board);
    const cleared = result.cleared;
    this.board = result.board;
    this.clearingRows = [];
    this.clearSweepProgress = 0;
    if (cleared > 0) {
      const nextCombo = this.combo + 1;
      this.lastClear = cleared;
      this.combo = nextCombo;
      this.score += lineScore(cleared) + comboScore(nextCombo);
      this.lines += cleared;
      this.level = speedLevelForLines(this.lines);
    }
    this.spawnNextPiece();
  }

  private refreshGhost(): void {
    this.ghostRow = ghostPiece(this.board, this.current).row;
  }

  private togglePause(): void {
    if (this.phase === TETRIS_PHASE_GAME_OVER || this.phase === TETRIS_PHASE_CLEARING) {
      return;
    }
    if (this.phase === TETRIS_PHASE_PAUSED) {
      this.resumeGame();
      return;
    }
    this.pauseGame();
  }

  private pauseGame(): void {
    if (this.phase === TETRIS_PHASE_GAME_OVER || this.phase === TETRIS_PHASE_PAUSED) {
      return;
    }
    this.previousPhase = this.phase;
    this.stopTimers();
    this.phase = TETRIS_PHASE_PAUSED;
  }

  private resumeGame(): void {
    if (this.phase !== TETRIS_PHASE_PAUSED) {
      return;
    }
    this.phase = this.previousPhase === TETRIS_PHASE_LOCKING ? TETRIS_PHASE_LOCKING : TETRIS_PHASE_FALLING;
    if (this.phase === TETRIS_PHASE_LOCKING) {
      this.scheduleLock();
    } else {
      this.scheduleDrop();
    }
  }

  private finishGame(): void {
    if (this.phase === TETRIS_PHASE_GAME_OVER) {
      return;
    }
    this.stopTimers();
    this.phase = TETRIS_PHASE_GAME_OVER;
    this.recordScore(Math.max(0, this.score));
  }

  private requestLeaveToHub(): void {
    if (!this.shouldConfirmExit()) {
      this.leaveToHub();
      return;
    }
    if (this.exitConfirmVisible) {
      return;
    }
    this.exitConfirmPhase = this.phase;
    if (this.phase === TETRIS_PHASE_FALLING) {
      this.clearDropTimer();
    }
    if (this.phase === TETRIS_PHASE_LOCKING) {
      this.clearLockTimer();
    }
    this.exitConfirmVisible = true;
  }

  private cancelExitConfirm(): void {
    this.exitConfirmVisible = false;
    if (this.phase === TETRIS_PHASE_GAME_OVER) {
      return;
    }
    if (this.exitConfirmPhase === TETRIS_PHASE_FALLING && this.phase === TETRIS_PHASE_FALLING) {
      this.scheduleDrop();
    }
    if (this.exitConfirmPhase === TETRIS_PHASE_LOCKING && this.phase === TETRIS_PHASE_LOCKING) {
      this.scheduleLock();
    }
  }

  private shouldConfirmExit(): boolean {
    return this.phase !== TETRIS_PHASE_GAME_OVER;
  }

  private leaveToHub(): void {
    this.exitConfirmVisible = false;
    this.stopTimers();
    this.exitToHub();
  }

  private canAcceptInput(): boolean {
    return this.phase === TETRIS_PHASE_FALLING || this.phase === TETRIS_PHASE_LOCKING;
  }

  private stopTimers(): void {
    this.clearDropTimer();
    this.clearLockTimer();
    this.clearClearTimer();
  }

  private clearDropTimer(): void {
    if (this.dropTimer !== -1) {
      clearTimeout(this.dropTimer);
      this.dropTimer = -1;
    }
  }

  private clearLockTimer(): void {
    if (this.lockTimer !== -1) {
      clearTimeout(this.lockTimer);
      this.lockTimer = -1;
    }
  }

  private clearClearTimer(): void {
    if (this.clearTimer !== -1) {
      clearTimeout(this.clearTimer);
      this.clearTimer = -1;
    }
  }

  private leftPanelWidth(): number {
    return Math.max(60, Math.min(68, Math.floor(this.pageWidth * 0.17)));
  }

  private rightPanelWidth(): number {
    return Math.max(62, Math.min(70, Math.floor(this.pageWidth * 0.18)));
  }

  private boardPixelWidth(): number {
    return this.cellSize() * BOARD_COLS;
  }

  private boardPixelHeight(): number {
    return this.cellSize() * BOARD_ROWS;
  }

  private controlPanelWidth(): number {
    const maxWidth = Math.max(1, this.pageWidth - 32);
    const preferredWidth = this.pageWidth - 92;
    return Math.min(maxWidth, Math.max(260, preferredWidth));
  }

  private controlPanelHeight(): number {
    return Math.max(132, Math.min(146, Math.floor(this.pageHeight * 0.18)));
  }

  private gameAreaTopMargin(): number {
    return Math.max(58, Math.min(76, Math.floor(this.pageHeight * 0.09)));
  }

  private controlPanelTopMargin(): number {
    return Math.max(28, Math.min(42, Math.floor(this.pageHeight * 0.045)));
  }

  private controlButtonGap(): number {
    return Math.max(10, Math.min(14, Math.floor(this.pageWidth * 0.034)));
  }

  private rotateButtonSize(): number {
    return Math.max(72, Math.min(84, Math.floor(this.controlPanelWidth() * 0.28)));
  }

  private controlButtonWidth(): number {
    const innerWidth = this.controlPanelWidth() - 32;
    const available = innerWidth - this.rotateButtonSize() - 12 - this.controlButtonGap();
    return Math.max(62, Math.min(74, Math.floor(available / 2)));
  }

  private controlButtonHeight(): number {
    return Math.max(46, Math.min(52, Math.floor(this.controlButtonWidth() * 0.72)));
  }

  private cellSize(): number {
    const widthBased = (this.pageWidth - this.leftPanelWidth() - this.rightPanelWidth() - 65) / BOARD_COLS;
    const heightBased = (this.pageHeight - this.controlPanelHeight() - 178) / BOARD_ROWS;
    return Math.max(TetrisTheme.minCell, Math.floor(Math.min(widthBased, heightBased, TetrisTheme.maxCell)));
  }
}
