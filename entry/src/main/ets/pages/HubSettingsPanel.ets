import { AppIcon } from '../components/AppIcon';
import { APPEARANCE_DARK, APPEARANCE_LIGHT, APPEARANCE_SYSTEM } from '../shell/GameModule';

@Component
export struct HubSettingsPanel {
  @Prop appearanceMode: string = APPEARANCE_SYSTEM;
  @Prop isDarkMode: boolean = false;
  @Prop roomy: boolean = false;
  updateAppearanceMode: (appearanceMode: string) => void = () => {};
  resetAchievements: () => Promise<boolean> = async (): Promise<boolean> => false;
  @State private developerExpanded: boolean = false;
  @State private resetPresented: boolean = false;
  @State private resetting: boolean = false;
  @State private resetMessage: string = '';

  build() {
    Column({ space: 24 }) {
      Column({ space: 7 }) {
        Text('设置').fontSize(26).fontWeight(FontWeight.Bold).fontColor(this.ink())
        Text('把鸡窝调成你喜欢的样子。').fontSize(13).fontColor(this.muted())
      }.width('100%').alignItems(HorizontalAlign.Start)
      Column({ space: 16 }) {
        Row({ space: 9 }) {
          AppIcon({ name: 'sun', iconSize: 21, tint: this.accent() })
          Text('外观').fontSize(17).fontWeight(FontWeight.Bold).fontColor(this.ink())
          Blank()
          Text(`${this.appearanceMode === APPEARANCE_SYSTEM ? '自动' : '手动'} · ${this.dark() ? '深色' : '浅色'}`)
            .fontSize(11).fontColor(this.muted())
        }.width('100%')
        this.SystemAppearanceOption()
        Row({ space: this.roomy ? 20 : 12 }) {
          this.AppearanceOption(APPEARANCE_LIGHT)
          this.AppearanceOption(APPEARANCE_DARK)
        }.width('100%').alignItems(VerticalAlign.Top)
        Text(this.appearanceMode === APPEARANCE_SYSTEM ? '日光与月色，随设备自然切换。' : '已固定当前外观，选择「跟随系统」可恢复自动切换。')
          .fontSize(12).fontColor(this.muted()).width('100%')
      }
      .width('100%').padding(this.roomy ? 24 : 16)
      .backgroundColor(this.surface()).borderRadius(24)
      .border({ width: 1, color: this.line() })
      Row({ space: 14 }) {
        Image($rawfile('app/ui/chicken.svg')).width(52).height(52).objectFit(ImageFit.Contain)
          .accessibilityLevel('no')
        Column({ space: 5 }) {
          Text('鸡窝游戏').fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.ink())
          Text('没网也能玩一窝').fontSize(12).fontColor(this.muted())
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        AppIcon({ name: 'heart', iconSize: 20, tint: this.accent() })
      }.width('100%').padding(18).backgroundColor(this.surface()).borderRadius(20)
      Column({ space: 12 }) {
        Button({ type: ButtonType.Normal }) {
          Row() {
            Text('开发与调试').fontSize(13).fontColor(this.muted())
            Blank()
            AppIcon({ name: 'chevron_right', iconSize: 18, tint: this.muted() })
              .rotate({ angle: this.developerExpanded ? 90 : 0 })
          }.width('100%')
        }.width('100%').height(44).padding({ left: 4, right: 4 })
        .backgroundColor(Color.Transparent)
        .accessibilityText(`开发与调试，${this.developerExpanded ? '收起' : '展开'}`)
        .onClick(() => { this.developerExpanded = !this.developerExpanded; })
        if (this.developerExpanded) {
          Text('仅用于测试成就反馈，游戏存档不会被清除。')
            .fontSize(12).fontColor(this.muted()).width('100%')
          Button('清除本机成就', { type: ButtonType.Normal })
            .width('100%').height(46).fontSize(13).borderRadius(14)
            .fontColor(this.dark() ? '#FFD0C4' : '#A33E30')
            .backgroundColor(this.dark() ? '#382622' : '#FBE9E2')
            .enabled(!this.resetting)
            .onClick(() => { this.resetMessage = ''; this.resetPresented = true; })
          if (this.resetMessage.length > 0) {
            Text(this.resetMessage).fontSize(12).fontColor(this.muted()).width('100%')
          }
        }
      }.width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
    .bindSheet($$this.resetPresented, this.ResetSheet(), {
      height: SheetSize.FIT_CONTENT, showClose: true, dragBar: true
    })
  }

  @Builder
  SystemAppearanceOption() {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 12 }) {
        AppIcon({ name: 'theme_auto', iconSize: 24, tint: this.accent() })
        Column({ space: 5 }) {
          Text('跟随系统').fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.ink())
          Text('随设备自动切换浅色与深色').fontSize(12).fontColor(this.muted())
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        AppIcon({ name: this.appearanceMode === APPEARANCE_SYSTEM ? 'check' : 'circle',
          iconSize: 18, tint: this.appearanceMode === APPEARANCE_SYSTEM ? this.accent() : this.muted() })
      }.width('100%')
    }
    .width('100%').padding(16).borderRadius(18)
    .backgroundColor(this.dark() ? '#2C2922' : '#FFF3DC')
    .border({ width: this.appearanceMode === APPEARANCE_SYSTEM ? 2 : 1,
      color: this.appearanceMode === APPEARANCE_SYSTEM ? this.accent() : this.line() })
    .accessibilityText(`跟随系统，${this.appearanceMode === APPEARANCE_SYSTEM ? '已选择' : '未选择'}`)
    .onClick(() => this.updateAppearanceMode(APPEARANCE_SYSTEM))
  }

  @Builder
  AppearanceOption(mode: string) {
    Column() {
    Button({ type: ButtonType.Normal }) {
      Column({ space: 12 }) {
        Image($rawfile(mode === APPEARANCE_DARK ? 'app/home/home_poster_dark.svg' : 'app/home/home_poster_light.svg'))
          .width('100%').aspectRatio(720 / 448).objectFit(ImageFit.Contain)
          .borderRadius(12).clip(true).draggable(false).accessibilityLevel('no')
        Row({ space: 6 }) {
          AppIcon({ name: mode === APPEARANCE_DARK ? 'moon' : 'sun', iconSize: 18,
            tint: mode === APPEARANCE_DARK ? '#FFD083' : '#895A27' })
          Text(mode === APPEARANCE_DARK ? '月色 · 深色' : '暖阳 · 浅色')
            .fontSize(13).fontWeight(FontWeight.Medium)
            .fontColor(mode === APPEARANCE_DARK ? '#FFF0D2' : '#634226').layoutWeight(1)
          if (this.appearanceMode === mode) {
            AppIcon({ name: 'check', iconSize: 16, tint: mode === APPEARANCE_DARK ? '#FFD083' : '#895A27' })
          }
        }.width('100%')
      }.width('100%').padding(this.roomy ? 16 : 10)
    }
    .width('100%').padding(0).borderRadius(18)
    .backgroundColor(Color.Transparent)
    .accessibilityText(`${mode === APPEARANCE_DARK ? '深色' : '浅色'}模式，${this.appearanceMode === mode ? '已选择' : '未选择'}`)
    .onClick(() => this.updateAppearanceMode(mode))
    }
    .layoutWeight(1).borderRadius(18).clip(true)
    .backgroundColor(mode === APPEARANCE_DARK ? '#302C27' : '#FFF0D5')
    .border({ width: this.appearanceMode === mode ? 2 : 1, radius: 18,
      color: this.appearanceMode === mode ? this.accent() : this.line() })
  }

  @Builder
  ResetSheet() {
    Column({ space: 16 }) {
      Text('清除本机成就？').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.ink())
      Text('会清空成就进度和已处理事件；游戏存档、最高分、收藏和设置不会受影响。')
        .fontSize(14).lineHeight(23).fontColor(this.muted()).width('100%')
      if (this.resetMessage.length > 0) {
        Text(this.resetMessage).fontSize(12).fontColor(this.muted())
      }
      Row({ space: 12 }) {
        Button('取消').layoutWeight(1).height(46).fontColor(this.ink()).backgroundColor(this.surface())
          .enabled(!this.resetting).onClick(() => { this.resetPresented = false; })
        Button(this.resetting ? '清除中…' : '确认清除').layoutWeight(1).height(46)
          .fontColor('#FFFFFF').backgroundColor('#B64D3B').enabled(!this.resetting)
          .onClick(() => this.confirmReset())
      }.width('100%')
    }.width('100%').padding({ left: 24, right: 24, top: 20, bottom: 28 })
    .backgroundColor(this.surface())
  }

  private async confirmReset(): Promise<void> {
    if (this.resetting) return;
    this.resetting = true;
    try {
      const saved = await this.resetAchievements();
      this.resetMessage = saved ? '已清除本机成就进度，可重新测试。' : '未能保存更改，请重试。';
      if (saved) this.resetPresented = false;
    } catch (_) {
      this.resetMessage = '未能保存更改，请重试。';
    }
    this.resetting = false;
  }

  private dark(): boolean { return this.isDarkMode; }
  private ink(): string { return this.dark() ? '#FFF2DF' : '#39291E'; }
  private muted(): string { return this.dark() ? '#C8B7A2' : '#806A54'; }
  private accent(): string { return this.dark() ? '#FFD083' : '#A76720'; }
  private surface(): string { return this.dark() ? '#211F1B' : '#FFFAF2'; }
  private line(): string { return this.dark() ? '#44392B' : '#E9D9C1'; }
}
