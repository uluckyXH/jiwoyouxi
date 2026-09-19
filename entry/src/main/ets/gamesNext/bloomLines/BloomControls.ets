import { BLOOM_COLOR_NAMES, BLOOM_MODES, BloomConfig, BloomMode } from './BloomModel';
import { BloomPalette as P } from './BloomPalette';

@Component
export struct BloomIconButton {
  @Prop dark: boolean = false;
  @Prop icon: string = 'help';
  @Prop label: string = '';
  @Prop primary: boolean = false;
  @Prop active: boolean = true;
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Normal }) {
      Image($rawfile(P.icon(this.icon, this.dark, this.primary ? 'on' : 'ink')))
        .width(22).height(22).draggable(false).accessibilityLevel('no')
    }.width(44).height(44).padding(0).borderRadius(16)
    .backgroundColor(this.primary ? P.accent(this.dark) : P.paper(this.dark))
    .border({ width: 1, color: this.primary ? P.accent(this.dark) : P.line(this.dark), radius: 16 })
    .enabled(this.active).opacity(this.active ? 1 : .45).accessibilityText(this.label).onClick(this.action)
  }
}

@Component
export struct BloomActionButton {
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
          .width(20).height(20).accessibilityLevel('no')
        Text(this.label).fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor(this.primary ? P.onAccent(this.dark) : P.ink(this.dark))
      }.width('100%').justifyContent(FlexAlign.Center)
    }.width('100%').height(48).padding(0).borderRadius(17)
    .backgroundColor(this.primary ? P.accent(this.dark) : P.soft(this.dark))
    .enabled(this.active).opacity(this.active ? 1 : .45).onClick(this.action)
  }
}

@Component
struct BloomStat {
  @Prop dark: boolean = false;
  @Prop icon: string = 'spark';
  @Prop label: string = '';
  @Prop value: number = 0;
  build() {
    Column({ space: 2 }) {
      Row({ space: 4 }) {
        Image($rawfile(P.icon(this.icon, this.dark, 'accent'))).width(13).height(13).accessibilityLevel('no')
        Text(this.label).fontSize(10).fontColor(P.muted(this.dark)).maxLines(1)
      }
      Text('' + this.value).fontSize(25).minFontSize(12).maxFontSize(25).maxLines(1)
        .fontFamily('monospace').fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        .width('100%').height(28).textAlign(TextAlign.Center)
    }.width('100%')
  }
}

@Component
struct BloomScoreFloat {
  @Prop dark: boolean = false;
  @Prop gain: number = 0;
  @State lifted: boolean = false;
  private enter(): void {
    this.getUIContext().animateTo({ duration: 650, curve: Curve.EaseOut }, () => { this.lifted = true; });
  }
  build() {
    Text('+' + this.gain).fontSize(16).fontWeight(FontWeight.Bold).fontColor(P.gold(this.dark))
      .translate({ y: this.lifted ? -28 : 0 }).opacity(this.lifted ? 0 : 1)
      .hitTestBehavior(HitTestMode.None).accessibilityLevel('no').onAppear(() => this.enter())
  }
}

@Component
export struct BloomStats {
  @Prop dark: boolean = false;
  @Prop panelHeight: number = 68;
  @Prop score: number = 0;
  @Prop best: number = 0;
  @Prop cleared: number = 0;
  @Prop gain: number = 0;
  @Prop turn: number = 0;
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Row() {
        BloomStat({ dark: this.dark, label: '本局得分', value: this.score }).layoutWeight(1)
        Divider().vertical(true).height(23).color(P.line(this.dark))
        BloomStat({ dark: this.dark, icon: 'trophy', label: '本档最佳', value: this.best }).layoutWeight(1)
        Divider().vertical(true).height(23).color(P.line(this.dark))
        BloomStat({ dark: this.dark, icon: 'flower', label: '本局消除', value: this.cleared }).layoutWeight(1)
      }.width('100%').height(this.panelHeight).padding({ left: 8, right: 8 }).borderRadius(23)
      .backgroundColor(P.paper(this.dark)).border({ width: 1, color: P.line(this.dark), radius: 23 })
      if (this.gain > 0) {
        ForEach([this.turn], (turn: number) => {
          BloomScoreFloat({ dark: this.dark, gain: this.gain }).position({ x: 18, y: 35 })
        }, (turn: number) => '' + turn)
      }
    }.width('100%').height(this.panelHeight)
  }
}

