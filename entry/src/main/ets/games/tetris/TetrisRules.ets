// 俄罗斯方块纯规则层。
// 全部为纯函数：输入 board / piece / 队列，输出新数据，无 ArkUI 依赖、无副作用。
// 设计目标：可被 scripts/test-tetris-rules.mjs 加载单元测试。
//
// 关键约定：
// - 棋盘是长度 200 的数组，row * BOARD_COLS + col，0 为空，1..7 为固定块（kind + 1）。
// - 方块形态用 4x4 矩阵预定义，活动方块只记录 4x4 网格左上角棋盘坐标 (row, col)。
// - 墙踢偏移 dy 正为向下。

import {
  ActivePiece,
  Board,
  Cell,
  ClearLinesResult,
  KickOffset,
  BOARD_COLS,
  BOARD_ROWS,
  COMBO_BASE_SCORE,
  HARD_DROP_SCORE,
  LINE_SCORES,
  LINES_PER_LEVEL,
  LOCK_DELAY_MS,
  MAX_SPEED_LEVEL,
  MAX_LOCK_RESETS,
  PIECE_COUNT,
  PIECE_I,
  PIECE_J,
  PIECE_L,
  PIECE_O,
  PIECE_S,
  PIECE_T,
  PIECE_Z,
  ROTATION_0,
  ROTATION_1,
  ROTATION_2,
  ROTATION_3,
  SOFT_DROP_SCORE,
  SPEED_DELAYS,
  SPAWN_COL,
  SPAWN_ROW
} from './TetrisTypes';

// 方块 4x4 形态矩阵：SHAPES[kind][rotation][row][col] -> 0/1。
// 每种方块预定义 4 个旋转形态，运行时直接索引，不做旋转计算。
// 导出供渲染层（TetrisBoard）复用，避免两份不同步的形状表。
export const TETRIS_SHAPES: number[][][][] = [
  // I
  [
    [[0, 0, 0, 0], [1, 1, 1, 1], [0, 0, 0, 0], [0, 0, 0, 0]],
    [[0, 1, 0, 0], [0, 1, 0, 0], [0, 1, 0, 0], [0, 1, 0, 0]],
    [[0, 0, 0, 0], [1, 1, 1, 1], [0, 0, 0, 0], [0, 0, 0, 0]],
    [[0, 1, 0, 0], [0, 1, 0, 0], [0, 1, 0, 0], [0, 1, 0, 0]]
  ],
  // O（四态相同）
  [
    [[0, 0, 0, 0], [0, 1, 1, 0], [0, 1, 1, 0], [0, 0, 0, 0]],
    [[0, 0, 0, 0], [0, 1, 1, 0], [0, 1, 1, 0], [0, 0, 0, 0]],
    [[0, 0, 0, 0], [0, 1, 1, 0], [0, 1, 1, 0], [0, 0, 0, 0]],
    [[0, 0, 0, 0], [0, 1, 1, 0], [0, 1, 1, 0], [0, 0, 0, 0]]
  ],
  // T
  [
    [[0, 0, 0, 0], [1, 1, 1, 0], [0, 1, 0, 0], [0, 0, 0, 0]],
    [[0, 0, 1, 0], [0, 1, 1, 0], [0, 0, 1, 0], [0, 0, 0, 0]],
    [[0, 0, 0, 0], [0, 1, 0, 0], [1, 1, 1, 0], [0, 0, 0, 0]],
    [[0, 1, 0, 0], [0, 1, 1, 0], [0, 1, 0, 0], [0, 0, 0, 0]]
  ],
  // S
  [
    [[0, 0, 0, 0], [0, 1, 1, 0], [1, 1, 0, 0], [0, 0, 0, 0]],
    [[0, 1, 0, 0], [0, 1, 1, 0], [0, 0, 1, 0], [0, 0, 0, 0]],
    [[0, 0, 0, 0], [0, 1, 1, 0], [1, 1, 0, 0], [0, 0, 0, 0]],
    [[0, 1, 0, 0], [0, 1, 1, 0], [0, 0, 1, 0], [0, 0, 0, 0]]
  ],
  // Z
  [
    [[0, 0, 0, 0], [1, 1, 0, 0], [0, 1, 1, 0], [0, 0, 0, 0]],
    [[0, 0, 1, 0], [0, 1, 1, 0], [0, 1, 0, 0], [0, 0, 0, 0]],
    [[0, 0, 0, 0], [1, 1, 0, 0], [0, 1, 1, 0], [0, 0, 0, 0]],
    [[0, 0, 1, 0], [0, 1, 1, 0], [0, 1, 0, 0], [0, 0, 0, 0]]
  ],
  // J
  [
    [[0, 0, 0, 0], [1, 0, 0, 0], [1, 1, 1, 0], [0, 0, 0, 0]],
    [[0, 1, 1, 0], [0, 1, 0, 0], [0, 1, 0, 0], [0, 0, 0, 0]],
    [[0, 0, 0, 0], [1, 1, 1, 0], [0, 0, 1, 0], [0, 0, 0, 0]],
    [[0, 0, 1, 0], [0, 0, 1, 0], [0, 1, 1, 0], [0, 0, 0, 0]]
  ],
  // L
  [
    [[0, 0, 0, 0], [0, 0, 1, 0], [1, 1, 1, 0], [0, 0, 0, 0]],
    [[0, 1, 0, 0], [0, 1, 0, 0], [0, 1, 1, 0], [0, 0, 0, 0]],
    [[0, 0, 0, 0], [1, 1, 1, 0], [1, 0, 0, 0], [0, 0, 0, 0]],
    [[0, 1, 1, 0], [0, 0, 1, 0], [0, 0, 1, 0], [0, 0, 0, 0]]
  ]
];

