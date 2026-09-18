import { common } from '@kit.AbilityKit';
import systemDateTime from '@ohos.systemDateTime';
import { AchievementEvent } from '../../shell/AchievementModule';
import { BlockEngine } from './BlockEngine';
import { BLOCK_ASSETS, BlockEvent } from './BlockModel';
import { BlockCrease, BlockFold, BlockInsets, BlockLayout, blockLayout } from './BlockLayout';
import { BlockPalette } from './BlockPalette';
import { BlockRenderer } from './BlockRenderer';
import { BlockAction, BlockIconButton, BlockKey, BlockPreview } from './BlockControls';
import { BlockAudio } from './BlockAudio';
import { BlockStorage } from './BlockStorage';
import { BlockWindow } from './BlockWindow';
import { BlockPerformance } from './BlockPerformance';
import { BlockScorePanel } from './BlockPanels';
import { BlockHelp } from './BlockHelp';
import { BlockBackdrop } from './BlockBackdrop';

@Component
export struct BlockWorkshopPage {
  @Prop @Watch('themeChanged') dark: boolean = false;
  @Prop bestScore: number = 0;
  @Prop @Watch('soundChanged') soundEnabled: boolean = true;
  @Prop @Watch('exitRequested') exitRequest: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  reportAchievementEvent: (event: AchievementEvent) => Promise<boolean> = async () => false;
  private achievementRequests: string[] = [];
  private achievementRetryAt: number = 0;
  private engine: BlockEngine = new BlockEngine();
  private renderer: BlockRenderer = new BlockRenderer();
  private canvas: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private sounds: BlockAudio = new BlockAudio();
  private storage: BlockStorage = new BlockStorage();
  private hostWindow: BlockWindow = new BlockWindow();
  private performance: BlockPerformance = new BlockPerformance();
  private context: common.Context | undefined = undefined;
  private insets: BlockInsets = { top: 24, bottom: 16, left: 0, right: 0 };
  private crease: BlockCrease = { x: 0, y: 0, width: 0, height: 0 };
  private fold: BlockFold = { foldable: false, status: 0 };
  private pageWidth: number = 390;
  private pageHeight: number = 844;
  private timer: number = -1;
  private repeatTimer: number = -1;
  private held: string = '';
  private lastTick: number = 0;
  private lastSave: number = 0;
  private ready: boolean = false;
  private canvasReady: boolean = false;
  private disposed: boolean = false;
  private loaded: boolean = false;
  private helpReturn: string = 'paused';
  @State viewport: BlockLayout = blockLayout(390, 844, { top: 24, bottom: 16, left: 0, right: 0 });
  @State dialog: string = 'loading';
  @State score: number = 0;
  @State best: number = 0;
  @State lines: number = 0;
  @State level: number = 1;
  @State combo: number = -1;
  @State lastClear: number = 0;
  @State hold: number = -1;
  @State holdUsed: boolean = false;
  @State next0: number = 0;
  @State next1: number = 0;
  @State next2: number = 0;
  @State saveFailed: boolean = false;
  @State saving: boolean = false;

  aboutToAppear(): void {
    this.context = this.getUIContext().getHostContext() as common.Context;
    if (this.context === undefined) { this.dialog = 'error'; return; }
    this.sounds.setEnabled(this.soundEnabled);
    this.sounds.init(this.context);
    this.hostWindow.setDark(this.dark);
    this.hostWindow.attach(this.context, (px: number): number => this.getUIContext().px2vp(px),
      (insets: BlockInsets, crease: BlockCrease, fold: BlockFold) => this.windowChanged(insets, crease, fold),
      () => this.pause());
    this.boot();
  }

