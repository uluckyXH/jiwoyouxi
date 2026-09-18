import { MINE_ASSETS, MineLevel, MINE_LEVELS, mineTime } from './MineModel';
import { MinePalette as P } from './MinePalette';
import { MineActionButton, MineIconButton } from './MineControls';

@Component
export struct MineDialog {
  @Prop dark: boolean = false;
  @Prop mode: string = 'pause';
  @Prop level: MineLevel = MINE_LEVELS[0];
  @Prop pendingName: string = '';
  @Prop elapsedMs: number = 0;
  @Prop score: number = 0;
  @Prop bestScore: number = 0;
  @Prop opened: number = 0;
  @Prop won: boolean = false;
  @Prop saving: boolean = false;
  @Prop saveFailed: boolean = false;
  @Prop panelWidth: number = 340;
  @Prop panelHeight: number = 620;
  close: () => void = () => {};
  restart: () => void = () => {};
  confirmRestart: () => void = () => {};
  leave: () => void = () => {};
  leaveWithoutSave: () => void = () => {};
  help: () => void = () => {};
  retry: () => void = () => {};
  retrySave: () => void = () => {};

  private title(): string {
    if (this.mode === 'loading') return '正在打开庭院';
    if (this.mode === 'loadError') return '暂时读不到进度';
    if (this.mode === 'help') return '一份探雷手记';
    if (this.mode === 'resume') return '接着上次的小径';
    if (this.mode === 'exit') return '把小径留到下次';
    if (this.mode === 'restart') return '重新铺一片雷区';
    if (this.mode === 'difficulty') return `前往${this.pendingName}`;
    if (this.mode === 'result') return this.won ? '这一片，平安无事' : '小心，踩到雷了';
    return '在树荫下歇一会';
  }

  private subtitle(): string {
    if (this.mode === 'loading') return '准备棋盘与上次的进度';
    if (this.mode === 'loadError') return '可以重试读取，或先返回大厅。';
    if (this.mode === 'help') return '慢慢观察，让每一步都有把握。';
    if (this.mode === 'exit') return '保存棋盘与用时，下次回来继续。';
    if (this.mode === 'restart' || this.mode === 'difficulty') return '当前这局会结束，新的第一步仍然安全。';
    if (this.mode === 'result') return this.won ? '每一次推理，都带你走到了这里。' : '标错的旗已指出，看看是哪一步藏了线索。';
    return '棋盘已收起，计时也停在这一刻。';
  }

