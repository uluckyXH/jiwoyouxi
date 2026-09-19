import { StarMode, starModeTitle } from './StarModel';
import { StarPalette as P } from './StarPalette';

@Component
export struct StarIconButton {
  @Prop dark: boolean = false;
  @Prop icon: string = 'back';
  @Prop label: string = '';
  @Prop active: boolean = true;
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Circle }) {
      Image($rawfile(P.icon(this.icon, this.dark))).width(21).height(21).accessibilityLevel('no')
    }.width(44).height(44).padding(0).backgroundColor(P.paper(this.dark))
    .border({ width: 1, color: P.line(this.dark), radius: 22 }).borderRadius(22).clip(true)
    .enabled(this.active).opacity(this.active ? 1 : .45).accessibilityText(this.label).onClick(this.action)
  }
}

@Component
export struct StarButton {
  @Prop dark: boolean = false;
  @Prop label: string = '';
  @Prop icon: string = '';
  @Prop primary: boolean = false;
  @Prop active: boolean = true;
  @Prop controlHeight: number = 50;
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Capsule }) {
      Row({ space: 6 }) {
        if (this.icon.length > 0) {
          Image($rawfile(P.icon(this.icon, this.dark, this.primary ? 'on' : 'accent')))
            .width(20).height(20).accessibilityLevel('no')
        }
        Text(this.label).fontSize(14).minFontSize(11).maxFontSize(14).maxLines(1)
          .fontWeight(FontWeight.Medium).fontColor(this.primary ? P.onAccent(this.dark) : P.ink(this.dark))
      }.width('100%').justifyContent(FlexAlign.Center)
    }.width('100%').height(this.controlHeight).padding({ left: 8, right: 8 })
    .backgroundColor(this.primary ? P.accent(this.dark) : P.paper(this.dark))
    .border({ width: 1, color: this.primary ? P.accent(this.dark) : P.line(this.dark), radius: this.controlHeight / 2 })
    .borderRadius(this.controlHeight / 2).clip(true).enabled(this.active).opacity(this.active ? 1 : .42)
    .accessibilityText(this.label).onClick(this.action)
  }
}

@Component
export struct StarStats {
  @Prop dark: boolean = false;
  @Prop mode: StarMode = 'easy';
  @Prop score: number = 0;
  @Prop stageScore: number = 0;
  @Prop target: number = 1000;
  @Prop best: number = 0;
  @Prop stage: number = 1;
  @Prop panelHeight: number = 100;
  build() {
    Column({ space: 7 }) {
      Row({ space: 12 }) {
        Column({ space: 1 }) {
          Text('旅程得分').fontSize(10).fontColor(P.muted(this.dark))
          Text('' + this.score).fontSize(29).minFontSize(19).maxFontSize(29).maxLines(1)
            .fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).width('100%')
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Column({ space: 5 }) {
          Text('第 ' + this.stage + ' 关').fontSize(13).fontWeight(FontWeight.Medium).fontColor(P.accent(this.dark))
            .padding({ left: 11, right: 11, top: 4, bottom: 4 }).backgroundColor(P.soft(this.dark)).borderRadius(12)
          Text(starModeTitle(this.mode)).fontSize(10).fontColor(P.muted(this.dark))
        }.alignItems(HorizontalAlign.End)
      }.width('100%')
      Column({ space: 4 }) {
        Row() {
          Text('本关 ' + this.stageScore + ' / ' + this.target).fontSize(10).fontColor(P.muted(this.dark)).layoutWeight(1)
          Image($rawfile(P.icon('trophy', this.dark, 'accent'))).width(11).height(11).margin({ right: 3 }).accessibilityLevel('no')
          Text('' + this.best).fontSize(10).fontColor(P.muted(this.dark))
        }.width('100%')
        Progress({ value: Math.min(100, this.stageScore / this.target * 100), total: 100, type: ProgressType.Linear })
          .width('100%').color(P.accent(this.dark)).backgroundColor(P.soft(this.dark))
          .style({ strokeWidth: 4, enableSmoothEffect: false })
      }.width('100%')
    }.width('100%').height(this.panelHeight).padding({ left: 17, right: 17, top: 11, bottom: 11 })
    .justifyContent(FlexAlign.Center).backgroundColor(P.paper(this.dark))
    .border({ width: 1, color: P.line(this.dark), radius: 24 }).borderRadius(24)
  }
}
