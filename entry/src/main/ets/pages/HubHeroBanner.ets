import { AppIcon } from '../components/AppIcon';
import { CoopMotion } from '../design/CoopMotion';

const POSTER_ASPECT_RATIO: number = 720 / 448;
const START_BUTTON_HEIGHT: number = 48;

/** SVG scenery and button surfaces, with readable native text and a real button. */
@Component
export struct HubHeroBanner {
  @Prop isDarkMode: boolean = false;
  @Prop gameTitle: string = '鸡窝水果摊';
  @Prop spacious: boolean = false;
  @Prop compact: boolean = false;
  @Prop bannerHeight: number = 218;
  @Prop availableWidth: number = 390;
  @Prop textScale: number = 1;
  startGame: () => void = () => {};
  @State private buttonPressed: boolean = false;

  build() {
    if (this.availableWidth < 340 || this.textScale > 1.25) {
      Column({ space: 12 }) {
        Image($rawfile(this.isDarkMode ? 'app/home/home_illustration_dark.svg' : 'app/home/home_illustration_light.svg'))
          .width(120).height(94).objectFit(ImageFit.Contain).accessibilityLevel('no')
        Text('没网也能玩一窝').fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFF0D2' : '#634226').textAlign(TextAlign.Center)
        Text(this.gameTitle).fontSize(12).fontColor(this.secondaryColor()).textAlign(TextAlign.Center)
        this.StartButton()
      }.width('100%').padding(20).borderRadius(24)
      .backgroundColor(this.isDarkMode ? '#302C27' : '#FFF0D5')
      .border({ width: 1, color: this.isDarkMode ? '#584A36' : '#DFC197' })
    } else if (this.spacious || this.compact) {
      Row({ space: 20 }) {
        Image($rawfile(this.isDarkMode ? 'app/home/home_illustration_dark.svg' : 'app/home/home_illustration_light.svg'))
          .width(this.compact ? 104 : '34%')
          .height(this.bannerHeight - 36)
          .objectFit(ImageFit.Contain).borderRadius(18).clip(true)
          .draggable(false).accessibilityLevel('no')
        Column({ space: this.compact ? 5 : 10 }) {
          Text('随时来一局').fontSize(11).fontColor(this.secondaryColor()).letterSpacing(2)
          Text('没网也能玩一窝')
            .fontSize(this.compact ? 21 : 28).fontWeight(FontWeight.Bold)
            .fontColor(this.isDarkMode ? '#FFF0D2' : '#634226')
          Text(this.gameTitle).fontSize(12).fontColor(this.secondaryColor())
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
          this.StartButton()
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('100%').height(this.bannerHeight).padding({ left: 24, right: 24 })
      .borderRadius(24).clip(true)
      .backgroundColor(this.isDarkMode ? '#302C27' : '#FFF0D5')
      .border({ width: 1, color: this.isDarkMode ? '#584A36' : '#DFC197' })
    } else {
    Stack({ alignContent: Alignment.End }) {
      Image($rawfile(this.isDarkMode ? 'app/home/home_poster_dark.svg' : 'app/home/home_poster_light.svg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .hitTestBehavior(HitTestMode.None)
        .accessibilityLevel('no')
      Column({ space: 7 }) {
        Text('随时来一局')
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.secondaryColor())
          .letterSpacing(1)
          .height(14)
        Text('鸡窝游戏')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFF0D2' : '#634226')
          .height(34)
          .maxLines(1)
          .minFontSize(22)
          .maxFontSize(26)
        Text('没网也能玩一窝')
          .fontSize(11)
          .fontColor(this.secondaryColor())
          .constraintSize({ minHeight: 18 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        this.StartButton()
      }
      .width('50%')
      .padding({ right: 18 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .aspectRatio(POSTER_ASPECT_RATIO)
    .borderRadius(24)
    .clip(true)
    .backgroundColor(this.isDarkMode ? '#302C27' : '#FFF0D5')
    .border({ width: 1, color: this.isDarkMode ? '#584A36' : '#DFC197' })
    }
  }

  @Builder
  StartButton() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Stack({ alignContent: Alignment.Center }) {
        Image($rawfile(this.isDarkMode
          ? 'app/home/home_start_button_dark.svg' : 'app/home/home_start_button_light.svg'))
          .width('100%')
          .height(START_BUTTON_HEIGHT)
          .objectFit(ImageFit.Fill)
          .draggable(false)
          .hitTestBehavior(HitTestMode.None)
          .accessibilityLevel('no')
        Row({ space: 8 }) {
          Text('开始游戏')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#55351E')
          AppIcon({ name: 'play', iconSize: 15, tint: '#55351E' })
        }
        .margin({ bottom: 4 })
        .hitTestBehavior(HitTestMode.None)
      }
      .width('100%')
      .height(START_BUTTON_HEIGHT)
    }
    .width('100%')
    .constraintSize({ maxWidth: 152 })
    .height(START_BUTTON_HEIGHT)
    .padding(0)
    .borderRadius(0)
    .backgroundColor(Color.Transparent)
    .scale({ x: this.buttonPressed ? 0.97 : 1, y: this.buttonPressed ? 0.97 : 1 })
    .translate({ y: this.buttonPressed ? 1 : 0 })
    .accessibilityGroup(true)
    .accessibilityText(`开始游戏，${this.gameTitle}`)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.setButtonPressed(true);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.setButtonPressed(false);
      }
    })
    .onClick(() => this.startGame())
  }

  private setButtonPressed(pressed: boolean): void {
    this.getUIContext().animateTo({ duration: CoopMotion.pressDuration, curve: Curve.EaseOut }, () => {
      this.buttonPressed = pressed;
    });
  }

  private secondaryColor(): string {
    return this.isDarkMode ? '#D1B991' : '#906C46';
  }
}
