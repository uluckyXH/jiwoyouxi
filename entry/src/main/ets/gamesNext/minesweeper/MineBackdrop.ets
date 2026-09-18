import { MINE_ASSETS } from './MineModel';

// Separate SVG layers stay at the usable area's edges on tall phones, tablets
// and half-fold panes. No Cover crop, timer, particle loop or touch interception.
@Component
export struct MineBackdrop {
  @Prop dark: boolean = false;
  @Prop areaWidth: number = 390;
  @Prop areaHeight: number = 800;

  private scene(name: string): Resource {
    return $rawfile(`${MINE_ASSETS}scene/${name}_${this.dark ? 'dark' : 'light'}.svg`);
  }

  private cornerWidth(): number { return Math.min(172, Math.max(100, this.areaWidth * 0.22)); }
  private contourWidth(): number { return Math.min(300, Math.max(152, this.areaWidth * 0.36)); }
  private groundHeight(): number { return Math.min(180, this.areaHeight * 0.22); }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image(this.scene('garden')).width(this.areaWidth).height(this.groundHeight()).objectFit(ImageFit.Fill)
        .position({ x: 0, y: this.areaHeight - this.groundHeight() })
      Image(this.scene('contour')).width(this.contourWidth()).height(this.contourWidth())
        .position({ x: this.areaWidth - this.contourWidth(), y: 0 })
      Image(this.scene('fern_left')).width(this.cornerWidth()).height(this.cornerWidth() * 1.2)
        .position({ x: 0, y: this.areaHeight - this.cornerWidth() * 1.2 })
      Image(this.scene('fern_right')).width(this.cornerWidth()).height(this.cornerWidth() * 1.2)
        .position({ x: this.areaWidth - this.cornerWidth(), y: this.areaHeight - this.cornerWidth() * 1.2 })
    }.width(this.areaWidth).height(this.areaHeight).clip(true)
    .hitTestBehavior(HitTestMode.None).accessibilityLevel('no-hide-descendants')
  }
}
