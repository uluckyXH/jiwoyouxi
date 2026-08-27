import {
  AchievementDefinition,
  AchievementFactCondition,
  AchievementGroupDefinition,
  AchievementRule,
  GameAchievementProfile
} from './AchievementModule';

export const ACHIEVEMENT_PRIMARY_GAME_IDS: string[] = [
  'rpsBattle',
  'freecell',
  'minesweeper',
  'chicken2048',
  'tetris',
  'suika'
];

const ACHIEVEMENT_BADGE_ASSET_DIRECTORY: string = 'app/achievements/';

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

export const GAME_ACHIEVEMENT_PROFILES: GameAchievementProfile[] = [
  {
    gameId: 'rpsBattle',
    factKeys: ['won', 'supportWon', 'elapsedSec', 'conversions', 'score']
  },
  {
    gameId: 'freecell',
    factKeys: ['won', 'moves', 'elapsedSec', 'score']
  },
  {
    gameId: 'minesweeper',
    factKeys: ['won', 'elapsedSec', 'manualAllMinesFlagged', 'hasEverFlaggedNonMine']
  },
  {
    gameId: 'chicken2048',
    factKeys: ['maxTile', 'movesMade', 'score']
  },
  {
    gameId: 'tetris',
    factKeys: ['score', 'totalLines', 'level', 'maxClearedLines']
  },
  {
    gameId: 'suika',
    factKeys: ['score', 'droppedCount', 'highestMergeLevel', 'madeWatermelon', 'isFinalMerge']
  }
];

