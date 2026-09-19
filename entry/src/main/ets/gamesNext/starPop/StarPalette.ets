import { STAR_ASSETS } from './StarModel';
export class StarPalette {
  static bg(dark: boolean): string { return dark ? '#1D231C' : '#FFF4E2'; }
  static paper(dark: boolean): string { return dark ? '#2A3128' : '#FFFCF4'; }
  static soft(dark: boolean): string { return dark ? '#38432F' : '#EDF0DA'; }
  static ink(dark: boolean): string { return dark ? '#F7EEDC' : '#443E31'; }
  static muted(dark: boolean): string { return dark ? '#B8C0AA' : '#82775F'; }
  static accent(dark: boolean): string { return dark ? '#BDD59D' : '#497143'; }
  static onAccent(dark: boolean): string { return dark ? '#243922' : '#FFF9EB'; }
  static line(dark: boolean): string { return dark ? '#505B45' : '#EBDABD'; }
  static gold(dark: boolean): string { return dark ? '#EDCB8B' : '#A27434'; }
  static danger(dark: boolean): string { return dark ? '#EFB39B' : '#A6523E'; }
  static icon(name: string, dark: boolean, tone: string = 'ink'): string {
    return `${STAR_ASSETS}icons/${name}_${tone}_${dark ? 'dark' : 'light'}.svg`;
  }
  static scene(name: string, dark: boolean): string { return `${STAR_ASSETS}scene/${name}_${dark ? 'dark' : 'light'}.svg`; }
  static tile(color: number, dark: boolean): string { return `${STAR_ASSETS}tiles/${color}_${dark ? 'dark' : 'light'}.svg`; }
}
