import { GlowTile } from './GlowModel';

// ForEach preserves a view by ID. Keep that view's observed object alive as
// positions and values change, rather than capturing an immutable old snapshot.
@Observed
export class GlowRenderTile {
  id: number;
  value: number;
  index: number;

  constructor(tile: GlowTile) {
    this.id = tile.id;
    this.value = tile.value;
    this.index = tile.index;
  }
}

export function glowReconcileTiles(current: GlowRenderTile[], next: GlowTile[]): GlowRenderTile[] {
  return next.map((tile: GlowTile): GlowRenderTile => {
    const live = current.find((item: GlowRenderTile) => item.id === tile.id);
    if (live === undefined) return new GlowRenderTile(tile);
    live.index = tile.index;
    live.value = tile.value;
    return live;
  });
}
