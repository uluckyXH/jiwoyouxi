import { DIFFICULTIES, MineCell, MineDifficulty } from './MinesweeperTypes';

export function minesweeperDifficulty(key: string): MineDifficulty {
  const found = DIFFICULTIES.find((item: MineDifficulty) => item.key === key);
  return found === undefined ? DIFFICULTIES[0] : found;
}

export function createEmptyMineCells(rows: number, cols: number): MineCell[] {
  const total = rows * cols;
  const cells: MineCell[] = [];
  for (let i = 0; i < total; i += 1) {
    cells.push({ index: i, mine: false, open: false, flag: false, neighbor: 0, boom: false });
  }
  return cells;
}

export function placeMinesForFirstTap(cells: MineCell[], difficulty: MineDifficulty, firstIndex: number): MineCell[] {
  const safe = safeZone(firstIndex, difficulty.rows, difficulty.cols);
  const total = difficulty.rows * difficulty.cols;
  const next = cloneMineCells(cells);
  let placed = 0;
  while (placed < difficulty.mines) {
    const index = Math.floor(Math.random() * total);
    if (safe.includes(index) || next[index].mine) {
      continue;
    }
    next[index].mine = true;
    placed += 1;
  }
  for (let i = 0; i < total; i += 1) {
    next[i].neighbor = neighborsOf(i, difficulty.rows, difficulty.cols).filter((neighbor: number) => next[neighbor].mine).length;
  }
  return next;
}

export function openSafeCells(cells: MineCell[], difficulty: MineDifficulty, index: number): MineCell[] {
  const next = cloneMineCells(cells);
  const queue: number[] = [index];
  const seen: number[] = [];
  while (queue.length > 0) {
    const current = queue.shift();
    if (current === undefined || seen.includes(current)) {
      continue;
    }
    seen.push(current);
    const cell = next[current];
    if (cell.flag || cell.mine) {
      continue;
    }
    cell.open = true;
    next[current] = cell;
    if (cell.neighbor === 0) {
      neighborsOf(current, difficulty.rows, difficulty.cols).forEach((neighbor: number) => {
        if (!seen.includes(neighbor)) {
          queue.push(neighbor);
        }
      });
    }
  }
  return next;
}

export function revealMines(cells: MineCell[]): MineCell[] {
  const next = cloneMineCells(cells);
  next.forEach((cell: MineCell) => {
    if (cell.mine) {
      cell.open = true;
    }
  });
  return next;
}

export function flagAllMines(cells: MineCell[]): MineCell[] {
  const next = cloneMineCells(cells);
  next.forEach((cell: MineCell) => {
    if (cell.mine) {
      cell.flag = true;
    }
  });
  return next;
}

export function toggleFlagAt(cells: MineCell[], index: number, maxFlags: number): MineCell[] {
  const next = cloneMineCells(cells);
  const cell = next[index];
  if (!cell.flag && flagCount(next) >= maxFlags) {
    return next;
  }
  cell.flag = !cell.flag;
  next[index] = cell;
  return next;
}

export function markBoomAt(cells: MineCell[], index: number): MineCell[] {
  const next = cloneMineCells(cells);
  const cell = next[index];
  cell.open = true;
  cell.boom = true;
  next[index] = cell;
  return next;
}

export function isMinesweeperWin(cells: MineCell[], difficulty: MineDifficulty): boolean {
  return openSafeCellCount(cells) >= difficulty.rows * difficulty.cols - difficulty.mines;
}

export function remainingMineCount(cells: MineCell[], mineCount: number): number {
  return Math.max(0, mineCount - flagCount(cells));
}

export function openSafeCellCount(cells: MineCell[]): number {
  return cells.filter((cell: MineCell) => cell.open && !cell.mine).length;
}

export function minesweeperScore(cells: MineCell[], elapsed: number, mineCount: number, won: boolean): number {
  if (won) {
    return Math.max(1, 10000 - elapsed * 8 + mineCount * 20);
  }
  return openSafeCellCount(cells);
}

export function neighborsOf(index: number, rows: number, cols: number): number[] {
  const result: number[] = [];
  const row = Math.floor(index / cols);
  const col = index % cols;
  for (let dr = -1; dr <= 1; dr += 1) {
    for (let dc = -1; dc <= 1; dc += 1) {
      if (dr === 0 && dc === 0) {
        continue;
      }
      const nr = row + dr;
      const nc = col + dc;
      if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
        result.push(nr * cols + nc);
      }
    }
  }
  return result;
}

function safeZone(index: number, rows: number, cols: number): number[] {
  const safe = neighborsOf(index, rows, cols);
  safe.push(index);
  return safe;
}

function cloneMineCells(cells: MineCell[]): MineCell[] {
  const next: MineCell[] = [];
  cells.forEach((cell: MineCell) => {
    next.push({
      index: cell.index,
      mine: cell.mine,
      open: cell.open,
      flag: cell.flag,
      neighbor: cell.neighbor,
      boom: cell.boom
    });
  });
  return next;
}

function flagCount(cells: MineCell[]): number {
  return cells.filter((cell: MineCell) => cell.flag).length;
}
