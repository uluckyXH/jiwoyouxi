import { common } from '@kit.AbilityKit';
import { AchievementEvent } from '../../shell/AchievementModule';
import { TangramAudio } from './TangramAudio';
import { TangramBoard } from './TangramBoard';
import { TangramButton } from './TangramControls';
import { TangramEngine } from './TangramEngine';
import { TangramPoint } from './TangramGeometry';
import { TangramCrease, TangramInsets, TangramLayout, tangramLayout } from './TangramLayout';
import { TANGRAM_LEVELS, TangramLevel, tangramLevel } from './TangramLevels';
import { TANGRAM_ASSETS, TANGRAM_LOGO, TangramPalette as P } from './TangramPalette';
import { TangramStorage } from './TangramStorage';
import { TangramWindow } from './TangramWindow';

const PIECE_NAMES: string[] = ['杏黄大三角', '蜜桃大三角', '青绿中三角', '晴蓝小三角', '香芋小三角', '奶黄正方形', '雾蓝平行四边形'];

@Component
export struct TangramPage {
  @Prop @Watch('themeChanged') dark: boolean = false;
  @Prop @Watch('soundChanged') soundEnabled: boolean = true;
  @Prop @Watch('exitRequested') exitRequest: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  reportAchievementEvent: (event: AchievementEvent) => Promise<boolean> = async () => false;
  private engine: TangramEngine = new TangramEngine();
  private storage: TangramStorage = new TangramStorage();
  private audio: TangramAudio = new TangramAudio();
  private host: TangramWindow = new TangramWindow();
  private context: common.Context | undefined = undefined;
  private loaded: boolean = false;
  private loading: boolean = false;
  private disposed: boolean = false;
  private reporting: boolean = false;
  private skipSave: boolean = false;
  private switchingTo: string = '';
  private insets: TangramInsets = { top: 24, bottom: 16, left: 0, right: 0 };
  private creases: TangramCrease[] = [];
  private vertical: Scroller = new Scroller();
  private horizontal: Scroller = new Scroller();
  @State pageWidth: number = 390;
  @State pageHeight: number = 844;
  @State layout: TangramLayout = tangramLayout(390, 844, { top: 24, bottom: 16, left: 0, right: 0 });
  @State revision: number = 0;
  @State selected: number = -1;
  @State levelId: string = TANGRAM_LEVELS[0].id;
  @State collected: string[] = [];
  @State placed: number = 0;
  @State moves: number = 0;
  @State undoAvailable: boolean = false;
  @State guide: boolean = true;
  @State solved: boolean = false;
  @State fine: boolean = false;
  @State dragging: boolean = false;
  @State dialog: string = 'loading';
  @State status: string = '把七块小拼板，送进浅绿色轮廓。';
  @State saving: boolean = false;
  @State saveFailed: boolean = false;
  @State achievementPending: boolean = false;

  aboutToAppear(): void {
    this.context = this.getUIContext().getHostContext() as common.Context;
    if (this.context === undefined) { this.dialog = 'loadError'; return; }
    this.audio.setEnabled(this.soundEnabled); this.audio.init(this.context);
    this.host.setDark(this.dark);
    this.host.attach(this.context, (px: number): number => this.getUIContext().px2vp(px),
      (insets: TangramInsets, creases: TangramCrease[]) => { this.insets = insets; this.creases = creases; this.relayout(); },
      () => this.backgrounded());
    this.boot();
  }

