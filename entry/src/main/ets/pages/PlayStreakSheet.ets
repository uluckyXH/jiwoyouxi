import { currentPlayStreak, localPlayDay, PlayDayView, recentPlayWeek } from '../design/PlayActivity';

@Component
export struct PlayStreakSheet {
  @Prop days: number[] = [];
  @Prop dark: boolean = false;
  @State private now: number = Date.now();
  @State private hop: number = 0;
  @State private tilt: number = 0;
  @State private sparkle: number = 0;
  private alive: boolean = false;
  private dancing: boolean = false;
  private animationRevision: number = 0;
  private entranceTimer: number = -1;

  aboutToAppear(): void {
    this.alive = true;
    this.dancing = false;
    this.hop = 0;
    this.tilt = 0;
    this.sparkle = 0;
    this.now = Date.now();
    this.entranceTimer = setTimeout(() => this.celebrate(), 80);
  }

  aboutToDisappear(): void {
    this.alive = false;
    this.animationRevision += 1;
    if (this.entranceTimer >= 0) clearTimeout(this.entranceTimer);
  }

  build() {
    Column({ space: 16 }) {
      Text('鸡窝里的小日常').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.ink())
      Button({ type: ButtonType.Normal, stateEffect: false }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(126).height(126).fill(this.dark ? '#34392A' : '#EDF0DA')
          Text('✦').fontSize(24).fontColor('#D8A346').position({ x: 8, y: 20 })
            .opacity(this.sparkle).scale({ x: 0.7 + this.sparkle * 0.4, y: 0.7 + this.sparkle * 0.4 })
          Text('✦').fontSize(16).fontColor('#D8A346').position({ x: 134, y: 38 })
            .opacity(this.sparkle)
          Image($rawfile('app/ui/chicken.svg')).width(94).height(94).objectFit(ImageFit.Contain)
            .translate({ y: this.hop }).rotate({ angle: this.tilt })
          Image($rawfile('app/ui/streak.svg')).width(36).height(36).objectFit(ImageFit.Contain)
            .position({ x: 112, y: 101 }).scale({ x: 1 + this.sparkle * 0.15, y: 1 + this.sparkle * 0.15 })
        }.width(164).height(152)
      }.padding(0).backgroundColor(Color.Transparent)
      .accessibilityText('点点小鸡，重播庆祝动画')
      .onClick(() => this.celebrate())
      Column({ space: 6 }) {
        Row({ space: 6 }) {
          Text(`${currentPlayStreak(this.days, this.now)}`).fontSize(44).fontWeight(FontWeight.Bold).fontColor(this.ink())
          Text('天').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.ink()).margin({ top: 16 })
        }
        Text('连续游玩').fontSize(13).fontColor(this.muted())
      }
      Text(this.encouragement()).fontSize(14).lineHeight(22).fontColor(this.muted()).textAlign(TextAlign.Center)
      Row({ space: 4 }) {
        ForEach(recentPlayWeek(this.days, this.now), (day: PlayDayView) => {
          Column({ space: 8 }) {
            Stack() {
              Circle().width(28).height(28).fill(day.played ? (this.dark ? '#786038' : '#FFE1A1') :
                (this.dark ? '#343027' : '#EFE7DA'))
              if (day.played) {
                Image($rawfile('app/ui/streak.svg')).width(21).height(21).objectFit(ImageFit.Contain)
              } else {
                Circle().width(5).height(5).fill(this.muted()).opacity(0.45)
              }
            }
            Text(day.label).fontSize(10).fontColor(day.today ? this.ink() : this.muted())
              .fontWeight(day.today ? FontWeight.Bold : FontWeight.Normal)
          }.layoutWeight(1)
          .accessibilityGroup(true).accessibilityText(`${day.label}，${day.played ? '已游玩' : '未游玩'}`)
        }, (day: PlayDayView) => `${day.day}:${day.played}`)
      }.width('100%').constraintSize({ maxWidth: 420 }).padding({ top: 8, bottom: 8 })
      Text('每天玩一会儿，留下一个小脚印。\n点点小鸡，还会再开心一下。')
        .fontSize(12).lineHeight(20).fontColor(this.muted()).textAlign(TextAlign.Center)
    }.width('100%').padding({ left: 24, right: 24, top: 24, bottom: 32 })
    .backgroundColor(this.dark ? '#211F1B' : '#FFFAF2')
  }

  private celebrate(): void {
    if (!this.alive || this.dancing) return;
    this.now = Date.now();
    this.dancing = true;
    const revision = ++this.animationRevision;
    this.getUIContext().animateTo({ duration: 220, curve: Curve.EaseOut, onFinish: () => {
      if (!this.alive || revision !== this.animationRevision) return;
      this.getUIContext().animateTo({ duration: 320, curve: Curve.EaseInOut, onFinish: () => {
        if (this.alive && revision === this.animationRevision) this.dancing = false;
      } }, () => { this.hop = 0; this.tilt = 0; this.sparkle = 0; });
    } }, () => { this.hop = -14; this.tilt = -8; this.sparkle = 1; });
  }

  private encouragement(): string {
    if (this.days.includes(localPlayDay(this.now))) return '今天的小火苗已经点亮，开心就好！';
    return currentPlayStreak(this.days, this.now) > 0 ? '昨天的快乐还在，今天也来玩一会儿吧。' : '从今天开始，攒一点属于自己的小快乐。';
  }
  private ink(): string { return this.dark ? '#FFF2DF' : '#39291E'; }
  private muted(): string { return this.dark ? '#C8B7A2' : '#806A54'; }
}
