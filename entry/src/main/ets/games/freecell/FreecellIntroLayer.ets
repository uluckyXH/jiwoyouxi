import { FreecellMotion } from './FreecellMotion';

@Component
export struct FreecellIntroLayer {
  @Prop sceneVisible: boolean = false;
  backgroundReady: () => void = () => {};
  backgroundFailed: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile('games/freecell/page_bg_coop_garden.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(this.sceneVisible ? 1 : 0)
        .animation({ duration: FreecellMotion.sceneRevealDuration, curve: Curve.EaseOut })
        .onComplete(() => {
          this.backgroundReady();
        })
        .onError(() => {
          this.backgroundFailed();
        })
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(255,251,232,0.08)')
        .opacity(this.sceneVisible ? 1 : 0)
        .animation({ duration: FreecellMotion.sceneRevealDuration, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }
}
