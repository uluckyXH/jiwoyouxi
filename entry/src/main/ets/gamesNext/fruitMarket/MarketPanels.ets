import { MarketAction, MarketFruitImage } from './MarketControls';
import { MARKET_ASSETS, MARKET_FRUITS, MarketFruit } from './MarketModel';
import { MarketPalette } from './MarketPalette';

/** A component (rather than a by-value @Builder argument) keeps each preview reactive. */
@Component
struct MarketFruitPreview {
  @Prop level: number = 0;
  @Prop dark: boolean = false;
  @Prop active: boolean = false;
  @Prop wide: boolean = false;

  build() {
    Column({ space: 2 }) {
      Text(this.active ? '准备投放' : '接下来').fontSize(10)
        .fontColor(this.active ? MarketPalette.accent(this.dark) : MarketPalette.muted(this.dark))
      MarketFruitImage({ level: this.level, imageSize: this.wide ? 54 : 34 })
      Text(MARKET_FRUITS[this.level].name).fontSize(this.wide ? 12 : 10).maxLines(1)
        .fontColor(MarketPalette.ink(this.dark))
    }.width('100%').height(this.wide ? 102 : 76)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.active ? MarketPalette.soft(this.dark) : Color.Transparent)
    .borderRadius(18)
    .accessibilityGroup(true)
    .accessibilityText(`${this.active ? '准备投放' : '接下来'}：${MARKET_FRUITS[this.level].name}，在下方摊位松手投放`)
  }
}

@Component
export struct MarketStats {
  @Prop dark: boolean = false;
  @Prop wide: boolean = false;
  @Prop score: number = 0;
  @Prop best: number = 0;
  @Prop current: number = 0;
  @Prop next: number = 0;

  @Builder
  Score() {
    Column({ space: 3 }) {
      Text('本局得分').fontSize(11).fontColor(MarketPalette.muted(this.dark))
      Text(`${this.score}`).fontSize(this.wide ? 44 : 30).fontWeight(FontWeight.Bold)
        .fontColor(MarketPalette.ink(this.dark)).maxLines(1).minFontSize(18)
        .maxFontSize(this.wide ? 44 : 30).heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
      Row({ space: 4 }) {
        Image($rawfile(MarketPalette.icon('trophy', this.dark, 'gold'))).width(11).height(11)
          .accessibilityLevel('no')
        Text(`最高 ${Math.max(this.best, this.score)}`).fontSize(10).maxLines(1)
          .fontColor(MarketPalette.gold(this.dark)).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }.alignItems(HorizontalAlign.Start).layoutWeight(1)
  }

  @Builder
  Queue() {
    Row({ space: this.wide ? 8 : 2 }) {
      MarketFruitPreview({ level: this.current, dark: this.dark, active: true, wide: this.wide })
        .layoutWeight(1)
      Image($rawfile(MarketPalette.icon('arrow', this.dark, 'accent'))).width(14).height(14)
        .rotate({ angle: 180 }).accessibilityLevel('no')
      MarketFruitPreview({ level: this.next, dark: this.dark, wide: this.wide })
        .layoutWeight(1)
    }.width(this.wide ? '100%' : 150).justifyContent(FlexAlign.Center)
  }

  build() {
    Column({ space: this.wide ? 18 : 0 }) {
      if (this.wide) {
        Row() { this.Score() }.width('100%')
        Divider().color(MarketPalette.line(this.dark))
        this.Queue()
        Text('松手投放，接下来自动补位').fontSize(11).fontColor(MarketPalette.muted(this.dark))
      } else {
        Row({ space: 10 }) {
          this.Score()
          this.Queue()
        }.width('100%')
      }
    }.width('100%').padding(this.wide ? 20 : { left: 16, right: 10, top: 10, bottom: 10 })
    .backgroundColor(MarketPalette.surface(this.dark))
    .border({ width: 1, color: MarketPalette.line(this.dark), radius: 24 })
  }
}

@Component
export struct MarketGuide {
  @Prop dark: boolean = false;
  @Prop highest: number = 0;

  build() {
    Column({ space: 14 }) {
      Row() {
        Text('从小葡萄，到瓜王').fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(MarketPalette.ink(this.dark))
        Blank()
        Image($rawfile(MarketPalette.icon('leaf', this.dark, 'accent'))).width(18).height(18).accessibilityLevel('no')
      }.width('100%')
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
        ForEach(MARKET_FRUITS, (fruit: MarketFruit, index: number) => {
          Column({ space: 2 }) {
            MarketFruitImage({ level: index, imageSize: 38 })
            Text(`${index + 1}`).fontSize(10).fontWeight(FontWeight.Medium)
              .fontColor(index <= this.highest ? MarketPalette.accent(this.dark) : MarketPalette.muted(this.dark))
          }.width('25%').margin({ bottom: 8 })
        }, (fruit: MarketFruit) => fruit.asset)
      }.width('100%')
      Text('相同水果相碰，就会长大一级。').fontSize(12).fontColor(MarketPalette.muted(this.dark))
        .lineHeight(19).width('100%')
    }.padding(18).width('100%').borderRadius(22)
    .backgroundColor(MarketPalette.surface(this.dark))
    .border({ width: 1, color: MarketPalette.line(this.dark), radius: 22 })
  }
}

