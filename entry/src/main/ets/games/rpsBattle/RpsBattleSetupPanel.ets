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
  RpsBattleMechanicOption,
  RpsBattleMechanicState,
  RpsBattleModeKey,
  RpsBattleModePreset,
  RpsBattleScale,
  RpsBattleScaleChoice,
  RpsBattleThemeKey,
  RpsBattleThemePreset
} from './RpsBattleTypes';
import { RPS_BATTLE_MODES, rpsBattleModeByKey } from './RpsBattleModeConfig';
import {
  RPS_BATTLE_THEMES,
  rpsBattleThemeByKey,
  rpsBattleThemeFactionInfo,
  rpsBattleThemeFactions
} from './RpsBattleThemeConfig';
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
  @Prop selectedFaction: RpsBattleFaction = 'rock';
  @Prop selectedScale: RpsBattleScale = 'standard';
  @Prop lineupCounts: RpsBattleFactionCounts = { rock: 8, scissors: 8, paper: 8 };
  @Prop syncCounts: boolean = true;
  @Prop advancedLineupOpen: boolean = false;
  @Prop durationSec: number = 60;
  selectTheme: (themeKey: RpsBattleThemeKey) => void = () => {};
  selectMode: (modeKey: RpsBattleModeKey) => void = () => {};
  selectFaction: (faction: RpsBattleFaction) => void = () => {};
  selectScale: (scale: RpsBattleScale) => void = () => {};
  selectDuration: (durationSec: number) => void = () => {};
  toggleSyncCounts: () => void = () => {};
  toggleAdvancedLineup: () => void = () => {};
  stepFactionCount: (faction: RpsBattleFaction, step: number) => void = () => {};
  startGame: () => void = () => {};

  build() {
    Column({ space: 14 }) {
      Column({ space: 6 }) {
        Text(rpsBattleModeByKey(this.selectedModeKey).name)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Text(rpsBattleThemeByKey(this.selectedThemeKey).subtitle)
          .fontSize(13)
          .fontColor(RpsBattleTheme.muted)
          .textAlign(TextAlign.Center)
          .maxLines(1)
      }
      .width('100%')

      this.SectionHeader('阵营主题', '选择本局展示身份')
      this.ThemeGrid()

      this.SectionHeader('支持阵营', '选中一方，见证它赢下乱斗')
      Row({ space: 8 }) {
        ForEach(rpsBattleThemeFactions(this.selectedThemeKey), (item: RpsBattleFactionInfo) => {
          this.FactionOption(item)
        }, (item: RpsBattleFactionInfo) => `${this.selectedThemeKey}-${item.id}`)
      }
      .width('100%')

      this.SectionHeader('玩法方案', '选择本局规则核心')
      this.ModeGrid()
      this.ModeSummary()
      this.ModeMechanicsPanel()

      this.SectionHeader('阵容规模', this.lineupSummaryText())
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

      this.SectionHeader('对局时长', '倒计时结束后开始计时')
      Row({ space: 8 }) {
        ForEach(RPS_BATTLE_DURATION_CHOICES, (item: RpsBattleDurationChoice) => {
          this.DurationOption(item)
        }, (item: RpsBattleDurationChoice) => `${item.durationSec}`)
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
  SectionHeader(title: string, subtitle: string) {
    Column({ space: 2 }) {
      Text(title)
        .width('100%')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .maxLines(1)
      Text(subtitle)
        .width('100%')
        .fontSize(11)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
    }
    .width('100%')
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
    .height(86)
    .borderRadius(10)
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

  @Builder
  ModeGrid() {
    Grid() {
      ForEach(RPS_BATTLE_MODES, (item: RpsBattleModePreset) => {
        GridItem() {
          this.ModeOption(item)
        }
      }, (item: RpsBattleModePreset) => item.key)
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(8)
    .columnsGap(8)
    .height(152)
  }

  @Builder
  ModeOption(item: RpsBattleModePreset) {
    Column({ space: 3 }) {
      Text(item.icon)
        .fontSize(20)
        .height(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.modeOptionSelected(item) ? RpsBattleTheme.primaryButtonText : RpsBattleTheme.pageInk)
        .textAlign(TextAlign.Center)
        .maxLines(1)
      Text(item.name)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.modeOptionSelected(item) ? RpsBattleTheme.primaryButtonText : RpsBattleTheme.pageInk)
        .textAlign(TextAlign.Center)
        .maxLines(1)
      Text(item.subtitle)
        .fontSize(10)
        .fontColor(this.modeOptionSelected(item) ? 'rgba(255,255,255,0.76)' : RpsBattleTheme.muted)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(72)
    .borderRadius(8)
    .backgroundColor(this.modeOptionSelected(item) ? RpsBattleTheme.primaryButtonBg : '#fff8e8')
    .border({
      width: this.modeOptionSelected(item) ? 2 : 1,
      color: this.modeOptionSelected(item) ? RpsBattleTheme.primaryButtonBg : RpsBattleTheme.panelLine
    })
    .onClick(() => {
      this.selectMode(item.key);
    })
  }

  @Builder
  ModeSummary() {
    Column({ space: 4 }) {
      Text(`目标：${rpsBattleModeByKey(this.selectedModeKey).objective}`)
        .width('100%')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .maxLines(1)
      Text(`机制：${this.modeMechanicsText()}`)
        .width('100%')
        .fontSize(11)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
      if (this.modeUpcomingText() !== '') {
        Text(`后续：${this.modeUpcomingText()}`)
          .width('100%')
          .fontSize(11)
          .fontColor(RpsBattleTheme.muted)
          .maxLines(1)
      }
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .borderRadius(8)
    .backgroundColor('#fffdf6')
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  @Builder
  ModeMechanicsPanel() {
    Column({ space: 7 }) {
      Row({ space: 8 }) {
        Text('模式机制')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .layoutWeight(1)
          .maxLines(1)
        Text(this.modeMechanicStatusText())
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.muted)
          .maxLines(1)
      }
      .width('100%')
      ForEach(rpsBattleModeByKey(this.selectedModeKey).mechanicOptions, (item: RpsBattleMechanicOption) => {
        this.ModeMechanicRow(item)
      }, (item: RpsBattleMechanicOption) => `${this.selectedModeKey}-${item.key}`)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 9, bottom: 9 })
    .borderRadius(8)
    .backgroundColor('#fffdf6')
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  @Builder
  ModeMechanicRow(item: RpsBattleMechanicOption) {
    Row({ space: 8 }) {
      Text(this.mechanicMark(item))
        .width(24)
        .height(24)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.mechanicMarkColor(item))
        .textAlign(TextAlign.Center)
        .backgroundColor(this.mechanicMarkBg(item))
        .borderRadius(7)
      Column({ space: 1 }) {
        Text(item.label)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.mechanicTextColor(item))
          .maxLines(1)
        Text(item.summary)
          .fontSize(10)
          .fontColor(RpsBattleTheme.muted)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(this.mechanicStateText(item.state))
        .width(42)
        .height(22)
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.mechanicStateTextColor(item.state))
        .textAlign(TextAlign.Center)
        .backgroundColor(this.mechanicStateBg(item.state))
        .borderRadius(7)
        .border({ width: 1, color: RpsBattleTheme.panelLine })
    }
    .width('100%')
    .height(42)
    .padding({ left: 7, right: 7 })
    .borderRadius(8)
    .backgroundColor(item.state === 'upcoming' ? '#fff8e8' : RpsBattleTheme.selectedBg)
    .opacity(item.state === 'upcoming' ? 0.62 : 1)
    .border({
      width: 1,
      color: item.state === 'upcoming' ? RpsBattleTheme.panelLine : RpsBattleTheme.selectedLine
    })
  }

  @Builder
  AdvancedLineupToggle() {
    Row({ space: 10 }) {
      Column({ space: 2 }) {
        Text('高级调整')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .maxLines(1)
        Text(`${this.syncCounts ? '同步' : '独立'} · 总数 ${rpsBattleTotalCount(this.lineupCounts)} / ${RPS_BATTLE_MAX_TOTAL_ENTITIES}`)
          .fontSize(10)
          .fontColor(RpsBattleTheme.muted)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(this.advancedLineupOpen ? '收起' : '展开')
        .width(44)
        .height(26)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .textAlign(TextAlign.Center)
        .backgroundColor('#fff8e8')
        .borderRadius(8)
        .border({ width: 1, color: RpsBattleTheme.panelLine })
    }
    .width('100%')
    .height(48)
    .padding({ left: 10, right: 8 })
    .borderRadius(9)
    .backgroundColor('#fffdf6')
    .border({ width: 1, color: RpsBattleTheme.panelLine })
    .onClick(() => {
      this.toggleAdvancedLineup();
    })
  }

  @Builder
  AdvancedLineupPanel() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        this.SyncToggle()
        Text(`每方 ${RPS_BATTLE_MIN_COUNT_PER_FACTION}-${RPS_BATTLE_MAX_COUNT_PER_FACTION}，总数最多 ${RPS_BATTLE_MAX_TOTAL_ENTITIES}`)
          .fontSize(10)
          .fontColor(RpsBattleTheme.muted)
          .layoutWeight(1)
          .maxLines(2)
      }
      .width('100%')
      Row({ space: 7 }) {
        ForEach(rpsBattleThemeFactions(this.selectedThemeKey), (item: RpsBattleFactionInfo) => {
          this.CountControl(item)
        }, (item: RpsBattleFactionInfo) => `count-${this.selectedThemeKey}-${item.id}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding(9)
    .borderRadius(9)
    .backgroundColor('#fffdf6')
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  @Builder
  SyncToggle() {
    Column({ space: 4 }) {
      Text('人数模式')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
      Row({ space: 4 }) {
        this.SyncModeOption('一起调', true)
        this.SyncModeOption('单独调', false)
      }
      .width('100%')
    }
    .width(148)
    .height(50)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 6, right: 6, top: 5, bottom: 5 })
    .borderRadius(8)
    .backgroundColor('#fff8e8')
    .border({ width: 1, color: RpsBattleTheme.panelLine })
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
    .height(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius(6)
    .backgroundColor(this.syncCounts === syncMode ? RpsBattleTheme.primaryButtonBg : '#fffdf6')
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
    Column({ space: 5 }) {
      Text(item.symbol)
        .fontSize(18)
        .height(22)
        .textAlign(TextAlign.Center)
      Text(item.label)
        .fontSize(this.factionLabelFontSize(item.label))
        .fontWeight(FontWeight.Bold)
        .fontColor(item.textColor)
        .maxLines(1)
      Row({ space: 4 }) {
        this.CountStepButton('-', this.canDecrease(item.id), () => {
          this.stepFactionCount(item.id, -1);
        })
        Text(`${rpsBattleCountValue(this.lineupCounts, item.id)}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .maxLines(1)
        this.CountStepButton('+', this.canIncrease(item.id), () => {
          this.stepFactionCount(item.id, 1);
        })
      }
      .width('100%')
    }
    .layoutWeight(1)
    .height(94)
    .padding({ left: 6, right: 6, top: 7, bottom: 7 })
    .borderRadius(8)
    .backgroundColor(item.softColor)
    .border({ width: 1, color: 'rgba(86,55,35,0.10)' })
  }

  @Builder
  CountStepButton(label: string, enabled: boolean, action: () => void) {
    Row() {
      Text(label)
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .width(26)
    .height(28)
    .borderRadius(7)
    .backgroundColor('#fff8e8')
    .opacity(enabled ? 1 : 0.36)
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
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .maxLines(1)
      Text(`${item.durationSec}s`)
        .fontSize(11)
        .fontColor(this.durationSec === item.durationSec ? RpsBattleTheme.pageInk : RpsBattleTheme.muted)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(52)
    .borderRadius(9)
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
    return `总数 ${rpsBattleTotalCount(this.lineupCounts)} / ${RPS_BATTLE_MAX_TOTAL_ENTITIES}`;
  }

  private modeOptionSelected(item: RpsBattleModePreset): boolean {
    return this.selectedModeKey === item.key;
  }

  private modeMechanicsText(): string {
    const enabled = rpsBattleModeByKey(this.selectedModeKey).enabledMechanics;
    if (enabled.length === 0) {
      return '待接入';
    }
    return enabled.join(' / ');
  }

  private modeUpcomingText(): string {
    return rpsBattleModeByKey(this.selectedModeKey).upcomingMechanics.join(' / ');
  }

  private modeMechanicStatusText(): string {
    if (this.selectedModeKey === 'zones') {
      return '默认机制包';
    }
    return '随模式变化';
  }

  private mechanicMark(item: RpsBattleMechanicOption): string {
    if (item.state === 'upcoming') {
      return '·';
    }
    return '✓';
  }

  private mechanicMarkColor(item: RpsBattleMechanicOption): string {
    if (item.state === 'upcoming') {
      return RpsBattleTheme.muted;
    }
    return RpsBattleTheme.primaryButtonText;
  }

  private mechanicMarkBg(item: RpsBattleMechanicOption): string {
    if (item.state === 'upcoming') {
      return '#fffdf6';
    }
    return RpsBattleTheme.primaryButtonBg;
  }

  private mechanicTextColor(item: RpsBattleMechanicOption): string {
    if (item.state === 'upcoming') {
      return RpsBattleTheme.muted;
    }
    return RpsBattleTheme.pageInk;
  }

  private mechanicStateText(state: RpsBattleMechanicState): string {
    if (state === 'core') {
      return '核心';
    }
    if (state === 'enabled') {
      return '已开';
    }
    return '后续';
  }

  private mechanicStateTextColor(state: RpsBattleMechanicState): string {
    if (state === 'upcoming') {
      return RpsBattleTheme.muted;
    }
    return RpsBattleTheme.pageInk;
  }

  private mechanicStateBg(state: RpsBattleMechanicState): string {
    if (state === 'upcoming') {
      return '#fffdf6';
    }
    return '#fff8e8';
  }

  private canIncrease(faction: RpsBattleFaction): boolean {
    return rpsBattleCanIncreaseCount(this.lineupCounts, faction, this.syncCounts);
  }

  private canDecrease(faction: RpsBattleFaction): boolean {
    return rpsBattleCanDecreaseCount(this.lineupCounts, faction, this.syncCounts);
  }
}
