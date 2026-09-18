import { MINE_ASSETS } from './MineModel';

export class MinePalette {
  static bg(dark: boolean): string { return dark ? '#101110' : '#FFF4E4'; }
  static paper(dark: boolean): string { return dark ? '#262A24' : '#FFFDF4'; }
  static soft(dark: boolean): string { return dark ? '#333D2E' : '#E7EDCF'; }
  static ink(dark: boolean): string { return dark ? '#F2E6D5' : '#3A4338'; }
  static muted(dark: boolean): string { return dark ? '#B5B7A4' : '#7B816A'; }
  static accent(dark: boolean): string { return dark ? '#B6D3AD' : '#416B55'; }
  static onAccent(dark: boolean): string { return dark ? '#1D3427' : '#FFFCF2'; }
  static line(dark: boolean): string { return dark ? '#485044' : '#D6DEBF'; }
  static gold(dark: boolean): string { return dark ? '#EFBD72' : '#A87135'; }
  static danger(dark: boolean): string { return dark ? '#FFB6A4' : '#AC4937'; }
  static dangerBg(dark: boolean): string { return dark ? '#674135' : '#F5CEC0'; }
  static number(value: number, dark: boolean): string {
    const light: string[] = ['', '#47718E', '#497548', '#B76042', '#836BA3', '#9E5F44', '#3C8781', '#65534B', '#7D795F'];
    const night: string[] = ['', '#9DC8E5', '#B6D3AD', '#ECA58F', '#C2ADE2', '#E4B58B', '#8ED2CA', '#E0CDC0', '#C7C5B1'];
    return (dark ? night : light)[Math.max(0, Math.min(8, value))];
  }
  static icon(name: string, dark: boolean, tone: string = ''): string {
    return `${MINE_ASSETS}icons/${name}_${tone.length > 0 ? tone + '_' : ''}${dark ? 'dark' : 'light'}.svg`;
  }
}
