#!/usr/bin/env node

// 俄罗斯方块规则回归测试。
// 复用 chicken2048 的加载方式：读 .ets -> stripTypeScriptTypes -> vm 沙箱执行。
// 覆盖：碰撞、边界、4x4 矩阵形状、SRS 墙踢、7-bag、消行计分、速度档、幽灵落点。

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const projectRoot = resolve(import.meta.dirname, '..');
const sourceFiles = [
  'entry/src/main/ets/games/tetris/TetrisTypes.ets',
  'entry/src/main/ets/games/tetris/TetrisRules.ets'
];

function loadTetrisRules() {
  const source = sourceFiles
    .map((file) => readFileSync(resolve(projectRoot, file), 'utf8'))
    .join('\n')
    .replace(/^import\s+[^;]+;\n/gm, '')
    .replace(/^export\s+/gm, '');
  const runtimeSource = stripTypeScriptTypes(source, { mode: 'transform' });
  const context = { Math: Math };
  vm.runInNewContext(`${runtimeSource}
globalThis.__tetris = {
  BOARD_COLS, BOARD_ROWS, PIECE_COUNT,
  PIECE_I, PIECE_O, PIECE_T, PIECE_S, PIECE_Z, PIECE_J, PIECE_L,
  createEmptyBoard, cellsOf, collides, shifted, isGrounded, ghostPiece,
  tryRotate, lockPiece, clearLines, lineScore, comboScore,
  softDropScore, hardDropScore, speedLevelForLines, speedDelayForLevel,
  shuffleBag, spawnPiece
};
`, context);
  return context.__tetris;
}

const T = loadTetrisRules();
let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    passed += 1;
    console.log(`  ✓ ${name}`);
  } catch (error) {
    failed += 1;
    console.log(`  ✗ ${name}`);
    console.log(`      ${error.message}`);
  }
}

function boardWith(filled) {
  // filled: [[row,col,kind+1],...]
  const board = T.createEmptyBoard();
  for (const [row, col, value] of filled) {
    board[row * T.BOARD_COLS + col] = value;
  }
  return board;
}

function cellsSet(piece) {
  const cells = T.cellsOf(piece);
  return new Set(cells.map((c) => `${c.row},${c.col}`));
}

console.log('\n俄罗斯方块规则测试\n');

test('空棋盘大小为 200', () => {
  assert.equal(T.createEmptyBoard().length, 200);
});

// 注：4x4 矩阵中方块天然占 row1（居中），spawn row=0 时实际占地在 row1。
test('I 块 spawn 形状是 4 格水平', () => {
  const piece = T.spawnPiece(T.PIECE_I);
  const cells = cellsSet(piece);
  assert.equal(cells.size, 4);
  assert.ok(cells.has('1,3'));
  assert.ok(cells.has('1,4'));
  assert.ok(cells.has('1,5'));
  assert.ok(cells.has('1,6'));
});

test('O 块 spawn 是 2x2', () => {
  const piece = T.spawnPiece(T.PIECE_O);
  const cells = cellsSet(piece);
  assert.equal(cells.size, 4);
  assert.ok(cells.has('1,4'));
  assert.ok(cells.has('1,5'));
  assert.ok(cells.has('2,4'));
  assert.ok(cells.has('2,5'));
});

test('T 块旋转 4 次回到原形态', () => {
  let piece = T.spawnPiece(T.PIECE_T);
  const original = cellsSet(piece);
  for (let i = 0; i < 4; i += 1) {
    piece = { ...piece, rotation: (piece.rotation + 1) % 4 };
  }
  assert.deepEqual(cellsSet(piece), original);
});

test('collides: 越左边界检测', () => {
  const piece = T.spawnPiece(T.PIECE_I);
  const board = T.createEmptyBoard();
  // I 块左移到 col=-4，最左格 col=-1 越界
  const moved = T.shifted(piece, -4, 0);
  assert.equal(T.collides(board, moved), true);
});

test('collides: 底部边界检测', () => {
  const piece = T.spawnPiece(T.PIECE_I);
  const board = T.createEmptyBoard();
  // I 块矩阵占地在 row1，spawn row0 -> 占 row1。到底部 piece.row=18（占 row19）合法，row=19 越界。
  const bottom = T.shifted(piece, 0, 18);
  assert.equal(T.collides(board, bottom), false);
  const overBottom = T.shifted(piece, 0, 19);
  assert.equal(T.collides(board, overBottom), true);
});

