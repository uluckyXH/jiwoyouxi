import { BLOOM_LOGO, BloomMode, bloomConfig } from './BloomModel';
import { BloomPalette as P } from './BloomPalette';
import { BloomActionButton, BloomIconButton } from './BloomControls';

@Component
export struct BloomDialog {
  @Prop dark: boolean = false;
  @Prop mode: string = 'pause';
  @Prop targetMode: BloomMode = 'garden';
  @Prop score: number = 0;
  @Prop cleared: number = 0;
  @Prop moves: number = 0;
  @Prop saving: boolean = false;
  @Prop saveFailed: boolean = false;
  @Prop panelWidth: number = 350;
  @Prop panelHeight: number = 700;
  @State revealed: boolean = false;
  close: () => void = () => {};
  restart: () => void = () => {};
  confirm: () => void = () => {};
  leave: () => void = () => {};
  discard: () => void = () => {};
  retry: () => void = () => {};
  retrySave: () => void = () => {};

  private enter(): void {
    this.getUIContext().animateTo({ duration: 200, curve: Curve.EaseOut }, () => { this.revealed = true; });
  }
  private title(): string {
    if (this.mode === 'loading') { return '摆好一盘小彩珠'; }
    if (this.mode === 'loadError') { return '暂时读不到进度'; }
    if (this.mode === 'corrupt') { return '这份进度暂时打不开'; }
    if (this.mode === 'resume') { return '彩珠还在等你'; }
    if (this.mode === 'help') { return '让五颗彩珠，一起开花'; }
    if (this.mode === 'end') { return '收好这一盘的小花'; }
    if (this.mode === 'mode') { return '换到' + bloomConfig(this.targetMode).title + '模式'; }
    if (this.mode === 'restart') { return '重新摆一盘彩珠'; }
    if (this.mode === 'exit') { return '把小院留到下次'; }
    return '让彩珠歇一会儿';
  }
  private detail(): string {
    if (this.mode === 'loading') { return '正在读取棋盘与小小的收藏'; }
    if (this.mode === 'loadError') { return '可以重试读取，或先返回大厅。'; }
    if (this.mode === 'corrupt') { return '原存档尚未替换。可以重试，或选择重新开始。'; }
    if (this.mode === 'help') { return '直接拖动或点选都能玩，给小伙伴留出一条路。'; }
    if (this.mode === 'end') { return '棋盘已经放满了，下一盘再试一条新路线。'; }
    if (this.mode === 'mode') { return '当前棋盘会换成新的' + bloomConfig(this.targetMode).subtitle + '棋盘，已获得的成就保留。'; }
    if (this.mode === 'restart') { return '当前棋盘将被替换，本档最佳与已获得的成就保留。'; }
    if (this.mode === 'exit') { return '保存棋盘、下一批彩珠与撤销记录，回来接着玩。'; }
    return '棋盘停在原处，准备好再继续。';
  }
  @Builder
  HelpRow(icon: string, title: string, detail: string) {
    Row({ space: 10 }) {
      Image($rawfile(P.icon(icon, this.dark, 'accent'))).width(23).height(23).accessibilityLevel('no')
      Column({ space: 4 }) {
        Text(title).fontSize(14).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
        Text(detail).fontSize(12).lineHeight(20).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }.width('100%').alignItems(VerticalAlign.Top)
  }
  @Builder
  Guide() {
    Row({ space: 3 }) {
      ForEach([0, 1, 2, 3, 4], (index: number) => {
        Image($rawfile(P.bead(2, this.dark))).width(32).height(32).accessibilityLevel('no')
      }, (index: number) => '' + index)
      Image($rawfile(P.icon('spark', this.dark, 'accent'))).width(22).height(22).margin({ left: 5 })
    }.width('100%').justifyContent(FlexAlign.Center).padding(8).backgroundColor(P.soft(this.dark)).borderRadius(17)
    this.HelpRow('path', '直接拖动，或点选移动', '按住彩珠直接拖，不用先点选或长按等待；松手落在绿色提示的空位。也可以点彩珠、再点空位。小圆点标出能到的位置，红框表示走不到；拖出棋盘或被挡住时会回弹。')
    this.HelpRow('leaf', '留一条小路给彩珠', '移动仍需有上下左右相连的空格，不能穿越其他彩珠。空间不足时，可从空格或棋盘外拖动页面来滚动浏览。')
    this.HelpRow('flower', '五颗同色，就会开花', '横、竖或斜线连成至少五颗即可消除，每颗得 2 分。一次形成多条线，交点只算一次。')
    this.HelpRow('seed', '消除后，这一步不补珠', '轻松模式未消除时补 2 颗，经典补 3 颗。预览告诉你颜色，落点随机；新珠自己连成五颗也能消除。若整盘清空，会送来预览中的小彩珠，让你继续玩。')
    this.HelpRow('undo', '可以撤销最近 20 步', '棋盘、得分、预览和随机状态一起回到上一步。盘满结算后不再撤销；已经获得的成就保留。')
    this.HelpRow('basket', '小成就，慢慢收集', '首次消除、单局 30 分、累计消除 30 颗，各有一枚勋章。两档都算，撤销重走同一段不会重复增加累计。')
    BloomActionButton({ dark: this.dark, label: '明白了，开始排彩珠', icon: 'check', action: this.close })
  }
  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(this.dark ? '#DA181B19' : '#DFFFF4E4')
        .opacity(this.revealed ? 1 : 0)
      Scroll() {
        Column({ space: 15 }) {
          if (!['loading', 'loadError', 'corrupt'].includes(this.mode)) {
            Row() {
              Text('花 窗 连 珠').fontSize(11).letterSpacing(2).fontColor(P.muted(this.dark)).layoutWeight(1)
              BloomIconButton({ dark: this.dark, icon: 'close', label: '关闭弹窗', active: !this.saving, action: this.close })
            }.width('100%')
          }
          Image($rawfile(this.mode === 'help' ? BLOOM_LOGO : P.scene('mascot', this.dark)))
            .width(74).height(74).accessibilityLevel('no')
          Text(this.title()).fontSize(23).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).textAlign(TextAlign.Center)
          Text(this.detail()).fontSize(13).lineHeight(21).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
          if (this.mode === 'help') {
            this.Guide()
          } else if (this.mode === 'loadError' || this.mode === 'corrupt') {
            BloomActionButton({ dark: this.dark, label: '重试读取', icon: 'restart', action: this.retry })
            if (this.mode === 'corrupt') {
              BloomActionButton({ dark: this.dark, label: '重新开始并替换存档', icon: 'seed', primary: false, action: this.confirm })
            }
            BloomActionButton({ dark: this.dark, label: '返回大厅', icon: 'back', primary: false, action: this.discard })
          } else if (this.mode !== 'loading') {
            Column({ space: 4 }) {
              Text('' + this.score).fontSize(34).fontWeight(FontWeight.Bold).fontFamily('monospace').fontColor(P.ink(this.dark))
              Text('消除 ' + this.cleared + ' 颗 · 移动 ' + this.moves + ' 步').fontSize(12).fontColor(P.muted(this.dark))
            }.width('100%').padding(14).backgroundColor(P.soft(this.dark)).borderRadius(20)
            if (this.saveFailed) {
              Text('进度或成就还没存好，请重试保存。').fontSize(12).fontColor(P.danger(this.dark))
              BloomActionButton({ dark: this.dark, label: '重试保存', icon: 'restart', primary: false,
                active: !this.saving, action: this.retrySave })
            }
            if (this.mode === 'restart' || this.mode === 'mode') {
              BloomActionButton({ dark: this.dark, label: '开始新的一局', icon: 'seed', active: !this.saving, action: this.confirm })
              BloomActionButton({ dark: this.dark, label: '保留当前这局', icon: 'back', primary: false, active: !this.saving, action: this.close })
            } else if (this.mode === 'exit') {
              BloomActionButton({ dark: this.dark, label: this.saving ? '正在保存…' : '保存并返回大厅',
                icon: 'back', active: !this.saving, action: this.leave })
              BloomActionButton({ dark: this.dark, label: '再玩一会', primary: false, active: !this.saving, action: this.close })
              if (this.saveFailed) {
                BloomActionButton({ dark: this.dark, label: '不保存，直接返回', icon: 'close',
                  primary: false, active: !this.saving, action: this.discard })
              }
            } else {
              if (this.mode !== 'end') {
                BloomActionButton({ dark: this.dark, label: '继续这一盘', active: !this.saving, action: this.close })
              }
              BloomActionButton({ dark: this.dark, label: '重新开局', icon: 'restart',
                primary: this.mode === 'end', active: !this.saving, action: this.restart })
              BloomActionButton({ dark: this.dark, label: '保存并返回大厅', icon: 'back',
                primary: false, active: !this.saving, action: this.leave })
            }
          }
        }.width('100%').padding(20)
      }.width(this.panelWidth).constraintSize({ maxHeight: this.panelHeight }).scrollBar(BarState.Off)
      .backgroundColor(P.paper(this.dark)).borderRadius(28).border({ width: 1, color: P.line(this.dark), radius: 28 }).clip(true)
      .scale({ x: this.revealed ? 1 : .96, y: this.revealed ? 1 : .96 })
      .translate({ y: this.revealed ? 0 : 10 }).opacity(this.revealed ? 1 : 0)
    }.width('100%').height('100%').onAppear(() => this.enter())
  }
}
