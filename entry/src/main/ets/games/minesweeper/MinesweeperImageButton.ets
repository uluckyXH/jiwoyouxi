import { CoopMotion } from '../../design/CoopMotion';

@Component
export struct MinesweeperImageButton {
  @Prop label: string = '';
  @Prop imagePath: string = 'games/minesweeper/button_yellow.png';
  @Prop buttonWidth: number = 132;
  @Prop buttonHeight: number = 46;
  @Prop fontSize: number = 17;
  @Prop textColor: string = '#fff7df';
  action: () => void = () => {};
  @State private pressed: boolean = false;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Image($rawfile(this.imagePath))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
      Text(this.label)
        .width('100%')
        .fontSize(this.fontSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textShadow({ radius: 2, color: 'rgba(72,50,20,0.58)', offsetX: 0, offsetY: 1 })
    }
    .width(this.buttonWidth)
    .height(this.buttonHeight)
    .scale({
      x: this.pressed ? CoopMotion.pressScale : 1,
      y: this.pressed ? CoopMotion.pressScale : 1
    })
    .opacity(this.pressed ? 0.96 : 1)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.setPressed(true);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.setPressed(false);
      }
    })
    .onClick(() => {
      this.action();
    })
  }

  private setPressed(pressed: boolean): void {
    if (this.pressed === pressed) {
      return;
    }
    this.getUIContext().animateTo({
      duration: CoopMotion.pressDuration,
      curve: Curve.EaseOut
    }, () => {
      this.pressed = pressed;
    });
  }
}
