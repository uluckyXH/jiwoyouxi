import { CoopMotion } from '../design/CoopMotion';

@Component
export struct MotionPressable {
  @Prop pressEnabled: boolean = true;
  @Prop pressScale: number = CoopMotion.pressScale;
  @Prop pressedOpacity: number = 0.96;
  action: () => void = () => {};
  @BuilderParam content: () => void = this.EmptyContent;
  @State private pressed: boolean = false;

  build() {
    Stack() {
      this.content()
    }
    .width('100%')
    .scale({
      x: this.pressEnabled && this.pressed ? this.pressScale : 1,
      y: this.pressEnabled && this.pressed ? this.pressScale : 1
    })
    .opacity(this.pressEnabled && this.pressed ? this.pressedOpacity : 1)
    .onTouch((event: TouchEvent) => {
      if (!this.pressEnabled) {
        return;
      }
      if (event.type === TouchType.Down) {
        this.setPressed(true);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.setPressed(false);
      }
    })
    .onClick(() => {
      if (this.pressEnabled) {
        this.action();
      }
    })
  }

  @Builder
  EmptyContent() {
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
