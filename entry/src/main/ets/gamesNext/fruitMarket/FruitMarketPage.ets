import { common } from '@kit.AbilityKit';
import { AchievementEvent } from '../../shell/AchievementModule';
import { MarketAudio } from './MarketAudio';
import { MarketIconButton } from './MarketControls';
import { MarketEngine } from './MarketEngine';
import { MarketFrameClock } from './MarketFrameClock';
import { MarketCrease, MarketInsets, MarketLayout, marketLayout } from './MarketLayout';
import { MARKET_ASSETS, MarketMerge } from './MarketModel';
import { MarketPalette } from './MarketPalette';
import { MarketDialog, MarketGuide, MarketStats } from './MarketPanels';
import { MarketRenderer } from './MarketRenderer';
import { MarketStorage } from './MarketStorage';
import { MarketWindow } from './MarketWindow';

@Component
export struct FruitMarketPage {
  @Prop dark: boolean = false;
  @Prop bestScore: number = 0;
  @Prop @Watch('soundChanged') soundEnabled: boolean = true;
  @Prop @Watch('exitRequested') exitRequest: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  reportAchievementEvent: (event: AchievementEvent) => void = () => {};
  private engine: MarketEngine = new MarketEngine();
  private renderer: MarketRenderer = new MarketRenderer();
  private sounds: MarketAudio = new MarketAudio();
  private storage: MarketStorage = new MarketStorage();
  private hostWindow: MarketWindow = new MarketWindow();
  private canvas: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private hostContext: common.Context | undefined = undefined;
  private insets: MarketInsets = { top: 24, bottom: 16, left: 0, right: 0 };
  private crease: MarketCrease = { x: 0, y: 0, width: 0, height: 0 };
  private pageWidth: number = 390;
  private pageHeight: number = 844;
  private frameClock: MarketFrameClock = new MarketFrameClock();
  private lastFrame: number = 0;
  private lastSave: number = 0;
  private canvasWidth: number = 0;
  private canvasHeight: number = 0;
  private touchId: number = -1;
  private aiming: boolean = false;
  private gameReady: boolean = false;
  private disposed: boolean = false;
  private booting: boolean = false;
  private backgroundDuringBoot: boolean = false;
  private helpReturn: string = '';
  @State viewport: MarketLayout = marketLayout(390, 844, { top: 24, bottom: 16, left: 0, right: 0 });
  @State dialogMode: string = 'loading';
  @State score: number = 0;
  @State best: number = 0;
  @State current: number = 0;
  @State next: number = 0;
  @State highest: number = 0;
  @State drops: number = 0;
  @State merges: number = 0;
  @State saveFailed: boolean = false;
  @State savingExit: boolean = false;

  aboutToAppear(): void {
    this.hostContext = this.getUIContext().getHostContext() as common.Context;
    const context = this.hostContext;
    if (context === undefined) { this.dialogMode = 'error'; return; }
    this.sounds.setEnabled(this.soundEnabled);
    this.sounds.init(context);
    this.hostWindow.attach(context, (px: number): number => this.getUIContext().px2vp(px),
      (insets: MarketInsets, crease: MarketCrease) => {
        this.insets = insets;
        this.crease = crease;
        this.relayout();
      }, () => this.backgrounded());
    this.boot();
  }

