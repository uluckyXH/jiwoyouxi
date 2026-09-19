import { STAR_COUNT, STAR_WIDTH, STAR_HEIGHT, StarFall, StarTile, starGain } from './StarModel';

export function starNeighbors(cell: number): number[] {
  const out: number[] = [];
  if (cell % STAR_WIDTH > 0) out.push(cell - 1);
  if (cell % STAR_WIDTH < STAR_WIDTH - 1) out.push(cell + 1);
  if (cell >= STAR_WIDTH) out.push(cell - STAR_WIDTH);
  if (cell < STAR_COUNT - STAR_WIDTH) out.push(cell + STAR_WIDTH);
  return out;
}

export function starGroup(cells: number[], cell: number): number[] {
  if (!Number.isInteger(cell) || cell < 0 || cell >= STAR_COUNT || cells[cell] < 0) return [];
  return starCollectGroup(cells, cell, new Array<boolean>(STAR_COUNT).fill(false));
}

function starCollectGroup(cells: number[], cell: number, seen: boolean[]): number[] {
  const group: number[] = [cell]; seen[cell] = true;
  for (let head = 0; head < group.length; head++) {
    const neighbors = starNeighbors(group[head]);
    for (let j = 0; j < neighbors.length; j++) {
      const next = neighbors[j];
      if (!seen[next] && cells[next] === cells[cell]) { seen[next] = true; group.push(next); }
    }
  }
  return group;
}

export function starGroups(cells: number[]): number[][] {
  const seen: boolean[] = new Array<boolean>(STAR_COUNT).fill(false);
  const groups: number[][] = [];
  for (let cell = 0; cell < STAR_COUNT; cell++) {
    if (cells[cell] < 0 || seen[cell]) continue;
    const group = starCollectGroup(cells, cell, seen);
    if (group.length >= 2) groups.push(group);
  }
  return groups;
}

export function starRemaining(cells: number[]): number {
  let count = 0;
  for (let i = 0; i < cells.length; i++) if (cells[i] >= 0) count++;
  return count;
}

export function starCollapse(cells: number[], ids: number[], group: number[]): StarFall {
  const removed: boolean[] = new Array<boolean>(STAR_COUNT).fill(false);
  const removedIds: number[] = [];
  for (let i = 0; i < group.length; i++) { removed[group[i]] = true; removedIds.push(ids[group[i]]); }
  const next: number[] = new Array<number>(STAR_COUNT).fill(-1);
  const nextIds: number[] = new Array<number>(STAR_COUNT).fill(-1);
  let column = 0;
  for (let x = 0; x < STAR_WIDTH; x++) {
    let yOut = STAR_HEIGHT - 1;
    for (let y = STAR_HEIGHT - 1; y >= 0; y--) {
      const cell = y * STAR_WIDTH + x;
      if (cells[cell] < 0 || removed[cell]) continue;
      next[yOut * STAR_WIDTH + column] = cells[cell];
      nextIds[yOut * STAR_WIDTH + column] = ids[cell]; yOut--;
    }
    if (yOut < STAR_HEIGHT - 1) column++;
  }
  return { cells: next, ids: nextIds, removedIds: removedIds, gain: starGain(group.length) };
}

export function starTiles(cells: number[], ids: number[]): StarTile[] {
  const tiles: StarTile[] = [];
  for (let i = 0; i < STAR_COUNT; i++) if (cells[i] >= 0) tiles.push({ id: ids[i], color: cells[i], cell: i });
  return tiles;
}

/** Intermediate visual positions: gravity first, then empty-column compression. */
export function starGravityTiles(before: StarTile[], after: StarTile[]): StarTile[] {
  const columns: number[] = new Array<number>(STAR_COUNT).fill(-1);
  for (let i = 0; i < before.length; i++) columns[before[i].id] = before[i].cell % STAR_WIDTH;
  return after.map((tile: StarTile): StarTile => {
    const previous = columns[tile.id];
    const column = previous >= 0 ? previous : tile.cell % STAR_WIDTH;
    return { id: tile.id, color: tile.color, cell: Math.floor(tile.cell / STAR_WIDTH) * STAR_WIDTH + column };
  });
}

export function starValidBoard(cells: number[], ids: number[], colors: number): boolean {
  if (!Array.isArray(cells) || !Array.isArray(ids) || cells.length !== STAR_COUNT || ids.length !== STAR_COUNT) return false;
  const used: boolean[] = new Array<boolean>(STAR_COUNT).fill(false);
  let emptyColumn = false;
  for (let x = 0; x < STAR_WIDTH; x++) {
    let found = false;
    for (let y = 0; y < STAR_HEIGHT; y++) {
      const cell = y * STAR_WIDTH + x, color = cells[cell], id = ids[cell];
      if (!Number.isInteger(color) || color < -1 || color >= colors || !Number.isInteger(id)) return false;
      if (color < 0) { if (found || id !== -1) return false; continue; }
      if (emptyColumn || id < 0 || id >= STAR_COUNT || used[id]) return false;
      found = true; used[id] = true;
    }
    if (!found) emptyColumn = true;
  }
  return true;
}
