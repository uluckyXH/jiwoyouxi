import { MemoryRound, MEMORY_HINT, memoryMatched, memoryOpen } from './MemoryModel';
import { memoryDeal } from './MemoryRules';
import { MemoryCard } from './MemoryCard';
import { MemoryPalette as P } from './MemoryPalette';

@Component
export struct MemoryBoard {
  @Prop dark: boolean = false;
  @Prop round: MemoryRound = memoryDeal('journey', 1, 1);
  @Prop boardWidth: number = 330;
  @Prop boardHeight: number = 380;
  @Prop card: number = 70;
  @Prop cardHeight: number = 78;
  @Prop gap: number = 7;
  @Prop pad: number = 12;
  @Prop active: boolean = true;
  @Prop deal: boolean = true;
  @Prop hint: string = MEMORY_HINT;
  @Prop failed: boolean = false;
  tap: (index: number) => void = () => {};
  retry: () => void = () => {};
  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text('第 ' + this.round.number + ' 桌 · 庭院寻双').fontSize(16).minFontSize(12).maxFontSize(16).maxLines(1)
            .fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
          Text(this.round.phase === 'complete' ? '都找到啦，下一桌也在等你' : '记住一眼，下次就会相遇')
            .fontSize(10).fontColor(P.muted(this.dark))
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Image($rawfile(P.icon('pair', this.dark, 'accent'))).width(19).height(19).margin({ right: 5 })
          .accessibilityLevel('no')
        Text(memoryMatched(this.round) + ' / ' + this.round.pairs).fontSize(14).fontFamily('monospace')
          .fontColor(P.accent(this.dark))
      }.width('100%').height(50)
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach([this.round.id], (_id: string) => {
          ForEach(this.round.cards, (picture: number, index: number) => {
            MemoryCard({ dark: this.dark, slot: index, picture: picture, widthVp: this.card, heightVp: this.cardHeight,
              isOpen: memoryOpen(this.round, index), matched: this.round.matched[index], active: this.active,
              deal: this.deal, action: () => this.tap(index)
            }).position({ x: index % 4 * (this.card + this.gap), y: Math.floor(index / 4) * (this.cardHeight + this.gap) })
          }, (_picture: number, index: number) => '' + index)
        }, (id: string) => id)
      }.width(this.boardWidth - this.pad * 2).height(this.round.pairs / 2 * this.cardHeight + (this.round.pairs / 2 - 1) * this.gap)
      Row({ space: 6 }) {
        Image($rawfile(P.icon(this.round.phase === 'complete' ? 'flower' : 'leaf', this.dark, 'accent')))
          .width(16).height(16).accessibilityLevel('no')
        Text(this.hint).fontSize(10).minFontSize(9).maxFontSize(10).maxLines(2)
          .fontColor(this.failed ? P.danger(this.dark) : P.muted(this.dark)).layoutWeight(1)
        if (this.failed) {
          Button('重试').fontSize(12).fontColor(P.accent(this.dark)).backgroundColor(P.soft(this.dark))
            .height(40).width(48).padding(2).borderRadius(12).onClick(this.retry)
        }
      }.width('100%').height(38).accessibilityText(this.hint)
    }.width(this.boardWidth).height(this.boardHeight).padding(this.pad).borderRadius(27)
    .backgroundColor(P.paper(this.dark)).border({ width: 1, color: P.line(this.dark), radius: 27 })
  }
}
