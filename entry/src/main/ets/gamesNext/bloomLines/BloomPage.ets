import { common } from '@kit.AbilityKit';
import { AchievementEvent } from '../../shell/AchievementModule';
import { BloomAudio } from './BloomAudio';
import { BloomBackdrop } from './BloomBackdrop';
import { BloomBoard } from './BloomBoard';
import { BloomIconButton, BloomModePicker, BloomNextBatch, BloomStats, BloomTools } from './BloomControls';
import { BloomDialog } from './BloomDialog';
import { BloomDrag, BloomGridGeometry, BloomPoint, bloomCellOrigin } from './BloomDrag';
import { BloomEngine } from './BloomEngine';
import { BloomCrease, BloomInsets, BloomLayout, bloomLayout, sameBloomLayout } from './BloomLayout';
import { BLOOM_HINT, BLOOM_LOGO, BloomMode, BloomTurn, bloomConfig } from './BloomModel';
import { BloomPalette as P } from './BloomPalette';
import { BloomProgress } from './BloomProgress';
import { BloomReflow } from './BloomReflow';
import { bloomReachable } from './BloomRules';
import { BloomStorage } from './BloomStorage';
import { BloomWindow } from './BloomWindow';

@Component
export struct BloomPage {
  @Prop @Watch('themeChanged') dark: boolean = false;
  @Prop @Watch('soundChanged') soundEnabled: boolean = true;
  @Prop @Watch('exitRequested') exitRequest: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  reportAchievementEvent: (event: AchievementEvent) => Promise<boolean> = async () => false;

  private engine: BloomEngine = new BloomEngine();
  private audio: BloomAudio = new BloomAudio();
  private storage: BloomStorage = new BloomStorage();
  private host: BloomWindow = new BloomWindow();
  private progress: BloomProgress | undefined = undefined;
  private context: common.Context | undefined = undefined;
  private loaded: boolean = false;
  private loading: boolean = false;
  private disposed: boolean = false;
  private skipSave: boolean = false;
  private backgroundPaused: boolean = false;
  private animationToken: number = 0;
  private animationTimer: number = -1;
  private currentTurn: BloomTurn | undefined = undefined;
  private returnDialog: string = '';
  private insets: BloomInsets = { top: 24, bottom: 16, left: 0, right: 0 };
  private creases: BloomCrease[] = [];
  private verticalScroll: Scroller = new Scroller();
  private horizontalScroll: Scroller = new Scroller();
  private layoutGeneration: number = 0;
  private saveSequence: number = 0;

