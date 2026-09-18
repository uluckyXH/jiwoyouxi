import { AchievementTheme } from '../design/AchievementTheme';
import { AchievementViewItem } from '../shell/AchievementModule';

/** Shared artwork and state treatment for the wall and its detail sheet. */
@Component
export struct AchievementBadge {
  @Prop item: AchievementViewItem;
  @Prop isDarkMode: boolean = false;
  @Prop badgeSize: number = AchievementTheme.badgeSize;
  @Prop accentColor: string = AchievementTheme.goldLight;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.item.definition.badgeAssetPath.length > 0) {
        Image($rawfile(this.item.definition.badgeAssetPath))
          .width(this.badgeSize * 0.9)
          .height(this.badgeSize * 0.9)
          .objectFit(ImageFit.Contain)
      } else {
        Image($rawfile('app/achievements/achievement_wall_logo.svg'))
          .width(this.badgeSize * 0.9)
          .height(this.badgeSize * 0.9)
          .objectFit(ImageFit.Contain)
      }
      if (this.item.status === 'unlocked') {
        Image($rawfile(`app/achievements/unlocked_mark_${this.isDarkMode ? 'dark' : 'light'}.svg`))
          .width(this.checkSize())
          .height(this.checkSize())
          .objectFit(ImageFit.Contain).accessibilityLevel('no')
          .position({ x: this.badgeSize - this.checkSize() - 3, y: this.badgeSize - this.checkSize() - 3 })
      }
    }
    .width(this.badgeSize)
    .height(this.badgeSize)
    .backgroundColor(this.surfaceColor())
    .border({ width: 1, color: this.item.status === 'unlocked' ? this.accentColor : this.lineColor() })
    .borderRadius(this.badgeSize * 0.31)
  }

  private checkSize(): number {
    return this.badgeSize > AchievementTheme.badgeSize ? 26 : 19;
  }

  private surfaceColor(): string {
    if (this.item.status === 'unlocked') {
      return this.isDarkMode ? AchievementTheme.goldSoftDark : AchievementTheme.goldSoftLight;
    }
    return this.isDarkMode ? AchievementTheme.unearnedSurfaceDark : AchievementTheme.unearnedSurfaceLight;
  }

  private lineColor(): string {
    return this.isDarkMode ? AchievementTheme.unearnedLineDark : AchievementTheme.unearnedLineLight;
  }
}
