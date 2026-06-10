import { common } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import { CoopTheme } from '../../design/CoopTheme';
import {
  collapseBlock,
  resolveBlockImpact,
  updateBlockMotion
} from './EggSlingCollision';
import {
  BOUNDARY_FLASH_FRAMES,
  EGG_RADIUS,
  GRAVITY,
  LAUNCH_POWER,
  TRAJECTORY_PREVIEW_FRAME_STEP,
  TRAJECTORY_PREVIEW_STEPS,
  VISUAL_DRAG_OFFSET_RATIO,
  VISUAL_MAX_DRAG_DISTANCE,
  WORLD_SIDE_PADDING,
  WORLD_TOP_BOUND,
  clampDragDistance,
  hasEggSettled,
  integrateEgg,
  resolveEggBounds
} from './EggSlingPhysics';
import {
  EggBoundaryHit,
  EggProjectile,
  EggWorldBounds,
  PigTarget,
  SlingBlock,
  SlingBlockKind
} from './EggSlingTypes';

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
  private activeTouchMapping: number = 0;
  private nextLevelTimer: number = -1;
  private landscapeHintTimer: number = -1;
  private initialOrientationTimer: number = -1;
  private boundaryFlashFrames: number = 0;
  private lastBoundaryHit: EggBoundaryHit = EggBoundaryHit.NONE;
  private initialOrientationChecked: boolean = false;
  private hasShownLandscapeHint: boolean = false;
  @State pageWidth: number = 390;
  @State pageHeight: number = 760;
  @State score: number = 0;
  @State level: number = 1;
  @State eggsLeft: number = 3;
  @State paused: boolean = false;
  @State gameOver: boolean = false;
  @State levelClear: boolean = false;
  @State landscapeHintVisible: boolean = false;
  @State tick: number = 0;

  aboutToAppear(): void {
    this.restart();
    this.checkInitialOrientation(this.pageWidth, this.pageHeight);
    this.setWindowOrientation(window.Orientation.LANDSCAPE);
    this.scheduleInitialOrientationCheck();
  }

  aboutToDisappear(): void {
    this.stopLoop();
    this.clearNextLevelTimer();
    this.clearLandscapeHintTimer();
    this.clearInitialOrientationTimer();
    this.setWindowOrientation(window.Orientation.UNSPECIFIED);
  }

  build() {
    Stack() {
      this.GameContent()
      if (this.landscapeHintVisible) {
        this.LandscapeHint()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CoopTheme.bg)
    .onAreaChange((oldArea, newArea) => {
      this.handleAreaChange(newArea);
    })
  }

  @Builder
  GameContent() {
    Stack() {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.draw();
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
    .width(this.worldWidth())
    .height(this.worldHeight())
    .position({ x: this.worldX(), y: this.worldY() })
    .rotate({ angle: this.isLandscape() ? 0 : 90 })
    .backgroundColor(CoopTheme.bg)
  }

  @Builder
  LandscapeHint() {
    Row() {
      Text('请横屏开始游戏')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#ffffff')
    }
    .width(160)
    .height(40)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 16, right: 16 })
    .borderRadius(8)
    .backgroundColor('rgba(31,41,55,0.88)')
    .shadow({
      radius: 14,
      color: 'rgba(0,0,0,0.20)',
      offsetX: 0,
      offsetY: 6
    })
    .position({ x: Math.max(12, (this.pageWidth - 160) * 0.5), y: 42 })
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

  private handleAreaChange(newArea: Area): void {
    const previousWorldWidth = this.worldWidth();
    const previousWorldHeight = this.worldHeight();
    const width = Number.parseFloat(`${newArea.width}`);
    const height = Number.parseFloat(`${newArea.height}`);
    if (Number.isNaN(width) || Number.isNaN(height)) {
      return;
    }
    this.pageWidth = Math.max(240, width);
    this.pageHeight = Math.max(240, height);
    this.checkInitialOrientation(width, height);
    if (Math.abs(previousWorldWidth - this.worldWidth()) > 1 || Math.abs(previousWorldHeight - this.worldHeight()) > 1) {
      this.resetEgg();
      this.generateLevel();
    }
    this.draw();
  }

  private scheduleInitialOrientationCheck(): void {
    this.clearInitialOrientationTimer();
    this.initialOrientationTimer = setTimeout(() => {
      this.initialOrientationTimer = -1;
      this.checkInitialOrientation(this.pageWidth, this.pageHeight);
    }, 120);
  }

  private checkInitialOrientation(width: number, height: number): void {
    if (this.initialOrientationChecked) {
      return;
    }
    this.initialOrientationChecked = true;
    if (this.shouldShowLandscapeHint(width, height)) {
      this.showLandscapeHint();
    }
  }

  private shouldShowLandscapeHint(width: number, height: number): boolean {
    const isDisplayPortrait = this.isDisplayPortrait();
    if (isDisplayPortrait !== undefined) {
      return isDisplayPortrait;
    }
    return width < height;
  }

  private isDisplayPortrait(): boolean | undefined {
    try {
      const defaultDisplay = display.getDefaultDisplaySync();
      return defaultDisplay.orientation === display.Orientation.PORTRAIT ||
        defaultDisplay.orientation === display.Orientation.PORTRAIT_INVERTED;
    } catch (error) {
      return undefined;
    }
  }

  private setWindowOrientation(orientation: window.Orientation): void {
    try {
      const hostContext = this.getUIContext().getHostContext();
      if (hostContext === undefined) {
        return;
      }
      const abilityContext = hostContext as common.UIAbilityContext;
      const mainWindow = abilityContext.windowStage.getMainWindowSync();
      mainWindow.setPreferredOrientation(orientation).catch(() => {
      });
    } catch (error) {
    }
  }

  private showLandscapeHint(): void {
    if (this.hasShownLandscapeHint) {
      return;
    }
    this.hasShownLandscapeHint = true;
    this.landscapeHintVisible = true;
    this.clearLandscapeHintTimer();
    this.landscapeHintTimer = setTimeout(() => {
      this.landscapeHintVisible = false;
      this.landscapeHintTimer = -1;
    }, 2000);
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

  private clearLandscapeHintTimer(): void {
    if (this.landscapeHintTimer !== -1) {
      clearTimeout(this.landscapeHintTimer);
      this.landscapeHintTimer = -1;
    }
  }

  private clearInitialOrientationTimer(): void {
    if (this.initialOrientationTimer !== -1) {
      clearTimeout(this.initialOrientationTimer);
      this.initialOrientationTimer = -1;
    }
  }

  private step(): void {
    if (this.paused || this.gameOver || this.levelClear) {
      this.draw();
      return;
    }
    this.updateBlocks();
    if (this.egg.active) {
      this.egg = integrateEgg(this.egg);
      this.resolveWorldBoundary();
      this.handleCollisions();
      if (hasEggSettled(this.egg, this.worldBounds())) {
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
    if (this.boundaryFlashFrames > 0) {
      this.boundaryFlashFrames -= 1;
    }
    this.tick += 1;
    this.draw();
  }

  private updateBlocks(): void {
    const groundY = this.groundY();
    this.blocks = this.blocks.map((block: SlingBlock) => updateBlockMotion(block, groundY));
  }

  private resolveWorldBoundary(): void {
    const result = resolveEggBounds(this.egg, this.worldBounds());
    this.egg = result.egg;
    if (result.hit !== EggBoundaryHit.NONE) {
      this.lastBoundaryHit = result.hit;
      this.boundaryFlashFrames = BOUNDARY_FLASH_FRAMES;
    }
  }

  private handleTouch(event: TouchEvent): void {
    if (this.paused || this.gameOver || this.levelClear) {
      return;
    }
    if (event.type === TouchType.Down) {
      if (this.egg.resting && this.eggsLeft > 0 && event.touches !== undefined && event.touches.length > 0) {
        const touch = event.touches[0];
        const touchPoint = this.selectWorldTouchPoint(touch.x, touch.y);
        if (this.canStartDrag(touchPoint[0], touchPoint[1])) {
          this.dragging = true;
          this.setDragPoint(touchPoint[0], touchPoint[1]);
        }
      }
    } else if (event.type === TouchType.Move) {
      if (this.dragging && event.touches !== undefined && event.touches.length > 0) {
        const touchPoint = this.mapTouchPoint(event.touches[0].x, event.touches[0].y, this.activeTouchMapping);
        this.setDragPoint(touchPoint[0], touchPoint[1]);
      }
    } else if (event.type === TouchType.Up) {
      if (this.dragging) {
        this.launchEgg();
      }
    }
  }

  private selectWorldTouchPoint(x: number, y: number): [number, number] {
    const candidates: Array<[number, number]> = this.touchPointCandidates(x, y);
    let selectedIndex = 0;
    let selectedDistance = Number.MAX_VALUE;
    for (let i = 0; i < candidates.length; i += 1) {
      const point = candidates[i];
      const dx = point[0] - this.slingX();
      const dy = point[1] - this.slingY();
      const distance = dx * dx + dy * dy;
      if (distance < selectedDistance) {
        selectedDistance = distance;
        selectedIndex = i;
      }
    }
    this.activeTouchMapping = selectedIndex;
    return candidates[selectedIndex];
  }

  private mapTouchPoint(x: number, y: number, mapping: number): [number, number] {
    const candidates: Array<[number, number]> = this.touchPointCandidates(x, y);
    if (mapping >= 0 && mapping < candidates.length) {
      return candidates[mapping];
    }
    return candidates[0];
  }

  private touchPointCandidates(x: number, y: number): Array<[number, number]> {
    if (this.isLandscape()) {
      return [[x, y]];
    }
    return [
      [x, y],
      [y, this.worldHeight() - x],
      [this.worldWidth() - y, x]
    ];
  }

  private setDragPoint(x: number, y: number): void {
    this.dragX = x;
    this.dragY = y;
  }

  private dragDx(): number {
    return clampDragDistance(this.dragX - this.slingX(), this.dragY - this.slingY())[0];
  }

  private dragDy(): number {
    return clampDragDistance(this.dragX - this.slingX(), this.dragY - this.slingY())[1];
  }

  private visualDragDx(): number {
    return this.clampVisualDragDistance(this.dragX - this.slingX(), this.dragY - this.slingY())[0];
  }

  private visualDragDy(): number {
    return this.clampVisualDragDistance(this.dragX - this.slingX(), this.dragY - this.slingY())[1];
  }

  private clampVisualDragDistance(dx: number, dy: number): [number, number] {
    const distance = Math.sqrt(dx * dx + dy * dy);
    if (distance <= VISUAL_MAX_DRAG_DISTANCE || distance === 0) {
      return [dx, dy];
    }
    const scale = VISUAL_MAX_DRAG_DISTANCE / distance;
    return [dx * scale, dy * scale];
  }

  private loadedEggX(): number {
    return this.dragEggX(VISUAL_DRAG_OFFSET_RATIO);
  }

  private loadedEggY(): number {
    return this.dragEggY(VISUAL_DRAG_OFFSET_RATIO);
  }

  private dragEggX(offsetRatio: number): number {
    const bounds = this.worldBounds();
    const minX = bounds.left + EGG_RADIUS;
    const maxX = bounds.right - EGG_RADIUS;
    return Math.max(minX, Math.min(maxX, this.slingX() + this.visualDragDx() * offsetRatio));
  }

  private dragEggY(offsetRatio: number): number {
    const bounds = this.worldBounds();
    const minY = bounds.top + EGG_RADIUS;
    const maxY = bounds.ground - EGG_RADIUS;
    return Math.max(minY, Math.min(maxY, this.slingY() + this.visualDragDy() * offsetRatio));
  }

  private launchEgg(): void {
    const dx = this.dragDx();
    const dy = this.dragDy();
    this.egg = {
      active: true,
      x: this.loadedEggX(),
      y: this.loadedEggY(),
      vx: -dx * LAUNCH_POWER,
      vy: -dy * LAUNCH_POWER,
      resting: false
    };
    this.eggsLeft -= 1;
    this.dragging = false;
    this.activeTouchMapping = 0;
  }

  private canStartDrag(x: number, y: number): boolean {
    const dx = x - this.slingX();
    const dy = y - this.slingY();
    return dx * dx + dy * dy <= 132 * 132;
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
      if (dist < pig.radius + EGG_RADIUS) {
        pig.alive = false;
        this.pigs[i] = pig;
        this.score += 500;
        this.egg.vx *= -0.35;
        this.egg.vy *= -0.35;
      }
    }
    for (let i = 0; i < this.blocks.length; i += 1) {
      const block = this.blocks[i];
      if (!block.visible || block.dynamic) {
        continue;
      }
      const result = resolveBlockImpact(this.egg, block);
      if (result.didHit) {
        this.blocks[i] = result.block;
        this.egg = result.egg;
        this.score += result.scoreDelta;
        if (result.shouldCollapseGroup) {
          this.collapseBlockGroup(result.block.groupId, result.block.id);
        }
        break;
      }
    }
  }

  private collapseBlockGroup(groupId: number, sourceBlockId: number): void {
    const direction = this.egg.vx >= 0 ? 1 : -1;
    this.blocks = this.blocks.map((block: SlingBlock) => {
      if (block.groupId !== groupId || !block.visible || block.dynamic || block.id === sourceBlockId) {
        return block;
      }
      return collapseBlock(block, this.egg, direction);
    });
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
    const spacing = Math.min(58, Math.max(46, this.worldWidth() * 0.07));
    const totalWidth = (count - 1) * spacing;
    const rightReserve = Math.min(96, Math.max(64, this.worldWidth() * 0.08));
    const slingGap = Math.min(320, Math.max(220, this.worldWidth() * 0.28));
    const baseX = Math.min(
      this.worldWidth() - totalWidth - rightReserve,
      Math.max(this.worldWidth() * 0.62, this.slingX() + slingGap)
    );
    const floorY = this.groundY();
    const supportHeight = 58;
    const beamHeight = 14;
    const targetRadius = 18;
    this.pigs = [];
    this.blocks = [];
    let blockId = 0;
    for (let i = 0; i < count; i += 1) {
      const x = baseX + i * spacing + Math.random() * 12;
      const supportCenterY = floorY - supportHeight * 0.5;
      const beamCenterY = floorY - supportHeight - beamHeight * 0.5;
      const targetY = floorY - supportHeight - beamHeight - targetRadius - 8;
      this.pigs.push({ id: i, groupId: i, x: x, y: targetY, radius: targetRadius, alive: true });
      this.blocks.push(this.createBlock(
        blockId,
        i,
        SlingBlockKind.SUPPORT,
        x - 24,
        supportCenterY,
        16,
        supportHeight,
        1 + Math.floor(this.level / 5),
        '#d2691e'
      ));
      blockId += 1;
      this.blocks.push(this.createBlock(
        blockId,
        i,
        SlingBlockKind.SUPPORT,
        x + 24,
        supportCenterY,
        16,
        supportHeight,
        1,
        '#93c5fd'
      ));
      blockId += 1;
      this.blocks.push(this.createBlock(
        blockId,
        i,
        SlingBlockKind.BEAM,
        x,
        beamCenterY,
        76,
        beamHeight,
        2,
        '#9ca3af'
      ));
      blockId += 1;
    }
  }

  private createBlock(
    id: number,
    groupId: number,
    kind: SlingBlockKind,
    x: number,
    y: number,
    blockWidth: number,
    blockHeight: number,
    hp: number,
    color: string
  ): SlingBlock {
    return {
      id: id,
      groupId: groupId,
      kind: kind,
      x: x,
      y: y,
      blockWidth: blockWidth,
      blockHeight: blockHeight,
      hp: hp,
      maxHp: hp,
      color: color,
      hitFrames: 0,
      offsetX: 0,
      offsetY: 0,
      vx: 0,
      vy: 0,
      rotation: 0,
      angularVelocity: 0,
      dynamic: false,
      visible: true
    };
  }

  private resetEgg(): void {
    this.egg = { active: false, x: this.slingX(), y: this.slingY(), vx: 0, vy: 0, resting: true };
    this.dragging = false;
    this.activeTouchMapping = 0;
  }

  private draw(): void {
    const ctx = this.context;
    const width = this.worldWidth();
    const height = this.worldHeight();
    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = '#eaf8ff';
    ctx.fillRect(0, 0, width, height);
    ctx.fillStyle = 'rgba(255,248,234,0.82)';
    ctx.fillRect(0, 0, width, this.groundY());
    ctx.fillStyle = '#d9ba84';
    ctx.fillRect(0, this.groundY(), width, height - this.groundY());
    this.drawFloor(ctx, width);
    this.drawWorldBounds(ctx);
    this.drawTrajectoryPreview(ctx);
    this.drawSling(ctx);
    this.blocks.forEach((block: SlingBlock) => this.drawBlock(ctx, block));
    this.pigs.forEach((pig: PigTarget) => this.drawPig(ctx, pig));
    this.drawEgg(ctx);
  }

  private drawFloor(ctx: CanvasRenderingContext2D, width: number): void {
    const floorY = this.groundY();
    ctx.fillStyle = 'rgba(255,255,255,0.42)';
    ctx.fillRect(0, floorY, width, 8);
    ctx.fillStyle = 'rgba(122,61,29,0.24)';
    ctx.fillRect(0, floorY - 3, width, 3);
    ctx.strokeStyle = 'rgba(122,61,29,0.20)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let x = 0; x < width; x += 42) {
      ctx.moveTo(x, floorY + 10);
      ctx.lineTo(x + 24, floorY + 24);
    }
    ctx.stroke();
  }

  private drawWorldBounds(ctx: CanvasRenderingContext2D): void {
    const bounds = this.worldBounds();
    const height = bounds.ground - bounds.top;
    const leftHot = this.boundaryFlashFrames > 0 && this.lastBoundaryHit === EggBoundaryHit.LEFT;
    const rightHot = this.boundaryFlashFrames > 0 && this.lastBoundaryHit === EggBoundaryHit.RIGHT;
    const topHot = this.boundaryFlashFrames > 0 && this.lastBoundaryHit === EggBoundaryHit.TOP;
    const groundHot = this.boundaryFlashFrames > 0 && this.lastBoundaryHit === EggBoundaryHit.GROUND;
    ctx.fillStyle = leftHot ? 'rgba(142,72,34,0.52)' : 'rgba(142,72,34,0.22)';
    ctx.fillRect(bounds.left - 4, bounds.top, 8, height);
    ctx.fillStyle = rightHot ? 'rgba(142,72,34,0.52)' : 'rgba(142,72,34,0.22)';
    ctx.fillRect(bounds.right - 4, bounds.top, 8, height);
    ctx.strokeStyle = topHot ? 'rgba(142,72,34,0.45)' : 'rgba(142,72,34,0.10)';
    ctx.lineWidth = topHot ? 3 : 1;
    ctx.beginPath();
    ctx.moveTo(bounds.left, bounds.top);
    ctx.lineTo(bounds.right, bounds.top);
    ctx.stroke();
    if (groundHot) {
      ctx.fillStyle = 'rgba(255,255,255,0.34)';
      ctx.fillRect(bounds.left, bounds.ground - 8, bounds.right - bounds.left, 8);
    }
  }

  private drawSling(ctx: CanvasRenderingContext2D): void {
    const sx = this.slingX();
    const sy = this.slingY();
    const pocketX = this.dragging ? this.loadedEggX() : sx;
    const pocketY = this.dragging ? this.loadedEggY() : sy;
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
      ctx.lineTo(pocketX, pocketY);
      ctx.lineTo(sx + 8, sy - 12);
      ctx.stroke();
    }
  }

  private drawTrajectoryPreview(ctx: CanvasRenderingContext2D): void {
    if (!this.dragging || !this.egg.resting) {
      return;
    }
    const bounds = this.worldBounds();
    const dx = this.dragDx();
    const dy = this.dragDy();
    const startX = this.loadedEggX();
    const startY = this.loadedEggY();
    const vx = -dx * LAUNCH_POWER;
    const vy = -dy * LAUNCH_POWER;

    for (let i = 1; i <= TRAJECTORY_PREVIEW_STEPS; i += 1) {
      const time = i * TRAJECTORY_PREVIEW_FRAME_STEP;
      const x = startX + vx * time;
      const y = startY + vy * time + 0.5 * GRAVITY * time * time;
      if (x < bounds.left || x > bounds.right || y < bounds.top || y > bounds.ground) {
        break;
      }
      const alpha = Math.max(0.12, 0.44 - i * 0.024);
      const radius = Math.max(1.7, 3.2 - i * 0.07);
      ctx.fillStyle = `rgba(122,61,29,${alpha})`;
      ctx.beginPath();
      ctx.arc(x, y, radius, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  private drawEgg(ctx: CanvasRenderingContext2D): void {
    let x = this.egg.active ? this.egg.x : this.slingX();
    let y = this.egg.active ? this.egg.y : this.slingY();
    if (this.dragging) {
      x = this.loadedEggX();
      y = this.loadedEggY();
    }
    ctx.beginPath();
    ctx.fillStyle = '#fef3c7';
    ctx.strokeStyle = '#7a3d1d';
    ctx.lineWidth = 2;
    ctx.arc(x, y, EGG_RADIUS, 0, Math.PI * 2);
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
    if (!block.visible) {
      return;
    }
    const x = block.x + block.offsetX;
    const y = block.y + block.offsetY;
    const isHit = block.hitFrames > 0;
    const isBroken = block.hp <= 0;
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(block.rotation);
    ctx.fillStyle = isHit ? '#fff4c7' : block.color;
    if (isBroken) {
      ctx.fillStyle = block.kind === SlingBlockKind.BEAM ? '#77716a' : '#b46a32';
    }
    ctx.fillRect(-block.blockWidth * 0.5, -block.blockHeight * 0.5, block.blockWidth, block.blockHeight);
    ctx.strokeStyle = 'rgba(59,33,20,0.35)';
    ctx.lineWidth = 1;
    ctx.strokeRect(-block.blockWidth * 0.5, -block.blockHeight * 0.5, block.blockWidth, block.blockHeight);
    if (isBroken || block.hp < block.maxHp) {
      this.drawBlockCracks(ctx, block);
    }
    ctx.restore();
  }

  private drawBlockCracks(ctx: CanvasRenderingContext2D, block: SlingBlock): void {
    const left = -block.blockWidth * 0.5;
    const top = -block.blockHeight * 0.5;
    ctx.strokeStyle = block.hp <= 0 ? 'rgba(59,33,20,0.48)' : 'rgba(59,33,20,0.32)';
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(left + block.blockWidth * 0.22, top + block.blockHeight * 0.20);
    ctx.lineTo(left + block.blockWidth * 0.48, top + block.blockHeight * 0.44);
    ctx.lineTo(left + block.blockWidth * 0.38, top + block.blockHeight * 0.70);
    if (block.hp <= 0 || block.maxHp - block.hp >= 2) {
      ctx.moveTo(left + block.blockWidth * 0.62, top + block.blockHeight * 0.24);
      ctx.lineTo(left + block.blockWidth * 0.52, top + block.blockHeight * 0.52);
      ctx.lineTo(left + block.blockWidth * 0.76, top + block.blockHeight * 0.78);
    }
    ctx.stroke();
  }

  private pigsAlive(): number {
    return this.pigs.filter((pig: PigTarget) => pig.alive).length;
  }

  private slingX(): number {
    return Math.max(74, this.worldWidth() * 0.18);
  }

  private slingY(): number {
    return this.groundY() - 44;
  }

  private groundY(): number {
    return this.worldHeight() - 46;
  }

  private worldBounds(): EggWorldBounds {
    return {
      left: WORLD_SIDE_PADDING,
      right: this.worldWidth() - WORLD_SIDE_PADDING,
      top: WORLD_TOP_BOUND,
      ground: this.groundY(),
      radius: EGG_RADIUS
    };
  }

  private isLandscape(): boolean {
    return this.pageWidth >= this.pageHeight;
  }

  private worldWidth(): number {
    return Math.max(this.pageWidth, this.pageHeight);
  }

  private worldHeight(): number {
    return Math.min(this.pageWidth, this.pageHeight);
  }

  private worldX(): number {
    return (this.pageWidth - this.worldWidth()) * 0.5;
  }

  private worldY(): number {
    return (this.pageHeight - this.worldHeight()) * 0.5;
  }
}
