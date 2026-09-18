import { BlockPalette as P } from './BlockPalette';

/** The base spans the whole window; only complete, transparent motifs sit in the margins. */
@Component
export struct BlockBackdrop {
  @Prop dark: boolean = false;
  @Prop areaWidth: number = 390;
  @Prop areaHeight: number = 800;
  @Prop contentWidth: number = 390;
  @Prop wide: boolean = false;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(P.scene('garden', this.dark)))
        .width('100%').height('100%').objectFit(ImageFit.Fill)
        .draggable(false).accessibilityLevel('no')
      Image($rawfile(P.scene('sprig', this.dark)))
        .width(this.wide ? 92 : 58).height(this.wide ? 180 : 113)
        .position({ x: this.wide ? Math.max(-20, (this.areaWidth - this.contentWidth) / 2 - 106) :
          this.areaWidth - 40, y: this.areaHeight * 0.55 })
        .draggable(false).accessibilityLevel('no')
      if (this.wide && this.areaWidth - this.contentWidth > 240) {
        Image($rawfile(P.scene('outline', this.dark)))
          .width(112).height(112).rotate({ angle: 8 })
          .position({ x: this.areaWidth - (this.areaWidth - this.contentWidth) / 2 + 20,
            y: this.areaHeight * 0.28 })
          .draggable(false).accessibilityLevel('no')
        Image($rawfile(P.scene('outline', this.dark)))
          .width(104).height(104).rotate({ angle: -12 })
          .position({ x: Math.max(20, (this.areaWidth - this.contentWidth) / 2 - 160), y: this.areaHeight * 0.60 })
          .draggable(false).accessibilityLevel('no')
      }
    }.width(this.areaWidth).height(this.areaHeight).clip(true).hitTestBehavior(HitTestMode.None)
      .accessibilityLevel('no')
  }
}
