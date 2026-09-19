import { common } from '@kit.AbilityKit';
import { AchievementEvent } from '../../shell/AchievementModule';
import { StarAudio } from './StarAudio';
import { StarBoard } from './StarBoard';
import { StarButton, StarIconButton, StarStats } from './StarControls';
import { StarDialog } from './StarDialog';
import { StarEngine } from './StarEngine';
import { StarCrease, StarInsets, StarLayout, starLayout } from './StarLayout';
import { STAR_LOGO, StarMode, StarStatus, StarTile, starBonus, starGain } from './StarModel';
import { StarPalette as P } from './StarPalette';
import { StarPerf } from './StarPerf';
import { StarPreparation } from './StarPreparation';
import { StarProgress } from './StarProgress';
import { starGravityTiles, starGroup, starGroups, starRemaining, starTiles } from './StarRules';
import { StarStorage } from './StarStorage';
import { StarWindow } from './StarWindow';

@Component
export struct StarPage {
  @Prop @Watch('themeChanged') dark: boolean = false;
  @Prop @Watch('soundChanged') soundEnabled: boolean = true;
  @Prop @Watch('exitRequested') exitRequest: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  reportAchievementEvent: (event: AchievementEvent) => Promise<boolean> = async () => false;

  private engine: StarEngine = new StarEngine();
  private audio: StarAudio = new StarAudio();
  private storage: StarStorage = new StarStorage();
  private host: StarWindow = new StarWindow();
  private preparation: StarPreparation = new StarPreparation();
  private perf: StarPerf = new StarPerf();
  private progress: StarProgress | undefined = undefined;
  private context: common.Context | undefined = undefined;
  private loaded: boolean = false;
  private loading: boolean = false;
  private disposed: boolean = false;
  private skipSave: boolean = false;
  private backgroundPaused: boolean = false;
  private animationToken: number = 0;
  private animationTimer: number = -1;
  private saveSequence: number = 0;
  private insets: StarInsets = { top: 24, bottom: 16, left: 0, right: 0 };
  private creases: StarCrease[] = [];
  private scroller: Scroller = new Scroller();

