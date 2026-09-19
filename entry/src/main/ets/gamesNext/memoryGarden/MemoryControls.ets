import { MEMORY_MODES, MemoryMode, MemoryModeInfo } from './MemoryModel';
import { MemoryPalette as P } from './MemoryPalette';

@Component
export struct MemoryIconButton {
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
export struct MemoryActionButton {
  @Prop dark: boolean = false;
  @Prop icon: string = 'play';
  @Prop label: string = '';
  @Prop primary: boolean = true;
  @Prop active: boolean = true;
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 7 }) {
        Image($rawfile(P.icon(this.icon, this.dark, this.primary ? 'on' : 'accent')))
          .width(20).height(20).accessibilityLevel('no')
        Text(this.label).fontSize(13).fontWeight(FontWeight.Medium).maxLines(1)
          .fontColor(this.primary ? P.onAccent(this.dark) : P.ink(this.dark))
      }.width('100%').justifyContent(FlexAlign.Center)
    }.width('100%').height(48).padding(5).borderRadius(17)
    .backgroundColor(this.primary ? P.accent(this.dark) : P.paper(this.dark))
    .border({ width: 1, color: this.primary ? P.accent(this.dark) : P.line(this.dark), radius: 17 })
    .enabled(this.active).opacity(this.active ? 1 : .45).onClick(this.action)
  }
}
@Component
struct MemoryStat {
  @Prop dark: boolean = false;
  @Prop icon: string = 'cards';
  @Prop label: string = '';
  @Prop value: string = '';
  build() {
    Column({ space: 3 }) {
      Row({ space: 4 }) {
        Image($rawfile(P.icon(this.icon, this.dark, 'accent'))).width(13).height(13).accessibilityLevel('no')
        Text(this.label).fontSize(10).fontColor(P.muted(this.dark)).maxLines(1)
      }
      Text(this.value).fontSize(25).minFontSize(13).maxFontSize(25).maxLines(1).fontFamily('monospace')
        .fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).width('100%').textAlign(TextAlign.Center).height(28)
    }.width('100%')
  }
}
@Component
export struct MemoryStats {
  @Prop dark: boolean = false;
  @Prop attempts: number = 0;
  @Prop streak: number = 0;
  @Prop best: number = 0;
  @Prop panelHeight: number = 66;
  build() {
    Row() {
      MemoryStat({ dark: this.dark, label: '翻牌次数', value: '' + this.attempts }).layoutWeight(1)
      Divider().vertical(true).height(24).color(P.line(this.dark))
      MemoryStat({ dark: this.dark, label: '连续配对', icon: 'pair', value: '' + this.streak }).layoutWeight(1)
      Divider().vertical(true).height(24).color(P.line(this.dark))
      MemoryStat({ dark: this.dark, label: '本档最少', icon: 'trophy', value: this.best > 0 ? '' + this.best : '—' }).layoutWeight(1)
    }.width('100%').height(this.panelHeight).padding({ left: 8, right: 8 }).borderRadius(23)
    .backgroundColor(P.paper(this.dark)).border({ width: 1, color: P.line(this.dark), radius: 23 })
  }
}
@Component
export struct MemoryModes {
  @Prop dark: boolean = false;
  @Prop mode: MemoryMode = 'journey';
  choose: (mode: MemoryMode) => void = () => {};
  build() {
    Row({ space: 6 }) {
      ForEach(MEMORY_MODES, (item: MemoryModeInfo) => {
        Button({ type: ButtonType.Normal }) {
          Column({ space: 3 }) {
            Text(item.title).fontSize(14).fontWeight(FontWeight.Medium)
              .fontColor(this.mode === item.id ? P.onAccent(this.dark) : P.ink(this.dark))
            Text(item.subtitle).fontSize(9).maxLines(1)
              .fontColor(this.mode === item.id ? P.onAccent(this.dark) : P.ink(this.dark))
          }.width('100%')
        }.layoutWeight(1).height(50).padding(3).borderRadius(16)
        .backgroundColor(this.mode === item.id ? P.accent(this.dark) : P.paper(this.dark))
        .border({ width: 1, color: this.mode === item.id ? P.accent(this.dark) : P.line(this.dark), radius: 16 })
        .accessibilityText(item.title + '，' + item.subtitle + (this.mode === item.id ? '，已选中' : ''))
        .onClick(() => this.choose(item.id))
      }, (item: MemoryModeInfo) => item.id)
    }.width('100%').height(50)
  }
}
@Component
export struct MemoryTools {
  @Prop dark: boolean = false;
  restart: () => void = () => {};
  help: () => void = () => {};
  build() {
    Row({ space: 10 }) {
      MemoryActionButton({ dark: this.dark, icon: 'restart', label: '重新开始', primary: false, action: this.restart })
        .layoutWeight(1)
      MemoryActionButton({ dark: this.dark, icon: 'help', label: '游玩指南', primary: false, action: this.help })
        .layoutWeight(1)
    }.width('100%').height(48)
  }
}
