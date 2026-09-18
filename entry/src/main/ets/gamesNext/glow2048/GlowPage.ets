import { common } from '@kit.AbilityKit';
import { AchievementEvent } from '../../shell/AchievementModule';
import { GlowAudio } from './GlowAudio';
import { GlowBoard } from './GlowBoard';
import { GlowDirectionPad, GlowIconButton, GlowStats, GlowUtilityButton } from './GlowControls';
import { GlowBackdrop } from './GlowBackdrop';
import { GlowDialog } from './GlowDialog';
import { GlowEngine } from './GlowEngine';
import { GlowCrease, GlowInsets, GlowLayout, glowLayout, sameGlowLayout } from './GlowLayout';
import { GLOW_LOGO, GLOW_PLAY_HINT, GlowDirection, GlowMotion, GlowTile, GlowTurn, glowMax, glowTarget } from './GlowModel';
import { GlowPalette as P } from './GlowPalette';
import { GlowRenderTile, glowReconcileTiles } from './GlowRenderTile';
import { GlowReflow } from './GlowReflow';
import { GlowStorage } from './GlowStorage';
import { GlowWindow } from './GlowWindow';

@Component
export struct GlowPage {
  @Prop @Watch('themeChanged') dark: boolean = false;
  @Prop bestScore: number = 0;
  @Prop @Watch('soundChanged') soundEnabled: boolean = true;
  @Prop @Watch('exitRequested') exitRequest: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  reportAchievementEvent: (event: AchievementEvent) => Promise<boolean> = async () => false;
  private reportingSession: string = '';
  private achievementSaveFailed: boolean = false;
  private engine: GlowEngine = new GlowEngine();
  private audio: GlowAudio = new GlowAudio();
  private storage: GlowStorage = new GlowStorage();
  private host: GlowWindow = new GlowWindow();
  private context: common.Context | undefined = undefined;
  private loaded: boolean = false;
  private loading: boolean = false;
  private disposed: boolean = false;
  private skipSave: boolean = false;
  private backgroundPaused: boolean = false;
  private animationToken: number = 0;
  private currentTurn: GlowTurn | undefined = undefined;
  private queued: GlowDirection | undefined = undefined;
  private settleTimer: number = -1;
  private returnDialog: string = '';
  @State pageWidth: number = 390;
  @State pageHeight: number = 844;
  private insets: GlowInsets = { top: 24, bottom: 16, left: 0, right: 0 };
  private creases: GlowCrease[] = [];
  private verticalScroll: Scroller = new Scroller();
  private horizontalScroll: Scroller = new Scroller();
  private layoutGeneration: number = 0;
  @State layout: GlowLayout = glowLayout(390, 844, { top: 24, bottom: 16, left: 0, right: 0 });
  @State tiles: GlowRenderTile[] = [];
  @State sessionKey: string = '';
  @State score: number = 0;
  @State moves: number = 0;
  @State maxTile: number = 2;
  @State streak: number = 0;
  @State gain: number = 0;
  @State spawned: number = 0;
  @State merged: number[] = [];
  @State busy: boolean = false;
  @State turnKey: number = 0;
  @State boardNudge: number = 0;
  @State dialog: string = 'loading';
  @State saving: boolean = false;
  @State saveFailed: boolean = false;
  @State ended: boolean = false;
  @State hint: string = GLOW_PLAY_HINT;

