import { TenPath, TenPuzzle, TenRound, TenSave, tenInteger, tenProfile } from './TenModel';
import { TEN_PUZZLES } from './TenPuzzles';

export function tenRotate(index: number, size: number, rotation: number): number {
  let result = index;
  for (let i = 0; i < rotation; i += 1) { result = result % size * size + size - 1 - Math.floor(result / size); }
  return result;
}
export function tenPuzzle(stage: number): TenPuzzle {
  if (stage === 1) return { key: 'intro-v1', size: 3, values: [0, 0, 0, 2, 8, 0, 3, 4, 3],
    solution: [{ cells: [3, 4] }, { cells: [6, 7, 8] }], direction: 0 };
  const index = (stage - 2) % TEN_PUZZLES.length;
  const rotation = Math.floor((stage - 2) / TEN_PUZZLES.length) % 4;
  const base = TEN_PUZZLES[index];
  const values: number[] = new Array<number>(36).fill(0);
  base.values.forEach((value: number, i: number) => { values[tenRotate(i, 6, rotation)] = value; });
  return { key: 'garden-v1-' + index + '-' + rotation, size: 6, values: values, direction: rotation,
    solution: base.steps.map((cells: number[]): TenPath => ({ cells: cells.map((i: number) => tenRotate(i, 6, rotation)) })) };
}
export function tenAdjacent(a: number, b: number, size: number): boolean {
  return Math.abs(a % size - b % size) + Math.abs(Math.floor(a / size) - Math.floor(b / size)) === 1;
}
export function tenSum(board: number[], path: number[]): number {
  return path.reduce((sum: number, i: number): number => sum + board[i], 0);
}
export function tenValidPath(board: number[], path: number[], size: number): boolean {
  if (path.length < 2 || path.length > 10 || new Set<number>(path).size !== path.length) return false;
  let sum = 0;
  for (let k = 0; k < path.length; k += 1) {
    const i = path[k];
    if (!tenInteger(i, 0, board.length - 1) || board[i] <= 0) return false;
    if (k > 0 && !tenAdjacent(path[k - 1], i, size)) return false;
    sum += board[i];
  }
  return sum === 10;
}
export function tenSelect(board: number[], path: number[], index: number, size: number): number[] {
  if (!tenInteger(index, 0, board.length - 1) || board[index] <= 0) return path.slice();
  const before = path.indexOf(index);
  if (before >= 0) return path.slice(0, before === path.length - 1 ? before : before + 1);
  if (path.length > 0 && !tenAdjacent(path[path.length - 1], index, size)) return path.slice();
  if (tenSum(board, path) + board[index] > 10) return path.slice();
  return path.concat(index);
}
/** Erase simultaneously, then compact one axis. Works for values and stable tile IDs. */
export function tenShift(board: number[], path: number[], size: number, direction: number): number[] {
  const next = board.slice();
  path.forEach((i: number) => { next[i] = 0; });
  for (let lane = 0; lane < size; lane += 1) {
    const slots: number[] = [];
    for (let k = 0; k < size; k += 1) {
      slots.push(direction === 0 ? k * size + lane : direction === 1 ? lane * size + size - 1 - k :
        direction === 2 ? (size - 1 - k) * size + lane : lane * size + k);
    }
    const values = slots.map((i: number): number => next[i]).filter((v: number): boolean => v > 0);
    const padding = size - values.length;
    slots.forEach((i: number, k: number) => { next[i] = k < padding ? 0 : values[k - padding]; });
  }
  return next;
}
export function tenEqual(a: number[], b: number[]): boolean {
  return a.length === b.length && a.every((v: number, i: number): boolean => v === b[i]);
}
export function tenStart(stage: number = 1): TenRound {
  const puzzle = tenPuzzle(stage);
  return { id: 'ten-' + Date.now() + '-' + Math.floor(Math.random() * 0xFFFFFFFF), stage: stage,
    board: puzzle.values.slice(), ids: puzzle.values.map((v: number, i: number): number => v > 0 ? i + 1 : 0),
    history: [], credited: 0, phase: 'playing', reported: false, undos: 0, hints: 0 };
}
export function tenSaveValid(save: TenSave): boolean {
  if (save === null || typeof save !== 'object' || save.version !== 1 || save.round === null ||
    typeof save.round !== 'object' || save.profile === null || typeof save.profile !== 'object') return false;
  const r = save.round;
  if (!tenInteger(r.stage, 1, 1000000) || typeof r.id !== 'string' || r.id.length < 1 || r.id.length > 100 ||
    !Array.isArray(r.board) || !Array.isArray(r.ids) || !Array.isArray(r.history) ||
    !tenInteger(r.undos, 0, 1000000000) || !tenInteger(r.hints, 0, 1000000000) || typeof r.reported !== 'boolean') return false;
  const puzzle = tenPuzzle(r.stage);
  if (r.history.length > puzzle.solution.length || !tenInteger(r.credited, r.history.length, puzzle.solution.length)) return false;
  let board = puzzle.values.slice();
  let ids = puzzle.values.map((v: number, i: number): number => v > 0 ? i + 1 : 0);
  for (let step = 0; step < r.history.length; step += 1) {
    const entry = r.history[step];
    if (entry === null || typeof entry !== 'object' || !Array.isArray(entry.cells) ||
      !tenValidPath(board, entry.cells, puzzle.size)) return false;
    board = tenShift(board, entry.cells, puzzle.size, (puzzle.direction + step) % 4);
    ids = tenShift(ids, entry.cells, puzzle.size, (puzzle.direction + step) % 4);
  }
  if (!tenEqual(board, r.board) || !tenEqual(ids, r.ids)) return false;
  const complete = board.every((v: number): boolean => v === 0);
  if (r.phase !== (complete ? 'complete' : 'playing') || (!complete && r.reported)) return false;
  const expected = tenProfile(r);
  return save.profile.totalGroups === expected.totalGroups && save.profile.totalWins === expected.totalWins &&
    save.profile.totalChallenges === expected.totalChallenges;
}
