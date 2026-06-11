import { CoopTheme } from '../../design/CoopTheme';
import { integrateFruits, resolveSuikaCollisions } from './SuikaPhysics';
import { clampAimX, getSpawnLevel, NEXT_FRUIT_DELAY_MS, resolveOverflowState } from './SuikaRules';
import { FRUITS, FruitBody, SuikaBounds } from './SuikaTypes';

@Component
export struct SuikaPage {
  @Prop bestScore: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private timer: number = -1;
  private nextId: number = 1;
  private fruits: FruitBody[] = [];
  private spawnIndex: number = 0;
  private currentLevel: number = 0;
  private nextLevel: number = 0;
  private hasCurrentFruit: boolean = true;
  private pendingSpawnAt: number = 0;
  private overflowSince: number = 0;
  private settled: boolean = false;
  private mergeText: string = '';
  private mergeTextX: number = 0;
  private mergeTextY: number = 0;
  private mergeTextUntil: number = 0;
  private finalMergeUntil: number = 0;
  @State pageWidth: number = 390;
  @State pageHeight: number = 760;
  @State score: number = 0;
  @State aimX: number = 195;
  @State paused: boolean = false;
  @State gameOver: boolean = false;
  @State tick: number = 0;

  aboutToAppear(): void {
    this.restart();
  }

  aboutToDisappear(): void {
    this.stopLoop();
  }

  build() {
    Stack() {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.draw();
        })
        .onAreaChange((oldArea, newArea) => {
          const width = Number.parseFloat(`${newArea.width}`);
          const height = Number.parseFloat(`${newArea.height}`);
          if (!Number.isNaN(width) && !Number.isNaN(height)) {
            this.pageWidth = Math.max(280, width);
            this.pageHeight = Math.max(420, height);
            this.aimX = this.containerLeft() + this.containerWidth() * 0.5;
            this.draw();
          }
        })
        .onTouch((event: TouchEvent) => {
          this.handleTouch(event);
        })

