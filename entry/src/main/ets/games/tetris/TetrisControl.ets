import { TetrisTheme } from './TetrisTheme';

interface ControlPoint {
  x: number;
  y: number;
}

@Component
export struct TetrisControlPanel {
  @Prop @Watch('handleDisabledChanged') disabled: boolean = false;
  @Prop panelWidth: number = 342;
  @Prop panelHeight: number = 190;
  @Prop buttonWidth: number = 82;
  @Prop buttonHeight: number = 60;
  @Prop buttonGap: number = 14;
  @Prop rotateButtonSize: number = 96;

  moveLeft: () => void = () => {};
  moveRight: () => void = () => {};
  softDrop: () => void = () => {};
  hardDrop: () => void = () => {};
  rotatePiece: () => void = () => {};

  // ↓ 键长按硬降的充能进度，0~1。驱动进度环 + 按钮高亮，引导玩家发现长按硬降。
  @State hardDropCharging: boolean = false;
  @State hardDropProgress: number = 0;
  @State pressedTarget: string = '';

  private moveRepeatTimer: number = -1;
  private controlHoldTimer: number = -1;
  private controlLongTriggered: boolean = false;
  private controlTouchTarget: string = '';

  aboutToDisappear(): void {
    this.stopControlTimers();
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Column({ space: 8 }) {
          Row({ space: this.buttonGap }) {
            this.ControlButton('←', 'left')
            this.ControlButton('→', 'right')
          }
          .justifyContent(FlexAlign.Center)
          this.DownButton()
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        this.RotateButton()
      }
      .width(this.panelWidth)
      .height(this.panelHeight)
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor(TetrisTheme.panelBg)
      .linearGradient(TetrisTheme.controlPanelGradient)
      .borderRadius(TetrisTheme.radiusControl)
      .border({ width: 1, color: TetrisTheme.panelBorder })
      .shadow({
        radius: 24,
        color: 'rgba(47,29,20,0.16)',
        offsetX: 0,
        offsetY: 10
      })
      .alignItems(VerticalAlign.Center)
      .opacity(this.disabled ? 0.58 : 1)
      .onTouch((event: TouchEvent) => {
        this.handleTouch(event);
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 16, right: 16, bottom: 10 })
  }

  @Builder
  ControlButton(label: string, target: string) {
    Stack({ alignContent: Alignment.Center }) {
      Text(label)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(TetrisTheme.controlLabel)
        .textAlign(TextAlign.Center)
      Text('')
        .width(Math.max(24, Math.floor(this.buttonWidth * 0.48)))
        .height(3)
        .borderRadius(2)
        .backgroundColor('rgba(255,255,255,0.86)')
        .position({ x: Math.max(12, Math.floor(this.buttonWidth * 0.24)), y: 9 })
    }
      .width(this.buttonWidth)
      .height(this.buttonHeight)
      .borderRadius(TetrisTheme.radiusButton)
      .backgroundColor(this.pressedTarget === target ? '#F4A62E' : '#FFC74A')
      .linearGradient(this.pressedTarget === target ? TetrisTheme.controlButtonActiveGradient : TetrisTheme.controlButtonGradient)
      .border({ width: 1, color: this.pressedTarget === target ? '#9F571E' : '#B8732C' })
      .shadow({
        radius: this.pressedTarget === target ? 7 : 14,
        color: this.pressedTarget === target ? 'rgba(132,84,32,0.24)' : 'rgba(155,91,25,0.28)',
        offsetX: 0,
        offsetY: this.pressedTarget === target ? 2 : 6
      })
  }

