import { CoopMotion } from '../../design/CoopMotion';
import { MEMORY_PICTURES } from './MemoryModel';
import { MemoryPalette as P } from './MemoryPalette';

@Component
export struct MemoryCard {
  @Prop dark: boolean = false;
  @Prop slot: number = 0;
  @Prop picture: number = 0;
  @Prop widthVp: number = 70;
  @Prop heightVp: number = 78;
  @Prop @Watch('turn') isOpen: boolean = false;
  @Prop @Watch('celebrate') matched: boolean = false;
  @Prop active: boolean = true;
  @Prop deal: boolean = true;
  @State faceUp: boolean = false;
  @State angle: number = 0;
  @State arrived: boolean = false;
  @State pulse: number = 1;
  private epoch: number = 0;
  private alive: boolean = false;
  action: () => void = () => {};

  aboutToAppear(): void {
    this.alive = true;
    this.faceUp = this.isOpen;
    this.angle = 0;
    this.arrived = !this.deal;
  }
  aboutToDisappear(): void { this.alive = false; this.epoch += 1; }
  private enter(): void {
    if (this.arrived) { return; }
    this.getUIContext().animateTo({ duration: CoopMotion.scenePushDuration, delay: this.slot * 13,
      curve: Curve.EaseOut }, () => { this.arrived = true; });
  }
  turn(): void {
    if (!this.alive) { return; }
    const token = ++this.epoch;
    // Only the artwork changes at the midpoint; the rules have already committed the flip.
    this.getUIContext().animateTo({ duration: CoopMotion.microDuration, curve: Curve.EaseIn,
      onFinish: () => {
        if (!this.alive || token !== this.epoch) { return; }
        this.faceUp = this.isOpen;
        this.angle = -90;
        this.getUIContext().animateTo({ duration: CoopMotion.tabDuration, curve: Curve.EaseOut },
          () => { this.angle = 0; });
      }
    }, () => { this.angle = 90; });
  }
  celebrate(): void {
    if (!this.alive || !this.matched) { return; }
    this.getUIContext().animateTo({ duration: 170, delay: 160, curve: Curve.EaseOut,
      onFinish: () => {
        if (this.alive) {
          this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut }, () => { this.pulse = 1; });
        }
      }
    }, () => { this.pulse = 1.055; });
  }
  private label(): string {
    const position = '第 ' + (Math.floor(this.slot / 4) + 1) + ' 行，第 ' + (this.slot % 4 + 1) + ' 张，';
    return position + (this.isOpen ? MEMORY_PICTURES[this.picture] + (this.matched ? '，已配对' : '，已翻开') : '未翻开');
  }
  build() {
    Button({ type: ButtonType.Normal }) {
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.faceUp) {
          Column({ space: 0 }) {
            Image($rawfile(P.picture(this.picture, this.dark))).width(this.widthVp * .8).height(this.widthVp * .8)
              .objectFit(ImageFit.Contain).draggable(false).accessibilityLevel('no')
            if (this.widthVp >= 58) {
              Text(MEMORY_PICTURES[this.picture]).fontSize(Math.min(12, this.widthVp * .135))
                .fontColor(P.muted(this.dark)).maxLines(1)
            }
          }.width('100%').height('100%').justifyContent(FlexAlign.Center)
          if (this.matched) {
            Image($rawfile(P.icon('check', this.dark, 'accent'))).width(13).height(13)
              .position({ x: this.widthVp - 17, y: 4 }).accessibilityLevel('no')
          }
        } else {
          Image($rawfile(P.scene('back', this.dark))).width('100%').height('100%')
            .objectFit(ImageFit.Fill).draggable(false).accessibilityLevel('no')
        }
      }.width('100%').height('100%').backgroundColor(P.paper(this.dark))
      .borderRadius(Math.min(18, this.widthVp * .2))
      .border({ width: this.faceUp ? 1.3 : 0,
        color: this.matched ? P.accent(this.dark) : P.line(this.dark), radius: Math.min(18, this.widthVp * .2) })
    }.width(this.widthVp).height(this.heightVp).padding(0).borderRadius(Math.min(18, this.widthVp * .2))
    .backgroundColor(Color.Transparent)
    .rotate({ x: 0, y: 1, z: 0, angle: this.angle, perspective: 600 })
    .scale({ x: (this.arrived ? 1 : .87) * this.pulse, y: (this.arrived ? 1 : .87) * this.pulse })
    .translate({ y: this.arrived ? 0 : 12 }).opacity(this.arrived ? (this.matched ? .73 : 1) : 0)
    .shadow({ radius: this.matched ? 0 : 2, color: this.dark ? '#19101813' : '#183C5736', offsetY: 2 })
    .enabled(this.active && !this.matched).accessibilityText(this.label())
    .accessibilityDescription(this.isOpen ? '' : '点击翻开这张牌')
    .onClick(this.action).onAppear(() => this.enter())
  }
}
