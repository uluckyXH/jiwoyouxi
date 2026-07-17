import { RpsBattleModeSetupCard } from './RpsBattleModeSetupCard';
import { RpsBattleSetupCardHeader } from './RpsBattleSetupCardHeader';
import { RpsBattleTheme } from './RpsBattleTheme';
import {
  RPS_BATTLE_DURATION_CHOICES,
  RPS_BATTLE_MAX_COUNT_PER_FACTION,
  RPS_BATTLE_MAX_TOTAL_ENTITIES,
  RPS_BATTLE_MIN_COUNT_PER_FACTION,
  RPS_BATTLE_SCALE_CHOICES,
  RpsBattleDurationChoice,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleFactionInfo,
  RpsBattleMechanicKey,
  RpsBattleMechanicSelection,
  RpsBattleModeKey,
  RpsBattleScale,
  RpsBattleScaleChoice,
  RpsBattleThemeKey,
  RpsBattleThemePreset
} from './RpsBattleTypes';
import {
  RPS_BATTLE_THEMES,
  rpsBattleThemeFactionInfo,
  rpsBattleThemeFactions
} from './RpsBattleThemeConfig';
import { rpsBattleModeByKey } from './RpsBattleModeConfig';
import {
  rpsBattleCanDecreaseCount,
  rpsBattleCanIncreaseCount,
  rpsBattleCountValue,
  rpsBattlePreyOf,
  rpsBattleTotalCount
} from './RpsBattleRules';

@Component
export struct RpsBattleSetupPanel {
  @Prop selectedThemeKey: RpsBattleThemeKey = 'rps';
  @Prop selectedModeKey: RpsBattleModeKey = 'classic';
  @Prop mechanicSelection: RpsBattleMechanicSelection = {};
  @Prop selectedFaction: RpsBattleFaction = 'rock';
  @Prop selectedScale: RpsBattleScale = 'standard';
  @Prop lineupCounts: RpsBattleFactionCounts = { rock: 8, scissors: 8, paper: 8 };
  @Prop syncCounts: boolean = true;
  @Prop advancedLineupOpen: boolean = false;
  @Prop durationSec: number = 60;
  selectTheme: (themeKey: RpsBattleThemeKey) => void = () => {};
  selectMode: (modeKey: RpsBattleModeKey) => void = () => {};
  toggleMechanic: (mechanicKey: RpsBattleMechanicKey) => void = () => {};
  selectFaction: (faction: RpsBattleFaction) => void = () => {};
  selectScale: (scale: RpsBattleScale) => void = () => {};
  selectDuration: (durationSec: number) => void = () => {};
  toggleSyncCounts: () => void = () => {};
  toggleAdvancedLineup: () => void = () => {};
  stepFactionCount: (faction: RpsBattleFaction, step: number) => void = () => {};

  build() {
    Column({ space: 12 }) {
      RpsBattleModeSetupCard({
        selectedModeKey: this.selectedModeKey,
        mechanicSelection: this.mechanicSelection,
        selectMode: (modeKey: RpsBattleModeKey) => {
          this.selectMode(modeKey);
        },
        toggleMechanic: (mechanicKey: RpsBattleMechanicKey) => {
          this.toggleMechanic(mechanicKey);
        }
      })
      this.ThemeConfigCard()
      this.SupportFactionConfigCard()
      this.LineupConfigCard()
      this.DurationConfigCard()
    }
    .width('100%')
  }