export const ACHIEVEMENT_DEFINITIONS: AchievementDefinition[] = [
  {
    id: 'global.first_settlement',
    groupId: 'global',
    gameId: 'global',
    title: '鸡窝开张',
    summary: '完成任意一局',
    detail: '在六款主推游戏中完成任意一局正式游戏。',
    placeholderSymbol: '✦',
    badgeAssetPath: '',
    progressKind: 'totalSessions',
    target: 1,
    rule: { type: 'globalCompletedSessionsAtLeast', target: 1 },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'global.play_six_games',
    groupId: 'global',
    gameId: 'global',
    title: '六边形鸡仔',
    summary: '体验六款主推游戏',
    detail: '分别完成六款主推游戏各一局正式游戏。',
    placeholderSymbol: '✦',
    badgeAssetPath: '',
    progressKind: 'playedGames',
    target: 6,
    rule: { type: 'globalPlayedGamesAtLeast', target: 6 },
    enabled: true,
    noticeLevel: 'highlight'
  },
  {
    id: 'global.favorite_three',
    groupId: 'global',
    gameId: 'global',
    title: '收藏家',
    summary: '收藏 3 个常玩游戏',
    detail: '当前独立事件核心不读取收藏记录；后续确认大厅事件后再启用。',
    placeholderSymbol: '✦',
    badgeAssetPath: '',
    progressKind: 'favoriteCount',
    target: 3,
    rule: { type: 'disabled' },
    enabled: false,
    noticeLevel: 'normal'
  },
  {
    id: 'global.complete_ten_sessions',
    groupId: 'global',
    gameId: 'global',
    title: '常驻鸡仔',
    summary: '完成 10 局游戏',
    detail: '在六款主推游戏中累计完成十局正式游戏。',
    placeholderSymbol: '✦',
    badgeAssetPath: '',
    progressKind: 'totalSessions',
    target: 10,
    rule: { type: 'globalCompletedSessionsAtLeast', target: 10 },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'rpsBattle.first_battle',
    groupId: 'rpsBattle',
    gameId: 'rpsBattle',
    title: '初入战场',
    summary: '完成任意一局新版乱斗',
    detail: '在新版石头剪刀布大作战完成一局正式对战。',
    placeholderSymbol: '✊',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 1,
    rule: { type: 'eventObserved', eventType: 'sessionEnd' },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'rpsBattle.supporter_wins',
    groupId: 'rpsBattle',
    gameId: 'rpsBattle',
    title: '押中阵营',
    summary: '支持的阵营赢得一局',
    detail: '在正式对战中，让你支持的阵营赢得一局。',
    placeholderSymbol: '✊',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 1,
    rule: {
      type: 'eventAllFacts',
      eventType: 'sessionEnd',
      conditions: [
        { key: 'won', comparison: 'equals', value: 1 },
        { key: 'supportWon', comparison: 'equals', value: 1 }
      ]
    },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'rpsBattle.conversion_storm',
    groupId: 'rpsBattle',
    gameId: 'rpsBattle',
    title: '转化风暴',
    summary: '见证一局高密度阵营转化',
    detail: '阵营转化阈值待校准，确认前不参与判定。',
    placeholderSymbol: '✊',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 1,
    rule: { type: 'disabled' },
    enabled: false,
    noticeLevel: 'highlight'
  },
  {
    id: 'freecell.complete_board',
    groupId: 'freecell',
    gameId: 'freecell',
    title: '纸牌归位',
    summary: '完成一局空当接龙',
    detail: '将四个花色全部整理到基础牌堆。',
    placeholderSymbol: '♣',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 1,
    rule: {
      type: 'eventFact',
      eventType: 'sessionEnd',
      condition: { key: 'won', comparison: 'equals', value: 1 }
    },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'freecell.efficient_win',
    groupId: 'freecell',
    gameId: 'freecell',
    title: '精打细算',
    summary: '用较少步数完成一局',
    detail: '步数阈值待校准，确认前不参与判定。',
    placeholderSymbol: '♣',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 1,
    rule: { type: 'disabled' },
    enabled: false,
    noticeLevel: 'normal'
  },
  {
    id: 'freecell.quick_win',
    groupId: 'freecell',
    gameId: 'freecell',
    title: '疾速清台',
    summary: '在合理时间内完成一局',
    detail: '时间阈值待校准，确认前不参与判定。',
    placeholderSymbol: '♣',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 1,
    rule: { type: 'disabled' },
    enabled: false,
    noticeLevel: 'highlight'
  },
  {
    id: 'minesweeper.first_clear',
    groupId: 'minesweeper',
    gameId: 'minesweeper',
    title: '平安出窝',
    summary: '首次成功排雷',
    detail: '在一局正式扫雷中成功打开所有安全格。',
    placeholderSymbol: '✹',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 1,
    rule: {
      type: 'eventFact',
      eventType: 'sessionEnd',
      condition: { key: 'won', comparison: 'equals', value: 1 }
    },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'minesweeper.quick_clear',
    groupId: 'minesweeper',
    gameId: 'minesweeper',
    title: '迅捷排雷',
    summary: '60 秒内完成雷区',
    detail: '在一局正式扫雷中于 60 秒内完成雷区。',
    placeholderSymbol: '✹',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 1,
    rule: {
      type: 'eventAllFacts',
      eventType: 'sessionEnd',
      conditions: [
        { key: 'won', comparison: 'equals', value: 1 },
        { key: 'elapsedSec', comparison: 'atMost', value: 60 }
      ]
    },
    enabled: true,
    noticeLevel: 'highlight'
  },
  {
    id: 'minesweeper.perfect_flags',
    groupId: 'minesweeper',
    gameId: 'minesweeper',
    title: '旗开得胜',
    summary: '十旗全对完成通关',
    detail: '在一局正式扫雷中手动正确插满十面旗并完成通关。',
    placeholderSymbol: '✹',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 1,
    rule: {
      type: 'eventAllFacts',
      eventType: 'sessionEnd',
      conditions: [
        { key: 'won', comparison: 'equals', value: 1 },
        { key: 'manualAllMinesFlagged', comparison: 'equals', value: 1 },
        { key: 'hasEverFlaggedNonMine', comparison: 'equals', value: 0 }
      ]
    },
    enabled: true,
    noticeLevel: 'highlight'
  },
  {
    id: 'chicken2048.reach_256',
    groupId: 'chicken2048',
    gameId: 'chicken2048',
    title: '合成小能手',
    summary: '最大方块达到 256',
    detail: '在一局正式的鸡窝 2048 中首次合成 256 方块。',
    placeholderSymbol: '◆',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 256,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'maxTile', comparison: 'atLeast', value: 256 }
    },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'chicken2048.reach_1024',
    groupId: 'chicken2048',
    gameId: 'chicken2048',
    title: '千格高手',
    summary: '最大方块达到 1024',
    detail: '在一局正式的鸡窝 2048 中首次合成 1024 方块。',
    placeholderSymbol: '◆',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 1024,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'maxTile', comparison: 'atLeast', value: 1024 }
    },
    enabled: true,
    noticeLevel: 'highlight'
  },
  {
    id: 'chicken2048.reach_2048',
    groupId: 'chicken2048',
    gameId: 'chicken2048',
    title: '2048 达成',
    summary: '最大方块达到 2048',
    detail: '在一局正式的鸡窝 2048 中首次合成 2048 方块。',
    placeholderSymbol: '◆',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 2048,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'maxTile', comparison: 'atLeast', value: 2048 }
    },
    enabled: true,
    noticeLevel: 'highlight'
  },
  {
    id: 'tetris.first_tetris',
    groupId: 'tetris',
    gameId: 'tetris',
    title: '第一记四消',
    summary: '单次消除 4 行',
    detail: '在一局俄罗斯方块中完成一次四消。',
    placeholderSymbol: '▣',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 4,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'maxClearedLines', comparison: 'atLeast', value: 4 }
    },
    enabled: true,
    noticeLevel: 'highlight'
  },
  {
    id: 'tetris.twenty_lines',
    groupId: 'tetris',
    gameId: 'tetris',
    title: '清行不停',
    summary: '单局累计消除 20 行',
    detail: '在同一局俄罗斯方块中累计消除二十行。',
    placeholderSymbol: '▣',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 20,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'totalLines', comparison: 'atLeast', value: 20 }
    },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'tetris.level_three',
    groupId: 'tetris',
    gameId: 'tetris',
    title: '方块进阶',
    summary: '达到等级 3',
    detail: '在同一局俄罗斯方块中达到等级 3。',
    placeholderSymbol: '▣',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 3,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'level', comparison: 'atLeast', value: 3 }
    },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'suika.score_600',
    groupId: 'suika',
    gameId: 'suika',
    title: '瓜摊开张',
    summary: '本局分数达到 600',
    detail: '在一局鸡窝水果摊中达到 600 分。',
    placeholderSymbol: '◉',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 600,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'score', comparison: 'atLeast', value: 600 }
    },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'suika.make_watermelon',
    groupId: 'suika',
    gameId: 'suika',
    title: '西瓜到手',
    summary: '首次合成西瓜',
    detail: '在一局鸡窝水果摊中首次合成普通西瓜。',
    placeholderSymbol: '◉',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 1,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'madeWatermelon', comparison: 'equals', value: 1 }
    },
    enabled: true,
    noticeLevel: 'highlight'
  },
  {
    id: 'suika.final_merge',
    groupId: 'suika',
    gameId: 'suika',
    title: '瓜王诞生',
    summary: '完成最终合成',
    detail: '在一局鸡窝水果摊中完成最终水果合成。',
    placeholderSymbol: '◉',
    badgeAssetPath: '',
    progressKind: 'none',
    target: 1,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'isFinalMerge', comparison: 'equals', value: 1 }
    },
    enabled: true,
    noticeLevel: 'highlight'
  }
];

