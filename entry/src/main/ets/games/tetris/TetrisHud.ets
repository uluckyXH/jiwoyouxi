import { MAX_LOCK_RESETS, TETRIS_PHASE_CLEARING, TETRIS_PHASE_LOCKING } from './TetrisTypes';
import { TetrisTheme } from './TetrisTheme';
import { CoopTheme } from '../../design/CoopTheme';

@Component
export struct TetrisStatsPanel {
  @Prop score: number = 0;
  @Prop lines: number = 0;
  @Prop level: number = 1;

  build() {
    Column({ space: 7 }) {
      TetrisStatBox({ label: '分数', value: `${this.score}` })
      TetrisStatBox({ label: '行数', value: `${this.lines}` })
      TetrisStatBox({ label: '等级', value: `${this.level}` })
    }
    .width('100%')
  }
}

@Component
export struct TetrisStatusPanel {
  @Prop phase: number = 1;
  @Prop holdUsed: boolean = false;
  @Prop lastClear: number = 0;
  @Prop combo: number = 0;
  @Prop lockResetCount: number = 0;

  build() {
    Column({ space: 5 }) {
      Text(this.statusLabel())
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.phase === TETRIS_PHASE_LOCKING ? TetrisTheme.lockWarningText : CoopTheme.brandDark)
        .textAlign(TextAlign.Center)
      Text(this.statusDetail())
        .fontSize(10)
        .fontColor(CoopTheme.muted)
        .maxLines(2)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10, left: 5, right: 5 })
    .borderRadius(TetrisTheme.radiusPanel)
    .backgroundColor(this.phase === TETRIS_PHASE_LOCKING ? TetrisTheme.lockWarningBg : TetrisTheme.panelBg)
    .border({ width: 1, color: TetrisTheme.panelBorder })
  }

  private statusLabel(): string {
    if (this.phase === TETRIS_PHASE_LOCKING) {
      return '快落定';
    }
    if (this.phase === TETRIS_PHASE_CLEARING) {
      return '消行中';
    }
    if (this.combo > 1) {
      return '连消';
    }
    if (this.holdUsed) {
      return '暂存已用';
    }
    if (this.lastClear === 4) {
      return '四行消除';
    }
    if (this.lastClear > 0) {
      return '消除成功';
    }
    return '小提示';
  }

  private statusDetail(): string {
    if (this.phase === TETRIS_PHASE_LOCKING) {
      return `还可调 ${Math.max(0, MAX_LOCK_RESETS - this.lockResetCount)} 次`;
    }
    if (this.phase === TETRIS_PHASE_CLEARING) {
      return '正在整理棋盘';
    }
    if (this.combo > 1) {
      return `第 ${this.combo} 次加分`;
    }
    if (this.holdUsed) {
      return '落地后可再换';
    }
    if (this.lastClear === 4) {
      return '一次清四行';
    }
    if (this.lastClear > 0) {
      return `刚清 ${this.lastClear} 行`;
    }
    return '浅色影子是落点';
  }
}

@Component
struct TetrisStatBox {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Column({ space: 4 }) {
      Text(this.label)
        .fontSize(11)
        .fontColor(CoopTheme.muted)
      Text(this.value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
        .maxLines(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 9, bottom: 9, left: 5, right: 5 })
    .borderRadius(TetrisTheme.radiusPanel)
    .backgroundColor(TetrisTheme.panelBg)
    .border({ width: 1, color: TetrisTheme.panelBorder })
  }
}
