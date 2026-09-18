import { CoopTheme } from '../design/CoopTheme';
import { AppIcon } from '../components/AppIcon';

@Component
export struct HubStatsPanel {
  @Prop playStreak: number = 0;
  @Prop unlockedBadges: number = 0;
  @Prop badgeTotal: number = 0;
  @Prop isDarkMode: boolean = false;
  @Prop stacked: boolean = false;
  openStreak: () => void = () => {};
  openAchievements: () => void = () => {};

  build() {
    if (this.stacked) {
      Column({ space: 10 }) {
        this.StreakCard()
        this.BadgeCard()
      }.width('100%')
    } else {
      Row({ space: 10 }) {
        Column() { this.StreakCard() }.layoutWeight(1)
        Column() { this.BadgeCard() }.layoutWeight(1)
      }.width('100%')
    }
  }

  @Builder
  StreakCard() {
    this.StatCard('连续游玩', String(this.playStreak), '天', 'app/ui/streak.svg', this.openStreak)
  }

  @Builder
  BadgeCard() {
    this.StatCard('鸡窝徽章', String(this.unlockedBadges), '/ ' + String(this.badgeTotal),
      'app/achievements/achievement_wall_logo.svg', this.openAchievements)
  }

  @Builder
  StatCard(label: string, value: string, suffix: string, icon: string, action: () => void) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 4 }) {
        Column({ space: 4 }) {
          Text(label)
            .fontSize(12)
            .lineHeight(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.mutedColor())
            .maxLines(2)
          Row({ space: 3 }) {
            Text(value)
              .fontSize(24)
              .lineHeight(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.inkColor())
            Text(suffix)
              .fontSize(13)
              .lineHeight(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.brandDarkColor())
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Column({ space: 4 }) {
          Image($rawfile(icon))
            .width(28)
            .height(28)
            .objectFit(ImageFit.Contain)
            .accessibilityLevel('no')
          AppIcon({ name: 'chevron_right', iconSize: 12, tint: this.mutedColor() })
        }
      }
      .width('100%')
      .constraintSize({ minHeight: 54 })
    }
    .width('100%')
    .constraintSize({ minHeight: 80 })
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(this.panelColor())
    // Apply the same radius to the painted border and the button's clipping outline.
    .border({ width: 1, color: this.lineColor(), radius: 22 })
    .borderRadius(22)
    .clip(true)
    .shadow(this.cardShadow())
    .accessibilityText(`${label}，${value}${suffix}，点击${label === '连续游玩' ? '查看游玩日历' : '打开成就墙'}`)
    .onClick(action)
  }

  private inkColor(): string {
    return this.isDarkMode ? '#fff2df' : CoopTheme.ink;
  }

  private mutedColor(): string {
    return this.isDarkMode ? '#c8b7a2' : '#786555';
  }

  private brandDarkColor(): string {
    return this.isDarkMode ? '#ffc46f' : CoopTheme.brandDark;
  }

  private panelColor(): string {
    return this.isDarkMode ? '#211f1b' : '#fffaf2';
  }

  private lineColor(): string {
    return this.isDarkMode ? 'rgba(255,236,205,0.14)' : 'rgba(132,91,45,0.12)';
  }

  private cardShadow(): ShadowOptions {
    if (this.isDarkMode) {
      return {
        radius: 12,
        color: 'rgba(0,0,0,0.32)',
        offsetX: 0,
        offsetY: 4
      };
    }
    return {
      radius: 12,
      color: 'rgba(112,69,28,0.14)',
      offsetX: 0,
      offsetY: 4
    };
  }
}
