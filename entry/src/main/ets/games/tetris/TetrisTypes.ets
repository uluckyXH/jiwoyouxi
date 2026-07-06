// 俄罗斯方块类型、常量与数据定义。
// 仅放数据，不依赖 ArkUI，便于规则层被单元测试加载。
// 为兼容 node 规则测试（stripTypeScriptTypes），不使用 enum，统一用数字常量。

export const BOARD_COLS: number = 10;
export const BOARD_ROWS: number = 20;
export const SPAWN_COL: number = 3;
export const SPAWN_ROW: number = 0;

// 7 种方块索引，与 PIECE_COLORS / SHAPES 对齐。
export const PIECE_I: number = 0;
export const PIECE_O: number = 1;
export const PIECE_T: number = 2;
export const PIECE_S: number = 3;
export const PIECE_Z: number = 4;
export const PIECE_J: number = 5;
export const PIECE_L: number = 6;
export const PIECE_COUNT: number = 7;

// 旋转方向：0 上、1 右(顺时针一次)、2 下、3 左。
export const ROTATION_0: number = 0;
export const ROTATION_1: number = 1;
export const ROTATION_2: number = 2;
export const ROTATION_3: number = 3;

// 方块的绝对棋盘坐标（y 向下为正）。
export interface Cell {
  row: number;
  col: number;
}

// 活动方块：4x4 网格左上角的棋盘坐标 + 形态索引。
export interface ActivePiece {
  kind: number;
  col: number;
  row: number;
  rotation: number;
}

export type Board = number[];

export interface ClearLinesResult {
  board: Board;
  cleared: number;
}

// 墙踢偏移：dx 正为向右，dy 正为向下。
export interface KickOffset {
  dx: number;
  dy: number;
}

// 游戏状态机。用数字常量而不是 enum，保持 node 规则测试加载简单。
export const TETRIS_PHASE_SPAWNING: number = 0;
export const TETRIS_PHASE_FALLING: number = 1;
export const TETRIS_PHASE_LOCKING: number = 2;
export const TETRIS_PHASE_CLEARING: number = 3;
export const TETRIS_PHASE_PAUSED: number = 4;
export const TETRIS_PHASE_GAME_OVER: number = 5;

// 方块颜色（kind -> 颜色），UI 与 Canvas 共用。
export const PIECE_COLORS: string[] = [
  '#06b6d4', // I
  '#eab308', // O
  '#8b5cf6', // T
  '#22c55e', // S
  '#ef4444', // Z
  '#3b82f6', // J
  '#f97316'  // L
];

// 消行得分（固定档，不乘等级，对应 1/2/3/4 行）。index 0 不可达，留 0。
export const LINE_SCORES: number[] = [0, 100, 300, 500, 800];

// 软降每格得分、硬降每格得分、连消基础分。
export const SOFT_DROP_SCORE: number = 1;
export const HARD_DROP_SCORE: number = 2;
export const COMBO_BASE_SCORE: number = 50;

// 6 档下落间隔（毫秒）。index 0 对应等级 1。
export const SPEED_DELAYS: number[] = [700, 600, 450, 320, 240, 160];
export const MAX_SPEED_LEVEL: number = 6;

// 每消多少行升一档速度。
export const LINES_PER_LEVEL: number = 20;

// 锁定延迟参数。
export const LOCK_DELAY_MS: number = 500;
export const MAX_LOCK_RESETS: number = 15;
