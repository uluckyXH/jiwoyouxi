import { AppIcon } from '../components/AppIcon';
import { gameLogoPath } from '../shell/GameRegistry';

/** Shared by the home grid and the favorites shelf. */
@Component
export struct HubGameLogoTile {
  @Prop gameId: string = 'rpsBattle';
  @Prop tileSize: number = 62;
  @Prop imageSize: number = 56;
  @Prop showFavorite: boolean = false;
  @Prop isFavorite: boolean = false;
  @Prop isDarkMode: boolean = false;
  toggleFavorite: (gameId: string) => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Image($rawfile(gameLogoPath(this.gameId)))
        .width(this.imageSize)
        .height(this.imageSize)
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .accessibilityLevel('no')
      if (this.showFavorite) {
        Stack({ alignContent: Alignment.Center }) {
          AppIcon({
            name: this.isFavorite ? 'star_filled' : 'star',
            iconSize: 17,
            tint: this.isFavorite ? this.activeColor() : this.mutedColor()
          })
        }
        .width(24)
        .height(24)
        .backgroundColor(this.isDarkMode ? '#1B1916' : '#FFFAF2')
        .borderRadius(12)
        .border({ width: 1, color: this.lineColor() })
        .position({ x: this.tileSize - 18, y: -7 })
        .responseRegion({ x: -8, y: -8, width: 40, height: 40 })
        .accessibilityText(this.isFavorite ? '取消收藏' : '收藏游戏')
        .onClick(() => {
          this.toggleFavorite(this.gameId);
        })
      }
    }
    .width(this.tileSize)
    .height(this.tileSize)
    .borderRadius(18)
    .backgroundColor(this.isDarkMode ? '#332C25' : '#FFF3D9')
    .border({ width: 1, color: this.lineColor() })
  }

  private activeColor(): string {
    return this.isDarkMode ? '#FFD083' : '#B47628';
  }

  private mutedColor(): string {
    return this.isDarkMode ? '#C8B7A2' : '#8B7560';
  }

  private lineColor(): string {
    return this.isDarkMode ? 'rgba(255,236,205,0.20)' : 'rgba(111,73,39,0.16)';
  }
}
