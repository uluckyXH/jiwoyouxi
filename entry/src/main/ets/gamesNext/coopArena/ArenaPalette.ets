import { ARENA_ASSETS } from './ArenaModel';
export class ArenaPalette {
  static background(dark: boolean): string { return dark ? '#101110' : '#fff4e4'; }
  static surface(dark: boolean): string { return dark ? '#25251f' : '#fffdf6'; }
  static soft(dark: boolean): string { return dark ? '#303126' : '#eeeeda'; }
  static ink(dark: boolean): string { return dark ? '#fff2df' : '#39291e'; }
  static muted(dark: boolean): string { return dark ? '#c0b59f' : '#81735d'; }
  static line(dark: boolean): string { return dark ? '#454334' : '#e7dcc5'; }
  static accent(dark: boolean): string { return dark ? '#b6d39a' : '#527342'; }
  static onAccent(dark: boolean): string { return dark ? '#25351f' : '#fff9e9'; }
  static faction(f: number, dark: boolean): string {
    return (dark ? ['#a4c6dc','#f5b094','#b0d6a8'] : ['#466d85','#a94d30','#3c713c'])[f];
  }
  static icon(name: string, dark: boolean, primary: boolean = false): string {
    return `${ARENA_ASSETS}icons/${name}_${primary ? 'primary_' : ''}${dark ? 'dark' : 'light'}.svg`;
  }
  static piece(f: number, dark: boolean): string { return `${ARENA_ASSETS}factions/${f}_${dark ? 'dark' : 'light'}.svg`; }
  static token(f: number, dark: boolean): string { return `${ARENA_ASSETS}tokens/${f}_${dark ? 'dark' : 'light'}.svg`; }
  static teamSurface(f: number, dark: boolean): string {
    return (dark ? ['#30414a','#49352b','#30402d'] : ['#e8eff0','#fbebdf','#e8efdc'])[f];
  }
  static scene(name: string, dark: boolean): string { return `${ARENA_ASSETS}scene/${name}_${dark ? 'dark' : 'light'}.svg`; }
}
