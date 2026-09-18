import { common } from '@kit.AbilityKit';
import { AchievementEvent } from '../../shell/AchievementModule';
import { MineAudio } from './MineAudio';
import { MineBackdrop } from './MineBackdrop';
import { MineBoard } from './MineBoard';
import { MineDifficultyPicker, MineIconButton, MineModeSwitch, MineStats } from './MineControls';
import { MineDialog } from './MineDialog';
import { MineEngine } from './MineEngine';
import { MineCompactMetrics as C, MineCrease, MineInsets, MineLayout, mineLayout, sameMineLayout } from './MineLayout';
import { MINE_ASSETS, MINE_LEVELS, MineLevel, SurveyCell, mineLevel } from './MineModel';
import { MinePalette as P } from './MinePalette';
import { MineStorage } from './MineStorage';
import { MineWindow } from './MineWindow';

@Component
export struct MineGardenPage {
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
  private engine: MineEngine = new MineEngine();
  private audio: MineAudio = new MineAudio();
  private storage: MineStorage = new MineStorage();
  private hostWindow: MineWindow = new MineWindow();
  private context: common.Context | undefined = undefined;
  private timer: number = -1;
  private lastTick: number = 0;
  private lastSave: number = 0;
  private disposed: boolean = false;
  private loaded: boolean = false;
  private loading: boolean = false;
  private backgroundWhileLoading: boolean = false;
  private skipExitSave: boolean = false;
  private returnDialog: string = '';
  private pageWidth: number = 390;
  private pageHeight: number = 844;
  private insets: MineInsets = { top: 24, bottom: 16, left: 0, right: 0 };
  private crease: MineCrease = { x: 0, y: 0, width: 0, height: 0 };
  @State viewport: MineLayout = mineLayout(390, 844, 8, 8, { top: 24, bottom: 16, left: 0, right: 0 });
  @State cells: SurveyCell[] = [];
  @State level: MineLevel = MINE_LEVELS[0];
  @State phase: string = 'ready';
  @State session: string = '';
  @State dialog: string = 'loading';
  @State pendingLevel: string = 'easy';
  @State elapsedMs: number = 0;
  @State bestMs: number = 0;
  @State remaining: number = 10;
  @State opened: number = 0;
  @State flagMode: boolean = false;
  @State score: number = 0;
  @State message: string = '选一格开始 · 第一步与周围八格都安全';
  @State saveFailed: boolean = false;
  @State saving: boolean = false;

  aboutToAppear(): void {
    this.context = this.getUIContext().getHostContext() as common.Context;
    if (this.context === undefined) { this.dialog = 'loadError'; return; }
    this.audio.setEnabled(this.soundEnabled);
    this.hostWindow.setDark(this.dark);
    this.audio.init(this.context);
    this.hostWindow.attach(this.context, (px: number): number => this.getUIContext().px2vp(px),
      (insets: MineInsets, crease: MineCrease) => { this.insets = insets; this.crease = crease; this.relayout(); },
      () => this.backgrounded());
    this.boot();
    this.lastTick = Date.now();
  }

