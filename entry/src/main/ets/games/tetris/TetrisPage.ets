import { CoopTheme } from '../../design/CoopTheme';

interface Offset {
  x: number;
  y: number;
}

interface PieceDef {
  name: string;
  color: string;
  cells: Offset[];
}

interface TetrisPiece {
  kind: number;
  x: number;
  y: number;
  rotation: number;
}

const PIECES: PieceDef[] = [
  { name: 'I', color: '#06b6d4', cells: [{ x: -1, y: 0 }, { x: 0, y: 0 }, { x: 1, y: 0 }, { x: 2, y: 0 }] },
  { name: 'O', color: '#eab308', cells: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 0, y: 1 }, { x: 1, y: 1 }] },
  { name: 'T', color: '#8b5cf6', cells: [{ x: -1, y: 0 }, { x: 0, y: 0 }, { x: 1, y: 0 }, { x: 0, y: 1 }] },
  { name: 'S', color: '#22c55e', cells: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: -1, y: 1 }, { x: 0, y: 1 }] },
  { name: 'Z', color: '#ef4444', cells: [{ x: -1, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 1 }, { x: 1, y: 1 }] },
  { name: 'J', color: '#3b82f6', cells: [{ x: -1, y: 0 }, { x: -1, y: 1 }, { x: 0, y: 1 }, { x: 1, y: 1 }] },
  { name: 'L', color: '#f97316', cells: [{ x: 1, y: 0 }, { x: -1, y: 1 }, { x: 0, y: 1 }, { x: 1, y: 1 }] }
];

const DROP_INTERVALS: number[] = [800, 717, 633, 550, 467, 383, 300, 217, 133, 100];
const BOARD_COLS: number = 10;
const BOARD_ROWS: number = 20;

@Component
export struct TetrisPage {
  @Prop bestScore: number = 0;
  @Prop @Watch('onSessionChanged') session: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  private timer: number = -1;
  private settled: boolean = false;
  private bag: number[] = [];
  private lastDropAt: number = 0;
  private lockStartedAt: number = 0;
  private lockResetCount: number = 0;
  private moveRepeatTimer: number = -1;
  private controlHoldTimer: number = -1;
  private controlLongTriggered: boolean = false;
  private controlTouchTarget: string = '';
  @State pageWidth: number = 390;
  @State pageHeight: number = 760;
  @State current: TetrisPiece = { kind: 0, x: 4, y: 0, rotation: 0 };
  @State nextQueue: number[] = [];
  @State holdKind: number = -1;
  @State holdUsed: boolean = false;
  @State board: number[] = [];
  @State score: number = 0;
  @State lines: number = 0;
  @State level: number = 1;
  @State combo: number = 0;
  @State lastClear: number = 0;
  @State lockActive: boolean = false;
  @State paused: boolean = false;
  @State gameOver: boolean = false;
  @State tick: number = 0;

  aboutToAppear(): void {
    this.restart();
  }

  aboutToDisappear(): void {
    this.stopControlTimers();
    this.stopLoop();
  }

  onSessionChanged(): void {
    this.restart();
  }

