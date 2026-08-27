import { AchievementTheme } from '../design/AchievementTheme';
import { CoopMotion } from '../design/CoopMotion';
import { AchievementNoticeItem } from '../shell/AchievementModule';
import { emptyAchievementNoticeItem } from '../shell/AchievementNotice';

/**
 * A short-lived, app-level achievement ribbon. Its frame intentionally matches
 * GameEntryBadge so entering a game and earning an achievement feel related.
 */
@Component
export struct AchievementUnlockNotice {
  @Prop notice: AchievementNoticeItem = emptyAchievementNoticeItem();
  @Prop noticeVisible: boolean = false;
  @Prop isDarkMode: boolean = false;

  build() {
    Column() {
      Row({ space: 9 }) {
        this.AchievementIdentity()
        Text(this.displayTitle())
          .layoutWeight(1)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.titleColor())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(AchievementTheme.noticeWidth)
      .height(AchievementTheme.noticeHeight)
      .padding({ left: 8, right: 15 })
      .alignItems(VerticalAlign.Center)
      .borderRadius(AchievementTheme.noticeRadius)
      .backgroundColor(this.surfaceColor())
      .border({ width: 1, color: this.lineColor() })
      .shadow(this.shadowStyle())
      .opacity(this.noticeVisible ? 1 : 0)
      .translate({ x: 0, y: this.noticeVisible ? 0 : CoopMotion.achievementNoticeOffsetVp })
      .animation({ duration: CoopMotion.achievementNoticeEnterDuration, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: AchievementTheme.noticeBottomPadding })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.End)
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  AchievementIdentity() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.hasBadgeAsset()) {
        Image($rawfile(this.notice.badgeAssetPath))
          .width(AchievementTheme.noticeIconImageSize)
          .height(AchievementTheme.noticeIconImageSize)
          .objectFit(ImageFit.Contain)
      } else {
        Text(this.notice.placeholderSymbol)
          .fontSize(this.notice.kind === 'summary' ? 17 : 20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.symbolColor())
      }
    }
    .width(AchievementTheme.noticeIconSize)
    .height(AchievementTheme.noticeIconSize)
    .backgroundColor(this.iconSurfaceColor())
    .borderRadius(AchievementTheme.noticeIconSize / 2)
    .border({ width: 1, color: this.iconLineColor() })
  }

  private hasBadgeAsset(): boolean {
    return this.notice.badgeAssetPath.length > 0;
  }

  private displayTitle(): string {
    if (this.notice.kind === 'summary') {
      return this.notice.title;
    }
    return `新成就 · ${this.notice.title}`;
  }

  private surfaceColor(): string {
    return this.isDarkMode ? 'rgba(36,32,28,0.92)' : 'rgba(255,250,240,0.92)';
  }

  private lineColor(): string {
    return this.isDarkMode ? 'rgba(255,236,205,0.18)' : 'rgba(255,255,255,0.88)';
  }

  private iconSurfaceColor(): string {
    return this.isDarkMode ? '#332C25' : '#FFF3D9';
  }

  private iconLineColor(): string {
    if (this.isHighlight()) {
      return this.isDarkMode ? 'rgba(255,196,111,0.42)' : 'rgba(214,139,32,0.30)';
    }
    return this.isDarkMode ? 'rgba(255,236,205,0.20)' : 'rgba(111,73,39,0.16)';
  }

  private titleColor(): string {
    return this.isDarkMode ? '#FFF2DF' : '#4E3020';
  }

  private symbolColor(): string {
    return this.isDarkMode ? AchievementTheme.goldDark : AchievementTheme.goldLight;
  }

  private isHighlight(): boolean {
    return this.notice.noticeLevel === 'highlight';
  }

  private shadowStyle(): ShadowOptions {
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
}
