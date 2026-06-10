import { CoopMotion } from '../design/CoopMotion';

@Component
export struct GameSceneTransition {
  @Prop role: string = 'hub';
  @Prop sceneDirection: string = 'push';
  @BuilderParam content: () => void = this.EmptyContent;

  build() {
    Stack() {
      this.content()
    }
    .width('100%')
    .height('100%')
    .transition(this.sceneTransition())
  }

  @Builder
  EmptyContent() {
  }

  private sceneTransition(): TransitionEffect {
    return TransitionEffect.asymmetric(this.enterEffect(), this.exitEffect());
  }

  private enterEffect(): TransitionEffect {
    return TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ x: this.enterOffset(), y: 0 }))
      .combine(TransitionEffect.scale({ x: CoopMotion.sceneScaleFrom, y: CoopMotion.sceneScaleFrom }))
      .animation({ duration: this.duration(), curve: Curve.Friction });
  }

  private exitEffect(): TransitionEffect {
    return TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ x: this.exitOffset(), y: 0 }))
      .combine(TransitionEffect.scale({ x: CoopMotion.sceneScaleFrom, y: CoopMotion.sceneScaleFrom }))
      .animation({ duration: this.duration(), curve: Curve.Friction });
  }

  private enterOffset(): number {
    if (this.role === 'hub') {
      return this.sceneDirection === 'pop' ? -CoopMotion.scenePopOffsetVp : 0;
    }
    return this.sceneDirection === 'push' ? CoopMotion.scenePushOffsetVp : 0;
  }

  private exitOffset(): number {
    if (this.role === 'hub') {
      return this.sceneDirection === 'push' ? -CoopMotion.scenePopOffsetVp : 0;
    }
    return this.sceneDirection === 'pop' ? CoopMotion.scenePushOffsetVp : 0;
  }

  private duration(): number {
    return this.sceneDirection === 'pop' ? CoopMotion.scenePopDuration : CoopMotion.scenePushDuration;
  }
}