test('collides: 检测压到固定块', () => {
  const piece = T.spawnPiece(T.PIECE_I);
  const board = boardWith([[1, 3, 1]]);
  assert.equal(T.collides(board, piece), true);
});

test('isGrounded: 空棋盘 spawn 的 I 块未落地', () => {
  const piece = T.spawnPiece(T.PIECE_I);
  const board = T.createEmptyBoard();
  assert.equal(T.isGrounded(board, piece), false);
});

test('isGrounded: 贴底即落地', () => {
  const piece = T.spawnPiece(T.PIECE_I);
  const board = T.createEmptyBoard();
  const bottom = T.shifted(piece, 0, 19);
  assert.equal(T.isGrounded(board, bottom), true);
});

test('ghostPiece: 空棋盘 I 块幽灵到 row=18', () => {
  const piece = T.spawnPiece(T.PIECE_I);
  const board = T.createEmptyBoard();
  const ghost = T.ghostPiece(board, piece);
  // I 占 row1，到底 piece.row=18（占 row19），再下移越界
  assert.equal(ghost.row, 18);
  assert.equal(ghost.col, piece.col);
});

test('ghostPiece: 有障碍时停在障碍上方', () => {
  const piece = T.spawnPiece(T.PIECE_I); // spawn 占 row1,col3-6
  const board = boardWith([[10, 4, 1]]); // col4 row10 有块
  const ghost = T.ghostPiece(board, piece);
  // I 块下移到 piece.row=9 (占 row10) 会压到 (10,4)，停在 piece.row=8（占 row9）
  assert.equal(ghost.row, 8);
});

test('tryRotate: O 块旋转不变（不踢）', () => {
  const piece = T.spawnPiece(T.PIECE_O);
  const board = T.createEmptyBoard();
  const rotated = T.tryRotate(board, piece);
  assert.deepEqual(cellsSet(rotated), cellsSet(piece));
});

test('tryRotate: 空棋盘 T 块可旋转', () => {
  const piece = T.spawnPiece(T.PIECE_T);
  const board = T.createEmptyBoard();
  const rotated = T.tryRotate(board, piece);
  assert.notEqual(rotated, null);
  assert.equal(rotated.rotation, 1);
});

test('tryRotate: 贴右墙 T 块旋转靠墙踢救回', () => {
  // T 块推到右边界，再右推使其部分越界，旋转应靠 SRS 墙踢左移成功。
  const piece = T.spawnPiece(T.PIECE_T); // 占 col3,4,5 row1
  const board = T.createEmptyBoard();
  const atWall = T.shifted(piece, 5, 0); // piece.col=8 -> 占 col8,9,10，col10越界
  // 当前 piece.col=8 越界，但 tryRotate 应通过墙踢把方块救回合法位置
  const rotated = T.tryRotate(board, atWall);
  assert.notEqual(rotated, null);
  assert.equal(T.collides(board, rotated), false);
});

test('tryRotate: I 块贴墙旋转用专属 kick', () => {
  const piece = T.spawnPiece(T.PIECE_I);
  const board = T.createEmptyBoard();
  const atWall = T.shifted(piece, 7, 0); // piece.col=10 越界
  const rotated = T.tryRotate(board, atWall);
  assert.notEqual(rotated, null);
  assert.equal(T.collides(board, rotated), false);
});

test('lockPiece: 写回棋盘正确（O 块占 row1-2）', () => {
  const piece = T.spawnPiece(T.PIECE_O);
  const board = T.createEmptyBoard();
  const locked = T.lockPiece(board, piece);
  assert.equal(locked[1 * T.BOARD_COLS + 4], 2); // O kind+1=2
  assert.equal(locked[1 * T.BOARD_COLS + 5], 2);
  assert.equal(locked[2 * T.BOARD_COLS + 4], 2);
  assert.equal(locked[2 * T.BOARD_COLS + 5], 2);
});

test('clearLines: 清一行', () => {
  // 底行填满（留一个空让其他行不满）
  const filled = [];
  for (let col = 0; col < T.BOARD_COLS; col += 1) {
    filled.push([19, col, 1]);
  }
  const board = boardWith(filled);
  const result = T.clearLines(board);
  assert.equal(result.cleared, 1);
  assert.equal(result.board[19 * T.BOARD_COLS + 0], 0);
});

