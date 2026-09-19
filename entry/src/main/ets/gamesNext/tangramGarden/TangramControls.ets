import { TangramPalette as P } from './TangramPalette';

@Component
export struct TangramButton {
  @Prop dark: boolean = false;
  @Prop icon: string = 'hint';
  @Prop label: string = '';
  @Prop primary: boolean = false;
  @Prop compact: boolean = false;
  @Prop active: boolean = true;
  @Prop buttonHeight: number = 48;
  action: () => void = () => {};
  build() {
    Button({ type: this.compact ? ButtonType.Circle : ButtonType.Normal }) {
      Row({ space: 7 }) {
        Image($rawfile(P.icon(this.icon, this.dark, this.primary))).width(22).height(22).draggable(false).accessibilityLevel('no')
        if (!this.compact) {
          Text(this.label).fontSize(13).minFontSize(10).maxFontSize(13).maxLines(1)
            .fontWeight(FontWeight.Medium).fontColor(this.primary ? '#FFF9EA' : P.ink(this.dark))
        }
      }.justifyContent(FlexAlign.Center).width('100%')
    }.width('100%').height(this.buttonHeight).borderRadius(this.compact ? this.buttonHeight / 2 : 17)
    .backgroundColor(this.primary ? '#446E43' : P.paper(this.dark))
    .border({ width: 1, color: this.primary ? '#668554' : P.line(this.dark) })
    .enabled(this.active).opacity(this.active ? 1 : .45)
    .accessibilityText(this.label).onClick(() => this.action())
  }
}