  aboutToDisappear(): void {
    this.captureTime();
    if (!this.skipExitSave) this.save();
    this.disposed = true;
    if (this.timer !== -1) clearInterval(this.timer);
    this.timer = -1;
    this.hostWindow.release();
    this.audio.release();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      MineBackdrop({ dark: this.dark, areaWidth: this.viewport.width, areaHeight: this.viewport.height })
        .position({ x: this.viewport.x, y: this.viewport.y })
      Column({ space: 8 }) {
        this.Header()
        if (this.viewport.wide) {
          Row({ space: this.viewport.gap }) {
            this.BoardCard()
            Scroll() {
              Column({ space: 14 }) {
                Text('庭 院 探 雷').fontSize(12).letterSpacing(4).fontColor(P.accent(this.dark))
                this.Controls()
                this.GuideNote()
              }.width('100%')
            }.width(this.viewport.rail).height(this.viewport.bodyHeight).scrollBar(BarState.Off)
          }.width('100%').justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
        } else {
          Scroll() {
            Column({ space: this.viewport.compact ? C.sectionGap : 12 }) {
              this.Controls()
              this.BoardCard()
            }.width('100%')
          }.width('100%').height(this.viewport.bodyHeight).scrollBar(BarState.Off)
        }
      }.width(this.viewport.width).height(this.viewport.height)
      .padding({ left: this.viewport.gap, right: this.viewport.gap, top: 4, bottom: 8 })
      .position({ x: this.viewport.x, y: this.viewport.y })
      if (this.dialog.length > 0) {
        MineDialog({ dark: this.dark, mode: this.dialog, level: this.level,
          pendingName: mineLevel(this.pendingLevel).name, elapsedMs: this.elapsedMs, score: this.score,
          bestScore: this.bestScore, opened: this.opened, won: this.phase === 'won',
          saving: this.saving, saveFailed: this.saveFailed,
          panelWidth: Math.min(390, this.viewport.width - 20), panelHeight: Math.max(80, this.viewport.height - 20),
          close: () => this.closeDialog(), restart: () => this.requestRestart(),
          confirmRestart: () => this.newRound(this.pendingLevel), leave: () => this.saveAndExit(),
          leaveWithoutSave: () => { this.skipExitSave = true; this.exitToHub(); },
          help: () => this.present('help'), retry: () => this.boot(), retrySave: () => this.retrySave()
        }).width(this.viewport.width).height(this.viewport.height)
          .position({ x: this.viewport.x, y: this.viewport.y })
      }
    }.width('100%').height('100%').backgroundColor(P.bg(this.dark))
    .onAreaChange((oldArea: Area, newArea: Area) => {
      this.pageWidth = Number(newArea.width);
      this.pageHeight = Number(newArea.height);
      this.hostWindow.measure();
      this.relayout();
    })
  }

  @Builder
  Header() {
    Row({ space: 8 }) {
      MineIconButton({ icon: 'back', label: '返回大厅', dark: this.dark, action: () => this.exitRequested() })
      Image($rawfile(`${MINE_ASSETS}scene/logo.svg`)).width(36).height(36).accessibilityLevel('no')
      Column({ space: 2 }) {
        Text('扫雷').fontSize(22).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        Text('庭院探雷').fontSize(10).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      MineIconButton({ icon: this.soundEnabled ? 'sound' : 'muted', label: this.soundEnabled ? '关闭音效' : '开启音效',
        dark: this.dark, action: () => this.updateSound(!this.soundEnabled) })
      MineIconButton({ icon: this.phase === 'won' ? 'trophy' : this.phase === 'lost' ? 'leaf' : 'pause',
        label: this.engine.finished() ? '查看本局结果' : '暂停游戏', dark: this.dark, primary: true,
        action: () => this.present(this.engine.finished() ? 'result' : 'pause') })
    }.width('100%').height(this.viewport.compact ? C.header : 64)
  }

  @Builder
  Controls() {
    Column({ space: this.viewport.compact ? C.controlGap : 8 }) {
      MineStats({ dark: this.dark, compact: this.viewport.compact,
        remaining: this.remaining, elapsedMs: this.elapsedMs, bestMs: this.bestMs })
      MineDifficultyPicker({ dark: this.dark, compact: this.viewport.compact,
        selected: this.level.key, choose: (key: string) => this.chooseLevel(key) })
      if (this.viewport.wide) {
        MineModeSwitch({ dark: this.dark, compact: this.viewport.compact,
          flagMode: this.flagMode, change: (flag: boolean) => this.changeMode(flag) })
        Row({ space: 8 }) {
          MineIconButton({ icon: 'restart', label: '重新开局', dark: this.dark, action: () => this.requestRestart() })
          Text('重新开局').fontSize(12).fontColor(P.muted(this.dark)).layoutWeight(1)
          MineIconButton({ icon: 'help', label: '游玩指南', dark: this.dark, action: () => this.present('help') })
        }.width('100%')
      } else {
        Row({ space: 6 }) {
          MineModeSwitch({ dark: this.dark, compact: this.viewport.compact,
            flagMode: this.flagMode, change: (flag: boolean) => this.changeMode(flag) })
            .layoutWeight(1)
          MineIconButton({ icon: 'restart', label: '重新开局', dark: this.dark, action: () => this.requestRestart() })
          MineIconButton({ icon: 'help', label: '游玩指南', dark: this.dark, action: () => this.present('help') })
        }.width('100%')
      }
    }.width('100%').geometryTransition('mine-garden-controls', { follow: true })
  }

  @Builder
  BoardCard() {
    Column({ space: this.viewport.compact ? 6 : 8 }) {
      Row() {
        Column({ space: 3 }) {
          Text(this.level.caption).fontSize(16).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
          Text(`${this.level.cols} × ${this.level.rows} 格 · ${this.level.mines} 颗雷`)
            .fontSize(10).fontColor(P.muted(this.dark))
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Text(`${this.opened} / ${this.level.rows * this.level.cols - this.level.mines}`)
          .fontSize(12).fontFamily('monospace').fontColor(P.accent(this.dark))
        Image($rawfile(P.icon('leaf', this.dark, 'accent'))).width(17).height(17).margin({ left: 7 }).accessibilityLevel('no')
      }.width('100%').height(this.viewport.compact ? 32 : 38)
      MineBoard({ dark: this.dark, cells: this.cells, rows: this.level.rows, cols: this.level.cols,
        cellSize: this.viewport.cell, lost: this.phase === 'lost', locked: this.dialog.length > 0 || this.engine.finished(),
        scrollX: this.viewport.scrollX, scrollY: this.viewport.scrollY,
        resetKey: this.session, tap: (index: number) => this.act(index, false), hold: (index: number) => this.act(index, true)
      }).width('100%').height(Math.max(1, this.viewport.boardCardHeight - (this.viewport.compact ? C.cardContent : 110)))
        .opacity(this.dialog.length > 0 ? 0 : 1)
      Row({ space: 6 }) {
        Image($rawfile(P.icon(this.viewport.scrolls ? 'pan' : 'leaf', this.dark, 'accent')))
          .width(13).height(13).accessibilityLevel('no')
        Text(this.saveFailed ? '进度未保存 · 暂停后可重试' : this.message)
          .fontSize(11).fontColor(this.saveFailed ? P.danger(this.dark) : P.muted(this.dark))
          .maxLines(2).layoutWeight(1)
      }.height(this.viewport.compact ? 24 : 32).width('100%')
    }.padding(this.viewport.compact ? C.cardPadding : 12)
    .width(this.viewport.boardCardWidth).height(this.viewport.boardCardHeight).borderRadius(26)
    .backgroundColor(P.paper(this.dark)).border({ width: 1, color: P.line(this.dark), radius: 26 }).clip(true)
    .shadow({ radius: 18, color: this.dark ? '#22000000' : '#0D647344', offsetY: 6 })
    .geometryTransition('mine-garden-board', { follow: true })
  }

  @Builder
  GuideNote() {
    Column({ space: 9 }) {
      Text('慢慢来，线索就在身边').fontSize(16).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
      Text(`数字是周围八格的雷数。\n长按插旗，点数字尝试连开。\n${this.viewport.scrolls ? '拖动可以查看完整棋盘。' : '棋盘随窗口自动调整大小。'}`)
        .fontSize(12).lineHeight(23).fontColor(P.muted(this.dark))
    }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
  }

  private async boot(): Promise<void> {
    const context = this.context;
    if (context === undefined || this.loading) return;
    this.loading = true;
    this.dialog = 'loading';
    try {
      const raw = await this.storage.load(context);
      if (this.disposed) return;
      const restored = raw.length > 0 && this.engine.restore(raw);
      this.loaded = true;
      this.sync();
      this.relayout();
      this.dialog = restored && this.phase === 'playing' ? 'resume' :
        restored && this.engine.finished() ? 'result' : this.backgroundWhileLoading ? 'pause' : '';
      if (raw.length > 0 && !restored) this.message = '上次进度无法恢复 · 已准备新的小径';
      else if (restored) this.message = this.defaultMessage();
      this.lastTick = Date.now();
      this.settle();
      this.syncClock();
      if (this.engine.finished()) this.save();
    } catch (_) {
      if (!this.disposed) this.dialog = 'loadError';
    } finally { this.loading = false; }
  }

  private act(index: number, hold: boolean): void {
    if (!this.loaded || this.dialog.length > 0 || this.engine.finished()) return;
    this.captureTime();
    const result = hold || this.flagMode && !this.engine.cells[index].open ? this.engine.flag(index) : this.engine.open(index);
    if (result === 'none') return;
    if (result === 'limit' || result === 'mismatch') {
      this.message = result === 'limit' ? '旗子已用完，先撤下一面再标记' : '周围旗数与数字一致后，才能连开';
      this.audio.play('blocked');
      return;
    }
    this.sync();
    this.message = result === 'flood' ? '一片空地展开了 · 留意边缘的数字' : this.defaultMessage();
    this.audio.play(result === 'won' ? 'win' : result === 'lost' ? 'lose' : result);
    this.settle();
    this.syncClock();
    this.save();
  }

  private async settle(): Promise<boolean> {
    if (!this.engine.finished() || this.engine.reported) return true;
    if (this.reportingSession === this.engine.session) return false;
    const session = this.engine.session;
    const score = this.engine.score();
    const won = this.engine.phase === 'won';
    this.reportingSession = session;
    const event: AchievementEvent = {
      eventId: `${this.engine.session}:session-end`, sessionId: this.engine.session, gameId: 'minesweeperNext',
      type: 'sessionEnd', occurredAt: Date.now(), isOfficial: true,
      facts: [ { key: 'won', value: won ? 1 : 0 },
        { key: 'elapsedSec', value: Math.ceil(this.engine.elapsedMs / 1000) },
        // Captured by the engine before it automatically flags the remaining mines.
        { key: 'manualAllMinesFlagged', value: this.engine.manualAllFlags ? 1 : 0 },
        { key: 'hasEverFlaggedNonMine', value: this.engine.everWrongFlag ? 1 : 0 } ]
    };
    this.returnDialog = '';
    this.dialog = 'result';
    // Persist the unacknowledged result before publishing it, so reopening can retry.
    if (!await this.save()) { this.reportingSession = ''; return false; }
    const accepted = await this.reportAchievementEvent(event).catch(() => false);
    if (accepted && won) this.recordScore(score);
    if (this.engine.session === session) {
      this.achievementSaveFailed = !accepted;
      this.engine.reported = accepted;
      await this.save();
    }
    if (this.reportingSession === session) this.reportingSession = '';
    return accepted;
  }

  private sync(): void {
    this.cells = this.engine.copyCells();
    this.level = this.engine.level;
    this.phase = this.engine.phase;
    this.session = this.engine.session;
    this.elapsedMs = Math.floor(this.engine.elapsedMs / 1000) * 1000;
    this.bestMs = this.engine.bestTime();
    this.remaining = this.level.mines - this.engine.flags();
    this.opened = this.engine.opened();
    this.flagMode = this.engine.flagMode;
    this.score = this.engine.score();
  }

  private defaultMessage(): string {
    if (this.phase === 'won') return '小径已全部探明 · 点右上角查看成绩';
    if (this.phase === 'lost') return '雷区已揭开 · 点右上角再来一局';
    if (this.phase === 'ready') return '选一格开始 · 第一步与周围八格都安全';
    return this.viewport.scrolls ? '拖动查看大棋盘 · 长按插旗 · 点数字连开' : '长按插旗 · 周围旗数足够时，点数字连开';
  }

  private captureTime(): void {
    const now = Date.now();
    if (this.loaded && this.dialog.length === 0 && !this.disposed) this.engine.advance(now - this.lastTick);
    this.lastTick = now;
    const displayed = Math.floor(this.engine.elapsedMs / 1000) * 1000;
    if (this.elapsedMs !== displayed) this.elapsedMs = displayed;
  }

  private syncClock(): void {
    const running = this.loaded && !this.disposed && this.dialog.length === 0 && this.phase === 'playing';
    if (running && this.timer === -1) this.timer = setInterval(() => this.tick(), 1000);
    else if (!running && this.timer !== -1) { clearInterval(this.timer); this.timer = -1; }
  }

  private tick(): void {
    this.captureTime();
    if (this.dialog.length === 0 && this.phase === 'playing' && Date.now() - this.lastSave > 5000) this.save();
  }

  private present(mode: string): void {
    if (!this.loaded || this.saving) return;
    this.captureTime();
    this.returnDialog = this.dialog;
    this.audio.silence();
    this.dialog = mode;
    this.syncClock();
    this.save();
  }

  private closeDialog(): void {
    if (!this.loaded || this.saving) return;
    const previous = this.returnDialog;
    this.returnDialog = '';
    this.dialog = previous;
    this.lastTick = Date.now();
    this.syncClock();
    this.audio.play('tap');
  }

  private requestRestart(): void {
    if (!this.loaded || this.saving) return;
    this.pendingLevel = this.level.key;
    if (this.phase === 'ready' && this.engine.flags() === 0 || this.engine.finished()) this.newRound(this.pendingLevel);
    else this.present('restart');
  }

  private chooseLevel(key: string): void {
    if (key === this.level.key || !this.loaded || this.saving) return;
    this.pendingLevel = key;
    if (this.phase === 'ready' && this.engine.flags() === 0 || this.engine.finished()) this.newRound(key);
    else this.present('difficulty');
  }

  private async newRound(key: string): Promise<void> {
    if (this.saving) return;
    if (this.engine.finished()) {
      this.saving = true;
      const accepted = await this.settle();
      this.saving = false;
      if (!accepted || this.disposed) return;
    }
    this.audio.silence();
    this.engine.reset(key);
    this.sync();
    this.relayout();
    this.returnDialog = '';
    this.dialog = '';
    this.lastTick = Date.now();
    this.message = this.defaultMessage();
    this.syncClock();
    this.audio.play('tap');
    this.save();
  }

  private changeMode(flag: boolean): void {
    if (!this.loaded || this.dialog.length > 0) return;
    this.engine.flagMode = flag;
    this.flagMode = flag;
    this.message = flag ? '插旗模式 · 轻点标记，再点撤旗' : this.defaultMessage();
    this.audio.play('tap');
    this.save();
  }

  private relayout(): void {
    if (this.disposed) return;
    const next = mineLayout(this.pageWidth, this.pageHeight, this.level.rows, this.level.cols, this.insets, this.crease);
    if (sameMineLayout(this.viewport, next)) return;
    if (!this.loaded || this.loading) {
      this.viewport = next;
      return;
    }
    // One native transition per actual layout change. No per-frame JS work or
    // engine reset; duplicate window/safe-area events do not restart it.
    this.getUIContext().animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
      this.viewport = next;
    });
  }

  private backgrounded(): void {
    this.backgroundWhileLoading = true;
    this.captureTime();
    if (this.loaded && this.dialog.length === 0 && !this.engine.finished()) this.dialog = 'pause';
    this.syncClock();
    this.audio.silence();
    this.save();
  }

  soundChanged(): void { this.audio.setEnabled(this.soundEnabled); }
  themeChanged(): void { this.hostWindow.setDark(this.dark); }

  exitRequested(): void {
    if (this.saving) return;
    if (!this.loaded) { this.skipExitSave = true; this.exitToHub(); return; }
    if (['help', 'difficulty', 'restart', 'exit'].includes(this.dialog)) this.closeDialog();
    else this.present('exit');
  }

  private async save(): Promise<boolean> {
    if (!this.loaded || this.context === undefined || this.skipExitSave) return true;
    this.lastSave = Date.now();
    const saved = await this.storage.save(this.context, this.engine.serialize());
    if (!this.disposed) this.saveFailed = !saved || this.achievementSaveFailed;
    return saved;
  }

  private async retrySave(): Promise<void> {
    if (this.saving) return;
    this.saving = true;
    if (await this.save()) await this.settle();
    if (!this.disposed) this.saving = false;
  }

  private async saveAndExit(): Promise<void> {
    if (this.saving) return;
    this.captureTime();
    this.audio.silence();
    this.saving = true;
    if (await this.save() && await this.settle()) {
      if (!this.disposed) { this.skipExitSave = true; this.exitToHub(); }
    } else if (!this.disposed) {
      this.dialog = 'exit';
    }
    if (!this.disposed) this.saving = false;
  }
}
