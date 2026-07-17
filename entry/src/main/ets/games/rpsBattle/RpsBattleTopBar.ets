import { RpsBattleTheme } from './RpsBattleTheme';
import { RpsBattlePhase } from './RpsBattleTypes';

const RPS_BATTLE_TOP_BAR_CONTENT_PADDING_TOP: number = 34;
const RPS_BATTLE_TOP_BAR_HEIGHT: number = 88;
const RPS_BATTLE_TOP_ACTION_GROUP_WIDTH: number = 114;
const RPS_BATTLE_TOP_ACTION_BUTTON_WIDTH: number = 54;

@Component
export struct RpsBattleTopBar {
  @Prop phase: RpsBattlePhase = 'setup';
  requestExit: () => void = () => {};
  restartGame: () => void = () => {};
  pauseGame: () => void = () => {};
  resumeGame: () => void = () => {};

  build() {
    Row({ space: 8 }) {
      this.TopBarButton('大厅', false, 66, () => {
        this.requestExit();
      })
      Text('石头剪刀布大作战')
        .fontSize(this.titleFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.topButtonText)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .layoutWeight(1)
      if (this.phase === 'countdown' || this.phase === 'playing' || this.phase === 'paused') {
        Row({ space: 6 }) {
          this.TopBarButton('重开', false, RPS_BATTLE_TOP_ACTION_BUTTON_WIDTH, () => {
            this.restartGame();
          })
          if (this.phase === 'playing' || this.phase === 'paused') {
            this.TopBarButton(this.phase === 'paused' ? '继续' : '暂停', this.phase === 'playing',
              RPS_BATTLE_TOP_ACTION_BUTTON_WIDTH, () => {
              if (this.phase === 'paused') {
                this.resumeGame();
              } else {
                this.pauseGame();
              }
            })
          }
        }
        .width(RPS_BATTLE_TOP_ACTION_GROUP_WIDTH)
        .height(36)
        .justifyContent(FlexAlign.End)
      } else {
        Blank()
          .width(66)
          .height(36)
      }
    }
    .width('100%')
    .height(RPS_BATTLE_TOP_BAR_HEIGHT)
    .padding({ left: 12, right: 12, top: RPS_BATTLE_TOP_BAR_CONTENT_PADDING_TOP })
    .backgroundColor(RpsBattleTheme.topBarBg)
  }

  @Builder
  TopBarButton(label: string, primary: boolean, widthValue: number, action: () => void) {
    Row() {
      Text(label)
        .width('100%')
        .fontSize(this.buttonFontSize(label, widthValue))
        .fontWeight(FontWeight.Bold)
        .fontColor(primary ? RpsBattleTheme.primaryButtonText : RpsBattleTheme.topButtonText)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .width(widthValue)
    .height(36)
    .borderRadius(8)
    .backgroundColor(primary ? RpsBattleTheme.primaryButtonBg : RpsBattleTheme.topButtonBg)
    .border({ width: 1, color: RpsBattleTheme.topButtonLine })
    .onClick(() => {
      action();
    })
  }

  private buttonFontSize(label: string, widthValue: number): number {
    if (widthValue <= RPS_BATTLE_TOP_ACTION_BUTTON_WIDTH && label.length >= 2) {
      return 13;
    }
    return 14;
  }

  private titleFontSize(): number {
    return 16;
  }
}
