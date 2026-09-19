import { common } from '@kit.AbilityKit';
import { AchievementEvent } from '../../shell/AchievementModule';
import { MemoryAudio } from './MemoryAudio';
import { MemoryBackdrop } from './MemoryBackdrop';
import { MemoryBoard } from './MemoryBoard';
import { MemoryIconButton, MemoryModes, MemoryStats, MemoryTools } from './MemoryControls';
import { MemoryDialog } from './MemoryDialog';
import { MemoryEngine } from './MemoryEngine';
import { MemoryInsets, MemoryCrease, MemoryLayout, memoryLayout } from './MemoryLayout';
import { MEMORY_HINT, MEMORY_LOGO, MemoryMode, MemoryRound, memoryMatched } from './MemoryModel';
import { MemoryPalette as P } from './MemoryPalette';
import { MemoryProgress } from './MemoryProgress';
import { MemoryReflow } from './MemoryReflow';
import { memoryDeal } from './MemoryRules';
import { MemoryStorage } from './MemoryStorage';
import { MemoryWindow } from './MemoryWindow';

@Component
export struct MemoryPage {
  @Prop @Watch('themeChanged') dark: boolean = false;
  @Prop @Watch('soundChanged') soundEnabled: boolean = true;
  @Prop @Watch('exitRequested') exitRequest: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (tables: number) => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  reportAchievementEvent: (event: AchievementEvent) => Promise<boolean> = async () => false;
  private engine: MemoryEngine = new MemoryEngine();
  private audio: MemoryAudio = new MemoryAudio();
  private storage: MemoryStorage = new MemoryStorage();
  private host: MemoryWindow = new MemoryWindow();
  private progress: MemoryProgress | undefined = undefined;
  private context: common.Context | undefined = undefined;
  private loaded: boolean = false;
  private loading: boolean = false;
  private disposed: boolean = false;
  private skipSave: boolean = false;
  private backgroundPaused: boolean = false;
  private timer: number = -1;
  private generation: number = 0;
  private saveSequence: number = 0;
  private layoutGeneration: number = 0;
  private returnDialog: string = '';
  private insets: MemoryInsets = { top: 24, bottom: 16, left: 0, right: 0 };
  private creases: MemoryCrease[] = [];
  private verticalScroll: Scroller = new Scroller();
  private horizontalScroll: Scroller = new Scroller();
  @State pageWidth: number = 390;
  @State pageHeight: number = 844;
  @State layout: MemoryLayout = memoryLayout(390, 844, { top: 24, bottom: 16, left: 0, right: 0 });
  @State round: MemoryRound = memoryDeal('journey', 1, 1);
  @State best: number = 0;
  @State totalTables: number = 0;
  @State totalPairs: number = 0;
  @State dialog: string = 'loading';
  @State pendingMode: MemoryMode = 'journey';
  @State saving: boolean = false;
  @State saveFailed: boolean = false;
  @State deal: boolean = true;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.Context;
    this.context = context;
    if (context === undefined) { this.dialog = 'loadError'; return; }
    this.progress = new MemoryProgress(this.engine, {
      save: (raw: string): Promise<boolean> => this.storage.save(context, raw),
      report: (event: AchievementEvent): Promise<boolean> => this.reportAchievementEvent(event),
      record: (tables: number): void => this.recordScore(tables)
    });
    this.audio.setEnabled(this.soundEnabled);
    this.audio.init(context);
    this.host.setDark(this.dark);
    this.host.attach(context, (px: number): number => this.getUIContext().px2vp(px),
      (insets: MemoryInsets, creases: MemoryCrease[]) => {
        this.insets = insets;
        this.creases = creases;
        this.relayout();
      }, () => this.backgrounded());
    this.boot();
  }
  aboutToDisappear(): void {
    this.cancelTimer();
    this.disposed = true;
    if (!this.skipSave) { this.save(); }
    this.host.release();
    this.audio.release();
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      MemoryBackdrop({ dark: this.dark, canvasWidth: this.pageWidth, canvasHeight: this.pageHeight })
      Column({ space: 10 }) {
        this.Header()
        Scroll(this.horizontalScroll) {
          Scroll(this.verticalScroll) {
            this.PlayArea()
          }.width(this.layout.contentWidth).height(this.layout.body)
          .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).edgeEffect(EdgeEffect.None)
          .enableScrollInteraction(this.layout.contentHeight > this.layout.body).align(Alignment.TopStart)
        }.width('100%').height(this.layout.body).scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off).edgeEffect(EdgeEffect.None)
        .enableScrollInteraction(this.layout.contentWidth > this.layout.width - this.layout.gap * 2)
        .align(Alignment.TopStart)
      }.width(this.layout.width).height(this.layout.height).clip(true)
      .padding({ left: this.layout.gap, right: this.layout.gap, top: 4, bottom: 8 })
      .position({ x: this.layout.x, y: this.layout.y }).enabled(this.dialog.length === 0)
      .accessibilityLevel(this.dialog.length === 0 ? 'auto' : 'no-hide-descendants')
      if (this.dialog.length > 0) {
        MemoryDialog({ dark: this.dark, mode: this.dialog, target: this.pendingMode, number: this.round.number,
          found: memoryMatched(this.round), pairs: this.round.pairs, attempts: this.round.attempts,
          saving: this.saving, saveFailed: this.saveFailed,
          panelWidth: Math.min(390, Math.max(1, this.layout.width - 20)), panelHeight: Math.max(40, this.layout.height - 20),
          close: () => this.closeDialog(), confirm: () => this.newJourney(), restart: () => this.requestRestart(),
          leave: () => this.saveAndExit(), discard: () => { this.skipSave = true; this.exitToHub(); },
          retry: () => this.boot(), retrySave: () => this.retrySave()
        }).width(this.layout.width).height(this.layout.height).position({ x: this.layout.x, y: this.layout.y })
      }
    }.width('100%').height('100%').backgroundColor(P.bg(this.dark))
    .onAreaChange((_oldArea: Area, area: Area) => {
      this.pageWidth = Number(area.width);
      this.pageHeight = Number(area.height);
      this.host.measure();
      this.relayout();
    })
  }
  @Builder
  Header() {
    Row({ space: 8 }) {
      MemoryIconButton({ dark: this.dark, icon: 'back', label: '保存并返回大厅', action: () => this.exitRequested() })
      if (this.layout.width >= 340) {
        Image($rawfile(MEMORY_LOGO)).width(35).height(35).accessibilityLevel('no')
      }
      Column({ space: 1 }) {
        Text('记忆翻牌').fontSize(22).minFontSize(13).maxFontSize(22).maxLines(1).width('100%')
          .fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        Text('庭院寻双').fontSize(10).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      MemoryIconButton({ dark: this.dark, icon: this.soundEnabled ? 'sound' : 'muted',
        label: this.soundEnabled ? '关闭音效' : '开启音效', action: () => this.updateSound(!this.soundEnabled) })
      MemoryIconButton({ dark: this.dark, icon: 'pause', label: '暂停', primary: true, action: () => this.present('pause') })
    }.width('100%').height(52)
  }
  @Builder
  PlayArea() {
    // The same nodes survive folded / expanded layout changes, including face-up cards.
    Stack({ alignContent: Alignment.TopStart }) {
      MemoryStats({ dark: this.dark, attempts: this.round.attempts, streak: this.round.streak, best: this.best,
        panelHeight: this.layout.stats.height }).width(this.layout.stats.width)
        .position({ x: this.layout.stats.x, y: this.layout.stats.y })
      MemoryModes({ dark: this.dark, mode: this.round.mode, panelHeight: this.layout.modes.height,
        choose: (mode: MemoryMode) => this.chooseMode(mode) })
        .width(this.layout.modes.width).position({ x: this.layout.modes.x, y: this.layout.modes.y })
      MemoryBoard({ dark: this.dark, round: this.round, boardWidth: this.layout.board.width, boardHeight: this.layout.board.height,
        card: this.layout.card, cardHeight: this.layout.cardHeight, gap: this.layout.tileGap, pad: this.layout.pad,
        headerHeight: this.layout.boardHeader, footerHeight: this.layout.boardFooter,
        active: this.loaded && !this.saving, deal: this.deal, hint: this.hint(), failed: this.saveFailed,
        tap: (index: number) => this.tap(index), retry: () => this.retrySave()
      }).position({ x: this.layout.board.x, y: this.layout.board.y })
      MemoryTools({ dark: this.dark, panelHeight: this.layout.tools.height,
        restart: () => this.requestRestart(), help: () => this.present('help') })
        .width(this.layout.tools.width).position({ x: this.layout.tools.x, y: this.layout.tools.y })
      if (this.layout.note.height > 0) {
        this.Note()
      }
    }.width(this.layout.contentWidth).height(this.layout.contentHeight)
  }
  @Builder
  Note() {
    Column({ space: 5 }) {
      if (this.layout.wide) {
        Image($rawfile(P.scene('mascot', this.dark))).width(100).height(82).objectFit(ImageFit.Contain).accessibilityLevel('no')
      }
      Text(this.layout.wide ? '不着急，小伙伴都在这里' : '不赶时间，慢慢找到彼此')
        .fontSize(this.layout.wide ? 14 : 11).fontColor(P.muted(this.dark))
      Text('已配好 ' + this.totalPairs + ' 对 · 完成 ' + this.totalTables + ' 桌')
        .fontSize(10).fontColor(P.muted(this.dark))
      if (this.layout.wide && this.round.mode === 'journey') {
        Text(this.round.pairs < 12 ? '每两桌添两对，慢慢练习记忆' : '保持 12 对，接着遇见新的小伙伴')
          .fontSize(10).fontColor(P.gold(this.dark))
      }
    }.width(this.layout.note.width).height(this.layout.note.height).justifyContent(FlexAlign.Center)
    .position({ x: this.layout.note.x, y: this.layout.note.y }).hitTestBehavior(HitTestMode.None)
  }
  private hint(): string {
    if (this.saveFailed) { return '进度或成就暂未保存，点重试继续'; }
    if (this.round.phase === 'complete') { return this.saving ? '收好这一桌的小欢喜…' : '这一桌都找到啦 · 马上继续下一桌'; }
    if (this.round.phase === 'mismatch') { return '这次没遇上，记住它们的位置'; }
    if (this.round.phase === 'match') { return this.round.streak > 1 ? '连续找到 ' + this.round.streak + ' 对 · 记得真清楚' : '找到你啦，两位小伙伴相遇了'; }
    return this.round.first >= 0 ? '再翻一张，找找它的小伙伴' : MEMORY_HINT;
  }
  private async boot(): Promise<void> {
    if (this.loading || this.context === undefined) { return; }
    this.loading = true;
    this.dialog = 'loading';
    try {
      const raw = await this.storage.load(this.context);
      if (this.disposed) { return; }
      if (raw.length > 0 && !this.engine.restore(raw)) { this.dialog = 'corrupt'; return; }
      this.loaded = true;
      this.deal = raw.length === 0;
      this.sync();
      this.pendingMode = this.round.mode;
      this.relayout();
      this.dialog = this.backgroundPaused ? 'pause' :
        raw.length > 0 && (this.round.attempts > 0 || this.round.first >= 0 || this.round.number > 1) ? 'resume' : '';
      if (this.dialog.length === 0) { this.schedulePhase(); }
      this.save();
    } catch (_) {
      if (!this.disposed) { this.dialog = 'loadError'; }
    } finally { this.loading = false; }
  }
  private tap(index: number): void {
    if (!this.loaded || this.disposed || this.dialog.length > 0 || this.saving) { return; }
    const result = this.engine.flip(index);
    if (!result.accepted) { return; }
    this.audio.play(result.complete ? 'complete' : result.paired ? (this.engine.round.streak > 1 ? 'combo' : 'match') : 'flip');
    this.sync();
    this.save();
    this.schedulePhase();
  }
  private sync(): void {
    this.round = this.engine.snapshot().round;
    this.best = this.engine.bestAttempts();
    this.totalTables = this.engine.profile.totalTables;
    this.totalPairs = this.engine.profile.totalPairs;
  }
  private cancelTimer(): void {
    this.generation += 1;
    if (this.timer !== -1) { clearTimeout(this.timer); }
    this.timer = -1;
  }
  private schedulePhase(): void {
    this.cancelTimer();
    if (this.disposed || this.dialog.length > 0 || this.backgroundPaused) { return; }
    const phase = this.engine.round.phase;
    if (phase === 'ready') { return; }
    const token = this.generation;
    const id = this.engine.round.id;
    this.timer = setTimeout(() => {
      if (this.disposed || token !== this.generation || this.engine.round.id !== id) { return; }
      this.timer = -1;
      if (phase === 'complete') {
        if (!this.saveFailed) { this.advance(); }
      } else if (this.engine.settle()) {
        if (phase === 'mismatch') { this.audio.play('miss'); }
        this.sync();
        this.save();
      }
    }, phase === 'mismatch' ? 1000 : phase === 'complete' ? 1700 : 460);
  }
  private async advance(): Promise<void> {
    if (this.disposed || this.dialog.length > 0 || this.saving || this.engine.round.phase !== 'complete') { return; }
    this.saving = true;
    const accepted = await this.save();
    if (this.disposed) { return; }
    this.saving = false;
    if (!accepted || this.dialog.length > 0 || this.backgroundPaused || !this.engine.next()) { return; }
    this.deal = true;
    this.sync();
    this.relayout(true);
    this.audio.play('deal');
    this.save();
  }
  private present(mode: string): void {
    if (!this.loaded || this.saving) { return; }
    this.cancelTimer();
    this.audio.silence();
    this.returnDialog = this.dialog;
    this.dialog = mode;
    this.save();
  }
  private closeDialog(): void {
    if (!this.loaded || this.saving) { return; }
    if (this.dialog === 'pause' || this.dialog === 'resume') {
      this.dialog = '';
      this.backgroundPaused = false;
    } else { this.dialog = this.backgroundPaused ? 'pause' : this.returnDialog; }
    this.returnDialog = '';
    this.pendingMode = this.engine.round.mode;
    this.schedulePhase();
  }
  private chooseMode(mode: MemoryMode): void {
    if (!this.loaded || this.saving || mode === this.round.mode) { return; }
    this.pendingMode = mode;
    this.present('mode');
  }
  private requestRestart(): void {
    this.pendingMode = this.round.mode;
    this.present('restart');
  }
  private async newJourney(): Promise<void> {
    if (this.saving || this.context === undefined) { return; }
    this.cancelTimer();
    this.saving = true;
    const accepted = !this.loaded || await this.save();
    if (this.disposed) { return; }
    this.saving = false;
    if (!accepted) { return; }
    this.engine.restart(this.pendingMode);
    this.loaded = true;
    this.deal = true;
    this.returnDialog = '';
    this.dialog = this.backgroundPaused ? 'pause' : '';
    this.sync();
    this.relayout(true);
    if (!this.backgroundPaused) { this.audio.play('deal'); }
    this.save();
  }
  private relayout(resetScroll: boolean = false): void {
    if (this.disposed) { return; }
    const next = memoryLayout(this.pageWidth, this.pageHeight, this.insets, this.creases, this.engine.round.pairs);
    if (!resetScroll && JSON.stringify(next) === JSON.stringify(this.layout)) { return; }
    this.layout = next;
    const generation = ++this.layoutGeneration;
    this.getUIContext().postFrameCallback(new MemoryReflow(() => {
      if (this.disposed || generation !== this.layoutGeneration) { return; }
      this.verticalScroll.scrollTo({ xOffset: 0, yOffset: 0, animation: false });
      this.horizontalScroll.scrollTo({ xOffset: 0, yOffset: 0, animation: false });
    }));
  }
  private backgrounded(): void {
    this.backgroundPaused = true;
    this.cancelTimer();
    this.audio.silence();
    if (this.loaded && this.dialog.length === 0) { this.dialog = 'pause'; }
    this.save();
  }
  themeChanged(): void { this.host.setDark(this.dark); }
  soundChanged(): void { this.audio.setEnabled(this.soundEnabled); }
  exitRequested(): void {
    if (this.saving) { return; }
    if (!this.loaded) { this.skipSave = true; this.exitToHub(); return; }
    if (['help', 'restart', 'mode', 'exit'].includes(this.dialog)) { this.closeDialog(); }
    else { this.present('exit'); }
  }
  private async save(): Promise<boolean> {
    if (!this.loaded || this.progress === undefined || this.skipSave) { return true; }
    const sequence = ++this.saveSequence;
    const accepted = await this.progress.flush();
    if (!this.disposed && sequence === this.saveSequence) { this.saveFailed = !accepted; }
    return accepted;
  }
  private async retrySave(): Promise<void> {
    if (this.saving) { return; }
    this.saving = true;
    const accepted = await this.save();
    if (this.disposed) { return; }
    this.saving = false;
    if (accepted) { this.schedulePhase(); }
  }
  private async saveAndExit(): Promise<void> {
    if (this.saving) { return; }
    this.cancelTimer();
    this.audio.silence();
    this.saving = true;
    const accepted = await this.save();
    if (this.disposed) { return; }
    this.saving = false;
    if (accepted) { this.skipSave = true; this.exitToHub(); }
    else { this.dialog = 'exit'; }
  }
}