  aboutToDisappear(): void {
    this.cancelDrag();
    if (!this.skipSave) this.save();
    this.disposed = true; this.host.release(); this.audio.release();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(`${TANGRAM_ASSETS}scene/branches_${this.dark ? 'dark' : 'light'}.svg`))
        .width(Math.min(260, this.pageWidth * .55)).height(Math.min(360, this.pageHeight * .65))
        .objectFit(ImageFit.Contain).position({ x: this.pageWidth - Math.min(260, this.pageWidth * .55),
          y: this.pageHeight - Math.min(360, this.pageHeight * .65) }).opacity(.7).hitTestBehavior(HitTestMode.None)
      Column({ space: 8 }) {
        this.Header()
        Scroll(this.horizontal) {
          Scroll(this.vertical) {
            this.Workspace()
          }.width(this.layout.contentWidth).height(this.layout.body).scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Auto).enableScrollInteraction(!this.dragging).align(Alignment.TopStart)
        }.width('100%').height(this.layout.body).scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Auto).enableScrollInteraction(!this.dragging).align(Alignment.TopStart)
      }.width(this.layout.width).height(this.layout.height).padding({ left: this.layout.gap, right: this.layout.gap, top: 4 })
      .position({ x: this.layout.x, y: this.layout.y }).clip(true)
      .enabled(this.dialog.length === 0).accessibilityLevel(this.dialog.length === 0 ? 'auto' : 'no-hide-descendants')
      if (this.dialog.length > 0) this.Dialog()
    }.width('100%').height('100%').backgroundColor(P.bg(this.dark))
    .onAreaChange((old: Area, area: Area) => {
      this.pageWidth = Number(area.width); this.pageHeight = Number(area.height); this.host.measure(); this.relayout();
    })
  }

  @Builder
  Header() {
    Row({ space: 8 }) {
      TangramButton({ dark: this.dark, icon: 'back', label: '保存并返回大厅', compact: true,
        action: () => this.exitRequested() }).width(46)
      if (this.layout.width >= 350) Image($rawfile(TANGRAM_LOGO)).width(36).height(36).accessibilityLevel('no')
      Column({ space: 1 }) {
        Text('七巧板').fontSize(24).minFontSize(16).maxFontSize(24).maxLines(1).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        Text('七巧小院 · 慢慢拼').fontSize(11).maxLines(1).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      TangramButton({ dark: this.dark, icon: this.soundEnabled ? 'sound' : 'muted',
        label: this.soundEnabled ? '关闭音效' : '开启音效', compact: true,
        action: () => this.updateSound(!this.soundEnabled) }).width(46)
    }.width('100%').height(50)
  }

  @Builder
  Workspace() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.LevelCard()
      TangramBoard({ engine: this.engine, dark: this.dark, edge: this.layout.board.width,
        revision: this.revision, active: this.dialog.length === 0 && !this.solved,
        input: (phase: string, p: TangramPoint) => this.input(phase, p)
      }).position({ x: this.layout.board.x, y: this.layout.board.y })
      this.Tools()
    }.width(this.layout.contentWidth)
    .height(this.layout.contentHeight + (this.fine && !this.layout.wide ? 174 : 0))
  }

  @Builder
  LevelCard() {
    Row({ space: 9 }) {
      Image($rawfile(`${TANGRAM_ASSETS}levels/${this.levelId}.svg`)).width(54).height(54).accessibilityLevel('no')
      Column({ space: 4 }) {
        Text(tangramLevel(this.levelId).title).fontSize(18).minFontSize(12).maxFontSize(18).maxLines(1)
          .fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
        Text(`已放好 ${this.placed} / 7 块 · 图鉴 ${this.collected.length} / ${TANGRAM_LEVELS.length}`)
          .fontSize(11).maxLines(1).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      if (this.solved) {
        Image($rawfile(P.icon('check', this.dark))).width(23).height(23).accessibilityText('已完成')
      }
    }.width(this.layout.wide ? this.layout.tools.width : this.layout.contentWidth).height(66).padding({ left: 8, right: 12 })
    .backgroundColor(P.paper(this.dark)).borderRadius(22).border({ width: 1, color: P.line(this.dark) })
    .position({ x: this.layout.wide ? this.layout.tools.x : 0, y: 0 })
  }

  @Builder
  Tools() {
    Column({ space: 8 }) {
      Text(this.saveFailed ? '进度暂未保存，请点这里重试' : this.status).fontSize(11).lineHeight(17).maxLines(2)
        .fontColor(this.saveFailed ? P.danger(this.dark) : P.muted(this.dark)).width('100%').height(36)
        .onClick(() => { if (this.saveFailed) this.save().then(() => this.reportPending()); })
      if (this.solved) {
        TangramButton({ dark: this.dark, primary: true, icon: 'next', label: '下一幅小风景',
          buttonHeight: this.layout.wide ? 62 : 48, action: () => this.nextLevel() })
        TangramButton({ dark: this.dark, icon: 'album', label: '看看我的图鉴', action: () => this.present('album') })
        TangramButton({ dark: this.dark, icon: 'reset', label: '再拼一次', action: () => this.present('reset') })
      } else {
        Row({ space: 7 }) {
          TangramButton({ dark: this.dark, icon: 'rotate-left', label: '逆转', active: this.selected >= 0,
            buttonHeight: this.layout.wide ? 60 : 48, action: () => this.rotatePiece(-1) }).layoutWeight(1)
          TangramButton({ dark: this.dark, icon: 'rotate-right', label: '旋转', active: this.selected >= 0,
            buttonHeight: this.layout.wide ? 60 : 48, action: () => this.rotatePiece(1) }).layoutWeight(1)
          TangramButton({ dark: this.dark, icon: 'flip', label: '翻面', active: this.selected >= 0,
            buttonHeight: this.layout.wide ? 60 : 48, action: () => this.rotatePiece(0, true) }).layoutWeight(1)
        }.width('100%')
        Row({ space: 7 }) {
          TangramButton({ dark: this.dark, icon: 'undo', label: '撤销', active: this.undoAvailable,
            action: () => { if (this.engine.undo()) this.finishAction('turn'); } }).layoutWeight(1)
          TangramButton({ dark: this.dark, icon: 'hint', label: '提示一块', action: () => this.hint() }).layoutWeight(1)
          TangramButton({ dark: this.dark, icon: 'guide', label: this.guide ? '藏线' : '辅助线',
            action: () => { this.engine.toggleGuide(); this.finishAction('tap'); } }).layoutWeight(1)
        }.width('100%')
        Row({ space: 7 }) {
          TangramButton({ dark: this.dark, icon: 'album', label: '图鉴', action: () => this.present('album') }).layoutWeight(1)
          TangramButton({ dark: this.dark, icon: 'tray', label: this.fine ? '收起微调' : '选板微调',
            action: () => { this.cancelDrag(); this.fine = !this.fine; } }).layoutWeight(1)
          TangramButton({ dark: this.dark, icon: 'help', label: '怎么玩', action: () => this.present('help') }).layoutWeight(1)
        }.width('100%')
        if (this.fine) this.FineControls()
      }
      if (this.layout.wide && !this.fine) {
        Column({ space: 4 }) {
          Image($rawfile(TANGRAM_LOGO)).width(88).height(88).accessibilityLevel('no')
          Text('七块小拼板，一院好风景').fontSize(14).fontWeight(FontWeight.Medium).fontColor(P.accent(this.dark))
          Text(tangramLevel(this.levelId).caption).fontSize(11).lineHeight(19).textAlign(TextAlign.Center).fontColor(P.muted(this.dark))
        }.width('100%').padding({ top: 16 })
      }
    }.width(this.layout.wide ? this.layout.tools.width : this.layout.contentWidth)
    .position({ x: this.layout.wide ? this.layout.tools.x : 0,
      y: this.layout.wide ? 82 : this.layout.board.y + this.layout.board.height + 8 })
  }

  @Builder
  FineControls() {
    Column({ space: 7 }) {
      Text(this.selected >= 0 ? PIECE_NAMES[this.selected] : '先选一块，再点轮廓或微调方向').fontSize(11)
        .fontColor(P.muted(this.dark)).width('100%').maxLines(1)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach([0, 1, 2, 3, 4, 5, 6], (id: number) => {
          Button({ type: ButtonType.Normal }) {
            Image($rawfile(`${TANGRAM_ASSETS}pieces/${id}.svg`)).width(32).height(32)
          }.width('25%').height(44).borderRadius(12)
          .backgroundColor(this.selected === id ? P.soft(this.dark) : P.paper(this.dark))
          .border({ width: 1, color: this.selected === id ? P.accent(this.dark) : P.line(this.dark) })
          .accessibilityText(`选择${PIECE_NAMES[id]}`).onClick(() => { this.engine.select(id); this.refresh(); })
        }, (id: number): string => `${id}`)
      }.width('100%')
      Row({ space: 5 }) {
        ForEach(['left', 'up', 'down', 'right'], (direction: string) => {
          TangramButton({ dark: this.dark, icon: direction, label: `微调${direction === 'left' ? '向左' : direction === 'right' ? '向右' : direction === 'up' ? '向上' : '向下'}`,
            compact: true, active: this.selected >= 0, buttonHeight: 44,
            action: () => this.nudge(direction) }).layoutWeight(1)
        }, (direction: string): string => direction)
        TangramButton({ dark: this.dark, icon: 'tray', label: '放回托盘', compact: true, active: this.selected >= 0,
          buttonHeight: 44, action: () => { this.engine.returnSelected(); this.finishAction('tap'); } }).layoutWeight(1)
      }.width('100%')
    }.width('100%').padding(8).backgroundColor(P.paper(this.dark)).borderRadius(18)
  }

  @Builder
  Dialog() {
    Stack() {
      Column() {}.width('100%').height('100%').backgroundColor('#171D1766')
      Scroll() {
        Column({ space: 16 }) {
          Row() {
            Text(this.dialogTitle()).fontSize(23).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).layoutWeight(1)
            if (this.loaded && this.dialog !== 'loading') {
              TangramButton({ dark: this.dark, icon: 'close', label: '关闭', compact: true, buttonHeight: 44,
                action: () => { this.dialog = ''; } }).width(44)
            }
          }.width('100%')
          if (this.dialog === 'album') this.Album()
          else if (this.dialog === 'help') this.Guide()
          else if (this.dialog === 'complete') this.Completion()
          else if (this.dialog === 'loading') {
            Image($rawfile(TANGRAM_LOGO)).width(96).height(96)
            Text('正在找回你的小拼板…').fontSize(14).fontColor(P.muted(this.dark))
          } else if (this.dialog === 'loadError') {
            Text('暂时没能读到进度，已有作品会保留。可以重试或返回大厅。').fontSize(14).lineHeight(23).fontColor(P.muted(this.dark))
            TangramButton({ dark: this.dark, primary: true, icon: 'reset', label: '重新读取', action: () => this.boot() })
            TangramButton({ dark: this.dark, icon: 'back', label: '返回大厅', action: () => { this.skipSave = true; this.exitToHub(); } })
          } else if (this.dialog === 'saveError') {
            Text('这次进度还没有保存成功，重试成功后再返回，就能接着拼。').fontSize(14).lineHeight(23).fontColor(P.muted(this.dark))
            TangramButton({ dark: this.dark, primary: true, icon: 'reset', label: this.saving ? '正在保存…' : '重试保存并返回',
              active: !this.saving, action: () => this.saveAndExit() })
            TangramButton({ dark: this.dark, icon: 'back', label: '继续拼图', action: () => { this.dialog = ''; } })
          } else {
            Text(this.dialog === 'switch' ? '切换后，这一幅会重新摆放。已完成的图鉴和成就都会保留。' : '把这一幅的七块拼板放回托盘，重新试一试。已完成的作品会保留。')
              .fontSize(14).lineHeight(23).fontColor(P.muted(this.dark))
            TangramButton({ dark: this.dark, primary: true, icon: 'reset', label: this.dialog === 'switch' ? '切换这一幅' : '重新摆放',
              action: () => this.startLevel(this.dialog === 'switch' ? this.switchingTo : this.levelId) })
            TangramButton({ dark: this.dark, icon: 'back', label: '继续这一幅', action: () => { this.dialog = ''; } })
          }
        }.width('100%').padding(22)
      }.width(Math.max(1, Math.min(460, this.layout.width - 24))).constraintSize({ maxHeight: Math.max(1, this.layout.height - 24) })
      .scrollBar(BarState.Auto).backgroundColor(P.paper(this.dark)).borderRadius(28)
    }.width(this.layout.width).height(this.layout.height).position({ x: this.layout.x, y: this.layout.y })
  }

  @Builder
  Album() {
    Text(`已收集 ${this.collected.length} / ${TANGRAM_LEVELS.length} 幅 · 所有关卡都可以尝试`)
      .fontSize(12).fontColor(P.muted(this.dark)).width('100%')
    ForEach(TANGRAM_LEVELS, (level: TangramLevel) => {
      Button({ type: ButtonType.Normal }) {
        Row({ space: 10 }) {
          Image($rawfile(`${TANGRAM_ASSETS}levels/${level.id}.svg`)).width(64).height(64).accessibilityLevel('no')
          Column({ space: 5 }) {
            Text(level.title).fontSize(16).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
            Text(this.collected.includes(level.id) ? '已收集 · 可以再拼一次' : level.guide ? '入门图案 · 默认显示辅助线' : '轮廓挑战 · 随时可开启辅助线')
              .fontSize(11).maxLines(2).fontColor(P.muted(this.dark))
          }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          Image($rawfile(P.icon(this.collected.includes(level.id) ? 'check' : 'next', this.dark))).width(20).height(20)
        }.width('100%').padding(10)
      }.width('100%').backgroundColor(P.soft(this.dark)).borderRadius(18)
      .accessibilityText(`${level.title}${this.collected.includes(level.id) ? '，已完成' : '，可开始'}`)
      .onClick(() => this.chooseLevel(level.id))
    }, (level: TangramLevel): string => level.id)
  }

  @Builder
  Guide() {
    Image($rawfile(`${TANGRAM_ASSETS}scene/guide.svg`)).width('100%').height(110).objectFit(ImageFit.Contain).accessibilityLevel('no')
    this.GuideLine('01 · 把拼板送进轮廓', '直接拖动彩色拼板；也可以先点选一块，再点击轮廓附近。靠近正确边缘，松手会轻轻吸附。')
    this.GuideLine('02 · 转一转，翻一面', '逆转和旋转每次转 45°。翻面能改变平行四边形的朝向；选板微调里还有方向按钮和放回托盘。')
    this.GuideLine('03 · 七块刚刚好', '七块全部填满轮廓，不能重叠或伸出轮廓。两块同样大的三角形可以互换，其他合法拼法也算完成。')
    this.GuideLine('卡住了，也没关系', '提示一块会标出一个参考位置，仍需自己转动和摆放。辅助线、撤销都能随时使用，不影响图鉴和成就；没有时间和步数限制。')
    TangramButton({ dark: this.dark, primary: true, icon: 'check', label: '知道了，慢慢拼', action: () => { this.dialog = ''; } })
    TangramButton({ dark: this.dark, icon: 'reset', label: '重新摆放这一幅', action: () => this.present('reset') })
  }

  @Builder
  GuideLine(title: string, body: string) {
    Column({ space: 5 }) {
      Text(title).fontSize(15).fontWeight(FontWeight.Medium).fontColor(P.accent(this.dark)).width('100%')
      Text(body).fontSize(13).lineHeight(22).fontColor(P.muted(this.dark)).width('100%')
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  Completion() {
    Image($rawfile(`${TANGRAM_ASSETS}levels/${this.levelId}.svg`)).width(170).height(170).accessibilityLevel('no')
    Text(tangramLevel(this.levelId).caption).fontSize(14).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
    Text(`这幅小风景已加入图鉴 · ${this.collected.length} / ${TANGRAM_LEVELS.length}`)
      .fontSize(14).fontWeight(FontWeight.Medium).fontColor(P.accent(this.dark))
    if (this.saveFailed || this.achievementPending) {
      Text(this.saveFailed ? '进度暂未保存，点这里重试。' : '成就正在等待保存，点这里重试；已拼好的作品会保留。')
        .fontSize(12).fontColor(P.danger(this.dark)).onClick(() => { this.save().then(() => this.reportPending()); })
    }
    TangramButton({ dark: this.dark, primary: true, icon: 'next', label: '再拼一幅', action: () => this.nextLevel() })
    TangramButton({ dark: this.dark, icon: 'album', label: '打开小院图鉴', action: () => this.present('album') })
  }

  private dialogTitle(): string {
    if (this.dialog === 'album') return '小院图鉴';
    if (this.dialog === 'help') return '七块拼板，慢慢来';
    if (this.dialog === 'complete') return '小风景拼好啦';
    if (this.dialog === 'loadError') return '稍等一下';
    if (this.dialog === 'saveError') return '进度还没放好';
    if (this.dialog === 'switch') return '换一幅小风景？';
    if (this.dialog === 'reset') return '重新摆放？';
    return '欢迎来到七巧小院';
  }

  private async boot(): Promise<void> {
    if (this.loading || this.context === undefined) return;
    this.loading = true; this.dialog = 'loading';
    try {
      const raw = await this.storage.load(this.context);
      if (this.disposed) return;
      if (!this.engine.restore(raw)) { this.dialog = 'loadError'; return; }
      this.loaded = true; this.refresh(); this.dialog = raw.length === 0 ? 'help' : '';
      this.reportPending();
    } catch (_) { if (!this.disposed) this.dialog = 'loadError'; }
    finally { this.loading = false; }
  }

  private refresh(): void {
    this.revision += 1; this.selected = this.engine.selected; this.levelId = this.engine.levelId;
    this.collected = this.engine.collected.slice(); this.placed = this.engine.placed(); this.moves = this.engine.moves;
    this.undoAvailable = this.engine.history.length > 0; this.guide = this.engine.guide; this.solved = this.engine.solved;
    this.achievementPending = this.engine.pending.length > 0;
  }

  private input(phase: string, p: TangramPoint): void {
    if (this.dialog.length > 0 || this.solved) return;
    if (phase === 'begin') {
      this.dragging = this.engine.begin(p);
      if (this.dragging) { this.audio.play('pick'); this.selected = this.engine.selected; this.revision += 1; }
    } else if (phase === 'drag' && this.dragging) {
      this.engine.drag(p); this.revision += 1;
    } else if (phase === 'end' && this.dragging) {
      this.engine.drag(p); const snapped = this.engine.end(); this.dragging = false;
      this.finishAction(snapped ? 'snap' : 'tap');
    } else if (phase === 'cancel') this.cancelDrag();
  }

  private rotatePiece(turn: number, flip: boolean = false): void { this.engine.transform(turn, flip); this.finishAction('turn'); }
  private nudge(direction: string): void {
    this.engine.nudge(direction === 'left' ? -.1 : direction === 'right' ? .1 : 0,
      direction === 'up' ? -.1 : direction === 'down' ? .1 : 0);
    this.finishAction('tap');
  }
  private hint(): void {
    const shown = this.engine.showHint(); this.finishAction('hint');
    this.status = shown ? '虚线标出这块的参考位置，转好朝向再放进去。' : '参考位置被挡住了，试着挪开一点，或打开辅助线。';
  }

  private finishAction(sound: string): void {
    const justSolved = this.engine.solved && !this.solved;
    this.refresh();
    this.status = this.solved ? '七块刚刚好，小风景已经收进图鉴。' : this.selected >= 0 ?
      `${PIECE_NAMES[this.selected]} · 点击或拖动摆放` : '把七块小拼板，送进浅绿色轮廓。';
    this.audio.play(justSolved ? 'win' : sound);
    if (justSolved) { this.dialog = 'complete'; this.recordScore(this.collected.length); }
    this.save().then((ok: boolean) => { if (ok) this.reportPending(); });
  }

  private async save(): Promise<boolean> {
    if (!this.loaded || this.context === undefined || this.skipSave) return false;
    const ok = await this.storage.save(this.context, this.engine.serialize());
    if (!this.disposed) this.saveFailed = !ok;
    return ok;
  }

  private async reportPending(): Promise<void> {
    if (this.reporting || !this.loaded || this.disposed) return;
    this.reporting = true;
    try {
      while (this.engine.pending.length > 0) {
        // Persist the recoverable event before asking the shared service to commit it.
        if (!await this.save()) break;
        const event = this.engine.pending[0];
        let acknowledged = false;
        try { acknowledged = await this.reportAchievementEvent(event); } catch (_) {}
        if (!acknowledged) break;
        this.engine.acknowledge(event.eventId);
        await this.save();
        if (this.disposed) break;
      }
    } finally {
      this.reporting = false;
      if (!this.disposed) this.achievementPending = this.engine.pending.length > 0;
    }
  }

  private cancelDrag(): void {
    this.engine.cancelDrag(); this.dragging = false; this.revision += 1;
  }
  private present(mode: string): void { this.cancelDrag(); this.dialog = mode; this.audio.play('tap'); }
  private chooseLevel(id: string): void {
    if (id === this.levelId && !this.solved) { this.dialog = ''; return; }
    if (!this.solved && this.moves > 0) { this.switchingTo = id; this.present('switch'); return; }
    this.startLevel(id);
  }
  private startLevel(id: string): void {
    this.cancelDrag(); this.engine.start(id); this.refresh(); this.dialog = ''; this.fine = false;
    this.status = '把七块小拼板，送进浅绿色轮廓。'; this.audio.play('tap'); this.save();
    this.vertical.scrollTo({ xOffset: 0, yOffset: 0 });
  }
  private nextLevel(): void {
    const next = TANGRAM_LEVELS.find((l: TangramLevel): boolean => !this.collected.includes(l.id));
    if (next === undefined) this.present('album'); else this.startLevel(next.id);
  }
  private async saveAndExit(): Promise<void> {
    if (this.saving) return;
    this.cancelDrag(); this.saving = true;
    const ok = await this.save(); this.saving = false;
    if (this.disposed) return;
    if (ok) { this.skipSave = true; this.exitToHub(); } else this.dialog = 'saveError';
  }
  private exitRequested(): void {
    if (!this.loaded) { this.skipSave = true; this.exitToHub(); return; }
    if (this.dialog.length > 0 && this.dialog !== 'saveError') { this.dialog = ''; return; }
    this.saveAndExit();
  }
  private relayout(): void {
    const next = tangramLayout(this.pageWidth, this.pageHeight, this.insets, this.creases);
    if (JSON.stringify(next) === JSON.stringify(this.layout)) return;
    this.cancelDrag(); this.layout = next;
  }
  private backgrounded(): void { this.cancelDrag(); this.audio.silence(); this.save(); }
  private themeChanged(): void { this.host.setDark(this.dark); this.revision += 1; }
  private soundChanged(): void { this.audio.setEnabled(this.soundEnabled); }
}
