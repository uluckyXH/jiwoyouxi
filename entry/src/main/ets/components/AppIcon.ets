/** Small, monochrome SVGs. Tint follows the surrounding UI theme and state. */
@Component
export struct AppIcon {
  @Prop name: string = 'home';
  @Prop iconSize: number = 24;
  @Prop tint: string = '#895A39';

  build() {
    Image($rawfile(`app/ui/icons/${this.name}.svg`))
      .width(this.iconSize)
      .height(this.iconSize)
      .objectFit(ImageFit.Contain)
      .fillColor(this.tint)
      .draggable(false)
      .hitTestBehavior(HitTestMode.None)
      .accessibilityLevel('no')
  }
}
