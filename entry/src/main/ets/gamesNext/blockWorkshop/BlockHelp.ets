import { BlockAction, BlockIconButton } from './BlockControls';
import { BlockPalette as P } from './BlockPalette';

/** A bounded sheet: only its reading area scrolls, so the close action stays reachable. */
@Component
export struct BlockHelp {
  @Prop dark: boolean = false;
  @Prop availableWidth: number = 390;
  @Prop availableHeight: number = 800;
  close: () => void = () => {};

  build() {
    Column({ space: this.availableHeight < 400 ? 8 : 16 }) {
      Row({ space: 12 }) {
        Column({ space: 3 }) {
          Text('操作与计分').fontSize(21).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
          Text('拼满一行，就能腾出新空间').fontSize(12).fontColor(P.muted(this.dark))
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        BlockIconButton({ icon: 'back', label: '返回游戏菜单', dark: this.dark, quiet: true, action: this.close })
      }.width('100%').height(48)
      Scroll() {
        if (this.availableWidth >= 700) {
          Row({ space: 24 }) {
            Column() { this.OperationGuide() }.layoutWeight(1)
            Column() { this.ScoreGuide() }.layoutWeight(1)
          }.width('100%').alignItems(VerticalAlign.Top)
        } else {
          Column({ space: 24 }) {
            this.OperationGuide()
            this.ScoreGuide()
          }.width('100%')
        }
      }.width('100%').layoutWeight(1).scrollBar(BarState.Auto).edgeEffect(EdgeEffect.None).align(Alignment.TopStart)
      BlockAction({ label: '知道了，返回菜单', dark: this.dark, action: this.close })
    }.padding(this.availableHeight < 400 ? 12 : 20)
      .width(Math.max(1, Math.min(760, this.availableWidth - 24)))
      .height(Math.max(1, Math.min(640, this.availableHeight - 24)))
      .backgroundColor(P.surface(this.dark)).borderRadius(26)
      .border({ width: 1, color: P.line(this.dark), radius: 26 })
  }

  @Builder
  Operation(icon: string, title: string, description: string) {
    Row({ space: 12 }) {
      Image($rawfile(P.icon(icon, this.dark))).width(22).height(22).padding(10)
        .width(42).height(42).backgroundColor(P.soft(this.dark)).borderRadius(13)
        .draggable(false).accessibilityLevel('no')
      Column({ space: 4 }) {
        Text(title).fontSize(14).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
        Text(description).fontSize(12).lineHeight(19).fontColor(P.muted(this.dark)).width('100%')
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }.width('100%').alignItems(VerticalAlign.Top)
  }

  @Builder
  OperationGuide() {
    Column({ space: 18 }) {
      Text('怎么操作').fontSize(15).fontWeight(FontWeight.Bold).fontColor(P.accent(this.dark)).width('100%')
      this.Operation('left', '移动与软降', '点击左右键移动；长按连续移动。长按软降，加快下落。')
      this.Operation('rotate', '旋转与逆转', '旋转是顺时针，逆转是逆时针。贴近墙边也可以尝试转向。')
      this.Operation('drop', '直接落下', '空心轮廓就是落点。点击落下，立即放到该位置。')
      this.Operation('hold', '暂存一块', '点击暂存卡片，留住或换出方块；当前方块落地后可再次使用。')
      Text('方块堆到顶部，这一局就结束。\n暂停后可以保存进度，下次继续。')
        .fontSize(12).lineHeight(20).fontColor(P.muted(this.dark)).width('100%')
        .padding(12).backgroundColor(P.soft(this.dark)).borderRadius(14)
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  ScoreRow(count: number, points: number) {
    Row({ space: 12 }) {
      Column({ space: 3 }) {
        ForEach([4, 3, 2, 1], (line: number) => {
          Row().width(26).height(4).borderRadius(2)
            .backgroundColor(line <= count ? P.accent(this.dark) : P.line(this.dark))
        })
      }.width(30)
      Text(`${count} 行`).fontSize(13).fontColor(P.ink(this.dark)).layoutWeight(1)
      Text(`+${points}`).fontSize(18).fontWeight(FontWeight.Bold).fontColor(P.accent(this.dark))
    }.width('100%').height(42)
  }

  @Builder
  ScoreGuide() {
    Column({ space: 12 }) {
      Row() {
        Text('一次消除').fontSize(15).fontWeight(FontWeight.Bold).fontColor(P.accent(this.dark)).layoutWeight(1)
        Text('基础分').fontSize(11).fontColor(P.muted(this.dark))
      }.width('100%')
      Column() {
        this.ScoreRow(1, 100)
        this.ScoreRow(2, 300)
        this.ScoreRow(3, 500)
        this.ScoreRow(4, 800)
      }.width('100%').padding({ left: 14, right: 14 }).backgroundColor(P.soft(this.dark)).borderRadius(16)
      Text('消行得分 = 基础分 × 本次消行前等级').fontSize(12).lineHeight(19).fontColor(P.ink(this.dark)).width('100%')
      Text('每消除 20 行升一级，下落也会加快。').fontSize(12).lineHeight(19).fontColor(P.muted(this.dark)).width('100%')
      Row({ space: 8 }) {
        Text('软降 +1 / 格').fontSize(12).fontColor(P.accent(this.dark)).layoutWeight(1)
        Text('直落 +2 / 格').fontSize(12).fontColor(P.accent(this.dark)).layoutWeight(1)
      }.width('100%').padding({ top: 8, bottom: 8 })
      Text('连续消行：从第 2 次开始，额外加 50、100、150… × 等级；中断后重新计算。')
        .fontSize(12).lineHeight(20).fontColor(P.muted(this.dark)).width('100%')
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
}
