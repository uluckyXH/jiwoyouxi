import { common } from '@kit.AbilityKit';
import { AchievementEvent } from '../../shell/AchievementModule';
import { StarAudio } from './StarAudio';
import { StarBoard } from './StarBoard';
import { StarButton, StarIconButton, StarStats } from './StarControls';
import { StarDialog } from './StarDialog';
import { StarEngine } from './StarEngine';
import { StarCrease, StarInsets, StarLayout, starLayout } from './StarLayout';
import { STAR_LOGO, StarMode, StarPuzzle, StarStatus, StarTile, starBonus, starGain } from './StarModel';
import { StarPalette as P } from './StarPalette';
import { StarPerf, starNow } from './StarPerf';
import { StarPreparation, StarPreparationTiming } from './StarPreparation';
import { StarProgress } from './StarProgress';
import { starGravityTiles, starGroup, starGroups, starRemaining, starTiles } from './StarRules';
import { StarStorage } from './StarStorage';
import { StarWindow } from './StarWindow';
import { StarScene, StarVisualTile } from './StarScene';

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
  private loading: boolean = false;
  private disposed: boolean = false;
  private leaving: boolean = false;
  private skipSave: boolean = false;
  private backgroundPaused: boolean = false;
  private animationToken: number = 0;
  private animationTimer: number = -1;
  private saveSequence: number = 0;
  private loadFeedbackTimer: number = -1;
  private loadFeedbackToken: number = 0;
  private insets: StarInsets = { top: 24, bottom: 16, left: 0, right: 0 };
  private creases: StarCrease[] = [];
  private scroller: Scroller = new Scroller();
  private scene: StarScene = new StarScene();
  private tiles: StarTile[] = [];
  private selected: number[] = [];

  @State pageWidth: number = 390;
  @State loaded: boolean = false;
  @State loadFeedback: string = '';
  @State pageHeight: number = 844;
  @State layout: StarLayout = starLayout(390, 844, { top: 24, bottom: 16, left: 0, right: 0 });
  @State tileViews: StarVisualTile[] = [];
  @State previewCount: number = 0;
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
  @State @Watch('dialogChanged') dialog: string = '';
  @State saving: boolean = false;
  @State saveFailed: boolean = false;

  aboutToAppear(): void {
    this.perf.event('进入页面', `主题=${this.dark ? '深' : '浅'} 音效=${this.soundEnabled}`);
    this.perf.sample('进入页面', 800);
    const context = this.getUIContext().getHostContext() as common.Context;
    this.context = context;
    if (context === undefined) { this.dialog = 'loadError'; return; }
    this.progress = new StarProgress(this.engine, {
      save: (raw: string): Promise<boolean> => this.persist(raw),
      report: (event: AchievementEvent): Promise<boolean> => this.reportProgress(event),
      record: (score: number): void => this.recordScore(score)
    });
    this.audio.setEnabled(this.soundEnabled); this.audio.init(context);
    this.host.setDark(this.dark);
    this.host.attach(context, (px: number): number => this.getUIContext().px2vp(px),
      (insets: StarInsets, creases: StarCrease[]) => {
        this.insets = insets; this.creases = creases; this.relayout();
      }, (reason: string) => this.backgrounded(reason));
    this.boot();
  }

  aboutToDisappear(): void {
    this.disposed = true; this.endLoadFeedback();
    this.finishMotion(); this.preparation.cancel();
    if (!this.skipSave) this.save();
    this.host.release(); this.audio.release();
    this.perf.release();
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
      StarBoard({ dark: this.dark, tiles: $tileViews, boardWidth: this.layout.board.width, boardHeight: this.layout.board.height,
        cell: this.layout.cell, gap: this.layout.tileGap, inset: this.layout.tilePad, roundKey: this.roundKey, gain: this.gain,
        active: this.loaded && !this.busy && !this.saving && this.status === 'playing',
        tap: (id: number) => this.tap(id), preview: (id: number) => this.preview(id), cancelPreview: () => this.clearPreview()
      }).position({ x: this.layout.board.x, y: this.layout.board.y })
      this.Note()
      if (this.layout.wide) {
        Column({ space: 8 }) {
          StarButton({ dark: this.dark, label: '撤销上一步', icon: 'undo', active: this.undoAvailable && !this.busy && !this.saving,
            controlHeight: 60, action: () => this.undo() })
          StarButton({ dark: this.dark, label: '找一组星星', icon: 'hint', active: this.loaded && this.status === 'playing' && !this.busy && !this.saving,
            controlHeight: 60, action: () => this.showHint() })
          StarButton({ dark: this.dark, label: '玩法与更多', icon: 'more', active: this.loaded, controlHeight: 60, action: () => this.present('more') })
        }.width(this.layout.tools.width).height(this.layout.tools.height)
          .position({ x: this.layout.tools.x, y: this.layout.tools.y })
      } else {
        Row({ space: 8 }) {
          StarButton({ dark: this.dark, label: '撤销', icon: 'undo', active: this.undoAvailable && !this.busy && !this.saving,
            action: () => this.undo() }).layoutWeight(1)
          StarButton({ dark: this.dark, label: '提示', icon: 'hint', active: this.loaded && this.status === 'playing' && !this.busy && !this.saving,
            action: () => this.showHint() }).layoutWeight(1)
          StarButton({ dark: this.dark, label: '更多', icon: 'more', active: this.loaded, action: () => this.present('more') }).layoutWeight(1)
        }.width(this.layout.tools.width).height(this.layout.tools.height)
          .position({ x: this.layout.tools.x, y: this.layout.tools.y })
      }
    }.width(this.layout.contentWidth).height(this.layout.contentHeight)
  }

  @Builder
  Note() {
    Column({ space: 5 }) {
      if (this.loadFeedback.length > 0) {
        Text(this.loadFeedback).fontSize(12).fontColor(P.muted(this.dark))
      } else if (this.saveFailed) {
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
          .fontColor(this.previewCount >= 2 ? P.accent(this.dark) : P.muted(this.dark))
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
    if (this.loading || this.context === undefined || this.disposed || this.leaving) return;
    const started = starNow();
    this.loading = true; this.dialog = '';
    this.beginLoadFeedback();
    try {
      const readStarted = starNow();
      const raw = await this.storage.load(this.context);
      this.perf.duration('读取存档', readStarted, `字符=${raw.length} 已离开=${this.leaving || this.disposed}`);
      if (this.disposed || this.leaving) return;
      if (raw.length > 0) {
        const restoreStarted = starNow();
        const restored = this.engine.restore(raw);
        this.perf.duration('恢复校验', restoreStarted, `成功=${restored}`);
        if (!restored) { this.dialog = 'corrupt'; return; }
      } else {
        if (this.backgroundPaused) { this.dialog = 'more'; return; }
        const puzzle = await this.preparePuzzle('easy');
        if (this.disposed || this.leaving) return;
        if (puzzle === undefined || this.backgroundPaused) { this.dialog = 'more'; return; }
        this.engine.start('easy', puzzle);
      }
      this.loaded = true; this.sync(); this.pendingMode = this.mode;
      this.dialog = this.status !== 'playing' ? this.status : this.backgroundPaused ? 'more' : '';
      this.perf.duration('进入完成', started, `来源=${raw.length > 0 ? '存档' : '新局'} 模式=${this.mode} ` +
        `关=${this.stage} 剩余=${this.remaining} 状态=${this.status} 弹窗=${this.dialog || '无'}`);
      if (!this.backgroundPaused) this.perf.sample('棋盘恢复后');
      this.save();
    } catch (_) {
      this.perf.duration('进入失败', started);
      if (!this.disposed && !this.leaving) this.dialog = 'loadError';
    } finally { this.loading = false; this.endLoadFeedback(); }
  }

  private beginLoadFeedback(): void {
    this.endLoadFeedback();
    const token = this.loadFeedbackToken;
    // Fast local restores must never mount a modal for a single frame.
    this.loadFeedbackTimer = setTimeout(() => {
      if (token !== this.loadFeedbackToken || !this.loading || this.disposed || this.leaving) return;
      this.loadFeedbackTimer = -1;
      this.loadFeedback = '正在准备星星，马上就好…';
      this.perf.event('读取等待提示');
    }, 300);
  }

  private endLoadFeedback(): void {
    this.loadFeedbackToken++;
    if (this.loadFeedbackTimer >= 0) clearTimeout(this.loadFeedbackTimer);
    this.loadFeedbackTimer = -1;
    this.loadFeedback = '';
  }

  private preparePuzzle(mode: StarMode): Promise<StarPuzzle | undefined> {
    return this.preparation.prepare(mode, this.seed(), (timing: StarPreparationTiming): void => {
      this.perf.event('生成棋盘', `模式=${mode} 总等待=${timing.elapsed.toFixed(2)}ms 切片=${timing.slices} ` +
        `计算合计=${timing.compute.toFixed(2)}ms 切片峰值=${timing.peak.toFixed(2)}ms ` +
        `校验=${timing.verification.toFixed(2)}ms 取消=${timing.cancelled} 备用=${timing.fallback}`);
    });
  }

  private seed(): number { return (Date.now() ^ Math.floor(Math.random() * 4294967296)) >>> 0; }
  private canPlay(): boolean {
    return this.loaded && !this.disposed && !this.leaving && !this.busy && !this.saving && !this.layout.small && this.dialog.length === 0 && this.status === 'playing';
  }
  private preview(id: number): void {
    if (!this.canPlay()) return;
    const started = starNow();
    const cell = this.engine.round.ids.indexOf(id);
    const group = starGroup(this.engine.round.cells, cell);
    this.selected = group.map((cell: number): number => this.engine.round.ids[cell]);
    this.scene.select(this.selected); this.previewCount = this.selected.length;
    this.hint = group.length >= 2 ? group.length + ' 块相连 · +' + starGain(group.length) + ' 分' : '这块还落单着 · 试试相邻的同色';
    this.perf.duration('按下预览', started, `连块=${group.length}`, 8);
  }
  private clearPreview(): void {
    this.selected = []; this.previewCount = 0; this.scene.select([]);
    this.hint = '点相邻同色 · 凑大组，得分更多';
  }
  private tap(id: number): void {
    if (!this.canPlay()) {
      this.perf.inputBlocked(`动画=${this.busy} 保存=${this.saving} 载入=${!this.loaded} 弹窗=${this.dialog || '无'} 状态=${this.status}`);
      return;
    }
    const start = starNow();
    const move = this.engine.pop(this.engine.round.ids.indexOf(id));
    const logic = starNow() - start;
    if (move === undefined) { this.preview(id); return; }
    const stateStarted = starNow();
    this.busy = true; this.selected = []; this.previewCount = 0; this.scene.select([]);
    this.gain = move.gain; this.hint = '收下 ' + move.removedIds.length + ' 块小欢喜 · +' + move.gain;
    this.syncCounters();
    const stateMs = starNow() - stateStarted;
    const saveStarted = starNow(); this.save(); const saveMs = starNow() - saveStarted;
    const audioStarted = starNow(); this.audio.play(move.removedIds.length >= 8 ? 'burst' : 'pop');
    const audioMs = starNow() - audioStarted;
    const prepareStarted = starNow();
    const finalTiles = starTiles(move.cells, move.ids);
    const fallingTiles = starGravityTiles(this.tiles, finalTiles);
    const shifts = fallingTiles.some((tile: StarTile, index: number): boolean => tile.cell !== finalTiles[index].cell);
    const prepareMs = starNow() - prepareStarted;
    this.animationToken++;
    const animationStarted = starNow();
    this.getUIContext().animateTo({ duration: 110, curve: Curve.EaseIn }, () => { this.scene.shrink(move.removedIds); });
    const animationMs = starNow() - animationStarted;
    this.later(115, () => {
      const fallingStarted = starNow();
      this.scene.hide(move.removedIds);
      this.tiles = shifts ? fallingTiles : finalTiles;
      let moved = 0;
      this.getUIContext().animateTo({ duration: shifts ? 100 : 190, curve: Curve.EaseOut }, () => {
        moved = this.scene.place(this.tiles);
      });
      this.perf.duration('下落提交', fallingStarted, `移动节点=${moved}`, 8);
      this.later(shifts ? 105 : 195, () => {
        if (shifts) {
          const shiftStarted = starNow();
          this.tiles = finalTiles;
          this.getUIContext().animateTo({ duration: 90, curve: Curve.EaseOut }, () => { moved = this.scene.place(finalTiles); });
          this.perf.duration('左靠提交', shiftStarted, `移动节点=${moved}`, 8);
          this.later(95, () => this.completeTurn());
        } else this.completeTurn();
      });
    });
    this.perf.move({ logic: logic, state: stateMs, save: saveMs, audio: audioMs, prepare: prepareMs,
      animation: animationMs, total: starNow() - start, group: move.removedIds.length,
      remaining: starRemaining(move.cells), shifts: shifts });
    this.perf.sample('消除·第' + this.stage + '关·' + this.engine.round.stageMoves + '步');
  }
  private completeTurn(): void {
    const ended = this.status !== 'playing';
    this.finishMotion();
    if (ended) this.audio.play(this.status === 'stageEnd' ? 'win' : 'end');
  }
  private later(delay: number, action: () => void): void {
    const token = this.animationToken;
    const started = starNow();
    this.animationTimer = setTimeout(() => {
      if (this.disposed || this.leaving || token !== this.animationToken) return;
      this.perf.animationDelay(started, delay);
      this.animationTimer = -1; action();
    }, delay);
  }
  private finishMotion(): void {
    this.animationToken++;
    if (this.animationTimer >= 0) clearTimeout(this.animationTimer);
    this.animationTimer = -1; this.busy = false; this.gain = 0;
    if (this.loaded) {
      this.sync();
      if (!this.disposed && !this.leaving && this.status !== 'playing' && this.dialog.length === 0) this.dialog = this.status;
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
    const started = starNow();
    this.syncCounters(); this.tiles = starTiles(this.engine.round.cells, this.engine.round.ids);
    const counts: number[] = new Array<number>(80).fill(0);
    starGroups(this.engine.round.cells).forEach((group: number[]) => {
      group.forEach((cell: number) => { counts[this.engine.round.ids[cell]] = group.length; });
    });
    if (this.scene.restore(this.roundKey, this.tiles, counts)) this.tileViews = this.scene.tiles;
    this.perf.duration('棋盘状态提交', started, `剩余=${this.tiles.length}`, 8);
  }
  private undo(): void {
    if (this.saving || this.busy || !this.loaded || !this.engine.undo()) return;
    this.dialog = ''; this.clearPreview(); this.sync(); this.audio.play('undo'); this.save();
    this.hint = '回到上一步 · 本关撤销已用完';
    this.perf.sample('撤销');
  }
  private showHint(): void {
    if (!this.canPlay()) return;
    const started = starNow();
    const group = this.engine.hint(); this.selected = group.map((cell: number): number => this.engine.round.ids[cell]);
    this.scene.select(this.selected); this.previewCount = this.selected.length;
    this.hint = '这组最大：' + group.length + ' 块 · +' + starGain(group.length) + ' 分'; this.audio.play('tap');
    this.perf.duration('提示计算及提交', started, `连块=${group.length}`);
  }
  private present(name: string): void {
    if (!this.loaded || this.saving || this.disposed || this.leaving) return;
    this.finishMotion(); this.clearPreview(); this.dialog = name;
  }
  private dialogAction(name: string): void {
    if (this.saving || this.leaving || this.disposed) return;
    if (name === 'leaveUntouched') { this.leavePage(); return; }
    if (name === 'retryLoad') { this.boot(); return; }
    if (name === 'retrySave') { this.save(); return; }
    if (name === 'close') {
      this.backgroundPaused = false; this.dialog = '';
      if (!this.loaded) this.boot();
      return;
    }
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
    const puzzle = await this.preparePuzzle(next ? this.mode : this.pendingMode);
    if (this.disposed) return;
    if (puzzle === undefined || this.backgroundPaused) { this.saving = false; this.dialog = 'more'; return; }
    const changed = next ? this.engine.advance(puzzle) : this.engine.start(this.pendingMode, puzzle);
    if (!changed) { this.saving = false; this.dialog = previousDialog; return; }
    this.clearPreview(); this.sync();
    await this.save();
    if (this.disposed) return;
    this.saving = false; this.dialog = this.backgroundPaused ? 'more' : '';
    if (!this.backgroundPaused) this.audio.play('settle');
    if (!this.backgroundPaused) this.perf.sample('下一盘');
    this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
  }
  private async save(): Promise<boolean> {
    if (!this.loaded || this.progress === undefined || this.skipSave) return false;
    const sequence = ++this.saveSequence;
    const started = starNow();
    const ok = await this.progress.flush();
    this.perf.saved(started, ok, this.engine.pending.length);
    if (!this.disposed && sequence === this.saveSequence) this.saveFailed = !ok;
    return ok;
  }
  private async persist(raw: string): Promise<boolean> {
    if (this.context === undefined) return false;
    const started = starNow();
    const ok = await this.storage.save(this.context, raw);
    this.perf.duration('写入存档', started, `成功=${ok} 字符=${raw.length}`, ok ? 32 : 0);
    return ok;
  }
  private async reportProgress(event: AchievementEvent): Promise<boolean> {
    const started = starNow();
    const ok = await this.reportAchievementEvent(event);
    this.perf.duration('成就上报', started, `成功=${ok} 类型=${event.type}`, ok ? 32 : 0);
    return ok;
  }
  private async saveAndExit(): Promise<void> {
    if (this.saving || !this.loaded) return;
    this.finishMotion(); this.saving = true;
    const ok = await this.save();
    if (this.disposed) return;
    this.saving = false;
    if (ok) this.leavePage();
    else this.dialog = 'exit';
  }
  private leavePage(): void {
    this.leaving = true; this.skipSave = true;
    this.endLoadFeedback(); this.preparation.cancel(); this.finishMotion();
    this.audio.silence(); this.perf.stopSample('返回大厅');
    this.perf.event('返回大厅', `关=${this.stage} 剩余=${this.remaining} 已加载=${this.loaded}`);
    this.exitToHub();
  }
  private exitRequested(): void {
    if (this.saving || this.leaving || this.disposed) return;
    if (!this.loaded) { this.leavePage(); return; }
    if (this.dialog === 'help' || this.dialog === 'restart' || this.dialog === 'changeMode') { this.dialog = 'more'; return; }
    this.present('exit');
  }
  private dialogChanged(): void {
    this.perf.event('弹窗变化', `弹窗=${this.dialog || '无'} 已加载=${this.loaded} 后台=${this.backgroundPaused}`);
  }
  private themeChanged(): void {
    this.host.setDark(this.dark); this.perf.event('主题变化', this.dark ? '深色' : '浅色');
    if (!this.backgroundPaused && !this.leaving) this.perf.sample('主题切换');
  }
  private soundChanged(): void {
    this.audio.setEnabled(this.soundEnabled); this.perf.event('音效开关', `开启=${this.soundEnabled}`);
  }
  private backgrounded(reason: string = '窗口后台'): void {
    if (this.disposed || this.leaving) return;
    this.perf.event('后台暂停', `来源=${reason} 弹窗=${this.dialog || '无'} 动画=${this.busy}`);
    this.perf.stopSample('后台');
    this.endLoadFeedback();
    this.backgroundPaused = true; this.preparation.cancel(); this.finishMotion(); this.audio.silence();
    if (this.loaded) { this.dialog = this.status === 'playing' ? 'more' : this.status; this.save(); }
  }
  private relayout(): void {
    if (this.disposed || this.leaving) return;
    const started = starNow();
    const next = starLayout(this.pageWidth, this.pageHeight, this.insets, this.creases);
    if (JSON.stringify(next) === JSON.stringify(this.layout)) return;
    this.finishMotion(); this.clearPreview(); this.layout = next;
    this.perf.layout(next.width, next.height, next.cell, next.wide,
      `窗口=${this.pageWidth.toFixed(1)}×${this.pageHeight.toFixed(1)}vp 折痕=${this.creases.length} ` +
      `小窗=${next.small} 耗时=${(starNow() - started).toFixed(2)}ms`);
    if (!this.backgroundPaused) this.perf.sample('窗口重排');
  }
}
