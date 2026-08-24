import { CoopTheme } from '../design/CoopTheme';

@Component
export struct HubStatsPanel {
  @Prop playStreak: number = 0;
  @Prop unlockedBadges: number = 0;
  @Prop badgeTotal: number = 0;
  @Prop isDarkMode: boolean = false;

  build() {
    Row({ space: 10 }) {
      this.StatCard('连续游玩', String(this.playStreak), '天', '🔥')
      this.StatCard('鸡窝徽章', String(this.unlockedBadges), '/ ' + String(this.badgeTotal), '⭐')
    }
    .width('100%')
  }

  @Builder
  StatCard(label: string, value: string, suffix: string, icon: string) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 6 }) {
        Text(label)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.mutedColor())
        Row({ space: 3 }) {
          Text(value)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.inkColor())
          Text(suffix)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.brandDarkColor())
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      Text(icon)
        .fontSize(24)
        .opacity(0.72)
        .position({ x: 100, y: 10 })
    }
    .layoutWeight(1)
    .height(84)
    .padding(14)
    .borderRadius(22)
    .backgroundColor(this.panelColor())
    .border({ width: 1, color: this.lineColor() })
    .shadow(this.cardShadow())
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
        radius: 30,
        color: 'rgba(0,0,0,0.48)',
        offsetX: 0,
        offsetY: 16
      };
    }
    return {
      radius: 30,
      color: 'rgba(112,69,28,0.22)',
      offsetX: 0,
      offsetY: 16
    };
  }
}
