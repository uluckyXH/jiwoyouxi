import { CoopModalTransition } from '../../components/CoopModalTransition';
import { MinesweeperFeatherLayer } from './MinesweeperFeatherLayer';
import { MinesweeperImageButton } from './MinesweeperImageButton';

@Component
export struct MinesweeperExitConfirmOverlay {
  @Prop pageWidth: number = 390;
  @Prop pageHeight: number = 760;
  @Prop elapsedText: string = '00:00';
  @Prop openedSafeCells: number = 0;
  @Prop safeCellTotal: number = 54;
  cancelExit: () => void = () => {};
  confirmExit: () => void = () => {};

  build() {
    CoopModalTransition({
      maskColor: 'rgba(22,13,8,0.48)',
      panelScaleFrom: 0.94,
      panelOffsetVp: 10
    }) {
      Stack({ alignContent: Alignment.Center }) {
        MinesweeperFeatherLayer({
          win: true,
          pageWidth: this.pageWidth,
          pageHeight: this.pageHeight
        })
        this.ConfirmCard()
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  ConfirmCard() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile('games/minesweeper/popup_success_card.png'))
        .width(this.cardWidth())
        .height(this.cardHeight())
        .objectFit(ImageFit.Fill)
      Column({ space: this.contentGap() }) {
        Text('要回大厅吗？')
          .width('100%')
          .fontSize(this.titleFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor('#7a461f')
          .textAlign(TextAlign.Center)
          .textShadow({ radius: 1, color: 'rgba(255,255,255,0.72)', offsetX: 0, offsetY: 1 })
        Text('本局扫雷会暂停在这里')
          .width('100%')
          .fontSize(this.subtitleFontSize())
          .fontWeight(FontWeight.Medium)
          .fontColor('#7e6247')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.progressText())
          .width('100%')
          .fontSize(this.infoFontSize())
          .fontWeight(FontWeight.Medium)
          .fontColor('#9a7149')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 10 }) {
          MinesweeperImageButton({
            label: '继续排雷',
            imagePath: 'games/minesweeper/button_yellow.png',
            buttonWidth: this.buttonWidth(),
            buttonHeight: this.buttonHeight(),
            fontSize: this.buttonFontSize(),
            action: () => {
              this.cancelExit();
            }
          })
          MinesweeperImageButton({
            label: '回大厅',
            imagePath: 'games/minesweeper/button_green.png',
            buttonWidth: this.buttonWidth(),
            buttonHeight: this.buttonHeight(),
            fontSize: this.buttonFontSize(),
            action: () => {
              this.confirmExit();
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width(this.contentWidth())
      .alignItems(HorizontalAlign.Center)
      .position({ x: this.contentX(), y: this.contentY() })
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

  private cardWidth(): number {
    return Math.min(this.pageWidth - 24, this.pageWidth < 340 ? 330 : 382);
  }

  private cardHeight(): number {
    return Math.round(this.cardWidth() * 1008 / 1136);
  }

  private contentWidth(): number {
    return Math.round(this.cardWidth() * 0.80);
  }

  private contentX(): number {
    return Math.round((this.cardWidth() - this.contentWidth()) * 0.5);
  }

  private contentY(): number {
    return Math.round(this.cardHeight() * 0.54);
  }

  private contentGap(): number {
    return this.pageWidth < 340 ? 5 : 7;
  }

  private titleFontSize(): number {
    return this.pageWidth < 340 ? 21 : 24;
  }

  private subtitleFontSize(): number {
    return this.pageWidth < 340 ? 11 : 13;
  }

  private infoFontSize(): number {
    return this.pageWidth < 340 ? 10 : 11;
  }

  private buttonWidth(): number {
    return Math.round(this.contentWidth() * 0.44);
  }

  private buttonHeight(): number {
    return this.pageWidth < 340 ? 42 : 46;
  }

  private buttonFontSize(): number {
    return this.pageWidth < 340 ? 13 : 15;
  }

  private progressText(): string {
    return `已排查 ${this.openedSafeCells}/${this.safeCellTotal} · 用时 ${this.elapsedText}`;
  }
}
