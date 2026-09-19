import { common } from '@kit.AbilityKit';
import { AchievementEvent } from '../../shell/AchievementModule';
import { TenAudio } from './TenAudio';
import { TenBackdrop } from './TenBackdrop';
import { TenBoard } from './TenBoard';
import { TenActionButton, TenIconButton, TenSelection, TenStats, TenTools } from './TenControls';
import { TenDialog } from './TenDialog';
import { TenEngine } from './TenEngine';
import { TenGesture } from './TenGesture';
import { TenInsets, TenCrease, TenLayout, tenLayout } from './TenLayout';
import { TEN_LOGO, TenHint, TenRound, tenProfile } from './TenModel';
import { TenPalette as P } from './TenPalette';
import { TenProgress } from './TenProgress';
import { TenReflow } from './TenReflow';
import { TenRenderTile, tenReconcileTiles } from './TenRenderTile';
import { tenEqual, tenSelect, tenStart, tenSum } from './TenRules';
import { TenStorage } from './TenStorage';
import { TenWindow } from './TenWindow';

@Component
export struct TenPage {
  @Prop @Watch('themeChanged') dark: boolean = false;
  @Prop @Watch('soundChanged') soundEnabled: boolean = true;
  @Prop @Watch('exitRequested') exitRequest: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (boards: number) => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  reportAchievementEvent: (event: AchievementEvent) => Promise<boolean> = async () => false;
  private engine: TenEngine = new TenEngine();
  private audio: TenAudio = new TenAudio();
  private storage: TenStorage = new TenStorage();
  private host: TenWindow = new TenWindow();
  private progress: TenProgress | undefined = undefined;
  private context: common.Context | undefined = undefined;
  private pointerInput: TenGesture = new TenGesture();
  private pointer: number = -1;
  private gestureCommitted: boolean = false;
  private pendingHint: TenHint | undefined = undefined;
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
  private insets: TenInsets = { top: 24, bottom: 16, left: 0, right: 0 };
  private creases: TenCrease[] = [];
  private verticalScroll: Scroller = new Scroller();
  private horizontalScroll: Scroller = new Scroller();
  @State pageWidth: number = 390;
  @State pageHeight: number = 844;
  @State layout: TenLayout = tenLayout(390, 844, { top: 24, bottom: 16, left: 0, right: 0 }, [], 3);
  @State round: TenRound = tenStart();
  @State tiles: TenRenderTile[] = [];
  @State gridSize: number = 3;
  @State goal: number = 2;
  @State windDirection: number = 0;
  @State selected: number[] = [];
  @State hintCells: number[] = [];
  @State receipt: string = '';
  @State dialog: string = 'loading';
  @State rewind: number = 0;
  @State saving: boolean = false;
  @State saveFailed: boolean = false;
  @State animating: boolean = false;
  @State touching: boolean = false;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.Context;
    this.context = context;
    if (context === undefined) { this.dialog = 'loadError'; return; }
    this.progress = new TenProgress(this.engine, {
      save: (raw: string): Promise<boolean> => this.storage.save(context, raw),
      report: (event: AchievementEvent): Promise<boolean> => this.reportAchievementEvent(event),
      record: (boards: number): void => this.recordScore(boards)
    });
    this.audio.setEnabled(this.soundEnabled);
    this.audio.init(context);
    this.host.setDark(this.dark);
    this.host.attach(context, (px: number): number => this.getUIContext().px2vp(px),
      (insets: TenInsets, creases: TenCrease[]) => {
        this.insets = insets; this.creases = creases; this.relayout();
      }, () => this.backgrounded());
    this.boot();
  }
  aboutToDisappear(): void {
    this.cancelGesture(); this.cancelAnimation();
    this.disposed = true;
    if (!this.skipSave) this.save();
    this.host.release(); this.audio.release();
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      TenBackdrop({ dark: this.dark, canvasWidth: this.pageWidth, canvasHeight: this.pageHeight })
      if (this.layout.width < 280 || this.layout.height < 260) {
        Column({ space: 12 }) {
          Image($rawfile(TEN_LOGO)).width(58).height(58)
          Text('把小院展开一点').fontSize(18).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
          Text('当前可用区域太小，展开屏幕或放大窗口后继续。进度会保留。')
            .fontSize(12).lineHeight(20).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
          TenActionButton({ dark: this.dark, icon: 'back', label: '返回大厅', action: () => this.saveAndExit() })
        }.padding(16).width(this.layout.width).height(this.layout.height).justifyContent(FlexAlign.Center)
          .position({ x: this.layout.x, y: this.layout.y })
      } else {
        Column({ space: 10 }) {
          this.Header()
          Scroll(this.horizontalScroll) {
            Scroll(this.verticalScroll) { this.PlayArea() }
              .width(this.layout.contentWidth).height(this.layout.body).scrollable(ScrollDirection.Vertical)
              .scrollBar(BarState.Off).edgeEffect(EdgeEffect.None)
              .enableScrollInteraction(!this.touching && this.layout.contentHeight > this.layout.body).align(Alignment.TopStart)
          }.width('100%').height(this.layout.body).scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off).edgeEffect(EdgeEffect.None)
            .enableScrollInteraction(!this.touching && this.layout.contentWidth > this.layout.width - this.layout.gap * 2)
            .align(Alignment.TopStart)
        }.width(this.layout.width).height(this.layout.height).clip(true)
          .padding({ left: this.layout.gap, right: this.layout.gap, top: 4, bottom: 8 })
          .position({ x: this.layout.x, y: this.layout.y }).enabled(this.dialog.length === 0)
          .accessibilityLevel(this.dialog.length === 0 ? 'auto' : 'no-hide-descendants')
      }
      if (this.dialog.length > 0) {
        TenDialog({ dark: this.dark, mode: this.dialog, stage: this.round.stage, collected: this.round.history.length,
          goal: this.goal, rewind: this.rewind, hints: this.round.hints, undos: this.round.undos,
          saving: this.saving, saveFailed: this.saveFailed,
          panelWidth: Math.min(430, Math.max(1, this.layout.width - 20)), panelHeight: Math.max(40, this.layout.height - 20),
          close: () => this.closeDialog(), confirm: () => this.confirmDialog(), restart: () => this.present('restart'),
          help: () => this.present('help'), leave: () => this.saveAndExit(),
          discard: () => { this.skipSave = true; this.exitToHub(); }, retry: () => this.boot(), retrySave: () => this.retrySave()
        }).width(this.layout.width).height(this.layout.height).position({ x: this.layout.x, y: this.layout.y })
      }
    }.width('100%').height('100%').backgroundColor(P.bg(this.dark))
      .onAreaChange((_oldArea: Area, area: Area) => {
        this.pageWidth = Number(area.width); this.pageHeight = Number(area.height);
        this.host.measure(); this.relayout();
      })
  }
  @Builder
  Header() {
    Row({ space: 8 }) {
      TenIconButton({ dark: this.dark, icon: 'back', label: '保存并返回大厅', action: () => this.exitRequested() })
      if (this.layout.width >= 340) { Image($rawfile(TEN_LOGO)).width(35).height(35).accessibilityLevel('no') }
      Column({ space: 1 }) {
        Text('凑十小院').fontSize(22).minFontSize(13).maxFontSize(22).maxLines(1).width('100%')
          .fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        Text('凑成十 · 借一阵风').fontSize(10).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      TenIconButton({ dark: this.dark, icon: this.soundEnabled ? 'sound' : 'muted',
        label: this.soundEnabled ? '关闭音效' : '开启音效', action: () => this.updateSound(!this.soundEnabled) })
      TenIconButton({ dark: this.dark, icon: 'pause', label: '暂停', primary: true, action: () => this.present('pause') })
    }.width('100%').height(52)
  }
  @Builder
  PlayArea() {
    // These nodes survive rotation and multi-hinge changes; the engine never resets on resize.
    Stack({ alignContent: Alignment.TopStart }) {
      TenStats({ dark: this.dark, stage: this.round.stage, collected: this.round.history.length, goal: this.goal })
        .width(this.layout.stats.width).position({ x: this.layout.stats.x, y: this.layout.stats.y })
      TenBoard({ dark: this.dark, gridSize: this.gridSize, grid: this.layout.grid, cell: this.layout.cell,
        gap: this.layout.tileGap, pad: this.layout.pad, windDirection: this.windDirection, tiles: $tiles,
        selected: this.selected, hintCells: this.hintCells, active: this.active(), sceneId: this.round.id,
        tap: (index: number) => this.tap(index), touch: (event: TouchEvent) => this.touch(event)
      }).position({ x: this.layout.board.x, y: this.layout.board.y })
      TenSelection({ dark: this.dark, wide: this.layout.wide,
        sum: this.animating && this.receipt.length > 0 ? 10 : tenSum(this.round.board, this.selected),
        formula: this.animating && this.receipt.length > 0 ? this.receipt :
          this.selected.map((i: number): string => '' + this.round.board[i]).join(' + '),
        collected: this.animating && this.receipt.length > 0, hasHint: this.hintCells.length > 0,
        clear: () => this.setSelection([])
      }).width(this.layout.selection.width).position({ x: this.layout.selection.x, y: this.layout.selection.y })
      TenTools({ dark: this.dark, wide: this.layout.wide, canUndo: this.round.history.length > 0, active: this.active(),
        undo: () => this.undo(), hint: () => this.hint(), more: () => this.present('more')
      }).width(this.layout.tools.width).position({ x: this.layout.tools.x, y: this.layout.tools.y })
      this.Note()
    }.width(this.layout.contentWidth).height(this.layout.contentHeight)
  }
  @Builder
  Note() {
    Column({ space: 6 }) {
      if (this.layout.wide && this.layout.note.height >= 126) {
        Image($rawfile(P.scene('mascot', this.dark))).width(104).height(80).objectFit(ImageFit.Contain).accessibilityLevel('no')
      }
      if (this.saveFailed) {
        Button({ type: ButtonType.Normal }) {
          Text('进度暂未存好 · 点此重试').fontSize(11).fontColor(P.danger(this.dark))
        }.height(28).padding(0).backgroundColor(Color.Transparent).onClick(() => this.retrySave())
      } else {
        Text(this.round.stage === 1 ? '先试试 2 + 8，凑满就会自动收下' : '点选或连线，凑满 10 自动收下')
          .fontSize(this.layout.wide ? 13 : 11).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
      }
      if (this.layout.wide) {
        Text('已收好 ' + tenProfile(this.round).totalWins + ' 盘小院 · 不限时间')
          .fontSize(11).fontColor(P.gold(this.dark))
      }
    }.width(this.layout.note.width).height(this.layout.note.height).justifyContent(FlexAlign.Center)
      .position({ x: this.layout.note.x, y: this.layout.note.y })
  }
  private active(): boolean {
    return this.loaded && !this.disposed && !this.saving && !this.animating && this.dialog.length === 0 &&
      !this.backgroundPaused && !this.gestureCommitted && this.round.phase === 'playing';
  }
  private async boot(): Promise<void> {
    if (this.loading || this.context === undefined) return;
    this.loading = true; this.dialog = 'loading';
    try {
      const raw = await this.storage.load(this.context);
      if (this.disposed) return;
      if (raw.length > 0 && !this.engine.restore(raw)) { this.dialog = 'corrupt'; return; }
      this.loaded = true; this.sync(); this.relayout();
      this.dialog = this.backgroundPaused ? 'pause' : this.round.phase === 'complete' ? 'complete' : raw.length > 0 ? 'resume' : 'intro';
      this.save();
    } catch (_) { if (!this.disposed) this.dialog = 'loadError'; }
    finally { this.loading = false; }
  }
  private setSelection(path: number[]): void {
    if (tenEqual(this.selected, path)) return;
    const changed = path.length > this.selected.length;
    this.selected = path;
    if (changed) this.audio.play('select');
  }
  private tap(index: number): void {
    if (!this.active()) return;
    this.setSelection(tenSelect(this.round.board, this.selected, index, this.gridSize));
    this.collectIfReady();
  }
  private collectIfReady(): void {
    if (tenSum(this.round.board, this.selected) === 10) this.collect();
  }
  private touch(event: TouchEvent): void {
    if (event.type === TouchType.Cancel || event.touches.length > 1) { this.cancelGesture(); return; }
    // Consume the remainder of this physical gesture, even after the animation ends.
    // A held finger must never start another group or scroll the board after collecting.
    if (this.gestureCommitted) {
      if (event.type === TouchType.Up) this.cancelGesture();
      return;
    }
    if (!this.active()) { this.cancelGesture(); return; }
    const points = event.touches.length > 0 ? event.touches : event.changedTouches;
    if (points.length === 0) { this.cancelGesture(); return; }
    const point = points[0];
    if (event.type === TouchType.Down) {
      this.pointer = point.id; this.touching = true;
      this.pointerInput.begin(point.x, point.y, this.selected, this.gridSize, this.layout.grid, this.layout.tileGap);
    } else if (point.id === this.pointer) {
      if (event.type === TouchType.Move) {
        this.setSelection(this.pointerInput.move(point.x, point.y, this.round.board, this.gridSize, this.layout.grid, this.layout.tileGap));
        this.collectIfReady();
      } else if (event.type === TouchType.Up) {
        const result = this.pointerInput.end(point.x, point.y, this.round.board, this.gridSize, this.layout.grid, this.layout.tileGap);
        this.pointer = -1; this.touching = false; this.setSelection(result.path);
        this.collectIfReady();
      }
    }
  }
  private cancelGesture(): void {
    if (this.pointer >= 0) {
      const before = this.pointerInput.cancel();
      if (!this.gestureCommitted) this.selected = before;
    }
    this.pointer = -1; this.touching = false; this.gestureCommitted = false;
  }
  private collect(): void {
    if (!this.active()) return;
    const formula = this.selected.map((i: number): string => '' + this.round.board[i]).join(' + ');
    if (!this.engine.submit(this.selected)) return;
    this.gestureCommitted = this.pointer >= 0;
    this.receipt = formula; this.selected = []; this.hintCells = [];
    this.audio.play(this.engine.round.phase === 'complete' ? 'complete' : 'collect');
    this.animateBoard(); this.save();
  }
  private undo(): void {
    if (!this.active() || !this.engine.rewind()) return;
    this.cancelGesture(); this.selected = []; this.hintCells = []; this.receipt = '';
    this.audio.play('undo'); this.animateBoard(); this.save();
  }
  private hint(): void {
    if (!this.active()) return;
    const hint = this.engine.hint();
    if (hint === undefined) return;
    this.pendingHint = hint;
    if (hint.rewind > 0) { this.rewind = hint.rewind; this.present('hintRewind'); }
    else this.showHint();
  }
  private showHint(): void {
    if (this.pendingHint === undefined || !this.engine.applyHint(this.pendingHint)) return;
    // A hint is a visual route, not a filled selection. The player's own taps/drag
    // still perform the move, using the same auto-collect rule as any other path.
    this.hintCells = this.pendingHint.path.slice(); this.selected = []; this.pendingHint = undefined;
    this.dialog = this.backgroundPaused ? 'pause' : ''; this.returnDialog = '';
    this.sync(); this.audio.play('tap'); this.save();
  }
  private sync(): void {
    this.round = this.engine.snapshot().round;
    this.tiles = tenReconcileTiles(this.tiles, this.engine.tiles());
    this.gridSize = this.engine.puzzle.size; this.goal = this.engine.puzzle.solution.length; this.windDirection = this.engine.direction();
  }
  private cancelAnimation(): void {
    this.generation += 1;
    if (this.timer !== -1) clearTimeout(this.timer);
    this.timer = -1; this.animating = false;
  }
  private animateBoard(): void {
    this.cancelAnimation(); this.animating = true;
    this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut }, () => this.sync());
    const token = this.generation;
    this.timer = setTimeout(() => {
      if (this.disposed || token !== this.generation) return;
      this.timer = -1; this.animating = false;
      if (this.dialog.length === 0 && this.engine.round.phase === 'complete') this.dialog = 'complete';
    }, 190);
  }
  private async advance(): Promise<void> {
    if (this.disposed || this.saving || this.engine.round.phase !== 'complete') return;
    this.saving = true;
    const accepted = await this.save();
    if (this.disposed) return;
    this.saving = false;
    if (!accepted || this.backgroundPaused || !this.engine.next()) return;
    this.cancelGesture(); this.selected = []; this.hintCells = []; this.receipt = ''; this.returnDialog = ''; this.dialog = '';
    this.sync(); this.relayout(true); this.audio.play('wind'); this.save();
  }
  private present(mode: string): void {
    if (!this.loaded || this.saving) return;
    this.cancelGesture(); this.cancelAnimation(); this.audio.silence();
    this.returnDialog = this.dialog; this.dialog = mode; this.save();
  }
  private closeDialog(): void {
    if (!this.loaded || this.saving) return;
    if (this.dialog === 'pause' || this.dialog === 'resume') {
      this.backgroundPaused = false; this.returnDialog = '';
    }
    this.dialog = this.backgroundPaused ? 'pause' : this.round.phase === 'complete' ? 'complete' : this.returnDialog;
    this.returnDialog = '';
  }
  private confirmDialog(): void {
    if (this.saving) return;
    if (this.dialog === 'complete') { this.advance(); return; }
    if (this.dialog === 'hintRewind') { this.showHint(); return; }
    const replacing = this.dialog === 'corrupt';
    if (replacing) { this.engine = new TenEngine(); this.loaded = true; }
    else if (!this.engine.restart()) return;
    // The progress bridge must reference the same engine when replacing a corrupt save.
    if (replacing && this.context !== undefined) {
      const context = this.context;
      this.progress = new TenProgress(this.engine, {
        save: (raw: string): Promise<boolean> => this.storage.save(context, raw),
        report: (event: AchievementEvent): Promise<boolean> => this.reportAchievementEvent(event),
        record: (boards: number): void => this.recordScore(boards)
      });
    }
    this.cancelGesture(); this.selected = []; this.hintCells = []; this.receipt = '';
    this.returnDialog = ''; this.dialog = this.backgroundPaused ? 'pause' : '';
    this.sync(); this.relayout(true); this.save();
  }
  private relayout(resetScroll: boolean = false): void {
    if (this.disposed) return;
    const next = tenLayout(this.pageWidth, this.pageHeight, this.insets, this.creases, this.engine.puzzle.size);
    if (!resetScroll && JSON.stringify(next) === JSON.stringify(this.layout)) return;
    this.cancelGesture(); this.layout = next;
    const generation = ++this.layoutGeneration;
    this.getUIContext().postFrameCallback(new TenReflow(() => {
      if (this.disposed || generation !== this.layoutGeneration) return;
      this.verticalScroll.scrollTo({ xOffset: 0, yOffset: 0, animation: false });
      this.horizontalScroll.scrollTo({ xOffset: 0, yOffset: 0, animation: false });
    }));
  }
  private backgrounded(): void {
    this.backgroundPaused = true; this.cancelGesture(); this.cancelAnimation(); this.audio.silence();
    if (this.loaded) { this.dialog = 'pause'; this.returnDialog = ''; }
    this.save();
  }
  themeChanged(): void { this.host.setDark(this.dark); }
  soundChanged(): void { this.audio.setEnabled(this.soundEnabled); }
  exitRequested(): void {
    if (this.saving) return;
    if (!this.loaded) { this.skipSave = true; this.exitToHub(); return; }
    if (['help', 'restart', 'hintRewind', 'exit'].includes(this.dialog)) this.closeDialog();
    else this.present('exit');
  }
  private async save(): Promise<boolean> {
    if (!this.loaded || this.progress === undefined || this.skipSave) return true;
    const sequence = ++this.saveSequence;
    const accepted = await this.progress.flush();
    if (!this.disposed && sequence === this.saveSequence) this.saveFailed = !accepted;
    return accepted;
  }
  private async retrySave(): Promise<void> {
    if (this.saving) return;
    this.saving = true; await this.save();
    if (!this.disposed) this.saving = false;
  }
  private async saveAndExit(): Promise<void> {
    if (this.saving) return;
    this.cancelGesture(); this.cancelAnimation(); this.audio.silence(); this.saving = true;
    const accepted = await this.save();
    if (this.disposed) return;
    this.saving = false;
    if (accepted) { this.skipSave = true; this.exitToHub(); } else this.dialog = 'exit';
  }
}
