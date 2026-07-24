import { CoopMotion } from '../design/CoopMotion';
import { CoopTheme } from '../design/CoopTheme';
import { GameModule } from './GameModule';
import { moduleById } from './GameRegistry';

@Component
export struct GameEntryBadge {
  @Prop gameId: string = 'rps';
  @Prop badgeVisible: boolean = false;
  @Prop isDarkMode: boolean = false;

  build() {
    Column() {
      Row({ space: 9 }) {
        Stack({ alignContent: Alignment.Center }) {
          Image($rawfile(this.logoPath()))
            .width(30)
            .height(30)
            .objectFit(ImageFit.Contain)
            .shadow(this.logoShadow())
        }
        .width(34)
        .height(34)
        .backgroundColor(this.logoTileBgColor())
        .borderRadius(17)
        .border({ width: 1, color: this.logoTileLineColor() })
        Text(this.title())
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.titleColor())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .height(46)
      .padding({ left: 8, right: 15 })
      .borderRadius(23)
      .backgroundColor(this.badgeBgColor())
      .border({ width: 1, color: this.badgeLineColor() })
      .shadow(this.badgeShadow())
      .opacity(this.badgeVisible ? 1 : 0)
      .translate({ x: 0, y: this.badgeVisible ? 0 : -CoopMotion.entryBadgeOffsetVp })
      .animation({ duration: CoopMotion.entryBadgeDuration, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
    .padding({ top: 24 })
    .alignItems(HorizontalAlign.Center)
    .hitTestBehavior(HitTestMode.None)
  }

  private module(): GameModule {
    return moduleById(this.gameId);
  }

  private title(): string {
    return this.module().title;
  }

  private logoPath(): string {
    if (this.gameId === 'suika') return 'app/game_logos/game_icon_suika.png';
    if (this.gameId === 'minesweeper') return 'app/game_logos/game_icon_minesweeper.png';
    if (this.gameId === 'tetris') return 'app/game_logos/game_icon_tetris.png';
    if (this.gameId === 'chicken2048') return 'app/game_logos/game_icon_chicken2048.png';
    if (this.gameId === 'freecell') return 'app/game_logos/game_icon_freecell.png';
    return 'app/game_logos/game_icon_rps.png';
  }

  private titleColor(): string {
    return this.isDarkMode ? '#fff2df' : CoopTheme.ink;
  }

  private badgeBgColor(): string {
    return this.isDarkMode ? 'rgba(36,32,28,0.92)' : 'rgba(255,250,240,0.92)';
  }

  private badgeLineColor(): string {
    return this.isDarkMode ? 'rgba(255,236,205,0.18)' : 'rgba(255,255,255,0.88)';
  }

  private logoTileBgColor(): string {
    return this.isDarkMode ? '#332c25' : '#fff3d9';
  }

  private logoTileLineColor(): string {
    return this.isDarkMode ? 'rgba(255,236,205,0.20)' : 'rgba(111,73,39,0.14)';
  }

  private badgeShadow(): ShadowOptions {
    if (this.isDarkMode) {
      return {
        radius: 20,
        color: 'rgba(0,0,0,0.44)',
        offsetX: 0,
        offsetY: 10
      };
    }
    return {
      radius: 20,
      color: 'rgba(62,40,18,0.18)',
      offsetX: 0,
      offsetY: 9
    };
  }

  private logoShadow(): ShadowOptions {
    if (this.isDarkMode) {
      return {
        radius: 10,
        color: 'rgba(0,0,0,0.32)',
        offsetX: 0,
        offsetY: 4
      };
    }
    return {
      radius: 10,
      color: 'rgba(96,57,24,0.14)',
      offsetX: 0,
      offsetY: 4
    };
  }
}
