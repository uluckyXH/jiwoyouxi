import { RpsBattleTheme } from './RpsBattleTheme';
import {
  RpsBattleControlZone,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleFactionInfo,
  RpsBattleSnapState,
  RpsBattleThemeKey
} from './RpsBattleTypes';
import { rpsBattleCountValue } from './RpsBattleRules';
import { rpsBattleThemeFactionInfo, rpsBattleThemeFactions } from './RpsBattleThemeConfig';

@Component
export struct RpsBattleHud {
  @Prop themeKey: RpsBattleThemeKey = 'rps';
  @Prop counts: RpsBattleFactionCounts = { rock: 0, scissors: 0, paper: 0 };
  @Prop timeLeftSec: number = 60;
  @Prop supportFaction: RpsBattleFaction = 'rock';
  @Prop conversions: number = 0;
  @Prop controlZone: RpsBattleControlZone | null = null;
  @Prop isDeathmatch: boolean = false;
  @Prop elapsedSec: number = 0;
  @Prop snap: RpsBattleSnapState | null = null;

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
        if (this.controlZone !== null) {
          this.ZonePill()
        } else {
          this.SupportPill()
        }
        this.ConversionPill()
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  ZonePill() {
    Row({ space: 4 }) {
      Text('占点')
        .fontSize(11)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
      ForEach(rpsBattleThemeFactions(this.themeKey), (item: RpsBattleFactionInfo) => {
        Text(`${item.symbol}${this.zoneScoreText(item.id)}`)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.zoneScoreColor(item.id))
          .maxLines(1)
      }, (item: RpsBattleFactionInfo) => item.id)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(2)
    .height(32)
    .borderRadius(8)
    .backgroundColor(RpsBattleTheme.panelBg)
    .border({ width: 1, color: RpsBattleTheme.panelLine })
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
    .border({ width: 1, color: RpsBattleTheme.softLine })
  }

  @Builder
  TimePill() {
    Row({ space: 5 }) {
      Text(this.isDeathmatch ? '赛制' : '剩余')
        .fontSize(12)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
      Text(this.statusText())
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

  private zoneScoreText(faction: RpsBattleFaction): string {
    if (this.controlZone === null) {
      return '0';
    }
    if (faction === 'rock') {
      return `${Math.floor(this.controlZone.scores.rock)}`;
    }
    if (faction === 'scissors') {
      return `${Math.floor(this.controlZone.scores.scissors)}`;
    }
    return `${Math.floor(this.controlZone.scores.paper)}`;
  }

  private statusText(): string {
    if (!this.isDeathmatch) {
      return Math.max(0, this.timeLeftSec).toFixed(1) + 's';
    }
    if (this.snap !== null && this.snap.phase === 'warning') {
      return '清算 ' + Math.max(0, this.snap.resolveAtSec - this.elapsedSec).toFixed(1) + 's';
    }
    if (this.snap !== null && this.snap.phase === 'resolved') {
      return '清算完成';
    }
    return '死斗清场';
  }

  private zoneScoreColor(faction: RpsBattleFaction): string {
    if (this.controlZone !== null && this.controlZone.capturingFaction === faction) {
      return rpsBattleThemeFactionInfo(this.themeKey, faction).color;
    }
    return rpsBattleThemeFactionInfo(this.themeKey, faction).textColor;
  }
}
