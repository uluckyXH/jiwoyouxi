import { RpsBattleTheme } from './RpsBattleTheme';
import { RpsBattleFactionInfo, RpsBattleModeKey, RpsBattleResult, RpsBattleThemeKey } from './RpsBattleTypes';
import { rpsBattleCountValue, rpsBattleInitialResult } from './RpsBattleRules';
import { rpsBattleThemeFactionInfo, rpsBattleThemeFactions } from './RpsBattleThemeConfig';

@Component
export struct RpsBattlePauseOverlay {
  @Prop exitConfirmationPending: boolean = false;
  resumeGame: () => void = () => {};
  restartGame: () => void = () => {};
  backToSetup: () => void = () => {};
  exitToHub: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 12 }) {
        Text(this.titleText())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Text(this.subtitleText())
          .fontSize(12)
          .fontColor(RpsBattleTheme.muted)
          .textAlign(TextAlign.Center)
          .maxLines(2)
        this.PrimaryActionButton('继续对局', () => {
          this.resumeGame();
        })
        this.FullSecondaryActionButton('重新开始', () => {
          this.restartGame();
        })
        Row({ space: 8 }) {
          this.SecondaryActionButton('重新选择', () => {
            this.backToSetup();
          })
          this.ExitActionButton(this.exitConfirmationPending ? '确认回大厅' : '回大厅', () => {
            this.exitToHub();
          })
        }
        .width('100%')
      }
      .width('84%')
      .padding({ left: 16, right: 16, top: 18, bottom: 18 })
      .borderRadius(8)
      .backgroundColor(RpsBattleTheme.panelBg)
      .border({ width: 1, color: RpsBattleTheme.panelLine })
      .shadow({
        radius: 18,
        color: RpsBattleTheme.panelShadowColor,
        offsetX: 0,
        offsetY: 8
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(RpsBattleTheme.overlayBg)
  }

  @Builder
  PrimaryActionButton(label: string, action: () => void) {
    Button(label)
      .width('100%')
      .height(42)
      .borderRadius(8)
      .fontWeight(FontWeight.Bold)
      .fontColor(RpsBattleTheme.primaryButtonText)
      .backgroundColor(RpsBattleTheme.primaryButtonBg)
      .onClick(() => {
        action();
      })
  }

  @Builder
  FullSecondaryActionButton(label: string, action: () => void) {
    Button(label)
      .width('100%')
      .height(40)
      .borderRadius(8)
      .fontColor(RpsBattleTheme.topButtonText)
      .backgroundColor(RpsBattleTheme.topButtonBg)
      .border({ width: 1, color: RpsBattleTheme.topButtonLine })
      .onClick(() => {
        action();
      })
  }

  @Builder
  SecondaryActionButton(label: string, action: () => void) {
    Button(label)
      .layoutWeight(1)
      .height(40)
      .borderRadius(8)
      .fontColor(RpsBattleTheme.topButtonText)
      .backgroundColor(RpsBattleTheme.topButtonBg)
      .border({ width: 1, color: RpsBattleTheme.topButtonLine })
      .onClick(() => {
        action();
      })
  }

  @Builder
  ExitActionButton(label: string, action: () => void) {
    Button(label)
      .layoutWeight(1)
      .height(40)
      .borderRadius(8)
      .fontWeight(FontWeight.Bold)
      .fontColor(RpsBattleTheme.dangerButtonText)
      .backgroundColor(RpsBattleTheme.dangerButtonBg)
      .onClick(() => {
        action();
      })
  }

  private titleText(): string {
    return this.exitConfirmationPending ? '确认要返回大厅吗？' : '已暂停';
  }

  private subtitleText(): string {
    return this.exitConfirmationPending ? '返回后本局不会保留进度。' : '本局进度已暂停，可继续或调整对局。';
  }
}

@Component
export struct RpsBattleResultOverlay {
  @Prop result: RpsBattleResult = rpsBattleInitialResult('rock');
  @Prop themeKey: RpsBattleThemeKey = 'rps';
  @Prop modeKey: RpsBattleModeKey = 'classic';
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
          ForEach(rpsBattleThemeFactions(this.themeKey), (item: RpsBattleFactionInfo) => {
            this.CountColumn(item)
          }, (item: RpsBattleFactionInfo) => item.id)
        }
        .width('100%')
        Row({ space: 8 }) {
          this.MetaPill('胜因', this.resultReasonText())
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
        color: RpsBattleTheme.panelShadowColor,
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
      color: this.result.winner === item.id ? item.color : RpsBattleTheme.softLine
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
    .backgroundColor(RpsBattleTheme.optionBg)
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
    const winner = rpsBattleThemeFactionInfo(this.themeKey, this.result.winner);
    return `${winner.symbol} ${winner.label}胜利`;
  }

  private resultColor(): string {
    if (this.result.winner === '') {
      return RpsBattleTheme.pageInk;
    }
    return rpsBattleThemeFactionInfo(this.themeKey, this.result.winner).textColor;
  }

  private supportText(): string {
    const support = rpsBattleThemeFactionInfo(this.themeKey, this.result.supportFaction);
    if (this.result.winner === '') {
      return `支持 ${support.label} · 本局未分胜负`;
    }
    return this.result.supportWon ? `支持 ${support.label} · 猜中了` : `支持 ${support.label} · 下局再战`;
  }

  private resultReasonText(): string {
    if (this.modeKey === 'zones') {
      if (this.result.finishReason === 'zone') {
        return '据点满分';
      }
      if (this.result.finishReason === 'time') {
        return '据点领先';
      }
      if (this.result.finishReason === 'draw') {
        return '据点平分';
      }
    }
    if (this.result.finishReason === 'clear') {
      return '清场';
    }
    if (this.result.finishReason === 'time') {
      return '限时领先';
    }
    return '平局';
  }
}
