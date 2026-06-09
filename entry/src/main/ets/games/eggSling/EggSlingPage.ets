import { CoopTheme } from '../../design/CoopTheme';

interface PigTarget {
  id: number;
  x: number;
  y: number;
  radius: number;
  alive: boolean;
}

interface SlingBlock {
  x: number;
  y: number;
  blockWidth: number;
  blockHeight: number;
  hp: number;
  color: string;
}

interface EggProjectile {
  active: boolean;
  x: number;
  y: number;
  vx: number;
  vy: number;
  resting: boolean;
}

@Component
export struct EggSlingPage {
  @Prop bestScore: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private timer: number = -1;
  private settled: boolean = false;
  private pigs: PigTarget[] = [];
  private blocks: SlingBlock[] = [];
  private egg: EggProjectile = { active: false, x: 0, y: 0, vx: 0, vy: 0, resting: true };
  private dragging: boolean = false;
  private dragX: number = 0;
  private dragY: number = 0;
  private nextLevelTimer: number = -1;
  @State pageWidth: number = 390;
  @State pageHeight: number = 760;
  @State score: number = 0;
  @State level: number = 1;
  @State eggsLeft: number = 3;
  @State paused: boolean = false;
  @State gameOver: boolean = false;
  @State levelClear: boolean = false;
  @State tick: number = 0;

  aboutToAppear(): void {
    this.restart();
  }

