import { CoopTheme } from '../../design/CoopTheme';
import { DIFFICULTIES, MineDifficulty } from './MinesweeperTypes';

@Component
export struct MinesweeperHud {
  @Prop pageWidth: number = 390;
  @Prop bestScore: number = 0;
  @Prop currentScore: number = 0;
  @Prop remainingMines: number = 0;
  @Prop elapsedText: string = '00:00';
  @Prop paused: boolean = false;
  @Prop flagMode: boolean = false;
  @Prop flagLimitReached: boolean = false;
  @Prop devRevealMines: boolean = false;
  @Prop showDevControls: boolean = false;
  @Prop difficultyKey: string = 'easy';
  @Prop showDifficultyBar: boolean = false;
  exitToHub: () => void = () => {};
  togglePause: () => void = () => {};
  selectDifficulty: (key: string) => void = () => {};
  toggleFlagMode: () => void = () => {};
  toggleDevRevealMines: () => void = () => {};
  restartGame: () => void = () => {};

  build() {
    Column({ space: 8 }) {
      this.TopBar()
      if (this.showDifficultyBar) {
        this.DifficultyBar()
      }
      this.ActionBar()
    }
    .width('100%')
  }

  @Builder
  TopBar() {
    Stack() {
      Image($rawfile('games/minesweeper/panel_wood_long.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
      Row({ space: this.topGap() }) {
        Row({ space: this.leftGap() }) {
          Text('大厅')
            .width(this.hubButtonWidth())
            .height(this.pauseButtonHeight())
            .fontSize(this.hubFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor('#6c421f')
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.exitToHub();
            })
          Text('|')
            .fontSize(this.dividerFontSize())
            .fontColor('rgba(114,76,42,0.28)')
          Text(this.flagMode ? '旗' : '鸡雷')
            .fontSize(this.mineLabelFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor('#6c421f')
          Text(`${this.remainingMines}`)
            .fontSize(this.mineCountFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor('#b93d2e')
        }
        .width(this.leftInfoWidth())
        .height('100%')
        .alignItems(VerticalAlign.Center)

        Column({ space: 0 }) {
          Text(this.elapsedText)
            .width('100%')
            .fontSize(this.timerFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor('#3e2212')
            .textAlign(TextAlign.Center)
            .maxLines(1)
          Text(`最高 ${Math.max(this.bestScore, this.currentScore)}`)
            .width('100%')
            .fontSize(this.bestScoreFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor('#80603f')
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width(this.timerWidth())
        .height('100%')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)

        this.SmallWoodButton(this.paused ? '继续' : '暂停', () => {
          this.togglePause();
        })
      }
      .width('100%')
      .height('100%')
      .padding({ left: this.topInnerPadding(), right: this.topInnerPadding(), top: 16, bottom: 14 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(138)
    .padding({ left: this.topOuterPadding(), right: this.topOuterPadding(), top: 42 })
  }

  @Builder
  DifficultyBar() {
    Row({ space: 8 }) {
      ForEach(DIFFICULTIES, (item: MineDifficulty) => {
        this.DifficultyButton(item)
      }, (item: MineDifficulty) => item.key)
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
  }

  @Builder
  ActionBar() {
    Row({ space: 6 }) {
      this.ModeImageButton(() => {
        this.toggleFlagMode();
      })
      this.ActionImageButton('重新开始', 'yellow', 'games/minesweeper/icon_reset.png', () => {
        this.restartGame();
      })
      if (this.showDevControls) {
        this.DevImageButton(() => {
          this.toggleDevRevealMines();
        })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
  }

  @Builder
  DifficultyButton(item: MineDifficulty) {
    Stack() {
      if (this.difficultyKey === item.key) {
        Image($rawfile('games/minesweeper/button_blue_flower.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
      } else if (item.key === 'hard') {
        Image($rawfile('games/minesweeper/button_wood_small_right.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
      } else {
        Image($rawfile('games/minesweeper/button_wood_small_left.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
      }
      Text(item.label)
        .width('100%')
        .height('100%')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.difficultyKey === item.key ? '#fff8e8' : '#5a3219')
        .textAlign(TextAlign.Center)
        .textShadow({
          radius: 1,
          color: this.difficultyKey === item.key ? 'rgba(25,64,120,0.52)' : 'rgba(255,255,255,0.58)',
          offsetX: 0,
          offsetY: 1
        })
    }
    .height(54)
    .layoutWeight(1)
    .onClick(() => {
      this.selectDifficulty(item.key);
    })
  }

  @Builder
  ModeImageButton(action: () => void) {
    Stack() {
      if (this.flagMode) {
        Image($rawfile('games/minesweeper/button_blue_flower.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
      } else {
        Image($rawfile('games/minesweeper/button_green.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
      }
      Row({ space: 5 }) {
        Image($rawfile('games/minesweeper/icon_flag_piece.png'))
          .width(this.actionIconSize())
          .height(this.actionIconSize())
          .objectFit(ImageFit.Contain)
          .opacity(this.flagMode ? 1 : 0.78)
        Text(this.modeButtonText())
          .fontSize(this.actionTitleFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(this.flagLimitReached ? '#fff2a8' : '#fff7df')
          .textAlign(TextAlign.Center)
          .textShadow({ radius: 2, color: 'rgba(72,50,20,0.58)', offsetX: 0, offsetY: 1 })
      }
      .width('100%')
      .height('100%')
      .padding({ left: this.actionHorizontalPadding(), right: this.actionHorizontalPadding() })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .height(58)
    .layoutWeight(1)
    .onClick(() => {
      action();
    })
  }

  @Builder
  ActionImageButton(label: string, variant: string, iconPath: string, action: () => void) {
    Stack() {
      if (variant === 'green') {
        Image($rawfile('games/minesweeper/button_green.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
      } else {
        Image($rawfile('games/minesweeper/button_yellow.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
      }
      Row({ space: 6 }) {
        Image($rawfile(iconPath))
          .width(this.actionIconSize())
          .height(this.actionIconSize())
          .objectFit(ImageFit.Contain)
        Text(label)
          .fontSize(this.actionTitleFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor('#fff7df')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textShadow({ radius: 2, color: 'rgba(72,50,20,0.58)', offsetX: 0, offsetY: 1 })
      }
        .width('100%')
        .height('100%')
        .padding({ left: this.actionHorizontalPadding(), right: this.actionHorizontalPadding() })
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }
    .height(58)
    .layoutWeight(1)
    .onClick(() => {
      action();
    })
  }

  @Builder
  DevImageButton(action: () => void) {
    Stack() {
      if (this.devRevealMines) {
        Image($rawfile('games/minesweeper/button_blue_flower.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
      } else {
        Image($rawfile('games/minesweeper/button_wood_small_right.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
      }
      Column({ space: 0 }) {
        Text(this.devRevealMines ? '藏鸡雷' : '显鸡雷')
          .fontSize(this.devButtonFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(this.devRevealMines ? '#fff7df' : '#5a3219')
          .textAlign(TextAlign.Center)
          .textShadow({
            radius: 1,
            color: this.devRevealMines ? 'rgba(25,64,120,0.52)' : 'rgba(255,255,255,0.58)',
            offsetX: 0,
            offsetY: 1
          })
        Text('DEV')
          .fontSize(this.devCaptionFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(this.devRevealMines ? '#fff2a8' : 'rgba(90,50,25,0.62)')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 4, right: 4 })
    }
    .height(58)
    .layoutWeight(0.72)
    .onClick(() => {
      action();
    })
  }

  @Builder
  SmallWoodButton(label: string, action: () => void) {
    Stack() {
      Image($rawfile('games/minesweeper/button_wood_small_right.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
      Text(label)
        .width('100%')
        .height('100%')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#4d2a15')
        .textAlign(TextAlign.Center)
        .textShadow({ radius: 1, color: 'rgba(255,255,255,0.62)', offsetX: 0, offsetY: 1 })
    }
    .width(this.pauseButtonWidth())
    .height(this.pauseButtonHeight())
    .onClick(() => {
      action();
    })
  }

  private topOuterPadding(): number {
    return this.pageWidth < 340 ? 6 : 10;
  }

  private topInnerPadding(): number {
    return this.pageWidth < 340 ? 12 : this.pageWidth < 390 ? 16 : 22;
  }

  private topContentWidth(): number {
    return Math.max(220, this.pageWidth - this.topOuterPadding() * 2 - this.topInnerPadding() * 2);
  }

  private topGap(): number {
    return this.pageWidth < 340 ? 4 : 8;
  }

  private leftGap(): number {
    return this.pageWidth < 340 ? 2 : 4;
  }

  private leftInfoWidth(): number {
    return Math.floor(Math.max(88, Math.min(122, this.topContentWidth() * 0.36)));
  }

  private timerWidth(): number {
    return Math.max(96, this.topContentWidth() - this.leftInfoWidth() - this.pauseButtonWidth() - this.topGap() * 2);
  }

  private hubButtonWidth(): number {
    return this.pageWidth < 340 ? 38 : 48;
  }

  private pauseButtonWidth(): number {
    return this.pageWidth < 340 ? 54 : 68;
  }

  private pauseButtonHeight(): number {
    return this.pageWidth < 340 ? 34 : 40;
  }

  private hubFontSize(): number {
    return this.pageWidth < 340 ? 13 : 16;
  }

  private dividerFontSize(): number {
    return this.pageWidth < 340 ? 16 : 20;
  }

  private mineLabelFontSize(): number {
    return this.pageWidth < 340 ? 11 : 14;
  }

  private mineCountFontSize(): number {
    return this.pageWidth < 340 ? 16 : 20;
  }

  private timerFontSize(): number {
    return this.pageWidth < 340 ? 22 : this.pageWidth < 390 ? 26 : 30;
  }

  private bestScoreFontSize(): number {
    return this.pageWidth < 340 ? 10 : 13;
  }

  private actionIconSize(): number {
    return this.pageWidth < 340 ? 22 : 27;
  }

  private actionTitleFontSize(): number {
    return this.pageWidth < 340 ? 14 : 17;
  }

  private modeButtonText(): string {
    if (this.flagMode && this.flagLimitReached) {
      return '旗已满';
    }
    return this.flagMode ? '插旗中' : '排雷中';
  }

  private actionHorizontalPadding(): number {
    return this.pageWidth < 340 ? 5 : 8;
  }

  private devButtonFontSize(): number {
    return this.pageWidth < 340 ? 12 : 14;
  }

  private devCaptionFontSize(): number {
    return this.pageWidth < 340 ? 8 : 9;
  }
}
