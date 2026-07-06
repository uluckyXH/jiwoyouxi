// 俄罗斯方块游戏私有视觉参数。
// 收敛原有 TetrisPage 散落的颜色与尺寸，复用 CoopTheme token。
// 仅放视觉数值，不放业务判断。

export class TetrisTheme {
  // 棋盘
  static readonly boardBg: string = '#151D24';
  static readonly boardBgAlt: string = '#121A21';
  static readonly boardCellBorder: string = '#2B3640';
  static readonly fixedCellBorder: string = 'rgba(255,255,255,0.30)';
  static readonly ghostColor: string = '#3A4A54';
  static readonly boardFrameBg: string = '#FFF8EA';
  static readonly boardFrameBorder: string = '#E9D6B8';

  // 面板
  static readonly panelBg: string = '#FFF8EA';
  static readonly panelSoftBg: string = '#FFF6E5';
  static readonly panelBorder: string = '#F2DFBF';
  static readonly controlBg: string = '#7B61FF';
  static readonly controlLabel: string = '#3A2418';
  static readonly topBarBg: string = '#FFFCF6';
  static readonly topBarBorder: string = '#E7D0B2';
  static readonly topBarGradient: LinearGradient = {
    angle: 180,
    colors: [['#FFFEFA', 0], ['#FFF6E8', 1]]
  };
  static readonly controlPanelGradient: LinearGradient = {
    angle: 180,
    colors: [['#FFFDF7', 0], ['#FFF1DA', 1]]
  };
  static readonly controlButtonGradient: LinearGradient = {
    angle: 180,
    colors: [['#FFFFFF', 0], ['#FFF0D8', 1]]
  };
  static readonly controlButtonActiveGradient: LinearGradient = {
    angle: 180,
    colors: [['#FFEAC3', 0], ['#FFD28B', 1]]
  };
  static readonly rotateButtonGradient: LinearGradient = {
    angle: 180,
    colors: [['#8F78FF', 0], ['#684AEF', 1]]
  };
  static readonly rotateButtonActiveGradient: LinearGradient = {
    angle: 180,
    colors: [['#A390FF', 0], ['#563BE0', 1]]
  };
  static readonly hardDropGradient: LinearGradient = {
    angle: 180,
    colors: [['#8F78FF', 0], ['#684AEF', 1]]
  };

  // 状态色
  static readonly lockWarningBg: string = '#FFE7DD';
  static readonly lockWarningText: string = '#B42318';
  // 硬降充能：与旋转键同色系，保持控制面板视觉统一。
  static readonly hardDropActive: string = '#7B61FF';
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
  static readonly maxCell: number = 24;
}
