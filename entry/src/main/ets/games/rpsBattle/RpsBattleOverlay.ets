import { RpsBattleTheme } from './RpsBattleTheme';
import { RPS_BATTLE_FACTIONS, RpsBattleFactionInfo, RpsBattleResult } from './RpsBattleTypes';
import { rpsBattleCountValue, rpsBattleFactionInfo, rpsBattleInitialResult } from './RpsBattleRules';

@Component
export struct RpsBattlePauseOverlay {
  resumeGame: () => void = () => {};
  restartGame: () => void = () => {};
  exitToHub: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 12 }) {
        Text('已暂停')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .maxLines(1)
        this.ActionButton('继续', () => {
          this.resumeGame();
        })
        this.ActionButton('重新开始', () => {
          this.restartGame();
        })
        this.ActionButton('回大厅', () => {
          this.exitToHub();
        })
      }
      .width(220)
      .padding({ left: 16, right: 16, top: 18, bottom: 18 })
      .borderRadius(12)
      .backgroundColor(RpsBattleTheme.panelBg)
      .border({ width: 1, color: RpsBattleTheme.panelLine })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(RpsBattleTheme.overlayBg)
  }

  @Builder
  ActionButton(label: string, action: () => void) {
    Button(label)
      .width('100%')
      .height(42)
      .borderRadius(9)
      .fontColor(RpsBattleTheme.primaryButtonText)
      .backgroundColor(RpsBattleTheme.primaryButtonBg)
      .onClick(() => {
        action();
      })
  }
}

@Component
export struct RpsBattleResultOverlay {
  @Prop result: RpsBattleResult = rpsBattleInitialResult('rock');
  restartGame: () => void = () => {};
  backToSetup: () => void = () => {};
  exitToHub: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 12 }) {
        Text(this.resultTitle())
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.resultColor())
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Text(this.supportText())
          .fontSize(14)
          .fontColor(RpsBattleTheme.muted)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Row({ space: 8 }) {
          ForEach(RPS_BATTLE_FACTIONS, (item: RpsBattleFactionInfo) => {
            this.CountColumn(item)
          }, (item: RpsBattleFactionInfo) => item.id)
        }
        .width('100%')
        Row({ space: 8 }) {
          this.MetaPill('转阵', `${this.result.conversions}`)
          this.MetaPill('用时', `${Math.ceil(this.result.elapsedSec)}s`)
        }
        .width('100%')
        this.ActionButton('再来一局', () => {
          this.restartGame();
        })
        Row({ space: 8 }) {
          this.SecondaryButton('重新选择', () => {
            this.backToSetup();
          })
          this.SecondaryButton('回大厅', () => {
            this.exitToHub();
          })
        }
        .width('100%')
      }
      .width('86%')
      .padding({ left: 16, right: 16, top: 18, bottom: 18 })
      .borderRadius(12)
      .backgroundColor(RpsBattleTheme.panelBg)
      .border({ width: 1, color: RpsBattleTheme.panelLine })
      .shadow({
        radius: 18,
        color: 'rgba(42,26,16,0.22)',
        offsetX: 0,
        offsetY: 8
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(RpsBattleTheme.overlayBg)
  }

  @Builder
  CountColumn(item: RpsBattleFactionInfo) {
    Column({ space: 4 }) {
      Text(item.symbol)
        .fontSize(20)
        .height(26)
        .textAlign(TextAlign.Center)
      Text(`${rpsBattleCountValue(this.result.counts, item.id)}`)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.textColor)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(58)
    .borderRadius(9)
    .backgroundColor(item.softColor)
    .border({
      width: this.result.winner === item.id ? 2 : 1,
      color: this.result.winner === item.id ? item.color : 'rgba(86,55,35,0.10)'
    })
  }

  @Builder
  MetaPill(label: string, value: string) {
    Row({ space: 5 }) {
      Text(label)
        .fontSize(12)
        .fontColor(RpsBattleTheme.muted)
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(32)
    .borderRadius(8)
    .backgroundColor('#fff8e8')
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  @Builder
  ActionButton(label: string, action: () => void) {
    Button(label)
      .width('100%')
      .height(44)
      .borderRadius(9)
      .fontWeight(FontWeight.Bold)
      .fontColor(RpsBattleTheme.primaryButtonText)
      .backgroundColor(RpsBattleTheme.primaryButtonBg)
      .onClick(() => {
        action();
      })
  }

  @Builder
  SecondaryButton(label: string, action: () => void) {
    Button(label)
      .layoutWeight(1)
      .height(40)
      .borderRadius(9)
      .fontColor(RpsBattleTheme.topButtonText)
      .backgroundColor(RpsBattleTheme.topButtonBg)
      .border({ width: 1, color: RpsBattleTheme.topButtonLine })
      .onClick(() => {
        action();
      })
  }

  private resultTitle(): string {
    if (this.result.winner === '') {
      return '平局';
    }
    const winner = rpsBattleFactionInfo(this.result.winner);
    return `${winner.symbol} ${winner.label}胜利`;
  }

  private resultColor(): string {
    if (this.result.winner === '') {
      return RpsBattleTheme.pageInk;
    }
    return rpsBattleFactionInfo(this.result.winner).textColor;
  }

  private supportText(): string {
    const support = rpsBattleFactionInfo(this.result.supportFaction);
    if (this.result.winner === '') {
      return `支持 ${support.label} · 本局未分胜负`;
    }
    return this.result.supportWon ? `支持 ${support.label} · 猜中了` : `支持 ${support.label} · 下局再战`;
  }
}