      this.TopBar()
      if (this.paused && !this.gameOver) {
        this.PauseOverlay()
      }
      if (this.gameOver) {
        this.ResultOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CoopTheme.bg)
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
      Column({ space: 2 }) {
        Text('鸡窝水果摊')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
        Text(`今日瓜分：${this.score} · 最高瓜分：${Math.max(this.bestScore, this.score)}`)
          .fontSize(12)
          .fontColor(CoopTheme.muted)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
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
    .position({ x: 0, y: 0 })
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
  PauseOverlay() {
    Column({ space: 12 }) {
      Text('水果摊暂停')
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
      Text('鸡窝被塞满了！')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
      Text(`今日瓜分：${this.score} · 最高瓜分：${Math.max(this.bestScore, this.score)}`)
        .fontSize(14)
        .fontColor(CoopTheme.muted)
      Button('再摆一摊')
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
    this.fruits = [];
    this.nextId = 1;
    this.spawnIndex = 0;
    this.currentLevel = getSpawnLevel(0);
    this.nextLevel = getSpawnLevel(1);
    this.hasCurrentFruit = true;
    this.score = 0;
    this.paused = false;
    this.gameOver = false;
    this.settled = false;
    this.pendingSpawnAt = 0;
    this.overflowSince = 0;
    this.mergeText = '';
    this.mergeTextUntil = 0;
    this.finalMergeUntil = 0;
    this.startLoop();
    this.draw();
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
    if (this.paused || this.gameOver) {
      this.draw();
      return;
    }
    const now = Date.now();
    this.activatePendingFruit(now);
    this.applyPhysics();
    this.resolveCollisions(now);
    this.checkOverflow(now);
    this.tick += 1;
    this.draw();
  }

  private handleTouch(event: TouchEvent): void {
    if (this.paused || this.gameOver) {
      return;
    }
    if (!this.hasCurrentFruit) {
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.dropFruit();
      return;
    }
    if (event.touches === undefined || event.touches.length === 0) {
      return;
    }
    const touch = event.touches[0];
    this.aimX = this.clampAimToCurrentFruit(touch.x);
  }

  private dropFruit(): void {
    const now = Date.now();
    if (!this.hasCurrentFruit) {
      return;
    }
    const radius = FRUITS[this.currentLevel].radius;
    const x = this.clampAimToCurrentFruit(this.aimX);
    this.fruits.push({
      id: this.nextId++,
      level: this.currentLevel,
      x: x,
      y: this.containerTop() - Math.max(24, radius * 0.55),
      vx: 0,
      vy: 0.8,
      bornAt: now,
      releasedAt: now,
      mergeLockedUntil: now + 120
    });
    this.spawnIndex += 1;
    this.currentLevel = this.nextLevel;
    this.nextLevel = getSpawnLevel(this.spawnIndex + 1);
    this.hasCurrentFruit = false;
    this.pendingSpawnAt = now + NEXT_FRUIT_DELAY_MS;
    this.aimX = this.clampAimToCurrentFruit(x);
  }

  private applyPhysics(): void {
    this.fruits = integrateFruits(this.fruits, FRUITS, this.containerBounds());
  }

  private resolveCollisions(now: number): void {
    const result = resolveSuikaCollisions(this.fruits, FRUITS, now, this.nextId);
    this.fruits = result.fruits;
    this.nextId = result.nextId;
    if (result.didMerge) {
      this.score += result.scoreDelta;
      this.mergeText = `+${result.scoreDelta}`;
      this.mergeTextX = result.mergeX;
      this.mergeTextY = result.mergeY;
      this.mergeTextUntil = now + 900;
      if (result.isFinalMerge) {
        this.finalMergeUntil = now + 1400;
      }
    }
  }

  private checkOverflow(now: number): void {
    const state = resolveOverflowState(this.fruits, FRUITS, this.failLineY(), now, this.overflowSince);
    this.overflowSince = state.overflowSince;
    if (state.shouldFinish) {
      this.finish();
    }
  }

  private activatePendingFruit(now: number): void {
    if (this.hasCurrentFruit || this.pendingSpawnAt === 0 || now < this.pendingSpawnAt) {
      return;
    }
    this.hasCurrentFruit = true;
    this.pendingSpawnAt = 0;
    this.aimX = this.clampAimToCurrentFruit(this.aimX);
  }

  private finish(): void {
    if (this.settled) {
      return;
    }
    this.settled = true;
    this.gameOver = true;
    this.stopLoop();
    this.recordScore(this.score);
    this.draw();
  }

  private draw(): void {
    const ctx = this.context;
    ctx.clearRect(0, 0, this.pageWidth, this.pageHeight);
    ctx.fillStyle = '#edf9ff';
    ctx.fillRect(0, 0, this.pageWidth, this.pageHeight);
    ctx.fillStyle = 'rgba(255,248,234,0.82)';
    ctx.fillRect(0, this.pageHeight * 0.34, this.pageWidth, this.pageHeight * 0.66);
    this.drawDropZone(ctx);
    this.drawContainer(ctx);
    for (let i = 0; i < this.fruits.length; i += 1) {
      this.drawFruit(ctx, this.fruits[i]);
    }
    this.drawMergeFeedback(ctx, Date.now());
  }

  private drawDropZone(ctx: CanvasRenderingContext2D): void {
    const def = FRUITS[this.currentLevel];
    ctx.fillStyle = 'rgba(255,255,255,0.74)';
    ctx.fillRect(12, 102, this.pageWidth - 24, 74);
    ctx.strokeStyle = 'rgba(255,255,255,0.92)';
    ctx.strokeRect(12, 102, this.pageWidth - 24, 74);
    ctx.fillStyle = CoopTheme.muted;
    ctx.font = '700 12vp sans-serif';
    ctx.textAlign = 'left';
    const title = this.hasCurrentFruit ? `手上 ${def.name}` : `备货 ${def.name}`;
    ctx.fillText(`${title} · 下个 ${FRUITS[this.nextLevel].name}`, 22, 128);
    ctx.beginPath();
    ctx.strokeStyle = this.hasCurrentFruit ? CoopTheme.ink : 'rgba(47,55,72,0.22)';
    ctx.lineWidth = 2;
    ctx.moveTo(this.aimX, 150);
    ctx.lineTo(this.aimX, this.containerTop() - 8);
    ctx.stroke();
    if (this.hasCurrentFruit) {
      ctx.beginPath();
      ctx.fillStyle = def.color;
      ctx.arc(this.aimX, 150, Math.max(10, def.radius * 0.55), 0, Math.PI * 2);
      ctx.fill();
      this.drawFruitFace(ctx, this.aimX, 150, Math.max(10, def.radius * 0.55));
    }
  }

  private drawContainer(ctx: CanvasRenderingContext2D): void {
    const left = this.containerLeft();
    const top = this.containerTop();
    const width = this.containerWidth();
    const height = this.containerHeight();
    ctx.fillStyle = 'rgba(255,250,240,0.72)';
    ctx.fillRect(left, top, width, height);
    ctx.strokeStyle = CoopTheme.ink;
    ctx.lineWidth = 2;
    ctx.strokeRect(left, top, width, height);
    ctx.setLineDash([6, 6]);
    const isWarning = this.overflowSince !== 0 && Math.floor(this.tick / 12) % 2 === 0;
    ctx.strokeStyle = isWarning ? '#f97316' : '#dc2626';
    ctx.lineWidth = isWarning ? 3 : 2;
    ctx.beginPath();
    ctx.moveTo(left, this.failLineY());
    ctx.lineTo(left + width, this.failLineY());
    ctx.stroke();
    ctx.setLineDash([]);
  }

  private drawFruit(ctx: CanvasRenderingContext2D, fruit: FruitBody): void {
    const def = FRUITS[fruit.level];
    ctx.beginPath();
    ctx.fillStyle = this.gameOver ? '#a8a29e' : def.color;
    ctx.arc(fruit.x, fruit.y, def.radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.fillStyle = 'rgba(255,255,255,0.34)';
    ctx.arc(fruit.x - def.radius * 0.3, fruit.y - def.radius * 0.32, def.radius * 0.34, 0, Math.PI * 2);
    ctx.fill();
    this.drawFruitFace(ctx, fruit.x, fruit.y, def.radius);
    if (def.radius >= 36) {
      ctx.fillStyle = '#ffffff';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.font = `700 ${this.fruitLabelFontSize(def.radius)}vp sans-serif`;
      ctx.fillText(this.fruitLabel(def.name), fruit.x, fruit.y);
    }
  }

  private drawMergeFeedback(ctx: CanvasRenderingContext2D, now: number): void {
    if (this.mergeTextUntil > now) {
      const progress = (this.mergeTextUntil - now) / 900;
      ctx.globalAlpha = Math.max(0, Math.min(1, progress));
      ctx.fillStyle = '#f97316';
      ctx.font = '800 18vp sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(this.mergeText, this.mergeTextX, this.mergeTextY - (1 - progress) * 30);
      ctx.globalAlpha = 1;
    }

    if (this.finalMergeUntil > now) {
      ctx.fillStyle = 'rgba(255,255,255,0.86)';
      ctx.fillRect(this.pageWidth * 0.5 - 104, this.pageHeight * 0.38 - 24, 208, 48);
      ctx.strokeStyle = 'rgba(22,163,74,0.42)';
      ctx.strokeRect(this.pageWidth * 0.5 - 104, this.pageHeight * 0.38 - 24, 208, 48);
      ctx.fillStyle = '#166534';
      ctx.font = '800 20vp sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('巨型鸡窝西瓜！', this.pageWidth * 0.5, this.pageHeight * 0.38);
    }
  }

  private fruitLabel(name: string): string {
    if (name === '巨型鸡窝西瓜') {
      return '鸡窝瓜';
    }
    if (name === '鸡冠西瓜') {
      return '鸡冠瓜';
    }
    return name;
  }

  private fruitLabelFontSize(radius: number): number {
    return Math.max(10, Math.min(13, radius * 0.24));
  }

  private drawFruitFace(ctx: CanvasRenderingContext2D, x: number, y: number, radius: number): void {
    if (radius < 10) {
      return;
    }
    const eyeY = y - radius * 0.12;
    const eyeGap = radius * 0.32;
    const eyeWidth = Math.max(4, radius * 0.22);
    ctx.strokeStyle = 'rgba(47,55,72,0.68)';
    ctx.lineWidth = Math.max(1.4, radius * 0.055);
    ctx.beginPath();
    ctx.moveTo(x - eyeGap - eyeWidth * 0.5, eyeY);
    ctx.lineTo(x - eyeGap + eyeWidth * 0.5, eyeY + radius * 0.03);
    ctx.moveTo(x + eyeGap - eyeWidth * 0.5, eyeY + radius * 0.03);
    ctx.lineTo(x + eyeGap + eyeWidth * 0.5, eyeY);
    ctx.stroke();
  }

  private clampAimToCurrentFruit(x: number): number {
    return clampAimX(x, this.containerLeft(), this.containerRight(), FRUITS[this.currentLevel].radius);
  }

  private containerBounds(): SuikaBounds {
    return {
      left: this.containerLeft(),
      right: this.containerRight(),
      bottom: this.containerBottom()
    };
  }

  private failLineY(): number {
    return this.containerTop() + 10;
  }

  private containerWidth(): number {
    return Math.max(260, this.pageWidth * 0.85);
  }

  private containerHeight(): number {
    return Math.max(330, this.pageHeight * 0.66);
  }

  private containerLeft(): number {
    return (this.pageWidth - this.containerWidth()) * 0.5;
  }

  private containerRight(): number {
    return this.containerLeft() + this.containerWidth();
  }

  private containerTop(): number {
    return Math.max(205, this.pageHeight - this.containerHeight() - 54);
  }

  private containerBottom(): number {
    return this.containerTop() + this.containerHeight();
  }
}
