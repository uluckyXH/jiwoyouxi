import { ArenaPalette as P } from './ArenaPalette';

/** Short menus fit their content; a small window can still scroll every action into view. */
@Component
export struct ArenaDialogFrame {
  @Prop dark: boolean = false;
  @Prop availableWidth: number = 390;
  @Prop availableHeight: number = 804;
  @Prop paneX: number = 0;
  @Prop paneY: number = 0;
  @Prop estimatedHeight: number = 480;
  @Prop @Watch('resetScroll') contentKey: string = '';
  @BuilderParam content: () => void = this.Empty;
  @State private contentHeight: number = 0;
  private scroller: Scroller = new Scroller();

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Row().width('100%').height('100%')
        .backgroundColor(this.dark ? 'rgba(0,0,0,0.42)' : 'rgba(57,41,30,0.18)')
        .accessibilityLevel('no')
        .onClick(() => {})
      Scroll(this.scroller) {
        Column() {
          this.content()
        }
        .width('100%')
        .onAreaChange((oldArea: Area, area: Area) => {
          const height = Math.ceil(Number(area.height)) + 2;
          if (Number.isFinite(height) && height > 2 && height !== this.contentHeight) {
            this.contentHeight = height;
          }
        })
      }
      .width(Math.max(1, Math.min(400, this.availableWidth - 24)))
      .height(Math.max(1, Math.min(this.availableHeight - 24,
        this.contentHeight > 0 ? this.contentHeight : this.estimatedHeight)))
      .scrollBar(BarState.Off)
      .backgroundColor(P.surface(this.dark))
      .border({ width: 1, radius: 24, color: P.line(this.dark) })
      .borderRadius(24).clip(true)
      .shadow({ radius: 20, offsetY: 8, color: this.dark ? 'rgba(0,0,0,0.30)' : 'rgba(57,41,30,0.14)' })
    }.width(this.availableWidth).height(this.availableHeight)
      .position({ x: this.paneX, y: this.paneY })
  }

  private resetScroll(): void {
    this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
  }

  @Builder
  Empty() {}
}
