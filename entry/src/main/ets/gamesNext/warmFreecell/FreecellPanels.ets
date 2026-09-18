import { FCButton } from './FreecellControls';
import { FC_LOGO } from './FreecellModel';
import { FCPalette as P } from './FreecellPalette';

@Component
export struct FreecellPanel {
  @Prop dark: boolean = false;
  @Prop mode: string = 'pause';
  @Prop panelWidth: number = 340;
  @Prop panelHeight: number = 600;
  @Prop collected: number = 0;
  @Prop moves: number = 0;
  @Prop seed: number = 1;
  @Prop saving: boolean = false;
  @Prop saveFailed: boolean = false;
  close: () => void = () => {};
  restart: () => void = () => {};
  same: () => void = () => {};
  fresh: () => void = () => {};
  leave: () => void = () => {};
  retry: () => void = () => {};
  discard: () => void = () => {};
  @State shown: boolean = false;
  private title(): string {
    if (this.mode === 'help') return '让每张牌，找到归处';
    if (this.mode === 'win') return '四季花色，都已归位';
    if (this.mode === 'restart') return '再铺开一桌新的可能';
    if (this.mode === 'exit') return '把这一局留到下次';
    if (this.mode === 'resume') return '回到你的牌桌';
    if (this.mode === 'loading') return '正在整理牌桌';
    if (this.mode === 'loadError') return '暂时读不到上次进度';
    return '在牌桌旁，歇一会';
  }
  @Builder
  Rule(icon: string, title: string, detail: string) {
    Row({ space: 10 }) {
      Image($rawfile(P.icon(icon, this.dark))).width(22).height(22).accessibilityLevel('no')
      Column({ space: 5 }) {
        Text(title).fontSize(14).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        Text(detail).fontSize(12).lineHeight(20).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }.width('100%').alignItems(VerticalAlign.Top)
  }
  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(this.dark ? '#E0101110' : '#E8FFF4E4')
      Scroll() {
        Column({ space: 15 }) {
          if (this.mode !== 'loading' && this.mode !== 'loadError') {
            Row() {
              Text('暖 木 牌 室').fontSize(11).letterSpacing(2).fontColor(P.muted(this.dark)).layoutWeight(1)
              FCButton({ dark: this.dark, icon: 'close', label: '关闭', small: true, active: !this.saving, action: this.close })
            }.width('100%')
          }
          Image($rawfile(FC_LOGO)).width(66).height(66).accessibilityLevel('no')
          Text(this.title()).fontSize(23).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).textAlign(TextAlign.Center)
          if (this.mode === 'help') {
            Image($rawfile(P.asset('guide/order', this.dark))).width(240).height(142).accessibilityText('黑桃8、红桃7、梅花6，交替递减')
            this.Rule('cards', '红黑交替，点数递减', '将红 7 接在黑 8 下方。空列能放任意起始牌；不能抽走被压住的中间牌。')
            this.Rule('auto', '四个空当，给思路留白', '每个空当只停一张。搬一组牌需要足够空当和空列：1 个空当能搬 2 张；空的目标列不算额外的中转位置。')
            this.Rule('trophy', '同一花色，从 A 收到 K', '右上四个槽按花色归位，全部 52 张归位即完成。归位每张 10 分，可撤销，但不能直接从归位槽取回。')
            this.Rule('play', '按住就能拖，点选也能玩', '按住可移动的纸牌直接拖到目标，也可以点选纸牌后再点目标，双击可归位。滑动牌桌空白或不能移动的牌列可查看长列；拖牌到边缘会自动滚动。')
            this.Rule('hint', '提示，给下一步一点方向', '标出一组可以移动的牌和目标，连续点击可查看其他建议。提示保证走法合法，不保证是最优解。')
            this.Rule('auto', '自动整理，帮你收牌和理牌', '先把能安全归位的牌收到上方，再尝试几步合法的牌列移动，减少重复操作。它不是自动通关，无法继续推进时会停下。再点一次按钮或点牌即可停止，每一步都能撤销，也会计入步数。')
            this.Rule('undo', '不用急，随时回想上一步', '可撤销最近 200 步，计时不倒退。新牌局可重玩同一编号；离开会保存当前局，回来接着玩。')
            FCButton({ dark: this.dark, icon: 'check', label: '明白了，开始整理', primary: true, action: this.close })
          } else if (this.mode === 'loading') {
            Text('正在读取上次的纸牌与进度…').fontSize(13).fontColor(P.muted(this.dark))
          } else if (this.mode === 'loadError') {
            Text('重试读取，或返回大厅后再来。').fontSize(13).fontColor(P.muted(this.dark))
            FCButton({ dark: this.dark, icon: 'restart', label: '重试读取', primary: true, action: this.retry })
            FCButton({ dark: this.dark, icon: 'back', label: '返回大厅', action: this.discard })
          } else {
            Column({ space: 7 }) {
              Text(`${this.collected} / 52`).fontSize(32).fontFamily('monospace').fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
              Text(`归位 ${this.collected * 10} 分 · ${this.moves} 步`).fontSize(13).fontColor(P.muted(this.dark))
              Text(`牌局 ${this.seed}`).fontSize(11).fontColor(P.muted(this.dark))
            }.width('100%').padding(15).backgroundColor(P.felt(this.dark)).borderRadius(22)
            Text(this.mode === 'restart' ? '重玩或换一局会替换当前进度。' : this.mode === 'win' ? '这一桌整齐的花色，是你的好思路。' : '纸牌停在原处，准备好再继续。')
              .fontSize(13).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
            if (this.saveFailed) {
              Text('进度尚未保存，请重试。').fontSize(12).fontColor(P.red(this.dark))
              FCButton({ dark: this.dark, icon: 'restart', label: '重试保存', active: !this.saving, action: this.retry })
            }
            if (this.mode === 'restart') {
              FCButton({ dark: this.dark, icon: 'cards', label: '换一局', primary: true, active: !this.saving, action: this.fresh })
              FCButton({ dark: this.dark, icon: 'restart', label: '重玩本局', active: !this.saving, action: this.same })
              FCButton({ dark: this.dark, icon: 'back', label: '保留当前这局', active: !this.saving, action: this.close })
            } else if (this.mode === 'exit') {
              FCButton({ dark: this.dark, icon: 'back', label: this.saving ? '正在保存…' : '保存并返回大厅', primary: true, active: !this.saving, action: this.leave })
              if (this.saveFailed) { FCButton({ dark: this.dark, icon: 'close', label: '不保存，直接返回', active: !this.saving, action: this.discard }) }
            } else {
              FCButton({ dark: this.dark, icon: this.mode === 'win' ? 'cards' : 'play', label: this.mode === 'win' ? '再来一局' : '继续这一盘', primary: true, active: !this.saving,
                action: () => { if (this.mode === 'win') this.restart(); else this.close(); } })
              FCButton({ dark: this.dark, icon: 'restart', label: '新牌局', active: !this.saving, action: this.restart })
              FCButton({ dark: this.dark, icon: 'back', label: '保存并返回大厅', active: !this.saving, action: this.leave })
            }
          }
        }.width(this.panelWidth).padding(22).backgroundColor(P.paper(this.dark)).borderRadius(28)
        .border({ width: 1, color: P.line(this.dark), radius: 28 }).opacity(this.shown ? 1 : 0)
        .translate({ y: this.shown ? 0 : 10 }).onAppear(() => {
          this.getUIContext().animateTo({ duration: 190, curve: Curve.EaseOut }, () => { this.shown = true; });
        })
      }.width(this.panelWidth).height(this.panelHeight).scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto)
    }.width('100%').height('100%')
  }
}