// SRS 标准墙踢表（JLSTZ）。键 `${from}->${to}`，单位为格。
// 数据来自 Super Rotation System，与原 TetrisPage.ets standardWallKicks 一致。
const STANDARD_KICKS: Record<string, KickOffset[]> = {
  '0->1': [{ dx: 0, dy: 0 }, { dx: -1, dy: 0 }, { dx: -1, dy: 1 }, { dx: 0, dy: -2 }, { dx: -1, dy: -2 }],
  '1->0': [{ dx: 0, dy: 0 }, { dx: 1, dy: 0 }, { dx: 1, dy: -1 }, { dx: 0, dy: 2 }, { dx: 1, dy: 2 }],
  '1->2': [{ dx: 0, dy: 0 }, { dx: 1, dy: 0 }, { dx: 1, dy: -1 }, { dx: 0, dy: 2 }, { dx: 1, dy: 2 }],
  '2->1': [{ dx: 0, dy: 0 }, { dx: -1, dy: 0 }, { dx: -1, dy: 1 }, { dx: 0, dy: -2 }, { dx: -1, dy: -2 }],
  '2->3': [{ dx: 0, dy: 0 }, { dx: 1, dy: 0 }, { dx: 1, dy: 1 }, { dx: 0, dy: -2 }, { dx: 1, dy: -2 }],
  '3->2': [{ dx: 0, dy: 0 }, { dx: -1, dy: 0 }, { dx: -1, dy: -1 }, { dx: 0, dy: 2 }, { dx: -1, dy: 2 }],
  '3->0': [{ dx: 0, dy: 0 }, { dx: -1, dy: 0 }, { dx: -1, dy: -1 }, { dx: 0, dy: 2 }, { dx: -1, dy: 2 }],
  '0->3': [{ dx: 0, dy: 0 }, { dx: 1, dy: 0 }, { dx: 1, dy: 1 }, { dx: 0, dy: -2 }, { dx: 1, dy: -2 }]
};

