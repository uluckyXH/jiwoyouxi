import { RpsBattleTheme } from './RpsBattleTheme';

@Component
export struct RpsBattleSetupCardHeader {
  @Prop order: string = '01';
  @Prop title: string = '';
  @Prop subtitle: string = '';

  build() {
    Row({ space: 8 }) {
      Text(this.order)
        .width(28)
        .height(24)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.primaryButtonText)
        .textAlign(TextAlign.Center)
        .backgroundColor(RpsBattleTheme.brandAccent)
        .borderRadius(7)
      Column({ space: 1 }) {
        Text(this.title)
          .width('100%')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .maxLines(1)
        Text(this.subtitle)
          .width('100%')
          .fontSize(11)
          .fontColor(RpsBattleTheme.muted)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(32)
    .alignItems(VerticalAlign.Center)
  }
}
