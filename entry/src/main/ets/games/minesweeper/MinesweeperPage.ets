import { CoopTheme } from '../../design/CoopTheme';
import { MinesweeperBoard } from './MinesweeperBoard';
import { MinesweeperHud } from './MinesweeperHud';
import { MinesweeperResultOverlay } from './MinesweeperResultOverlay';
import {
  createEmptyMineCells,
  flagAllMines,
  isMinesweeperWin,
  markBoomAt,
  minesweeperDifficulty,
  minesweeperScore,
  openSafeCells,
  placeMinesForFirstTap,
  remainingMineCount,
  revealMines,
  toggleFlagAt
} from './MinesweeperRules';
import { MinesweeperTheme } from './MinesweeperTheme';
import { MineCell, MineDifficulty } from './MinesweeperTypes';

@Component
export struct MinesweeperPage {
  @Prop bestScore: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  private timer: number = -1;
  private settled: boolean = false;
  @State pageWidth: number = 390;
  @State pageHeight: number = 760;
  @State difficultyKey: string = 'easy';
  @State cells: MineCell[] = [];
  @State elapsed: number = 0;
  @State started: boolean = false;
  @State flagMode: boolean = false;
  @State devRevealMines: boolean = false;
  @State paused: boolean = false;
  @State gameOver: boolean = false;
  @State win: boolean = false;
  @State showResultOverlay: boolean = false;

  aboutToAppear(): void {
    this.restart();
  }

  aboutToDisappear(): void {
    this.stopTimer();
  }

