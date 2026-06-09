import { CoopTheme } from '../../design/CoopTheme';
import { MinesweeperTheme } from './MinesweeperTheme';

@Component
export struct MinesweeperResultOverlay {
  @Prop win: boolean = false;
  @Prop pageWidth: number = 390;
  @Prop elapsedText: string = '00:00';
  @Prop currentScore: number = 0;
  @Prop bestScore: number = 0;
  restartGame: () => void = () => {};
  exitToHub: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      Text(this.win ? MinesweeperTheme.winTitle : MinesweeperTheme.loseTitle)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
      Text(`用时 ${this.elapsedText} · 得分 ${this.currentScore} · 最高 ${Math.max(this.bestScore, this.currentScore)}`)
        .fontSize(14)
        .fontColor(CoopTheme.muted)
      Button('再来一局')
        .width('100%')
        .height(44)
        .borderRadius(8)
        .backgroundColor(CoopTheme.ink)
        .fontColor('#ffffff')
        .onClick(() => {
          this.restartGame();
        })
      Button('回大厅')
        .width('100%')
        .height(40)
        .borderRadius(8)
        .backgroundColor(CoopTheme.panel)
        .fontColor(CoopTheme.ink)
        .border({ width: 1, color: CoopTheme.glassLine })
        .onClick(() => {
          this.exitToHub();
        })
    }
    .width(Math.min(this.pageWidth - 36, 350))
    .padding(18)
    .borderRadius(8)
    .backgroundColor(CoopTheme.glassStrong)
    .border({ width: 1, color: CoopTheme.glassLine })
    .shadow(CoopTheme.shadow)
  }
}