  // ↓ 键：按住时高亮变色 + 350ms 填充进度环，填满即硬降。
  // 进度环同时是操作反馈和「长按硬降」的发现引导。
  @Builder
  DownButton() {
    Stack({ alignContent: Alignment.Center }) {
      Text('↓')
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.hardDropCharging ? '#FFFFFF' : TetrisTheme.controlLabel)
        .textAlign(TextAlign.Center)
      Text('')
        .width(Math.max(24, Math.floor(this.buttonWidth * 0.48)))
        .height(3)
        .borderRadius(2)
        .backgroundColor(this.hardDropCharging ? 'rgba(255,255,255,0.70)' : 'rgba(255,255,255,0.86)')
        .position({ x: Math.max(12, Math.floor(this.buttonWidth * 0.24)), y: 9 })
      // 进度环只在充能时显示，比按钮大一圈，环底透明。
      if (this.hardDropCharging) {
        Progress({ value: this.hardDropProgress * 100, total: 100, type: ProgressType.Ring })
          .width(this.buttonWidth + 14)
          .height(this.buttonHeight + 14)
          .style({ strokeWidth: 3 })
          .color(TetrisTheme.hardDropActive)
          .backgroundColor('rgba(242,95,131,0.18)')
      }
    }
    .width(this.buttonWidth)
    .height(this.buttonHeight)
    .borderRadius(TetrisTheme.radiusButton)
    .backgroundColor(this.hardDropCharging ? TetrisTheme.hardDropActive : TetrisTheme.panelSoftBg)
    .linearGradient(this.hardDropCharging ? TetrisTheme.hardDropGradient : TetrisTheme.controlDownButtonGradient)
    .border({ width: 1, color: this.hardDropCharging ? '#A72F49' : TetrisTheme.panelBorder })
    .shadow({
      radius: this.hardDropCharging ? 18 : 14,
      color: this.hardDropCharging ? 'rgba(206,62,96,0.38)' : 'rgba(106,61,27,0.18)',
      offsetX: 0,
      offsetY: this.hardDropCharging ? 7 : 6
    })
  }

  @Builder
  RotateButton() {
    Stack({ alignContent: Alignment.Center }) {
      Text('↻')
        .fontSize(42)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
      Text('')
        .width(Math.floor(this.rotateButtonSize * 0.44))
        .height(4)
        .borderRadius(2)
        .backgroundColor('rgba(255,255,255,0.42)')
        .position({ x: Math.floor(this.rotateButtonSize * 0.28), y: 16 })
    }
      .width(this.rotateButtonSize)
      .height(this.rotateButtonSize)
      .borderRadius(this.rotateButtonSize / 2)
      .backgroundColor(TetrisTheme.controlBg)
      .linearGradient(this.pressedTarget === 'rotate' ? TetrisTheme.rotateButtonActiveGradient : TetrisTheme.rotateButtonGradient)
      .border({ width: 1, color: 'rgba(255,255,255,0.44)' })
      .shadow({
        radius: this.pressedTarget === 'rotate' ? 14 : 22,
        color: this.pressedTarget === 'rotate' ? 'rgba(172,47,75,0.34)' : 'rgba(206,62,96,0.40)',
        offsetX: 0,
        offsetY: this.pressedTarget === 'rotate' ? 5 : 10
      })
  }

  handleDisabledChanged(): void {
    if (this.disabled) {
      this.stopControlTimers();
    }
  }

  private handleTouch(event: TouchEvent): void {
    if (this.disabled) {
      this.stopControlTimers();
      return;
    }
    const point = this.controlTouchPoint(event);
    if (event.type === TouchType.Down) {
      this.startControlTouch(point.x, point.y);
      return;
    }
    if (event.type === TouchType.Up) {
      this.finishControlTouch(false);
      return;
    }
    if (event.type === TouchType.Cancel) {
      this.finishControlTouch(true);
    }
  }

  private controlTouchPoint(event: TouchEvent): ControlPoint {
    if (event.touches !== undefined && event.touches.length > 0) {
      return { x: event.touches[0].x, y: event.touches[0].y };
    }
    if (event.changedTouches !== undefined && event.changedTouches.length > 0) {
      return { x: event.changedTouches[0].x, y: event.changedTouches[0].y };
    }
    return { x: 0, y: 0 };
  }

  private startControlTouch(x: number, y: number): void {
    this.stopControlTimers();
    this.controlTouchTarget = this.controlTargetAt(x, y);
    this.pressedTarget = this.controlTouchTarget;
    this.controlLongTriggered = false;
    if (this.controlTouchTarget === 'left' || this.controlTouchTarget === 'right') {
      this.controlHoldTimer = setTimeout(() => {
        this.controlHoldTimer = -1;
        this.controlLongTriggered = true;
        this.triggerControlTarget(this.controlTouchTarget);
        this.moveRepeatTimer = setInterval(() => {
          this.triggerControlTarget(this.controlTouchTarget);
        }, 80);
      }, 180);
      return;
    }
    if (this.controlTouchTarget === 'down') {
      // 进度环充能：350ms 线性填满，填满即硬降。
      this.hardDropCharging = true;
      this.hardDropProgress = 0;
      this.getUIContext().animateTo({ duration: 350, curve: Curve.Linear, delay: 0, iterations: 1, playMode: PlayMode.Normal }, () => {
        this.hardDropProgress = 1;
      });
      this.controlHoldTimer = setTimeout(() => {
        this.controlHoldTimer = -1;
        this.controlLongTriggered = true;
        this.stopHardDropCharge();
        this.hardDrop();
      }, 350);
    }
  }

  private finishControlTouch(cancelled: boolean): void {
    const target = this.controlTouchTarget;
    const wasLong = this.controlLongTriggered;
    this.clearControlHoldTimer();
    this.stopRepeatMove();
    this.stopHardDropCharge();
    this.controlTouchTarget = '';
    this.pressedTarget = '';
    this.controlLongTriggered = false;
    if (cancelled || wasLong) {
      return;
    }
    this.triggerControlTarget(target);
  }

  // 停止硬降充能：进度环立即归零，不再触发硬降。
  private stopHardDropCharge(): void {
    if (this.hardDropCharging) {
      this.hardDropCharging = false;
      // 不用动画，直接归零，避免松手后环还慢慢退。
      this.hardDropProgress = 0;
    }
  }

  private triggerControlTarget(target: string): void {
    if (target === 'left') {
      this.moveLeft();
      return;
    }
    if (target === 'right') {
      this.moveRight();
      return;
    }
    if (target === 'down') {
      this.softDrop();
      return;
    }
    if (target === 'rotate') {
      this.rotatePiece();
    }
  }

  private controlTargetAt(x: number, y: number): string {
    const rotateStart = Math.max(0, this.panelWidth - this.rotateButtonSize - 26);
    if (x >= rotateStart) {
      return 'rotate';
    }
    if (y >= this.panelHeight * 0.55) {
      return 'down';
    }
    const directionWidth = Math.max(1, rotateStart - 14);
    return x < directionWidth / 2 ? 'left' : 'right';
  }

  private clearControlHoldTimer(): void {
    if (this.controlHoldTimer !== -1) {
      clearTimeout(this.controlHoldTimer);
      this.controlHoldTimer = -1;
    }
  }

  private stopRepeatMove(): void {
    if (this.moveRepeatTimer !== -1) {
      clearInterval(this.moveRepeatTimer);
      this.moveRepeatTimer = -1;
    }
  }

  private stopControlTimers(): void {
    this.clearControlHoldTimer();
    this.stopRepeatMove();
    this.stopHardDropCharge();
    this.controlTouchTarget = '';
    this.pressedTarget = '';
    this.controlLongTriggered = false;
  }
}