  aboutToAppear(): void {
    this.context = this.getUIContext().getHostContext() as common.Context;
    if (this.context === undefined) { this.dialog = 'loadError'; return; }
    this.audio.setEnabled(this.soundEnabled);
    this.audio.init(this.context);
    this.host.setDark(this.dark);
    this.host.attach(this.context, (px: number): number => this.getUIContext().px2vp(px),
      (insets: GlowInsets, creases: GlowCrease[]) => { this.insets = insets; this.creases = creases; this.relayout(); },
      () => this.backgrounded());
    this.boot();
  }
  aboutToDisappear(): void {
    this.finishMotion(false);
    if (!this.skipSave) this.save();
    this.disposed = true;
    this.host.release();
    this.audio.release();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      GlowBackdrop({ dark: this.dark, canvasWidth: this.pageWidth, canvasHeight: this.pageHeight })
      Column({ space: 10 }) {
        this.Header()
        Scroll(this.horizontalScroll) {
          Scroll(this.verticalScroll) {
            this.PlayArea()
          }.width(this.layout.contentWidth).height(this.layout.body)
          .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).align(Alignment.TopStart)
        }.width('100%').height(this.layout.body).scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Auto).align(Alignment.TopStart)
      }.width(this.layout.width).height(this.layout.height).clip(true)
      .padding({ left: this.layout.gap, right: this.layout.gap, top: 4, bottom: 6 })
      .position({ x: this.layout.x, y: this.layout.y })
      .enabled(this.dialog.length === 0).accessibilityLevel(this.dialog.length === 0 ? 'auto' : 'no-hide-descendants')
      if (this.dialog.length > 0) {
        GlowDialog({ dark: this.dark, mode: this.dialog, score: this.score, maxTile: this.maxTile,
          moves: this.moves, saving: this.saving, saveFailed: this.saveFailed,
          panelWidth: Math.min(390, Math.max(1, this.layout.width - 20)), panelHeight: Math.max(80, this.layout.height - 20),
          close: () => this.closeDialog(), restart: () => this.requestRestart(), confirmRestart: () => this.newRound(),
          leave: () => this.saveAndExit(), discard: () => { this.skipSave = true; this.exitToHub(); },
          retry: () => this.boot(), retrySave: () => this.retrySave()
        }).width(this.layout.width).height(this.layout.height).position({ x: this.layout.x, y: this.layout.y })
      }
    }.width('100%').height('100%').backgroundColor(P.bg(this.dark))
    .onAreaChange((oldArea: Area, area: Area) => {
      this.pageWidth = Number(area.width);
      this.pageHeight = Number(area.height);
      this.host.measure();
      this.relayout();
    })
  }

  @Builder
  Header() {
    Row({ space: 8 }) {
      GlowIconButton({ dark: this.dark, icon: 'back', label: '返回大厅', action: () => this.exitRequested() })
      if (this.layout.width >= 300) {
        Image($rawfile(GLOW_LOGO)).width(34).height(34).accessibilityLevel('no')
      }
      Column({ space: 1 }) {
        Text('2048').fontSize(25).minFontSize(12).maxFontSize(25).maxLines(1).width('100%')
          .fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        Text('暖光叠数').fontSize(10).maxLines(1).width('100%').fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      GlowIconButton({ dark: this.dark, icon: this.soundEnabled ? 'sound' : 'muted',
        label: this.soundEnabled ? '关闭音效' : '开启音效', action: () => this.updateSound(!this.soundEnabled) })
      GlowIconButton({ dark: this.dark, icon: this.ended ? 'trophy' : 'pause', label: this.ended ? '查看成绩' : '暂停',
        primary: true, action: () => this.present(this.ended ? 'end' : 'pause') })
    }.width('100%').height(52)
  }

  @Builder
  Journey() {
    Column({ space: 8 }) {
      Row() {
        Row({ space: 5 }) {
          Image($rawfile(P.icon('sun', this.dark, 'accent'))).width(16).height(16).accessibilityLevel('no')
          Text(`下一束光 · ${glowTarget(this.maxTile)}`).fontSize(12).fontColor(P.ink(this.dark))
        }.layoutWeight(1)
        Text(this.streak > 1 ? `${this.streak} 步连合` : `最大 ${this.maxTile}`)
          .fontSize(11).fontColor(this.streak > 1 ? P.gold(this.dark) : P.muted(this.dark))
      }.width('100%')
      Progress({ value: Math.log2(this.maxTile), total: Math.log2(glowTarget(this.maxTile)), type: ProgressType.Linear })
        .width('100%').color(P.accent(this.dark)).backgroundColor(P.soft(this.dark)).style({ strokeWidth: 4 })
    }.width(this.layout.journey.width).height(this.layout.journey.height).padding({ left: 4, right: 4, top: 4 })
    .position({ x: this.layout.journey.x, y: this.layout.journey.y })
  }

  @Builder
  BoardPanel() {
    Column({ space: 8 }) {
      GlowBoard({ dark: this.dark, tiles: $tiles, session: this.sessionKey, edge: this.layout.board, cell: this.layout.cell,
        gap: this.layout.tileGap, tileInset: this.layout.tilePad, spawned: this.spawned,
        merged: this.merged, turn: this.turnKey, active: this.dialog.length === 0 && !this.ended,
        move: (direction: GlowDirection) => this.move(direction)
      }).translate({ x: this.boardNudge }).opacity(this.dialog.length > 0 ? .25 : 1)
      Text(this.saveFailed ? '进度未保存 · 暂停后可重试' : this.hint).fontSize(11).maxLines(1)
        .fontColor(this.saveFailed ? P.danger(this.dark) : P.muted(this.dark)).height(16)
    }.width(this.layout.board).height(this.layout.boardBox.height)
    .position({ x: this.layout.boardBox.x, y: this.layout.boardBox.y })
  }

  @Builder
  PlayArea() {
    // One instance of every interactive component survives every posture change.
    // Coordinates come from one layout result; no shared-element transforms or
    // old Row/Column branches can carry an offset into the new viewport.
    Stack({ alignContent: Alignment.TopStart }) {
      GlowStats({ dark: this.dark, score: this.score, best: this.bestScore,
        moves: this.moves, gain: this.gain, turn: this.turnKey, panelHeight: this.layout.stats.height
      }).width(this.layout.stats.width).position({ x: this.layout.stats.x, y: this.layout.stats.y })
      this.Journey()
      this.BoardPanel()
      GlowDirectionPad({ dark: this.dark, active: this.dialog.length === 0 && !this.ended,
        buttonEdge: this.layout.buttonEdge, move: (direction: GlowDirection) => this.move(direction)
      }).position({ x: this.layout.pad.x, y: this.layout.pad.y })
      GlowUtilityButton({ dark: this.dark, icon: 'restart', label: '重新开局',
        controlHeight: this.layout.restart.height,
        stacked: this.layout.restart.width < 110 && this.layout.restart.height > 48,
        action: () => this.requestRestart()
      }).width(this.layout.restart.width).position({ x: this.layout.restart.x, y: this.layout.restart.y })
      GlowUtilityButton({ dark: this.dark, icon: 'help', label: '游玩指南',
        controlHeight: this.layout.help.height,
        stacked: this.layout.help.width < 110 && this.layout.help.height > 48,
        action: () => this.present('help')
      }).width(this.layout.help.width).position({ x: this.layout.help.x, y: this.layout.help.y })
      if (this.layout.note.height > 0) {
        Column({ space: 9 }) {
          Text('留一点空白，等下一次相遇').fontSize(15).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
          Text('让大数字靠在一角，\n给新数字留出移动的空间。').fontSize(12).lineHeight(22).fontColor(P.muted(this.dark))
        }.width(this.layout.note.width).height(this.layout.note.height).alignItems(HorizontalAlign.Start)
        .position({ x: this.layout.note.x, y: this.layout.note.y })
      }
    }.width(this.layout.contentWidth).height(this.layout.contentHeight)
  }

  private async boot(): Promise<void> {
    if (this.loading || this.context === undefined) return;
    this.loading = true;
    this.dialog = 'loading';
    try {
      const raw = await this.storage.load(this.context);
      if (this.disposed) return;
      const restored = raw.length > 0 && this.engine.restore(raw);
      this.loaded = true;
      this.sync();
      this.hint = raw.length > 0 && !restored ? '上次进度无法恢复，已准备新棋盘' : GLOW_PLAY_HINT;
      this.dialog = this.engine.needsCelebration() ? 'win' : this.engine.ended ? 'end' :
        restored && this.engine.moves > 0 ? 'resume' : this.backgroundPaused ? 'pause' : '';
      if (this.maxTile >= 256) this.reportMilestone();
      if (this.engine.ended && !this.engine.reported) { this.reportEnd(); this.save(); }
    } catch (_) { if (!this.disposed) this.dialog = 'loadError'; }
    finally { this.loading = false; }
  }

  private move(direction: GlowDirection): void {
    if (!this.loaded || this.dialog.length > 0 || this.ended || this.disposed) return;
    if (this.busy) { this.queued = direction; return; }
    const turn = this.engine.move(direction);
    if (!turn.moved) {
      this.audio.play('blocked');
      this.hint = '这个方向暂时不通，换个方向试试';
      this.boardNudge = 3;
      this.getUIContext().animateTo({ duration: 150, curve: Curve.EaseOut }, () => { this.boardNudge = 0; });
      return;
    }
    this.currentTurn = turn;
    this.busy = true;
    this.merged = [];
    this.spawned = 0;
    this.gain = 0;
    this.audio.play('slide');
    this.save(); // The engine already holds the final board, including the new tile.
    const token = ++this.animationToken;
    this.getUIContext().animateTo({ duration: 140, curve: Curve.EaseOut,
      onFinish: () => { if (!this.disposed && token === this.animationToken) this.finishMotion(true); }
    }, () => {
      this.tiles = glowReconcileTiles(this.tiles,
        turn.motions.map((motion: GlowMotion): GlowTile => ({ id: motion.id, value: motion.value, index: motion.to })));
    });
    // Ensure input unlocks even when the OS suppresses an animation callback.
    this.settleTimer = setTimeout(() => {
      this.settleTimer = -1;
      if (!this.disposed && token === this.animationToken) this.finishMotion(true);
    }, 240);
  }

  private finishMotion(effects: boolean): void {
    this.animationToken++;
    if (this.settleTimer !== -1) clearTimeout(this.settleTimer);
    this.settleTimer = -1;
    const turn = this.currentTurn;
    this.currentTurn = undefined;
    const queued = this.queued;
    this.queued = undefined;
    this.busy = false;
    if (!effects) {
      this.spawned = 0;
      this.merged = [];
      this.gain = 0;
      this.boardNudge = 0;
    }
    if (turn === undefined) return;
    this.spawned = effects ? turn.spawned : 0;
    this.turnKey++;
    this.gain = effects ? turn.gain : 0;
    this.merged = effects ? turn.tiles.filter((tile: GlowTile) => turn.merged.includes(tile.id)).map((tile: GlowTile) => tile.index) : [];
    this.sync();
    this.hint = this.ended ? '这一盘结束了，点右上角查看成绩' : GLOW_PLAY_HINT;
    if (this.engine.needsCelebration()) this.dialog = 'win';
    else if (this.ended) this.dialog = 'end';
    if (effects) {
      if (this.engine.needsCelebration()) this.audio.play('win');
      else if (this.ended) this.audio.play('end');
      else if (this.maxTile > turn.previousMax && this.maxTile >= 256) this.audio.play('milestone');
      else if (turn.gain > 0) this.audio.play(turn.gain >= 128 ? 'bright' : 'merge');
    }
    if (this.maxTile > turn.previousMax && this.maxTile >= 256) this.reportMilestone();
    if (this.ended) { this.reportEnd(); this.save(); }
    if (effects && this.dialog.length === 0 && queued !== undefined) this.move(queued);
  }

  private sync(): void {
    if (this.sessionKey !== this.engine.session) this.tiles = [];
    this.sessionKey = this.engine.session;
    this.tiles = glowReconcileTiles(this.tiles, this.engine.tiles);
    this.score = this.engine.score;
    this.moves = this.engine.moves;
    this.maxTile = glowMax(this.engine.tiles);
    this.streak = this.engine.streak;
    this.ended = this.engine.ended;
  }
  private async reportMilestone(): Promise<boolean> {
    const maxTile = glowMax(this.engine.tiles);
    if (maxTile < 256) return true;
    const session = this.engine.session;
    const event: AchievementEvent = { eventId: `${session}:tile-v2:${maxTile}`,
      sessionId: this.engine.session, gameId: 'chicken2048Next', type: 'milestone', occurredAt: Date.now(), isOfficial: true,
      facts: [{ key: 'maxTile', value: maxTile }] };
    const accepted = await this.reportAchievementEvent(event).catch(() => false);
    if (this.engine.session === session) {
      this.achievementSaveFailed = !accepted;
      if (!accepted && !this.disposed) this.saveFailed = true;
    }
    return accepted;
  }
  private async reportEnd(): Promise<boolean> {
    if (!this.engine.ended || this.engine.reported || this.engine.moves === 0) return true;
    if (this.reportingSession === this.engine.session) return false;
    const session = this.engine.session;
    const score = this.engine.score;
    this.reportingSession = session;
    const event: AchievementEvent = { eventId: `${this.engine.session}:session-end`, sessionId: this.engine.session,
      gameId: 'chicken2048Next', type: 'sessionEnd', occurredAt: Date.now(), isOfficial: true,
      facts: [{ key: 'maxTile', value: glowMax(this.engine.tiles) }, { key: 'movesMade', value: this.engine.moves },
        { key: 'score', value: this.engine.score }] };
    if (!await this.save()) { this.reportingSession = ''; return false; }
    const accepted = await this.reportAchievementEvent(event).catch(() => false);
    if (accepted) this.recordScore(score);
    if (this.engine.session === session) {
      this.achievementSaveFailed = !accepted;
      this.engine.reported = accepted;
      await this.save();
    }
    if (this.reportingSession === session) this.reportingSession = '';
    return accepted;
  }
  private async preserveAchievements(): Promise<boolean> {
    if (!await this.save()) return false;
    // A session-end event includes the tile facts too. An unfinished board only
    // publishes milestones, so restarting never counts as completing a game.
    if (this.engine.ended && !this.engine.reported) return this.reportEnd();
    const accepted = await this.reportMilestone();
    if (!this.disposed && accepted) this.saveFailed = false;
    return accepted;
  }
  private present(mode: string): void {
    if (!this.loaded || this.saving) return;
    this.finishMotion(false);
    this.returnDialog = this.dialog;
    this.dialog = mode;
    this.audio.silence();
    this.save();
  }
  private closeDialog(): void {
    if (!this.loaded || this.saving) return;
    if (this.dialog === 'win') { this.engine.continuePlaying(); this.dialog = this.ended ? 'end' : ''; this.save(); }
    else { this.dialog = this.returnDialog; }
    this.returnDialog = '';
    this.backgroundPaused = false;
    this.audio.play('tap');
  }
  private requestRestart(): void {
    if (!this.loaded || this.saving) return;
    if (this.engine.moves > 0 && !this.engine.ended) this.present('restart');
    else this.newRound();
  }
  private async newRound(): Promise<void> {
    if (this.saving) return;
    this.finishMotion(false);
    if (this.engine.ended || glowMax(this.engine.tiles) >= 256) {
      this.saving = true;
      const accepted = await this.preserveAchievements();
      this.saving = false;
      if (!accepted || this.disposed) return;
    }
    // Preserve the score of an abandoned attempt without counting a completed game.
    if (!this.engine.ended && this.engine.moves > 0) this.recordScore(this.engine.score);
    this.engine.reset();
    this.achievementSaveFailed = false;
    this.tiles = [];
    this.spawned = 0;
    this.merged = [];
    this.gain = 0;
    this.sync();
    this.returnDialog = '';
    this.dialog = '';
    this.hint = GLOW_PLAY_HINT;
    this.audio.play('tap');
    this.save();
  }
  private relayout(): void {
    if (this.disposed) return;
    const next = glowLayout(this.pageWidth, this.pageHeight, this.insets, this.creases);
    if (sameGlowLayout(this.layout, next)) return;
    this.finishMotion(false);
    this.layout = next;
    const generation = ++this.layoutGeneration;
    this.getUIContext().postFrameCallback(new GlowReflow(() => {
      if (this.disposed || generation !== this.layoutGeneration) return;
      this.verticalScroll.scrollTo({ xOffset: 0, yOffset: 0, animation: false });
      this.horizontalScroll.scrollTo({ xOffset: 0, yOffset: 0, animation: false });
    }));
  }

  private backgrounded(): void {
    this.backgroundPaused = true;
    this.finishMotion(false);
    this.audio.silence();
    if (this.loaded && this.dialog.length === 0) this.dialog = 'pause';
    this.save();
  }
  themeChanged(): void { this.host.setDark(this.dark); }
  soundChanged(): void { this.audio.setEnabled(this.soundEnabled); }
  exitRequested(): void {
    if (this.saving) return;
    if (!this.loaded) { this.skipSave = true; this.exitToHub(); return; }
    if (['help', 'restart', 'exit'].includes(this.dialog)) this.closeDialog();
    else this.present('exit');
  }
  private async save(): Promise<boolean> {
    if (!this.loaded || this.context === undefined || this.skipSave) return true;
    const ok = await this.storage.save(this.context, this.engine.serialize());
    if (!this.disposed) this.saveFailed = !ok || this.achievementSaveFailed;
    return ok;
  }
  private async retrySave(): Promise<void> {
    if (this.saving) return;
    this.saving = true;
    await this.preserveAchievements();
    if (!this.disposed) this.saving = false;
  }
  private async saveAndExit(): Promise<void> {
    if (this.saving) return;
    this.finishMotion(false);
    this.audio.silence();
    this.saving = true;
    const saved = await this.preserveAchievements();
    if (this.disposed) return;
    this.saving = false;
    if (saved) { this.skipSave = true; this.exitToHub(); }
    else this.dialog = 'exit';
  }
}
