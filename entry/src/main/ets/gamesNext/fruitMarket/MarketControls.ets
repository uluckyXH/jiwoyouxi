import { marketFruitPath } from './MarketModel';
import { MarketPalette } from './MarketPalette';

@Component
export struct MarketIconButton {
  @Prop icon: string = 'pause';
  @Prop label: string = '暂停';
  @Prop dark: boolean = false;
  @Prop primary: boolean = false;
  @Prop quiet: boolean = false;
  action: () => void = () => {};

  build() {
    Button({ type: ButtonType.Circle }) {
      Image($rawfile(MarketPalette.icon(this.icon, this.dark, this.primary ? 'primary' : '')))
        .width(21).height(21)
        .draggable(false).accessibilityLevel('no')
    }
    .width(44).height(44)
    .backgroundColor(this.primary ? MarketPalette.primary(this.dark) :
      this.quiet ? Color.Transparent : MarketPalette.surface(this.dark))
    .border({ width: this.primary || this.quiet ? 0 : 1, color: MarketPalette.line(this.dark), radius: 22 })
    .clip(true)
    .accessibilityText(this.label)
    .onClick(this.action)
  }
}

@Component
export struct MarketAction {
  @Prop label: string = '继续摆摊';
  @Prop icon: string = 'play';
  @Prop dark: boolean = false;
  @Prop primary: boolean = true;
  action: () => void = () => {};

  build() {
    Button({ type: ButtonType.Capsule }) {
      Row({ space: 8 }) {
        Image($rawfile(MarketPalette.icon(this.icon, this.dark, this.primary ? 'primary' : '')))
          .width(18).height(18)
          .draggable(false).accessibilityLevel('no')
        Text(this.label).fontSize(15).fontWeight(FontWeight.Bold)
          .fontColor(this.primary ? MarketPalette.onPrimary(this.dark) : MarketPalette.ink(this.dark))
      }.justifyContent(FlexAlign.Center)
    }
    .width('100%').height(50)
    .backgroundColor(this.primary ? MarketPalette.primary(this.dark) : MarketPalette.soft(this.dark))
    .accessibilityText(this.label).onClick(this.action)
  }
}

@Component
export struct MarketFruitImage {
  @Prop level: number = 0;
  @Prop imageSize: number = 40;

  build() {
    Image($rawfile(marketFruitPath(this.level)))
      .width(this.imageSize).height(this.imageSize).objectFit(ImageFit.Contain)
      .draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
  }
}
