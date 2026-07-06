import { CoopTheme } from '../../design/CoopTheme';
import { TetrisBoard } from './TetrisBoard';
import { TetrisControlPanel } from './TetrisControl';
import { TetrisStatsPanel, TetrisStatusPanel } from './TetrisHud';
import { TetrisPauseOverlay, TetrisResultOverlay } from './TetrisOverlay';
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

  @State pageWidth: number = 390;
  @State pageHeight: number = 760;
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
        .margin({ top: 6 })
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
    }
    .width('100%')
    .height('100%')
    .onAreaChange((oldArea, newArea) => {
      const width = Number.parseFloat(`${newArea.width}`);
      const height = Number.parseFloat(`${newArea.height}`);
      if (!Number.isNaN(width) && !Number.isNaN(height)) {
        this.pageWidth = Math.max(280, width);
        this.pageHeight = Math.max(420, height);
      }
    })
  }

  @Builder
  TopBar() {
    Row({ space: 8 }) {
      Button('← 大厅')
        .width(78)
        .height(38)
        .borderRadius(20)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#FFF6E8')
        .fontColor(CoopTheme.ink)
        .border({ width: 1, color: TetrisTheme.topBarBorder })
        .shadow({
          radius: 12,
          color: 'rgba(47,29,20,0.12)',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(() => {
          this.leaveToHub();
        })

      Column({ space: 1 }) {
        Text('俄罗斯方块')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Text(`最高 ${Math.max(this.bestScore, this.score)}`)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(CoopTheme.brandDark)
          .textAlign(TextAlign.Center)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .height(42)
      .layoutWeight(1)

      Stack({ alignContent: Alignment.Center }) {
        Text(this.phase === TETRIS_PHASE_PAUSED ? '继续' : '暂停')
          .width(62)
          .height(34)
          .borderRadius(18)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(CoopTheme.ink)
          .fontColor('#ffffff')
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.togglePause();
          })
      }
      .width(78)
      .height(38)
    }
    .width('100%')
    .height(94)
    .padding({ left: 14, right: 14, top: 34 })
    .backgroundColor(TetrisTheme.topBarBg)
    .linearGradient(TetrisTheme.topBarGradient)
    .border({ width: { bottom: 1 }, color: TetrisTheme.topBarBorder })
    .shadow({
      radius: 22,
      color: 'rgba(90,64,36,0.16)',
      offsetX: 0,
      offsetY: 8
    })
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
          dropDelay: speedDelayForLevel(this.level),
          queueSize: this.nextQueue.length,
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
      .width(this.boardPixelWidth() + 10)
      .height(this.boardPixelHeight() + 10)
      .padding(5)
      .backgroundColor(TetrisTheme.boardBg)
      .border({ width: 1, color: '#2B3640' })
      .borderRadius(TetrisTheme.radiusBoard)
      .clip(true)
    }
    .padding(7)
    .backgroundColor(TetrisTheme.boardFrameBg)
    .border({ width: 1, color: TetrisTheme.boardFrameBorder })
    .borderRadius(20)
    .shadow({
      radius: 22,
      color: 'rgba(0,0,0,0.13)',
      offsetX: 0,
      offsetY: 10
    })
  }

  private restart(): void {
    this.stopTimers();
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

  private leaveToHub(): void {
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
    return Math.max(150, Math.min(172, Math.floor(this.pageHeight * 0.19)));
  }

  private controlPanelTopMargin(): number {
    return Math.max(52, Math.min(68, Math.floor(this.pageHeight * 0.075)));
  }

  private controlButtonGap(): number {
    return Math.max(10, Math.min(14, Math.floor(this.pageWidth * 0.034)));
  }

  private rotateButtonSize(): number {
    return Math.max(78, Math.min(90, Math.floor(this.controlPanelWidth() * 0.3)));
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