  aboutToDisappear(): void {
    this.disposed = true;
    this.stop();
    this.save();
    this.hostWindow.release();
    this.sounds.release();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      BlockBackdrop({ dark: this.dark, areaWidth: this.pageWidth, areaHeight: this.pageHeight,
        contentWidth: this.viewport.contentWidth, wide: this.viewport.wide })
      if (this.viewport.limited) {
        this.SpacePrompt()
      } else {
        Column({ space: this.viewport.gap }) {
          this.Header()
          if (this.viewport.wide) {
            Row({ space: this.viewport.gap }) {
              this.Board()
                Column({ space: this.viewport.gap }) {
                  this.Stats()
                  Row({ space: 8 }) {
                    BlockPreview({ kind: this.hold, compact: this.viewport.compact, label: this.holdUsed ? '已暂存' : '暂存', dark: this.dark,
                      muted: this.holdUsed, interactive: true, action: () => this.action('hold') }).layoutWeight(1)
                    BlockPreview({ kind: this.next0, compact: this.viewport.compact, label: '接下来', order: 1, dark: this.dark }).layoutWeight(1)
                  }
                  if (!this.viewport.compact) {
                    Row({ space: 8 }) {
                      BlockPreview({ kind: this.next1, label: '随后', order: 2, dark: this.dark }).layoutWeight(1)
                      BlockPreview({ kind: this.next2, label: '随后', order: 3, dark: this.dark }).layoutWeight(1)
                    }
                  }
                  this.Controls()
                  if (this.viewport.body >= 280) {
                    BlockAction({ label: '操作与计分', dark: this.dark, primary: false, action: () => this.showHelp() })
                  }
                }.width(this.viewport.rail)
            }.width('100%').height(this.viewport.body).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Top)
          } else {
            this.Stats()
            Row({ space: this.viewport.gap }) {
              this.Board()
                Column({ space: this.viewport.compact ? 6 : 10 }) {
                  BlockPreview({ kind: this.hold, compact: this.viewport.compact, label: this.holdUsed ? '已暂存' : '暂存', dark: this.dark,
                    muted: this.holdUsed, interactive: true, action: () => this.action('hold') })
                  BlockPreview({ kind: this.next0, compact: this.viewport.compact, label: '接下来', order: 1, dark: this.dark })
                  BlockPreview({ kind: this.next1, compact: this.viewport.compact, label: '随后', order: 2, dark: this.dark })
                  BlockPreview({ kind: this.next2, compact: this.viewport.compact, label: '随后', order: 3, dark: this.dark })
                  if (this.viewport.ornamentHeight > 0) {
                    Blank().layoutWeight(1)
                    Image($rawfile(BlockPalette.scene('workbench', this.dark)))
                      .width(this.viewport.rail).height(this.viewport.ornamentHeight).objectFit(ImageFit.Contain)
                      .draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
                  }
                }.width(this.viewport.rail).height(this.viewport.body)
            }.width('100%').height(this.viewport.body).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Top)
            this.Controls()
          }
        }.width(this.viewport.contentWidth).height(this.viewport.height)
          .padding({ left: this.viewport.gap, right: this.viewport.gap })
          .justifyContent(this.viewport.wide ? FlexAlign.Center : FlexAlign.Start)
          .position({ x: this.viewport.x + (this.viewport.width - this.viewport.contentWidth) / 2, y: this.viewport.y })
        if (this.dialog.length > 0) { this.Dialog() }
      }
    }.width('100%').height('100%').backgroundColor(BlockPalette.background(this.dark))
      .onAreaChange((oldArea: Area, area: Area) => {
        this.pageWidth = Number(area.width); this.pageHeight = Number(area.height);
        this.cancelHold(); this.hostWindow.measure(); this.relayout();
      })
  }

  @Builder
  Header() {
    Row({ space: 8 }) {
      BlockIconButton({ icon: 'back', label: '暂停并返回', dark: this.dark, action: () => this.exitRequested() })
      Column({ space: 2 }) {
        Text('俄罗斯方块').fontSize(this.viewport.width < 350 ? 17 : 20).fontWeight(FontWeight.Bold)
          .fontColor(BlockPalette.ink(this.dark)).maxLines(1)
        Text('方块工坊 · 慢慢拼好每一行').fontSize(10).fontColor(BlockPalette.muted(this.dark)).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Row({ space: 4 }) {
        BlockIconButton({ icon: this.soundEnabled ? 'sound' : 'mute', label: this.soundEnabled ? '关闭声音' : '开启声音',
          dark: this.dark, quiet: true, action: () => this.updateSound(!this.soundEnabled) })
        BlockIconButton({ icon: 'pause', label: '暂停与玩法', dark: this.dark, primary: true, action: () => this.pause() })
      }.padding(2).borderRadius(24).backgroundColor(BlockPalette.surface(this.dark))
        .border({ width: 1, color: BlockPalette.line(this.dark), radius: 24 })
    }.width('100%').height(this.viewport.header)
  }

  @Builder
  Stats() {
    BlockScorePanel({ dark: this.dark, compact: this.viewport.compact,
      score: this.score, best: this.best, lines: this.lines, level: this.level })
      .width('100%').height(this.viewport.stats)
  }

  @Builder
  Board() {
    Stack() {
      Stack() {
        Image($rawfile(BlockPalette.scene('field', this.dark))).width('100%').height('100%')
          .objectFit(ImageFit.Fill).draggable(false).accessibilityLevel('no').hitTestBehavior(HitTestMode.None)
        Canvas(this.canvas).width(this.viewport.boardWidth).height(this.viewport.boardHeight)
          .onReady(() => { this.canvasReady = true; this.renderer.invalidate(); this.paint(); })
          .onAreaChange(() => { this.renderer.invalidate(); this.paint(); })
          .accessibilityText('十列二十行棋盘，通过下方或右侧按钮移动、旋转和落下方块')
      }.width(this.viewport.boardWidth).height(this.viewport.boardHeight)
        .backgroundColor(BlockPalette.surface(this.dark)).borderRadius(8).clip(true)
    }.width(this.viewport.boardWidth + 16).height(this.viewport.boardHeight + 16)
      .backgroundColor(BlockPalette.surface(this.dark)).borderRadius(18)
      .border({ width: 1, color: BlockPalette.line(this.dark), radius: 18 })
  }

  @Builder
  Key(name: string, label: string, primary: boolean = false) {
    BlockKey({ name: name, label: label, dark: this.dark, primary: primary,
      compact: this.viewport.compact || (this.viewport.wide && this.viewport.rail < 250),
      spacious: this.viewport.spaciousControls,
      active: this.dialog.length === 0 && !this.viewport.limited && this.ready,
      press: (key: string) => this.startHold(key), release: (key: string) => this.endHold(key),
      click: (key: string) => this.action(key) }).layoutWeight(1)
  }

  @Builder
  Controls() {
      Column({ space: this.viewport.keyGap }) {
      Row({ space: this.viewport.keyGap }) {
        this.Key('left', '左移')
        this.Key('down', '软降')
        this.Key('right', '右移')
      }.width('100%').layoutWeight(1)
      Row({ space: this.viewport.keyGap }) {
        this.Key('reverse', '逆转')
        this.Key('drop', '落下', true)
        this.Key('rotate', '旋转')
      }.width('100%').layoutWeight(1)
      }.width('100%').height(this.viewport.keys)
  }

  @Builder
  Dialog() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(this.dark ? '#a0101611' : '#70534d38')
      if (this.dialog === 'help') {
        BlockHelp({ dark: this.dark, availableWidth: this.viewport.width, availableHeight: this.viewport.height,
          close: () => this.closeHelp() })
      } else {
      Scroll() {
        Column({ space: this.viewport.compact ? 10 : 14 }) {
          if (this.viewport.height >= 400) {
            Image($rawfile(`${BLOCK_ASSETS}pieces/2.svg`))
              .width(72).height(44)
              .objectFit(ImageFit.Contain).draggable(false).accessibilityLevel('no')
          }
          Text(this.dialogTitle()).fontSize(this.viewport.compact ? 22 : 25).fontWeight(FontWeight.Bold).fontColor(BlockPalette.ink(this.dark))
            .textAlign(TextAlign.Center).width('100%')
          Text(this.dialogBody()).fontSize(13).lineHeight(23).fontColor(BlockPalette.muted(this.dark))
            .textAlign(TextAlign.Center).width('100%')
          if (this.saveFailed) {
            Text('进度保存失败，可重试保存后返回。').fontSize(12).fontColor(this.dark ? '#ffbb91' : '#a45430')
          }
          if (this.dialog === 'loading') {
            LoadingProgress().width(36).height(36).color(BlockPalette.accent(this.dark))
          } else if (this.dialog === 'error') {
            BlockAction({ label: '重新载入', dark: this.dark, action: () => this.boot() })
          } else if (this.dialog === 'restart') {
            BlockAction({ label: '确认重新开始', dark: this.dark, action: () => this.restart() })
            BlockAction({ label: '保留这局', dark: this.dark, primary: false,
              action: () => { this.dialog = this.engine.round.phase === 'over' ? 'over' : 'paused'; } })
          } else {
            BlockAction({ label: this.dialog === 'over' ? '再来一局' : this.dialog === 'ready' ? '开始游戏' : '继续这一局',
              icon: 'play', dark: this.dark, active: !this.saving,
              action: () => { if (this.dialog === 'over') this.restart(); else this.resume(); } })
            BlockAction({ label: '操作与计分', dark: this.dark, primary: false, action: () => this.showHelp() })
            if (this.dialog !== 'over' && this.dialog !== 'ready') {
              BlockAction({ label: '重新开始', dark: this.dark, primary: false, action: () => { this.dialog = 'restart'; } })
            }
          }
          if (this.dialog !== 'loading') {
            BlockAction({ label: this.saving ? '正在保存…' : '保存并返回大厅', dark: this.dark, primary: false,
              active: !this.saving, action: () => this.saveAndExit() })
          }
          if (this.saveFailed) {
            BlockAction({ label: '不保存，直接返回', dark: this.dark, primary: false, action: () => this.exitToHub() })
          }
        }.padding(this.viewport.compact ? 18 : 24).width('100%')
      }.width(Math.min(360, this.viewport.width - 32)).constraintSize({ maxHeight: Math.max(100, this.viewport.height - 32) })
        .backgroundColor(BlockPalette.surface(this.dark)).borderRadius(28)
        .border({ width: 1, color: BlockPalette.line(this.dark), radius: 28 }).scrollBar(BarState.Off)
      }
    }.width(this.viewport.width).height(this.viewport.height).position({ x: this.viewport.x, y: this.viewport.y })
  }

  @Builder
  SpacePrompt() {
    Stack() {
      Scroll() {
        Column({ space: 14 }) {
          if (this.viewport.unfold) {
            Image($rawfile(BlockPalette.scene('unfold', this.dark))).width(180).height(98)
              .objectFit(ImageFit.Contain).draggable(false).accessibilityLevel('no')
          } else {
            Image($rawfile(BlockPalette.icon('expand', this.dark))).width(40).height(40)
              .draggable(false).accessibilityLevel('no')
          }
          Text(this.viewport.unfold ? '展开屏幕，继续拼搭' : '给方块多一点空间').fontSize(22).fontWeight(FontWeight.Bold)
            .fontColor(BlockPalette.ink(this.dark)).textAlign(TextAlign.Center)
          Text(this.viewport.unfold ? '当前可用区域太小，游戏已暂停。\n展开屏幕或放大窗口后，\n点击继续，接着玩这一局。' :
            '当前窗口太小，游戏已暂停。\n旋转设备或放大窗口后，\n就能继续这一局。').fontSize(13).lineHeight(23)
            .fontColor(BlockPalette.muted(this.dark)).textAlign(TextAlign.Center)
          if (this.saveFailed) { Text('保存失败，请重试或选择直接返回。').fontSize(12).fontColor(BlockPalette.muted(this.dark)) }
          BlockAction({ label: this.saving ? '正在保存…' : this.loaded ? '保存并返回大厅' : '返回大厅', dark: this.dark,
            active: !this.saving, action: () => this.saveAndExit() })
          if (this.saveFailed) {
            BlockAction({ label: '不保存，直接返回', dark: this.dark, primary: false, action: () => this.exitToHub() })
          }
        }.padding(24).width('100%')
      }.width(Math.max(1, Math.min(360, this.viewport.width - 24)))
        .constraintSize({ maxHeight: Math.max(1, this.viewport.height - 24) })
        .backgroundColor(BlockPalette.surface(this.dark)).borderRadius(26).scrollBar(BarState.Off)
    }.width(this.viewport.width).height(this.viewport.height).position({ x: this.viewport.x, y: this.viewport.y })
  }

  private async boot(): Promise<void> {
    if (this.context === undefined || this.disposed) { this.dialog = 'error'; return; }
    this.dialog = 'loading';
    const raw = await this.storage.load(this.context);
    if (this.disposed) return;
    const restored = raw.length > 0 && this.engine.restore(raw);
    this.loaded = true;
    this.ready = true;
    this.engine.round.best = Math.max(this.bestScore, this.engine.round.best);
    this.dialog = restored ? (this.engine.round.phase === 'over' ? 'over' : 'paused') : 'ready';
    this.sync(); this.paint();
    this.milestones(true);
    if (this.engine.round.phase === 'over') this.finish();
  }

  private now(): number { return systemDateTime.getUptime(systemDateTime.TimeType.STARTUP, true) / 1000000; }
  private playing(): boolean { return this.ready && !this.disposed && this.dialog === '' && !this.viewport.limited; }

  private step(): void {
    if (!this.playing()) return;
    const now = this.now();
    this.engine.advance(Math.max(0, now - this.lastTick));
    this.lastTick = now;
    this.performance.logic(this.now() - now);
  }

  private schedule(): void {
    if (this.timer >= 0) clearTimeout(this.timer);
    this.timer = -1;
    if (!this.playing() || this.engine.round.phase === 'over') return;
    this.timer = setTimeout(() => {
      this.timer = -1;
      if (!this.playing()) return;
      this.step(); this.flush(); this.schedule();
    }, this.engine.nextDelay());
  }

  private action(name: string): void {
    if (!this.playing()) return;
    this.step();
    const start = this.now();
    this.engine.command(name);
    this.performance.logic(this.now() - start);
    this.flush(); this.schedule();
  }

  private startHold(name: string): void {
    this.cancelHold();
    this.action(name);
    if (!this.playing() || !['left', 'right', 'down'].includes(name)) return;
    this.held = name;
    this.repeatTimer = setTimeout(() => this.repeat(), name === 'down' ? 100 : 180);
  }

  private repeat(): void {
    this.repeatTimer = -1;
    if (!this.playing() || this.held.length === 0) { this.cancelHold(); return; }
    this.action(this.held);
    if (this.playing() && this.held.length > 0) this.repeatTimer = setTimeout(() => this.repeat(), 55);
  }
  private endHold(name: string): void { if (this.held === name) this.cancelHold(); }
  private cancelHold(): void {
    if (this.repeatTimer >= 0) clearTimeout(this.repeatTimer);
    this.repeatTimer = -1; this.held = '';
  }
  private stop(): void {
    if (this.timer >= 0) clearTimeout(this.timer);
    this.timer = -1; this.cancelHold(); this.sounds.silence();
  }

  private flush(): void {
    const events: BlockEvent[] = this.engine.takeEvents();
    const priorities: string[] = ['finish', 'level', 'four', 'clear', 'drop', 'hold', 'rotate', 'lock', 'move'];
    for (let i = 0; i < priorities.length; i += 1) {
      if (events.some((event: BlockEvent): boolean => event.name === priorities[i])) { this.sounds.play(priorities[i]); break; }
    }
    this.sync(); this.paint(); this.milestones();
    this.performance.report(this.now(), this.level,
      this.engine.round.pieces * 4 - this.engine.round.lines * 10);
    if (this.engine.round.phase === 'over') { this.finish(); return; }
    if (this.now() - this.lastSave >= 5000) this.save();
  }

  private sync(): void {
    const r = this.engine.round;
    if (this.score !== r.score) this.score = r.score;
    if (this.best !== r.best) this.best = r.best;
    if (this.lines !== r.lines) this.lines = r.lines;
    if (this.level !== r.level) this.level = r.level;
    if (this.combo !== r.combo) this.combo = r.combo;
    if (this.lastClear !== r.lastClear) this.lastClear = r.lastClear;
    if (this.hold !== r.hold) this.hold = r.hold;
    if (this.holdUsed !== r.holdUsed) this.holdUsed = r.holdUsed;
    if (this.next0 !== r.queue[0]) this.next0 = r.queue[0];
    if (this.next1 !== r.queue[1]) this.next1 = r.queue[1];
    if (this.next2 !== r.queue[2]) this.next2 = r.queue[2];
  }
  private paint(): void {
    if (!this.canvasReady || this.viewport.limited) return;
    const start = this.now();
    if (this.renderer.paint(this.canvas, this.engine, this.viewport.boardWidth, this.dark)) {
      this.performance.paint(this.now() - start);
    }
  }

  private pause(): void {
    if (this.dialog.length > 0 || !this.ready) { this.stop(); return; }
    this.step(); this.flush();
    if (this.engine.round.phase !== 'over') this.dialog = 'paused';
    this.stop(); this.save();
  }
  private resume(): void {
    if (!this.ready || this.viewport.limited || this.engine.round.phase === 'over' || this.saving) return;
    this.dialog = ''; this.lastTick = this.now(); this.performance.reset(this.lastTick);
    this.sounds.play('tap'); this.schedule();
  }
  private restart(): void {
    if (this.saving || !this.ready) return;
    this.stop();
    const best = this.engine.round.best;
    this.engine = new BlockEngine(); this.engine.round.best = best;
    this.renderer.invalidate(); this.sync(); this.paint(); this.save(); this.resume();
  }
  private showHelp(): void {
    this.pause();
    this.helpReturn = this.dialog === 'help' ? 'paused' : this.dialog;
    this.dialog = 'help';
  }
  private closeHelp(): void { this.dialog = this.helpReturn; }
  private exitRequested(): void {
    if (this.dialog === 'help') { this.closeHelp(); return; }
    if (!this.ready) this.exitToHub(); else this.pause();
  }
  private themeChanged(): void { this.hostWindow.setDark(this.dark); this.renderer.invalidate(); this.paint(); }
  private soundChanged(): void { this.sounds.setEnabled(this.soundEnabled); }

  private windowChanged(insets: BlockInsets, crease: BlockCrease, fold: BlockFold): void {
    if (this.fold.status !== fold.status) this.cancelHold();
    this.insets = insets; this.crease = crease; this.fold = fold;
    this.relayout();
  }

  private relayout(): void {
    const next = blockLayout(this.pageWidth, this.pageHeight, this.insets, this.crease, this.fold);
    if (next.x !== this.viewport.x || next.y !== this.viewport.y || next.width !== this.viewport.width ||
      next.height !== this.viewport.height || next.wide !== this.viewport.wide) this.cancelHold();
    if (next.limited && !this.viewport.limited) this.pause();
    this.viewport = next;
    this.renderer.invalidate(); this.paint();
  }

  private async save(): Promise<boolean> {
    if (!this.loaded || this.context === undefined) return false;
    this.lastSave = this.now();
    const ok = await this.storage.save(this.context, this.engine.serialize());
    if (!this.disposed) this.saveFailed = !ok;
    return ok;
  }
  private async saveAndExit(): Promise<void> {
    if (this.saving) return;
    if (!this.loaded) { this.exitToHub(); return; }
    this.pause(); this.saving = true;
    if (await this.save()) { if (!this.disposed) this.exitToHub(); }
    if (!this.disposed) this.saving = false;
  }

  private milestones(restoring: boolean = false): void {
    if (Date.now() < this.achievementRetryAt) return;
    const r = this.engine.round;
    const achieved: boolean[] = [r.maxClear >= 4, r.lines >= 20, r.level >= 3];
    for (let i = 0; i < achieved.length; i += 1) {
      const bit = 1 << i;
      if (achieved[i] && (restoring || (r.milestones & bit) === 0)) {
        this.report('milestone', 'milestone-' + i).then((accepted: boolean) => {
          if (accepted) {
            r.milestones |= bit;
            if (r === this.engine.round) this.save();
          }
        });
      }
    }
  }
  private finish(): void {
    this.dialog = 'over';
    if (this.timer >= 0) clearTimeout(this.timer);
    this.timer = -1; this.cancelHold();
    if (!this.engine.round.reported) this.report('sessionEnd', 'finish');
    this.save();
  }
  private async report(type: 'milestone' | 'sessionEnd', suffix: string): Promise<boolean> {
    const r = this.engine.round;
    const eventId = r.session + ':' + suffix;
    if (this.achievementRequests.includes(eventId)) return false;
    this.achievementRequests.push(eventId);
    const accepted = await this.reportAchievementEvent({ eventId: eventId, sessionId: r.session, gameId: 'tetris',
      type: type, occurredAt: Date.now(), isOfficial: true,
      facts: [{ key: 'score', value: r.score }, { key: 'maxClearedLines', value: r.maxClear },
        { key: 'totalLines', value: r.lines }, { key: 'level', value: r.level }] }).catch(() => false);
    if (accepted && type === 'sessionEnd') {
      r.reported = true;
      this.recordScore(r.score);
      if (r === this.engine.round) await this.save();
    }
    if (!accepted) this.achievementRetryAt = Date.now() + 5000;
    this.achievementRequests = this.achievementRequests.filter((id: string) => id !== eventId);
    return accepted;
  }

  private dialogTitle(): string {
    if (this.dialog === 'loading') return '正在整理方块';
    if (this.dialog === 'error') return '暂时没有准备好';
    if (this.dialog === 'ready') return '欢迎来到方块工坊';
    if (this.dialog === 'over') return '这一局，拼得不错';
    if (this.dialog === 'restart') return '重新开始这一局？';
    return '歇一会儿，方块等你';
  }
  private dialogBody(): string {
    if (this.dialog === 'loading') return '正在读取本地进度';
    if (this.dialog === 'error') return '返回大厅后重试即可。';
    if (this.dialog === 'ready') return '七种方块，十列空间。\n旋转、暂存，找到刚刚好的落点。';
    if (this.dialog === 'restart') return '当前棋盘会被替换，最高分会保留。';
    return `得分 ${this.score}  ·  消行 ${this.lines}  ·  等级 ${this.level}\n${this.dialog === 'over' ? '下一局，也许能留出更漂亮的空位。' : '棋盘已暂停，可以安心回来接着玩。'}`;
  }
}
