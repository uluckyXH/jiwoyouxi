// 俄罗斯方块游戏私有视觉参数。
// 收敛原有 TetrisPage 散落的颜色与尺寸，复用 CoopTheme token。
// 仅放视觉数值，不放业务判断。

export class TetrisTheme {
  // 棋盘
  static readonly boardBg: string = '#3A2114';
  static readonly boardBgAlt: string = '#422819';
  static readonly boardCellBorder: string = 'rgba(30,14,8,0.42)';
  static readonly boardCellSoftLine: string = 'rgba(255,214,154,0.055)';
  static readonly fixedCellBorder: string = 'rgba(84,35,17,0.46)';
  static readonly ghostColor: string = 'rgba(255,236,202,0.30)';
  static readonly boardFrameBg: string = '#A76535';
  static readonly boardFrameBorder: string = '#7B4324';
  static readonly boardInsetBg: string = '#2A160E';
  static readonly boardInsetBorder: string = '#5F331C';
  static readonly boardFrameGradient: LinearGradient = {
    angle: 135,
    colors: [['#D2935C', 0], ['#9B572D', 0.55], ['#6F3B22', 1]]
  };
  static readonly boardLeftEdgeGradient: LinearGradient = {
    angle: 90,
    colors: [['rgba(88,38,18,0.44)', 0], ['rgba(255,211,144,0.26)', 1]]
  };
  static readonly boardRightEdgeGradient: LinearGradient = {
    angle: 90,
    colors: [['rgba(255,211,144,0.22)', 0], ['rgba(72,29,13,0.48)', 1]]
  };

  // 面板
  static readonly panelBg: string = '#FFF8EA';
  static readonly panelSoftBg: string = '#FFF6E5';
  static readonly panelBorder: string = '#D9AA75';
  static readonly controlBg: string = '#F25F83';
  static readonly controlLabel: string = '#552819';
  static readonly topBarBg: string = '#FFF8EA';
  static readonly topBarBorder: string = '#D9AA75';
  static readonly topButtonBorder: string = '#C99D6D';
  static readonly topButtonText: string = '#552819';
  static readonly pauseButtonBorder: string = '#9B2E3E';
  static readonly pauseButtonText: string = '#7B2230';
  static readonly topBarGradient: LinearGradient = {
    angle: 180,
    colors: [['#FFFDF5', 0], ['#FFEFD5', 1]]
  };
  static readonly topButtonGradient: LinearGradient = {
    angle: 180,
    colors: [['#FFFDF5', 0], ['#FFE8C0', 1]]
  };
  static readonly pauseButtonGradient: LinearGradient = {
    angle: 180,
    colors: [['#FF94AA', 0], ['#F15F83', 0.62], ['#DD496D', 1]]
  };
  static readonly controlPanelGradient: LinearGradient = {
    angle: 180,
    colors: [['#FFFDF5', 0], ['#FFEFD5', 1]]
  };
  static readonly controlButtonGradient: LinearGradient = {
    angle: 180,
    colors: [['#FFECA8', 0], ['#FFC74A', 0.62], ['#F4A62E', 1]]
  };
  static readonly controlButtonActiveGradient: LinearGradient = {
    angle: 180,
    colors: [['#FFD879', 0], ['#F4A62E', 1]]
  };
  static readonly controlDownButtonGradient: LinearGradient = {
    angle: 180,
    colors: [['#FFFDF5', 0], ['#FFEFD5', 1]]
  };
  static readonly rotateButtonGradient: LinearGradient = {
    angle: 180,
    colors: [['#FF9CAD', 0], ['#F25F83', 0.62], ['#D94166', 1]]
  };
  static readonly rotateButtonActiveGradient: LinearGradient = {
    angle: 180,
    colors: [['#FF7F98', 0], ['#D94166', 1]]
  };
  static readonly hardDropGradient: LinearGradient = {
    angle: 180,
    colors: [['#FF9CAD', 0], ['#F25F83', 0.62], ['#D94166', 1]]
  };

  // 状态色
  static readonly lockWarningBg: string = '#FFE7DD';
  static readonly lockWarningText: string = '#B42318';
  // 硬降充能：与旋转键同色系，保持控制面板视觉统一。
  static readonly hardDropActive: string = '#F25F83';
  // 消行扫光：暖金色，区别于方块颜色但不做复古像素闪烁。
  static readonly clearSweepColor: string = '#FFE9A8';
  static readonly clearSweepCore: string = 'rgba(255,255,255,0.96)';
  static readonly clearSweepGlow: string = 'rgba(255,214,116,0.52)';
  static readonly clearSweepDurationMs: number = 320;

  // 页面渐变背景
  static readonly pageGradient: LinearGradient = {
    angle: 180,
    colors: [['#fff8ea', 0], ['#f7efe0', 0.52], ['#eef8ff', 1]]
  };

  // 圆角
  static readonly radiusCell: number = 3;
  static readonly radiusPanel: number = 20;
  static readonly radiusBoard: number = 14;
  static readonly radiusControl: number = 32;
  static readonly radiusButton: number = 24;

  // 尺寸比例（用于根据页面尺寸派生）
  static readonly leftPanelRatio: number = 0.17;
  static readonly rightPanelRatio: number = 0.18;
  static readonly controlPanelRatio: number = 0.245;
  static readonly minCell: number = 14;
  static readonly maxCell: number = 18;
}
