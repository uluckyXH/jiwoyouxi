import { CoopModalTransition } from '../../components/CoopModalTransition';
import { CoopTheme } from '../../design/CoopTheme';
import { TetrisTheme } from './TetrisTheme';

@Component
export struct TetrisPauseOverlay {
  resumeGame: () => void = () => {};
  restartGame: () => void = () => {};

  build() {
    CoopModalTransition({
      maskColor: 'rgba(7,8,18,0.58)',
      panelScaleFrom: 0.96,
      panelOffsetVp: 8
    }) {
      Column({ space: 12 }) {
        Text('方块暂停')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
        Button('继续')
          .width(160)
          .height(42)
          .borderRadius(8)
          .backgroundColor('#ffffff')
          .fontColor(CoopTheme.ink)
          .onClick(() => {
            this.resumeGame();
          })
        Button('重新开始')
          .width(160)
          .height(42)
          .borderRadius(8)
          .backgroundColor(CoopTheme.brand)
          .fontColor('#ffffff')
          .onClick(() => {
            this.restartGame();
          })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')
    }
  }
}

@Component
export struct TetrisResultOverlay {
  @Prop pageWidth: number = 390;
  @Prop score: number = 0;
  @Prop bestScore: number = 0;
  @Prop lines: number = 0;
  @Prop level: number = 1;
  restartGame: () => void = () => {};
  exitToHub: () => void = () => {};

  build() {
    CoopModalTransition({
      maskColor: 'rgba(22,13,8,0.44)',
      panelScaleFrom: 0.96,
      panelOffsetVp: 10
    }) {
      Column({ space: 12 }) {
        Text('游戏结束')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
        Text(`本局 ${this.score} · 最高 ${Math.max(this.bestScore, this.score)}`)
          .fontSize(14)
          .fontColor(CoopTheme.muted)
          .maxLines(1)
          .textAlign(TextAlign.Center)
        Text(`消除 ${this.lines} 行 · 等级 ${this.level}`)
          .fontSize(13)
          .fontColor(CoopTheme.brandDark)
          .maxLines(1)
          .textAlign(TextAlign.Center)
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
          .backgroundColor(TetrisTheme.panelBg)
          .fontColor(CoopTheme.ink)
          .border({ width: 1, color: TetrisTheme.panelBorder })
          .onClick(() => {
            this.exitToHub();
          })
      }
      .width(Math.min(this.pageWidth - 36, 340))
      .padding(18)
      .borderRadius(8)
      .backgroundColor(CoopTheme.glassStrong)
      .border({ width: 1, color: CoopTheme.glassLine })
      .shadow(CoopTheme.shadow)
    }
  }
}
