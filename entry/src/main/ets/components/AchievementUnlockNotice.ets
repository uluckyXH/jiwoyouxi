import { AchievementTheme } from '../design/AchievementTheme';
import { CoopMotion } from '../design/CoopMotion';
import { AchievementNoticeItem } from '../shell/AchievementModule';
import { emptyAchievementNoticeItem } from '../shell/AchievementNotice';
import { gameLogoPath } from '../shell/GameRegistry';

@Component
export struct AchievementUnlockNotice {
  @Prop notice: AchievementNoticeItem = emptyAchievementNoticeItem();
  @Prop noticeVisible: boolean = false;
  @Prop isDarkMode: boolean = false;

  build() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Row({ space: 9 }) {
          this.GameIdentity()
          this.MedalIdentity()
          Column({ space: 1 }) {
            Text(this.noticeLabel())
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.labelColor())
              .maxLines(1)
            Text(this.notice.title)
              .width('100%')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.titleColor())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.notice.summary)
              .width('100%')
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.summaryColor())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 11, right: 13, top: 10, bottom: 10 })
        .alignItems(VerticalAlign.Center)

        if (this.isHighlight()) {
          this.HighlightSparkles()
        }
      }
      .width(AchievementTheme.noticeWidth)
      .height(AchievementTheme.noticeHeight)
      .borderRadius(AchievementTheme.noticeRadius)
      .backgroundColor(this.surfaceColor())
      .border({ width: 1, color: this.lineColor() })
      .shadow(this.shadowStyle())
      .opacity(this.noticeVisible ? 1 : 0)
      .scale({
        x: this.noticeVisible ? 1 : CoopMotion.achievementNoticeScaleFrom,
        y: this.noticeVisible ? 1 : CoopMotion.achievementNoticeScaleFrom
      })
      .translate({ x: 0, y: this.noticeVisible ? 0 : -CoopMotion.achievementNoticeOffsetVp })
      .animation({ duration: CoopMotion.achievementNoticeEnterDuration, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
    .padding({ top: AchievementTheme.noticeTopPadding })
    .alignItems(HorizontalAlign.Center)
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  GameIdentity() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.notice.gameId === 'global') {
        Text('✦')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.goldColor())
      } else {
        Image($rawfile(gameLogoPath(this.notice.gameId)))
          .width(28)
          .height(28)
          .objectFit(ImageFit.Contain)
      }
    }
    .width(AchievementTheme.noticeLogoSize)
    .height(AchievementTheme.noticeLogoSize)
    .backgroundColor(this.logoSurfaceColor())
    .borderRadius(AchievementTheme.noticeLogoSize / 2)
    .border({ width: 1, color: this.logoLineColor() })
  }

  @Builder
  MedalIdentity() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.notice.placeholderSymbol)
        .fontSize(this.notice.kind === 'summary' ? 19 : 22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.medalSymbolColor())
      if (this.notice.kind === 'summary') {
        Text(`${this.notice.achievementCount}`)
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.summaryCountColor())
          .position({ x: 25, y: 23 })
      }
    }
    .width(AchievementTheme.noticeMedalSize)
    .height(AchievementTheme.noticeMedalSize)
    .backgroundColor(this.medalSurfaceColor())
    .borderRadius(14)
    .border({ width: 1, color: this.medalLineColor() })
  }

  @Builder
  HighlightSparkles() {
    Text('✦')
      .fontSize(11)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.goldColor())
      .opacity(this.noticeVisible ? 0.88 : 0)
      .position({ x: 251, y: 8 })
      .translate({ x: 0, y: this.noticeVisible ? 0 : -4 })
      .animation({ duration: CoopMotion.achievementNoticeEnterDuration, curve: Curve.EaseOut })
    Text('·')
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.goldColor())
      .opacity(this.noticeVisible ? 0.74 : 0)
      .position({ x: 242, y: 47 })
      .translate({ x: 0, y: this.noticeVisible ? 0 : 3 })
      .animation({ duration: CoopMotion.achievementNoticeEnterDuration, curve: Curve.EaseOut })
  }

  private isHighlight(): boolean {
    return this.notice.noticeLevel === 'highlight';
  }

  private noticeLabel(): string {
    return this.notice.kind === 'summary' ? '本局收获' : '新成就';
  }

  private surfaceColor(): string {
    return this.isDarkMode ? 'rgba(35,31,27,0.96)' : 'rgba(255,249,238,0.96)';
  }

  private lineColor(): string {
    if (this.isHighlight()) {
      return this.isDarkMode ? 'rgba(255,196,111,0.40)' : 'rgba(244,166,42,0.42)';
    }
    return this.isDarkMode ? 'rgba(255,236,205,0.20)' : 'rgba(126,84,43,0.16)';
  }

  private logoSurfaceColor(): string {
    return this.isDarkMode ? '#322B24' : '#FFF0D4';
  }

  private logoLineColor(): string {
    return this.isDarkMode ? 'rgba(255,236,205,0.18)' : 'rgba(111,73,39,0.14)';
  }

  private medalSurfaceColor(): string {
    return this.isDarkMode ? '#4A3920' : AchievementTheme.goldSoftLight;
  }

  private medalLineColor(): string {
    return this.isDarkMode ? 'rgba(255,210,132,0.34)' : 'rgba(214,139,32,0.34)';
  }

  private medalSymbolColor(): string {
    return this.isDarkMode ? '#FFE0A3' : '#A76008';
  }

  private titleColor(): string {
    return this.isDarkMode ? '#FFF2DF' : '#4E3020';
  }

  private labelColor(): string {
    return this.isDarkMode ? '#FFD083' : '#B66B14';
  }

  private summaryColor(): string {
    return this.isDarkMode ? '#C8B7A2' : '#876E58';
  }

  private summaryCountColor(): string {
    return this.isDarkMode ? '#2A1C0C' : '#FFFFFF';
  }

  private goldColor(): string {
    return this.isDarkMode ? AchievementTheme.goldDark : AchievementTheme.goldLight;
  }

  private shadowStyle(): ShadowOptions {
    if (this.isDarkMode) {
      return {
        radius: 20,
        color: 'rgba(0,0,0,0.42)',
        offsetX: 0,
        offsetY: 10
      };
    }
    return {
      radius: 20,
      color: 'rgba(77,44,18,0.20)',
      offsetX: 0,
      offsetY: 9
    };
  }
}
