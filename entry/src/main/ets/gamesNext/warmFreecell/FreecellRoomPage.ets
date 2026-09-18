import { common } from '@kit.AbilityKit';
import { AchievementEvent } from '../../shell/AchievementModule';
import { FreecellAudio } from './FreecellAudio';
import { FreecellBoard } from './FreecellBoard';
import { FCCardView } from './FreecellCard';
import { FCButton, FCStats } from './FreecellControls';
import { FCCrease, FCInsets, FCLayout, fcCardY, fcLayout, fcPileX, fcTarget } from './FreecellLayout';
import { FC_HINT, FC_LOGO, fcCapacity, fcLocate, fcName, fcSuit } from './FreecellModel';
import { FCPalette as P } from './FreecellPalette';
import { FreecellPanel } from './FreecellPanels';
import { FreecellSession } from './FreecellSession';
import { FreecellStorage } from './FreecellStorage';
import { FreecellWindow } from './FreecellWindow';

@Component
export struct FreecellRoomPage {
  @Prop @Watch('themeChanged') dark: boolean = false;
  @Prop @Watch('soundChanged') soundEnabled: boolean = true;
  @Prop @Watch('exitRequested') exitRequest: number = 0;
  exitToHub: () => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  recordScore: (score: number) => void = () => {};
  reportAchievementEvent: (event: AchievementEvent) => Promise<boolean> = async () => false;
  private engine: FreecellSession = new FreecellSession();
  private audio: FreecellAudio = new FreecellAudio();
  private storage: FreecellStorage = new FreecellStorage();
  private host: FreecellWindow = new FreecellWindow();
  private context: common.Context | undefined = undefined;
  private loaded: boolean = false;
  private loading: boolean = false;
  private disposed: boolean = false;
  private skipSave: boolean = false;
  private backgroundPaused: boolean = false;
  private clock: number = -1;
  private clockMark: number = 0;
  private started: boolean = false;
  private motionTimer: number = -1;
  private motionEpoch: number = 0;
  private autoTimer: number = -1;
  private autoVisited: string[] = [];
  private moving: number[] = [];
  private dragging: boolean = false;
  private lastDrag: number = 0;
  private lastTap: number = 0;
  private lastCard: number = -1;
  private queuedCard: number = -1;
  private queuedTarget: number = -1;
  private hintIndex: number = 0;
  private returnMode: string = '';
  private insets: FCInsets = { top: 24, bottom: 16, left: 0, right: 0 };
  private folds: FCCrease[] = [];
  private outerV: Scroller = new Scroller();
  private outerH: Scroller = new Scroller();
  @State pageWidth: number = 390;
  @State pageHeight: number = 844;
  @State layout: FCLayout = fcLayout(390, 844, { top: 24, bottom: 16, left: 0, right: 0 });
  @State cards: FCCardView[] = Array.from({ length: 52 }, (_: number, id: number): FCCardView => new FCCardView(id));
  @State session: string = '';
  @State seed: number = 1;
  @State selected: number = -1;
  @State hintCard: number = -1;
  @State hintTarget: number = -1;
  @State collected: number = 0;
  @State elapsed: number = 0;
  @State moves: number = 0;
  @State historyCount: number = 0;
  @State surfaceHeight: number = 400;
  @State revision: number = 0;
  @State busy: boolean = false;
  @State automatic: boolean = false;
  @State dialog: string = 'loading';
  @State note: string = FC_HINT;
  @State saving: boolean = false;
  @State saveFailed: boolean = false;