  @State pageWidth: number = 390;
  @State pageHeight: number = 844;
  @State layout: StarLayout = starLayout(390, 844, { top: 24, bottom: 16, left: 0, right: 0 });
  @State tiles: StarTile[] = [];
  @State selected: number[] = [];
  @State groupCounts: number[] = [];
  @State clearing: number[] = [];
  @State clearScale: number = 1;
  @State busy: boolean = false;
  @State gain: number = 0;
  @State roundKey: string = '';
  @State mode: StarMode = 'easy';
  @State pendingMode: StarMode = 'easy';
  @State status: StarStatus = 'playing';
  @State stage: number = 1;
  @State score: number = 0;
  @State stageScore: number = 0;
  @State target: number = 1000;
  @State best: number = 0;
  @State remaining: number = 80;
  @State bonus: number = 0;
  @State undoAvailable: boolean = false;
  @State reached: boolean = false;
  @State hint: string = '点相邻同色 · 凑大组，得分更多';
  @State dialog: string = 'loading';
  @State saving: boolean = false;
  @State saveFailed: boolean = false;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.Context;
    this.context = context;
    if (context === undefined) { this.dialog = 'loadError'; return; }
    this.progress = new StarProgress(this.engine, {
      save: (raw: string): Promise<boolean> => this.storage.save(context, raw),
      report: (event: AchievementEvent): Promise<boolean> => this.reportAchievementEvent(event),
      record: (score: number): void => this.recordScore(score)
    });
    this.audio.setEnabled(this.soundEnabled); this.audio.init(context);
    this.host.setDark(this.dark);
    this.host.attach(context, (px: number): number => this.getUIContext().px2vp(px),
      (insets: StarInsets, creases: StarCrease[]) => {
        this.insets = insets; this.creases = creases; this.relayout();
      }, () => this.backgrounded());
    this.boot();
  }

  aboutToDisappear(): void {
    this.finishMotion(); this.preparation.cancel(); this.disposed = true;
    if (!this.skipSave) this.save();
    this.host.release(); this.audio.release();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(P.scene('sprigs', this.dark))).width(Math.min(480, this.pageWidth)).height(Math.min(480, this.pageWidth))
        .position({ x: Math.max(0, this.pageWidth - 480), y: Math.max(0, this.pageHeight - 440) })
        .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      Column({ space: 8 }) {
        this.Header()
        if (this.layout.small) {
          this.SmallSpace()
        } else {
          Scroll(this.scroller) {
            this.PlayArea()
          }.width('100%').height(this.layout.body).scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Auto).align(Alignment.TopStart)
        }
      }.width(this.layout.width).height(this.layout.height).clip(true)
      .padding({ left: this.layout.gap, right: this.layout.gap, top: 4, bottom: 2 })
      .position({ x: this.layout.x, y: this.layout.y })
      .enabled(this.dialog.length === 0)
      .accessibilityLevel(this.dialog.length === 0 ? 'auto' : 'no-hide-descendants')
      if (this.dialog.length > 0) {
        StarDialog({ dark: this.dark, mode: this.dialog, roundMode: this.mode, pendingMode: this.pendingMode,
          stage: this.stage, score: this.stageScore, total: this.score + (this.status === 'playing' && this.dialog === 'stageEnd' ? starBonus(this.remaining) : 0),
          target: this.target, remaining: this.remaining, bonus: this.status === 'playing' ? starBonus(this.remaining) : this.bonus,
          undoAvailable: this.undoAvailable, canContinue: this.status === 'playing', saving: this.saving, saveFailed: this.saveFailed,
          panelWidth: Math.min(410, Math.max(1, this.layout.width - 20)), panelHeight: Math.max(40, this.layout.height - 20),
          action: (name: string) => this.dialogAction(name)
        }).width(this.layout.width).height(this.layout.height).position({ x: this.layout.x, y: this.layout.y })
      }
    }.width('100%').height('100%').backgroundColor(P.bg(this.dark))
    .onAreaChange((_old: Area, area: Area) => {
      this.pageWidth = Number(area.width); this.pageHeight = Number(area.height);
      this.host.measure(); this.relayout();
    })
  }

  @Builder
  Header() {
    Row({ space: 8 }) {
      StarIconButton({ dark: this.dark, icon: 'back', label: '保存并返回大厅', action: () => this.exitRequested() })
      if (this.layout.width >= 340) {
        Image($rawfile(STAR_LOGO)).width(35).height(35).accessibilityLevel('no')
      }
      Column({ space: 2 }) {
        Text('消灭星星').fontSize(23).minFontSize(14).maxFontSize(23).maxLines(1).width('100%')
          .fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        Text('星星小院 · 收集一点小欢喜').fontSize(10).minFontSize(8).maxFontSize(10).maxLines(1)
          .fontColor(P.muted(this.dark)).width('100%')
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      StarIconButton({ dark: this.dark, icon: this.soundEnabled ? 'sound' : 'muted',
        label: this.soundEnabled ? '关闭音效' : '开启音效', action: () => this.updateSound(!this.soundEnabled) })
    }.width('100%').height(52)
  }

  @Builder
  PlayArea() {
    Stack({ alignContent: Alignment.TopStart }) {
      StarStats({ dark: this.dark, mode: this.mode, stage: this.stage, score: this.score, stageScore: this.stageScore + this.bonus,
        target: this.target, best: this.best, panelHeight: this.layout.stats.height })
        .width(this.layout.stats.width).position({ x: this.layout.stats.x, y: this.layout.stats.y })
      StarBoard({ dark: this.dark, tiles: this.tiles, selected: this.selected, groupCounts: this.groupCounts, clearing: this.clearing,
        clearScale: this.clearScale, boardWidth: this.layout.board.width, boardHeight: this.layout.board.height,
        cell: this.layout.cell, gap: this.layout.tileGap, inset: this.layout.tilePad, roundKey: this.roundKey, gain: this.gain,
        active: this.loaded && !this.busy && !this.saving && this.status === 'playing',
        tap: (id: number) => this.tap(id), preview: (id: number) => this.preview(id), cancelPreview: () => this.clearPreview()
      }).position({ x: this.layout.board.x, y: this.layout.board.y })
      this.Note()
      if (this.layout.wide) {
        Column({ space: 8 }) {
          StarButton({ dark: this.dark, label: '撤销上一步', icon: 'undo', active: this.undoAvailable && !this.busy && !this.saving,
            controlHeight: 60, action: () => this.undo() })
          StarButton({ dark: this.dark, label: '找一组星星', icon: 'hint', active: this.status === 'playing' && !this.busy && !this.saving,
            controlHeight: 60, action: () => this.showHint() })
          StarButton({ dark: this.dark, label: '玩法与更多', icon: 'more', controlHeight: 60, action: () => this.present('more') })
        }.width(this.layout.tools.width).height(this.layout.tools.height)
          .position({ x: this.layout.tools.x, y: this.layout.tools.y })
      } else {
        Row({ space: 8 }) {
          StarButton({ dark: this.dark, label: '撤销', icon: 'undo', active: this.undoAvailable && !this.busy && !this.saving,
            action: () => this.undo() }).layoutWeight(1)
          StarButton({ dark: this.dark, label: '提示', icon: 'hint', active: this.status === 'playing' && !this.busy && !this.saving,
            action: () => this.showHint() }).layoutWeight(1)
          StarButton({ dark: this.dark, label: '更多', icon: 'more', action: () => this.present('more') }).layoutWeight(1)
        }.width(this.layout.tools.width).height(this.layout.tools.height)
          .position({ x: this.layout.tools.x, y: this.layout.tools.y })
      }
    }.width(this.layout.contentWidth).height(this.layout.contentHeight)
  }

  @Builder
  Note() {
    Column({ space: 5 }) {
      if (this.saveFailed) {
        StarButton({ dark: this.dark, label: '进度未存好 · 点此重试', icon: 'restart', controlHeight: 34,
          action: () => this.save() })
      } else if (this.reached && !this.busy) {
        StarButton({ dark: this.dark, label: '目标达成 · 前往下一关', icon: 'next', primary: true, controlHeight: 34,
          action: () => this.present('stageEnd') })
      } else if (this.status === 'failed' || this.status === 'finished') {
        StarButton({ dark: this.dark, label: '查看本局收获', icon: 'trophy', controlHeight: 34,
          action: () => this.present(this.status) })
      } else {
        Text(this.hint).fontSize(12).minFontSize(10).maxFontSize(12).maxLines(2).textAlign(TextAlign.Center)
          .fontColor(this.selected.length >= 2 ? P.accent(this.dark) : P.muted(this.dark))
      }
      if (this.layout.wide) {
        Row({ space: 5 }) {
          Image($rawfile(P.icon('leaf', this.dark, 'accent'))).width(13).height(13).accessibilityLevel('no')
          Text('不赶时间，慢慢收集').fontSize(11).fontColor(P.muted(this.dark))
        }.justifyContent(FlexAlign.Center)
      }
    }.width(this.layout.note.width).height(this.layout.note.height).justifyContent(FlexAlign.Center)
      .position({ x: this.layout.note.x, y: this.layout.note.y })
  }

  @Builder
  SmallSpace() {
    Scroll() {
      Column({ space: 16 }) {
        Image($rawfile(P.icon('expand', this.dark, 'accent'))).width(40).height(40)
        Text('给星星多一点空间').fontSize(19).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
        Text('展开屏幕、转动设备或放大窗口，\n就能继续这盘。进度会为你保留。')
          .fontSize(13).lineHeight(22).textAlign(TextAlign.Center).fontColor(P.muted(this.dark))
        StarButton({ dark: this.dark, label: '保存并返回大厅', icon: 'back', action: () => this.present('exit') })
      }.width('100%').padding({ top: 20, bottom: 20 })
    }.width('100%').height(this.layout.body)
  }

  private async boot(): Promise<void> {
    if (this.loading || this.context === undefined || this.disposed) return;
    this.loading = true; this.dialog = 'loading';
    try {
      const raw = await this.storage.load(this.context);
      if (this.disposed) return;
      if (raw.length > 0 && !this.engine.restore(raw)) { this.dialog = 'corrupt'; return; }
      if (raw.length === 0 && !this.backgroundPaused) {
        const puzzle = await this.preparation.prepare('easy', this.seed());
        if (this.disposed) return;
        if (puzzle !== undefined) this.engine.start('easy', puzzle);
      }
      this.loaded = true; this.sync(); this.pendingMode = this.mode;
      this.dialog = this.status !== 'playing' ? this.status : this.backgroundPaused ? 'more' : '';
      this.save();
    } catch (_) { if (!this.disposed) this.dialog = 'loadError'; }
    finally { this.loading = false; }
  }

  private seed(): number { return (Date.now() ^ Math.floor(Math.random() * 4294967296)) >>> 0; }
  private canPlay(): boolean {
    return this.loaded && !this.disposed && !this.busy && !this.saving && !this.layout.small && this.dialog.length === 0 && this.status === 'playing';
  }
  private preview(id: number): void {
    if (!this.canPlay()) return;
    const cell = this.engine.round.ids.indexOf(id);
    const group = starGroup(this.engine.round.cells, cell);
    this.selected = group.map((cell: number): number => this.engine.round.ids[cell]);
    this.hint = group.length >= 2 ? group.length + ' 块相连 · +' + starGain(group.length) + ' 分' : '这块还落单着 · 试试相邻的同色';
  }
  private clearPreview(): void { this.selected = []; this.hint = '点相邻同色 · 凑大组，得分更多'; }
  private tap(id: number): void {
    if (!this.canPlay()) return;
    const start = Date.now();
    const move = this.engine.pop(this.engine.round.ids.indexOf(id));
    if (move === undefined) { this.preview(id); return; }
    this.perf.logMove(Date.now() - start, move.removedIds.length, starRemaining(move.cells));
    this.busy = true; this.selected = []; this.clearing = move.removedIds.slice(); this.clearScale = 1;
    this.gain = move.gain; this.hint = '收下 ' + move.removedIds.length + ' 块小欢喜 · +' + move.gain;
    this.syncCounters(); this.save(); this.audio.play(move.removedIds.length >= 8 ? 'burst' : 'pop');
    const finalTiles = starTiles(move.cells, move.ids);
    const fallingTiles = starGravityTiles(this.tiles, finalTiles);
    const shifts = fallingTiles.some((tile: StarTile, index: number): boolean => tile.cell !== finalTiles[index].cell);
    this.animationToken++;
    this.getUIContext().animateTo({ duration: 110, curve: Curve.EaseIn }, () => { this.clearScale = .03; });
    this.later(115, () => {
      this.getUIContext().animateTo({ duration: shifts ? 100 : 190, curve: Curve.EaseOut }, () => {
        this.tiles = shifts ? fallingTiles : finalTiles;
      });
      this.clearing = []; this.clearScale = 1;
      this.later(shifts ? 105 : 195, () => {
        if (shifts) {
          this.getUIContext().animateTo({ duration: 90, curve: Curve.EaseOut }, () => { this.tiles = finalTiles; });
          this.later(95, () => this.completeTurn());
        } else this.completeTurn();
      });
    });
  }
  private completeTurn(): void {
    const ended = this.status !== 'playing';
    this.finishMotion();
    if (ended) this.audio.play(this.status === 'stageEnd' ? 'win' : 'end');
  }
  private later(delay: number, action: () => void): void {
    const token = this.animationToken;
    this.animationTimer = setTimeout(() => {
      if (this.disposed || token !== this.animationToken) return;
      this.animationTimer = -1; action();
    }, delay);
  }
  private finishMotion(): void {
    this.animationToken++;
    if (this.animationTimer >= 0) clearTimeout(this.animationTimer);
    this.animationTimer = -1; this.busy = false; this.clearing = []; this.clearScale = 1; this.gain = 0;
    if (this.loaded) {
      this.sync();
      if (this.status !== 'playing' && this.dialog.length === 0) this.dialog = this.status;
    }
  }
  private syncCounters(): void {
    const r = this.engine.round;
    this.mode = r.mode; this.status = r.status; this.stage = r.stage; this.score = this.engine.totalScore();
    this.stageScore = r.score; this.target = r.target; this.best = this.engine.bestScore(); this.bonus = r.bonus;
    this.remaining = starRemaining(r.cells); this.undoAvailable = this.engine.canUndo(); this.reached = this.engine.canAdvance();
    this.roundKey = r.session + ':' + r.stage;
  }
  private sync(): void {
    this.syncCounters(); this.tiles = starTiles(this.engine.round.cells, this.engine.round.ids);
    const counts: number[] = new Array<number>(80).fill(0);
    starGroups(this.engine.round.cells).forEach((group: number[]) => {
      group.forEach((cell: number) => { counts[this.engine.round.ids[cell]] = group.length; });
    });
    this.groupCounts = counts;
  }
  private undo(): void {
    if (this.saving || this.busy || !this.loaded || !this.engine.undo()) return;
    this.dialog = ''; this.clearPreview(); this.sync(); this.audio.play('undo'); this.save();
    this.hint = '回到上一步 · 本关撤销已用完';
  }
  private showHint(): void {
    if (!this.canPlay()) return;
    const group = this.engine.hint(); this.selected = group.map((cell: number): number => this.engine.round.ids[cell]);
    this.hint = '这组最大：' + group.length + ' 块 · +' + starGain(group.length) + ' 分'; this.audio.play('tap');
  }
  private present(name: string): void {
    if (!this.loaded || this.saving || this.disposed) return;
    this.finishMotion(); this.clearPreview(); this.dialog = name;
  }
  private dialogAction(name: string): void {
    if (this.saving) return;
    if (name === 'leaveUntouched') { this.skipSave = true; this.exitToHub(); return; }
    if (name === 'retryLoad') { this.boot(); return; }
    if (name === 'retrySave') { this.save(); return; }
    if (name === 'close') { this.backgroundPaused = false; this.dialog = ''; return; }
    if (name === 'help') { this.dialog = 'help'; return; }
    if (name === 'restart') { this.pendingMode = this.mode; this.dialog = 'restart'; return; }
    if (name === 'easy' || name === 'classic') {
      if (name === this.mode) return;
      this.pendingMode = name; this.dialog = 'changeMode'; return;
    }
    if (name === 'confirm') { this.replaceRound(false); return; }
    if (name === 'next') { this.replaceRound(true); return; }
    if (name === 'undo') { this.undo(); return; }
    if (name === 'finish') {
      if (this.engine.finish()) { this.sync(); this.dialog = 'finished'; this.save(); }
      return;
    }
    if (name === 'leave') this.saveAndExit();
  }
  private async replaceRound(next: boolean): Promise<void> {
    if (!this.loaded || this.saving || this.disposed || (next && !this.engine.canAdvance())) return;
    this.finishMotion(); this.saving = true;
    const previousDialog = this.dialog;
    if (!await this.save() || this.disposed || this.backgroundPaused) { this.saving = false; return; }
    this.dialog = 'loading';
    const puzzle = await this.preparation.prepare(next ? this.mode : this.pendingMode, this.seed());
    if (this.disposed) return;
    if (puzzle === undefined || this.backgroundPaused) { this.saving = false; this.dialog = 'more'; return; }
    const changed = next ? this.engine.advance(puzzle) : this.engine.start(this.pendingMode, puzzle);
    if (!changed) { this.saving = false; this.dialog = previousDialog; return; }
    this.clearPreview(); this.sync();
    await this.save();
    if (this.disposed) return;
    this.saving = false; this.dialog = this.backgroundPaused ? 'more' : '';
    if (!this.backgroundPaused) this.audio.play('settle');
    this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
  }
  private async save(): Promise<boolean> {
    if (!this.loaded || this.progress === undefined || this.skipSave) return false;
    const sequence = ++this.saveSequence;
    const ok = await this.progress.flush();
    if (!this.disposed && sequence === this.saveSequence) this.saveFailed = !ok;
    return ok;
  }
  private async saveAndExit(): Promise<void> {
    if (this.saving || !this.loaded) return;
    this.finishMotion(); this.saving = true;
    const ok = await this.save();
    if (this.disposed) return;
    this.saving = false;
    if (ok) { this.skipSave = true; this.audio.silence(); this.exitToHub(); }
    else this.dialog = 'exit';
  }
  private exitRequested(): void {
    if (this.saving) return;
    if (!this.loaded) { this.skipSave = true; this.preparation.cancel(); this.exitToHub(); return; }
    if (this.dialog === 'help' || this.dialog === 'restart' || this.dialog === 'changeMode') { this.dialog = 'more'; return; }
    this.present('exit');
  }
  private themeChanged(): void { this.host.setDark(this.dark); }
  private soundChanged(): void { this.audio.setEnabled(this.soundEnabled); }
  private backgrounded(): void {
    this.backgroundPaused = true; this.preparation.cancel(); this.finishMotion(); this.audio.silence();
    if (this.loaded) { this.dialog = this.status === 'playing' ? 'more' : this.status; this.save(); }
  }
  private relayout(): void {
    const next = starLayout(this.pageWidth, this.pageHeight, this.insets, this.creases);
    if (JSON.stringify(next) === JSON.stringify(this.layout)) return;
    this.finishMotion(); this.clearPreview(); this.layout = next;
    this.perf.layout(next.width, next.height, next.cell, next.wide);
  }
}
