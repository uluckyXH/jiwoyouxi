import { RpsBattleSetupPanel } from './RpsBattleSetupPanel';
import { RpsBattleTheme } from './RpsBattleTheme';
import {
  RPS_BATTLE_SCALE_CHOICES,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleMechanicKey,
  RpsBattleMechanicOption,
  RpsBattleMechanicSelection,
  RpsBattleModeKey,
  RpsBattleScale,
  RpsBattleThemeKey
} from './RpsBattleTypes';
import { rpsBattleMechanicEnabledForMode, rpsBattleModeByKey } from './RpsBattleModeConfig';

const RPS_BATTLE_TOP_BAR_HEIGHT: number = 88;
const RPS_BATTLE_SETUP_BOTTOM_ACTION_HEIGHT: number = 92;

@Component
export struct RpsBattleSetupScreen {
  @Prop contentWidth: number = 358;
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
  startGame: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          Column({ space: 12 }) {
            this.SetupIntro()
            RpsBattleSetupPanel({
              selectedThemeKey: this.selectedThemeKey,
              selectedModeKey: this.selectedModeKey,
              mechanicSelection: this.mechanicSelection,
              selectedFaction: this.selectedFaction,
              selectedScale: this.selectedScale,
              lineupCounts: this.lineupCounts,
              syncCounts: this.syncCounts,
              advancedLineupOpen: this.advancedLineupOpen,
              durationSec: this.durationSec,
              selectTheme: (themeKey: RpsBattleThemeKey) => {
                this.selectTheme(themeKey);
              },
              selectMode: (modeKey: RpsBattleModeKey) => {
                this.selectMode(modeKey);
              },
              toggleMechanic: (mechanicKey: RpsBattleMechanicKey) => {
                this.toggleMechanic(mechanicKey);
              },
              selectFaction: (faction: RpsBattleFaction) => {
                this.selectFaction(faction);
              },
              selectScale: (scale: RpsBattleScale) => {
                this.selectScale(scale);
              },
              selectDuration: (durationSec: number) => {
                this.selectDuration(durationSec);
              },
              toggleSyncCounts: () => {
                this.toggleSyncCounts();
              },
              toggleAdvancedLineup: () => {
                this.toggleAdvancedLineup();
              },
              stepFactionCount: (faction: RpsBattleFaction, step: number) => {
                this.stepFactionCount(faction, step);
              }
            })
            Blank()
              .height(RPS_BATTLE_SETUP_BOTTOM_ACTION_HEIGHT)
          }
          .width(this.contentWidth)
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .padding({ top: RPS_BATTLE_TOP_BAR_HEIGHT + 16, bottom: 12 })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')

      this.StartActionBar()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SetupIntro() {
    Column({ space: 3 }) {
      Text('创建一局乱斗')
        .width('100%')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .maxLines(1)
      Text(`${rpsBattleModeByKey(this.selectedModeKey).name} · ${rpsBattleModeByKey(this.selectedModeKey).objective}`)
        .width('100%')
        .fontSize(12)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
    }
    .width('100%')
    .padding({ left: 2, right: 2, bottom: 2 })
  }

  @Builder
  StartActionBar() {
    Column({ space: 6 }) {
      Text(this.startSummaryText())
        .width(this.contentWidth)
        .fontSize(11)
        .fontColor(RpsBattleTheme.muted)
        .textAlign(TextAlign.Center)
        .maxLines(1)
      Button('开始乱斗')
        .width(this.contentWidth)
        .height(48)
        .borderRadius(8)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.primaryButtonText)
        .backgroundColor(RpsBattleTheme.primaryButtonBg)
        .onClick(() => {
          this.startGame();
        })
    }
    .width('100%')
    .padding({ top: 9, bottom: 11 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(RpsBattleTheme.topBarBg)
    .border({ width: { top: 1 }, color: RpsBattleTheme.panelLine })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .shadow({
      radius: 10,
      color: RpsBattleTheme.boardShadowColor,
      offsetX: 0,
      offsetY: -2
    })
  }

  private startSummaryText(): string {
    const segments: string[] = [];
    segments.push(rpsBattleModeByKey(this.selectedModeKey).name);
    const mechanicText = this.optionalMechanicSummary();
    if (mechanicText !== '') {
      segments.push(mechanicText);
    }
    segments.push(this.scaleLabel());
    segments.push(`${this.durationSec}秒`);
    return segments.join(' · ');
  }

  private optionalMechanicSummary(): string {
    const labels: string[] = [];
    const options = rpsBattleModeByKey(this.selectedModeKey).mechanicOptions;
    for (let i = 0; i < options.length; i += 1) {
      const item: RpsBattleMechanicOption = options[i];
      if (item.state === 'enabled' && item.canDisable) {
        const enabled = rpsBattleMechanicEnabledForMode(this.selectedModeKey, this.mechanicSelection, item.key);
        labels.push(`${item.label}${enabled ? '开' : '关'}`);
      }
    }
    return labels.join(' / ');
  }

  private scaleLabel(): string {
    if (this.selectedScale === 'custom') {
      return '自定义规模';
    }
    for (let i = 0; i < RPS_BATTLE_SCALE_CHOICES.length; i += 1) {
      if (RPS_BATTLE_SCALE_CHOICES[i].id === this.selectedScale) {
        return `${RPS_BATTLE_SCALE_CHOICES[i].label}规模`;
      }
    }
    return '标准规模';
  }
}
