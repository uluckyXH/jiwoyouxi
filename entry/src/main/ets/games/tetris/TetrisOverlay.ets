import { CoopModalTransition } from '../../components/CoopModalTransition';
import { TetrisTheme } from './TetrisTheme';

@Component
export struct TetrisPauseOverlay {
  @Prop pageWidth: number = 390;
  resumeGame: () => void = () => {};
  restartGame: () => void = () => {};

  build() {
    CoopModalTransition({
      maskColor: 'rgba(41,21,11,0.38)',
      panelScaleFrom: 0.96,
      panelOffsetVp: 8
    }) {
      Column({ space: 14 }) {
        Text('方块暂停')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(TetrisTheme.controlLabel)
        Text('休息一下，当前局面已经帮你停住了。')
          .fontSize(14)
          .fontColor('#6A452F')
          .textAlign(TextAlign.Center)
          .maxLines(2)
        Text('继续游戏')
          .width('100%')
          .height(42)
          .borderRadius(22)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(TetrisTheme.pauseButtonText)
          .textAlign(TextAlign.Center)
          .backgroundColor(TetrisTheme.controlBg)
          .linearGradient(TetrisTheme.pauseButtonGradient)
          .border({ width: 1, color: TetrisTheme.pauseButtonBorder })
          .onClick(() => {
            this.resumeGame();
          })
        Text('重新开始')
          .width('100%')
          .height(42)
          .borderRadius(22)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(TetrisTheme.controlLabel)
          .textAlign(TextAlign.Center)
          .backgroundColor(TetrisTheme.panelBg)
          .linearGradient(TetrisTheme.topButtonGradient)
          .border({ width: 1, color: TetrisTheme.topButtonBorder })
          .onClick(() => {
            this.restartGame();
          })
      }
      .width(Math.min(this.pageWidth - 42, 320))
      .padding({ left: 18, right: 18, top: 20, bottom: 18 })
      .borderRadius(24)
      .backgroundColor(TetrisTheme.panelBg)
      .linearGradient(TetrisTheme.controlPanelGradient)
      .border({ width: 2, color: TetrisTheme.panelBorder })
      .shadow({
        radius: 24,
        color: 'rgba(83,43,18,0.22)',
        offsetX: 0,
        offsetY: 10
      })
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
      maskColor: 'rgba(41,21,11,0.38)',
      panelScaleFrom: 0.96,
      panelOffsetVp: 8
    }) {
      Column({ space: 14 }) {
        Text('游戏结束')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(TetrisTheme.controlLabel)
        Text(`本局 ${this.score}`)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(TetrisTheme.pauseButtonText)
          .maxLines(1)
          .textAlign(TextAlign.Center)
        Text(`最高 ${Math.max(this.bestScore, this.score)} · 消除 ${this.lines} 行 · 等级 ${this.level}`)
          .fontSize(14)
          .fontColor('#6A452F')
          .maxLines(1)
          .textAlign(TextAlign.Center)
        Text('再来一局')
          .width('100%')
          .height(42)
          .borderRadius(22)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(TetrisTheme.pauseButtonText)
          .textAlign(TextAlign.Center)
          .backgroundColor(TetrisTheme.controlBg)
          .linearGradient(TetrisTheme.pauseButtonGradient)
          .border({ width: 1, color: TetrisTheme.pauseButtonBorder })
          .onClick(() => {
            this.restartGame();
          })
        Text('回大厅')
          .width('100%')
          .height(42)
          .borderRadius(22)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(TetrisTheme.controlLabel)
          .textAlign(TextAlign.Center)
          .backgroundColor(TetrisTheme.panelBg)
          .linearGradient(TetrisTheme.topButtonGradient)
          .border({ width: 1, color: TetrisTheme.topButtonBorder })
          .onClick(() => {
            this.exitToHub();
          })
      }
      .width(Math.min(this.pageWidth - 42, 320))
      .padding({ left: 18, right: 18, top: 20, bottom: 18 })
      .borderRadius(24)
      .backgroundColor(TetrisTheme.panelBg)
      .linearGradient(TetrisTheme.controlPanelGradient)
      .border({ width: 2, color: TetrisTheme.panelBorder })
      .shadow({
        radius: 24,
        color: 'rgba(83,43,18,0.22)',
        offsetX: 0,
        offsetY: 10
      })
    }
  }
}

@Component
export struct TetrisExitConfirmOverlay {
  @Prop pageWidth: number = 390;
  cancelExit: () => void = () => {};
  confirmExit: () => void = () => {};

  build() {
    CoopModalTransition({
      maskColor: 'rgba(41,21,11,0.38)',
      panelScaleFrom: 0.96,
      panelOffsetVp: 8
    }) {
      Column({ space: 14 }) {
        Text('离开本局？')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(TetrisTheme.controlLabel)
        Text('当前方块进度会结束，分数不会再继续累计。')
          .fontSize(14)
          .fontColor('#6A452F')
          .textAlign(TextAlign.Center)
          .maxLines(2)
        Row({ space: 10 }) {
          Text('继续游戏')
            .height(42)
            .layoutWeight(1)
            .borderRadius(22)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TetrisTheme.controlLabel)
            .textAlign(TextAlign.Center)
            .backgroundColor(TetrisTheme.panelBg)
            .linearGradient(TetrisTheme.topButtonGradient)
            .border({ width: 1, color: TetrisTheme.topButtonBorder })
            .onClick(() => {
              this.cancelExit();
            })
          Text('回大厅')
            .height(42)
            .layoutWeight(1)
            .borderRadius(22)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(TetrisTheme.pauseButtonText)
            .textAlign(TextAlign.Center)
            .backgroundColor(TetrisTheme.controlBg)
            .linearGradient(TetrisTheme.pauseButtonGradient)
            .border({ width: 1, color: TetrisTheme.pauseButtonBorder })
            .onClick(() => {
              this.confirmExit();
            })
        }
        .width('100%')
      }
      .width(Math.min(this.pageWidth - 42, 320))
      .padding({ left: 18, right: 18, top: 20, bottom: 18 })
      .borderRadius(24)
      .backgroundColor(TetrisTheme.panelBg)
      .linearGradient(TetrisTheme.controlPanelGradient)
      .border({ width: 2, color: TetrisTheme.panelBorder })
      .shadow({
        radius: 24,
        color: 'rgba(83,43,18,0.22)',
        offsetX: 0,
        offsetY: 10
      })
    }
  }
}
