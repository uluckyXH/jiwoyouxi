import { FC_ASSETS } from './FreecellModel';
export class FCPalette {
  static bg(d: boolean): string { return d ? '#101110' : '#FFF4E4'; }
  static ink(d: boolean): string { return d ? '#F4EBD8' : '#27372D'; }
  static muted(d: boolean): string { return d ? '#B4C0AC' : '#62725B'; }
  static accent(d: boolean): string { return d ? '#A8CFA8' : '#2C6B52'; }
  static on(d: boolean): string { return d ? '#183A2A' : '#FFFAF2'; }
  static paper(d: boolean): string { return d ? '#211F1B' : '#FFFAF2'; }
  static felt(d: boolean): string { return d ? '#1C2B24' : '#E5ECD9'; }
  static line(d: boolean): string { return d ? '#425242' : '#CDDAC1'; }
  static red(d: boolean): string { return d ? '#FFB5A5' : '#A63F39'; }
  static gold(d: boolean): string { return d ? '#DDB875' : '#916022'; }
  static asset(path: string, d: boolean): string { return `${FC_ASSETS}${path}_${d ? 'dark' : 'light'}.svg`; }
  static icon(name: string, d: boolean, on: boolean = false): string { return `${FC_ASSETS}ui/${name}_${d ? 'dark' : 'light'}_${on ? 'on' : 'accent'}.svg`; }
}
