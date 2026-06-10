export class MinesweeperTheme {
  static readonly winTitle: string = '鸡窝安全！';
  static readonly loseTitle: string = '踩到鸡雷了！';
  static readonly pageTint: string = 'rgba(255,248,232,0.16)';
  static readonly hudBg: string = 'rgba(255,244,214,0.84)';
  static readonly hudLine: string = 'rgba(128,81,34,0.20)';
  static readonly hudShadow: string = 'rgba(94,55,19,0.12)';
  static readonly boardBg: string = '#8a5a2b';
  static readonly boardBorder: string = '#6b3f1d';
  static readonly openCellBg: string = '#d8b98a';
  static readonly boomCellBg: string = '#d77254';
  static readonly closedCellBg: string = '#e8c85f';
  static readonly closedCellBorder: string = 'rgba(105,69,28,0.30)';
  static readonly flagColor: string = '#c64b31';

  static numberColor(value: number): string {
    if (value === 1) return '#3577b8';
    if (value === 2) return '#4f8f3d';
    if (value === 3) return '#b84d3d';
    if (value === 4) return '#7252a3';
    if (value === 5) return '#7c5630';
    if (value === 6) return '#3f9190';
    if (value === 7) return '#4b3827';
    return '#8b7a62';
  }
}