  @Builder
  ThemeConfigCard() {
    Column({ space: 12 }) {
      RpsBattleSetupCardHeader({ order: this.sectionOrder(3), title: '阵营主题', subtitle: '决定名称、图标和颜色' })
      this.ThemeGrid()
    }
    .width('100%')
    .padding(14)
    .borderRadius(8)
    .backgroundColor(RpsBattleTheme.panelBg)
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  @Builder
  SupportFactionConfigCard() {
    Column({ space: 12 }) {
      RpsBattleSetupCardHeader({ order: this.sectionOrder(4), title: '支持阵营', subtitle: '选中一方，见证它赢下乱斗' })
      Row({ space: 8 }) {
        ForEach(rpsBattleThemeFactions(this.selectedThemeKey), (item: RpsBattleFactionInfo) => {
          this.FactionOption(item)
        }, (item: RpsBattleFactionInfo) => `${this.selectedThemeKey}-${item.id}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .borderRadius(8)
    .backgroundColor(RpsBattleTheme.panelBg)
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  @Builder
  LineupConfigCard() {
    Column({ space: 12 }) {
      RpsBattleSetupCardHeader({ order: this.sectionOrder(5), title: '战斗规模', subtitle: this.lineupSummaryText() })
      Row({ space: 8 }) {
        ForEach(RPS_BATTLE_SCALE_CHOICES, (item: RpsBattleScaleChoice) => {
          this.ScaleOption(item)
        }, (item: RpsBattleScaleChoice) => item.id)
      }
      .width('100%')
      this.AdvancedLineupToggle()
      if (this.advancedLineupOpen) {
        this.AdvancedLineupPanel()
      }
    }
    .width('100%')
    .padding(14)
    .borderRadius(8)
    .backgroundColor(RpsBattleTheme.panelBg)
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  @Builder
  DurationConfigCard() {
    Column({ space: 12 }) {
      RpsBattleSetupCardHeader({ order: this.sectionOrder(6), title: '对局时长', subtitle: '倒计时结束后开始计时' })
      Row({ space: 8 }) {
        ForEach(RPS_BATTLE_DURATION_CHOICES, (item: RpsBattleDurationChoice) => {
          this.DurationOption(item)
        }, (item: RpsBattleDurationChoice) => `${item.durationSec}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .borderRadius(8)
    .backgroundColor(RpsBattleTheme.panelBg)
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  @Builder
  SectionRule() {
    Blank()
      .width('100%')
      .height(1)
      .backgroundColor(RpsBattleTheme.panelLine)
  }

  @Builder
  ThemeGrid() {
    Grid() {
      ForEach(RPS_BATTLE_THEMES, (item: RpsBattleThemePreset) => {
        GridItem() {
          this.ThemeOption(item)
        }
      }, (item: RpsBattleThemePreset) => item.key)
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(8)
    .columnsGap(8)
    .height(116)
  }

  @Builder
  ThemeOption(item: RpsBattleThemePreset) {
    Column({ space: 2 }) {
      Text(item.mark)
        .fontSize(16)
        .height(22)
        .textAlign(TextAlign.Center)
        .maxLines(1)
      Text(item.name)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.selectedThemeKey === item.key ? '#ffffff' : RpsBattleTheme.pageInk)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(54)
    .borderRadius(8)
    .backgroundColor(this.selectedThemeKey === item.key ? item.factions[1].color : '#fff8e8')
    .border({
      width: this.selectedThemeKey === item.key ? 2 : 1,
      color: this.selectedThemeKey === item.key ? item.factions[1].color : RpsBattleTheme.panelLine
    })
    .onClick(() => {
      this.selectTheme(item.key);
    })
  }

  @Builder
  FactionOption(item: RpsBattleFactionInfo) {
    Column({ space: 4 }) {
      Text(item.symbol)
        .fontSize(23)
        .height(28)
        .textAlign(TextAlign.Center)
      Text(item.label)
        .fontSize(this.factionLabelFontSize(item.label))
        .fontWeight(FontWeight.Bold)
        .fontColor(item.textColor)
        .maxLines(1)
      Text(this.factionRuleText(item.id))
        .fontSize(10)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(84)
    .borderRadius(8)
    .backgroundColor(item.softColor)
    .border({
      width: this.selectedFaction === item.id ? 2 : 1,
      color: this.selectedFaction === item.id ? item.color : 'rgba(86,55,35,0.10)'
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
    .borderRadius(8)
    .backgroundColor(this.selectedScale === item.id ? RpsBattleTheme.selectedBg : '#fff8e8')
    .border({
      width: this.selectedScale === item.id ? 2 : 1,
      color: this.selectedScale === item.id ? RpsBattleTheme.selectedLine : RpsBattleTheme.panelLine
    })
    .onClick(() => {
      this.selectScale(item.id);
    })
  }

  @Builder
  AdvancedLineupToggle() {
    Row({ space: 10 }) {
      Column({ space: 2 }) {
        Text('高级人数')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .maxLines(1)
        Text(`${this.syncCounts ? '一起调' : '单独调'} · 总数 ${rpsBattleTotalCount(this.lineupCounts)} / ${RPS_BATTLE_MAX_TOTAL_ENTITIES}`)
          .fontSize(10)
          .fontColor(RpsBattleTheme.muted)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(this.advancedLineupOpen ? '收起' : '调整')
        .width(52)
        .height(32)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .textAlign(TextAlign.Center)
        .backgroundColor('#fff8e8')
        .borderRadius(8)
        .border({ width: 1, color: RpsBattleTheme.panelLine })
    }
    .width('100%')
    .height(52)
    .padding({ left: 10, right: 8 })
    .borderRadius(8)
    .backgroundColor('#fffaf0')
    .border({ width: 1, color: RpsBattleTheme.panelLine })
    .onClick(() => {
      this.toggleAdvancedLineup();
    })
  }

  @Builder
  AdvancedLineupPanel() {
    Column({ space: 8 }) {
      this.SectionRule()
      this.SyncModeRow()
      Column({ space: 6 }) {
        ForEach(rpsBattleThemeFactions(this.selectedThemeKey), (item: RpsBattleFactionInfo) => {
          this.CountControl(item)
        }, (item: RpsBattleFactionInfo) => `count-${this.selectedThemeKey}-${item.id}`)
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  SyncModeRow() {
    Row({ space: 10 }) {
      Column({ space: 1 }) {
        Text('人数模式')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .maxLines(1)
        Text(`每方 ${RPS_BATTLE_MIN_COUNT_PER_FACTION}-${RPS_BATTLE_MAX_COUNT_PER_FACTION}`)
          .fontSize(10)
          .fontColor(RpsBattleTheme.muted)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Row({ space: 4 }) {
        this.SyncModeOption('一起调', true)
        this.SyncModeOption('单独调', false)
      }
      .width(146)
    }
    .width('100%')
    .height(48)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  SyncModeOption(label: string, syncMode: boolean) {
    Row() {
      Text(label)
        .width('100%')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.syncCounts === syncMode ? RpsBattleTheme.primaryButtonText : RpsBattleTheme.pageInk)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .layoutWeight(1)
    .height(40)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius(8)
    .backgroundColor(this.syncCounts === syncMode ? RpsBattleTheme.primaryButtonBg : '#fff8e8')
    .border({
      width: 1,
      color: this.syncCounts === syncMode ? RpsBattleTheme.primaryButtonBg : RpsBattleTheme.panelLine
    })
    .onClick(() => {
      if (this.syncCounts !== syncMode) {
        this.toggleSyncCounts();
      }
    })
  }

  @Builder
  CountControl(item: RpsBattleFactionInfo) {
    Row({ space: 8 }) {
      Text(item.symbol)
        .width(30)
        .fontSize(20)
        .textAlign(TextAlign.Center)
      Column({ space: 1 }) {
        Text(item.label)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.textColor)
          .maxLines(1)
        Text(this.factionRuleText(item.id))
          .fontSize(10)
          .fontColor(RpsBattleTheme.muted)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      this.CountStepButton('-', this.canDecrease(item.id), () => {
        this.stepFactionCount(item.id, -1);
      })
      Text(`${rpsBattleCountValue(this.lineupCounts, item.id)}`)
        .width(28)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .textAlign(TextAlign.Center)
        .maxLines(1)
      this.CountStepButton('+', this.canIncrease(item.id), () => {
        this.stepFactionCount(item.id, 1);
      })
    }
    .width('100%')
    .height(52)
    .padding({ left: 8, right: 8 })
    .borderRadius(8)
    .backgroundColor(item.softColor)
    .border({ width: 1, color: 'rgba(86,55,35,0.10)' })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CountStepButton(label: string, enabled: boolean, action: () => void) {
    Row() {
      Text(label)
        .width('100%')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .width(40)
    .height(40)
    .borderRadius(8)
    .backgroundColor('#fff8e8')
    .opacity(enabled ? 1 : 0.36)
    .border({ width: 1, color: RpsBattleTheme.panelLine })
    .onClick(() => {
      if (enabled) {
        action();
      }
    })
  }

  @Builder
  DurationOption(item: RpsBattleDurationChoice) {
    Column({ space: 3 }) {
      Text(item.label)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .maxLines(1)
      Text(`${item.durationSec}s`)
        .fontSize(10)
        .fontColor(this.durationSec === item.durationSec ? RpsBattleTheme.pageInk : RpsBattleTheme.muted)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(52)
    .borderRadius(8)
    .backgroundColor(this.durationSec === item.durationSec ? RpsBattleTheme.selectedBg : '#fff8e8')
    .border({
      width: this.durationSec === item.durationSec ? 2 : 1,
      color: this.durationSec === item.durationSec ? RpsBattleTheme.selectedLine : RpsBattleTheme.panelLine
    })
    .onClick(() => {
      this.selectDuration(item.durationSec);
    })
  }

  private factionRuleText(faction: RpsBattleFaction): string {
    const prey = rpsBattleThemeFactionInfo(this.selectedThemeKey, rpsBattlePreyOf(faction));
    return `克 ${prey.label}`;
  }

  private factionLabelFontSize(label: string): number {
    return label.length > 3 ? 11 : 13;
  }

  private lineupSummaryText(): string {
    const total = rpsBattleTotalCount(this.lineupCounts);
    if (this.selectedScale === 'custom') {
      return `自定义 · 总数 ${total} / ${RPS_BATTLE_MAX_TOTAL_ENTITIES}`;
    }
    return `总数 ${total} / ${RPS_BATTLE_MAX_TOTAL_ENTITIES}`;
  }

  private sectionOrder(defaultOrder: number): string {
    const order = this.hasMechanicsCard() ? defaultOrder : defaultOrder - 1;
    return order < 10 ? `0${order}` : `${order}`;
  }

  private hasMechanicsCard(): boolean {
    const options = rpsBattleModeByKey(this.selectedModeKey).mechanicOptions;
    for (let i = 0; i < options.length; i += 1) {
      if (options[i].state !== 'core') {
        return true;
      }
    }
    return false;
  }

  private canIncrease(faction: RpsBattleFaction): boolean {
    return rpsBattleCanIncreaseCount(this.lineupCounts, faction, this.syncCounts);
  }

  private canDecrease(faction: RpsBattleFaction): boolean {
    return rpsBattleCanDecreaseCount(this.lineupCounts, faction, this.syncCounts);
  }
}
