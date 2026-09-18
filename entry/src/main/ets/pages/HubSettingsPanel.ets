import { AppIcon } from '../components/AppIcon';
import { APPEARANCE_DARK, APPEARANCE_LIGHT, APPEARANCE_SYSTEM } from '../shell/GameModule';

@Component
export struct HubSettingsPanel {
  @Prop appearanceMode: string = APPEARANCE_SYSTEM;
  @Prop isDarkMode: boolean = false;
  @Prop roomy: boolean = false;
  @Prop stackedAppearance: boolean = false;
  updateAppearanceMode: (appearanceMode: string) => void = () => {};

  build() {
    Column({ space: 24 }) {
      Column({ space: 7 }) {
        Text('设置').fontSize(26).fontWeight(FontWeight.Bold).fontColor(this.ink())
        Text('把鸡窝调成你喜欢的样子。').fontSize(13).fontColor(this.muted())
      }.width('100%').alignItems(HorizontalAlign.Start)
      Column({ space: 16 }) {
        Row({ space: 9 }) {
          AppIcon({ name: 'theme_auto', iconSize: 21, tint: this.accent() })
          Text('外观').fontSize(17).fontWeight(FontWeight.Bold).fontColor(this.ink())
          Blank()
          Text(`当前${this.dark() ? '深色' : '浅色'}`)
            .fontSize(10).fontColor(this.muted())
            .padding({ left: 9, right: 9, top: 5, bottom: 5 })
            .backgroundColor(this.dark() ? '#302B23' : '#F6EAD7').borderRadius(12)
        }.width('100%')
        if (this.stackedAppearance) {
          Column({ space: 10 }) {
            this.AppearanceOption(APPEARANCE_SYSTEM)
            this.AppearanceOption(APPEARANCE_LIGHT)
            this.AppearanceOption(APPEARANCE_DARK)
          }.width('100%')
        } else {
          Row({ space: this.roomy ? 12 : 8 }) {
            Column() { this.AppearanceOption(APPEARANCE_SYSTEM) }.layoutWeight(1)
            Column() { this.AppearanceOption(APPEARANCE_LIGHT) }.layoutWeight(1)
            Column() { this.AppearanceOption(APPEARANCE_DARK) }.layoutWeight(1)
          }.width('100%').alignItems(VerticalAlign.Top)
        }
        Text(this.appearanceMode === APPEARANCE_SYSTEM ? '日光与月色，随设备自然切换。' : '已固定当前外观，选择「跟随系统」可恢复自动切换。')
          .fontSize(11).lineHeight(18).fontColor(this.muted()).width('100%')
      }
      .width('100%').padding(this.roomy ? 24 : 16)
      .backgroundColor(this.surface())
      .border({ width: 1, radius: 24, color: this.line() }).borderRadius(24).clip(true)
      Row({ space: 14 }) {
        Image($rawfile('app/ui/chicken.svg')).width(52).height(52).objectFit(ImageFit.Contain)
          .accessibilityLevel('no')
        Column({ space: 5 }) {
          Text('鸡窝游戏').fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.ink())
          Text('没网也能玩一窝').fontSize(12).fontColor(this.muted())
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        AppIcon({ name: 'heart', iconSize: 20, tint: this.accent() })
      }.width('100%').padding(18).backgroundColor(this.surface()).borderRadius(20)
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  AppearanceOption(mode: string) {
    Button({ type: ButtonType.Normal }) {
      if (this.stackedAppearance) {
        Row({ space: 12 }) {
          Image($rawfile(`app/appearance/${mode}.svg`))
            .width(64).height(48).objectFit(ImageFit.Contain)
            .draggable(false).accessibilityLevel('no')
          Column({ space: 4 }) {
            Text(this.modeTitle(mode)).fontSize(13).lineHeight(18)
              .fontWeight(600).fontColor(this.ink()).width('100%')
            Text(this.modeDescription(mode)).fontSize(11).lineHeight(16)
              .fontColor(this.muted()).width('100%')
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          this.SelectionMark(mode)
        }.width('100%').padding(12)
      } else {
        Column({ space: 10 }) {
          Image($rawfile(`app/appearance/${mode}.svg`))
            .width('100%').height(this.roomy ? 84 : 62).objectFit(ImageFit.Contain)
            .draggable(false).accessibilityLevel('no')
          Row({ space: 4 }) {
            Text(this.modeTitle(mode)).fontSize(12).lineHeight(16).fontWeight(600)
              .fontColor(this.ink()).layoutWeight(1).maxLines(1)
            this.SelectionMark(mode)
          }.width('100%')
        }.width('100%').padding(this.roomy ? 12 : 8)
      }
    }
    .width('100%').padding(0)
    .backgroundColor(this.optionSurface(mode))
    .border({ width: 1.5, radius: 18, color: this.appearanceMode === mode ? this.accent() : this.line() })
    .borderRadius(18).clip(true)
    .accessibilityText(`${this.modeTitle(mode)}，${this.appearanceMode === mode ? '已选择' : '未选择'}，${this.modeDescription(mode)}`)
    .onClick(() => this.updateAppearanceMode(mode))
  }

  @Builder
  SelectionMark(mode: string) {
    Stack() {
      if (this.appearanceMode === mode) {
        AppIcon({ name: 'check', iconSize: 10, tint: this.dark() ? '#39291E' : '#FFFAF2' })
      }
    }
    .width(16).height(16)
    .backgroundColor(this.appearanceMode === mode ? this.accent() : Color.Transparent)
    .border({ width: 1.5, radius: 8, color: this.appearanceMode === mode ? this.accent() :
      (this.dark() ? '#82725F' : '#CBB799') })
    .borderRadius(8)
    .accessibilityLevel('no')
  }

  private modeTitle(mode: string): string {
    if (mode === APPEARANCE_SYSTEM) return '跟随系统';
    return mode === APPEARANCE_DARK ? '深色' : '浅色';
  }

  private modeDescription(mode: string): string {
    if (mode === APPEARANCE_SYSTEM) return '随设备自动切换';
    return mode === APPEARANCE_DARK ? '温柔月色，安静陪伴' : '奶油暖阳，明亮轻松';
  }

  private optionSurface(mode: string): string {
    if (this.appearanceMode === mode) return this.dark() ? '#352D22' : '#FFF0D5';
    return this.dark() ? '#292620' : '#FFFDF8';
  }

  private dark(): boolean { return this.isDarkMode; }
  private ink(): string { return this.dark() ? '#FFF2DF' : '#39291E'; }
  private muted(): string { return this.dark() ? '#C8B7A2' : '#806A54'; }
  private accent(): string { return this.dark() ? '#FFD083' : '#A76720'; }
  private surface(): string { return this.dark() ? '#211F1B' : '#FFFAF2'; }
  private line(): string { return this.dark() ? '#44392B' : '#E9D9C1'; }
}
