import { CoopMotion } from '../design/CoopMotion';
import { hubCardLogoSize, hubCardStacked } from '../design/HubLayout';
import { GameModule } from '../shell/GameModule';
import { moduleById } from '../shell/GameRegistry';
import { HubGameLogoTile } from './HubGameLogoTile';

/** Compact rounded cards; large type can fall back to a full-width text area. */
@Component
export struct HubGameCard {
  @Prop game: GameModule = moduleById('suika');
  @Prop subtitle: string = '';
  @Prop detail: string = '';
  @Prop favorite: boolean = false;
  @Prop dark: boolean = false;
  @Prop textScale: number = 1;
  @Prop cardWidth: number = 170;
  launch: (id: string) => void = () => {};
  toggleFavorite: (id: string) => void = () => {};
  @State private pressed: boolean = false;

  build() {
    Stack({ alignContent: this.stacked() ? Alignment.TopEnd : Alignment.End }) {
      Button({ type: ButtonType.Normal, stateEffect: false }) {
        if (this.stacked()) {
          Column({ space: 6 }) {
            Row() {
              HubGameLogoTile({ gameId: this.game.id, tileSize: this.logoSize(), imageSize: this.logoSize() - 4,
                isDarkMode: this.dark })
              Blank()
            }.width('100%').height(36)
            this.CardText()
          }.width('100%').height('100%').justifyContent(FlexAlign.Center)
          .padding({ left: 12, right: 12, top: 8, bottom: 12 })
        } else {
          Row({ space: 6 }) {
            HubGameLogoTile({ gameId: this.game.id, tileSize: this.logoSize(), imageSize: this.logoSize() - 4,
              isDarkMode: this.dark })
            Column() { this.CardText() }.layoutWeight(1)
          }.width('100%').height('100%').alignItems(VerticalAlign.Center)
          // The favorite has its own trailing space, so content can stay vertically centered.
          .padding({ left: 12, right: 44, top: 12, bottom: 12 })
        }
      }
      .width('100%').height('100%').padding(0).borderRadius(20)
      .backgroundColor(Color.Transparent)
      .accessibilityText(`打开${this.game.title}，${this.subtitle}`)
      .onTouch((event: TouchEvent) => {
        this.pressed = event.type === TouchType.Down;
      })
      .onClick(() => this.launch(this.game.id))

      this.FavoriteButton()
    }
    .width('100%').height(this.cardHeight())
    .borderRadius(20)
    .clip(true)
    .backgroundColor(this.dark ? '#25221E' : '#FFFDF8')
    .border({ width: 1, radius: 20,
      color: this.dark ? 'rgba(255,231,196,0.18)' : 'rgba(126,78,35,0.16)' })
    .shadow({ radius: 12, color: this.dark ? 'rgba(0,0,0,0.36)' : 'rgba(112,69,28,0.16)', offsetY: 4 })
    .scale({ x: this.pressed ? CoopMotion.pressScale : 1, y: this.pressed ? CoopMotion.pressScale : 1 })
    .animation({ duration: CoopMotion.pressDuration, curve: Curve.EaseOut })
  }

  @Builder
  CardText() {
    Column({ space: 2 }) {
      Text(this.game.title).width('100%').fontSize(12).lineHeight(16)
        .fontWeight(600).fontColor(this.ink())
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.detail.length > 0 ? this.detail : this.subtitle).width('100%')
        .fontSize(9).lineHeight(12).fontWeight(FontWeight.Medium).fontColor(this.muted())
        .maxLines(this.detail.length > 0 ? 2 : 1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  FavoriteButton() {
    Button({ type: ButtonType.Circle }) {
      Stack() {
        // Keep the SVG's explicit fill: tinting an outline SVG makes both states look filled.
        Image($rawfile(`app/home/favorite_${this.favorite ? 'on' : 'off'}_${this.dark ? 'dark' : 'light'}.svg`))
          .width(16).height(16).objectFit(ImageFit.Contain)
          .draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      }
      .width(24).height(24).borderRadius(12)
      .backgroundColor(this.favorite ? (this.dark ? '#62431E' : '#FFE3A4') : (this.dark ? '#312C25' : '#FFFDF8'))
      .border({ width: 1, radius: 12,
        color: this.favorite ? (this.dark ? '#B98A3F' : '#D9A33B') : (this.dark ? '#80705A' : '#CDBB9F') })
    }
    .width(44).height(44).padding(0).backgroundColor(Color.Transparent)
    .accessibilityText(`${this.favorite ? '取消收藏' : '收藏'}${this.game.title}，${this.subtitle}`)
    .onClick(() => this.toggleFavorite(this.game.id))
  }

  private ink(): string { return this.dark ? '#FFF2DF' : '#2F1D14'; }
  private stacked(): boolean { return hubCardStacked(this.cardWidth, this.textScale); }
  private cardHeight(): number {
    const baseHeight = this.stacked() ? 112 : 80;
    const hasDetail = this.detail.length > 0;
    // Allow two title lines and scale the text area only when system type grows.
    return baseHeight + (hasDetail ? 12 : 0) + (hasDetail ? 56 : 44) * (this.textScale - 1);
  }
  private logoSize(): number { return hubCardLogoSize(this.cardWidth); }
  private muted(): string { return this.dark ? '#C8B7A2' : '#786555'; }
}
