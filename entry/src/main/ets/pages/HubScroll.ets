import { HubSession } from '../design/HubSession';

@Component
export struct HubScroll {
  @ObjectLink session: HubSession;
  @Prop slot: number = 0;
  @BuilderParam content: () => void = this.Empty;
  private scroller: Scroller = new Scroller();

  build() {
    Scroll(this.scroller) {
      Column() {
        this.content()
      }
      .width('100%')
      .padding({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .initialOffset({ yOffset: this.session.scrollOffsets[this.slot] })
    .onDidScroll(() => {
      this.session.scrollOffsets[this.slot] = this.scroller.currentOffset().yOffset;
    })
  }

  @Builder
  Empty() {}
}
