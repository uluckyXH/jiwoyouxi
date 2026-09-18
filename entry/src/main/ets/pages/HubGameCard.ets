import { CoopMotion } from '../design/CoopMotion';
import { hubCardStacked } from '../design/HubLayout';
import { GameModule } from '../shell/GameModule';
import { moduleById } from '../shell/GameRegistry';
import { HubGameLogoTile } from './HubGameLogoTile';

/** Keep the rounded card style while giving narrow cards a full-width text area. */
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
          Row().width(this.detail.length > 0 ? 34 : 42).height(4).borderRadius(2)
            .backgroundColor(this.game.accent).opacity(this.dark ? 0.72 : 0.58)
            .position({ x: 14, y: 10 })
          if (this.stacked()) {
            Column({ space: 8 }) {
              Row() {
                HubGameLogoTile({ gameId: this.game.id, tileSize: 54, imageSize: 50, isDarkMode: this.dark })
                Blank()
              }.width('100%')
              this.CardText()
            }.width('100%').padding({ left: 14, right: 14, top: 22, bottom: 14 })
          } else {
            Row({ space: 12 }) {
              HubGameLogoTile({ gameId: this.game.id, tileSize: 62, imageSize: 56, isDarkMode: this.dark })
              Column() { this.CardText() }.layoutWeight(1)
            }.width('100%').height('100%').alignItems(VerticalAlign.Center)
            .padding({ left: 14, right: 44, top: 24, bottom: 14 })
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
      }.width(44).height(44).margin({ right: 6, top: 6 })
    }
    .width('100%').height((this.stacked() ? 184 : 132) + 100 * (this.textScale - 1))
    .borderRadius(20)
    .backgroundColor(this.dark ? '#25221E' : '#FFFDF8')
    .border({ width: 1, color: this.dark ? 'rgba(255,231,196,0.18)' : 'rgba(126,78,35,0.16)' })
    .shadow({ radius: 30, color: this.dark ? 'rgba(0,0,0,0.48)' : 'rgba(112,69,28,0.22)', offsetY: 16 })
    .scale({ x: this.pressed ? CoopMotion.pressScale : 1, y: this.pressed ? CoopMotion.pressScale : 1 })
    .animation({ duration: CoopMotion.pressDuration, curve: Curve.EaseOut })
  }

  @Builder
  CardText() {
    Column({ space: 4 }) {
      Text(this.game.title).width('100%').fontSize(15).lineHeight(21)
        .fontWeight(FontWeight.Bold).fontColor(this.ink())
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.detail.length > 0 ? this.detail : this.subtitle).width('100%')
        .fontSize(11).lineHeight(16).fontWeight(FontWeight.Medium).fontColor(this.muted())
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  FavoriteButton() {
    Button({ type: ButtonType.Circle }) {
      Stack() {
        // Keep the SVG's explicit fill: tinting an outline SVG makes both states look filled.
        Image($rawfile(`app/home/favorite_${this.favorite ? 'on' : 'off'}_${this.dark ? 'dark' : 'light'}.svg`))
          .width(22).height(22).objectFit(ImageFit.Contain)
          .draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      }
      .width(32).height(32).borderRadius(16)
      .backgroundColor(this.favorite ? (this.dark ? '#62431E' : '#FFE3A4') : (this.dark ? '#312C25' : '#FFFDF8'))
      .border({ width: 1.5, radius: 16,
        color: this.favorite ? (this.dark ? '#B98A3F' : '#D9A33B') : (this.dark ? '#80705A' : '#CDBB9F') })
    }
    .width(44).height(44).padding(0).backgroundColor(Color.Transparent)
    .accessibilityText(`${this.favorite ? '取消收藏' : '收藏'}${this.game.title}，${this.subtitle}`)
    .onClick(() => this.toggleFavorite(this.game.id))
  }

  private ink(): string { return this.dark ? '#FFF2DF' : '#2F1D14'; }
  private stacked(): boolean { return this.detail.length > 0 || hubCardStacked(this.cardWidth, this.textScale); }
  private muted(): string { return this.dark ? '#C8B7A2' : '#786555'; }
}