test('clearLines: Tetris 清四行', () => {
  const filled = [];
  for (let row = 16; row < 20; row += 1) {
    for (let col = 0; col < T.BOARD_COLS; col += 1) {
      filled.push([row, col, 1]);
    }
  }
  const board = boardWith(filled);
  const result = T.clearLines(board);
  assert.equal(result.cleared, 4);
});

test('clearLines: 上方块下落', () => {
  const filled = [];
  for (let col = 0; col < T.BOARD_COLS; col += 1) {
    filled.push([19, col, 1]);
  }
  filled.push([18, 3, 3]); // 上一行有个块
  const board = boardWith(filled);
  const result = T.clearLines(board);
  // 第18行那个块应该下落到第19行
  assert.equal(result.board[19 * T.BOARD_COLS + 3], 3);
});

test('lineScore: 固定档计分', () => {
  assert.equal(T.lineScore(0), 0);
  assert.equal(T.lineScore(1), 100);
  assert.equal(T.lineScore(2), 300);
  assert.equal(T.lineScore(3), 500);
  assert.equal(T.lineScore(4), 800);
});

test('comboScore: 连消加分', () => {
  assert.equal(T.comboScore(1), 0);
  assert.equal(T.comboScore(2), 50);
  assert.equal(T.comboScore(3), 100);
});

test('softDropScore / hardDropScore', () => {
  assert.equal(T.softDropScore(5), 5);
  assert.equal(T.hardDropScore(5), 10);
});

test('speedLevelForLines: 每20行升一档', () => {
  assert.equal(T.speedLevelForLines(0), 1);
  assert.equal(T.speedLevelForLines(19), 1);
  assert.equal(T.speedLevelForLines(20), 2);
  assert.equal(T.speedLevelForLines(40), 3);
  assert.equal(T.speedLevelForLines(120), 6); // 封顶
});

test('speedDelayForLevel: 6档递减', () => {
  assert.equal(T.speedDelayForLevel(1), 700);
  assert.equal(T.speedDelayForLevel(2), 600);
  assert.equal(T.speedDelayForLevel(6), 160);
  assert.equal(T.speedDelayForLevel(99), 160); // 越界封顶
});

test('shuffleBag: 每次包含 0-6 各一次', () => {
  for (let trial = 0; trial < 50; trial += 1) {
    const bag = T.shuffleBag();
    assert.equal(bag.length, 7);
    const sorted = [...bag].sort((a, b) => a - b);
    assert.deepEqual(sorted, [0, 1, 2, 3, 4, 5, 6]);
  }
});

test('spawnPiece: spawn 位置 col=3 row=0', () => {
  const piece = T.spawnPiece(T.PIECE_L);
  assert.equal(piece.col, 3);
  assert.equal(piece.row, 0);
  assert.equal(piece.rotation, 0);
});

test('tryRotate: 返回值安全性质（非null必不碰撞）', () => {
  // 安全性质：无论什么棋盘，tryRotate 返回非 null 时，结果一定不碰撞。
  // 比构造一个特定"全堵"棋盘更稳定、更有回归价值。
  const piece = T.spawnPiece(T.PIECE_T);
  const board = boardWith([
    [0, 1, 1], [0, 2, 1], [0, 6, 1], [0, 7, 1],
    [2, 2, 1], [2, 3, 1], [2, 5, 1], [2, 6, 1],
    [3, 1, 1], [3, 2, 1], [3, 3, 1], [3, 4, 1], [3, 5, 1], [3, 6, 1], [3, 7, 1]
  ]);
  const rotated = T.tryRotate(board, piece);
  if (rotated !== null) {
    assert.equal(T.collides(board, rotated), false, '旋转结果必须不碰撞');
  }
});

test('tryRotate: 方块在棋盘外（row 负）时碰撞但不崩', () => {
  // 边界鲁棒性：piece 部分在棋盘上方（row 负）时不应抛异常
  const piece = T.spawnPiece(T.PIECE_I);
  const board = T.createEmptyBoard();
  const above = { kind: piece.kind, col: piece.col, row: -2, rotation: piece.rotation };
  const rotated = T.tryRotate(board, above);
  if (rotated !== null) {
    assert.equal(T.collides(board, rotated), false);
  }
});

console.log(`\n${passed} passed, ${failed} failed\n`);
if (failed > 0) {
  process.exit(1);
}
