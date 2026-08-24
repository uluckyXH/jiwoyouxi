import { CoopMotion } from '../design/CoopMotion';
import { CoopTheme } from '../design/CoopTheme';
import { APPEARANCE_DARK, APPEARANCE_LIGHT } from '../shell/GameModule';

const SETTINGS_GROUP_RADIUS: number = 18;
const SETTINGS_SEGMENT_HEIGHT: number = 58;

@Component
export struct HubSettingsPanel {
  @Prop appearanceMode: string = APPEARANCE_LIGHT;
  updateAppearanceMode: (appearanceMode: string) => void = () => {};

  build() {
    Column({ space: 12 }) {
      this.SettingsTitleRow()
      Column({ space: 8 }) {
        this.SettingsGroupLabel('外观')
        this.AppearanceModeSelector()
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  SettingsTitleRow() {
    Row() {
      Row({ space: 8 }) {
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph($r('sys.symbol.more'))
            .fontSize(17)
            .fontColor([this.activeIconColor()])
        }
        .width(28)
        .height(28)
        .backgroundColor(this.sectionIconBgColor())
        .borderRadius(14)
        .border({ width: 1, color: this.lineColor() })
        Text('设置')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.inkColor())
      }
    }
    .width('100%')
    .margin({ top: 2 })
  }

  @Builder
  SettingsGroupLabel(label: string) {
    Text(label)
      .width('100%')
      .height(18)
      .padding({ left: 4 })
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.settingsSectionColor())
  }

  @Builder
  AppearanceModeSelector() {
    Row({ space: 6 }) {
      this.AppearanceModeOption('☀', '浅色', APPEARANCE_LIGHT)
      this.AppearanceModeOption('☾', '深色', APPEARANCE_DARK)
    }
    .width('100%')
    .height(SETTINGS_SEGMENT_HEIGHT)
    .padding(5)
    .borderRadius(SETTINGS_GROUP_RADIUS)
    .backgroundColor(this.panelColor())
    .border({ width: 1, color: this.lineColor() })
    .shadow(this.softShadow())
  }

  @Builder
  AppearanceModeOption(symbol: string, label: string, appearanceMode: string) {
    Stack({ alignContent: Alignment.Center }) {
      Row({ space: 7 }) {
        Text(symbol)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.appearanceSegmentTextColor(appearanceMode))
        Text(label)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.appearanceSegmentTextColor(appearanceMode))
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .layoutWeight(1)
    .height('100%')
    .borderRadius(SETTINGS_GROUP_RADIUS - 5)
    .backgroundColor(this.appearanceSegmentBgColor(appearanceMode))
    .border({ width: 1, color: this.appearanceSegmentLineColor(appearanceMode) })
    .onClick(() => {
      this.selectAppearanceMode(appearanceMode);
    })
  }

  private selectAppearanceMode(appearanceMode: string): void {
    if (appearanceMode === this.appearanceMode) {
      return;
    }
    this.getUIContext().animateTo({
      duration: CoopMotion.modalDuration,
      curve: Curve.EaseOut
    }, () => {
      this.updateAppearanceMode(appearanceMode);
    });
  }

  private isDarkMode(): boolean {
    return this.appearanceMode === APPEARANCE_DARK;
  }

  private inkColor(): string {
    return this.isDarkMode() ? '#FFF2DF' : CoopTheme.ink;
  }

  private activeIconColor(): string {
    return this.isDarkMode() ? '#FFD083' : '#F4A51F';
  }

  private panelColor(): string {
    return this.isDarkMode() ? '#211F1B' : '#FFFAF2';
  }

  private sectionIconBgColor(): string {
    return this.isDarkMode() ? '#2A2621' : '#FFF0DA';
  }

  private lineColor(): string {
    return this.isDarkMode() ? 'rgba(255,236,205,0.14)' : 'rgba(132,91,45,0.12)';
  }

  private settingsSectionColor(): string {
    return this.isDarkMode() ? '#C8B7A2' : '#8B6D52';
  }

  private appearanceSegmentBgColor(appearanceMode: string): string {
    if (appearanceMode === this.appearanceMode) {
      return this.isDarkMode() ? '#D99632' : '#F7C66B';
    }
    return this.isDarkMode() ? '#2A2621' : '#FFF8EE';
  }

  private appearanceSegmentTextColor(appearanceMode: string): string {
    return appearanceMode === this.appearanceMode ? '#2F1D14' : this.settingsSectionColor();
  }

  private appearanceSegmentLineColor(appearanceMode: string): string {
    return appearanceMode === this.appearanceMode ? 'rgba(110,66,25,0.24)' : this.lineColor();
  }

  private softShadow(): ShadowOptions {
    if (this.isDarkMode()) {
      return {
        radius: 26,
        color: 'rgba(0,0,0,0.42)',
        offsetX: 0,
        offsetY: 12
      };
    }
    return {
      radius: 26,
      color: 'rgba(112,73,34,0.18)',
      offsetX: 0,
      offsetY: 12
    };
  }
}
