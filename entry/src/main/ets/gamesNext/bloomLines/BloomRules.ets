function bloomNeighbors(index: number, size: number): number[] {
  const result: number[] = [];
  const x = index % size;
  const y = Math.floor(index / size);
  if (x > 0) { result.push(index - 1); }
  if (x + 1 < size) { result.push(index + 1); }
  if (y > 0) { result.push(index - size); }
  if (y + 1 < size) { result.push(index + size); }
  return result;
}

export function bloomParents(board: number[], size: number, from: number): number[] {
  const parents: number[] = new Array<number>(board.length).fill(-2);
  if (!Number.isInteger(from) || from < 0 || from >= board.length || board[from] < 0) { return parents; }
  const queue: number[] = [from];
  parents[from] = -1;
  for (let head = 0; head < queue.length; head += 1) {
    const index = queue[head];
    const neighbors = bloomNeighbors(index, size);
    for (let i = 0; i < neighbors.length; i += 1) {
      const next = neighbors[i];
      if (board[next] === -1 && parents[next] === -2) {
        parents[next] = index;
        queue.push(next);
      }
    }
  }
  return parents;
}

export function bloomPath(board: number[], size: number, from: number, to: number): number[] {
  if (!Number.isInteger(to) || to < 0 || to >= board.length || board[to] !== -1 || to === from) { return []; }
  const parents = bloomParents(board, size, from);
  if (parents[to] === -2) { return []; }
  const path: number[] = [];
  for (let index = to; index !== -1; index = parents[index]) { path.push(index); }
  return path.reverse();
}

export function bloomReachable(board: number[], size: number, from: number): number[] {
  const parents = bloomParents(board, size, from);
  const result: number[] = [];
  parents.forEach((parent: number, index: number) => {
    if (parent >= 0) { result.push(index); }
  });
  return result;
}

export function bloomLinesAt(board: number[], size: number, index: number): number[] {
  if (index < 0 || index >= board.length || board[index] < 0) { return []; }
  const color = board[index];
  const x = index % size;
  const y = Math.floor(index / size);
  const xs: number[] = [1, 0, 1, 1];
  const ys: number[] = [0, 1, 1, -1];
  const removed: Set<number> = new Set<number>();
  for (let axis = 0; axis < 4; axis += 1) {
    const line: number[] = [index];
    for (let sign = -1; sign <= 1; sign += 2) {
      let col = x + xs[axis] * sign;
      let row = y + ys[axis] * sign;
      while (col >= 0 && col < size && row >= 0 && row < size && board[row * size + col] === color) {
        line.push(row * size + col);
        col += xs[axis] * sign;
        row += ys[axis] * sign;
      }
    }
    if (line.length >= 5) { line.forEach((cell: number) => removed.add(cell)); }
  }
  return Array.from(removed).sort((a: number, b: number) => a - b);
}

export function bloomAllLines(board: number[], size: number, candidates: number[]): number[] {
  const removed: Set<number> = new Set<number>();
  // Collect the union before removing anything, including intersecting new lines.
  candidates.forEach((index: number) => {
    bloomLinesAt(board, size, index).forEach((cell: number) => removed.add(cell));
  });
  return Array.from(removed).sort((a: number, b: number) => a - b);
}
