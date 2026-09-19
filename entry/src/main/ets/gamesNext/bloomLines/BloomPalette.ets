import { BLOOM_ASSETS } from './BloomModel';

export class BloomPalette {
  static bg(dark: boolean): string { return dark ? '#181B19' : '#FFF4E4'; }
  static paper(dark: boolean): string { return dark ? '#282E29' : '#FFFCF4'; }
  static soft(dark: boolean): string { return dark ? '#374237' : '#E9EEDB'; }
  static ink(dark: boolean): string { return dark ? '#F8EEDB' : '#3D4938'; }
  static muted(dark: boolean): string { return dark ? '#BBC3AA' : '#78816A'; }
  static accent(dark: boolean): string { return dark ? '#BCD49C' : '#4D7048'; }
  static onAccent(dark: boolean): string { return dark ? '#253A29' : '#FFFCEC'; }
  static line(dark: boolean): string { return dark ? '#4B5747' : '#DDE4C7'; }
  static gold(dark: boolean): string { return dark ? '#F0CD89' : '#976B32'; }
  static danger(dark: boolean): string { return dark ? '#F0B29A' : '#A35741'; }
  static icon(name: string, dark: boolean, tone: string = 'ink'): string {
    return `${BLOOM_ASSETS}icons/${name}_${tone}_${dark ? 'dark' : 'light'}.svg`;
  }
  static scene(name: string, dark: boolean): string {
    return `${BLOOM_ASSETS}scene/${name}_${dark ? 'dark' : 'light'}.svg`;
  }
  static bead(color: number, dark: boolean): string {
    return `${BLOOM_ASSETS}beads/${color}_${dark ? 'dark' : 'light'}.svg`;
  }
}
