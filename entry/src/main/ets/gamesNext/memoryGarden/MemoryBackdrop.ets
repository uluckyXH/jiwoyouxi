import { MemoryPalette as P } from './MemoryPalette';
@Component
export struct MemoryBackdrop {
  @Prop dark: boolean = false;
  @Prop canvasWidth: number = 390;
  @Prop canvasHeight: number = 844;
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(P.scene('atmosphere', this.dark))).width('100%').height('100%').objectFit(ImageFit.Fill)
      Image($rawfile(P.scene('canopy', this.dark))).width(Math.min(480, this.canvasWidth * .85)).aspectRatio(380 / 270)
        .position({ x: this.canvasWidth - Math.min(480, this.canvasWidth * .85), y: -12 })
      Image($rawfile(P.scene('garden', this.dark))).width(Math.min(270, this.canvasWidth * .42)).aspectRatio(250 / 270)
        .position({ x: -12, y: this.canvasHeight - Math.min(270, this.canvasWidth * .42) * 270 / 250 })
      Image($rawfile(P.scene('stilllife', this.dark))).width(Math.min(370, this.canvasWidth * .64)).aspectRatio(320 / 205)
        .position({ x: this.canvasWidth - Math.min(370, this.canvasWidth * .64) + 7,
          y: this.canvasHeight - Math.min(370, this.canvasWidth * .64) * 205 / 320 })
      Image($rawfile(P.scene('edge_fade', this.dark))).width('100%').height('100%').objectFit(ImageFit.Fill)
    }.width(this.canvasWidth).height(this.canvasHeight).clip(true)
    .hitTestBehavior(HitTestMode.None).accessibilityLevel('no-hide-descendants')
  }
}
