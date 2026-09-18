import { BLOCK_ASSETS, BLOCK_NAMES } from './BlockModel';
import { BlockPalette } from './BlockPalette';

@Component
export struct BlockIconButton {
  @Prop icon: string = 'pause';
  @Prop label: string = '暂停';
  @Prop dark: boolean = false;
  @Prop primary: boolean = false;
  @Prop quiet: boolean = false;
  action: () => void = () => {};

  build() {
    Button({ type: ButtonType.Circle }) {
      Image($rawfile(BlockPalette.icon(this.icon, this.dark, this.primary))).width(21).height(21)
        .draggable(false).accessibilityLevel('no')
    }.width(44).height(44).padding(0)
      .backgroundColor(this.primary ? BlockPalette.accent(this.dark) :
        this.quiet ? Color.Transparent : BlockPalette.surface(this.dark))
      .border({ width: this.primary || this.quiet ? 0 : 1, color: BlockPalette.line(this.dark), radius: 22 }).clip(true)
      .accessibilityText(this.label).onClick(this.action)
  }
}

@Component
export struct BlockKey {
  @Prop name: string = 'left';
  @Prop label: string = '左移';
  @Prop dark: boolean = false;
  @Prop primary: boolean = false;
  @Prop compact: boolean = false;
  @Prop spacious: boolean = false;
  @Prop @Watch('activityChanged') active: boolean = true;
  press: (name: string) => void = () => {};
  release: (name: string) => void = () => {};
  click: (name: string) => void = () => {};
  private lastTouch: number = 0;
  @State pressed: boolean = false;

  private activityChanged(): void {
    if (!this.active) { this.pressed = false; this.release(this.name); }
  }
  aboutToDisappear(): void { this.release(this.name); }
  private hint(): string {
    if (this.compact) {
      if (this.name === 'drop') return '直落';
      if (this.name === 'rotate') return '顺向';
      if (this.name === 'reverse') return '逆向';
      return this.name === 'down' ? '加速' : '连移';
    }
    if (this.name === 'drop') return '直达落点';
    if (this.name === 'rotate') return '顺时针';
    if (this.name === 'reverse') return '逆时针';
    return this.name === 'down' ? '长按加速' : '长按连移';
  }

  build() {
    Button({ type: ButtonType.Normal }) {
        Row({ space: this.spacious ? 9 : this.compact ? 4 : 7 }) {
          Image($rawfile(BlockPalette.icon(this.name, this.dark, this.primary)))
            .width(this.spacious ? 26 : 20).height(this.spacious ? 26 : 20)
            .draggable(false).accessibilityLevel('no')
            Text(this.label).fontSize(this.spacious ? 16 : this.compact ? 12 : 14).fontWeight(FontWeight.Medium).maxLines(1)
              .fontColor(this.primary ? BlockPalette.onAccent(this.dark) : BlockPalette.ink(this.dark))
        }.justifyContent(FlexAlign.Center)
    }.width('100%').height('100%').padding(0).borderRadius(this.spacious ? 22 : 18)
      .backgroundColor(this.primary ? BlockPalette.accent(this.dark) : BlockPalette.surface(this.dark))
      .border({ width: this.primary ? 0 : 1, color: BlockPalette.line(this.dark), radius: this.spacious ? 22 : 18 })
      .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
      .animation({ duration: 70, curve: Curve.EaseOut })
      .enabled(this.active).accessibilityText(`${this.label}，${this.hint()}`)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.lastTouch = Date.now(); this.pressed = true; this.press(this.name);
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.lastTouch = Date.now(); this.pressed = false; this.release(this.name);
        }
      })
      .onClick(() => { if (Date.now() - this.lastTouch > 500) this.click(this.name); })
  }
}

@Component
export struct BlockPreview {
  @Prop kind: number = -1;
  @Prop label: string = '暂存';
  @Prop order: number = 0;
  @Prop compact: boolean = false;
  @Prop dark: boolean = false;
  @Prop muted: boolean = false;
  @Prop interactive: boolean = false;
  action: () => void = () => {};

  build() {
    Button({ type: ButtonType.Normal }) {
        Column({ space: 1 }) {
          Row({ space: 3 }) {
            if (this.interactive) {
              Image($rawfile(BlockPalette.icon('hold', this.dark))).width(10).height(10)
                .draggable(false).accessibilityLevel('no')
            }
            Text(this.label).fontSize(10).fontColor(BlockPalette.muted(this.dark)).maxLines(1)
            if (this.order > 0) {
              Text(`${this.order}`).fontSize(9).fontColor(BlockPalette.muted(this.dark))
            }
          }.height(13).justifyContent(FlexAlign.Center)
          if (this.kind >= 0) {
            Image($rawfile(`${BLOCK_ASSETS}pieces/${this.kind}.svg`)).width('100%').height(this.compact ? 23 : 33)
              .objectFit(ImageFit.Contain).draggable(false).accessibilityLevel('no').opacity(this.muted ? 0.45 : 1)
          } else {
            Text('点此暂存').height(this.compact ? 23 : 33).fontSize(10).fontColor(BlockPalette.muted(this.dark))
          }
        }.padding({ top: 3, bottom: 3, left: 4, right: 4 }).width('100%')
    }.width('100%').height(this.compact ? 46 : 60).padding(0).borderRadius(14)
      .backgroundColor(BlockPalette.surface(this.dark))
      .border({ width: this.interactive ? 1 : 0, color: BlockPalette.line(this.dark), radius: 14 })
      .stateEffect(this.interactive && !this.muted)
      .accessibilityText(`${this.label}，${this.kind < 0 ? '空' : BLOCK_NAMES[this.kind]}${this.muted ? '，落地后可再使用' : ''}`)
      .accessibilityLevel('yes')
      .focusable(this.interactive).onClick(() => { if (this.interactive && !this.muted) this.action(); })
  }
}

@Component
export struct BlockAction {
  @Prop label: string = '继续游戏';
  @Prop icon: string = '';
  @Prop dark: boolean = false;
  @Prop primary: boolean = true;
  @Prop active: boolean = true;
  action: () => void = () => {};

  build() {
    Button({ type: ButtonType.Capsule }) {
        Row({ space: 8 }) {
          if (this.icon.length > 0) {
            Image($rawfile(BlockPalette.icon(this.icon, this.dark, this.primary))).width(17).height(17)
              .draggable(false).accessibilityLevel('no')
          }
          Text(this.label).fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor(this.primary ? BlockPalette.onAccent(this.dark) : BlockPalette.ink(this.dark))
        }.justifyContent(FlexAlign.Center)
    }.width('100%').height(48).padding({ left: 12, right: 12 })
      .backgroundColor(this.primary ? BlockPalette.accent(this.dark) : BlockPalette.soft(this.dark))
      .enabled(this.active).accessibilityText(this.label).onClick(this.action)
  }
}
