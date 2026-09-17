import { AchievementTheme } from '../design/AchievementTheme';
import { AchievementViewItem } from '../shell/AchievementModule';
import { AppIcon } from './AppIcon';

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
        Stack({ alignContent: Alignment.Center }) {
          AppIcon({ name: 'check', iconSize: this.checkSize() * 0.8, tint: '#4E3020' })
        }
          .width(this.checkSize())
          .height(this.checkSize())
          .backgroundColor(this.isDarkMode ? AchievementTheme.goldDark : AchievementTheme.goldLight)
          .borderRadius(this.checkSize() / 2)
          .position({ x: this.badgeSize - this.checkSize() + 2, y: this.badgeSize - this.checkSize() + 2 })
      }
    }
    .width(this.badgeSize)
    .height(this.badgeSize)
    .backgroundColor(this.surfaceColor())
    .border({ width: 1, color: this.item.status === 'unlocked' ? this.accentColor : this.lineColor() })
    .borderRadius(this.badgeSize * 0.31)
  }

  private checkSize(): number {
    return this.badgeSize > AchievementTheme.badgeSize ? 24 : 17;
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
