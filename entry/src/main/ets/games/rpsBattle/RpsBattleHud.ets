import { RpsBattleTheme } from './RpsBattleTheme';
import { RpsBattleFaction, RpsBattleFactionCounts, RpsBattleFactionInfo, RpsBattleThemeKey } from './RpsBattleTypes';
import { rpsBattleCountValue } from './RpsBattleRules';
import { rpsBattleThemeFactionInfo, rpsBattleThemeFactions } from './RpsBattleThemeConfig';

@Component
export struct RpsBattleHud {
  @Prop themeKey: RpsBattleThemeKey = 'rps';
  @Prop counts: RpsBattleFactionCounts = { rock: 0, scissors: 0, paper: 0 };
  @Prop timeLeftSec: number = 60;
  @Prop supportFaction: RpsBattleFaction = 'rock';
  @Prop conversions: number = 0;

  build() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        ForEach(rpsBattleThemeFactions(this.themeKey), (item: RpsBattleFactionInfo) => {
          this.FactionCount(item)
        }, (item: RpsBattleFactionInfo) => item.id)
      }
      .width('100%')
      Row({ space: 8 }) {
        this.TimePill()
        this.SupportPill()
        this.ConversionPill()
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  FactionCount(item: RpsBattleFactionInfo) {
    Column({ space: 1 }) {
      Row({ space: 5 }) {
        Text(item.symbol)
          .fontSize(16)
          .height(20)
          .textAlign(TextAlign.Center)
        Text(`${rpsBattleCountValue(this.counts, item.id)}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.textColor)
          .maxLines(1)
      }
      .justifyContent(FlexAlign.Center)
      Text(item.label)
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor(item.textColor)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(46)
    .borderRadius(9)
    .backgroundColor(item.softColor)
    .border({ width: 1, color: 'rgba(86,55,35,0.10)' })
  }

  @Builder
  TimePill() {
    Row({ space: 5 }) {
      Text('剩余')
        .fontSize(12)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
      Text(`${Math.max(0, this.timeLeftSec).toFixed(1)}s`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(32)
    .borderRadius(8)
    .backgroundColor(RpsBattleTheme.panelBg)
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  @Builder
  SupportPill() {
    Row({ space: 5 }) {
      Text('支持')
        .fontSize(12)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
      Text(rpsBattleThemeFactionInfo(this.themeKey, this.supportFaction).label)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(32)
    .borderRadius(8)
    .backgroundColor(RpsBattleTheme.panelBg)
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  @Builder
  ConversionPill() {
    Row({ space: 5 }) {
      Text('转阵')
        .fontSize(12)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
      Text(`${this.conversions}`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(32)
    .borderRadius(8)
    .backgroundColor(RpsBattleTheme.panelBg)
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }
}
