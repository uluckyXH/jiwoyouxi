import { CoopMotion } from '../design/CoopMotion';
import { hubCardStacked } from '../design/HubLayout';
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
    Stack({ alignContent: Alignment.TopEnd }) {
      Button({ type: ButtonType.Normal, stateEffect: false }) {
        Stack({ alignContent: Alignment.TopStart }) {
          Row().width(34).height(3).borderRadius(2)
            .backgroundColor(this.game.accent).opacity(this.dark ? 0.72 : 0.58)
            .position({ x: 12, y: 13 })
          if (this.stacked()) {
            Column({ space: 6 }) {
              Row() {
                HubGameLogoTile({ gameId: this.game.id, tileSize: 44, imageSize: 40, isDarkMode: this.dark })
                Blank()
              }.width('100%')
              this.CardText()
            }.width('100%').padding({ left: 12, right: 12, top: 22, bottom: 6 })
          } else {
            Row({ space: 8 }) {
              HubGameLogoTile({ gameId: this.game.id, tileSize: this.logoSize(), imageSize: this.logoSize() - 4,
                isDarkMode: this.dark })
              Column() { this.CardText() }.layoutWeight(1)
            }.width('100%').height('100%').alignItems(VerticalAlign.Center)
            // Keep text below the complete 44 vp favorite target, even with two title lines.
            .padding({ left: 12, right: 12, top: 44, bottom: 6 })
          }
        }.width('100%').height('100%')
      }
      .width('100%').height('100%').padding(0).borderRadius(20)
      .backgroundColor(Color.Transparent)
      .accessibilityText(`打开${this.game.title}，${this.subtitle}`)
      .onTouch((event: TouchEvent) => {
        this.pressed = event.type === TouchType.Down;
      })
      .onClick(() => this.launch(this.game.id))

      Column() {
        this.FavoriteButton()
      }.width(44).height(44).margin({ right: 2, top: 0 })
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
      Text(this.game.title).width('100%').fontSize(14).lineHeight(18)
        .fontWeight(FontWeight.Bold).fontColor(this.ink())
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.detail.length > 0 ? this.detail : this.subtitle).width('100%')
        .fontSize(10).lineHeight(14).fontWeight(FontWeight.Medium).fontColor(this.muted())
        .maxLines(this.detail.length > 0 ? 2 : 1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  FavoriteButton() {
    Button({ type: ButtonType.Circle }) {
      Stack() {
        // Keep the SVG's explicit fill: tinting an outline SVG makes both states look filled.
        Image($rawfile(`app/home/favorite_${this.favorite ? 'on' : 'off'}_${this.dark ? 'dark' : 'light'}.svg`))
          .width(18).height(18).objectFit(ImageFit.Contain)
          .draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      }
      .width(26).height(26).borderRadius(13)
      .backgroundColor(this.favorite ? (this.dark ? '#62431E' : '#FFE3A4') : (this.dark ? '#312C25' : '#FFFDF8'))
      .border({ width: 1.5, radius: 13,
        color: this.favorite ? (this.dark ? '#B98A3F' : '#D9A33B') : (this.dark ? '#80705A' : '#CDBB9F') })
    }
    .width(44).height(44).padding(0).backgroundColor(Color.Transparent)
    .accessibilityText(`${this.favorite ? '取消收藏' : '收藏'}${this.game.title}，${this.subtitle}`)
    .onClick(() => this.toggleFavorite(this.game.id))
  }

  private ink(): string { return this.dark ? '#FFF2DF' : '#2F1D14'; }
  private stacked(): boolean { return hubCardStacked(this.cardWidth, this.textScale); }
  private cardHeight(): number {
    const baseHeight = this.stacked() ? 132 : 104;
    // Only saved-game details need a second subtitle line; normal home cards stay short.
    return baseHeight + (this.detail.length > 0 ? 14 : 0) + 64 * (this.textScale - 1);
  }
  private logoSize(): number { return this.cardWidth < 200 ? 44 : 52; }
  private muted(): string { return this.dark ? '#C8B7A2' : '#786555'; }
}