  @State pageWidth: number = 390;
  @State pageHeight: number = 844;
  @State layout: BloomLayout = bloomLayout(390, 844, { top: 24, bottom: 16, left: 0, right: 0 });
  @State mode: BloomMode = 'garden';
  @State pendingMode: BloomMode = 'garden';
  @State board: number[] = new Array<number>(49).fill(-1);
  @State next: number[] = [];
  @State selected: number = -1;
  @State drag: BloomDrag = new BloomDrag();
  @State reachable: number[] = [];
  @State score: number = 0;
  @State best: number = 0;
  @State moves: number = 0;
  @State cleared: number = 0;
  @State undoAvailable: boolean = false;
  @State ended: boolean = false;
  @State busy: boolean = false;
  @State gain: number = 0;
  @State turn: number = 0;
  @State movingColor: number = -1;
  @State movingX: number = 0;
  @State movingY: number = 0;
  @State movingScale: number = 1.06;
  @State trail: number[] = [];
  @State born: number[] = [];
  @State birthScale: number = 1;
  @State clearing: number[] = [];
  @State clearScale: number = 1;
  @State hint: string = BLOOM_HINT;
  @State dialog: string = 'loading';
  @State saving: boolean = false;
  @State saveFailed: boolean = false;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.Context;
    this.context = context;
    if (context === undefined) { this.dialog = 'loadError'; return; }
    this.progress = new BloomProgress(this.engine, {
      save: (raw: string): Promise<boolean> => this.storage.save(context, raw),
      report: (event: AchievementEvent): Promise<boolean> => this.reportAchievementEvent(event),
      record: (score: number): void => this.recordScore(score)
    });
    this.audio.setEnabled(this.soundEnabled);
    this.audio.init(context);
    this.host.setDark(this.dark);
    this.host.attach(context, (px: number): number => this.getUIContext().px2vp(px),
      (insets: BloomInsets, creases: BloomCrease[]) => {
        this.insets = insets;
        this.creases = creases;
        this.relayout();
      }, () => this.backgrounded());
    this.boot();
  }

  aboutToDisappear(): void {
    this.finishMotion();
    this.disposed = true;
    if (!this.skipSave) { this.save(); }
    this.host.release();
    this.audio.release();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      BloomBackdrop({ dark: this.dark, canvasWidth: this.pageWidth, canvasHeight: this.pageHeight })
      Column({ space: 10 }) {
        this.Header()
        Scroll(this.horizontalScroll) {
          Scroll(this.verticalScroll) {
            this.PlayArea()
          }.width(this.layout.contentWidth).height(this.layout.body)
          .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).align(Alignment.TopStart)
          .enableScrollInteraction(this.drag.from < 0)
        }.width('100%').height(this.layout.body).scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Auto).align(Alignment.TopStart)
        .enableScrollInteraction(this.drag.from < 0)
      }.width(this.layout.width).height(this.layout.height).clip(true)
      .padding({ left: this.layout.gap, right: this.layout.gap, top: 4, bottom: 8 })
      .position({ x: this.layout.x, y: this.layout.y })
      .enabled(this.dialog.length === 0)
      .accessibilityLevel(this.dialog.length === 0 ? 'auto' : 'no-hide-descendants')
      if (this.dialog.length > 0) {
        BloomDialog({ dark: this.dark, mode: this.dialog, targetMode: this.pendingMode,
          score: this.score, cleared: this.cleared, moves: this.moves, saving: this.saving, saveFailed: this.saveFailed,
          panelWidth: Math.min(390, Math.max(1, this.layout.width - 20)), panelHeight: Math.max(40, this.layout.height - 20),
          close: () => this.closeDialog(), restart: () => this.requestRestart(),
          confirm: () => this.newRound(), leave: () => this.saveAndExit(),
          discard: () => { this.skipSave = true; this.exitToHub(); },
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
      BloomIconButton({ dark: this.dark, icon: 'back', label: '保存并返回大厅', action: () => this.exitRequested() })
      if (this.layout.width >= 340) {
        Image($rawfile(BLOOM_LOGO)).width(35).height(35).accessibilityLevel('no')
      }
      Column({ space: 1 }) {
        Text('五子连珠').fontSize(23).minFontSize(13).maxFontSize(23).maxLines(1).width('100%')
          .fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        Text('花窗连珠').fontSize(10).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      BloomIconButton({ dark: this.dark, icon: this.soundEnabled ? 'sound' : 'muted',
        label: this.soundEnabled ? '关闭音效' : '开启音效', action: () => this.updateSound(!this.soundEnabled) })
      BloomIconButton({ dark: this.dark, icon: this.ended ? 'trophy' : 'pause',
        label: this.ended ? '查看成绩' : '暂停', primary: true,
        action: () => this.present(this.ended ? 'end' : 'pause') })
    }.width('100%').height(52)
  }

  @Builder
  PlayArea() {
    // One set of controls, positioned from one layout result through every fold transition.
    Stack({ alignContent: Alignment.TopStart }) {
      BloomStats({ dark: this.dark, score: this.score, best: this.best, cleared: this.cleared,
        gain: this.gain, turn: this.turn, panelHeight: this.layout.stats.height
      }).width(this.layout.stats.width).position({ x: this.layout.stats.x, y: this.layout.stats.y })
      BloomModePicker({ dark: this.dark, mode: this.mode, panelHeight: this.layout.modes.height,
        choose: (mode: BloomMode) => this.chooseMode(mode)
      }).width(this.layout.modes.width).position({ x: this.layout.modes.x, y: this.layout.modes.y })
      BloomNextBatch({ dark: this.dark, next: this.next, panelHeight: this.layout.queue.height })
        .width(this.layout.queue.width).position({ x: this.layout.queue.x, y: this.layout.queue.y })
      BloomBoard({ dark: this.dark, board: this.board, drag: this.drag, gridSize: bloomConfig(this.mode).size,
        edge: this.layout.board, cell: this.layout.cell, gap: this.layout.tileGap, inset: this.layout.tilePad,
        selected: this.selected, reachable: this.reachable, active: this.loaded && !this.ended && !this.saving,
        title: this.mode === 'garden' ? '小院慢游' : '花窗漫步',
        hint: this.saveFailed ? '进度或成就未保存 · 暂停后可重试' : this.hint, failed: this.saveFailed,
        movingColor: this.movingColor, movingX: this.movingX, movingY: this.movingY, trail: this.trail,
        movingScale: this.movingScale,
        born: this.born, birthScale: this.birthScale, clearing: this.clearing, clearScale: this.clearScale,
        turn: this.turn, tap: (index: number) => this.tap(index),
        dragStart: (index: number, dx: number, dy: number) => this.dragStart(index, dx, dy),
        dragUpdate: (index: number, dx: number, dy: number) => this.dragUpdate(index, dx, dy),
        dragEnd: (index: number) => this.dragEnd(index), dragCancel: (index: number) => this.dragCancel(index)
      }).position({ x: this.layout.boardBox.x, y: this.layout.boardBox.y })
      BloomTools({ dark: this.dark, undoAvailable: this.undoAvailable && !this.busy,
        controlHeight: this.layout.tools.height, undo: () => this.undo(),
        restart: () => this.requestRestart(), help: () => this.present('help')
      }).width(this.layout.tools.width).position({ x: this.layout.tools.x, y: this.layout.tools.y })
      if (this.layout.note.height > 0) {
        this.Note()
      }
    }.width(this.layout.contentWidth).height(this.layout.contentHeight)
  }

  @Builder
  Note() {
    Row({ space: 10 }) {
      if (this.layout.wide) {
        Image($rawfile(P.scene('mascot', this.dark))).width(64).height(64).accessibilityLevel('no')
      }
      Column({ space: 5 }) {
        Text('留一条小路，等一朵花开').fontSize(this.layout.wide ? 14 : 11)
          .fontWeight(FontWeight.Medium).fontColor(P.muted(this.dark))
        if (this.layout.wide) {
          Text('移动要有路，消除就能腾出空位。\n慢慢来，小鸡陪你想。')
            .fontSize(11).lineHeight(19).fontColor(P.muted(this.dark))
        }
      }.layoutWeight(1).alignItems(this.layout.wide ? HorizontalAlign.Start : HorizontalAlign.Center)
    }.width(this.layout.note.width).height(this.layout.note.height)
    .position({ x: this.layout.note.x, y: this.layout.note.y }).hitTestBehavior(HitTestMode.None)
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
      this.sync();
      this.pendingMode = this.mode;
      this.relayout();
      this.dialog = this.ended ? 'end' : this.backgroundPaused ? 'pause' :
        raw.length > 0 && this.moves > 0 ? 'resume' : '';
      if (this.dialog.length === 0) { this.animateOpening(); }
      this.save();
    } catch (_) {
      if (!this.disposed) { this.dialog = 'loadError'; }
    } finally { this.loading = false; }
  }

  private tap(index: number): void {
    if (!this.beginInput()) { return; }
    if (this.engine.round.board[index] >= 0) {
      const selected = this.selected === index ? -1 : index;
      this.getUIContext().animateTo({ duration: 130, curve: Curve.EaseOut }, () => { this.selected = selected; });
      this.reachable = selected < 0 ? [] : bloomReachable(this.engine.round.board, bloomConfig(this.mode).size, selected);
      this.hint = selected < 0 ? BLOOM_HINT : this.reachable.length > 0 ?
        '点带小圆点的空位，让彩珠沿着小路过去' : '这颗彩珠被围住了，先试试别的小伙伴';
      this.audio.play('tap');
      return;
    }
    if (this.selected < 0) { this.hint = '可以直接拖动彩珠，也可以先点珠再点空位'; return; }
    this.playMove(this.selected, index);
  }

  private beginInput(): boolean {
    if (!this.loaded || this.disposed || this.ended || this.dialog.length > 0 || this.saving || this.drag.from >= 0) {
      return false;
    }
    // The turn is already committed: accept the next action without waiting for decorative effects.
    if (this.busy) { this.finishMotion(); }
    return !this.ended && this.dialog.length === 0;
  }

  private gridGeometry(): BloomGridGeometry {
    return { gridSize: bloomConfig(this.mode).size, cell: this.layout.cell,
      gap: this.layout.tileGap, inset: this.layout.tilePad };
  }

  private dragStart(index: number, dx: number, dy: number): void {
    if (!this.beginInput() || this.engine.round.board[index] < 0 || this.engine.round.board[index] === undefined) { return; }
    this.selected = index;
    this.reachable = bloomReachable(this.engine.round.board, bloomConfig(this.mode).size, index);
    this.drag.begin(index, this.engine.round.board[index], this.gridGeometry());
    this.hint = '拖到带圆点的空位，松手放下';
    this.audio.play('tap');
    this.dragUpdate(index, dx, dy);
  }

  private dragUpdate(index: number, dx: number, dy: number): void {
    if (this.drag.from !== index) { return; }
    const previous = this.drag.target;
    this.drag.offset(dx, dy);
    if (this.drag.target !== previous) {
      this.drag.valid = this.reachable.includes(this.drag.target);
      this.hint = this.drag.valid ? '松手放下 · 这里有小路可以到达' :
        this.drag.target < 0 ? '拖回棋盘内的空位，或松手放回原处' :
        this.drag.target === index ? '拖到带圆点的空位，松手放下' : '这里暂时走不到，换个带圆点的空位';
    }
  }

  private dragEnd(index: number): void {
    if (this.drag.from !== index) { return; }
    const target = this.drag.target;
    const valid = this.drag.valid;
    const point: BloomPoint = { x: this.drag.x, y: this.drag.y };
    this.drag.cancel();
    if (!valid) {
      this.hint = target === index ? BLOOM_HINT : target < 0 ? '已放回原处 · 在棋盘里的空位松手' : '这条小路被挡住了，换个空位试试';
      if (target >= 0 && target !== index) { this.audio.play('blocked'); }
      this.returnBead(index, point);
      return;
    }
    this.playMove(index, target, point);
  }

  private dragCancel(index: number): void {
    if (this.drag.from !== index) { return; }
    const point: BloomPoint = { x: this.drag.x, y: this.drag.y };
    this.drag.cancel();
    this.hint = BLOOM_HINT;
    this.returnBead(index, point);
  }

  private returnBead(index: number, point: BloomPoint): void {
    this.busy = true;
    this.animationToken += 1;
    this.movingColor = this.engine.round.board[index];
    this.movingScale = 1.12;
    this.movingX = point.x;
    this.movingY = point.y;
    this.board = this.engine.round.board.slice();
    this.board[index] = -1;
    const origin = bloomCellOrigin(index, this.gridGeometry());
    this.later(16, () => {
      this.getUIContext().animateTo({ duration: 120, curve: Curve.EaseOut }, () => {
        this.movingX = origin.x;
        this.movingY = origin.y;
        this.movingScale = 1.08;
      });
      this.later(125, () => this.finishMotion());
    });
  }

  private playMove(from: number, index: number, handoff?: BloomPoint): void {
    const turn = this.engine.move(from, index);
    if (!turn.valid) {
      this.audio.play('blocked');
      this.hint = '这里暂时走不到，换个空位试试';
      if (handoff !== undefined) { this.returnBead(from, handoff); }
      return;
    }
    this.currentTurn = turn;
    this.hint = BLOOM_HINT;
    this.busy = true;
    this.selected = -1;
    this.reachable = [];
    this.turn += 1;
    this.gain = 0;
    this.syncCounters();
    this.board = turn.afterMove.slice();
    this.board[index] = -1;
    this.trail = turn.path.slice();
    this.movingColor = turn.color;
    this.movingScale = handoff === undefined ? 1.06 : 1.12;
    const origin = handoff === undefined ? bloomCellOrigin(turn.path[0], this.gridGeometry()) : handoff;
    this.movingX = origin.x;
    this.movingY = origin.y;
    this.animationToken += 1;
    this.audio.play('travel');
    this.save();
    if (handoff === undefined) { this.later(16, () => this.advancePath(1)); }
    else {
      // The bead has already followed the hand; do not replay its whole route after releasing.
      this.trail = [];
      const target = bloomCellOrigin(index, this.gridGeometry());
      this.later(16, () => {
        this.getUIContext().animateTo({ duration: 90, curve: Curve.EaseOut }, () => {
          this.movingX = target.x;
          this.movingY = target.y;
          this.movingScale = 1;
        });
        this.later(95, () => this.arrived());
      });
    }
  }

  private advancePath(index: number): void {
    const turn = this.currentTurn;
    if (turn === undefined) { return; }
    if (index >= turn.path.length) { this.arrived(); return; }
    const duration = Math.max(8, Math.min(28, Math.floor(280 / (turn.path.length - 1))));
    const point = bloomCellOrigin(turn.path[index], this.gridGeometry());
    this.getUIContext().animateTo({ duration: duration, curve: Curve.Linear }, () => {
      this.movingX = point.x;
      this.movingY = point.y;
    });
    this.later(duration, () => this.advancePath(index + 1));
  }

  private arrived(): void {
    const turn = this.currentTurn;
    if (turn === undefined) { return; }
    this.movingColor = -1;
    this.trail = [];
    this.board = turn.afterMove.slice();
    if (turn.clearFromMove) { this.animateClear(); return; }
    this.board = turn.spawnBoard.slice();
    this.born = turn.spawned.slice();
    this.birthScale = .45;
    this.next = this.engine.round.next.slice();
    this.audio.play('spawn');
    this.later(16, () => {
      this.getUIContext().animateTo({ duration: 170, curve: Curve.EaseOut }, () => { this.birthScale = 1; });
      this.later(180, () => {
        if (turn.removed.length > 0) { this.animateClear(); }
        else { this.finishMotion(); }
      });
    });
  }

  private animateClear(): void {
    const turn = this.currentTurn;
    if (turn === undefined) { return; }
    this.born = [];
    this.clearing = turn.removed.slice();
    this.clearScale = 1;
    this.gain = turn.gain;
    this.hint = '小花开了 · 消除 ' + turn.removed.length + ' 颗，得到 ' + turn.gain + ' 分';
    this.audio.play('clear');
    this.later(16, () => {
      this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseInOut }, () => { this.clearScale = .04; });
      this.later(330, () => this.afterClear());
    });
  }

  private afterClear(): void {
    const turn = this.currentTurn;
    if (turn === undefined || turn.refilled.length === 0) { this.finishMotion(); return; }
    this.clearing = [];
    this.board = this.engine.round.board.slice();
    this.next = this.engine.round.next.slice();
    this.born = turn.refilled.slice();
    this.birthScale = .45;
    this.hint = '整盘开花了 · 送来几颗小彩珠，接着玩';
    this.audio.play('spawn');
    this.later(16, () => {
      this.getUIContext().animateTo({ duration: 190, curve: Curve.EaseOut }, () => { this.birthScale = 1; });
      this.later(200, () => this.finishMotion());
    });
  }

  private animateOpening(): void {
    this.born = [];
    this.board.forEach((color: number, index: number) => { if (color >= 0) { this.born.push(index); } });
    this.birthScale = .45;
    this.busy = true;
    this.later(16, () => {
      this.getUIContext().animateTo({ duration: 190, curve: Curve.EaseOut }, () => { this.birthScale = 1; });
      this.later(200, () => this.finishMotion());
    });
  }

  private later(delay: number, action: () => void): void {
    const token = this.animationToken;
    this.animationTimer = setTimeout(() => {
      if (this.disposed || token !== this.animationToken) { return; }
      this.animationTimer = -1;
      action();
    }, delay);
  }

  private finishMotion(): void {
    this.drag.cancel();
    const wasBusy = this.busy;
    this.animationToken += 1;
    if (this.animationTimer !== -1) { clearTimeout(this.animationTimer); }
    this.animationTimer = -1;
    this.currentTurn = undefined;
    this.movingColor = -1;
    this.movingScale = 1.06;
    this.trail = [];
    this.born = [];
    this.clearing = [];
    this.birthScale = 1;
    this.clearScale = 1;
    this.busy = false;
    this.sync();
    if (wasBusy && this.ended && this.dialog.length === 0 && !this.disposed) {
      this.dialog = 'end';
      this.audio.play('end');
    }
  }

  private syncCounters(): void {
    this.mode = this.engine.round.mode;
    this.score = this.engine.round.score;
    this.best = this.engine.best();
    this.moves = this.engine.round.moves;
    this.cleared = this.engine.round.cleared;
    this.ended = this.engine.round.ended;
    this.undoAvailable = !this.ended && this.engine.history.length > 0;
  }
  private sync(): void {
    this.syncCounters();
    this.board = this.engine.round.board.slice();
    this.next = this.engine.round.next.slice();
  }

  private undo(): void {
    if (this.busy || this.saving || !this.engine.undo()) { return; }
    this.selected = -1;
    this.reachable = [];
    this.gain = 0;
    this.sync();
    this.hint = '已回到上一步 · 下一批彩珠也一起回来了';
    this.audio.play('undo');
    this.save();
  }
  private chooseMode(mode: BloomMode): void {
    if (!this.loaded || this.saving || mode === this.mode) { return; }
    this.pendingMode = mode;
    this.present('mode');
  }
  private requestRestart(): void {
    if (!this.loaded || this.saving) { return; }
    this.pendingMode = this.mode;
    this.present('restart');
  }
  private async newRound(): Promise<void> {
    if (this.saving || this.context === undefined) { return; }
    this.finishMotion();
    this.saving = true;
    const accepted = !this.loaded || await this.save();
    this.saving = false;
    if (!accepted || this.disposed) { return; }
    if (this.loaded && !this.engine.round.ended && this.engine.round.moves > 0) { this.recordScore(this.engine.round.score); }
    this.engine.reset(this.pendingMode);
    this.loaded = true;
    this.selected = -1;
    this.reachable = [];
    this.gain = 0;
    this.returnDialog = '';
    this.dialog = this.backgroundPaused ? 'pause' : '';
    this.hint = BLOOM_HINT;
    this.sync();
    this.relayout();
    if (!this.backgroundPaused) {
      this.animateOpening();
      this.audio.play('tap');
    }
    this.save();
  }

  private present(mode: string): void {
    if (!this.loaded || this.saving) { return; }
    this.finishMotion();
    this.returnDialog = this.dialog;
    this.dialog = mode;
    this.audio.silence();
    this.save();
  }
  private closeDialog(): void {
    if (!this.loaded || this.saving) { return; }
    this.dialog = this.returnDialog;
    this.returnDialog = '';
    this.pendingMode = this.mode;
    this.backgroundPaused = false;
    this.audio.play('tap');
  }
  private relayout(): void {
    if (this.disposed) { return; }
    const next = bloomLayout(this.pageWidth, this.pageHeight, this.insets, this.creases, this.engine.round.mode);
    if (sameBloomLayout(this.layout, next)) { return; }
    this.finishMotion();
    this.layout = next;
    const generation = ++this.layoutGeneration;
    this.getUIContext().postFrameCallback(new BloomReflow(() => {
      if (this.disposed || generation !== this.layoutGeneration) { return; }
      this.verticalScroll.scrollTo({ xOffset: 0, yOffset: 0, animation: false });
      this.horizontalScroll.scrollTo({ xOffset: 0, yOffset: 0, animation: false });
    }));
  }
  private backgrounded(): void {
    this.backgroundPaused = true;
    this.finishMotion();
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
    await this.save();
    if (!this.disposed) { this.saving = false; }
  }
  private async saveAndExit(): Promise<void> {
    if (this.saving) { return; }
    this.finishMotion();
    this.audio.silence();
    this.saving = true;
    const accepted = await this.save();
    if (this.disposed) { return; }
    this.saving = false;
    if (accepted) {
      if (!this.engine.round.ended && this.engine.round.moves > 0) { this.recordScore(this.engine.round.score); }
      this.skipSave = true;
      this.exitToHub();
    } else { this.dialog = 'exit'; }
  }
}