  build() {
    Stack() {
      Column({ space: 12 }) {
        this.TopBar()
        this.GameMainArea()
        this.ControlPanel()
        Blank()
      }
      .width('100%')
      .height('100%')
      .linearGradient({
        angle: 180,
        colors: [['#fff8ea', 0], ['#f7efe0', 0.52], ['#eef8ff', 1]]
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
      Button('← 大厅')
        .width(78)
        .height(38)
        .borderRadius(20)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#FFF8EA')
        .fontColor(CoopTheme.ink)
        .border({ width: 1, color: '#F2DFBF' })
        .shadow({
          radius: 10,
          color: 'rgba(47,29,20,0.08)',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(() => {
          this.stopControlTimers();
          this.exitToHub();
        })
      Column({ space: 0 }) {
        Text('🐔')
          .fontSize(13)
          .height(15)
          .textAlign(TextAlign.Center)
        Text('俄罗斯方块')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .height(42)
      .layoutWeight(1)
      Row({ space: 6 }) {
        Text(`最高 ${Math.max(this.bestScore, this.score)}`)
          .height(34)
          .padding({ left: 10, right: 10 })
          .borderRadius(18)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(CoopTheme.brandDark)
          .textAlign(TextAlign.Center)
          .backgroundColor('rgba(255,248,234,0.84)')
          .border({ width: 1, color: '#F2DFBF' })
        Text(this.paused ? '继续' : '暂停')
          .width(62)
          .height(34)
          .borderRadius(18)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(CoopTheme.ink)
          .fontColor('#ffffff')
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.stopControlTimers();
            this.paused = !this.paused;
          })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(92)
    .padding({ left: 14, right: 14, top: 30 })
    .backgroundColor('rgba(255,255,255,0.46)')
    .border({ width: { bottom: 1 }, color: 'rgba(242,223,191,0.72)' })
    .shadow({
      radius: 20,
      color: 'rgba(90,64,36,0.08)',
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  GameMainArea() {
    Row({ space: 7 }) {
      Column({ space: 7 }) {
        this.HoldBox()
        this.StatBox('分数', `${this.score}`)
        this.StatBox('行数', `${this.lines}`)
        this.StatBox('等级', `${this.level}`)
      }
      .width(this.leftPanelWidth())
      this.Board()
      Column({ space: 7 }) {
        this.NextQueueBox()
        this.StatusChip()
      }
      .width(this.rightPanelWidth())
    }
    .width('100%')
    .padding({ left: 7, right: 7 })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  Board() {
    Stack() {
      Grid() {
        ForEach(this.gridIndexes(), (index: number) => {
          GridItem() {
            Row()
              .width('100%')
              .height(this.cellSize())
              .backgroundColor(this.colorAt(index))
              .border({ width: 0.5, color: this.cellBorderAt(index) })
          }
        }, (index: number) => `${index}-${this.tick}-${this.board[index]}`)
      }
      .columnsTemplate(this.boardColumnsTemplate())
      .rowsGap(1)
      .columnsGap(1)
      .width(this.boardWidth())
      .height(this.boardHeight())
      .padding(5)
      .backgroundColor('#151D24')
      .border({ width: 1, color: '#2B3640' })
      .borderRadius(14)
      .clip(true)
    }
    .padding(7)
    .backgroundColor('#FFF8EA')
    .border({ width: 1, color: '#E9D6B8' })
    .borderRadius(20)
    .shadow({
      radius: 22,
      color: 'rgba(0,0,0,0.13)',
      offsetX: 0,
      offsetY: 10
    })
  }

  @Builder
  StatBox(label: string, value: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(11)
        .fontColor(CoopTheme.muted)
      Text(value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
        .maxLines(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 9, bottom: 9, left: 5, right: 5 })
    .borderRadius(20)
    .backgroundColor('#FFF8EA')
    .border({ width: 1, color: '#F2DFBF' })
    .shadow({
      radius: 10,
      color: 'rgba(47,29,20,0.07)',
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  HoldBox() {
    Column({ space: 8 }) {
      Text('暂存')
        .fontSize(11)
        .fontColor(CoopTheme.muted)
      if (this.holdKind >= 0) {
        this.MiniPiece(this.holdKind, `hold-${this.holdKind}-${this.tick}`)
        Text(PIECES[this.holdKind].name)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
      } else {
        Text('H')
          .width(this.previewSize())
          .height(this.previewSize())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('rgba(255,255,255,0.56)')
          .textAlign(TextAlign.Center)
          .backgroundColor('#151D24')
          .borderRadius(12)
      }
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .borderRadius(20)
    .backgroundColor('#FFF8EA')
    .border({ width: 1, color: '#F2DFBF' })
    .shadow({
      radius: 10,
      color: 'rgba(47,29,20,0.07)',
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  NextQueueBox() {
    Column({ space: 9 }) {
      Text('下个')
        .fontSize(11)
        .fontColor(CoopTheme.muted)
      ForEach(this.previewSlots(), (slot: number) => {
        Column({ space: 3 }) {
          this.MiniPiece(this.nextKindAt(slot), `queue-${slot}-${this.queueKey()}-${this.tick}`)
          if (slot === 0) {
            Text(PIECES[this.nextKindAt(slot)].name)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(CoopTheme.ink)
          }
        }
      }, (slot: number) => `queue-slot-${slot}-${this.queueKey()}-${this.tick}`)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .borderRadius(20)
    .backgroundColor('#FFF8EA')
    .border({ width: 1, color: '#F2DFBF' })
    .shadow({
      radius: 10,
      color: 'rgba(47,29,20,0.07)',
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  MiniPiece(kind: number, keyPrefix: string) {
    Grid() {
      ForEach(this.previewIndexes(), (index: number) => {
        GridItem() {
          Row()
            .width('100%')
            .height(this.previewCellSize())
            .backgroundColor(this.previewColorAt(index, kind))
            .border({ width: 0.5, color: 'rgba(255,255,255,0.32)' })
        }
      }, (index: number) => `${keyPrefix}-${index}`)
    }
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .rowsGap(2)
    .columnsGap(2)
    .width(this.previewSize())
    .height(this.previewSize())
    .padding(4)
    .borderRadius(12)
    .backgroundColor('#151D24')
  }

  @Builder
  StatusChip() {
    Column({ space: 5 }) {
      Text(this.statusLabel())
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.lockActive ? '#B42318' : CoopTheme.brandDark)
        .textAlign(TextAlign.Center)
      Text(this.statusDetail())
        .fontSize(10)
        .fontColor(CoopTheme.muted)
        .maxLines(2)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10, left: 5, right: 5 })
    .borderRadius(20)
    .backgroundColor(this.lockActive ? '#FFE7DD' : '#FFF8EA')
    .border({ width: 1, color: '#F2DFBF' })
  }

  @Builder
  ControlPanel() {
    Column() {
      Row({ space: 14 }) {
        Column({ space: 12 }) {
          Row({ space: this.controlButtonGap() }) {
            this.RepeatControlButton('←', () => {
              this.moveLeft();
            })
            this.RepeatControlButton('→', () => {
              this.moveRight();
            })
          }
          .justifyContent(FlexAlign.Center)
          this.DownButton()
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        this.RotateButton()
      }
      .width('100%')
      .height(this.controlPanelHeight())
      .padding({ left: 18, right: 18, top: 18, bottom: 18 })
      .backgroundColor('#FFF8EA')
      .borderRadius(32)
      .border({ width: 1, color: '#F2DFBF' })
      .shadow({
        radius: 18,
        color: 'rgba(47,29,20,0.12)',
        offsetX: 0,
        offsetY: 8
      })
      .alignItems(VerticalAlign.Center)
      .onTouch((event: TouchEvent) => {
        this.handleControlTouch(event);
      })
    }
    .width('100%')
    .padding({ left: 24, right: 24, bottom: 18 })
  }

  @Builder
  RepeatControlButton(label: string, action: () => void) {
    Text(label)
      .width(this.controlButtonWidth())
      .height(this.controlButtonHeight())
      .borderRadius(24)
      .fontSize(32)
      .fontWeight(FontWeight.Bold)
      .fontColor('#3A2418')
      .textAlign(TextAlign.Center)
      .backgroundColor('#FFF6E5')
      .border({ width: 1, color: '#F2DFBF' })
      .shadow({
        radius: 10,
        color: 'rgba(0,0,0,0.12)',
        offsetX: 0,
        offsetY: 4
      })
  }

  @Builder
  DownButton() {
    Text('↓')
      .width(this.controlButtonWidth())
      .height(this.controlButtonHeight())
      .borderRadius(24)
      .fontSize(34)
      .fontWeight(FontWeight.Bold)
      .fontColor('#3A2418')
      .textAlign(TextAlign.Center)
      .backgroundColor('#FFF6E5')
      .border({ width: 1, color: '#F2DFBF' })
      .shadow({
        radius: 10,
        color: 'rgba(0,0,0,0.12)',
        offsetX: 0,
        offsetY: 4
      })
  }

  @Builder
  RotateButton() {
    Text('↻')
      .width(this.rotateButtonSize())
      .height(this.rotateButtonSize())
      .borderRadius(this.rotateButtonSize() / 2)
      .fontSize(42)
      .fontWeight(FontWeight.Bold)
      .fontColor('#FFFFFF')
      .textAlign(TextAlign.Center)
      .backgroundColor('#7B61FF')
      .border({ width: 1, color: 'rgba(255,255,255,0.34)' })
      .shadow({
        radius: 18,
        color: 'rgba(123,97,255,0.36)',
        offsetX: 0,
        offsetY: 8
      })
  }

  @Builder
  PauseOverlay() {
    Column({ space: 12 }) {
      Text('方块暂停')
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
      Text(`本局 ${this.score} · 最高 ${Math.max(this.bestScore, this.score)}`)
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

  private handleControlTouch(event: TouchEvent): void {
    const point = this.controlTouchPoint(event);
    if (event.type === TouchType.Down) {
      this.startControlTouch(point.x, point.y);
      return;
    }
    if (event.type === TouchType.Up) {
      this.finishControlTouch(false);
      return;
    }
    if (event.type === TouchType.Cancel) {
      this.finishControlTouch(true);
    }
  }

  private controlTouchPoint(event: TouchEvent): Offset {
    if (event.touches !== undefined && event.touches.length > 0) {
      return { x: event.touches[0].x, y: event.touches[0].y };
    }
    if (event.changedTouches !== undefined && event.changedTouches.length > 0) {
      return { x: event.changedTouches[0].x, y: event.changedTouches[0].y };
    }
    return { x: 0, y: 0 };
  }

  private startControlTouch(x: number, y: number): void {
    this.stopControlTimers();
    this.controlTouchTarget = this.controlTargetAt(x, y);
    this.controlLongTriggered = false;
    if (this.controlTouchTarget === 'left' || this.controlTouchTarget === 'right') {
      this.controlHoldTimer = setTimeout(() => {
        this.controlHoldTimer = -1;
        this.controlLongTriggered = true;
        this.triggerControlTarget(this.controlTouchTarget);
        this.moveRepeatTimer = setInterval(() => {
          this.triggerControlTarget(this.controlTouchTarget);
        }, 80);
      }, 180);
      return;
    }
    if (this.controlTouchTarget === 'down') {
      this.controlHoldTimer = setTimeout(() => {
        this.controlHoldTimer = -1;
        this.controlLongTriggered = true;
        this.hardDrop();
      }, 350);
    }
  }

  private finishControlTouch(cancelled: boolean): void {
    const target = this.controlTouchTarget;
    const wasLong = this.controlLongTriggered;
    this.clearControlHoldTimer();
    this.stopRepeatMove();
    this.controlTouchTarget = '';
    this.controlLongTriggered = false;
    if (cancelled || wasLong) {
      return;
    }
    this.triggerControlTarget(target);
  }

  private clearControlHoldTimer(): void {
    if (this.controlHoldTimer !== -1) {
      clearTimeout(this.controlHoldTimer);
      this.controlHoldTimer = -1;
    }
  }

  private stopRepeatMove(): void {
    if (this.moveRepeatTimer !== -1) {
      clearInterval(this.moveRepeatTimer);
      this.moveRepeatTimer = -1;
    }
  }

  private triggerControlTarget(target: string): void {
    if (target === 'left') {
      this.moveLeft();
      return;
    }
    if (target === 'right') {
      this.moveRight();
      return;
    }
    if (target === 'down') {
      this.softDrop();
      return;
    }
    if (target === 'rotate') {
      this.rotatePiece();
    }
  }

  private controlTargetAt(x: number, y: number): string {
    const panelWidth = Math.max(1, this.pageWidth - 48);
    const panelHeight = this.controlPanelHeight();
    const rotateStart = panelWidth - this.rotateButtonSize() - 26;
    if (x >= rotateStart) {
      return 'rotate';
    }
    if (y >= panelHeight * 0.55) {
      return 'down';
    }
    const directionWidth = Math.max(1, rotateStart - 14);
    return x < directionWidth / 2 ? 'left' : 'right';
  }

  private stopControlTimers(): void {
    this.clearControlHoldTimer();
    this.stopRepeatMove();
    this.controlTouchTarget = '';
    this.controlLongTriggered = false;
  }

  private restart(): void {
    this.stopControlTimers();
    this.stopLoop();
    this.board = new Array(BOARD_ROWS * BOARD_COLS).fill(0);
    this.score = 0;
    this.lines = 0;
    this.level = 1;
    this.combo = 0;
    this.lastClear = 0;
    this.lockActive = false;
    this.paused = false;
    this.gameOver = false;
    this.settled = false;
    this.bag = [];
    this.nextQueue = [];
    this.holdKind = -1;
    this.holdUsed = false;
    this.ensureNextQueue();
    this.lastDropAt = Date.now();
    this.lockStartedAt = 0;
    this.lockResetCount = 0;
    this.spawn();
    this.startLoop();
  }

  private startLoop(): void {
    if (this.timer !== -1) {
      return;
    }
    this.timer = setInterval(() => {
      this.gameTick();
    }, 50);
  }

  private restartLoop(): void {
    this.lastDropAt = Date.now();
  }

  private stopLoop(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  private gameTick(): void {
    if (this.paused || this.gameOver) {
      return;
    }
    const now = Date.now();
    if (now - this.lastDropAt >= this.dropInterval()) {
      if (this.moveInternal(0, 1, false)) {
        this.lastDropAt = now;
        this.clearLockDelay();
      } else {
        this.handleGrounded(now);
      }
      return;
    }
    if (this.isGrounded()) {
      this.handleGrounded(now);
    } else if (this.lockActive) {
      this.clearLockDelay();
    }
  }

  private spawn(): void {
    this.current = { kind: this.takeNextKind(), x: 4, y: 0, rotation: 0 };
    this.holdUsed = false;
    this.lastDropAt = Date.now();
    this.clearLockDelay();
    if (this.collides(this.current)) {
      this.finish();
    }
    this.tick += 1;
  }

  private takeNextKind(): number {
    this.ensureNextQueue();
    const next = this.nextQueue.shift();
    this.ensureNextQueue();
    return next === undefined ? this.drawKind() : next;
  }

  private ensureNextQueue(): void {
    while (this.nextQueue.length < 5) {
      this.nextQueue.push(this.drawKind());
    }
  }

  private drawKind(): number {
    if (this.bag.length === 0) {
      this.bag = [0, 1, 2, 3, 4, 5, 6];
      for (let i = this.bag.length - 1; i > 0; i -= 1) {
        const j = Math.floor(Math.random() * (i + 1));
        const value = this.bag[i];
        this.bag[i] = this.bag[j];
        this.bag[j] = value;
      }
    }
    const next = this.bag.shift();
    return next === undefined ? 0 : next;
  }

  private moveInternal(dx: number, dy: number, userAction: boolean): boolean {
    if (this.paused || this.gameOver) {
      return false;
    }
    const next: TetrisPiece = {
      kind: this.current.kind,
      x: this.current.x + dx,
      y: this.current.y + dy,
      rotation: this.current.rotation
    };
    if (this.collides(next)) {
      return false;
    }
    this.current = next;
    if (userAction && dy === 0 && this.isGrounded()) {
      this.resetLockDelay();
    }
    this.tick += 1;
    return true;
  }

  private moveLeft(): void {
    this.moveInternal(-1, 0, true);
  }

  private moveRight(): void {
    this.moveInternal(1, 0, true);
  }

  private rotatePiece(): void {
    this.rotateWithDirection(1);
  }

  private rotateWithDirection(direction: number): void {
    if (this.paused || this.gameOver) {
      return;
    }
    const fromRotation = this.current.rotation;
    const nextRotation = (this.current.rotation + direction + 4) % 4;
    const kicks = this.wallKicks(this.current.kind, fromRotation, nextRotation);
    for (let i = 0; i < kicks.length; i += 1) {
      const candidate: TetrisPiece = {
        kind: this.current.kind,
        x: this.current.x + kicks[i].x,
        y: this.current.y + kicks[i].y,
        rotation: nextRotation
      };
      if (!this.collides(candidate)) {
        this.current = candidate;
        if (this.isGrounded()) {
          this.resetLockDelay();
        }
        this.tick += 1;
        return;
      }
    }
  }

  private holdPiece(): void {
    if (this.paused || this.gameOver || this.holdUsed) {
      return;
    }
    const currentKind = this.current.kind;
    let incomingKind = this.holdKind;
    if (this.holdKind < 0) {
      incomingKind = this.nextKindAt(0);
    }
    const candidate: TetrisPiece = { kind: incomingKind, x: 4, y: 0, rotation: 0 };
    if (this.collides(candidate)) {
      return;
    }
    if (this.holdKind < 0) {
      this.takeNextKind();
    }
    this.holdKind = currentKind;
    this.current = candidate;
    this.holdUsed = true;
    this.lastDropAt = Date.now();
    this.clearLockDelay();
    this.tick += 1;
  }

  private softDrop(): void {
    if (this.moveInternal(0, 1, false)) {
      this.score += 1;
      this.lastDropAt = Date.now();
      this.clearLockDelay();
    } else if (this.isGrounded()) {
      this.handleGrounded(Date.now());
    }
  }

  private hardDrop(): void {
    if (this.paused || this.gameOver) {
      return;
    }
    let moved = 0;
    while (this.moveInternal(0, 1, false)) {
      moved += 1;
    }
    this.score += moved * 2;
    this.lockAndSpawn();
  }

  private handleGrounded(now: number): void {
    if (this.lockStartedAt === 0) {
      this.lockStartedAt = now;
      this.lockActive = true;
      this.tick += 1;
      return;
    }
    if (now - this.lockStartedAt >= 500) {
      this.lockAndSpawn();
    }
  }

  private lockAndSpawn(): void {
    this.clearLockDelay();
    this.lockPiece();
    const cleared = this.clearLines();
    if (cleared > 0) {
      this.lastClear = cleared;
      this.combo += 1;
      if (this.combo > 1) {
        this.score += (this.combo - 1) * 50 * this.level;
      }
    } else {
      this.lastClear = 0;
      this.combo = 0;
    }
    this.spawn();
  }

  private clearLockDelay(): void {
    this.lockStartedAt = 0;
    this.lockResetCount = 0;
    this.lockActive = false;
  }

  private resetLockDelay(): void {
    if (this.lockResetCount >= 15) {
      return;
    }
    this.lockStartedAt = Date.now();
    this.lockResetCount += 1;
    this.lockActive = true;
  }

  private isGrounded(): boolean {
    return this.collides({
      kind: this.current.kind,
      x: this.current.x,
      y: this.current.y + 1,
      rotation: this.current.rotation
    });
  }

  private dropInterval(): number {
    const index = Math.min(DROP_INTERVALS.length - 1, Math.max(0, this.level - 1));
    return DROP_INTERVALS[index];
  }

  private wallKicks(kind: number, fromRotation: number, toRotation: number): Offset[] {
    if (kind === 1) {
      return [{ x: 0, y: 0 }];
    }
    if (kind === 0) {
      return this.iWallKicks(fromRotation, toRotation);
    }
    return this.standardWallKicks(fromRotation, toRotation);
  }

  private standardWallKicks(fromRotation: number, toRotation: number): Offset[] {
    const transition = `${fromRotation}-${toRotation}`;
    if (transition === '0-1') {
      return [{ x: 0, y: 0 }, { x: -1, y: 0 }, { x: -1, y: 1 }, { x: 0, y: -2 }, { x: -1, y: -2 }];
    }
    if (transition === '1-0') {
      return [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: -1 }, { x: 0, y: 2 }, { x: 1, y: 2 }];
    }
    if (transition === '1-2') {
      return [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: -1 }, { x: 0, y: 2 }, { x: 1, y: 2 }];
    }
    if (transition === '2-1') {
      return [{ x: 0, y: 0 }, { x: -1, y: 0 }, { x: -1, y: 1 }, { x: 0, y: -2 }, { x: -1, y: -2 }];
    }
    if (transition === '2-3') {
      return [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 1 }, { x: 0, y: -2 }, { x: 1, y: -2 }];
    }
    if (transition === '3-2') {
      return [{ x: 0, y: 0 }, { x: -1, y: 0 }, { x: -1, y: -1 }, { x: 0, y: 2 }, { x: -1, y: 2 }];
    }
    if (transition === '3-0') {
      return [{ x: 0, y: 0 }, { x: -1, y: 0 }, { x: -1, y: -1 }, { x: 0, y: 2 }, { x: -1, y: 2 }];
    }
    if (transition === '0-3') {
      return [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 1 }, { x: 0, y: -2 }, { x: 1, y: -2 }];
    }
    return [{ x: 0, y: 0 }];
  }

  private iWallKicks(fromRotation: number, toRotation: number): Offset[] {
    const transition = `${fromRotation}-${toRotation}`;
    if (transition === '0-1') {
      return [{ x: 0, y: 0 }, { x: -2, y: 0 }, { x: 1, y: 0 }, { x: -2, y: -1 }, { x: 1, y: 2 }];
    }
    if (transition === '1-0') {
      return [{ x: 0, y: 0 }, { x: 2, y: 0 }, { x: -1, y: 0 }, { x: 2, y: 1 }, { x: -1, y: -2 }];
    }
    if (transition === '1-2') {
      return [{ x: 0, y: 0 }, { x: -1, y: 0 }, { x: 2, y: 0 }, { x: -1, y: 2 }, { x: 2, y: -1 }];
    }
    if (transition === '2-1') {
      return [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: -2, y: 0 }, { x: 1, y: -2 }, { x: -2, y: 1 }];
    }
    if (transition === '2-3') {
      return [{ x: 0, y: 0 }, { x: 2, y: 0 }, { x: -1, y: 0 }, { x: 2, y: 1 }, { x: -1, y: -2 }];
    }
    if (transition === '3-2') {
      return [{ x: 0, y: 0 }, { x: -2, y: 0 }, { x: 1, y: 0 }, { x: -2, y: -1 }, { x: 1, y: 2 }];
    }
    if (transition === '3-0') {
      return [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: -2, y: 0 }, { x: 1, y: -2 }, { x: -2, y: 1 }];
    }
    if (transition === '0-3') {
      return [{ x: 0, y: 0 }, { x: -1, y: 0 }, { x: 2, y: 0 }, { x: -1, y: 2 }, { x: 2, y: -1 }];
    }
    return [{ x: 0, y: 0 }];
  }

  private lockPiece(): void {
    const next = this.board.slice();
    const cells = this.cellsFor(this.current);
    cells.forEach((cell: Offset) => {
      if (cell.y >= 0 && cell.y < BOARD_ROWS && cell.x >= 0 && cell.x < BOARD_COLS) {
        next[cell.y * BOARD_COLS + cell.x] = this.current.kind + 1;
      }
    });
    this.board = next;
  }

  private clearLines(): number {
    const next: number[] = [];
    let cleared = 0;
    for (let row = 0; row < BOARD_ROWS; row += 1) {
      let full = true;
      for (let col = 0; col < BOARD_COLS; col += 1) {
        if (this.board[row * BOARD_COLS + col] === 0) {
          full = false;
          break;
        }
      }
      if (full) {
        cleared += 1;
      } else {
        for (let col = 0; col < BOARD_COLS; col += 1) {
          next.push(this.board[row * BOARD_COLS + col]);
        }
      }
    }
    while (next.length < BOARD_ROWS * BOARD_COLS) {
      next.unshift(0);
    }
    if (cleared > 0) {
      const scores = [0, 100, 300, 500, 800];
      this.score += scores[cleared] * this.level;
      this.lines += cleared;
      const nextLevel = Math.floor(this.lines / 10) + 1;
      if (nextLevel !== this.level) {
        this.level = nextLevel;
        this.restartLoop();
      }
      this.board = next;
    }
    return cleared;
  }

  private finish(): void {
    if (this.settled) {
      return;
    }
    this.settled = true;
    this.gameOver = true;
    this.stopLoop();
    this.recordScore(this.score);
  }

  private collides(piece: TetrisPiece): boolean {
    const cells = this.cellsFor(piece);
    for (let i = 0; i < cells.length; i += 1) {
      const cell = cells[i];
      if (cell.x < 0 || cell.x >= BOARD_COLS || cell.y >= BOARD_ROWS) {
        return true;
      }
      if (cell.y >= 0 && this.board[cell.y * BOARD_COLS + cell.x] > 0) {
        return true;
      }
    }
    return false;
  }

  private cellsFor(piece: TetrisPiece): Offset[] {
    const result: Offset[] = [];
    PIECES[piece.kind].cells.forEach((base: Offset) => {
      let rotated: Offset = { x: base.x, y: base.y };
      if (piece.kind !== 1) {
        for (let i = 0; i < piece.rotation; i += 1) {
          rotated = { x: -rotated.y, y: rotated.x };
        }
      }
      result.push({ x: piece.x + rotated.x, y: piece.y + rotated.y });
    });
    return result;
  }

  private colorAt(index: number): string {
    const row = Math.floor(index / BOARD_COLS);
    const col = index % BOARD_COLS;
    const currentCell = this.cellsFor(this.current).find((cell: Offset) => cell.x === col && cell.y === row);
    if (currentCell !== undefined && !this.gameOver) {
      return PIECES[this.current.kind].color;
    }
    const ghostCell = this.cellsFor(this.ghostPiece()).find((cell: Offset) => cell.x === col && cell.y === row);
    if (ghostCell !== undefined && !this.gameOver) {
      return '#3A4A54';
    }
    const value = this.board[index];
    if (value > 0) {
      return PIECES[value - 1].color;
    }
    return row % 2 === 0 ? '#151D24' : '#121A21';
  }

  private cellBorderAt(index: number): string {
    const value = this.board[index];
    if (value > 0) {
      return 'rgba(255,255,255,0.30)';
    }
    return '#2B3640';
  }

  private ghostPiece(): TetrisPiece {
    const ghost: TetrisPiece = {
      kind: this.current.kind,
      x: this.current.x,
      y: this.current.y,
      rotation: this.current.rotation
    };
    while (!this.collides({
      kind: ghost.kind,
      x: ghost.x,
      y: ghost.y + 1,
      rotation: ghost.rotation
    })) {
      ghost.y += 1;
    }
    return ghost;
  }

  private gridIndexes(): number[] {
    const indexes: number[] = [];
    for (let i = 0; i < BOARD_ROWS * BOARD_COLS; i += 1) {
      indexes.push(i);
    }
    return indexes;
  }

  private previewIndexes(): number[] {
    const indexes: number[] = [];
    for (let i = 0; i < 16; i += 1) {
      indexes.push(i);
    }
    return indexes;
  }

  private previewSlots(): number[] {
    return [0, 1, 2];
  }

  private nextKindAt(slot: number): number {
    const kind = this.nextQueue[slot];
    return kind === undefined ? 0 : kind;
  }

  private queueKey(): string {
    return this.nextQueue.join('-');
  }

  private previewColorAt(index: number, kind: number): string {
    const row = Math.floor(index / 4);
    const col = index % 4;
    const found = this.previewCells(kind).find((cell: Offset) => cell.x === col && cell.y === row);
    if (found !== undefined) {
      return PIECES[kind].color;
    }
    return 'rgba(255,255,255,0.08)';
  }

  private previewCells(kind: number): Offset[] {
    const baseCells = PIECES[kind].cells;
    let minX = 99;
    let maxX = -99;
    let minY = 99;
    let maxY = -99;
    baseCells.forEach((cell: Offset) => {
      minX = Math.min(minX, cell.x);
      maxX = Math.max(maxX, cell.x);
      minY = Math.min(minY, cell.y);
      maxY = Math.max(maxY, cell.y);
    });
    const width = maxX - minX + 1;
    const height = maxY - minY + 1;
    const shiftX = Math.floor((4 - width) / 2) - minX;
    const shiftY = Math.floor((4 - height) / 2) - minY;
    const result: Offset[] = [];
    baseCells.forEach((cell: Offset) => {
      result.push({ x: cell.x + shiftX, y: cell.y + shiftY });
    });
    return result;
  }

  private boardColumnsTemplate(): string {
    let value = '1fr';
    for (let i = 1; i < BOARD_COLS; i += 1) {
      value += ' 1fr';
    }
    return value;
  }

  private statusLabel(): string {
    if (this.lockActive) {
      return '落地缓冲';
    }
    if (this.holdUsed) {
      return '暂存已用';
    }
    if (this.lastClear === 4) {
      return 'TETRIS';
    }
    if (this.lastClear > 0) {
      return `消 ${this.lastClear} 行`;
    }
    return '幽灵落点';
  }

  private statusDetail(): string {
    if (this.lockActive) {
      return `${Math.max(0, 15 - this.lockResetCount)} 次调整`;
    }
    if (this.combo > 1) {
      return `连消 ${this.combo} · 加分`;
    }
    return `${this.dropInterval()}ms · ${this.nextQueue.length} 队列`;
  }

  private leftPanelWidth(): number {
    return Math.max(60, Math.min(68, Math.floor(this.pageWidth * 0.17)));
  }

  private rightPanelWidth(): number {
    return Math.max(62, Math.min(70, Math.floor(this.pageWidth * 0.18)));
  }

  private boardWidth(): number {
    return this.cellSize() * BOARD_COLS + 9;
  }

  private boardHeight(): number {
    return this.cellSize() * BOARD_ROWS + 19;
  }

  private previewSize(): number {
    return Math.max(46, Math.min(56, this.leftPanelWidth() - 10));
  }

  private previewCellSize(): number {
    return Math.max(8, Math.floor((this.previewSize() - 14) / 4));
  }

  private controlPanelHeight(): number {
    return Math.max(180, Math.min(204, Math.floor(this.pageHeight * 0.245)));
  }

  private controlButtonGap(): number {
    return Math.max(12, Math.min(18, Math.floor(this.pageWidth * 0.04)));
  }

  private rotateButtonSize(): number {
    return Math.max(88, Math.min(108, Math.floor((this.pageWidth - 96) * 0.35)));
  }

  private controlButtonWidth(): number {
    const innerWidth = this.pageWidth - 84;
    const available = innerWidth - this.rotateButtonSize() - 14 - this.controlButtonGap();
    return Math.max(72, Math.min(88, Math.floor(available / 2)));
  }

  private controlButtonHeight(): number {
    return Math.max(56, Math.min(64, Math.floor(this.controlButtonWidth() * 0.74)));
  }

  private cellSize(): number {
    const widthBased = (this.pageWidth - this.leftPanelWidth() - this.rightPanelWidth() - 65) / BOARD_COLS;
    const heightBased = (this.pageHeight - this.controlPanelHeight() - 150) / BOARD_ROWS;
    return Math.max(14, Math.floor(Math.min(widthBased, heightBased, 22)));
  }
}
