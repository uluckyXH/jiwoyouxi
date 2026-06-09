import { FactionInfo, FACTIONS } from '../model/GameTypes';

@Component
export struct RageBar {
  @Prop rageType: number;
  @Prop rageTimeLeftSec: number;
  @Prop rageProgress: number;
  @Prop canvasWidth: number;
  @Prop factions: FactionInfo[] = FACTIONS;

  build() {
    Column({ space: 4 }) {
      Row() {
        Text(`${this.factions[this.rageType].emoji} 我要打十个`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
        Blank()
        Text(`${this.rageTimeLeftSec.toFixed(1)}s`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
      }
      .width('100%')
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(6)
          .borderRadius(3)
          .backgroundColor('rgba(255,255,255,0.28)')
        Row()
          .width(Math.max(6, (this.canvasWidth - 36) * this.rageProgress))
          .height(6)
          .borderRadius(3)
          .backgroundColor('#f0b429')
      }
      .width('100%')
      .height(6)
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 7, bottom: 7 })
    .borderRadius(8)
    .backgroundColor('rgba(155,92,255,0.90)')
  }
}