// I 型专属墙踢表。与原 TetrisPage.ets iWallKicks 一致。
const I_KICKS: Record<string, KickOffset[]> = {
  '0->1': [{ dx: 0, dy: 0 }, { dx: -2, dy: 0 }, { dx: 1, dy: 0 }, { dx: -2, dy: -1 }, { dx: 1, dy: 2 }],
  '1->0': [{ dx: 0, dy: 0 }, { dx: 2, dy: 0 }, { dx: -1, dy: 0 }, { dx: 2, dy: 1 }, { dx: -1, dy: -2 }],
  '1->2': [{ dx: 0, dy: 0 }, { dx: -1, dy: 0 }, { dx: 2, dy: 0 }, { dx: -1, dy: 2 }, { dx: 2, dy: -1 }],
  '2->1': [{ dx: 0, dy: 0 }, { dx: 1, dy: 0 }, { dx: -2, dy: 0 }, { dx: 1, dy: -2 }, { dx: -2, dy: 1 }],
  '2->3': [{ dx: 0, dy: 0 }, { dx: 2, dy: 0 }, { dx: -1, dy: 0 }, { dx: 2, dy: 1 }, { dx: -1, dy: -2 }],
  '3->2': [{ dx: 0, dy: 0 }, { dx: -2, dy: 0 }, { dx: 1, dy: 0 }, { dx: -2, dy: -1 }, { dx: 1, dy: 2 }],
  '3->0': [{ dx: 0, dy: 0 }, { dx: 1, dy: 0 }, { dx: -2, dy: 0 }, { dx: 1, dy: -2 }, { dx: -2, dy: 1 }],
  '0->3': [{ dx: 0, dy: 0 }, { dx: -1, dy: 0 }, { dx: 2, dy: 0 }, { dx: -1, dy: 2 }, { dx: 2, dy: -1 }]
};

// 新建空棋盘。
export function createEmptyBoard(): Board {
  return new Array<number>(BOARD_COLS * BOARD_ROWS).fill(0);
}

// 取方块在某形态下的占地绝对坐标。
export function cellsOf(piece: ActivePiece): Cell[] {
  const shape: number[][] = TETRIS_SHAPES[piece.kind][piece.rotation];
  const cells: Cell[] = [];
  for (let row = 0; row < 4; row += 1) {
    for (let col = 0; col < 4; col += 1) {
      if (shape[row][col] === 1) {
        cells.push({ row: piece.row + row, col: piece.col + col });
      }
    }
  }
  return cells;
}

// 碰撞检测：越界或压到固定块都算碰撞。
export function collides(board: Board, piece: ActivePiece): boolean {
  const cells = cellsOf(piece);
  for (let i = 0; i < cells.length; i += 1) {
    const cell = cells[i];
    if (cell.col < 0 || cell.col >= BOARD_COLS || cell.row >= BOARD_ROWS) {
      return true;
    }
    if (cell.row >= 0 && board[cell.row * BOARD_COLS + cell.col] > 0) {
      return true;
    }
  }
  return false;
}

// 平移方块，返回新 piece（不可变风格）。
export function shifted(piece: ActivePiece, dx: number, dy: number): ActivePiece {
  return { kind: piece.kind, col: piece.col + dx, row: piece.row + dy, rotation: piece.rotation };
}

// 是否落地（下移一格即碰撞）。
export function isGrounded(board: Board, piece: ActivePiece): boolean {
  return collides(board, shifted(piece, 0, 1));
}

// 幽灵落点：当前列、当前形态下不碰撞的最低位置。
export function ghostPiece(board: Board, piece: ActivePiece): ActivePiece {
  let ghost = piece;
  while (!collides(board, shifted(ghost, 0, 1))) {
    ghost = shifted(ghost, 0, 1);
  }
  return ghost;
}

// 墙踢偏移表。
export function kickTableFor(kind: number, from: number, to: number): KickOffset[] {
  if (kind === PIECE_O) {
    return [{ dx: 0, dy: 0 }];
  }
  const key = `${from}->${to}`;
  if (kind === PIECE_I) {
    return I_KICKS[key];
  }
  return STANDARD_KICKS[key];
}

