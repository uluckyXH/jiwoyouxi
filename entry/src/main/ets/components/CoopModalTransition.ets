import { CoopMotion } from '../design/CoopMotion';

@Component
export struct CoopModalTransition {
  @Prop maskColor: string = 'rgba(22,13,8,0.42)';
  @Prop panelScaleFrom: number = CoopMotion.modalScaleFrom;
  @Prop panelOffsetVp: number = CoopMotion.modalOffsetVp;
  @BuilderParam content: () => void = this.EmptyContent;
  @State private active: boolean = false;

  aboutToAppear(): void {
    this.active = false;
    setTimeout(() => {
      this.getUIContext().animateTo({
        duration: CoopMotion.modalDuration,
        curve: Curve.Friction
      }, () => {
        this.active = true;
      });
    }, 20);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Rect()
        .width('100%')
        .height('100%')
        .fill(this.maskColor)
        .opacity(this.active ? 1 : 0)
        .animation({ duration: CoopMotion.modalMaskDuration, curve: Curve.EaseOut })

      Stack({ alignContent: Alignment.Center }) {
        this.content()
      }
      .width('100%')
      .height('100%')
      .opacity(this.active ? 1 : 0)
      .scale({
        x: this.active ? 1 : this.panelScaleFrom,
        y: this.active ? 1 : this.panelScaleFrom
      })
      .translate({ x: 0, y: this.active ? 0 : this.panelOffsetVp })
      .animation({ duration: CoopMotion.modalDuration, curve: Curve.Friction })
    }
    .width('100%')
    .height('100%')
    .transition(TransitionEffect.OPACITY.animation({
      duration: CoopMotion.modalMaskDuration,
      curve: Curve.EaseOut
    }))
  }

  @Builder
  EmptyContent() {
  }
}