@Component
export struct BloomModePicker {
  @Prop dark: boolean = false;
  @Prop mode: BloomMode = 'garden';
  @Prop panelHeight: number = 52;
  choose: (mode: BloomMode) => void = () => {};
  build() {
    Row({ space: 8 }) {
      ForEach(BLOOM_MODES, (config: BloomConfig) => {
        Button({ type: ButtonType.Normal }) {
          Row({ space: 8 }) {
            Image($rawfile(P.icon(config.mode === 'garden' ? 'seed' : 'flower', this.dark,
              this.mode === config.mode ? 'on' : 'accent'))).width(21).height(21).accessibilityLevel('no')
            Column({ space: 2 }) {
              Text(config.title).fontSize(14).fontWeight(FontWeight.Medium)
                .fontColor(this.mode === config.mode ? P.onAccent(this.dark) : P.ink(this.dark))
              Text(config.subtitle).fontSize(9).maxLines(1)
                .fontColor(this.mode === config.mode ? P.onAccent(this.dark) : P.ink(this.dark))
            }.alignItems(HorizontalAlign.Start)
          }.justifyContent(FlexAlign.Center).width('100%')
        }.layoutWeight(1).height(this.panelHeight).padding(4).borderRadius(18)
        .backgroundColor(this.mode === config.mode ? P.accent(this.dark) : P.paper(this.dark))
        .border({ width: 1, color: this.mode === config.mode ? P.accent(this.dark) : P.line(this.dark), radius: 18 })
        .accessibilityText(config.title + '，' + config.subtitle + (this.mode === config.mode ? '，已选择' : ''))
        .onClick(() => this.choose(config.mode))
      }, (config: BloomConfig) => config.mode)
    }.width('100%').height(this.panelHeight)
  }
}

@Component
export struct BloomNextBatch {
  @Prop dark: boolean = false;
  @Prop next: number[] = [];
  @Prop panelHeight: number = 62;
  build() {
    Row({ space: 8 }) {
      Column({ space: 4 }) {
        Text('下一批小彩珠').fontSize(12).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
        Text('消除后，留到下一步').fontSize(10).minFontSize(8).maxFontSize(10)
          .maxLines(1).fontColor(P.muted(this.dark)).width('100%')
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Row({ space: 4 }) {
        ForEach(this.next, (color: number, index: number) => {
          Image($rawfile(P.bead(color, this.dark))).width(32).height(32)
            .draggable(false).accessibilityText('第 ' + (index + 1) + ' 颗，' + BLOOM_COLOR_NAMES[color])
        }, (color: number, index: number) => index + ':' + color)
      }
    }.width('100%').height(this.panelHeight).padding({ left: 14, right: 14 })
    .backgroundColor(P.soft(this.dark)).borderRadius(21)
  }
}

@Component
struct BloomTool {
  @Prop dark: boolean = false;
  @Prop label: string = '';
  @Prop icon: string = '';
  @Prop active: boolean = true;
  @Prop controlHeight: number = 52;
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 5 }) {
        Image($rawfile(P.icon(this.icon, this.dark, 'accent'))).width(19).height(19).accessibilityLevel('no')
        Text(this.label).fontSize(12).maxLines(1).fontColor(P.ink(this.dark))
      }.justifyContent(FlexAlign.Center).width('100%')
    }.width('100%').height(this.controlHeight).padding(2).borderRadius(17)
    .backgroundColor(P.paper(this.dark)).border({ width: 1, color: P.line(this.dark), radius: 17 })
    .enabled(this.active).opacity(this.active ? 1 : .43).accessibilityText(this.label).onClick(this.action)
  }
}

@Component
export struct BloomTools {
  @Prop dark: boolean = false;
  @Prop undoAvailable: boolean = false;
  @Prop controlHeight: number = 52;
  undo: () => void = () => {};
  restart: () => void = () => {};
  help: () => void = () => {};
  build() {
    Row({ space: 8 }) {
      BloomTool({ dark: this.dark, label: '撤销', icon: 'undo', active: this.undoAvailable,
        controlHeight: this.controlHeight, action: this.undo }).layoutWeight(1)
      BloomTool({ dark: this.dark, label: '重开', icon: 'restart',
        controlHeight: this.controlHeight, action: this.restart }).layoutWeight(1)
      BloomTool({ dark: this.dark, label: '玩法', icon: 'help',
        controlHeight: this.controlHeight, action: this.help }).layoutWeight(1)
    }.width('100%').height(this.controlHeight)
  }
}
