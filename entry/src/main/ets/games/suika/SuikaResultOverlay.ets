import { CoopModalTransition } from '../../components/CoopModalTransition';
import { SuikaFeatherLayer } from './SuikaFeatherLayer';
import { SuikaImageButton } from './SuikaImageButton';

@Component
export struct SuikaResultOverlay {
  @Prop success: boolean = false;
  @Prop pageWidth: number = 390;
  @Prop pageHeight: number = 760;
  @Prop currentScore: number = 0;
  @Prop bestScore: number = 0;
  @Prop successScore: number = 600;
  restartGame: () => void = () => {};
  exitToHub: () => void = () => {};
  closeOverlay: () => void = () => {};

  build() {
    CoopModalTransition({
      maskColor: 'rgba(22,13,8,0.42)'
    }) {
      Stack({ alignContent: Alignment.Center }) {
        SuikaFeatherLayer({
          success: this.success,
          pageWidth: this.pageWidth,
          pageHeight: this.pageHeight
        })
        this.ResultCard()
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  ResultCard() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(this.cardImage()))
        .width(this.cardWidth())
        .height(this.cardHeight())
        .objectFit(ImageFit.Fill)
      Column({ space: this.contentGap() }) {
        Text(this.titleText())
          .width('100%')
          .fontSize(this.titleFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(this.success ? '#946112' : '#794022')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textShadow({ radius: 1, color: 'rgba(255,255,255,0.72)', offsetX: 0, offsetY: 1 })
        Text(this.subtitleText())
          .width('100%')
          .fontSize(this.subtitleFontSize())
          .fontColor('#7e6247')
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.infoText())
          .width('100%')
          .fontSize(this.infoFontSize())
          .fontWeight(FontWeight.Medium)
          .fontColor('#9a7149')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 10 }) {
          SuikaImageButton({
            label: '再摆一摊',
            imagePath: 'games/minesweeper/button_yellow.png',
            buttonWidth: this.buttonWidth(),
            buttonHeight: this.buttonHeight(),
            fontSize: this.buttonFontSize(),
            action: () => {
              this.restartGame();
            }
          })
          SuikaImageButton({
            label: '回大厅',
            imagePath: 'games/minesweeper/button_green.png',
            buttonWidth: this.buttonWidth(),
            buttonHeight: this.buttonHeight(),
            fontSize: this.buttonFontSize(),
            action: () => {
              this.exitToHub();
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width(this.contentWidth())
      .position({ x: this.contentX(), y: this.contentY() })
      this.CloseButton()
    }
    .width(this.cardWidth())
    .height(this.cardHeight())
    .shadow({
      radius: 20,
      color: 'rgba(80,46,19,0.24)',
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  CloseButton() {
    Stack() {
      Image($rawfile('games/minesweeper/button_wood_small_right.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
      Text('X')
        .width('100%')
        .height('100%')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#5b351d')
        .textAlign(TextAlign.Center)
        .textShadow({ radius: 1, color: 'rgba(255,255,255,0.58)', offsetX: 0, offsetY: 1 })
    }
    .width(42)
    .height(34)
    .position({ x: this.cardWidth() - 54, y: this.closeY() })
    .onClick(() => {
      this.closeOverlay();
    })
  }

  private cardImage(): string {
    return this.success ? 'games/minesweeper/popup_success_card.png' : 'games/minesweeper/popup_failure_card.png';
  }

  private cardWidth(): number {
    return Math.min(this.pageWidth - 24, this.pageWidth < 340 ? 330 : 382);
  }

  private cardHeight(): number {
    return Math.round(this.cardWidth() * (this.success ? 1004 / 1132 : 970 / 1259));
  }

  private contentWidth(): number {
    return Math.round(this.cardWidth() * 0.78);
  }

  private contentX(): number {
    return Math.round((this.cardWidth() - this.contentWidth()) * 0.5);
  }

  private contentY(): number {
    return Math.round(this.cardHeight() * (this.success ? 0.535 : 0.475));
  }

  private closeY(): number {
    return Math.round(this.cardHeight() * (this.success ? 0.31 : 0.33));
  }

  private contentGap(): number {
    return this.pageWidth < 340 ? 5 : 7;
  }

  private titleFontSize(): number {
    return this.pageWidth < 340 ? 21 : 24;
  }

  private subtitleFontSize(): number {
    return this.pageWidth < 340 ? 12 : 13;
  }

  private infoFontSize(): number {
    return this.pageWidth < 340 ? 11 : 12;
  }

  private buttonWidth(): number {
    return Math.round(this.contentWidth() * 0.44);
  }

  private buttonHeight(): number {
    return this.pageWidth < 340 ? 42 : 46;
  }

  private buttonFontSize(): number {
    return this.pageWidth < 340 ? 15 : 16;
  }

  private titleText(): string {
    return this.success ? '鸡窝水果摊大丰收！' : '鸡窝被塞满了！';
  }

  private subtitleText(): string {
    if (this.success) {
      return `今日瓜分超过 ${this.successScore}，水果摊稳稳开张。`;
    }
    return `还差一点到 ${this.successScore}，再摆一摊。`;
  }

  private infoText(): string {
    return `今日瓜分 ${this.currentScore} · 最高纪录 ${Math.max(this.bestScore, this.currentScore)}`;
  }
}
