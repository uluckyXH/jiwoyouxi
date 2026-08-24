import {
  AchievementDefinition,
  AchievementGroupDefinition
} from './AchievementModule';

export const ACHIEVEMENT_PRIMARY_GAME_IDS: string[] = [
  'rpsBattle',
  'freecell',
  'minesweeper',
  'chicken2048',
  'tetris',
  'suika'
];

export const ACHIEVEMENT_GROUPS: AchievementGroupDefinition[] = [
  {
    id: 'global',
    title: '合集里程碑',
    gameId: 'global',
    placeholderSymbol: '✦'
  },
  {
    id: 'rpsBattle',
    title: '石头剪刀布大作战',
    gameId: 'rpsBattle',
    placeholderSymbol: '✊'
  },
  {
    id: 'freecell',
    title: '空当接龙',
    gameId: 'freecell',
    placeholderSymbol: '♣'
  },
  {
    id: 'minesweeper',
    title: '扫雷',
    gameId: 'minesweeper',
    placeholderSymbol: '✹'
  },
  {
    id: 'chicken2048',
    title: '鸡窝 2048',
    gameId: 'chicken2048',
    placeholderSymbol: '◆'
  },
  {
    id: 'tetris',
    title: '俄罗斯方块',
    gameId: 'tetris',
    placeholderSymbol: '▣'
  },
  {
    id: 'suika',
    title: '鸡窝水果摊',
    gameId: 'suika',
    placeholderSymbol: '◉'
  }
];

