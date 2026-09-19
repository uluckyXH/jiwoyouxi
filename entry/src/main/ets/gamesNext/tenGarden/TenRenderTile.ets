import { TenTileView } from './TenModel';

/** Keyed ArkUI nodes retain this object; update it instead of replacing its snapshot. */
@Observed
export class TenRenderTile {
  @Track id: number;
  @Track value: number;
  @Track index: number;

  constructor(tile: TenTileView) {
    this.id = tile.id;
    this.value = tile.value;
    this.index = tile.index;
  }
}

export function tenReconcileTiles(current: TenRenderTile[], next: TenTileView[]): TenRenderTile[] {
  return next.map((tile: TenTileView): TenRenderTile => {
    const live = current.find((item: TenRenderTile): boolean => item.id === tile.id);
    if (live === undefined) return new TenRenderTile(tile);
    if (live.index !== tile.index) live.index = tile.index;
    if (live.value !== tile.value) live.value = tile.value;
    return live;
  });
}