  build() {
    Stack() {
      Image($rawfile('games/minesweeper/bg.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
      Column({ space: 8 }) {
        MinesweeperHud({
          pageWidth: this.pageWidth,
          bestScore: this.bestScore,
          currentScore: this.currentScore(),
          remainingMines: this.remainingMines(),
          elapsedText: this.timeText(),
          paused: this.paused,
          flagMode: this.flagMode,
          flagLimitReached: this.remainingMines() <= 0,
          devRevealMines: this.devRevealMines,
          difficultyKey: this.difficultyKey,
          exitToHub: () => {
            this.exitToHub();
          },
          togglePause: () => {
            this.paused = !this.paused;
          },
          selectDifficulty: (key: string) => {
            this.difficultyKey = key;
            this.restart();
          },
          toggleFlagMode: () => {
            this.flagMode = !this.flagMode;
          },
          toggleDevRevealMines: () => {
            this.toggleDevRevealMines();
          },
          restartGame: () => {
            this.restart();
          }
        })

        Stack({ alignContent: Alignment.Top }) {
          MinesweeperBoard({
            cells: this.cells,
            cellPx: this.cellSize(),
            frameWidthPx: this.boardFrameWidth(),
            frameHeightPx: this.boardFrameHeight(),
            boardWidthPx: this.boardWidth(),
            boardHeightPx: this.boardHeight(),
            columnsTemplateValue: this.columnsTemplate(),
            rowsTemplateValue: this.rowsTemplate(),
            revealMines: this.devRevealMines,
            tapCell: (index: number) => {
              this.tapCell(index);
            }
          })
        }
        .width('100%')
        .height(this.boardContainerHeight())
        .clip(true)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(MinesweeperTheme.pageTint)

      if (this.paused && !this.gameOver) {
        this.PauseOverlay()
      }
      if (this.gameOver && this.showResultOverlay) {
        MinesweeperResultOverlay({
          win: this.win,
          pageWidth: this.pageWidth,
          pageHeight: this.pageHeight,
          elapsedText: this.timeText(),
          currentScore: this.currentScore(),
          bestScore: this.bestScore,
          restartGame: () => {
            this.restart();
          },
          exitToHub: () => {
            this.exitToHub();
          },
          closeOverlay: () => {
            this.showResultOverlay = false;
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
  PauseOverlay() {
    Column({ space: 12 }) {
      Text('扫雷暂停')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
      Button('继续')
        .width(160)
        .height(42)
        .borderRadius(8)
        .backgroundColor('#ffffff')
        .fontColor(CoopTheme.ink)
        .onClick(() => {
          this.paused = false;
        })
      Button('重新开始')
        .width(160)
        .height(42)
        .borderRadius(8)
        .backgroundColor(CoopTheme.brand)
        .fontColor('#ffffff')
        .onClick(() => {
          this.restart();
        })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(7,8,18,0.62)')
  }

  private restart(): void {
    this.stopTimer();
    this.elapsed = 0;
    this.started = false;
    this.flagMode = false;
    this.devRevealMines = false;
    this.paused = false;
    this.gameOver = false;
    this.win = false;
    this.showResultOverlay = false;
    this.settled = false;
    const difficulty = this.difficulty();
    this.cells = createEmptyMineCells(difficulty.rows, difficulty.cols);
  }

  private startTimer(): void {
    if (this.timer !== -1) {
      return;
    }
    this.timer = setInterval(() => {
      if (!this.paused && !this.gameOver && this.started) {
        this.elapsed += 1;
      }
    }, 1000);
  }

  private stopTimer(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  private tapCell(index: number): void {
    if (this.paused || this.gameOver) {
      return;
    }
    const difficulty = this.difficulty();
    if (!this.started) {
      if (!this.hasMines()) {
        this.cells = placeMinesForFirstTap(this.cells, difficulty, index);
      }
      this.started = true;
      this.startTimer();
    }
    const cell = this.cells[index];
    if (cell.open) {
      return;
    }
    if (this.flagMode) {
      this.cells = toggleFlagAt(this.cells, index, this.mineCount());
      return;
    }
    if (cell.flag) {
      return;
    }
    if (cell.mine) {
      this.cells = revealMines(markBoomAt(this.cells, index));
      this.finish(false);
      return;
    }
    const opened = openSafeCells(this.cells, difficulty, index);
    if (isMinesweeperWin(opened, difficulty)) {
      this.cells = flagAllMines(opened);
      this.finish(true);
      return;
    }
    this.cells = opened;
  }

  private finish(won: boolean): void {
    if (this.settled) {
      return;
    }
    this.settled = true;
    this.win = won;
    this.gameOver = true;
    this.showResultOverlay = true;
    this.stopTimer();
    this.recordScore(minesweeperScore(this.cells, this.elapsed, this.mineCount(), won));
  }

  private toggleDevRevealMines(): void {
    const next = !this.devRevealMines;
    if (next && !this.hasMines()) {
      this.cells = placeMinesForFirstTap(this.cells, this.difficulty(), 0);
    }
    this.devRevealMines = next;
  }

  private hasMines(): boolean {
    return this.cells.some((cell: MineCell) => cell.mine);
  }

  private difficulty(): MineDifficulty {
    return minesweeperDifficulty(this.difficultyKey);
  }

  private rows(): number {
    return this.difficulty().rows;
  }

  private cols(): number {
    return this.difficulty().cols;
  }

  private mineCount(): number {
    return this.difficulty().mines;
  }

  private remainingMines(): number {
    return remainingMineCount(this.cells, this.mineCount());
  }

  private currentScore(): number {
    return minesweeperScore(this.cells, this.elapsed, this.mineCount(), this.win);
  }

  private timeText(): string {
    const minutes = Math.floor(this.elapsed / 60);
    const seconds = this.elapsed % 60;
    return `${minutes < 10 ? '0' : ''}${minutes}:${seconds < 10 ? '0' : ''}${seconds}`;
  }

  private cellSize(): number {
    return Math.max(8, Math.floor(Math.min(this.maxCellSizeByFrameWidth(), this.maxCellSizeByFrameHeight())));
  }

  private boardWidth(): number {
    return this.cellSize() * this.cols();
  }

  private boardHeight(): number {
    return this.cellSize() * this.rows();
  }

  private columnsTemplate(): string {
    let value = '1fr';
    for (let i = 1; i < this.cols(); i += 1) {
      value += ' 1fr';
    }
    return value;
  }

  private rowsTemplate(): string {
    let value = '1fr';
    for (let i = 1; i < this.rows(); i += 1) {
      value += ' 1fr';
    }
    return value;
  }

  private boardContainerHeight(): number {
    return Math.min(this.boardFrameHeight() + 4, this.availableBoardAreaHeight());
  }

  private maxCellSizeByFrameWidth(): number {
    return Math.floor((this.boardFrameWidth() - this.boardFrameHorizontalInset() * 2) / this.cols());
  }

  private maxCellSizeByFrameHeight(): number {
    return Math.floor((this.boardFrameHeight() - this.boardFrameVerticalInset() * 2) / this.rows());
  }

  private boardFrameWidth(): number {
    const widthLimit = this.pageWidth - this.boardHorizontalMargin() * 2;
    const heightLimit = this.availableBoardAreaHeight() - this.bottomBackgroundReserve();
    const widthByHeight = Math.floor(heightLimit / this.boardFrameHeightRatio());
    return Math.max(210, Math.floor(Math.min(widthLimit, widthByHeight)));
  }

  private boardFrameHeight(): number {
    return Math.floor(this.boardFrameWidth() * this.boardFrameHeightRatio());
  }

  private boardFrameHeightRatio(): number {
    return Math.min(1.22, Math.max(1.04, this.rows() / this.cols() * 0.98));
  }

  private boardHorizontalMargin(): number {
    return this.pageWidth < 340 ? 14 : 18;
  }

  private availableBoardAreaHeight(): number {
    return Math.max(120, this.pageHeight - this.hudHeightEstimate() - 16);
  }

  private hudHeightEstimate(): number {
    return 214;
  }

  private boardFrameHorizontalInset(): number {
    return Math.round(this.boardFrameWidth() * 0.042);
  }

  private boardFrameVerticalInset(): number {
    return Math.round(this.boardFrameWidth() * 0.056);
  }

  private bottomBackgroundReserve(): number {
    return this.pageHeight < 700 ? 18 : 46;
  }
}
