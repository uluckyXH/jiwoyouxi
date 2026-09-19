import { TenPalette as P } from './TenPalette';

@Component
export struct TenIconButton {
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
export struct TenActionButton {
  @Prop dark: boolean = false;
  @Prop icon: string = 'play';
  @Prop label: string = '';
  @Prop primary: boolean = true;
  @Prop active: boolean = true;
  @Prop panelHeight: number = 48;
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 7 }) {
        Image($rawfile(P.icon(this.icon, this.dark, this.primary ? 'on' : 'accent')))
          .width(20).height(20).accessibilityLevel('no')
        Text(this.label).fontSize(13).fontWeight(FontWeight.Medium).maxLines(1)
          .fontColor(this.primary ? P.onAccent(this.dark) : P.ink(this.dark))
      }.width('100%').justifyContent(FlexAlign.Center)
    }.width('100%').height(this.panelHeight).padding(5).borderRadius(17)
    .backgroundColor(this.primary ? P.accent(this.dark) : P.paper(this.dark))
    .border({ width: 1, color: this.primary ? P.accent(this.dark) : P.line(this.dark), radius: 17 })
    .enabled(this.active).opacity(this.active ? 1 : .45).onClick(this.action)
  }
}
@Component
export struct TenStats {
  @Prop dark: boolean = false;
  @Prop stage: number = 1;
  @Prop collected: number = 0;
  @Prop goal: number = 2;
  build() {
    Column({ space: 4 }) {
      Row() {
        Column({ space: 2 }) {
          Text('第 ' + this.stage + ' 关').fontSize(19).minFontSize(14).maxFontSize(19).maxLines(1)
            .fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
          Text(this.stage === 1 ? '晒晒太阳 · 两次就好' : this.stage < 258 ? '风向变了 · 想好再收' :
            '第 ' + (Math.floor((this.stage - 2) / 256) + 1) + ' 轮 · 再走一次小院')
            .fontSize(10).maxLines(1).fontColor(P.muted(this.dark))
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Image($rawfile(P.icon('flower', this.dark, 'accent'))).width(19).height(19).margin({ right: 6 }).accessibilityLevel('no')
        Text(this.collected + ' / ' + this.goal).fontSize(23).minFontSize(15).maxFontSize(23).maxLines(1)
          .fontWeight(FontWeight.Medium).fontColor(P.accent(this.dark)).fontFamily('monospace')
      }.width('100%')
      Progress({ value: this.collected, total: this.goal, type: ProgressType.Linear })
        .color(P.accent(this.dark)).backgroundColor(P.soft(this.dark)).height(3).width('100%')
        .accessibilityText('已收 ' + this.collected + ' 组，共 ' + this.goal + ' 组')
    }.width('100%').height(64).padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .backgroundColor(P.paper(this.dark)).borderRadius(22).border({ width: 1, color: P.line(this.dark), radius: 22 })
  }
}
@Component
export struct TenSelection {
  @Prop dark: boolean = false;
  @Prop wide: boolean = false;
  @Prop sum: number = 0;
  @Prop formula: string = '';
  @Prop collected: boolean = false;
  @Prop hasHint: boolean = false;
  clear: () => void = () => {};
  @Builder
  Selected() {
    Column({ space: 3 }) {
      Row({ space: 6 }) {
        Text(this.collected ? '刚好是十，收好啦' : '已选 ' + this.sum + ' / 10')
          .fontSize(14).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
        if (this.formula.length > 0 && !this.collected) {
          Button({ type: ButtonType.Normal }) {
            Image($rawfile(P.icon('clear', this.dark, 'accent'))).width(13).height(13).accessibilityLevel('no')
          }.width(24).height(24).padding(0).backgroundColor(Color.Transparent).borderRadius(12)
          .responseRegion({ x: -10, y: -10, width: 44, height: 44 })
          .accessibilityText('取消当前连线').onClick(this.clear)
        }
      }
      Text(this.formula.length > 0 ? this.formula : this.hasHint ? '沿虚线路线点选或连起来' : '点选或连过相邻数字')
        .fontSize(11).minFontSize(10).maxFontSize(11)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).fontColor(P.muted(this.dark)).width('100%')
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
  @Builder
  AutoStatus() {
    Row({ space: 6 }) {
      Image($rawfile(P.icon(this.collected ? 'check' : 'spark', this.dark, 'accent')))
        .width(17).height(17).accessibilityLevel('no')
      Column({ space: 2 }) {
        Text(this.collected ? '已收下' : '还差 ' + (10 - this.sum)).fontSize(14)
          .fontWeight(FontWeight.Medium).fontColor(P.accent(this.dark))
        if (!this.collected) { Text('凑满自动收').fontSize(9).fontColor(P.muted(this.dark)) }
      }
    }.width('100%').height(48).justifyContent(FlexAlign.Center).backgroundColor(P.soft(this.dark)).borderRadius(17)
  }
  build() {
    if (this.wide) {
      Column({ space: 10 }) {
        this.Selected()
        this.AutoStatus()
      }.width('100%').height(128).padding(12).backgroundColor(P.paper(this.dark)).borderRadius(21)
        .border({ width: 1, color: P.line(this.dark), radius: 21 })
    } else {
      Row({ space: 8 }) {
        Column() { this.Selected() }.layoutWeight(1)
        Column() { this.AutoStatus() }.width(104)
      }.width('100%').height(64).padding({ left: 12, right: 8, top: 8, bottom: 8 })
        .backgroundColor(P.paper(this.dark)).borderRadius(21).border({ width: 1, color: P.line(this.dark), radius: 21 })
    }
  }
}
@Component
export struct TenTools {
  @Prop dark: boolean = false;
  @Prop wide: boolean = false;
  @Prop canUndo: boolean = false;
  @Prop active: boolean = true;
  undo: () => void = () => {};
  hint: () => void = () => {};
  more: () => void = () => {};
  build() {
    Row({ space: 7 }) {
      TenActionButton({ dark: this.dark, icon: 'undo', label: '撤销', primary: false, panelHeight: this.wide ? 64 : 48,
        active: this.active && this.canUndo, action: this.undo }).layoutWeight(1)
      TenActionButton({ dark: this.dark, icon: 'hint', label: '看一步', primary: false, panelHeight: this.wide ? 64 : 48,
        active: this.active, action: this.hint }).layoutWeight(1)
      TenActionButton({ dark: this.dark, icon: 'more', label: '更多', primary: false, panelHeight: this.wide ? 64 : 48,
        active: this.active, action: this.more }).layoutWeight(1)
    }.width('100%').height(this.wide ? 64 : 48)
  }
}