export const ACHIEVEMENT_DEFINITIONS: AchievementDefinition[] = [
  {
    id: 'global.first_settlement',
    groupId: 'global',
    gameId: 'global',
    title: '鸡窝开张',
    summary: '完成任意一局',
    detail: '在六款主推游戏中完成任意一局。',
    placeholderSymbol: '✦',
    progressKind: 'totalSessions',
    target: 1
  },
  {
    id: 'global.play_six_games',
    groupId: 'global',
    gameId: 'global',
    title: '六边形鸡仔',
    summary: '体验六款主推游戏',
    detail: '分别完成石头剪刀布大作战、空当接龙、扫雷、2048、' +
      '俄罗斯方块和鸡窝水果摊各一局。',
    placeholderSymbol: '✦',
    progressKind: 'playedGames',
    target: 6
  },
  {
    id: 'global.favorite_three',
    groupId: 'global',
    gameId: 'global',
    title: '收藏家',
    summary: '收藏 3 个常玩游戏',
    detail: '在大厅收藏三款主推游戏。',
    placeholderSymbol: '✦',
    progressKind: 'favoriteCount',
    target: 3
  },
  {
    id: 'global.complete_ten_sessions',
    groupId: 'global',
    gameId: 'global',
    title: '常驻鸡仔',
    summary: '完成 10 局游戏',
    detail: '在六款主推游戏中累计完成十局。',
    placeholderSymbol: '✦',
    progressKind: 'totalSessions',
    target: 10
  },
  {
    id: 'rpsBattle.first_battle',
    groupId: 'rpsBattle',
    gameId: 'rpsBattle',
    title: '初入战场',
    summary: '完成任意一局新版乱斗',
    detail: '在新版石头剪刀布大作战完成一局正式对战。',
    placeholderSymbol: '✊',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'rpsBattle.supporter_wins',
    groupId: 'rpsBattle',
    gameId: 'rpsBattle',
    title: '押中阵营',
    summary: '支持的阵营赢得一局',
    detail: '在正式对战中，让你支持的阵营赢得一局。',
    placeholderSymbol: '✊',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'rpsBattle.conversion_storm',
    groupId: 'rpsBattle',
    gameId: 'rpsBattle',
    title: '转化风暴',
    summary: '见证一局高密度阵营转化',
    detail: '在一局正式对战中达到待校准的阵营转化次数。',
    placeholderSymbol: '✊',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'freecell.complete_board',
    groupId: 'freecell',
    gameId: 'freecell',
    title: '纸牌归位',
    summary: '完成一局空当接龙',
    detail: '将四个花色全部整理到基础牌堆。',
    placeholderSymbol: '♣',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'freecell.efficient_win',
    groupId: 'freecell',
    gameId: 'freecell',
    title: '精打细算',
    summary: '用较少步数完成一局',
    detail: '在待校准的步数以内完成一局空当接龙。',
    placeholderSymbol: '♣',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'freecell.quick_win',
    groupId: 'freecell',
    gameId: 'freecell',
    title: '疾速清台',
    summary: '在合理时间内完成一局',
    detail: '在待校准的时间以内完成一局空当接龙。',
    placeholderSymbol: '♣',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'minesweeper.first_clear',
    groupId: 'minesweeper',
    gameId: 'minesweeper',
    title: '雷区通关',
    summary: '首次成功排雷',
    detail: '在正式局中成功打开所有安全格。',
    placeholderSymbol: '✹',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'minesweeper.quick_clear',
    groupId: 'minesweeper',
    gameId: 'minesweeper',
    title: '迅捷排雷',
    summary: '在目标时间内完成雷区',
    detail: '在指定难度与待校准时间内完成一局扫雷。',
    placeholderSymbol: '✹',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'minesweeper.perfect_flags',
    groupId: 'minesweeper',
    gameId: 'minesweeper',
    title: '旗帜无误',
    summary: '正确标记本局全部地雷',
    detail: '在正式局中手动正确标记全部地雷，且没有错误插旗。',
    placeholderSymbol: '✹',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'chicken2048.reach_256',
    groupId: 'chicken2048',
    gameId: 'chicken2048',
    title: '合成小能手',
    summary: '最大方块达到 256',
    detail: '在一局正式的鸡窝 2048 中首次合成 256 方块。',
    placeholderSymbol: '◆',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'chicken2048.reach_1024',
    groupId: 'chicken2048',
    gameId: 'chicken2048',
    title: '千格高手',
    summary: '最大方块达到 1024',
    detail: '在一局正式的鸡窝 2048 中首次合成 1024 方块。',
    placeholderSymbol: '◆',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'chicken2048.reach_2048',
    groupId: 'chicken2048',
    gameId: 'chicken2048',
    title: '2048 达成',
    summary: '最大方块达到 2048',
    detail: '在一局正式的鸡窝 2048 中首次合成 2048 方块。',
    placeholderSymbol: '◆',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'tetris.first_tetris',
    groupId: 'tetris',
    gameId: 'tetris',
    title: '第一记四消',
    summary: '单次消除 4 行',
    detail: '在一局俄罗斯方块中完成一次四消。',
    placeholderSymbol: '▣',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'tetris.twenty_lines',
    groupId: 'tetris',
    gameId: 'tetris',
    title: '清行不停',
    summary: '单局累计消除 20 行',
    detail: '在同一局俄罗斯方块中累计消除二十行。',
    placeholderSymbol: '▣',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'tetris.level_three',
    groupId: 'tetris',
    gameId: 'tetris',
    title: '方块进阶',
    summary: '达到等级 3',
    detail: '在同一局俄罗斯方块中达到等级 3。',
    placeholderSymbol: '▣',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'suika.score_600',
    groupId: 'suika',
    gameId: 'suika',
    title: '瓜摊开张',
    summary: '本局分数达到 600',
    detail: '在一局鸡窝水果摊中达到 600 分。',
    placeholderSymbol: '◉',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'suika.make_watermelon',
    groupId: 'suika',
    gameId: 'suika',
    title: '西瓜到手',
    summary: '首次合成西瓜',
    detail: '在一局鸡窝水果摊中首次合成普通西瓜。',
    placeholderSymbol: '◉',
    progressKind: 'none',
    target: 0
  },
  {
    id: 'suika.final_merge',
    groupId: 'suika',
    gameId: 'suika',
    title: '瓜王诞生',
    summary: '完成最终合成',
    detail: '在一局鸡窝水果摊中完成最终水果合成。',
    placeholderSymbol: '◉',
    progressKind: 'none',
    target: 0
  }
];

export function achievementDefinitionFor(id: string): AchievementDefinition | undefined {
  return ACHIEVEMENT_DEFINITIONS.find((item: AchievementDefinition) => item.id === id);
}
