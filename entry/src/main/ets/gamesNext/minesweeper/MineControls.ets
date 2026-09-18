import { MINE_ASSETS, MINE_LEVELS, MineLevel, mineTime } from './MineModel';
import { MinePalette as P } from './MinePalette';

@Component
export struct MineIconButton {
  @Prop icon: string = 'help';
  @Prop label: string = '';
  @Prop dark: boolean = false;
  @Prop primary: boolean = false;
  action: () => void = () => {};

  build() {
    Button({ type: ButtonType.Circle }) {
      Image($rawfile(P.icon(this.icon, this.dark, this.primary ? 'on' : '')))
        .width(21).height(21).draggable(false).accessibilityLevel('no')
    }.width(44).height(44)
    .backgroundColor(this.primary ? P.accent(this.dark) : P.paper(this.dark))
    .border({ width: 1, color: this.primary ? P.accent(this.dark) : P.line(this.dark) })
    .accessibilityText(this.label).onClick(this.action)
  }
}

@Component
export struct MineActionButton {
  @Prop label: string = '继续探索';
  @Prop icon: string = 'play';
  @Prop dark: boolean = false;
  @Prop primary: boolean = true;
  @Prop actionEnabled: boolean = true;
  action: () => void = () => {};

  build() {
    Button({ type: ButtonType.Normal }) {
      Stack() {
        if (this.primary) {
          Image($rawfile(`${MINE_ASSETS}scene/action_${this.dark ? 'dark' : 'light'}.svg`))
            .width('100%').height(50).objectFit(ImageFit.Fill).accessibilityLevel('no')
        }
        Row({ space: 9 }) {
          Image($rawfile(P.icon(this.icon, this.dark, this.primary ? 'on' : '')))
            .width(19).height(19).accessibilityLevel('no')
          Text(this.label).fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor(this.primary ? P.onAccent(this.dark) : P.ink(this.dark))
        }.justifyContent(FlexAlign.Center).width('100%')
      }.width('100%').height(50)
    }.width('100%').height(50).borderRadius(25)
    .backgroundColor(this.primary ? Color.Transparent : P.soft(this.dark))
    .enabled(this.actionEnabled).opacity(this.actionEnabled ? 1 : 0.55)
    .accessibilityText(this.label).onClick(this.action)
  }
}

@Component
struct MineStatValue {
  @Prop dark: boolean = false;
  @Prop icon: string = 'clock';
  @Prop value: string = '';
  @Prop label: string = '';

  build() {
    Column({ space: 4 }) {
      Row({ space: 5 }) {
        Image($rawfile(P.icon(this.icon, this.dark, 'accent'))).width(14).height(14).accessibilityLevel('no')
        Text(this.label).fontSize(10).fontColor(P.muted(this.dark))
      }
      Text(this.value).fontSize(23).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
        .minFontSize(14).maxFontSize(23).maxLines(1).fontFamily('monospace')
        .width('100%').height(30).textAlign(TextAlign.Center)
    }.width('100%').alignItems(HorizontalAlign.Center)
  }
}

@Component
export struct MineStats {
  @Prop dark: boolean = false;
  @Prop compact: boolean = false;
  @Prop remaining: number = 10;
  @Prop elapsedMs: number = 0;
  @Prop bestMs: number = 0;

  build() {
    Row() {
      MineStatValue({ dark: this.dark, icon: 'flag', value: `${this.remaining < 10 ? '0' : ''}${this.remaining}`, label: '剩余雷数' })
        .layoutWeight(1)
      Divider().vertical(true).height(30).color(P.line(this.dark))
      MineStatValue({ dark: this.dark, icon: 'clock', value: mineTime(this.elapsedMs), label: '用时' }).layoutWeight(1)
      Divider().vertical(true).height(30).color(P.line(this.dark))
      MineStatValue({ dark: this.dark, icon: 'trophy', value: this.bestMs > 0 ? mineTime(this.bestMs) : '—', label: '本档最佳' })
        .layoutWeight(1)
    }.width('100%').height(this.compact ? 68 : 76).padding(8).borderRadius(22)
    .backgroundColor(P.paper(this.dark)).border({ width: 1, color: P.line(this.dark) })
  }
}

@Component
export struct MineDifficultyPicker {
  @Prop dark: boolean = false;
  @Prop compact: boolean = false;
  @Prop selected: string = 'easy';
  choose: (key: string) => void = () => {};

  build() {
    Row({ space: 6 }) {
      ForEach(MINE_LEVELS, (level: MineLevel, i: number) => {
        Button({ type: ButtonType.Normal }) {
          Column({ space: 4 }) {
            Row({ space: 5 }) {
              Image($rawfile(P.icon(i === 0 ? 'sprout' : i === 1 ? 'leaf' : 'forest', this.dark,
                this.selected === level.key ? 'on' : 'accent'))).width(18).height(18).accessibilityLevel('no')
              Text(level.name).fontSize(14).fontWeight(FontWeight.Medium)
                .fontColor(this.selected === level.key ? P.onAccent(this.dark) : P.ink(this.dark))
            }
            Text(`${level.cols}×${level.rows} · ${level.mines} 雷`).fontSize(10)
              .fontColor(this.selected === level.key ? P.onAccent(this.dark) : P.muted(this.dark))
          }.width('100%').height(this.compact ? 52 : 60).justifyContent(FlexAlign.Center)
        }.layoutWeight(1).height(this.compact ? 52 : 60).padding(0).borderRadius(16)
        .backgroundColor(this.selected === level.key ? P.accent(this.dark) : P.paper(this.dark))
        .fontColor(this.selected === level.key ? P.onAccent(this.dark) : P.muted(this.dark))
        .border({ width: 1, color: this.selected === level.key ? P.accent(this.dark) : P.line(this.dark), radius: 16 })
        .accessibilityText(`${level.name}难度，${level.cols}列${level.rows}行，${level.mines}颗雷${this.selected === level.key ? '，已选中' : ''}`)
        .onClick(() => this.choose(level.key))
      }, (level: MineLevel) => level.key)
    }.width('100%')
  }
}

@Component
export struct MineModeSwitch {
  @Prop dark: boolean = false;
  @Prop flagMode: boolean = false;
  change: (flag: boolean) => void = () => {};

  @Builder
  Mode(flag: boolean, label: string) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 7 }) {
        Image($rawfile(P.icon(flag ? 'flag' : 'open', this.dark, this.flagMode === flag ? 'accent' : '')))
          .width(18).height(18).accessibilityLevel('no')
        Text(label).fontSize(14).fontWeight(this.flagMode === flag ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.flagMode === flag ? P.accent(this.dark) : P.muted(this.dark))
      }.justifyContent(FlexAlign.Center).width('100%')
    }.layoutWeight(1).height(44).borderRadius(14)
    .backgroundColor(this.flagMode === flag ? P.paper(this.dark) : Color.Transparent)
    .accessibilityText(`${label}模式${this.flagMode === flag ? '，已选中' : ''}`)
    .onClick(() => this.change(flag))
  }

  build() {
    Row({ space: 4 }) {
      this.Mode(false, '翻开')
      this.Mode(true, '插旗')
    }.width('100%').padding(4).borderRadius(18).backgroundColor(P.soft(this.dark))
  }
}
