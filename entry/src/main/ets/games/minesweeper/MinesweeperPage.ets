import { CoopTheme } from '../../design/CoopTheme';

interface MineCell {
  index: number;
  mine: boolean;
  open: boolean;
  flag: boolean;
  neighbor: number;
  boom: boolean;
}

interface MineDifficulty {
  key: string;
  label: string;
  rows: number;
  cols: number;
  mines: number;
}

const DIFFICULTIES: MineDifficulty[] = [
  { key: 'easy', label: '简单', rows: 9, cols: 9, mines: 10 },
  { key: 'normal', label: '中等', rows: 13, cols: 10, mines: 25 },
  { key: 'hard', label: '困难', rows: 16, cols: 12, mines: 45 }
];

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
  @State paused: boolean = false;
  @State gameOver: boolean = false;
  @State win: boolean = false;

  aboutToAppear(): void {
    this.restart();
  }

  aboutToDisappear(): void {
    this.stopTimer();
  }

  build() {
    Stack() {
      Column({ space: 10 }) {
        this.TopBar()
        Row({ space: 8 }) {
          ForEach(DIFFICULTIES, (item: MineDifficulty) => {
            Button(item.label)
              .height(34)
              .layoutWeight(1)
              .borderRadius(8)
              .fontColor(this.difficultyKey === item.key ? '#ffffff' : CoopTheme.ink)
              .backgroundColor(this.difficultyKey === item.key ? CoopTheme.blue : CoopTheme.panel)
              .border({ width: 1, color: this.difficultyKey === item.key ? 'rgba(255,255,255,0.28)' : CoopTheme.glassLine })
              .onClick(() => {
                this.difficultyKey = item.key;
                this.restart();
              })
          }, (item: MineDifficulty) => item.key)
        }
        .width('100%')
        .padding({ left: 12, right: 12 })

        Row({ space: 8 }) {
          Button(this.flagMode ? '插旗模式' : '翻开模式')
            .height(36)
            .layoutWeight(1)
            .borderRadius(8)
            .backgroundColor(this.flagMode ? CoopTheme.brand : CoopTheme.panel)
            .fontColor(this.flagMode ? '#ffffff' : CoopTheme.ink)
            .border({ width: 1, color: this.flagMode ? 'rgba(255,255,255,0.28)' : CoopTheme.glassLine })
            .onClick(() => {
              this.flagMode = !this.flagMode;
            })
          Button('重新开始')
            .height(36)
            .layoutWeight(1)
            .borderRadius(8)
            .backgroundColor(CoopTheme.panel)
            .fontColor(CoopTheme.ink)
            .border({ width: 1, color: CoopTheme.glassLine })
            .onClick(() => {
              this.restart();
            })
        }
        .width('100%')
        .padding({ left: 12, right: 12 })

        Grid() {
          ForEach(this.cells, (cell: MineCell) => {
            GridItem() {
              this.CellView(cell)
            }
          }, (cell: MineCell) => `${cell.index}-${cell.open}-${cell.flag}-${cell.boom}`)
        }
        .columnsTemplate(this.columnsTemplate())
        .rowsGap(1)
        .columnsGap(1)
        .width(this.boardWidth())
        .height(this.boardHeight())
        .padding(4)
        .backgroundColor('#808080')
        .border({ width: 3, color: '#6b6b6b' })

        Blank()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(CoopTheme.bg)
      .linearGradient({
        angle: 180,
        colors: [['#edf9ff', 0], ['#fff8ea', 0.50], ['#f7fbff', 1]]
      })

      if (this.paused && !this.gameOver) {
        this.PauseOverlay()
      }
      if (this.gameOver) {
        this.ResultOverlay()
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
      Button('大厅')
        .width(62)
        .height(36)
        .borderRadius(8)
        .backgroundColor(CoopTheme.panel)
        .fontColor(CoopTheme.ink)
        .border({ width: 1, color: CoopTheme.glassLine })
        .onClick(() => {
          this.exitToHub();
        })
      Text(`雷 ${this.remainingMines()}`)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
      Blank()
      Text(this.timeText())
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
      Blank()
      Text(`最高 ${Math.max(this.bestScore, this.currentScore())}`)
        .fontSize(12)
        .fontColor(CoopTheme.muted)
      Button(this.paused ? '继续' : '暂停')
        .width(66)
        .height(36)
        .borderRadius(8)
        .backgroundColor(CoopTheme.ink)
        .fontColor('#ffffff')
        .onClick(() => {
          this.paused = !this.paused;
        })
    }
    .width('100%')
    .height(88)
    .padding({ left: 12, right: 12, top: 30 })
    .backgroundColor(CoopTheme.glassStrong)
    .border({ width: { bottom: 1 }, color: CoopTheme.glassLine })
    .shadow({
      radius: 16,
      color: 'rgba(66,92,120,0.10)',
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  CellView(cell: MineCell) {
    Stack() {
      if (cell.open) {
        Text(this.openCellText(cell))
          .width('100%')
          .height('100%')
          .fontSize(Math.max(12, this.cellSize() * 0.45))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.numberColor(cell.neighbor))
          .textAlign(TextAlign.Center)
          .backgroundColor(cell.boom ? '#ef4444' : '#c0c0c0')
      } else {
        Text(cell.flag ? '⚑' : '')
          .width('100%')
          .height('100%')
          .fontSize(Math.max(13, this.cellSize() * 0.45))
          .fontColor('#dc2626')
          .textAlign(TextAlign.Center)
          .backgroundColor('#d4d0c8')
          .border({ width: 1, color: '#ffffff' })
      }
    }
    .width('100%')
    .height(this.cellSize())
    .onClick(() => {
      this.tapCell(cell.index);
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

  @Builder
  ResultOverlay() {
    Column({ space: 12 }) {
      Text(this.win ? '扫雷成功' : '踩雷了')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
      Text(`用时 ${this.timeText()} · 得分 ${this.currentScore()} · 最高 ${Math.max(this.bestScore, this.currentScore())}`)
        .fontSize(14)
        .fontColor(CoopTheme.muted)
      Button('再来一局')
        .width('100%')
        .height(44)
        .borderRadius(8)
        .backgroundColor(CoopTheme.ink)
        .fontColor('#ffffff')
        .onClick(() => {
          this.restart();
        })
      Button('回大厅')
        .width('100%')
        .height(40)
        .borderRadius(8)
        .backgroundColor(CoopTheme.panel)
        .fontColor(CoopTheme.ink)
        .border({ width: 1, color: CoopTheme.glassLine })
        .onClick(() => {
          this.exitToHub();
        })
    }
    .width(Math.min(this.pageWidth - 36, 350))
    .padding(18)
    .borderRadius(8)
    .backgroundColor(CoopTheme.glassStrong)
    .border({ width: 1, color: CoopTheme.glassLine })
    .shadow(CoopTheme.shadow)
  }

  private restart(): void {
    this.stopTimer();
    this.elapsed = 0;
    this.started = false;
    this.flagMode = false;
    this.paused = false;
    this.gameOver = false;
    this.win = false;
    this.settled = false;
    const total = this.rows() * this.cols();
    const next: MineCell[] = [];
    for (let i = 0; i < total; i += 1) {
      next.push({ index: i, mine: false, open: false, flag: false, neighbor: 0, boom: false });
    }
    this.cells = next;
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
    if (!this.started) {
      this.placeMines(index);
      this.started = true;
      this.startTimer();
    }
    const next = this.cells.slice();
    const cell = next[index];
    if (cell.open) {
      return;
    }
    if (this.flagMode) {
      cell.flag = !cell.flag;
      next[index] = cell;
      this.cells = next;
      return;
    }
    if (cell.flag) {
      return;
    }
    if (cell.mine) {
      cell.open = true;
      cell.boom = true;
      next[index] = cell;
      this.revealMines(next);
      this.cells = next;
      this.finish(false);
      return;
    }
    this.openSafeCells(next, index);
    this.cells = next;
    if (this.openCount() >= this.rows() * this.cols() - this.mineCount()) {
      const done = this.cells.slice();
      done.forEach((item: MineCell) => {
        if (item.mine) {
          item.flag = true;
        }
      });
      this.cells = done;
      this.finish(true);
    }
  }

  private placeMines(firstIndex: number): void {
    const safe = this.safeZone(firstIndex);
    const total = this.rows() * this.cols();
    const next = this.cells.slice();
    let placed = 0;
    while (placed < this.mineCount()) {
      const index = Math.floor(Math.random() * total);
      if (safe.includes(index) || next[index].mine) {
        continue;
      }
      next[index].mine = true;
      placed += 1;
    }
    for (let i = 0; i < total; i += 1) {
      next[i].neighbor = this.neighbors(i).filter((neighbor: number) => next[neighbor].mine).length;
    }
    this.cells = next;
  }

  private openSafeCells(cells: MineCell[], index: number): void {
    const queue: number[] = [index];
    const seen: number[] = [];
    while (queue.length > 0) {
      const current = queue.shift();
      if (current === undefined || seen.includes(current)) {
        continue;
      }
      seen.push(current);
      const cell = cells[current];
      if (cell.flag || cell.mine) {
        continue;
      }
      cell.open = true;
      cells[current] = cell;
      if (cell.neighbor === 0) {
        this.neighbors(current).forEach((neighbor: number) => {
          if (!seen.includes(neighbor)) {
            queue.push(neighbor);
          }
        });
      }
    }
  }

  private revealMines(cells: MineCell[]): void {
    cells.forEach((cell: MineCell) => {
      if (cell.mine) {
        cell.open = true;
      }
    });
  }

  private finish(won: boolean): void {
    if (this.settled) {
      return;
    }
    this.settled = true;
    this.win = won;
    this.gameOver = true;
    this.stopTimer();
    this.recordScore(this.currentScore());
  }

  private safeZone(index: number): number[] {
    const safe = this.neighbors(index);
    safe.push(index);
    return safe;
  }

  private neighbors(index: number): number[] {
    const result: number[] = [];
    const row = Math.floor(index / this.cols());
    const col = index % this.cols();
    for (let dr = -1; dr <= 1; dr += 1) {
      for (let dc = -1; dc <= 1; dc += 1) {
        if (dr === 0 && dc === 0) {
          continue;
        }
        const nr = row + dr;
        const nc = col + dc;
        if (nr >= 0 && nr < this.rows() && nc >= 0 && nc < this.cols()) {
          result.push(nr * this.cols() + nc);
        }
      }
    }
    return result;
  }

  private difficulty(): MineDifficulty {
    const found = DIFFICULTIES.find((item: MineDifficulty) => item.key === this.difficultyKey);
    return found === undefined ? DIFFICULTIES[0] : found;
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
    return this.mineCount() - this.cells.filter((cell: MineCell) => cell.flag).length;
  }

  private openCount(): number {
    return this.cells.filter((cell: MineCell) => cell.open && !cell.mine).length;
  }

  private currentScore(): number {
    if (this.win) {
      return Math.max(1, 10000 - this.elapsed * 8 + this.mineCount() * 20);
    }
    return this.openCount();
  }

  private timeText(): string {
    const minutes = Math.floor(this.elapsed / 60);
    const seconds = this.elapsed % 60;
    return `${minutes < 10 ? '0' : ''}${minutes}:${seconds < 10 ? '0' : ''}${seconds}`;
  }

  private cellSize(): number {
    return Math.floor(Math.min((this.pageWidth - 32) / this.cols(), (this.pageHeight - 180) / this.rows()));
  }

  private boardWidth(): number {
    return this.cellSize() * this.cols() + 8;
  }

  private boardHeight(): number {
    return this.cellSize() * this.rows() + 8;
  }

  private columnsTemplate(): string {
    let value = '1fr';
    for (let i = 1; i < this.cols(); i += 1) {
      value += ' 1fr';
    }
    return value;
  }

  private openCellText(cell: MineCell): string {
    if (cell.mine) {
      return cell.boom ? '×' : '●';
    }
    return cell.neighbor > 0 ? `${cell.neighbor}` : '';
  }

  private numberColor(value: number): string {
    if (value === 1) return '#0000ff';
    if (value === 2) return '#008000';
    if (value === 3) return '#ff0000';
    if (value === 4) return '#000080';
    if (value === 5) return '#800000';
    if (value === 6) return '#008080';
    if (value === 7) return '#000000';
    return '#808080';
  }
}
