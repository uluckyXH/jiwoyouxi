import { FCPalette as P } from './FreecellPalette';

@Component
export struct FCButton {
  @Prop dark: boolean = false;
  @Prop icon: string = 'help';
  @Prop label: string = '';
  @Prop primary: boolean = false;
  @Prop active: boolean = true;
  @Prop small: boolean = false;
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 6 }) {
        Image($rawfile(P.icon(this.icon, this.dark, this.primary))).width(20).height(20).draggable(false).accessibilityLevel('no')
        if (!this.small) {
          Text(this.label).fontSize(12).minFontSize(10).maxFontSize(12).maxLines(1)
            .fontWeight(FontWeight.Medium).fontColor(this.primary ? P.on(this.dark) : P.ink(this.dark))
        }
      }.width('100%').justifyContent(FlexAlign.Center)
    }.width(this.small ? 44 : '100%').height(this.small ? 44 : 50).padding(4).borderRadius(this.small ? 17 : 18)
    .backgroundColor(this.primary ? P.accent(this.dark) : P.paper(this.dark))
    .border({ width: 1, color: this.primary ? P.accent(this.dark) : P.line(this.dark), radius: this.small ? 17 : 18 })
    .enabled(this.active).opacity(this.active ? 1 : .4).accessibilityText(this.label).onClick(this.action)
  }
}

@Component
struct FCStat {
  @Prop dark: boolean = false;
  @Prop icon: string = 'cards';
  @Prop label: string = '';
  @Prop value: string = '';
  build() {
    Column({ space: 4 }) {
      Row({ space: 4 }) {
        Image($rawfile(P.icon(this.icon, this.dark))).width(12).height(12).accessibilityLevel('no')
        Text(this.label).fontSize(10).fontColor(P.muted(this.dark))
      }
      Text(this.value).fontSize(20).minFontSize(12).maxFontSize(20).maxLines(1).fontWeight(FontWeight.Bold)
        .fontFamily('monospace').fontColor(P.ink(this.dark))
    }.width('100%').id(`freecell-stat-${this.icon}`)
  }
}

@Component
export struct FCStats {
  @Prop dark: boolean = false;
  @Prop collected: number = 0;
  @Prop elapsed: number = 0;
  @Prop moves: number = 0;
  build() {
    Row() {
      FCStat({ dark: this.dark, icon: 'cards', label: '归位', value: `${this.collected} / 52` }).layoutWeight(1)
      FCStat({ dark: this.dark, icon: 'time', label: '用时',
        value: `${Math.floor(this.elapsed / 60).toString().padStart(2, '0')}:${(this.elapsed % 60).toString().padStart(2, '0')}` }).layoutWeight(1)
      FCStat({ dark: this.dark, icon: 'steps', label: '步数', value: `${this.moves}` }).layoutWeight(1)
    }.width('100%').height(62).padding(8).borderRadius(21).backgroundColor(P.paper(this.dark))
    .border({ width: 1, color: P.line(this.dark), radius: 21 })
  }
}
