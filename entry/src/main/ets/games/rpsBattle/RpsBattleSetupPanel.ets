import { RpsBattleTheme } from './RpsBattleTheme';
import {
  RPS_BATTLE_FACTIONS,
  RPS_BATTLE_SCALE_CHOICES,
  RpsBattleFaction,
  RpsBattleFactionInfo,
  RpsBattleScale,
  RpsBattleScaleChoice
} from './RpsBattleTypes';

@Component
export struct RpsBattleSetupPanel {
  @Prop selectedFaction: RpsBattleFaction = 'rock';
  @Prop selectedScale: RpsBattleScale = 'standard';
  selectFaction: (faction: RpsBattleFaction) => void = () => {};
  selectScale: (scale: RpsBattleScale) => void = () => {};
  startGame: () => void = () => {};

  build() {
    Column({ space: 16 }) {
      Column({ space: 6 }) {
        Text('经典乱斗')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Text('石头克剪刀 · 剪刀克布 · 布克石头')
          .fontSize(13)
          .fontColor(RpsBattleTheme.muted)
          .textAlign(TextAlign.Center)
          .maxLines(1)
      }
      .width('100%')

      this.SectionTitle('支持阵营')
      Row({ space: 8 }) {
        ForEach(RPS_BATTLE_FACTIONS, (item: RpsBattleFactionInfo) => {
          this.FactionOption(item)
        }, (item: RpsBattleFactionInfo) => item.id)
      }
      .width('100%')

      this.SectionTitle('对局规模')
      Row({ space: 8 }) {
        ForEach(RPS_BATTLE_SCALE_CHOICES, (item: RpsBattleScaleChoice) => {
          this.ScaleOption(item)
        }, (item: RpsBattleScaleChoice) => item.id)
      }
      .width('100%')

      Button('开始乱斗')
        .width('100%')
        .height(48)
        .borderRadius(10)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.primaryButtonText)
        .backgroundColor(RpsBattleTheme.primaryButtonBg)
        .onClick(() => {
          this.startGame();
        })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 18, bottom: 18 })
    .borderRadius(12)
    .backgroundColor(RpsBattleTheme.panelBg)
    .border({ width: 1, color: RpsBattleTheme.panelLine })
    .shadow({
      radius: 16,
      color: 'rgba(86,55,35,0.12)',
      offsetX: 0,
      offsetY: 6
    })
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .width('100%')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(RpsBattleTheme.pageInk)
      .maxLines(1)
  }

  @Builder
  FactionOption(item: RpsBattleFactionInfo) {
    Column({ space: 5 }) {
      Text(item.symbol)
        .fontSize(24)
        .height(30)
        .textAlign(TextAlign.Center)
      Text(item.label)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.textColor)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(76)
    .borderRadius(10)
    .backgroundColor(this.selectedFaction === item.id ? RpsBattleTheme.selectedBg : item.softColor)
    .border({
      width: this.selectedFaction === item.id ? 2 : 1,
      color: this.selectedFaction === item.id ? RpsBattleTheme.selectedLine : 'rgba(86,55,35,0.10)'
    })
    .onClick(() => {
      this.selectFaction(item.id);
    })
  }

  @Builder
  ScaleOption(item: RpsBattleScaleChoice) {
    Column({ space: 4 }) {
      Text(item.label)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .maxLines(1)
      Text(`${item.count} / ${item.count} / ${item.count}`)
        .fontSize(11)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(58)
    .borderRadius(9)
    .backgroundColor(this.selectedScale === item.id ? RpsBattleTheme.selectedBg : '#fff8e8')
    .border({
      width: this.selectedScale === item.id ? 2 : 1,
      color: this.selectedScale === item.id ? RpsBattleTheme.selectedLine : RpsBattleTheme.panelLine
    })
    .onClick(() => {
      this.selectScale(item.id);
    })
  }
}
