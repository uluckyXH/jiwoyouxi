import { CoopTheme } from '../../design/CoopTheme';

interface FruitDef {
  name: string;
  radius: number;
  color: string;
  score: number;
}

interface FruitBody {
  id: number;
  level: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  bornAt: number;
}

const FRUITS: FruitDef[] = [
  { name: '葡萄', radius: 13, color: '#8b5cf6', score: 1 },
  { name: '樱桃', radius: 17, color: '#ef4444', score: 3 },
  { name: '橘子', radius: 21, color: '#f97316', score: 6 },
  { name: '柠檬', radius: 26, color: '#eab308', score: 10 },
  { name: '猕猴桃', radius: 31, color: '#84cc16', score: 15 },
  { name: '番茄', radius: 37, color: '#dc2626', score: 21 },
  { name: '桃子', radius: 43, color: '#fb923c', score: 28 },
  { name: '菠萝', radius: 50, color: '#facc15', score: 36 },
  { name: '椰子', radius: 58, color: '#a16207', score: 45 },
  { name: '半瓜', radius: 67, color: '#22c55e', score: 55 },
  { name: '西瓜', radius: 77, color: '#16a34a', score: 66 }
];

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
  private currentLevel: number = 0;
  private nextLevel: number = 1;
  private cooldownUntil: number = 0;
  private overflowSince: number = 0;
  private settled: boolean = false;
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
      Text('合成大西瓜')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
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
      Text('西瓜暂停')
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
      Text('装不下了')
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

  private restart(): void {
    this.stopLoop();
    this.fruits = [];
    this.nextId = 1;
    this.currentLevel = this.randomStartLevel();
    this.nextLevel = this.randomStartLevel();
    this.score = 0;
    this.paused = false;
    this.gameOver = false;
    this.settled = false;
    this.cooldownUntil = 0;
    this.overflowSince = 0;
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
    if (event.type === TouchType.Up) {
      this.dropFruit();
      return;
    }
    if (event.touches === undefined || event.touches.length === 0) {
      return;
    }
    const touch = event.touches[0];
    this.aimX = Math.max(this.containerLeft() + 16, Math.min(this.containerRight() - 16, touch.x));
  }

  private dropFruit(): void {
    const now = Date.now();
    if (now < this.cooldownUntil) {
      return;
    }
    const def = FRUITS[this.currentLevel];
    this.fruits.push({
      id: this.nextId++,
      level: this.currentLevel,
      x: this.aimX,
      y: this.containerTop() - 28,
      vx: 0,
      vy: 0,
      bornAt: now
    });
    this.currentLevel = this.nextLevel;
    this.nextLevel = this.randomStartLevel();
    this.cooldownUntil = now + 500;
    this.aimX = Math.max(this.containerLeft() + def.radius, Math.min(this.containerRight() - def.radius, this.aimX));
  }

  private applyPhysics(): void {
    const left = this.containerLeft();
    const right = this.containerRight();
    const bottom = this.containerBottom();
    for (let i = 0; i < this.fruits.length; i += 1) {
      const fruit = this.fruits[i];
      const radius = FRUITS[fruit.level].radius;
      fruit.vy += 0.4;
      fruit.x += fruit.vx;
      fruit.y += fruit.vy;
      fruit.vx *= 0.992;
      if (fruit.x - radius < left) {
        fruit.x = left + radius;
        fruit.vx = Math.abs(fruit.vx) * 0.35;
      }
      if (fruit.x + radius > right) {
        fruit.x = right - radius;
        fruit.vx = -Math.abs(fruit.vx) * 0.35;
      }
      if (fruit.y + radius > bottom) {
        fruit.y = bottom - radius;
        fruit.vy = -Math.abs(fruit.vy) * 0.22;
        fruit.vx *= 0.94;
      }
      this.fruits[i] = fruit;
    }
  }

  private resolveCollisions(now: number): void {
    for (let i = 0; i < this.fruits.length; i += 1) {
      for (let j = i + 1; j < this.fruits.length; j += 1) {
        const a = this.fruits[i];
        const b = this.fruits[j];
        const ar = FRUITS[a.level].radius;
        const br = FRUITS[b.level].radius;
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const dist = Math.max(0.01, Math.sqrt(dx * dx + dy * dy));
        const target = ar + br;
        if (dist >= target) {
          continue;
        }
        if (a.level === b.level) {
          this.mergeFruits(i, j, now);
          return;
        }
        const overlap = (target - dist) * 0.5;
        const nx = dx / dist;
        const ny = dy / dist;
        a.x -= nx * overlap;
        a.y -= ny * overlap;
        b.x += nx * overlap;
        b.y += ny * overlap;
        const avx = a.vx;
        const avy = a.vy;
        a.vx = b.vx * 0.3 - nx * 0.3;
        a.vy = b.vy * 0.3 - ny * 0.3;
        b.vx = avx * 0.3 + nx * 0.3;
        b.vy = avy * 0.3 + ny * 0.3;
        this.fruits[i] = a;
        this.fruits[j] = b;
      }
    }
  }

  private mergeFruits(firstIndex: number, secondIndex: number, now: number): void {
    const a = this.fruits[firstIndex];
    const b = this.fruits[secondIndex];
    const nextLevel = Math.min(FRUITS.length - 1, a.level + 1);
    const x = (a.x + b.x) * 0.5;
    const y = (a.y + b.y) * 0.5;
    const next: FruitBody[] = [];
    for (let i = 0; i < this.fruits.length; i += 1) {
      if (i !== firstIndex && i !== secondIndex) {
        next.push(this.fruits[i]);
      }
    }
    if (a.level >= FRUITS.length - 1) {
      this.score += 100;
    } else {
      this.score += FRUITS[nextLevel].score + 5;
      next.push({ id: this.nextId++, level: nextLevel, x: x, y: y, vx: 0, vy: -1.2, bornAt: now });
    }
    this.fruits = next;
  }

  private checkOverflow(now: number): void {
    const top = this.containerTop() + 10;
    let over = false;
    for (let i = 0; i < this.fruits.length; i += 1) {
      const fruit = this.fruits[i];
      if (now - fruit.bornAt > 1200 && fruit.y - FRUITS[fruit.level].radius < top) {
        over = true;
        break;
      }
    }
    if (over) {
      if (this.overflowSince === 0) {
        this.overflowSince = now;
      } else if (now - this.overflowSince > 2000) {
        this.finish();
      }
    } else {
      this.overflowSince = 0;
    }
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
    ctx.fillText(`当前 ${def.name} · 下个 ${FRUITS[this.nextLevel].name}`, 22, 128);
    ctx.beginPath();
    ctx.strokeStyle = CoopTheme.ink;
    ctx.lineWidth = 2;
    ctx.moveTo(this.aimX, 150);
    ctx.lineTo(this.aimX, this.containerTop() - 8);
    ctx.stroke();
    ctx.beginPath();
    ctx.fillStyle = def.color;
    ctx.arc(this.aimX, 150, Math.max(10, def.radius * 0.55), 0, Math.PI * 2);
    ctx.fill();
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
    ctx.strokeStyle = '#dc2626';
    ctx.beginPath();
    ctx.moveTo(left, top + 10);
    ctx.lineTo(left + width, top + 10);
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
    if (def.radius >= 36) {
      ctx.fillStyle = '#ffffff';
      ctx.font = '700 12vp sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(def.name, fruit.x, fruit.y);
    }
  }

  private randomStartLevel(): number {
    return Math.floor(Math.random() * 5);
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
