import { CoopModalTransition } from '../../components/CoopModalTransition';
import { FreecellTheme } from './FreecellTheme';

@Component
export struct FreecellGuideOverlay {
  @Prop pageWidth: number = 390;
  closeGuide: () => void = () => {};

  build() {
    CoopModalTransition({
      maskColor: 'rgba(55,31,9,0.44)',
      panelScaleFrom: 0.96,
      panelOffsetVp: 8
    }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Image($rawfile('games/freecell/panel_card_base_cut.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
        Column({ space: 7 }) {
          Text('玩法提示')
            .width('100%')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(FreecellTheme.deepBrown)
            .textAlign(TextAlign.Center)
            .maxLines(1)
          Column({ space: 7 }) {
            Text('目标：同花色 A 到 K 归位')
              .width('100%')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(FreecellTheme.brown)
              .textAlign(TextAlign.Center)
              .lineHeight(17)
              .maxLines(2)
            this.RuleRow('♠', '牌列', '红黑交替递减')
            this.RuleRow('♥', '空当', '每格只停一张')
            this.RuleRow('♦', '辅助', '双击或提示走一步')
          }
          .width(this.guideBodyWidth())
          this.GoldButton('知道了', () => {
            this.closeGuide();
          })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 28, right: 28, top: 56, bottom: 28 })
        .alignItems(HorizontalAlign.Center)
      }
      .width(this.panelWidth())
      .height(405)
    }
  }

  @Builder
  RuleRow(mark: string, label: string, text: string) {
    Row({ space: 8 }) {
      Text(mark)
        .width(26)
        .height(26)
        .borderRadius(13)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(mark === '♥' || mark === '♦' ? FreecellTheme.red : FreecellTheme.black)
        .textAlign(TextAlign.Center)
        .backgroundColor('#fff4dc')
        .border({ width: 1, color: '#dfb36b' })
      Column({ space: 1 }) {
        Text(label)
          .width('100%')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(FreecellTheme.deepBrown)
          .textAlign(TextAlign.Start)
          .maxLines(1)
        Text(text)
          .width('100%')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#76512f')
          .lineHeight(15)
          .maxLines(2)
      }
      .height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 0, right: 0, top: 2, bottom: 2 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  GoldButton(label: string, action: () => void) {
    Stack({ alignContent: Alignment.Center }) {
      Image($rawfile('games/freecell/btn_highlight_gold_cut.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
      Text(label)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#5f310b')
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width(172)
    .height(58)
    .margin({ top: 8 })
    .onClick(() => {
      action();
    })
  }

  private panelWidth(): number {
    return Math.min(this.pageWidth - 32, 318);
  }

  private guideBodyWidth(): number {
    return Math.min(this.panelWidth() - 64, 226);
  }
}

@Component
export struct FreecellExitConfirmOverlay {
  @Prop pageWidth: number = 390;
  cancelExit: () => void = () => {};
  confirmExit: () => void = () => {};

  build() {
    CoopModalTransition({
      maskColor: 'rgba(55,31,9,0.46)',
      panelScaleFrom: 0.96,
      panelOffsetVp: 8
    }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Image($rawfile('games/freecell/panel_card_base_cut.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
        Column({ space: 10 }) {
          Text('离开本局？')
            .width('100%')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(FreecellTheme.deepBrown)
            .textAlign(TextAlign.Center)
            .maxLines(1)
          Text('离开后当前牌局不会保留。')
            .width('100%')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#76512f')
            .textAlign(TextAlign.Center)
            .lineHeight(18)
            .maxLines(2)
          this.GoldButton('继续游戏', () => {
            this.cancelExit();
          })
          this.CreamButton('回大厅', () => {
            this.confirmExit();
          })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 28, right: 28, top: 66, bottom: 32 })
        .alignItems(HorizontalAlign.Center)
      }
      .width(this.panelWidth())
      .height(335)
    }
  }

  @Builder
  GoldButton(label: string, action: () => void) {
    Stack({ alignContent: Alignment.Center }) {
      Image($rawfile('games/freecell/btn_highlight_gold_cut.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
      Text(label)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#5f310b')
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width(172)
    .height(58)
    .margin({ top: 8 })
    .onClick(() => {
      action();
    })
  }

  @Builder
  CreamButton(label: string, action: () => void) {
    Stack({ alignContent: Alignment.Center }) {
      Text(label)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(FreecellTheme.brown)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width(154)
    .height(48)
    .borderRadius(24)
    .backgroundColor('#fff0d2')
    .border({ width: 2, color: '#d89234' })
    .shadow({ radius: 5, color: 'rgba(103,55,12,0.18)', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      action();
    })
  }

  private panelWidth(): number {
    return Math.min(this.pageWidth - 32, 318);
  }
}
