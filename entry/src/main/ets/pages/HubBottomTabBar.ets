import { CoopMotion } from '../design/CoopMotion';
import { CoopTheme } from '../design/CoopTheme';

const TAB_BAR_HEIGHT: number = 96;
const TAB_BAR_SIDE_PADDING: number = 20;
const TAB_BAR_TOP_PADDING: number = 10;
const TAB_BAR_BOTTOM_PADDING: number = 24;
const TAB_ITEM_RADIUS: number = 14;
const TAB_ICON_SIZE: number = 26;
const TAB_SYMBOL_SIZE: number = 23;
const TAB_LABEL_HEIGHT: number = 16;

@Component
export struct HubBottomTabBar {
  @Prop activeTab: number = 0;
  @Prop isDarkMode: boolean = false;
  onTabSelected: (index: number) => void = () => {};
  @State private pressedTab: number = -1;

  build() {
    Row() {
      this.TabItem(0, $r('sys.symbol.house'), '首页')
      this.TabItem(1, $r('sys.symbol.heart'), '收藏')
      this.TabItem(2, $r('sys.symbol.star'), '成就')
      this.TabItem(3, $r('sys.symbol.more'), '设置')
    }
    .width('100%')
    .height(TAB_BAR_HEIGHT)
    .padding({
      left: TAB_BAR_SIDE_PADDING,
      right: TAB_BAR_SIDE_PADDING,
      top: TAB_BAR_TOP_PADDING,
      bottom: TAB_BAR_BOTTOM_PADDING
    })
    .backgroundColor(this.tabBarSurfaceColor())
    .border({ width: { top: 1 }, color: this.lineColor() })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  TabItem(index: number, icon: Resource, label: string) {
    Column({ space: 3 }) {
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph(icon)
          .fontSize(TAB_SYMBOL_SIZE)
          .fontColor([this.activeTab === index ? this.activeIconColor() : this.mutedColor()])
      }
      .width(TAB_ICON_SIZE)
      .height(TAB_ICON_SIZE)
      Text(label)
        .height(TAB_LABEL_HEIGHT)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.activeTab === index ? this.activeLabelColor() : this.mutedColor())
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .borderRadius(TAB_ITEM_RADIUS)
    .backgroundColor('rgba(255,255,255,0.00)')
    .scale({
      x: this.pressedTab === index ? CoopMotion.pressScale : 1,
      y: this.pressedTab === index ? CoopMotion.pressScale : 1
    })
    .opacity(this.pressedTab === index ? 0.96 : 1)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.setPressedTab(index);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.setPressedTab(-1);
      }
    })
    .onClick(() => {
      this.onTabSelected(index);
    })
  }

  private setPressedTab(index: number): void {
    if (this.pressedTab === index) {
      return;
    }
    this.getUIContext().animateTo({
      duration: CoopMotion.pressDuration,
      curve: Curve.EaseOut
    }, () => {
      this.pressedTab = index;
    });
  }

  private tabBarSurfaceColor(): string {
    return this.isDarkMode ? '#101110' : CoopTheme.appSurface;
  }

  private mutedColor(): string {
    return this.isDarkMode ? '#a99a88' : CoopTheme.muted;
  }

  private activeIconColor(): string {
    return this.isDarkMode ? '#ffd083' : '#f4a51f';
  }

  private activeLabelColor(): string {
    return this.isDarkMode ? '#f7dfbd' : '#5b3d25';
  }

  private lineColor(): string {
    return this.isDarkMode ? 'rgba(255,236,205,0.16)' : 'rgba(132,91,45,0.14)';
  }
}
