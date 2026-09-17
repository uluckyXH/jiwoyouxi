import { AppIcon } from '../components/AppIcon';
import { CoopMotion } from '../design/CoopMotion';

const POSTER_ASPECT_RATIO: number = 720 / 448;
const START_BUTTON_HEIGHT: number = 48;

/** SVG scenery and button surfaces, with readable native text and a real button. */
@Component
export struct HubHeroBanner {
  @Prop isDarkMode: boolean = false;
  @Prop gameTitle: string = '鸡窝水果摊';
  startGame: () => void = () => {};
  @State private buttonPressed: boolean = false;

  build() {
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
          .height(18)
          .maxLines(1)
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
