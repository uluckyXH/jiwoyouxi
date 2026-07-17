import { RpsBattleTheme } from './RpsBattleTheme';

@Component
export struct RpsBattleCountdownOverlay {
  @Prop boardWidth: number = 280;
  @Prop boardHeight: number = 250;
  @Prop countdownValue: number = 3;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 4 }) {
        Text('开战')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.muted)
          .maxLines(1)
        Text(`${this.countdownValue}`)
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .height(76)
          .textAlign(TextAlign.Center)
      }
      .width(132)
      .height(126)
      .justifyContent(FlexAlign.Center)
      .borderRadius(18)
      .backgroundColor('rgba(255,248,232,0.82)')
      .border({ width: 1, color: RpsBattleTheme.panelLine })
      .shadow({
        radius: 18,
        color: 'rgba(42,26,16,0.18)',
        offsetX: 0,
        offsetY: 7
      })
    }
    .width(this.boardWidth)
    .height(this.boardHeight)
    .backgroundColor('rgba(247,239,217,0.22)')
  }
}
