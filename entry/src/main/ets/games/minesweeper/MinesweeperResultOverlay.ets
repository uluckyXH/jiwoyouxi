import { CoopModalTransition } from '../../components/CoopModalTransition';
import { MinesweeperFeatherLayer } from './MinesweeperFeatherLayer';
import { MinesweeperTheme } from './MinesweeperTheme';

@Component
export struct MinesweeperResultOverlay {
  @Prop win: boolean = false;
  @Prop pageWidth: number = 390;
  @Prop pageHeight: number = 760;
  @Prop elapsedText: string = '00:00';
  @Prop currentScore: number = 0;
  @Prop bestScore: number = 0;
  @Prop openedSafeCells: number = 0;
  @Prop safeCellTotal: number = 54;
  restartGame: () => void = () => {};
  exitToHub: () => void = () => {};
  closeOverlay: () => void = () => {};

  build() {
    CoopModalTransition({
      maskColor: 'rgba(22,13,8,0.42)'
    }) {
      Stack({ alignContent: Alignment.Center }) {
        MinesweeperFeatherLayer({
          win: this.win,
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
        Text(this.win ? MinesweeperTheme.winTitle : MinesweeperTheme.loseTitle)
          .width('100%')
          .fontSize(this.titleFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(this.win ? '#946112' : '#794022')
          .textAlign(TextAlign.Center)
          .textShadow({ radius: 1, color: 'rgba(255,255,255,0.72)', offsetX: 0, offsetY: 1 })
        Text(this.subtitleText())
          .width('100%')
          .fontSize(this.subtitleFontSize())
          .fontColor('#7e6247')
          .textAlign(TextAlign.Center)
          .maxLines(1)
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
          this.ImageButton('再来一局', 'games/minesweeper/button_yellow.png', () => {
            this.restartGame();
          })
          this.ImageButton('回大厅', 'games/minesweeper/button_green.png', () => {
            this.exitToHub();
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
  ImageButton(label: string, imagePath: string, action: () => void) {
    Stack() {
      Image($rawfile(imagePath))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
      Text(label)
        .width('100%')
        .height('100%')
        .fontSize(this.buttonFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor('#fff7df')
        .textAlign(TextAlign.Center)
        .textShadow({ radius: 2, color: 'rgba(72,50,20,0.58)', offsetX: 0, offsetY: 1 })
    }
    .width(this.buttonWidth())
    .height(this.buttonHeight())
    .onClick(() => {
      action();
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
    return this.win ? 'games/minesweeper/popup_success_card.png' : 'games/minesweeper/popup_failure_card.png';
  }

  private cardWidth(): number {
    return Math.min(this.pageWidth - 24, this.pageWidth < 340 ? 330 : 382);
  }

  private cardHeight(): number {
    return Math.round(this.cardWidth() * (this.win ? 1004 / 1132 : 970 / 1259));
  }

  private contentWidth(): number {
    return Math.round(this.cardWidth() * 0.78);
  }

  private contentX(): number {
    return Math.round((this.cardWidth() - this.contentWidth()) * 0.5);
  }

  private contentY(): number {
    return Math.round(this.cardHeight() * (this.win ? 0.54 : 0.48));
  }

  private closeY(): number {
    return Math.round(this.cardHeight() * (this.win ? 0.31 : 0.33));
  }

  private contentGap(): number {
    return this.pageWidth < 340 ? 5 : 7;
  }

  private titleFontSize(): number {
    return this.pageWidth < 340 ? 23 : 27;
  }

  private subtitleFontSize(): number {
    return this.pageWidth < 340 ? 12 : 14;
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
    return this.pageWidth < 340 ? 15 : 17;
  }

  private subtitleText(): string {
    return this.win ? '所有鸡雷都被你避开了。' : '鸡窝里混进了鸡雷，再试一次。';
  }

  private infoText(): string {
    if (this.win) {
      return `用时 ${this.elapsedText} · 得分 ${this.currentScore} · 最高 ${Math.max(this.bestScore, this.currentScore)}`;
    }
    return `已排查 ${this.openedSafeCells}/${this.safeCellTotal}`;
  }
}