  aboutToAppear(): void {
    this.context = this.getUIContext().getHostContext() as common.Context;
    if (this.context === undefined) { this.dialog = 'loadError'; return; }
    this.audio.setEnabled(this.soundEnabled); this.audio.init(this.context);
    this.host.setDark(this.dark);
    this.host.attach(this.context, (px: number): number => this.getUIContext().px2vp(px),
      (insets: FCInsets, folds: FCCrease[]) => { this.insets = insets; this.folds = folds; this.relayout(); },
      () => this.backgrounded());
    this.clockMark = Date.now();
    this.clock = setInterval(() => this.tick(), 500);
    this.boot();
  }
  aboutToDisappear(): void {
    this.tick(); this.stopAuto(); this.finishMotion(); this.cancelDrag();
    if (!this.skipSave) this.save();
    this.disposed = true;
    if (this.clock >= 0) clearInterval(this.clock);
    this.host.release(); this.audio.release();
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(P.asset('scene/backdrop', this.dark))).width('100%').height('100%')
        .objectFit(ImageFit.Fill).draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      Scroll() { this.Header() }.width(this.layout.frame.width).height(56).scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off).position({ x: this.layout.frame.x, y: this.layout.frame.y + 2 })
        .enabled(this.dialog === '').accessibilityLevel(this.dialog === '' ? 'auto' : 'no-hide-descendants')
      Scroll(this.outerH) {
        Scroll(this.outerV) {
          this.PlayArea()
        }.width(this.layout.width).height(Math.max(1, this.layout.frame.height - 64))
          .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).align(Alignment.TopStart)
      }.width(Math.min(this.layout.frame.width, this.layout.width)).height(Math.max(1, this.layout.frame.height - 64))
        .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Auto).align(Alignment.TopStart)
        .position({ x: this.layout.frame.x + Math.max(0, (this.layout.frame.width - this.layout.width) / 2), y: this.layout.frame.y + 62 })
        .enabled(this.dialog === '').accessibilityLevel(this.dialog === '' ? 'auto' : 'no-hide-descendants')
      if (this.dialog !== '') {
        FreecellPanel({ dark: this.dark, mode: this.dialog, collected: this.collected, moves: this.moves, seed: this.seed,
          panelWidth: Math.min(410, Math.max(1, this.layout.frame.width - 16)), panelHeight: Math.max(1, this.layout.frame.height - 12),
          saving: this.saving, saveFailed: this.saveFailed, close: () => this.closePanel(),
          restart: () => this.present('restart'), same: () => this.newGame(true), fresh: () => this.newGame(false),
          leave: () => this.saveAndExit(), retry: () => {
            if (this.dialog === 'loadError') this.boot();
            else if (this.engine.won() && !this.engine.reported) this.reportWin();
            else this.save();
          },
          discard: () => { this.skipSave = true; this.exitToHub(); }
        }).width(this.layout.frame.width).height(this.layout.frame.height)
          .position({ x: this.layout.frame.x, y: this.layout.frame.y })
      }
    }.width('100%').height('100%').backgroundColor(P.bg(this.dark))
    .onAreaChange((_old: Area, area: Area) => {
      this.pageWidth = Number(area.width); this.pageHeight = Number(area.height); this.host.measure(); this.relayout();
    })
  }
  @Builder
  Header() {
    Row({ space: 7 }) {
      FCButton({ dark: this.dark, icon: 'back', small: true, label: '返回大厅', action: () => this.exitRequested() })
      if (this.layout.frame.width >= 350) { Image($rawfile(FC_LOGO)).width(32).height(32).accessibilityLevel('no') }
      Column({ space: 1 }) {
        Text('空当接龙').fontSize(23).minFontSize(14).maxFontSize(23).maxLines(1).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        Text('暖木牌室').fontSize(10).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      FCButton({ dark: this.dark, icon: this.soundEnabled ? 'sound' : 'muted', small: true,
        label: this.soundEnabled ? '关闭音效' : '开启音效', action: () => this.updateSound(!this.soundEnabled) })
      FCButton({ dark: this.dark, icon: 'pause', small: true, primary: true, label: '暂停', action: () => this.present('pause') })
    }.width(Math.max(280, this.layout.frame.width - 24)).height(54).margin({ left: 12, right: 12 })
  }
  @Builder
  PlayArea() {
    Stack({ alignContent: Alignment.TopStart }) {
      FCStats({ dark: this.dark, collected: this.collected, moves: this.moves, elapsed: this.elapsed })
        .width(this.layout.stats.width).position({ x: this.layout.stats.x, y: this.layout.stats.y })
      FreecellBoard({ cards: $cards, dark: this.dark, layout: this.layout, surfaceHeight: this.surfaceHeight,
        session: this.session, revision: this.revision, hintTarget: this.hintTarget, active: this.dialog === '',
        tap: (id: number) => this.tap(id), target: (pile: number) => this.target(pile),
        dragStart: (id: number) => this.beginDrag(id), dragUpdate: (dx: number, dy: number) => this.drag(dx, dy),
        dragEnd: (id: number, dx: number, dy: number) => this.drop(id, dx, dy), dragCancel: () => this.cancelDrag()
      }).position({ x: this.layout.board.x, y: this.layout.board.y })
      this.Tools()
    }.width(this.layout.width).height(this.layout.height)
  }
  private toolWidth(): number { return this.layout.wide ? this.layout.tools.width : (this.layout.tools.width - 16) / 3; }
  @Builder
  Tools() {
    Scroll() {
      Stack({ alignContent: Alignment.TopStart }) {
        FCButton({ dark: this.dark, icon: 'undo', label: '撤销', active: this.historyCount > 0, action: () => this.undo() })
          .width(this.toolWidth()).position({ x: 0, y: 0 })
        FCButton({ dark: this.dark, icon: 'hint', label: '提示', active: !this.busy && this.collected < 52, action: () => this.showHint() })
          .width(this.toolWidth()).position({ x: this.layout.wide ? 0 : this.toolWidth() + 8, y: this.layout.wide ? 60 : 0 })
        FCButton({ dark: this.dark, icon: this.automatic ? 'pause' : 'auto', label: this.automatic ? '停止整理' : '自动整理',
          primary: this.automatic, active: this.collected < 52, action: () => this.toggleAuto() })
          .width(this.toolWidth()).position({ x: this.layout.wide ? 0 : (this.toolWidth() + 8) * 2, y: this.layout.wide ? 120 : 0 })
        Text(this.saveFailed ? '进度尚未保存 · 暂停后可重试' : this.note).fontSize(11).maxLines(this.layout.wide ? 4 : 2)
          .fontColor(this.saveFailed ? P.red(this.dark) : P.muted(this.dark)).textAlign(TextAlign.Center)
          .width(this.layout.tools.width).height(this.layout.wide ? 74 : 32)
          .position({ x: 0, y: this.layout.wide ? 320 : 54 })
        FCButton({ dark: this.dark, icon: 'restart', label: '新牌局', action: () => this.present('restart') })
          .width(this.layout.wide ? this.layout.tools.width : (this.layout.tools.width - 8) / 2)
          .position({ x: 0, y: this.layout.wide ? 200 : 88 })
        FCButton({ dark: this.dark, icon: 'help', label: '游玩指南', action: () => this.present('help') })
          .width(this.layout.wide ? this.layout.tools.width : (this.layout.tools.width - 8) / 2)
          .position({ x: this.layout.wide ? 0 : (this.layout.tools.width + 8) / 2, y: this.layout.wide ? 260 : 88 })
        if (this.layout.wide) {
          Text('留一个空当，\n也给下一步留一点余地。').fontSize(16).lineHeight(27).fontColor(P.muted(this.dark))
            .width(this.layout.tools.width).textAlign(TextAlign.Center).position({ x: 0, y: 410 })
        }
      }.width(this.layout.tools.width).height(this.layout.wide ? 485 : 140)
    }.width(this.layout.tools.width).height(this.layout.tools.height).scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto)
      .align(Alignment.TopStart)
      .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
      .position({ x: this.layout.tools.x, y: this.layout.tools.y })
  }
  private async boot(): Promise<void> {
    if (this.loading || this.context === undefined) return;
    this.loading = true; this.dialog = 'loading';
    try {
      const raw = await this.storage.load(this.context);
      if (this.disposed) return;
      const restored = raw.length > 0 && this.engine.restore(raw);
      this.loaded = true; this.started = this.engine.moves > 0 || this.engine.elapsed > 0;
      this.sync();
      this.note = raw.length > 0 && !restored ? '上次进度无法恢复，已准备新的牌局' : FC_HINT;
      this.dialog = this.backgroundPaused ? 'pause' : this.engine.won() ? 'win' : restored && this.started ? 'resume' : '';
      if (this.engine.won()) this.reportWin();
      else if (!restored && !this.backgroundPaused) this.deal();
    } catch (_) { if (!this.disposed) this.dialog = 'loadError'; }
    finally { this.loading = false; }
  }
  private sync(): void {
    this.session = this.engine.session; this.seed = this.engine.seed; this.moves = this.engine.moves;
    this.collected = this.engine.collected(); this.elapsed = this.engine.elapsed; this.historyCount = this.engine.history.length;
    const selected = this.selected >= 0 ? this.engine.selected(this.selected) : [];
    this.cards.forEach((card: FCCardView) => {
      const where = fcLocate(this.engine.piles, card.id);
      card.width = this.layout.card; card.height = this.layout.cardHeight;
      card.x = fcPileX(this.layout, where.pile); card.y = fcCardY(this.layout, where.pile, where.index);
      card.layer = where.index + 1 + (this.moving.includes(card.id) ? 150 : 0);
      card.visible = where.pile < 12 || where.index === this.engine.piles[where.pile].length - 1;
      card.selected = selected.includes(card.id); card.hinted = card.id === this.hintCard;
      card.dx = 0; card.dy = 0;
    });
    const longest = Math.max(...this.engine.piles.slice(0, 8).map((p: number[]) => p.length));
    this.surfaceHeight = Math.max(this.layout.board.height, this.layout.tableY + Math.max(0, longest - 1) * this.layout.fan + this.layout.cardHeight + 16);
  }
  private canPlay(): boolean { return this.loaded && !this.disposed && !this.saving && this.dialog === ''; }
  private tap(id: number): void {
    if (!this.canPlay() || Date.now() - this.lastDrag < 220) return;
    this.stopAuto();
    if (this.busy) { this.queuedCard = id; this.queuedTarget = -1; return; }
    const target = fcLocate(this.engine.piles, id);
    if (id === this.lastCard && Date.now() - this.lastTap < 330) {
      this.lastCard = -1;
      if (!this.move(id, fcSuit(id) + 12)) { this.selected = id; this.note = '这张牌还不能归位，先整理下方的牌'; this.sync(); }
      return;
    }
    this.lastCard = id; this.lastTap = Date.now();
    if (this.selected >= 0 && id !== this.selected && this.move(this.selected, target.pile)) return;
    if (this.engine.selected(id).length === 0) {
      this.note = target.pile >= 12 ? '归位的牌可以通过撤销取回' : '先整理这张牌下面的纸牌'; this.audio.play('blocked'); return;
    }
    this.selected = this.selected === id ? -1 : id; this.hintCard = -1; this.hintTarget = -1;
    this.note = this.selected < 0 ? FC_HINT : `${fcName(id)} · 点选目标位置`;
    this.audio.play('tap'); this.sync();
  }
  private target(pile: number): void {
    if (!this.canPlay()) return;
    this.stopAuto();
    if (this.busy) { this.queuedTarget = pile; this.queuedCard = -1; return; }
    if (this.selected >= 0 && !this.move(this.selected, pile)) {
      this.note = pile < 8 && this.engine.selected(this.selected).length > fcCapacity(this.engine.piles, pile) ?
        `空当不足，这次最多搬 ${fcCapacity(this.engine.piles, pile)} 张` : '这里暂时放不下，试试其他位置';
      this.audio.play('blocked');
    }
  }
  private move(id: number, target: number): boolean {
    if (!this.canPlay() || this.busy) return false;
    const moving = this.engine.selected(id);
    if (!this.engine.move(id, target)) return false;
    if (!this.started) { this.started = true; this.clockMark = Date.now(); }
    this.moving = moving; this.selected = -1; this.hintCard = -1; this.hintTarget = target >= 12 ? target : -1; this.hintIndex = 0;
    this.busy = true; this.note = target >= 12 ? '一张归位，思路又清楚了一点' : FC_HINT;
    this.audio.play(target >= 12 ? 'home' : 'slide');
    this.getUIContext().animateTo({ duration: 185, curve: Curve.EaseOut }, () => this.sync());
    this.scheduleFinish(210); this.save();
    if (this.engine.won()) this.reportWin();
    return true;
  }
  private scheduleFinish(ms: number): void {
    if (this.motionTimer >= 0) clearTimeout(this.motionTimer);
    const epoch = ++this.motionEpoch;
    this.motionTimer = setTimeout(() => {
      if (this.disposed || epoch !== this.motionEpoch) return;
      this.finishMotion();
      if (this.engine.won()) { this.stopAuto(); this.present('win'); this.audio.play('win'); this.reportWin(); }
      else if (this.automatic) this.scheduleAuto();
      else {
        const card = this.queuedCard; const target = this.queuedTarget; this.queuedCard = -1; this.queuedTarget = -1;
        if (card >= 0) this.tap(card); else if (target >= 0) this.target(target);
      }
    }, ms);
  }
  private finishMotion(): void {
    this.motionEpoch++;
    if (this.motionTimer >= 0) clearTimeout(this.motionTimer);
    if (this.busy) this.hintTarget = -1;
    this.motionTimer = -1; this.busy = false; this.moving = [];
    if (this.loaded) this.sync();
  }
  private clearIntent(): void { this.queuedCard = -1; this.queuedTarget = -1; this.lastCard = -1; }
  private undo(): void {
    if (!this.canPlay()) return;
    this.stopAuto(); this.clearIntent(); this.finishMotion(); this.cancelDrag();
    if (!this.engine.undo()) return;
    this.selected = -1; this.hintCard = -1; this.hintTarget = -1; this.audio.play('undo'); this.busy = true;
    this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut }, () => this.sync());
    this.scheduleFinish(200); this.note = '回到上一步，再想想也很好'; this.save();
  }
  private showHint(): void {
    if (!this.canPlay() || this.busy) return;
    this.stopAuto(); this.selected = -1;
    const hints = this.engine.suggestions();
    if (hints.length === 0) { this.note = '暂时没有可走的牌，可以撤销或重玩'; this.hintCard = -1; this.hintTarget = -1; }
    else {
      const hint = hints[this.hintIndex++ % hints.length];
      this.hintCard = hint.card; this.hintTarget = hint.target;
      const dest = this.engine.piles[hint.target];
      this.note = hint.target >= 12 ? `${fcName(hint.card)} 可以归位` : hint.target >= 8 ? `${fcName(hint.card)} 可暂放空当` :
        dest.length > 0 ? `${fcName(hint.card)} 可接在${fcName(dest[dest.length - 1])}下方` : `${fcName(hint.card)} 可移到空列`;
    }
    this.audio.play('hint'); this.sync();
  }
  private toggleAuto(): void {
    if (this.automatic) { this.stopAuto(); this.note = '自动整理已停止，轮到你了'; return; }
    if (!this.canPlay() || this.busy || this.engine.won()) return;
    this.automatic = true; this.autoVisited = [this.engine.key()]; this.selected = -1;
    this.scheduleAuto();
  }
  private scheduleAuto(): void {
    this.autoTimer = setTimeout(() => {
      this.autoTimer = -1;
      if (!this.automatic || !this.canPlay()) return;
      const move = this.autoVisited.length < 120 ? this.engine.automatic(this.autoVisited) : undefined;
      if (move === undefined || !this.move(move.card, move.target)) {
        this.stopAuto(); this.note = '自动整理先停在这里，你可以接着想一想'; return;
      }
      this.autoVisited.push(this.engine.key());
    }, 170);
  }
  private stopAuto(): void { if (this.autoTimer >= 0) clearTimeout(this.autoTimer); this.autoTimer = -1; this.automatic = false; }
  private beginDrag(id: number): boolean {
    this.stopAuto();
    if (!this.canPlay() || this.busy || this.engine.selected(id).length === 0) return false;
    this.stopAuto(); this.selected = id; this.dragging = true; this.hintCard = -1; this.hintTarget = -1; this.sync(); this.audio.play('tap');
    return true;
  }
  private drag(dx: number, dy: number): void {
    if (!this.dragging) return;
    const ids = this.engine.selected(this.selected);
    this.cards.forEach((card: FCCardView) => { if (ids.includes(card.id)) { card.dx = dx; card.dy = dy; } });
  }
  private drop(id: number, dx: number, dy: number): void {
    if (!this.dragging) return;
    this.dragging = false; this.lastDrag = Date.now();
    const card = this.cards[id];
    const target = fcTarget(this.layout, card.x + dx + this.layout.card / 2, card.y + dy + 12);
    if (!this.move(id, target)) {
      this.audio.play('blocked'); this.note = '这里暂时放不下，换一个位置试试';
      this.getUIContext().animateTo({ duration: 150, curve: Curve.EaseOut }, () => this.sync());
    }
  }
  private cancelDrag(): void { this.dragging = false; if (this.loaded) this.sync(); }
  private deal(): void {
    this.busy = true;
    this.cards.forEach((card: FCCardView) => { card.x = this.layout.surfaceWidth * .45; card.y = this.layout.tableY + 20; });
    this.audio.play('deal');
    this.getUIContext().animateTo({ duration: 620, curve: Curve.EaseOut }, () => this.sync());
    this.scheduleFinish(650);
  }
  private newGame(same: boolean): void {
    if (!this.loaded || this.saving) return;
    this.stopAuto(); this.clearIntent(); this.finishMotion(); this.cancelDrag();
    this.engine.newGame(same ? this.engine.seed : undefined); this.selected = -1; this.started = false;
    this.hintCard = -1; this.hintTarget = -1; this.hintIndex = 0; this.dialog = ''; this.returnMode = '';
    this.note = FC_HINT; this.revision++; this.sync(); this.save(); this.deal();
  }
  private present(mode: string): void {
    if (!this.loaded) return;
    this.tick(); this.stopAuto(); this.clearIntent(); this.finishMotion(); this.cancelDrag(); this.revision++;
    if (mode === 'help' || mode === 'restart') this.returnMode = this.dialog;
    this.dialog = mode; this.audio.silence(); this.save();
  }
  private closePanel(): void {
    if (this.saving) return;
    this.dialog = this.dialog === 'help' || this.dialog === 'restart' ? this.returnMode : '';
    this.returnMode = ''; this.backgroundPaused = false; this.clockMark = Date.now();
  }
  private exitRequested(): void {
    if (!this.loaded) { if (!this.loading) this.exitToHub(); return; }
    if (this.dialog !== '') { this.closePanel(); return; }
    this.present('exit');
  }
  private backgrounded(): void {
    this.tick(); this.backgroundPaused = true; this.stopAuto(); this.clearIntent(); this.finishMotion(); this.cancelDrag();
    if (this.loaded && this.dialog === '') this.dialog = 'pause';
    this.revision++; this.audio.silence(); this.save();
  }
  private tick(): void {
    const now = Date.now();
    if (!this.loaded || !this.started || this.dialog !== '' || this.engine.won() || this.backgroundPaused) { this.clockMark = now; return; }
    const seconds = Math.max(0, Math.floor((now - this.clockMark) / 1000));
    if (seconds > 0) { this.clockMark += seconds * 1000; this.engine.elapsed += seconds; this.elapsed = this.engine.elapsed; if (this.elapsed % 15 === 0) this.save(); }
  }
  private relayout(): void {
    const next = fcLayout(this.pageWidth, this.pageHeight, this.insets, this.folds);
    if (JSON.stringify(next) === JSON.stringify(this.layout)) return;
    this.stopAuto(); this.clearIntent(); this.finishMotion(); this.cancelDrag();
    this.layout = next; this.revision++; if (this.loaded) this.sync();
    // A fold can cancel the last card's animation after its move has committed.
    // Keep the result reachable even when that animation callback never runs.
    if (this.loaded && this.engine.won() && this.dialog === '') this.dialog = 'win';
  }
  themeChanged(): void { this.host.setDark(this.dark); }
  soundChanged(): void { this.audio.setEnabled(this.soundEnabled); }
  private async save(): Promise<boolean> {
    if (!this.loaded || this.context === undefined || this.skipSave) return false;
    const session = this.engine.session;
    const success = await this.storage.save(this.context, this.engine.serialize());
    if (!this.disposed && this.engine.session === session) this.saveFailed = !success;
    return success;
  }
  private async saveAndExit(): Promise<void> {
    if (this.saving) return;
    this.present('exit'); this.saving = true;
    const success = await this.save();
    if (this.disposed) return;
    this.saving = false;
    if (success) { this.skipSave = true; this.exitToHub(); }
  }
  private async reportWin(): Promise<void> {
    if (!this.engine.won() || this.engine.reported || this.saving || this.context === undefined) return;
    this.saving = true;
    const session = this.engine.session; const moves = this.engine.moves; const elapsed = this.engine.elapsed;
    // Keep the won board recoverable before sending, without acknowledging early.
    const success = await this.save();
    if (!success) { if (!this.disposed) this.saving = false; return; }
    const event: AchievementEvent = { eventId: `${session}:session-end`, sessionId: session, gameId: 'freecell', type: 'sessionEnd', occurredAt: Date.now(), isOfficial: true,
      facts: [{ key: 'won', value: 1 }, { key: 'moves', value: moves }, { key: 'elapsedSec', value: elapsed }, { key: 'score', value: 520 }] };
    const accepted = await this.reportAchievementEvent(event).catch(() => false);
    if (accepted) this.recordScore(520);
    if (this.engine.session === session && accepted) {
      this.engine.reported = true;
      await this.save();
    }
    if (!this.disposed) { this.saving = false; if (!accepted) this.saveFailed = true; }
  }
}
