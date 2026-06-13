interface FeatherParticle {
  index: number;
  image: string;
  size: number;
  startXRatio: number;
  startYRatio: number;
  endX: number;
  endY: number;
  startAngle: number;
  endAngle: number;
  delay: number;
  duration: number;
  opacity: number;
}

const FAILURE_FEATHERS: FeatherParticle[] = [
  { index: 0, image: 'games/minesweeper/feather_01.png', size: 42, startXRatio: 0.18, startYRatio: 0.18, endX: -42, endY: 150, startAngle: -18, endAngle: 24, delay: 0, duration: 920, opacity: 0.92 },
  { index: 1, image: 'games/minesweeper/feather_02.png', size: 48, startXRatio: 0.35, startYRatio: 0.14, endX: 32, endY: 190, startAngle: 12, endAngle: -32, delay: 80, duration: 1160, opacity: 0.86 },
  { index: 2, image: 'games/minesweeper/feather_03.png', size: 38, startXRatio: 0.55, startYRatio: 0.16, endX: -28, endY: 180, startAngle: 22, endAngle: 48, delay: 50, duration: 1080, opacity: 0.88 },
  { index: 3, image: 'games/minesweeper/feather_04.png', size: 44, startXRatio: 0.74, startYRatio: 0.20, endX: 44, endY: 155, startAngle: -8, endAngle: -42, delay: 130, duration: 980, opacity: 0.84 },
  { index: 4, image: 'games/minesweeper/feather_05.png', size: 36, startXRatio: 0.24, startYRatio: 0.36, endX: 64, endY: 170, startAngle: 36, endAngle: 8, delay: 180, duration: 1250, opacity: 0.78 },
  { index: 5, image: 'games/minesweeper/feather_06.png', size: 46, startXRatio: 0.45, startYRatio: 0.33, endX: -58, endY: 190, startAngle: -24, endAngle: 32, delay: 220, duration: 1320, opacity: 0.82 },
  { index: 6, image: 'games/minesweeper/feather_07.png', size: 34, startXRatio: 0.66, startYRatio: 0.35, endX: 52, endY: 165, startAngle: 8, endAngle: -26, delay: 260, duration: 1110, opacity: 0.76 },
  { index: 7, image: 'games/minesweeper/feather_08.png', size: 50, startXRatio: 0.82, startYRatio: 0.38, endX: -52, endY: 175, startAngle: -34, endAngle: 18, delay: 310, duration: 1220, opacity: 0.74 },
  { index: 8, image: 'games/minesweeper/feather_09.png', size: 45, startXRatio: 0.16, startYRatio: 0.58, endX: 42, endY: 135, startAngle: 14, endAngle: -38, delay: 360, duration: 1020, opacity: 0.70 },
  { index: 9, image: 'games/minesweeper/feather_10.png', size: 40, startXRatio: 0.50, startYRatio: 0.56, endX: -36, endY: 145, startAngle: -12, endAngle: 30, delay: 410, duration: 1060, opacity: 0.68 },
  { index: 10, image: 'games/minesweeper/feather_03.png', size: 32, startXRatio: 0.77, startYRatio: 0.60, endX: 38, endY: 120, startAngle: 20, endAngle: 54, delay: 460, duration: 980, opacity: 0.66 },
  { index: 11, image: 'games/minesweeper/feather_01.png', size: 30, startXRatio: 0.36, startYRatio: 0.66, endX: -44, endY: 116, startAngle: -30, endAngle: -2, delay: 510, duration: 940, opacity: 0.64 }
];

const SUCCESS_FEATHERS: FeatherParticle[] = [
  { index: 0, image: 'games/minesweeper/feather_01.png', size: 34, startXRatio: 0.18, startYRatio: 0.18, endX: 28, endY: 120, startAngle: -10, endAngle: 22, delay: 80, duration: 1450, opacity: 0.48 },
  { index: 1, image: 'games/minesweeper/feather_04.png', size: 36, startXRatio: 0.42, startYRatio: 0.12, endX: -34, endY: 148, startAngle: 12, endAngle: -18, delay: 220, duration: 1550, opacity: 0.42 },
  { index: 2, image: 'games/minesweeper/feather_07.png', size: 30, startXRatio: 0.68, startYRatio: 0.16, endX: 34, endY: 132, startAngle: -18, endAngle: 18, delay: 340, duration: 1420, opacity: 0.40 },
  { index: 3, image: 'games/minesweeper/feather_10.png', size: 32, startXRatio: 0.82, startYRatio: 0.26, endX: -28, endY: 126, startAngle: 8, endAngle: -24, delay: 480, duration: 1500, opacity: 0.36 }
];

@Component
export struct SuikaFeatherLayer {
  @Prop success: boolean = false;
  @Prop pageWidth: number = 390;
  @Prop pageHeight: number = 760;
  @State active: boolean = false;
  @State visible: boolean = true;

  aboutToAppear(): void {
    this.active = false;
    this.visible = true;
    setTimeout(() => {
      this.active = true;
    }, 40);
    setTimeout(() => {
      this.visible = false;
    }, this.success ? 2100 : 1700);
  }

  build() {
    Stack() {
      if (this.visible) {
        ForEach(this.items(), (item: FeatherParticle) => {
          Image($rawfile(item.image))
            .width(item.size)
            .height(item.size)
            .objectFit(ImageFit.Contain)
            .opacity(this.active ? 0 : item.opacity)
            .rotate({ angle: this.active ? item.endAngle : item.startAngle })
            .translate({ x: this.active ? item.endX : 0, y: this.active ? item.endY : 0 })
            .position({ x: this.startX(item), y: this.startY(item) })
            .animation({
              duration: item.duration,
              curve: Curve.EaseOut,
              delay: item.delay
            })
        }, (item: FeatherParticle) => `${item.index}-${item.image}`)
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }

  private items(): FeatherParticle[] {
    return this.success ? SUCCESS_FEATHERS : FAILURE_FEATHERS;
  }

  private startX(item: FeatherParticle): number {
    return Math.round(this.pageWidth * item.startXRatio - item.size * 0.5);
  }

  private startY(item: FeatherParticle): number {
    return Math.round(this.pageHeight * item.startYRatio - item.size * 0.5);
  }
}
