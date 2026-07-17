import { RpsBattleSetupCardHeader } from './RpsBattleSetupCardHeader';
import { RpsBattleTheme } from './RpsBattleTheme';
import {
  RpsBattleMechanicKey,
  RpsBattleMechanicOption,
  RpsBattleMechanicSelection,
  RpsBattleMechanicState,
  RpsBattleModeKey,
  RpsBattleModePreset
} from './RpsBattleTypes';
import {
  RPS_BATTLE_MODES,
  rpsBattleMechanicEnabledForMode,
  rpsBattleModeByKey
} from './RpsBattleModeConfig';

@Component
export struct RpsBattleModeSetupCard {
  @Prop selectedModeKey: RpsBattleModeKey = 'classic';
  @Prop mechanicSelection: RpsBattleMechanicSelection = {};
  selectMode: (modeKey: RpsBattleModeKey) => void = () => {};
  toggleMechanic: (mechanicKey: RpsBattleMechanicKey) => void = () => {};

  build() {
    Column({ space: 12 }) {
      this.ModeConfigCard()
      if (this.shouldShowMechanicsCard()) {
        this.MechanicsConfigCard()
      }
    }
    .width('100%')
  }

  @Builder
  ModeConfigCard() {
    Column({ space: 12 }) {
      RpsBattleSetupCardHeader({ order: '01', title: '玩法方案', subtitle: '先确定本局规则核心' })
      this.ModeGrid()
      this.ModeRuleSummary()
    }
    .width('100%')
    .padding(14)
    .borderRadius(8)
    .backgroundColor(RpsBattleTheme.panelBg)
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  @Builder
  MechanicsConfigCard() {
    Column({ space: 8 }) {
      RpsBattleSetupCardHeader({ order: '02', title: '本局机制', subtitle: this.modeMechanicStatusText() })
      this.SectionRule()
      Column({ space: 0 }) {
        ForEach(rpsBattleModeByKey(this.selectedModeKey).mechanicOptions, (item: RpsBattleMechanicOption) => {
          this.ModeMechanicRow(item)
        }, (item: RpsBattleMechanicOption) => `${this.selectedModeKey}-${item.key}`)
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
  ModeRuleSummary() {
    Column({ space: 6 }) {
      this.SectionRule()
      this.SummaryRow('目标', rpsBattleModeByKey(this.selectedModeKey).objective)
      if (this.hasEnabledMechanics()) {
        this.SummaryRow('已启用', this.modeMechanicsText())
      } else {
        this.SummaryRow('状态', '机制迁移中')
      }
      if (this.modeUpcomingText() !== '') {
        this.SummaryRow('后续', this.modeUpcomingText())
      }
    }
    .width('100%')
  }

  @Builder
  SummaryRow(label: string, value: string) {
    Row({ space: 8 }) {
      Text(label)
        .width(42)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
      Text(value)
        .fontSize(11)
        .fontColor(RpsBattleTheme.pageInk)
        .layoutWeight(1)
        .maxLines(2)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  ModeMechanicRow(item: RpsBattleMechanicOption) {
    Row({ space: 10 }) {
      Text(this.mechanicMark(item))
        .width(28)
        .height(28)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.mechanicMarkColor(item))
        .textAlign(TextAlign.Center)
        .backgroundColor(this.mechanicMarkBg(item))
        .borderRadius(8)
      Column({ space: 2 }) {
        Text(item.label)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.mechanicTextColor(item))
          .maxLines(1)
        Text(item.summary)
          .fontSize(10)
          .fontColor(RpsBattleTheme.muted)
          .maxLines(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      if (this.mechanicCanToggle(item)) {
        this.MechanicSwitch(item)
      } else {
        this.MechanicStateBadge(item.state)
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .opacity(item.state === 'upcoming' ? 0.62 : 1)
    .border({ width: { bottom: 1 }, color: RpsBattleTheme.panelLine })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  MechanicSwitch(item: RpsBattleMechanicOption) {
    Row() {
      Text(this.mechanicEnabled(item) ? '开' : '关')
        .width('100%')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.mechanicEnabled(item) ? RpsBattleTheme.primaryButtonText : RpsBattleTheme.pageInk)
        .textAlign(TextAlign.Center)
    }
    .width(50)
    .height(40)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius(8)
    .backgroundColor(this.mechanicEnabled(item) ? RpsBattleTheme.primaryButtonBg : '#fff8e8')
    .border({ width: 1, color: this.mechanicEnabled(item) ? RpsBattleTheme.primaryButtonBg : RpsBattleTheme.panelLine })
    .onClick(() => {
      this.toggleMechanic(item.key);
    })
  }

  @Builder
  MechanicStateBadge(state: RpsBattleMechanicState) {
    Text(this.mechanicStateText(state))
      .width(50)
      .height(28)
      .fontSize(10)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.mechanicStateTextColor(state))
      .textAlign(TextAlign.Center)
      .backgroundColor(this.mechanicStateBg(state))
      .borderRadius(7)
      .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  private shouldShowMechanicsCard(): boolean {
    const options = rpsBattleModeByKey(this.selectedModeKey).mechanicOptions;
    for (let i = 0; i < options.length; i += 1) {
      if (options[i].state !== 'core') {
        return true;
      }
    }
    return false;
  }

  private hasEnabledMechanics(): boolean {
    const options = rpsBattleModeByKey(this.selectedModeKey).mechanicOptions;
    for (let i = 0; i < options.length; i += 1) {
      if (options[i].state !== 'upcoming' && this.mechanicEnabled(options[i])) {
        return true;
      }
    }
    return false;
  }

  private modeMechanicsText(): string {
    const labels: string[] = [];
    const options = rpsBattleModeByKey(this.selectedModeKey).mechanicOptions;
    for (let i = 0; i < options.length; i += 1) {
      const item = options[i];
      if (item.state !== 'upcoming' && this.mechanicEnabled(item)) {
        labels.push(item.label);
      }
    }
    return labels.join(' / ');
  }

  private modeUpcomingText(): string {
    return rpsBattleModeByKey(this.selectedModeKey).upcomingMechanics.join(' / ');
  }

  private modeMechanicStatusText(): string {
    const options = rpsBattleModeByKey(this.selectedModeKey).mechanicOptions;
    let hasRunnableMechanic = false;
    for (let i = 0; i < options.length; i += 1) {
      if (options[i].state !== 'upcoming') {
        hasRunnableMechanic = true;
      }
      if (this.mechanicCanToggle(options[i])) {
        return '默认可调，可在开局前关闭';
      }
    }
    return hasRunnableMechanic ? '核心机制不可关闭' : '机制迁移中';
  }

  private modeOptionSelected(item: RpsBattleModePreset): boolean {
    return this.selectedModeKey === item.key;
  }

  private mechanicMark(item: RpsBattleMechanicOption): string {
    if (item.state === 'upcoming') {
      return '·';
    }
    return this.mechanicEnabled(item) ? '✓' : '关';
  }

  private mechanicMarkColor(item: RpsBattleMechanicOption): string {
    if (item.state === 'upcoming') {
      return RpsBattleTheme.muted;
    }
    return this.mechanicEnabled(item) ? RpsBattleTheme.primaryButtonText : RpsBattleTheme.muted;
  }

  private mechanicMarkBg(item: RpsBattleMechanicOption): string {
    if (item.state === 'upcoming' || !this.mechanicEnabled(item)) {
      return '#fff8e8';
    }
    return RpsBattleTheme.primaryButtonBg;
  }

  private mechanicTextColor(item: RpsBattleMechanicOption): string {
    if (item.state === 'upcoming' || !this.mechanicEnabled(item)) {
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
      return '#fff8e8';
    }
    return '#fff4d9';
  }

  private mechanicCanToggle(item: RpsBattleMechanicOption): boolean {
    return item.state === 'enabled' && item.canDisable;
  }

  private mechanicEnabled(item: RpsBattleMechanicOption): boolean {
    return rpsBattleMechanicEnabledForMode(this.selectedModeKey, this.mechanicSelection, item.key);
  }
}
