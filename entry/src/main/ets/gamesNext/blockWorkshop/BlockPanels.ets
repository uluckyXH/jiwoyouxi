import { BlockPalette as P } from './BlockPalette';

@Component
export struct BlockScorePanel {
  @Prop dark: boolean = false;
  @Prop compact: boolean = false;
  @Prop score: number = 0;
  @Prop best: number = 0;
  @Prop lines: number = 0;
  @Prop level: number = 1;

  build() {
      Row({ space: 10 }) {
        Column({ space: 1 }) {
          Text('本局得分').fontSize(10).fontColor(P.muted(this.dark)).letterSpacing(1)
          Text(`${this.score}`).fontSize(this.compact ? 21 : 28).minFontSize(16).maxFontSize(this.compact ? 21 : 28)
            .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST).fontWeight(FontWeight.Bold)
            .fontColor(P.ink(this.dark)).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Column({ space: this.compact ? 2 : 5 }) {
          Row({ space: 6 }) {
            Text(`等级 ${this.level}`).fontSize(11).fontWeight(FontWeight.Bold).fontColor(P.accent(this.dark))
            Text('·').fontSize(10).fontColor(P.gold(this.dark))
            Text(`${this.lines} 行`).fontSize(11).fontColor(P.ink(this.dark))
          }
          Row({ space: 4 }) {
            Image($rawfile(P.icon('trophy', this.dark))).width(10).height(10).draggable(false).accessibilityLevel('no')
            Text(`最高 ${this.best}`).fontSize(9).fontColor(P.gold(this.dark)).maxLines(1)
          }
        }.alignItems(HorizontalAlign.End)
      }.width('100%').height('100%').padding({ left: this.compact ? 12 : 16, right: this.compact ? 12 : 16 })
      .backgroundColor(P.surface(this.dark)).borderRadius(this.compact ? 14 : 22).clip(true)
      .border({ width: 1, color: P.line(this.dark), radius: this.compact ? 14 : 22 })
  }
}