  aboutToDisappear(): void {
    this.disposed = true;
    this.stop();
    this.save();
    this.hostWindow.release();
    this.sounds.release();
    this.renderer.release();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(`${MARKET_ASSETS}scene/garden_${this.dark ? 'dark' : 'light'}.svg`))
        .width('100%').height('100%').objectFit(ImageFit.Cover)
        .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      Column({ space: this.viewport.gap }) {
        this.Header()
        if (this.viewport.wide) {
          Row({ space: this.viewport.gap }) {
            this.Board()
            Scroll() {
              Column({ space: 14 }) {
                MarketStats({ dark: this.dark, wide: true, score: this.score, best: this.best,
                  current: this.current, next: this.next })
                MarketGuide({ dark: this.dark, highest: this.highest })
                Text('左右移动，松手投放\n相同相碰，慢慢长大').fontSize(12).lineHeight(21)
                  .textAlign(TextAlign.Center).fontColor(MarketPalette.muted(this.dark)).width('100%')
              }.width('100%')
            }.width(this.viewport.railWidth).height(this.viewport.bodyHeight).scrollBar(BarState.Off)
          }
          .width('100%').height(this.viewport.bodyHeight).justifyContent(FlexAlign.Center)
        } else {
          Column({ space: 12 }) {
            MarketStats({ dark: this.dark, score: this.score, best: this.best, current: this.current, next: this.next })
            this.Board()
          }.width('100%').height(this.viewport.bodyHeight).justifyContent(FlexAlign.Center)
        }
        Text(this.saveFailed ? '进度暂未保存 · 请在暂停页重试' : '左右移动，松手投放 · 相同水果碰出新鲜感')
          .fontSize(11).fontColor(this.saveFailed ? MarketPalette.danger(this.dark) : MarketPalette.muted(this.dark))
          .textAlign(TextAlign.Center).maxLines(1).height(30).width('100%')
      }
      .padding({ left: this.viewport.gap, right: this.viewport.gap })
      .width(this.viewport.width).height(this.viewport.height)
      .position({ x: this.viewport.x, y: this.viewport.y })
      if (this.dialogMode.length > 0) {
        MarketDialog({
          mode: this.dialogMode, dark: this.dark, score: this.score, highest: this.highest,
          drops: this.drops, merges: this.merges, saveFailed: this.saveFailed,
          cardWidth: Math.min(380, this.viewport.width - 24), cardHeight: Math.max(100, this.viewport.height - 24),
          resume: () => this.resume(), restart: () => this.restartRequested(),
          exitWithoutSave: () => this.exitToHub(),
          exit: () => this.saveAndExit(), help: () => this.showHelp(), retry: () => this.boot()
        }).width(this.viewport.width).height(this.viewport.height)
          .position({ x: this.viewport.x, y: this.viewport.y })
      }
    }
    .width('100%').height('100%').backgroundColor(MarketPalette.background(this.dark))
    .onAreaChange((oldArea: Area, newArea: Area) => {
      this.pageWidth = Number(newArea.width);
      this.pageHeight = Number(newArea.height);
      this.cancelTouch();
      this.hostWindow.measure();
      this.relayout();
    })
  }

  @Builder
  Header() {
    Row({ space: 8 }) {
      MarketIconButton({ icon: 'back', label: '保存并返回大厅', dark: this.dark, action: () => this.exitRequested() })
      Column({ space: 3 }) {
        Text('鸡窝水果摊').fontSize(this.viewport.width < 360 ? 18 : 20).fontWeight(FontWeight.Bold)
          .fontColor(MarketPalette.ink(this.dark)).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 4 }) {
          Image($rawfile(MarketPalette.icon('leaf', this.dark, 'accent'))).width(11).height(11)
            .accessibilityLevel('no')
          Text('今日鲜果 · 慢慢合成').fontSize(10).fontColor(MarketPalette.muted(this.dark)).maxLines(1)
        }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Row({ space: 0 }) {
        if (this.viewport.width >= 420) {
          MarketIconButton({ icon: 'help', label: '玩法说明', dark: this.dark, quiet: true,
            action: () => this.showHelp() })
        }
        MarketIconButton({ icon: this.soundEnabled ? 'sound' : 'muted', label: this.soundEnabled ? '关闭音效' : '开启音效',
          dark: this.dark, quiet: true, action: () => { this.updateSound(!this.soundEnabled); } })
        MarketIconButton({ icon: 'pause', label: '暂停游戏', dark: this.dark, primary: true,
          action: () => this.pause('pause') })
      }.padding(4).backgroundColor(MarketPalette.surface(this.dark))
      .border({ width: 1, color: MarketPalette.line(this.dark), radius: 28 })
    }.width('100%').height(64)
  }

  @Builder
  Board() {
    Stack() {
      Image($rawfile(`${MARKET_ASSETS}scene/stall_${this.dark ? 'dark' : 'light'}.svg`))
        .width('100%').height('100%').objectFit(ImageFit.Fill)
        .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      Canvas(this.canvas).width('100%').height('100%')
        .onReady(() => { this.renderer.prepare(); this.draw(); })
        .onAreaChange((oldArea: Area, newArea: Area) => {
          this.canvasWidth = Number(newArea.width);
          this.canvasHeight = Number(newArea.height);
          this.draw();
        })
        .onTouch((event: TouchEvent) => this.touch(event))
        .accessibilityText('水果摊投放区，左右拖动选择位置，松手投放；也可直接点击落点')
    }.width(this.viewport.boardWidth).height(this.viewport.boardHeight)
  }

  private async boot(): Promise<void> {
    const context = this.hostContext;
    if (this.booting || this.disposed || context === undefined) return;
    this.booting = true;
    this.dialogMode = 'loading';
    const raw = await this.storage.load(context);
    const restored = raw.length > 0 && this.engine.restore(raw);
    this.engine.round.best = Math.max(this.engine.round.best, this.bestScore);
    this.gameReady = true;
    this.booting = false;
    if (this.disposed) return;
    this.sync();
    this.dialogMode = restored && this.engine.round.drops > 0 ? (this.engine.round.ended ? 'result' : 'resume') : '';
    if (this.backgroundDuringBoot && this.dialogMode === '') this.dialogMode = 'pause';
    if (this.engine.round.ended) this.finish();
    this.draw();
    if (this.dialogMode === '') this.start();
  }

  private start(): void {
    if (!this.gameReady || this.disposed || this.dialogMode !== '' || this.engine.round.ended) return;
    this.stop();
    this.lastFrame = Date.now();
    this.lastSave = this.lastFrame;
    this.frameClock.start(() => this.frame());
  }

  private stop(): void {
    this.frameClock.stop();
    this.cancelTouch();
  }

  private frame(): void {
    if (this.disposed || this.dialogMode !== '') return;
    const now = Date.now();
    const oldScore = this.engine.round.score;
    const oldHighest = this.engine.round.highest;
    const events = this.engine.advance((now - this.lastFrame) / 1000);
    this.lastFrame = now;
    if (events.length > 0) {
      this.renderer.add(events);
      const peak = events.reduce((value: number, event: MarketMerge): number => Math.max(value, event.level), 0);
      this.sounds.play(peak === 10 ? 'crown' : peak >= 6 ? 'bloom' : 'merge');
      this.sync();
      if (oldHighest < 7 && this.highest >= 7) this.report('watermelon', false);
      if (oldHighest < 10 && this.highest >= 10) this.report('crown', false);
      if (oldScore < 600 && this.score >= 600) this.report('score-600', false);
    }
    if (this.engine.round.overflow > 0.5 && !this.engine.round.ended) this.sounds.play('warning');
    this.draw();
    if (this.engine.round.ended) {
      this.finish();
    } else if (now - this.lastSave > 5000 && this.engine.round.drops > 0) {
      this.lastSave = now;
      this.save();
    }
  }

  private touch(event: TouchEvent): void {
    if (this.dialogMode !== '' || !this.gameReady || this.canvasWidth <= 0) return;
    if (event.type === TouchType.Cancel) { this.cancelTouch(); this.draw(); return; }
    if (event.type === TouchType.Down && this.touchId === -1 && event.touches.length > 0) {
      if (!this.engine.canDrop()) return;
      this.touchId = event.touches[0].id;
      this.aiming = true;
    }
    if (this.touchId === -1) return;
    const points = event.type === TouchType.Up ? event.changedTouches : event.touches;
    const point = points.find((item: TouchObject): boolean => item.id === this.touchId);
    if (point === undefined) return;
    this.engine.aimAt(point.x * 360 / this.canvasWidth);
    if (event.type === TouchType.Up) {
      const inside = point.x >= 0 && point.x <= this.canvasWidth && point.y >= 0 && point.y <= this.canvasHeight;
      this.cancelTouch();
      if (inside && this.engine.drop()) { this.sounds.play('drop'); this.sync(); }
    }
    // The next display frame paints the latest aim, coalescing high-rate touch moves.
  }

  private cancelTouch(): void { this.touchId = -1; this.aiming = false; }

  private draw(): void {
    if (this.gameReady && !this.disposed) {
      this.renderer.draw(this.canvas, this.engine, this.canvasWidth, this.canvasHeight, this.dark, this.aiming,
        this.getUIContext().vp2px(this.canvasWidth) / 360);
    }
  }

  private relayout(): void {
    if (this.disposed || this.pageWidth <= 0 || this.pageHeight <= 0) return;
    this.viewport = marketLayout(this.pageWidth, this.pageHeight, this.insets, this.crease);
    this.draw();
  }

  private sync(): void {
    const round = this.engine.round;
    this.score = round.score;
    this.best = round.best;
    this.current = round.current;
    this.next = round.next;
    this.highest = round.highest;
    this.drops = round.drops;
    this.merges = round.merges;
  }

  private pause(mode: string): void {
    if (!this.gameReady || this.disposed) return;
    this.stop();
    this.sounds.silence();
    this.dialogMode = this.engine.round.ended ? 'result' : mode;
    this.save();
    this.draw();
  }

  private resume(): void {
    if (this.dialogMode === 'help') {
      this.dialogMode = this.helpReturn;
      this.helpReturn = '';
    } else {
      this.dialogMode = this.engine.round.ended ? 'result' : '';
    }
    this.sounds.play('tap');
    this.start();
  }

  private showHelp(): void {
    if (!this.gameReady) return;
    this.helpReturn = this.dialogMode;
    this.stop();
    this.sounds.silence();
    this.dialogMode = 'help';
    this.save();
  }

  private restartRequested(): void {
    if (this.dialogMode !== 'restart' && this.dialogMode !== 'result') { this.pause('restart'); return; }
    const best = this.engine.round.best;
    this.engine = new MarketEngine();
    this.engine.round.best = best;
    this.renderer.reset();
    this.sync();
    this.dialogMode = '';
    this.save();
    this.sounds.play('tap');
    this.draw();
    this.start();
  }

  private exitRequested(): void {
    if (this.dialogMode === 'help') { this.resume(); return; }
    if (!this.gameReady) { this.exitToHub(); return; }
    this.pause('exit');
  }

  private soundChanged(): void { this.sounds.setEnabled(this.soundEnabled); }

  private backgrounded(): void {
    this.backgroundDuringBoot = true;
    if (this.disposed || !this.gameReady) return;
    if (this.dialogMode === '') this.pause('pause');
    this.sounds.silence();
    this.save();
  }

  private async save(): Promise<boolean> {
    if (!this.gameReady || this.hostContext === undefined) return true;
    const saved = await this.storage.save(this.hostContext, this.engine.serialize());
    if (!this.disposed) this.saveFailed = !saved;
    return saved;
  }

  private async saveAndExit(): Promise<void> {
    if (this.savingExit) return;
    this.savingExit = true;
    this.stop();
    this.sounds.silence();
    const saved = await this.save();
    this.savingExit = false;
    if (saved && !this.disposed) this.exitToHub();
  }

  private finish(): void {
    this.stop();
    this.sync();
    this.dialogMode = 'result';
    if (!this.engine.round.reported) {
      this.engine.round.reported = true;
      this.recordScore(this.engine.round.score);
      this.report('session-end', true);
      this.sounds.play('finish');
    }
    this.save();
  }

  private report(key: string, ended: boolean): void {
    const round = this.engine.round;
    this.reportAchievementEvent({
      eventId: `${round.sessionId}:${key}`, sessionId: round.sessionId, gameId: 'suika',
      type: ended ? 'sessionEnd' : 'milestone', occurredAt: Date.now(), isOfficial: true,
      facts: [
        { key: 'score', value: round.score }, { key: 'droppedCount', value: round.drops },
        { key: 'highestMergeLevel', value: round.highest }, { key: 'madeWatermelon', value: round.highest >= 7 ? 1 : 0 },
        { key: 'isFinalMerge', value: round.highest >= 10 ? 1 : 0 }
      ]
    });
  }
}
