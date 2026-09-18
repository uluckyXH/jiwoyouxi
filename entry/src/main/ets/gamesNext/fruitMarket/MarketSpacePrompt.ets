import { MarketAction } from './MarketControls';
import { MarketPalette } from './MarketPalette';

/** A scrollable exit remains reachable even on a very small cover display. */
@Component
export struct MarketSpacePrompt {
  @Prop dark: boolean = false;
  @Prop halfFoldPane: boolean = false;
  @Prop cardWidth: number = 300;
  @Prop cardHeight: number = 400;
  @Prop saveFailed: boolean = false;
  @Prop saving: boolean = false;
  exit: () => void = () => {};
  exitWithoutSave: () => void = () => {};

  build() {
    Stack() {
      Scroll() {
        Column({ space: 14 }) {
          Image($rawfile(MarketPalette.icon('expand', this.dark, 'accent')))
            .width(88).height(88).padding(16).borderRadius(24)
            .backgroundColor(MarketPalette.soft(this.dark)).accessibilityLevel('no')
          Text(this.halfFoldPane ? '展开屏幕，继续摆摊' : '给水果摊多一点空间')
            .fontSize(21).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
            .fontColor(MarketPalette.ink(this.dark))
          Text(this.halfFoldPane ? '这半边屏幕有点小。展开后，水果和落点会更清楚。' :
            '当前窗口有点小。请展开屏幕，或把游戏窗口调大一些。')
            .fontSize(14).lineHeight(22).textAlign(TextAlign.Center)
            .fontColor(MarketPalette.muted(this.dark))
          Text('对局会保持暂停，调整好后点“继续摆摊”接着玩。')
            .fontSize(12).lineHeight(19).textAlign(TextAlign.Center)
            .fontColor(MarketPalette.muted(this.dark))
          if (this.saveFailed) {
            Text('进度暂未保存成功，可重试返回。').fontSize(12)
              .fontColor(MarketPalette.danger(this.dark)).textAlign(TextAlign.Center)
            Button('不保存返回').fontSize(13).height(44).backgroundColor(Color.Transparent)
              .fontColor(MarketPalette.danger(this.dark)).onClick(this.exitWithoutSave)
          }
          MarketAction({ label: this.saving ? '正在保存' : '返回大厅', icon: 'back', dark: this.dark, action: this.exit })
            .enabled(!this.saving)
        }.width('100%').padding(20)
      }
      .width(this.cardWidth).constraintSize({ maxHeight: this.cardHeight }).scrollBar(BarState.Off)
      .backgroundColor(MarketPalette.surface(this.dark)).borderRadius(28)
      .border({ width: 1, color: MarketPalette.line(this.dark), radius: 28 })
    }.width('100%').height('100%')
  }
}
