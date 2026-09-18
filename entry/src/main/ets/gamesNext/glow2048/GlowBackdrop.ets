import { GlowPalette as P } from './GlowPalette';

@Component
export struct GlowBackdrop {
  @Prop dark: boolean = false;
  @Prop canvasWidth: number = 390;
  @Prop canvasHeight: number = 800;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(P.scene('atmosphere', this.dark)))
        .width('100%').height('100%').objectFit(ImageFit.Fill)
      Image($rawfile(P.scene('window', this.dark)))
        .width(Math.min(380, this.canvasWidth * .64)).aspectRatio(320 / 440)
        .position({ x: this.canvasWidth - Math.min(380, this.canvasWidth * .64) + 16, y: -28 })
      Image($rawfile(P.scene('garden', this.dark)))
        .width(Math.min(250, this.canvasWidth * .37)).aspectRatio(260 / 300)
        .position({ x: -18, y: this.canvasHeight - Math.min(250, this.canvasWidth * .37) * 300 / 260 + 8 })
      Image($rawfile(P.scene('stilllife', this.dark)))
        .width(Math.min(350, this.canvasWidth * .53)).aspectRatio(320 / 200)
        .position({ x: this.canvasWidth - Math.min(350, this.canvasWidth * .53) + 14,
          y: this.canvasHeight - Math.min(350, this.canvasWidth * .53) * 200 / 320 + 8 })
    }.width(this.canvasWidth).height(this.canvasHeight).clip(true)
    .hitTestBehavior(HitTestMode.None).accessibilityLevel('no-hide-descendants')
  }
}
