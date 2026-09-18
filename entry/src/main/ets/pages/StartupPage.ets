// Shown only while local preferences are being restored; no minimum display time.
@Component
export struct StartupPage {
  @State private pageWidth: number = 360;
  @State private pageHeight: number = 720;

  private compactLandscape(): boolean {
    return this.pageHeight < 420 && this.pageWidth > this.pageHeight;
  }

  private markSize(): number {
    if (this.compactLandscape()) {
      return Math.min(156, this.pageHeight * 0.55, this.pageWidth * 0.32);
    }
    return Math.min(this.pageWidth >= 600 ? 208 : 176, this.pageWidth - 48, this.pageHeight * 0.32);
  }

  @Builder
  private brandMark() {
    Image($r('app.media.start_icon'))
      .width(this.markSize())
      .height(this.markSize())
      .objectFit(ImageFit.Contain)
      .accessibilityLevel('no')
  }

  @Builder
  private brandName() {
    Column({ space: 12 }) {
      Text($r('app.string.app_name'))
        .fontSize(this.pageWidth >= 600 && !this.compactLandscape() ? 32 : 28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.start_brand_ink'))
        .letterSpacing(3)
        .textAlign(TextAlign.Center)
      Row({ space: 6 }) {
        Rect().width(18).height(3).radius(2)
          .fill($r('app.color.start_brand_accent'))
        Circle().width(4).height(4)
          .fill($r('app.color.start_brand_accent'))
        Rect().width(18).height(3).radius(2)
          .fill($r('app.color.start_brand_accent'))
      }
      .accessibilityLevel('no')
      Text('休息一下，玩一会儿')
        .fontSize(14)
        .fontColor($r('app.color.start_brand_caption'))
        .lineHeight(22)
        .textAlign(TextAlign.Center)
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.compactLandscape()) {
        Row({ space: 28 }) {
          this.brandMark()
          this.brandName()
        }
      } else {
        Column({ space: 14 }) {
          this.brandMark()
          this.brandName()
        }
        .translate({ y: -16 })
      }
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .backgroundColor($r('app.color.start_window_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      this.pageWidth = Number(newArea.width);
      this.pageHeight = Number(newArea.height);
    })
  }
}
