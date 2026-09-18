import { GlowPalette as P } from './GlowPalette';
import { GlowDirection } from './GlowModel';

@Component
export struct GlowIconButton {
  @Prop dark: boolean = false;
  @Prop icon: string = 'help';
  @Prop label: string = '';
  @Prop primary: boolean = false;
  @Prop active: boolean = true;
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Circle }) {
      Image($rawfile(P.icon(this.icon, this.dark, this.primary ? 'on' : 'ink')))
        .width(21).height(21).draggable(false).accessibilityLevel('no')
    }.width(44).height(44).padding(0)
    .backgroundColor(this.primary ? P.accent(this.dark) : P.paper(this.dark))
    .border({ width: 1, color: this.primary ? P.accent(this.dark) : P.line(this.dark) })
    .enabled(this.active).opacity(this.active ? 1 : .45).accessibilityText(this.label).onClick(this.action)
  }
}

@Component
export struct GlowActionButton {
  @Prop dark: boolean = false;
  @Prop icon: string = 'play';
  @Prop label: string = '';
  @Prop primary: boolean = true;
  @Prop active: boolean = true;
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 8 }) {
        Image($rawfile(P.icon(this.icon, this.dark, this.primary ? 'on' : 'accent')))
          .width(19).height(19).accessibilityLevel('no')
        Text(this.label).fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor(this.primary ? P.onAccent(this.dark) : P.ink(this.dark))
      }.width('100%').justifyContent(FlexAlign.Center)
    }.width('100%').height(48).borderRadius(16).padding(0)
    .backgroundColor(this.primary ? P.accent(this.dark) : P.soft(this.dark))
    .enabled(this.active).opacity(this.active ? 1 : .45).defaultFocus(this.primary).onClick(this.action)
  }
}

@Component
struct GlowStatValue {
  @Prop dark: boolean = false;
  @Prop icon: string = 'spark';
  @Prop label: string = '';
  @Prop value: number = 0;
  build() {
    Column({ space: 5 }) {
      Row({ space: 4 }) {
        Image($rawfile(P.icon(this.icon, this.dark, 'accent'))).width(13).height(13).accessibilityLevel('no')
        Text(this.label).fontSize(10).fontColor(P.muted(this.dark))
      }
      Text(`${this.value}`).fontSize(24).minFontSize(12).maxFontSize(24).maxLines(1)
        .fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).fontFamily('monospace')
        .width('100%').height(29).textAlign(TextAlign.Center)
    }.width('100%')
  }
}

@Component
export struct GlowStats {
  @Prop dark: boolean = false;
  @Prop score: number = 0;
  @Prop best: number = 0;
  @Prop moves: number = 0;
  @Prop gain: number = 0;
  @Prop turn: number = 0;
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Row() {
        GlowStatValue({ dark: this.dark, icon: 'spark', label: '本局得分', value: this.score }).layoutWeight(1)
        Divider().vertical(true).height(24).color(P.line(this.dark))
        GlowStatValue({ dark: this.dark, icon: 'trophy', label: '最高得分', value: Math.max(this.score, this.best) }).layoutWeight(1)
        Divider().vertical(true).height(24).color(P.line(this.dark))
        GlowStatValue({ dark: this.dark, icon: 'steps', label: '有效步数', value: this.moves }).layoutWeight(1)
      }.width('100%').height(78).padding(12).borderRadius(22)
      .backgroundColor(P.paper(this.dark)).border({ width: 1, color: P.line(this.dark) })
      if (this.gain > 0) {
        ForEach([this.turn], (turn: number) => {
          GlowScoreFloat({ dark: this.dark, gain: this.gain }).position({ x: 22, y: 30 })
        }, (turn: number) => `${turn}`)
      }
    }.width('100%').height(78)
  }
}

@Component
struct GlowScoreFloat {
  @Prop dark: boolean = false;
  @Prop gain: number = 0;
  @State lifted: boolean = false;
  private enter(): void {
    this.getUIContext().animateTo({ duration: 650, curve: Curve.EaseOut }, () => { this.lifted = true; });
  }
  build() {
    Text(`+${this.gain}`).fontSize(15).fontWeight(FontWeight.Bold).fontColor(P.gold(this.dark))
      .translate({ y: this.lifted ? -30 : 0 }).opacity(this.lifted ? 0 : 1)
      .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      .onAppear(() => this.enter())
  }
}

@Component
struct GlowDirectionButton {
  @Prop dark: boolean = false;
  @Prop heading: GlowDirection = 'up';
  @Prop label: string = '';
  @Prop active: boolean = true;
  move: (direction: GlowDirection) => void = () => {};
  build() {
    Button({ type: ButtonType.Normal }) {
      Image($rawfile(P.icon(this.heading, this.dark, 'accent')))
        .width(29).height(29).draggable(false).accessibilityLevel('no')
    }.width(60).height(60).padding(0).borderRadius(20)
    .backgroundColor(P.paper(this.dark)).border({ width: 1.5, color: P.line(this.dark) })
    .shadow({ radius: 4, offsetY: 3, color: this.dark ? '#38000000' : '#1C777D54' })
    .enabled(this.active).opacity(this.active ? 1 : .45).accessibilityText(this.label)
    .onClick(() => this.move(this.heading))
  }
}

@Component
export struct GlowUtilityButton {
  @Prop dark: boolean = false;
  @Prop icon: string = 'help';
  @Prop label: string = '';
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Normal }) {
      Column({ space: 7 }) {
        Image($rawfile(P.icon(this.icon, this.dark, 'accent'))).width(24).height(24).accessibilityLevel('no')
        Text(this.label).fontSize(11).maxLines(1).fontColor(P.ink(this.dark))
      }.width('100%')
    }.width('100%').height(76).padding(4).borderRadius(20)
    .backgroundColor(P.paper(this.dark)).border({ width: 1, color: P.line(this.dark) })
    .accessibilityText(this.label).onClick(this.action)
  }
}

@Component
export struct GlowDirectionPad {
  @Prop dark: boolean = false;
  @Prop active: boolean = true;
  move: (direction: GlowDirection) => void = () => {};
  build() {
    Column({ space: 4 }) {
      GlowDirectionButton({ dark: this.dark, heading: 'up', label: '向上移动', active: this.active, move: this.move })
      Row({ space: 4 }) {
        GlowDirectionButton({ dark: this.dark, heading: 'left', label: '向左移动', active: this.active, move: this.move })
        Image($rawfile(P.scene('compass', this.dark))).width(60).height(60)
          .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
        GlowDirectionButton({ dark: this.dark, heading: 'right', label: '向右移动', active: this.active, move: this.move })
      }
      GlowDirectionButton({ dark: this.dark, heading: 'down', label: '向下移动', active: this.active, move: this.move })
    }.width(188).height(188)
  }
}
