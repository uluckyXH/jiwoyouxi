import { STAR_COUNT, StarTile } from './StarModel';

/** One observable per stable tile, so moving one tile never subscribes to the whole board. */
@Observed
export class StarVisualTile {
  @Track id: number;
  @Track color: number = 0;
  @Track cell: number = 0;
  @Track visible: boolean = false;
  @Track selected: boolean = false;
  @Track scale: number = 1;
  @Track groupCount: number = 0;
  constructor(id: number) { this.id = id; }
}

export class StarScene {
  tiles: StarVisualTile[] = [];
  private round: string = '';

  restore(round: string, tiles: StarTile[], counts: number[]): boolean {
    const replaced = this.round !== round || this.tiles.length === 0;
    if (replaced) {
      this.round = round;
      this.tiles = [];
      for (let id = 0; id < STAR_COUNT; id++) this.tiles.push(new StarVisualTile(id));
    }
    const visible: boolean[] = new Array<boolean>(STAR_COUNT).fill(false);
    for (let i = 0; i < tiles.length; i++) {
      const next = tiles[i], tile = this.tiles[next.id];
      visible[next.id] = true;
      if (tile.cell !== next.cell) tile.cell = next.cell;
      if (tile.color !== next.color) tile.color = next.color;
    }
    for (let id = 0; id < this.tiles.length; id++) {
      const tile = this.tiles[id];
      const count = counts[id] ?? 0;
      if (tile.visible !== visible[id]) tile.visible = visible[id];
      if (tile.groupCount !== count) tile.groupCount = count;
      if (tile.scale !== 1) tile.scale = 1;
      if (tile.selected) tile.selected = false;
    }
    return replaced;
  }

  select(ids: number[]): void {
    const selected: boolean[] = new Array<boolean>(STAR_COUNT).fill(false);
    for (let i = 0; i < ids.length; i++) selected[ids[i]] = true;
    for (let id = 0; id < this.tiles.length; id++) {
      if (this.tiles[id].selected !== selected[id]) this.tiles[id].selected = selected[id];
    }
  }

  shrink(ids: number[]): void {
    for (let i = 0; i < ids.length; i++) this.tiles[ids[i]].scale = .03;
  }

  hide(ids: number[]): void {
    for (let i = 0; i < ids.length; i++) this.tiles[ids[i]].visible = false;
  }

  place(tiles: StarTile[]): number {
    let changed = 0;
    for (let i = 0; i < tiles.length; i++) {
      const next = tiles[i], tile = this.tiles[next.id];
      if (tile.cell !== next.cell) { tile.cell = next.cell; changed++; }
    }
    return changed;
  }
}