// 尝试顺时针旋转 + 墙踢。成功返回新 piece，失败返回 null。
export function tryRotate(board: Board, piece: ActivePiece): ActivePiece | null {
  const from = piece.rotation;
  const to = (piece.rotation + 1) % 4;
  const kicks = kickTableFor(piece.kind, from, to);
  for (let i = 0; i < kicks.length; i += 1) {
    const candidate = shifted({ kind: piece.kind, col: piece.col, row: piece.row, rotation: to }, kicks[i].dx, kicks[i].dy);
    if (!collides(board, candidate)) {
      return candidate;
    }
  }
  return null;
}

// 锁定方块：把活动块写回棋盘，返回新棋盘。
export function lockPiece(board: Board, piece: ActivePiece): Board {
  const next = board.slice();
  const cells = cellsOf(piece);
  for (let i = 0; i < cells.length; i += 1) {
    const cell = cells[i];
    if (cell.row >= 0 && cell.row < BOARD_ROWS && cell.col >= 0 && cell.col < BOARD_COLS) {
      next[cell.row * BOARD_COLS + cell.col] = piece.kind + 1;
    }
  }
  return next;
}

// 消行：返回新棋盘和清除的行数。
export function clearLines(board: Board): ClearLinesResult {
  const next: number[] = [];
  let cleared = 0;
  for (let row = 0; row < BOARD_ROWS; row += 1) {
    let full = true;
    for (let col = 0; col < BOARD_COLS; col += 1) {
      if (board[row * BOARD_COLS + col] === 0) {
        full = false;
        break;
      }
    }
    if (full) {
      cleared += 1;
    } else {
      for (let col = 0; col < BOARD_COLS; col += 1) {
        next.push(board[row * BOARD_COLS + col]);
      }
    }
  }
  while (next.length < BOARD_ROWS * BOARD_COLS) {
    next.unshift(0);
  }
  const result: ClearLinesResult = { board: next, cleared: cleared };
  return result;
}

// 消行计分（固定档，不乘等级）。
export function lineScore(cleared: number): number {
  if (cleared < 1 || cleared > 4) {
    return 0;
  }
  return LINE_SCORES[cleared];
}

// 连消加分：combo > 1 时生效。
export function comboScore(combo: number): number {
  if (combo <= 1) {
    return 0;
  }
  return (combo - 1) * COMBO_BASE_SCORE;
}

// 软降得分（每格）。
export function softDropScore(cells: number): number {
  return cells * SOFT_DROP_SCORE;
}

// 硬降得分（每格）。
export function hardDropScore(cells: number): number {
  return cells * HARD_DROP_SCORE;
}

// 按已消总行数算速度等级（1..6）。
export function speedLevelForLines(totalLines: number): number {
  const level = Math.floor(totalLines / LINES_PER_LEVEL) + 1;
  return Math.min(level, MAX_SPEED_LEVEL);
}

// 速度等级对应下落间隔。
export function speedDelayForLevel(level: number): number {
  const index = Math.max(0, Math.min(SPEED_DELAYS.length - 1, level - 1));
  return SPEED_DELAYS[index];
}

// 7-bag：返回打乱后的 [0..6]。
export function shuffleBag(): number[] {
  const bag = [0, 1, 2, 3, 4, 5, 6];
  for (let i = bag.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    const value = bag[i];
    bag[i] = bag[j];
    bag[j] = value;
  }
  return bag;
}

// 生成活动方块（spawn 位置）。
export function spawnPiece(kind: number): ActivePiece {
  return { kind: kind, col: SPAWN_COL, row: SPAWN_ROW, rotation: 0 };
}

export const TETRIS_LOCK_DELAY_MS = LOCK_DELAY_MS;
export const TETRIS_MAX_LOCK_RESETS = MAX_LOCK_RESETS;
