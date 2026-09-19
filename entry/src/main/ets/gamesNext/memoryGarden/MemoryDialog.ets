import { CoopMotion } from '../../design/CoopMotion';
import { MEMORY_LOGO, MemoryMode, memoryModeTitle } from './MemoryModel';
import { MemoryPalette as P } from './MemoryPalette';
import { MemoryActionButton, MemoryIconButton } from './MemoryControls';

@Component
export struct MemoryDialog {
  @Prop dark: boolean = false;
  @Prop mode: string = 'pause';
  @Prop target: MemoryMode = 'journey';
  @Prop number: number = 1;
  @Prop found: number = 0;
  @Prop pairs: number = 6;
  @Prop attempts: number = 0;
  @Prop saving: boolean = false;
  @Prop saveFailed: boolean = false;
  @Prop panelWidth: number = 350;
  @Prop panelHeight: number = 700;
  @State appeared: boolean = false;
  close: () => void = () => {};
  confirm: () => void = () => {};
  restart: () => void = () => {};
  leave: () => void = () => {};
  discard: () => void = () => {};
  retry: () => void = () => {};
  retrySave: () => void = () => {};
  private enter(): void {
    this.getUIContext().animateTo({ duration: CoopMotion.modalDuration, curve: Curve.EaseOut },
      () => { this.appeared = true; });
  }
  private title(): string {
    if (this.mode === 'loading') { return '摆好一桌小欢喜'; }
    if (this.mode === 'loadError') { return '暂时读不到进度'; }
    if (this.mode === 'corrupt') { return '这份进度暂时打不开'; }
    if (this.mode === 'help') { return '记住一眼，找到一对'; }
    if (this.mode === 'resume') { return '小伙伴还在原处'; }
    if (this.mode === 'restart') { return '重新摆一桌牌'; }
    if (this.mode === 'mode') { return '换到' + memoryModeTitle(this.target) + '模式'; }
    if (this.mode === 'exit') { return '把相遇留到下次'; }
    return '让记忆歇一会儿';
  }
  private detail(): string {
    if (this.mode === 'loading') { return '正在读取牌桌和小小的收藏'; }
    if (this.mode === 'loadError') { return '可以重试读取，或先返回大厅。'; }
    if (this.mode === 'corrupt') { return '原存档尚未替换。可以重试，或明确选择重新开始。'; }
    if (this.mode === 'help') { return '没有倒计时，不用着急，翻错也没关系。'; }
    if (this.mode === 'restart' || this.mode === 'mode') { return '从第 1 桌重新开始，当前牌桌会被替换。累计配对、纪录与成就保留。'; }
    if (this.mode === 'exit') { return '保存当前牌序和已翻开的牌，回来继续寻找。'; }
    return '牌还在原来的位置，准备好了就接着翻。';
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
    Row({ space: 14 }) {
      Image($rawfile(P.picture(0, this.dark))).width(64).height(64).accessibilityLevel('no')
      Image($rawfile(P.icon('pair', this.dark, 'accent'))).width(24).height(24).accessibilityLevel('no')
      Image($rawfile(P.picture(0, this.dark))).width(64).height(64).accessibilityLevel('no')
    }.width('100%').justifyContent(FlexAlign.Center).padding(6).backgroundColor(P.soft(this.dark)).borderRadius(18)
    this.HelpRow('cards', '每次翻开两张', '图案相同就配对成功，留在原处；不同就稍等一下盖回。记住见过的位置，下一次更容易找到。等待盖回时不会翻开第三张。')
    this.HelpRow('next', '配完一桌，继续下一桌', '默认漫游从 6 对开始，每完成两桌增加 2 对，最多 12 对。也可以选固定 6、8、12 对。完成后自动续牌，想歇一会随时暂停。')
    this.HelpRow('trophy', '少翻几次，多记住一点', '完整翻开两张算一次尝试。连续配对会增加连对数，翻错或换桌后重新计算；本档最少按 6、8、10、12 对分别保存。')
    this.HelpRow('pause', '随时回来，接着寻找', '没有时间和生命限制。返回大厅会保存牌序和进度；折叠、展开只调整尺寸与信息栏，不会重新洗牌。')
    this.HelpRow('flower', '三枚小勋章', '第一次配对、配完一桌、累计配对 30 对，分别获得一枚成就。全部模式都算，可以分多次完成。')
    MemoryActionButton({ dark: this.dark, icon: 'check', label: '明白了，开始翻牌', action: this.close })
  }
  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(this.dark ? '#DD171E1C' : '#E6FFF4E4')
      Scroll() {
        Column({ space: 15 }) {
          if (!['loading', 'loadError', 'corrupt'].includes(this.mode)) {
            Row() {
              Text('庭 院 寻 双').fontSize(11).letterSpacing(2).fontColor(P.muted(this.dark)).layoutWeight(1)
              MemoryIconButton({ dark: this.dark, icon: 'close', label: '关闭弹窗', active: !this.saving, action: this.close })
            }.width('100%')
          }
          Image($rawfile(this.mode === 'help' ? MEMORY_LOGO : P.scene('mascot', this.dark)))
            .width(90).height(76).objectFit(ImageFit.Contain).accessibilityLevel('no')
          Text(this.title()).fontSize(23).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).textAlign(TextAlign.Center)
          Text(this.detail()).fontSize(13).lineHeight(21).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
          if (this.mode === 'help') {
            this.Guide()
          } else if (this.mode === 'loadError' || this.mode === 'corrupt') {
            MemoryActionButton({ dark: this.dark, icon: 'restart', label: '重试读取', action: this.retry })
            if (this.mode === 'corrupt') {
              MemoryActionButton({ dark: this.dark, icon: 'cards', label: '重新开始并替换存档',
                primary: false, action: this.confirm })
            }
            MemoryActionButton({ dark: this.dark, icon: 'back', label: '返回大厅', primary: false, action: this.discard })
          } else if (this.mode !== 'loading') {
            Column({ space: 5 }) {
              Text('第 ' + this.number + ' 桌').fontSize(24).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
              Text('找到 ' + this.found + ' / ' + this.pairs + ' 对 · 翻牌 ' + this.attempts + ' 次')
                .fontSize(12).fontColor(P.muted(this.dark))
            }.width('100%').padding(14).backgroundColor(P.soft(this.dark)).borderRadius(20)
            if (this.saveFailed) {
              Text('进度或成就还没存好，请重试保存。').fontSize(12).fontColor(P.danger(this.dark))
              MemoryActionButton({ dark: this.dark, icon: 'restart', label: '重试保存', primary: false,
                active: !this.saving, action: this.retrySave })
            }
            if (this.mode === 'restart' || this.mode === 'mode') {
              MemoryActionButton({ dark: this.dark, icon: 'cards', label: '重新开始', active: !this.saving, action: this.confirm })
              MemoryActionButton({ dark: this.dark, icon: 'back', label: '保留当前这桌', primary: false,
                active: !this.saving, action: this.close })
            } else if (this.mode === 'exit') {
              MemoryActionButton({ dark: this.dark, icon: 'back', label: this.saving ? '正在保存…' : '保存并返回大厅',
                active: !this.saving, action: this.leave })
              MemoryActionButton({ dark: this.dark, label: '再玩一会', primary: false, active: !this.saving, action: this.close })
              if (this.saveFailed) {
                MemoryActionButton({ dark: this.dark, icon: 'close', label: '不保存，直接返回', primary: false,
                  active: !this.saving, action: this.discard })
              }
            } else {
              MemoryActionButton({ dark: this.dark, label: '继续寻找', active: !this.saving, action: this.close })
              MemoryActionButton({ dark: this.dark, icon: 'restart', label: '重新开始', primary: false,
                active: !this.saving, action: this.restart })
              MemoryActionButton({ dark: this.dark, icon: 'back', label: '保存并返回大厅', primary: false,
                active: !this.saving, action: this.leave })
            }
          }
        }.width('100%').padding(20)
      }.width(this.panelWidth).constraintSize({ maxHeight: this.panelHeight }).scrollBar(BarState.Off)
      .backgroundColor(P.paper(this.dark)).borderRadius(28).border({ width: 1, color: P.line(this.dark), radius: 28 }).clip(true)
      .scale({ x: this.appeared ? 1 : CoopMotion.modalScaleFrom, y: this.appeared ? 1 : CoopMotion.modalScaleFrom })
      .translate({ y: this.appeared ? 0 : CoopMotion.modalOffsetVp }).opacity(this.appeared ? 1 : 0)
    }.width('100%').height('100%').onAppear(() => this.enter())
  }
}
