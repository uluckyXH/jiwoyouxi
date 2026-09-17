import { CoopTheme } from '../../design/CoopTheme';

export class MarketPalette {
  static background(dark: boolean): string { return dark ? '#101110' : CoopTheme.appSurface; }
  static surface(dark: boolean): string { return dark ? '#25251f' : '#fffdf6'; }
  static soft(dark: boolean): string { return dark ? '#303126' : '#eeeeda'; }
  static ink(dark: boolean): string { return dark ? '#fff2df' : CoopTheme.ink; }
  static muted(dark: boolean): string { return dark ? '#c0b59f' : '#81735d'; }
  static line(dark: boolean): string { return dark ? '#454334' : '#e7dcc5'; }
  static accent(dark: boolean): string { return dark ? '#b6d39a' : '#527342'; }
  static gold(dark: boolean): string { return dark ? '#ffd083' : '#9b6324'; }
  static danger(dark: boolean): string { return dark ? '#ffa38f' : '#b34939'; }
  static primary(dark: boolean): string { return dark ? '#b6d39a' : '#527342'; }
  static onPrimary(dark: boolean): string { return dark ? '#25351f' : '#fff9e9'; }
  static icon(name: string, dark: boolean, tone: string = ''): string {
    return `gamesNext/fruitMarket/icons/${name}_${tone.length > 0 ? tone + '_' : ''}${dark ? 'dark' : 'light'}.svg`;
  }
}
