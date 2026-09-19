export const TANGRAM_ASSETS: string = 'gamesNext/tangramGarden/';
export const TANGRAM_LOGO: string = `${TANGRAM_ASSETS}scene/logo.svg`;
export class TangramPalette {
  static bg(dark: boolean): string { return dark ? '#1B211D' : '#FFF4E4'; }
  static paper(dark: boolean): string { return dark ? '#29332C' : '#FFFCF4'; }
  static soft(dark: boolean): string { return dark ? '#354335' : '#EAF0DB'; }
  static ink(dark: boolean): string { return dark ? '#F6EDDC' : '#493D30'; }
  static muted(dark: boolean): string { return dark ? '#B9C3AB' : '#827760'; }
  static line(dark: boolean): string { return dark ? '#4D5B45' : '#E9D8B9'; }
  static accent(dark: boolean): string { return dark ? '#BBD6A4' : '#477345'; }
  static wood(dark: boolean): string { return dark ? '#87704D' : '#E3BD83'; }
  static target(dark: boolean): string { return dark ? '#475742' : '#E4E8D0'; }
  static danger(dark: boolean): string { return dark ? '#F6B89E' : '#A44F33'; }
  static piece(id: number, dark: boolean): string {
    const light: string[] = ['#EDB569', '#ED9684', '#A8C78E', '#93C7D2', '#C5A6D4', '#F3D17C', '#A5BCE2'];
    const night: string[] = ['#D7A05E', '#D6897B', '#8CB779', '#7CB3C0', '#AF94C4', '#DABD71', '#8FA9D1'];
    return (dark ? night : light)[id];
  }
  static icon(name: string, dark: boolean, primary: boolean = false): string {
    return `${TANGRAM_ASSETS}icons/${name}_${primary ? 'on' : dark ? 'dark' : 'light'}.svg`;
  }
}
