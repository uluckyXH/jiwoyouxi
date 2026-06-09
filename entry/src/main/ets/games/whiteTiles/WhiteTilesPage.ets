import { CoopTheme } from '../../design/CoopTheme';

interface TileRow {
  id: number;
  y: number;
  blackCol: number;
  hit: boolean;
  missed: boolean;
}

@Component
export struct WhiteTilesPage {
  @Prop bestScore: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  private timer: number = -1;
  private nextId: number = 1;
  private settled: boolean = false;
  @State pageWidth: number = 390;
  @State pageHeight: number = 760;
  @State rows: TileRow[] = [];
  @State score: number = 0;
  @State speed: number = 3;
  @State paused: boolean = false;
  @State started: boolean = false;
  @State gameOver: boolean = false;
  @State errorCol: number = -1;
  @State errorRowId: number = -1;
  @State tick: number = 0;

  aboutToAppear(): void {
    this.restart();
  }

  aboutToDisappear(): void {
    this.stopLoop();
  }

  build() {
    Stack() {
      Column() {
        this.TopBar()
        Stack({ alignContent: Alignment.TopStart }) {
          ForEach(this.rows, (row: TileRow) => {
            this.RowView(row)
          }, (row: TileRow) => `${row.id}`)
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#ffffff')
        .clip(true)
        .onAreaChange((oldArea, newArea) => {
          const width = Number.parseFloat(`${newArea.width}`);
          const height = Number.parseFloat(`${newArea.height}`);
          if (!Number.isNaN(width) && !Number.isNaN(height)) {
            const oldHeight = this.pageHeight;
            this.pageWidth = Math.max(280, width);
            this.pageHeight = Math.max(420, height);
            if (this.rows.length === 0 || (this.score === 0 && !this.gameOver && Math.abs(oldHeight - this.pageHeight) > 12)) {
              this.seedRows();
            }
          }
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(CoopTheme.bg)
      .linearGradient({
        angle: 180,
        colors: [['#edf9ff', 0], ['#fff8ea', 0.48], ['#f7fbff', 1]]
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
      Column({ space: 1 }) {
        Text('别踩白块')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
        Text(this.speedHint())
          .fontSize(11)
          .fontColor(this.speedColor())
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(`${this.score}`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
      Text(`最高 ${Math.max(this.bestScore, this.score)}`)
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
  RowView(row: TileRow) {
    Row() {
      ForEach([0, 1, 2, 3], (col: number) => {
        Row()
          .layoutWeight(1)
          .height(this.tileHeight())
          .backgroundColor(this.cellColor(row, col))
          .border({ width: 0.5, color: '#e5e7eb' })
          .onClick(() => {
            this.handleTap(row.id, col);
          })
      }, (col: number) => `${row.id}-${col}`)
    }
    .position({ x: 0, y: row.y })
    .width('100%')
    .height(this.tileHeight())
  }

  @Builder
  PauseOverlay() {
    Column({ space: 12 }) {
      Text('已暂停')
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
      Text('游戏结束')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
      Text(`本局 ${this.score} 行 · 最高 ${Math.max(this.bestScore, this.score)}`)
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
    .width(Math.min(this.pageWidth - 36, 340))
    .padding(18)
    .borderRadius(8)
    .backgroundColor(CoopTheme.glassStrong)
    .border({ width: 1, color: CoopTheme.glassLine })
    .shadow(CoopTheme.shadow)
  }

  private restart(): void {
    this.stopLoop();
    this.nextId = 1;
    this.score = 0;
    this.speed = 3;
    this.paused = false;
    this.started = false;
    this.gameOver = false;
    this.errorCol = -1;
    this.errorRowId = -1;
    this.settled = false;
    this.seedRows();
    this.startLoop();
  }

  private seedRows(): void {
    const next: TileRow[] = [];
    for (let i = -2; i <= 3; i += 1) {
      next.push(this.makeRow(i * this.tileHeight()));
    }
    this.rows = next;
  }

  private makeRow(y: number): TileRow {
    return {
      id: this.nextId++,
      y: y,
      blackCol: Math.floor(Math.random() * 4),
      hit: false,
      missed: false
    };
  }

  private startLoop(): void {
    if (this.timer !== -1) {
      return;
    }
    this.timer = setInterval(() => this.step(), 16);
  }

  private stopLoop(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  private step(): void {
    if (this.paused || this.gameOver || !this.started) {
      return;
    }
    const rowHeight = this.tileHeight();
    let next = this.rows.map((row: TileRow) => {
      return {
        id: row.id,
        y: row.y + this.speed,
        blackCol: row.blackCol,
        hit: row.hit,
        missed: row.missed
      } as TileRow;
    });
    for (let i = 0; i < next.length; i += 1) {
      if (!next[i].hit && next[i].y > this.pageHeight + Math.max(8, this.speed * 2)) {
        next[i].missed = true;
        this.rows = next;
        this.finishGame();
        return;
      }
    }
    next = next.filter((row: TileRow) => row.y <= this.pageHeight + rowHeight);
    let minY = this.pageHeight;
    next.forEach((row: TileRow) => {
      minY = Math.min(minY, row.y);
    });
    while (minY > -rowHeight * 3) {
      minY -= rowHeight;
      next.push(this.makeRow(minY));
    }
    this.rows = next;
    this.tick += 1;
  }

  private handleTap(rowId: number, col: number): void {
    if (this.paused || this.gameOver) {
      return;
    }
    const next = this.rows.slice();
    const index = next.findIndex((row: TileRow) => row.id === rowId);
    if (index < 0) {
      return;
    }
    const row = next[index];
    if (row.blackCol !== col || row.hit) {
      this.errorCol = col;
      this.errorRowId = row.id;
      this.finishGame();
      return;
    }
    this.started = true;
    row.hit = true;
    next[index] = row;
    this.rows = next;
    this.score += 1;
    this.speed = Math.min(15, this.speed + 0.03);
  }

  private finishGame(): void {
    if (this.settled) {
      return;
    }
    this.settled = true;
    this.gameOver = true;
    this.stopLoop();
    this.recordScore(this.score);
  }

  private tileHeight(): number {
    return Math.max(110, this.pageHeight / 4);
  }

  private cellColor(row: TileRow, col: number): string {
    if (row.missed && col === row.blackCol) {
      return '#ef4444';
    }
    if (this.errorRowId === row.id && this.errorCol === col && this.gameOver) {
      return '#fecaca';
    }
    if (col === row.blackCol) {
      return row.hit ? '#4b5563' : '#1f2937';
    }
    return '#ffffff';
  }

  private speedHint(): string {
    if (this.speed < 6) {
      return '速度 慢';
    }
    if (this.speed < 11) {
      return '速度 中';
    }
    return '速度 快';
  }

  private speedColor(): string {
    if (this.speed < 6) {
      return '#16a34a';
    }
    if (this.speed < 11) {
      return '#d97706';
    }
    return '#dc2626';
  }
}
