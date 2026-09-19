import { BloomPalette as P } from './BloomPalette';

@Component
export struct BloomBackdrop {
  @Prop dark: boolean = false;
  @Prop canvasWidth: number = 390;
  @Prop canvasHeight: number = 844;
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(P.scene('atmosphere', this.dark))).width('100%').height('100%').objectFit(ImageFit.Fill)
      Image($rawfile(P.scene('window', this.dark))).width(Math.min(380, this.canvasWidth * .68)).aspectRatio(320 / 440)
        .position({ x: this.canvasWidth - Math.min(380, this.canvasWidth * .68) + 16, y: -20 })
      Image($rawfile(P.scene('garden', this.dark))).width(Math.min(260, this.canvasWidth * .4)).aspectRatio(240 / 300)
        .position({ x: -20, y: this.canvasHeight - Math.min(260, this.canvasWidth * .4) * 300 / 240 + 8 })
      Image($rawfile(P.scene('stilllife', this.dark))).width(Math.min(360, this.canvasWidth * .58)).aspectRatio(320 / 210)
        .position({ x: this.canvasWidth - Math.min(360, this.canvasWidth * .58) + 4,
          y: this.canvasHeight - Math.min(360, this.canvasWidth * .58) * 210 / 320 + 4 })
      Image($rawfile(P.scene('edge_fade', this.dark))).width('100%').height('100%').objectFit(ImageFit.Fill)
    }.width(this.canvasWidth).height(this.canvasHeight).clip(true)
    .hitTestBehavior(HitTestMode.None).accessibilityLevel('no-hide-descendants')
  }
}
