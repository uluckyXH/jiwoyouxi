import { TEN_ASSETS } from './TenModel';
export class TenPalette {
  static bg(dark: boolean): string { return dark ? '#171E1C' : '#FFF4E4'; }
  static paper(dark: boolean): string { return dark ? '#29332E' : '#FFFCF3'; }
  static soft(dark: boolean): string { return dark ? '#34463C' : '#E8EFDD'; }
  static ink(dark: boolean): string { return dark ? '#F6ECD8' : '#324C40'; }
  static muted(dark: boolean): string { return dark ? '#B1C3B3' : '#6D8070'; }
  static accent(dark: boolean): string { return dark ? '#AAD8B4' : '#28745D'; }
  static onAccent(dark: boolean): string { return dark ? '#183D30' : '#FFFBEF'; }
  static line(dark: boolean): string { return dark ? '#4B6152' : '#D4E1C6'; }
  static gold(dark: boolean): string { return dark ? '#EDC995' : '#A16F3E'; }
  static danger(dark: boolean): string { return dark ? '#F2BBA3' : '#A55F46'; }
  static icon(name: string, dark: boolean, tone: string = 'ink'): string {
    return TEN_ASSETS + 'icons/' + name + '_' + tone + '_' + (dark ? 'dark' : 'light') + '.svg';
  }
  static scene(name: string, dark: boolean): string {
    return TEN_ASSETS + 'scene/' + name + '_' + (dark ? 'dark' : 'light') + '.svg';
  }
}
