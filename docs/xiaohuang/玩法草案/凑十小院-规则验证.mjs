// Design-only discrete rules and solution certificates. Not wired into the App.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
export const design = JSON.parse(readFileSync(new URL('./凑十小院-示例棋盘.json', import.meta.url), 'utf8'));
export function neighbors(a, b, size) {
  return Math.abs(a % size - b % size) + Math.abs(Math.floor(a / size) - Math.floor(b / size)) === 1;
}
export function validPath(board, path, size) {
  if (path.length < 2 || new Set(path).size !== path.length) return false;
  let sum = 0;
  for (let k = 0; k < path.length; k++) {
    const i = path[k];
    if (!Number.isInteger(i) || i < 0 || i >= board.length || board[i] <= 0) return false;
    if (k > 0 && !neighbors(path[k - 1], i, size)) return false;
    sum += board[i];
  }
  return sum === 10;
}
export function collect(board, path, size, direction) {
  if (!validPath(board, path, size)) throw new Error('Invalid path');
  const next = board.slice();
  for (const i of path) next[i] = 0;
  for (let lane = 0; lane < size; lane++) {
    const slots = Array.from({ length: size }, (_, k) => direction === 0 ? k * size + lane :
      direction === 1 ? lane * size + size - 1 - k :
      direction === 2 ? (size - 1 - k) * size + lane : lane * size + k);
    const values = slots.map(i => next[i]).filter(v => v > 0);
    const padding = size - values.length;
    slots.forEach((i, k) => { next[i] = k < padding ? 0 : values[k - padding]; });
  }
  return next;
}
// Exact replay is small; full-board puzzle generation/search stays out of the App's frame path.
export function replay(level) {
  let board = level.board.slice();
  assert.equal(board.length, level.size ** 2);
  assert.ok(board.every(v => Number.isInteger(v) && v >= 0 && v <= 9));
  const total = board.reduce((a, b) => a + b, 0);
  assert.equal(total, level.solution.length * 10);
  level.solution.forEach((path, step) => {
    assert.ok(validPath(board, path, level.size), `${level.id} step ${step + 1}`);
    const next = collect(board, path, level.size, step % 4);
    assert.equal(next.reduce((a, b) => a + b, 0), total - (step + 1) * 10);
    assert.equal(next.filter(Boolean).length, board.filter(Boolean).length - path.length);
    board = next;
  });
  assert.ok(board.every(v => v === 0));
}
for (const level of design.levels) {
  replay(level);
  console.log(`PASS ${level.id}: ${level.board.filter(Boolean).length} tiles, ${level.solution.length} collections, fully cleared`);
}
const start = [2,8,3,4];
assert.deepEqual(collect(start,[0,1],2,0),[0,0,3,4]);
assert.deepEqual(collect(start,[0,1],2,1),[0,0,3,4]);
assert.deepEqual(collect(start,[0,1],2,2),[3,4,0,0]);
assert.deepEqual(collect(start,[0,1],2,3),[0,0,3,4]);
const sideways = [2,3,8,4];
assert.deepEqual(collect(sideways,[0,2],2,1),[3,0,4,0]);
assert.deepEqual(collect(sideways,[0,2],2,3),[0,3,0,4]);
assert.deepEqual(start,[2,8,3,4]);
for (const bad of [[0],[0,0],[0,3],[1,2],[-1,1],[0,.5],[4,0]]) assert.equal(validPath(start,bad,2),false);
console.log('PASS four directions preserve lane order; invalid selections do not mutate the board');