@Component
export struct MarketDialog {
  @Prop mode: string = 'pause';
  @Prop dark: boolean = false;
  @Prop score: number = 0;
  @Prop highest: number = 0;
  @Prop drops: number = 0;
  @Prop merges: number = 0;
  @Prop cardWidth: number = 340;
  @Prop cardHeight: number = 600;
  @Prop saveFailed: boolean = false;
  resume: () => void = () => {};
  restart: () => void = () => {};
  exit: () => void = () => {};
  exitWithoutSave: () => void = () => {};
  help: () => void = () => {};
  retry: () => void = () => {};

  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor('#00000070')
      Scroll() {
        Column({ space: 16 }) {
          if (this.mode === 'loading') {
            LoadingProgress().width(44).height(44).color(MarketPalette.accent(this.dark))
          } else if (this.mode === 'result') {
            MarketFruitImage({ level: this.highest, imageSize: 92 })
          } else {
            Image($rawfile(`${MARKET_ASSETS}scene/market_badge.svg`))
              .width(78).height(78).objectFit(ImageFit.Contain).accessibilityLevel('no')
          }
          Text(this.title()).fontSize(23).fontWeight(FontWeight.Bold)
            .fontColor(MarketPalette.ink(this.dark)).textAlign(TextAlign.Center)
          Text(this.message()).fontSize(14).lineHeight(22)
            .fontColor(MarketPalette.muted(this.dark)).textAlign(TextAlign.Center)
          if (this.mode === 'result') {
            Text(`${this.score}`).fontSize(44).fontWeight(FontWeight.Bold).fontColor(MarketPalette.gold(this.dark))
            Text(`${this.drops} 次投放 · ${this.merges} 次合成`).fontSize(12)
              .fontColor(MarketPalette.muted(this.dark))
          }
          if (this.mode === 'help') {
            MarketGuide({ dark: this.dark, highest: this.highest })
          }
          if (this.saveFailed) {
            Text('进度暂未保存成功，请稍后重试。').fontSize(12).fontColor(MarketPalette.danger(this.dark))
            Button('不保存，直接返回大厅').fontSize(12).height(44).backgroundColor(Color.Transparent)
              .fontColor(MarketPalette.danger(this.dark)).onClick(this.exitWithoutSave)
          }
          if (this.mode === 'error') {
            MarketAction({ label: '重新加载', icon: 'restart', dark: this.dark, action: this.retry })
            MarketAction({ label: '返回大厅', icon: 'back', dark: this.dark, primary: false, action: this.exit })
          } else if (this.mode === 'result') {
            MarketAction({ label: '再摆一摊', icon: 'restart', dark: this.dark, action: this.restart })
            MarketAction({ label: '返回大厅', icon: 'back', dark: this.dark, primary: false, action: this.exit })
          } else if (this.mode === 'restart') {
            MarketAction({ label: '确认重新开局', icon: 'restart', dark: this.dark, action: this.restart })
            MarketAction({ label: '保留这局', icon: 'play', dark: this.dark, primary: false, action: this.resume })
          } else if (this.mode === 'exit') {
            MarketAction({ label: '保存并返回大厅', icon: 'back', dark: this.dark, action: this.exit })
            MarketAction({ label: '继续摆摊', icon: 'play', dark: this.dark, primary: false, action: this.resume })
          } else if (this.mode !== 'loading') {
            MarketAction({ label: this.mode === 'help' ? '明白了' : '继续摆摊', icon: 'play', dark: this.dark,
              action: this.resume })
            if (this.mode === 'pause' || this.mode === 'resume') {
              Row({ space: 10 }) {
                Button('玩法说明').fontSize(13).fontColor(MarketPalette.ink(this.dark))
                  .backgroundColor(MarketPalette.soft(this.dark)).height(44).layoutWeight(1).onClick(this.help)
                Button('重新开局').fontSize(13).fontColor(MarketPalette.ink(this.dark))
                  .backgroundColor(MarketPalette.soft(this.dark)).height(44).layoutWeight(1).onClick(this.restart)
              }.width('100%')
              Button('保存并返回大厅').fontSize(13).fontColor(MarketPalette.muted(this.dark))
                .backgroundColor(Color.Transparent).height(44).onClick(this.exit)
            }
          }
        }.width('100%').padding(24)
      }
      .width(this.cardWidth).constraintSize({ maxHeight: this.cardHeight })
      .scrollBar(BarState.Off).backgroundColor(MarketPalette.surface(this.dark)).borderRadius(28)
      .border({ width: 1, color: MarketPalette.line(this.dark), radius: 28 })
    }.width('100%').height('100%').onTouch((event: TouchEvent) => { event.stopPropagation(); })
  }

  private title(): string {
    if (this.mode === 'loading') return '水果摊准备中';
    if (this.mode === 'error') return '水果还没摆好';
    if (this.mode === 'result') return this.highest >= 10 ? '今天的瓜王诞生了' : '今天也是满满收获';
    if (this.mode === 'help') return '慢慢放，碰出大西瓜';
    if (this.mode === 'restart') return '重新摆一摊？';
    if (this.mode === 'exit') return '先收摊，待会儿再来？';
    if (this.mode === 'resume') return '上次的水果还在等你';
    return '歇一会儿，水果不会跑';
  }

  private message(): string {
    if (this.mode === 'loading') return '正在准备鲜果与摊位';
    if (this.mode === 'error') return '素材加载失败，重新加载后就能继续。';
    if (this.mode === 'result') return '水果持续越过警戒线，本局结束。';
    if (this.mode === 'help') return '在摊位内左右拖动，松手投放；也可以直接点击落点。水果越线后有 3 秒合成机会，腾出空间就能继续。';
    if (this.mode === 'restart') return '当前这一局将结束，最好成绩会保留。';
    if (this.mode === 'exit') return '保存当前水果和分数，下次从这里继续。';
    if (this.mode === 'resume') return '已恢复上次进度，准备好再继续。';
    return '当前对局已暂停。';
  }
}
