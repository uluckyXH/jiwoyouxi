#!/usr/bin/env node
// Offline only: produce fixed, replay-verified puzzles; no solver ships in the game loop.
import { readFileSync, writeFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
const root = new URL('../', import.meta.url);
const read = path => readFileSync(new URL(path, root), 'utf8');
const clean = text => text.replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export /gm, '');
const code = clean(read('entry/src/main/ets/gamesNext/tenGarden/TenModel.ets')) + '\nconst TEN_PUZZLES = [];\n' +
  clean(read('entry/src/main/ets/gamesNext/tenGarden/TenRules.ets'));
const api = vm.runInNewContext(stripTypeScriptTypes(code, { mode: 'transform' }) + '\n({tenShift,tenValidPath})');
let seed = 0x19092026;
function random() { seed ^= seed << 13; seed ^= seed >>> 17; seed ^= seed << 5; return (seed >>> 0) / 4294967296; }
const n = 6;
const neighbors = Array.from({ length: 36 }, (_, i) => [i % n > 0 ? i - 1 : -1, i % n < 5 ? i + 1 : -1,
  i >= n ? i - n : -1, i < 30 ? i + n : -1].filter(v => v >= 0));
function paths(board) {
  const result = [], seen = new Set(), picked = new Uint8Array(36), path = [];
  function walk(i, sum) {
    if (picked[i] || !board[i] || sum + board[i] > 10) return;
    picked[i] = 1; path.push(i); sum += board[i];
    if (sum === 10) {
      const key = [...path].sort((a, b) => a - b).join(',');
      if (!seen.has(key)) { seen.add(key); result.push([...path]); }
    } else for (const j of neighbors[i]) walk(j, sum);
    picked[i] = 0; path.pop();
  }
  for (let i = 0; i < 36; i++) walk(i, 0);
  return result;
}
function solve(board) {
  let nodes = 0, limited = false;
  const failed = new Set();
  function dfs(b, direction) {
    if (!b.some(Boolean)) return [];
    if (++nodes > 30000) { limited = true; return null; }
    const key = b.join('') + direction;
    if (failed.has(key)) return null;
    for (const path of paths(b)) {
      const tail = dfs(api.tenShift(b, path, n, direction), (direction + 1) % 4);
      if (tail) return [path, ...tail];
      if (limited) return null;
    }
    failed.add(key); return null;
  }
  return dfs(board, 0);
}
function randomWins(board) {
  let wins = 0;
  for (let trial = 0; trial < 160; trial++) {
    let b = board, direction = 0;
    while (b.some(Boolean)) {
      const moves = paths(b);
      if (!moves.length) break;
      b = api.tenShift(b, moves[Math.floor(random() * moves.length)], n, direction);
      direction = (direction + 1) % 4;
    }
    if (!b.some(Boolean)) wins++;
  }
  return wins;
}
const sample = JSON.parse(read('docs/xiaohuang/玩法草案/凑十小院-示例棋盘.json')).levels[1];
const puzzles = [{ values: sample.board, steps: sample.solution }];
const unique = new Set([sample.board.join('')]);
let candidates = 0;
while (puzzles.length < 64 && candidates++ < 3000) {
  const values = [];
  for (let i = 0; i < 12; i++) {
    const a = 1 + Math.floor(random() * 7), b = 1 + Math.floor(random() * (9 - a));
    values.push(a, b, 10 - a - b);
  }
  for (let i = 35; i > 0; i--) { const j = Math.floor(random() * (i + 1)); [values[i], values[j]] = [values[j], values[i]]; }
  if (unique.has(values.join(''))) continue;
  const steps = solve(values);
  if (!steps || randomWins(values) > 12) continue;
  let board = values;
  for (let i = 0; i < steps.length; i++) {
    if (!api.tenValidPath(board, steps[i], 6)) throw new Error('Invalid certificate');
    board = api.tenShift(board, steps[i], 6, i % 4);
  }
  if (board.some(Boolean) || steps.length !== 12) throw new Error('Incomplete certificate');
  unique.add(values.join('')); puzzles.push({ values, steps });
  if (puzzles.length % 8 === 0) console.log(`Verified ${puzzles.length}/64 puzzles`);
}
if (puzzles.length !== 64) throw new Error('Puzzle search budget exhausted');
writeFileSync(new URL('entry/src/main/ets/gamesNext/tenGarden/TenPuzzles.ets', root),
  "// Generated offline; v1 order is part of the save format. Keep it stable.\nimport { TenPuzzleTemplate } from './TenModel';\n" +
  'export const TEN_PUZZLES: TenPuzzleTemplate[] = [\n' + puzzles.map(p => '  ' + JSON.stringify(p)).join(',\n') + '\n];\n');
console.log(`PASS ${puzzles.length} certified puzzles; ${candidates} candidates; random policy used only for curation, not a human difficulty estimate.`);