export function achievementDefinitionFor(id: string): AchievementDefinition | undefined {
  return ACHIEVEMENT_DEFINITIONS.find((item: AchievementDefinition) => item.id === id);
}

export function achievementProfileFor(gameId: string): GameAchievementProfile | undefined {
  return GAME_ACHIEVEMENT_PROFILES.find((item: GameAchievementProfile) => item.gameId === gameId);
}

export function isAchievementFactKeyAllowed(gameId: string, factKey: string): boolean {
  const profile = achievementProfileFor(gameId);
  return profile !== undefined && profile.factKeys.includes(factKey);
}

export function isAchievementBadgeAssetPathValid(badgeAssetPath: string): boolean {
  return badgeAssetPath.length === 0 || (badgeAssetPath.startsWith(ACHIEVEMENT_BADGE_ASSET_DIRECTORY) &&
    badgeAssetPath.endsWith('.png'));
}

function ruleFactKeys(rule: AchievementRule): string[] {
  if (rule.type === 'eventFact') {
    return [rule.condition.key];
  }
  if (rule.type === 'eventAllFacts') {
    const keys: string[] = [];
    rule.conditions.forEach((condition: AchievementFactCondition) => {
      if (!keys.includes(condition.key)) {
        keys.push(condition.key);
      }
    });
    return keys;
  }
  return [];
}

export function achievementRegistryIssues(): string[] {
  const issues: string[] = [];
  const ids: string[] = [];
  ACHIEVEMENT_DEFINITIONS.forEach((definition: AchievementDefinition) => {
    if (definition.id.length === 0 || ids.includes(definition.id)) {
      issues.push(`duplicate-or-empty-id:${definition.id}`);
    }
    ids.push(definition.id);
    if (!Number.isFinite(definition.target) || definition.target <= 0) {
      issues.push(`invalid-target:${definition.id}`);
    }
    if (definition.gameId !== 'global' && achievementProfileFor(definition.gameId) === undefined) {
      issues.push(`missing-profile:${definition.id}`);
    }
    if (definition.enabled && definition.rule.type === 'disabled') {
      issues.push(`enabled-disabled-rule:${definition.id}`);
    }
    if (!definition.enabled && definition.rule.type !== 'disabled') {
      issues.push(`disabled-active-rule:${definition.id}`);
    }
    if (!isAchievementBadgeAssetPathValid(definition.badgeAssetPath)) {
      issues.push(`invalid-badge-asset-path:${definition.id}`);
    }
    if (definition.gameId !== 'global') {
      ruleFactKeys(definition.rule).forEach((factKey: string) => {
        if (!isAchievementFactKeyAllowed(definition.gameId, factKey)) {
          issues.push(`unknown-rule-fact:${definition.id}:${factKey}`);
        }
      });
    }
  });
  return issues;
}