  aboutToDisappear(): void {
    this.stopLoop();
    this.clearNextLevelTimer();
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
            this.resetEgg();
            this.generateLevel();
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
      if (this.levelClear && !this.gameOver) {
        this.LevelClearOverlay()
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
      Column({ space: 1 }) {
        Text('弹射鸡蛋')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
        Text(`第 ${this.level} 关 · 蛋 ${this.eggsLeft}`)
          .fontSize(11)
          .fontColor(CoopTheme.muted)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(`${this.score}`)
        .fontSize(22)
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
      Text('弹弓暂停')
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
  LevelClearOverlay() {
    Column({ space: 10 }) {
      Text('过关')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
      Text(`剩余鸡蛋奖励 +${this.eggsLeft * 1000}`)
        .fontSize(14)
        .fontColor('rgba(255,255,255,0.82)')
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(22,101,52,0.62)')
  }

  @Builder
  ResultOverlay() {
    Column({ space: 12 }) {
      Text('关卡失败')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
      Text(`本局 ${this.score} · 最高 ${Math.max(this.bestScore, this.score)}`)
        .fontSize(14)
        .fontColor(CoopTheme.muted)
      Button('重新挑战')
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
    this.clearNextLevelTimer();
    this.score = 0;
    this.level = 1;
    this.eggsLeft = 3;
    this.paused = false;
    this.gameOver = false;
    this.levelClear = false;
    this.settled = false;
    this.generateLevel();
    this.resetEgg();
    this.startLoop();
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

  private clearNextLevelTimer(): void {
    if (this.nextLevelTimer !== -1) {
      clearTimeout(this.nextLevelTimer);
      this.nextLevelTimer = -1;
    }
  }

  private step(): void {
    if (this.paused || this.gameOver || this.levelClear) {
      this.draw();
      return;
    }
    if (this.egg.active) {
      this.egg.vy += 0.3;
      this.egg.x += this.egg.vx;
      this.egg.y += this.egg.vy;
      if (this.egg.y > this.groundY() - 15) {
        this.egg.y = this.groundY() - 15;
        this.egg.vy = -Math.abs(this.egg.vy) * 0.35;
        this.egg.vx *= 0.78;
      }
      this.handleCollisions();
      const speed = Math.abs(this.egg.vx) + Math.abs(this.egg.vy);
      if (speed < 0.5 || this.egg.x > this.pageWidth + 120 || this.egg.x < -80) {
        this.egg.active = false;
        this.egg.resting = true;
        if (this.pigsAlive() === 0) {
          this.clearLevel();
        } else if (this.eggsLeft <= 0) {
          this.finish();
        } else {
          this.resetEgg();
        }
      }
    }
    this.tick += 1;
    this.draw();
  }

  private handleTouch(event: TouchEvent): void {
    if (this.paused || this.gameOver || this.levelClear) {
      return;
    }
    if (event.type === TouchType.Down) {
      if (this.egg.resting && this.eggsLeft > 0 && event.touches !== undefined && event.touches.length > 0) {
        const touch = event.touches[0];
        if (this.canStartDrag(touch.x, touch.y)) {
          this.dragging = true;
          this.dragX = touch.x;
          this.dragY = touch.y;
        }
      }
    } else if (event.type === TouchType.Move) {
      if (this.dragging && event.touches !== undefined && event.touches.length > 0) {
        this.dragX = event.touches[0].x;
        this.dragY = event.touches[0].y;
      }
    } else if (event.type === TouchType.Up) {
      if (this.dragging) {
        this.launchEgg();
      }
    }
  }

  private launchEgg(): void {
    const sx = this.slingX();
    const sy = this.slingY();
    const dx = Math.max(-120, Math.min(120, this.dragX - sx));
    const dy = Math.max(-120, Math.min(120, this.dragY - sy));
    this.egg = {
      active: true,
      x: sx + dx * 0.28,
      y: sy + dy * 0.28,
      vx: -dx * 0.14,
      vy: -dy * 0.14,
      resting: false
    };
    this.eggsLeft -= 1;
    this.dragging = false;
  }

  private canStartDrag(x: number, y: number): boolean {
    const dx = x - this.slingX();
    const dy = y - this.slingY();
    return dx * dx + dy * dy <= 90 * 90;
  }

  private handleCollisions(): void {
    for (let i = 0; i < this.pigs.length; i += 1) {
      const pig = this.pigs[i];
      if (!pig.alive) {
        continue;
      }
      const dx = this.egg.x - pig.x;
      const dy = this.egg.y - pig.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < pig.radius + 15) {
        pig.alive = false;
        this.pigs[i] = pig;
        this.score += 500;
        this.egg.vx *= -0.35;
        this.egg.vy *= -0.35;
      }
    }
    for (let i = 0; i < this.blocks.length; i += 1) {
      const block = this.blocks[i];
      if (block.hp <= 0) {
        continue;
      }
      if (this.circleHitsRect(this.egg.x, this.egg.y, 15, block)) {
        block.hp -= 1;
        this.blocks[i] = block;
        this.score += 30;
        this.egg.vx *= -0.45;
        this.egg.vy *= -0.35;
      }
    }
  }

  private clearLevel(): void {
    this.levelClear = true;
    this.score += this.eggsLeft * 1000;
    this.clearNextLevelTimer();
    this.nextLevelTimer = setTimeout(() => {
      this.level += 1;
      this.eggsLeft = 3;
      this.levelClear = false;
      this.generateLevel();
      this.resetEgg();
      this.nextLevelTimer = -1;
    }, 1200);
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

  private generateLevel(): void {
    const count = Math.min(5, 2 + Math.floor(this.level / 2));
    const baseX = this.pageWidth * 0.56;
    this.pigs = [];
    this.blocks = [];
    for (let i = 0; i < count; i += 1) {
      const x = baseX + (i % 3) * 54 + Math.random() * 18;
      const y = this.groundY() - 38 - Math.floor(i / 3) * 70;
      this.pigs.push({ id: i, x: x, y: y, radius: 18, alive: true });
      this.blocks.push({ x: x - 24, y: y + 28, blockWidth: 16, blockHeight: 58, hp: 1 + Math.floor(this.level / 5), color: '#d2691e' });
      this.blocks.push({ x: x + 24, y: y + 28, blockWidth: 16, blockHeight: 58, hp: 1, color: '#93c5fd' });
      this.blocks.push({ x: x, y: y + 56, blockWidth: 76, blockHeight: 14, hp: 2, color: '#9ca3af' });
    }
  }

  private resetEgg(): void {
    this.egg = { active: false, x: this.slingX(), y: this.slingY(), vx: 0, vy: 0, resting: true };
    this.dragging = false;
  }

  private draw(): void {
    const ctx = this.context;
    ctx.clearRect(0, 0, this.pageWidth, this.pageHeight);
    ctx.fillStyle = '#eaf8ff';
    ctx.fillRect(0, 0, this.pageWidth, this.pageHeight);
    ctx.fillStyle = 'rgba(255,248,234,0.82)';
    ctx.fillRect(0, 0, this.pageWidth, this.groundY());
    ctx.fillStyle = '#d9ba84';
    ctx.fillRect(0, this.groundY(), this.pageWidth, this.pageHeight - this.groundY());
    ctx.fillStyle = 'rgba(255,255,255,0.42)';
    ctx.fillRect(0, this.groundY(), this.pageWidth, 8);
    this.drawSling(ctx);
    this.blocks.forEach((block: SlingBlock) => this.drawBlock(ctx, block));
    this.pigs.forEach((pig: PigTarget) => this.drawPig(ctx, pig));
    this.drawEgg(ctx);
  }

  private drawSling(ctx: CanvasRenderingContext2D): void {
    const sx = this.slingX();
    const sy = this.slingY();
    ctx.strokeStyle = '#7a3d1d';
    ctx.lineWidth = 8;
    ctx.beginPath();
    ctx.moveTo(sx - 16, sy + 44);
    ctx.lineTo(sx - 8, sy - 12);
    ctx.moveTo(sx + 16, sy + 44);
    ctx.lineTo(sx + 8, sy - 12);
    ctx.stroke();
    if (this.dragging) {
      ctx.strokeStyle = '#8b4513';
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(sx - 8, sy - 12);
      ctx.lineTo(this.dragX, this.dragY);
      ctx.lineTo(sx + 8, sy - 12);
      ctx.stroke();
    }
  }

  private drawEgg(ctx: CanvasRenderingContext2D): void {
    let x = this.egg.active ? this.egg.x : this.slingX();
    let y = this.egg.active ? this.egg.y : this.slingY();
    if (this.dragging) {
      x = this.dragX;
      y = this.dragY;
    }
    ctx.beginPath();
    ctx.fillStyle = '#fef3c7';
    ctx.strokeStyle = '#7a3d1d';
    ctx.lineWidth = 2;
    ctx.arc(x, y, 15, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = CoopTheme.ink;
    ctx.beginPath();
    ctx.arc(x - 4, y - 3, 2, 0, Math.PI * 2);
    ctx.arc(x + 4, y - 3, 2, 0, Math.PI * 2);
    ctx.fill();
  }

  private drawPig(ctx: CanvasRenderingContext2D, pig: PigTarget): void {
    if (!pig.alive) {
      return;
    }
    ctx.beginPath();
    ctx.fillStyle = '#65a30d';
    ctx.arc(pig.x, pig.y, pig.radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#ffffff';
    ctx.beginPath();
    ctx.arc(pig.x - 6, pig.y - 5, 4, 0, Math.PI * 2);
    ctx.arc(pig.x + 6, pig.y - 5, 4, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#3f6212';
    ctx.fillRect(pig.x - 6, pig.y + 3, 12, 7);
  }

  private drawBlock(ctx: CanvasRenderingContext2D, block: SlingBlock): void {
    if (block.hp <= 0) {
      return;
    }
    ctx.fillStyle = block.color;
    ctx.fillRect(block.x - block.blockWidth * 0.5, block.y - block.blockHeight * 0.5, block.blockWidth, block.blockHeight);
    ctx.strokeStyle = 'rgba(59,33,20,0.35)';
    ctx.lineWidth = 1;
    ctx.strokeRect(block.x - block.blockWidth * 0.5, block.y - block.blockHeight * 0.5, block.blockWidth, block.blockHeight);
  }

  private circleHitsRect(x: number, y: number, radius: number, block: SlingBlock): boolean {
    const left = block.x - block.blockWidth * 0.5;
    const right = block.x + block.blockWidth * 0.5;
    const top = block.y - block.blockHeight * 0.5;
    const bottom = block.y + block.blockHeight * 0.5;
    const cx = Math.max(left, Math.min(right, x));
    const cy = Math.max(top, Math.min(bottom, y));
    const dx = x - cx;
    const dy = y - cy;
    return dx * dx + dy * dy <= radius * radius;
  }

  private pigsAlive(): number {
    return this.pigs.filter((pig: PigTarget) => pig.alive).length;
  }

  private slingX(): number {
    return Math.max(74, this.pageWidth * 0.18);
  }

  private slingY(): number {
    return this.groundY() - 74;
  }

  private groundY(): number {
    return this.pageHeight - 78;
  }
}
