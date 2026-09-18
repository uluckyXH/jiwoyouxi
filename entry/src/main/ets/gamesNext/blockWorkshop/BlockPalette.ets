import { CoopTheme } from '../../design/CoopTheme';
import { BLOCK_ASSETS } from './BlockModel';

export class BlockPalette {
  static background(dark: boolean): string { return dark ? '#101110' : CoopTheme.appSurface; }
  static surface(dark: boolean): string { return dark ? '#25251f' : '#fffdf6'; }
  static soft(dark: boolean): string { return dark ? '#303126' : '#eeeeda'; }
  static ink(dark: boolean): string { return dark ? '#fff2df' : CoopTheme.ink; }
  static muted(dark: boolean): string { return dark ? '#c0b59f' : '#81735d'; }
  static line(dark: boolean): string { return dark ? '#454334' : '#e7dcc5'; }
  static accent(dark: boolean): string { return dark ? '#b6d39a' : '#527342'; }
  static onAccent(dark: boolean): string { return dark ? '#25351f' : '#fff9e9'; }
  static gold(dark: boolean): string { return dark ? '#ffd083' : '#9b6324'; }
  static shadow(dark: boolean): string { return dark ? '#25000000' : '#18755632'; }
  static scene(name: string, dark: boolean): string { return `${BLOCK_ASSETS}scene/${name}_${dark ? 'dark' : 'light'}.svg`; }
  static icon(name: string, dark: boolean, primary: boolean = false): string {
    return `${BLOCK_ASSETS}icons/${name}_${primary ? 'primary_' : ''}${dark ? 'dark' : 'light'}.svg`;
  }
}
