import { GLOW_LOGO } from './GlowModel';
import { GlowPalette as P } from './GlowPalette';
import { GlowActionButton, GlowIconButton } from './GlowControls';

@Component
export struct GlowDialog {
  @Prop dark: boolean = false;
  @Prop mode: string = 'pause';
  @Prop score: number = 0;
  @Prop maxTile: number = 2;
  @Prop moves: number = 0;
  @Prop saving: boolean = false;
  @Prop saveFailed: boolean = false;
  @Prop panelWidth: number = 340;
  @Prop panelHeight: number = 600;
  @State revealed: boolean = false;
  close: () => void = () => {};
  restart: () => void = () => {};
  confirmRestart: () => void = () => {};
  leave: () => void = () => {};
  discard: () => void = () => {};
  retry: () => void = () => {};
  retrySave: () => void = () => {};

  private enter(): void {
    this.getUIContext().animateTo({ duration: 220, curve: Curve.EaseOut }, () => { this.revealed = true; });
  }

  private title(): string {
    if (this.mode === 'loading') return '准备一盘暖光';
    if (this.mode === 'loadError') return '暂时读不到进度';
    if (this.mode === 'resume') return '接着上次的灵感';
    if (this.mode === 'help') return '把相同的数字，放在一起';
    if (this.mode === 'win') return '2048，这束光属于你';
    if (this.mode === 'end') return '这一盘，已经很精彩';
    if (this.mode === 'restart') return '从两枚数字重新开始';
    if (this.mode === 'exit') return '把这一盘留到下次';
    return '让灵感歇一会';
  }
  private detail(): string {
    if (this.mode === 'loading') return '正在读取上次的数字与得分';
    if (this.mode === 'loadError') return '请重试读取，或先返回大厅。';
    if (this.mode === 'help') return '四个方向，一点留白，慢慢合出更大的数字。';
    if (this.mode === 'win') return '可以继续合成 4096，以及更远的风景。';
    if (this.mode === 'end') return '没有可移动的方向了，下一盘再试一条新路线。';
    if (this.mode === 'restart') return '当前这盘会被替换，确定再开一局吗？';
    if (this.mode === 'exit') return '保存棋盘、得分与步数，回来后继续。';
    return '数字停在原处，准备好再继续。';
  }
  @Builder
  Help(icon: string, title: string, detail: string) {
    Row({ space: 12 }) {
      Image($rawfile(P.icon(icon, this.dark, 'accent'))).width(23).height(23).accessibilityLevel('no')
      Column({ space: 5 }) {
        Text(title).fontSize(14).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        Text(detail).fontSize(12).lineHeight(20).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }.width('100%').alignItems(VerticalAlign.Top)
  }
  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(this.dark ? '#D9151916' : '#DDFFF4E4')
        .opacity(this.revealed ? 1 : 0)
      Scroll() {
        Column({ space: 16 }) {
          if (this.mode !== 'loading' && this.mode !== 'loadError') {
            Row() {
              Text('暖 光 叠 数').fontSize(11).letterSpacing(2).fontColor(P.muted(this.dark)).layoutWeight(1)
              GlowIconButton({ dark: this.dark, icon: 'close', label: '关闭弹窗', active: !this.saving, action: this.close })
            }.width('100%')
          }
          Image($rawfile(this.mode === 'win' ? P.scene('medal', this.dark) : GLOW_LOGO))
            .width(this.mode === 'win' ? 96 : 64).height(this.mode === 'win' ? 96 : 64).accessibilityLevel('no')
          Text(this.title()).fontSize(23).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).textAlign(TextAlign.Center)
          Text(this.detail()).fontSize(13).lineHeight(21).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
          if (this.mode === 'help') {
            this.Help('left', '滑动，或者点按方向', '滑动棋盘，也可点方向按钮；键盘方向键和 W A S D 同样有效。')
            this.Help('spark', '相同数字，只合并一次', '每次移动中，相邻同数合成两倍数字，所得数字计入总分。合出的格子这一步不会再次合并。')
            this.Help('sun', '每一步，留一点空间', '有效移动后生成一枚 2 或 4；无效方向不会生成数字或增加步数。连合提示不额外加分。')
            this.Help('trophy', '2048 以后，还可以继续', '第一次合出 2048 会庆祝；继续游玩可冲击更大数字。所有方向都不能移动时结束。')
            GlowActionButton({ dark: this.dark, label: '明白了', icon: 'check', action: this.close })
          } else if (this.mode === 'loadError') {
            GlowActionButton({ dark: this.dark, label: '重试读取', icon: 'restart', action: this.retry })
            GlowActionButton({ dark: this.dark, label: '返回大厅', icon: 'back', primary: false, action: this.discard })
          } else if (this.mode !== 'loading') {
            Column({ space: 5 }) {
              Text(`${this.score}`).fontSize(34).minFontSize(18).maxFontSize(34).maxLines(1)
                .fontFamily('monospace').fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
              Text(`最高方块 ${this.maxTile} · ${this.moves} 步`).fontSize(12).fontColor(P.muted(this.dark))
            }.width('100%').padding(14).borderRadius(20).backgroundColor(P.soft(this.dark))
            if (this.saveFailed) {
              Text('进度或成就还没存好，请重试保存。').fontSize(12).fontColor(P.danger(this.dark))
              GlowActionButton({ dark: this.dark, label: '重试保存', icon: 'restart', primary: false,
                active: !this.saving, action: this.retrySave })
            }
            if (this.mode === 'restart') {
              GlowActionButton({ dark: this.dark, label: '开始新的一局', icon: 'spark', active: !this.saving, action: this.confirmRestart })
              GlowActionButton({ dark: this.dark, label: '保留当前这局', icon: 'back', primary: false, active: !this.saving, action: this.close })
            } else if (this.mode === 'exit') {
              GlowActionButton({ dark: this.dark, label: this.saving ? '正在保存…' : '保存并返回大厅', icon: 'back', active: !this.saving, action: this.leave })
              if (this.saveFailed) {
                GlowActionButton({ dark: this.dark, label: '不保存，直接返回', icon: 'close', primary: false, active: !this.saving, action: this.discard })
              } else {
                GlowActionButton({ dark: this.dark, label: '再玩一会', primary: false, active: !this.saving, action: this.close })
              }
            } else {
              if (this.mode !== 'end') {
                GlowActionButton({ dark: this.dark, label: this.mode === 'win' ? '继续冲击更大数字' : '继续这一盘', active: !this.saving, action: this.close })
              }
              GlowActionButton({ dark: this.dark, label: '重新开局', icon: 'restart', primary: this.mode === 'end', active: !this.saving, action: this.restart })
              GlowActionButton({ dark: this.dark, label: '保存并返回大厅', icon: 'back', primary: false, active: !this.saving, action: this.leave })
            }
          }
        }.width('100%').padding(22)
      }.width(this.panelWidth).constraintSize({ maxHeight: this.panelHeight }).scrollBar(BarState.Off)
      .backgroundColor(P.paper(this.dark)).borderRadius(28).border({ width: 1, color: P.line(this.dark), radius: 28 }).clip(true)
      .shadow({ radius: 28, color: '#22000000', offsetY: 10 })
      .scale({ x: this.revealed ? 1 : .96, y: this.revealed ? 1 : .96 })
      .translate({ y: this.revealed ? 0 : 10 }).opacity(this.revealed ? 1 : 0)
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.Default).onAppear(() => this.enter())
  }
}