  @Builder
  HelpLine(icon: string, title: string, detail: string) {
    Row({ space: 12 }) {
      Image($rawfile(P.icon(icon, this.dark, 'accent'))).width(24).height(24).accessibilityLevel('no')
      Column({ space: 4 }) {
        Text(title).fontSize(14).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        Text(detail).fontSize(12).lineHeight(19).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }.width('100%').alignItems(VerticalAlign.Top)
  }

  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(this.dark ? '#E8101110' : '#E8EFE8D8')
      Scroll() {
        Column({ space: 16 }) {
          if (this.mode !== 'loading' && this.mode !== 'loadError') {
            Row() {
              Text(this.mode === 'help' ? '游玩指南' : `${this.level.caption} · ${this.level.mines} 雷`)
                .fontSize(11).fontColor(P.muted(this.dark)).layoutWeight(1)
              MineIconButton({ icon: 'close', label: '关闭弹窗', dark: this.dark, action: this.close })
            }.width('100%')
          }
          Image($rawfile(this.mode === 'result' ? P.icon(this.won ? 'trophy' : 'leaf', this.dark, 'accent') :
            `${MINE_ASSETS}scene/logo.svg`)).width(64).height(64).accessibilityLevel('no')
          Column({ space: 8 }) {
            Text(this.title()).fontSize(23).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
              .textAlign(TextAlign.Center)
            Text(this.subtitle()).fontSize(13).lineHeight(21).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
          }.width('100%')
          if (this.mode === 'help') {
            this.HelpLine('open', '第一步安心翻开', '第一次翻格及周围八格不会有雷。数字表示周围八格的雷数；后续仍需推理，可能遇到需要猜测的局面。')
            this.HelpLine('flag', '长按插旗，也能切换模式', '长按未翻开的格子可以插旗或撤旗。插旗模式下，点一下就能标记；旗数不能超过总雷数。')
            this.HelpLine('check', '点数字，快速连开', '周围旗数等于数字时，再点数字即可展开其余邻格。旗插错了，连开也会触雷。')
            this.HelpLine('pan', '棋盘跟着屏幕调整', '手机按难度缩放，平板与展开的大屏保持大格子。空间不足时可上下左右拖动；旋转和折叠不会重开。')
            this.HelpLine('trophy', '每个难度，都有自己的纪录', '打开所有安全格即获胜，自动补旗不算手动插旗。各难度单独记录最快用时；通关得分随用时递减。')
            MineActionButton({ label: '明白了', icon: 'check', dark: this.dark, action: this.close })
          } else if (this.mode === 'loadError') {
            MineActionButton({ label: '重试读取', icon: 'restart', dark: this.dark, action: this.retry })
            MineActionButton({ label: '返回大厅', icon: 'back', dark: this.dark, primary: false, action: this.leaveWithoutSave })
          } else if (this.mode !== 'loading') {
            Row() {
              Column({ space: 3 }) {
                Text(mineTime(this.elapsedMs)).fontSize(26).fontWeight(FontWeight.Bold).fontFamily('monospace').fontColor(P.ink(this.dark))
                Text('本局用时').fontSize(11).fontColor(P.muted(this.dark))
              }.layoutWeight(1)
              Column({ space: 3 }) {
                Text(this.mode === 'result' && this.won ? `${this.score}` : `${this.opened}`)
                  .fontSize(26).fontWeight(FontWeight.Bold).fontFamily('monospace').fontColor(P.ink(this.dark))
                Text(this.mode === 'result' && this.won ? `最高得分 ${Math.max(this.bestScore, this.score)}` : '已探索的安全格')
                  .fontSize(11).fontColor(P.muted(this.dark))
              }.layoutWeight(1)
            }.width('100%').padding(16).borderRadius(18).backgroundColor(P.soft(this.dark))
            if (this.saveFailed) {
              Text('进度或成就还没存好，请重试保存。').fontSize(12).fontColor(P.danger(this.dark))
              MineActionButton({ label: '重试保存', icon: 'restart', dark: this.dark, primary: false,
                actionEnabled: !this.saving, action: this.retrySave })
            }
            if (this.mode === 'restart' || this.mode === 'difficulty') {
              MineActionButton({ label: '开始新的一局', icon: 'sprout', dark: this.dark, action: this.confirmRestart })
              MineActionButton({ label: '保留当前这局', icon: 'back', dark: this.dark, primary: false, action: this.close })
            } else if (this.mode === 'exit') {
              MineActionButton({ label: this.saving ? '正在保存…' : '保存并返回大厅', icon: 'back', dark: this.dark,
                actionEnabled: !this.saving, action: this.leave })
              if (this.saveFailed) {
                MineActionButton({ label: '不保存，直接返回', icon: 'close', dark: this.dark, primary: false,
                  actionEnabled: !this.saving, action: this.leaveWithoutSave })
              } else {
                MineActionButton({ label: '再待一会', icon: 'leaf', dark: this.dark, primary: false,
                  actionEnabled: !this.saving, action: this.close })
              }
            } else if (this.mode === 'result') {
              MineActionButton({ label: '再探一片小径', icon: 'restart', dark: this.dark, action: this.restart })
              MineActionButton({ label: '看看这局棋盘', icon: 'open', dark: this.dark, primary: false, action: this.close })
              MineActionButton({ label: '保存并返回大厅', icon: 'back', dark: this.dark, primary: false,
                actionEnabled: !this.saving, action: this.leave })
            } else {
              MineActionButton({ label: '继续探索', icon: 'play', dark: this.dark, action: this.close })
              MineActionButton({ label: '重新开局', icon: 'restart', dark: this.dark, primary: false, action: this.restart })
              Row() {
                Button('游玩指南').fontSize(13).fontColor(P.accent(this.dark)).backgroundColor(Color.Transparent)
                  .height(44).layoutWeight(1).onClick(this.help)
                Button('返回大厅').fontSize(13).fontColor(P.muted(this.dark)).backgroundColor(Color.Transparent)
                  .height(44).layoutWeight(1).onClick(this.leave)
              }.width('100%')
            }
          }
        }.padding(22).width('100%')
      }.width(this.panelWidth).constraintSize({ maxHeight: this.panelHeight })
      .scrollBar(BarState.Off).borderRadius(28).backgroundColor(P.paper(this.dark))
      .border({ width: 1, color: P.line(this.dark), radius: 28 }).clip(true)
      .shadow({ radius: 30, color: '#22000000', offsetY: 12 })
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.Default)
  }
}
