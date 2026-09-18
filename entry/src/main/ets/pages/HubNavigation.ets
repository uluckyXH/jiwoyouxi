import { AppIcon } from '../components/AppIcon';

const LABELS: string[] = ['首页', '收藏', '成就', '设置'];
const ICONS: string[] = ['home', 'heart', 'medal', 'settings'];

export function hubNavigationSurface(dark: boolean): string {
  return dark ? '#171613' : '#FFF7EA';
}

@Component
export struct HubNavigation {
  @Prop mode: string = 'bottom';
  @Prop activeTab: number = 0;
  @Prop dark: boolean = false;
  @Prop short: boolean = false;
  select: (index: number) => void = () => {};
  @State private hovered: number = -1;
  @State private pressed: number = -1;

  build() {
    if (this.mode === 'bottom') {
      Row({ space: 4 }) {
        ForEach(LABELS, (label: string, index: number) => {
          this.BottomNavigationItem(index)
        })
      }
      .width('100%')
      .height(68)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .backgroundColor(this.surface())
    } else {
      Scroll() {
      Column({ space: 8 }) {
        if (!this.short) {
          Row({ space: 10 }) {
            Image($rawfile('app/ui/chicken.svg'))
              .width(38).height(38).objectFit(ImageFit.Contain)
              .accessibilityLevel('no')
            if (this.mode === 'sidebar') {
              Column({ space: 3 }) {
                Text('鸡窝游戏').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.ink())
                Text('随时来一局').fontSize(11).fontColor(this.muted())
              }.alignItems(HorizontalAlign.Start)
            }
          }
          .width('100%')
          .justifyContent(this.mode === 'sidebar' ? FlexAlign.Start : FlexAlign.Center)
          .padding({ top: 12, bottom: 28 })
        }
        ForEach(LABELS, (label: string, index: number) => {
          this.NavigationItem(index)
        })
        if (this.mode === 'sidebar') {
          Text('没网也能玩一窝')
            .fontSize(11).fontColor(this.muted())
            .padding({ bottom: 16 })
        }
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: this.short ? 8 : 16, bottom: 12 })
      }
      .width(this.mode === 'sidebar' ? 184 : 80)
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .border({ width: { right: 1 }, color: this.line() })
      .backgroundColor(this.surface())
    }
  }

  @Builder
  BottomNavigationItem(index: number) {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Column({ space: 4 }) {
        Stack() {
          // Preserve the hand-drawn outlines; fillColor would turn these into solid shapes.
          Image($rawfile(this.dark ? `app/home/nav_${ICONS[index]}_dark.svg` : `app/ui/icons/${ICONS[index]}.svg`))
            .width(22).height(22).objectFit(ImageFit.Contain)
            .opacity(this.activeTab === index ? 1 : 0.76)
            .draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
        }
        .width(48).height(30).borderRadius(15)
        .backgroundColor(this.activeTab === index ? (this.dark ? '#4E3921' : '#F8DFA9') :
          (this.hovered === index || this.pressed === index ? (this.dark ? '#2B261F' : '#FFF0D7') : Color.Transparent))
        .scale({ x: this.pressed === index ? 0.94 : 1, y: this.pressed === index ? 0.94 : 1 })
        .animation({ duration: 120, curve: Curve.EaseOut })
        Text(LABELS[index]).fontSize(11)
          .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.tint(index)).maxLines(1)
      }.width('100%').height('100%').justifyContent(FlexAlign.Center)
    }
    .layoutWeight(1).height(60).padding(0).borderRadius(16)
    .backgroundColor(Color.Transparent)
    .accessibilityText(`${LABELS[index]}，${this.activeTab === index ? '已选择' : '未选择'}`)
    .onTouch((event: TouchEvent) => {
      this.pressed = event.type === TouchType.Down ? index : -1;
    })
    .onHover((hovered: boolean) => { this.hovered = hovered ? index : -1; })
    .onClick(() => this.select(index))
  }

  @Builder
  NavigationItem(index: number) {
    Button({ type: ButtonType.Normal }) {
      if (this.mode === 'sidebar') {
        Row({ space: 13 }) {
          AppIcon({ name: ICONS[index], iconSize: 23, tint: this.tint(index) })
          Text(LABELS[index]).fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.tint(index))
          Blank()
          if (this.activeTab === index) {
            Circle().width(5).height(5).fill(this.tint(index))
          }
        }.width('100%').padding({ left: 13, right: 12 })
      } else {
        Column({ space: 3 }) {
          AppIcon({ name: ICONS[index], iconSize: 23, tint: this.tint(index) })
          Text(LABELS[index]).fontSize(11).fontWeight(FontWeight.Medium).fontColor(this.tint(index))
        }
      }
    }
    .layoutWeight(this.mode === 'bottom' ? 1 : 0)
    .width(this.mode === 'bottom' ? undefined : '100%')
    .height(this.mode === 'sidebar' ? 50 : 56)
    .padding(0)
    .borderRadius(16)
    .backgroundColor(this.activeTab === index ? (this.dark ? '#493820' : '#FBE7BF') :
      (this.hovered === index ? (this.dark ? '#2B261F' : '#FFF0D7') : Color.Transparent))
    .accessibilityText(`${LABELS[index]}，${this.activeTab === index ? '已选择' : '未选择'}`)
    .onHover((hovered: boolean) => { this.hovered = hovered ? index : -1; })
    .onClick(() => this.select(index))
  }

  private tint(index: number): string {
    return this.activeTab === index ? (this.dark ? '#FFD083' : '#86541D') : this.muted();
  }
  private ink(): string { return this.dark ? '#FFF2DF' : '#39291E'; }
  private muted(): string { return this.dark ? '#B6A48D' : '#806E5C'; }
  private surface(): string { return hubNavigationSurface(this.dark); }
  private line(): string { return this.dark ? '#342E25' : '#EDE0CC'; }
}
