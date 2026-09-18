import { GLOW_ASSETS, glowRank } from './GlowModel';

export class GlowPalette {
  static bg(dark: boolean): string { return dark ? '#151916' : '#FFF4E4'; }
  static paper(dark: boolean): string { return dark ? '#252E27' : '#FFFCF3'; }
  static soft(dark: boolean): string { return dark ? '#344136' : '#E8EDD9'; }
  static ink(dark: boolean): string { return dark ? '#F5EBD9' : '#354639'; }
  static muted(dark: boolean): string { return dark ? '#B9C3AE' : '#74816C'; }
  static accent(dark: boolean): string { return dark ? '#B9D5A7' : '#34664D'; }
  static onAccent(dark: boolean): string { return dark ? '#243B2B' : '#FFFDF1'; }
  static line(dark: boolean): string { return dark ? '#485946' : '#DCE3C8'; }
  static gold(dark: boolean): string { return dark ? '#EBC581' : '#936423'; }
  static danger(dark: boolean): string { return dark ? '#F0B19A' : '#A64F39'; }
  static tileInk(value: number, dark: boolean): string {
    const rank = glowRank(value);
    return dark || rank === 5 || rank === 6 || rank === 9 || rank === 10 ? '#FFF7E5' : '#3A4536';
  }
  static icon(name: string, dark: boolean, tone: string = 'ink'): string {
    return `${GLOW_ASSETS}icons/${name}_${tone}_${dark ? 'dark' : 'light'}.svg`;
  }
  static scene(name: string, dark: boolean): string {
    return `${GLOW_ASSETS}scene/${name}_${dark ? 'dark' : 'light'}.svg`;
  }
}
