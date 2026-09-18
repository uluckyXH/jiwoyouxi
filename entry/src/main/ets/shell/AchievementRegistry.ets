import {
  AchievementDefinition,
  AchievementEventType,
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

// Source routes are separate from stable badge/storage IDs. Legacy games cannot report.
export const ACHIEVEMENT_SOURCE_GAME_IDS: string[] = [
  'rpsBattleNext', 'freecellNext', 'minesweeperNext', 'chicken2048Next', 'tetrisNext', 'suikaNext'
];
export function isAchievementSourceGameId(gameId: string): boolean {
  return ACHIEVEMENT_SOURCE_GAME_IDS.includes(gameId);
}

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
    title: '鸡窝乱斗 · 庭院擂台',
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
    title: '俄罗斯方块 · 方块工坊',
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
    gameId: 'global',
    factKeys: ['favoriteCount'],
    eventTypes: ['milestone']
  },
  {
    gameId: 'rpsBattle',
    factKeys: ['won', 'supportWon', 'elapsedSec', 'conversions', 'score'],
    eventTypes: ['sessionEnd', 'milestone']
  },
  {
    gameId: 'freecell',
    factKeys: ['won', 'moves', 'elapsedSec', 'score'],
    eventTypes: ['sessionEnd', 'milestone']
  },
  {
    gameId: 'minesweeper',
    factKeys: ['won', 'elapsedSec', 'manualAllMinesFlagged', 'hasEverFlaggedNonMine'],
    eventTypes: ['sessionEnd', 'milestone']
  },
  {
    gameId: 'chicken2048',
    factKeys: ['maxTile', 'movesMade', 'score'],
    eventTypes: ['sessionEnd', 'milestone']
  },
  {
    gameId: 'tetris',
    factKeys: ['score', 'totalLines', 'level', 'maxClearedLines'],
    eventTypes: ['sessionEnd', 'milestone']
  },
  {
    gameId: 'suika',
    factKeys: ['score', 'droppedCount', 'highestMergeLevel', 'madeWatermelon', 'isFinalMerge'],
    eventTypes: ['sessionEnd', 'milestone']
  }
];

export const ACHIEVEMENT_DEFINITIONS: AchievementDefinition[] = [
  {
    id: 'global.first_settlement',
    groupId: 'global',
    gameId: 'global',
    title: '鸡窝开张',
    summary: '首次完成一局游戏',
    detail: '在任意一款重构新版游戏中正常结束一局。胜负都算，主动退出和重开不计入；旧版不计入。',
    placeholderSymbol: '✦',
    badgeAssetPath: 'app/achievements/ach_global_first_settlement.svg',
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
    summary: '六款游戏各完成一局',
    detail: '六款重构新版游戏各正常结束一局。同一款重复游玩只算一种；空当接龙需通关，旧版不计入。',
    placeholderSymbol: '✦',
    badgeAssetPath: 'app/achievements/ach_global_play_six_games.svg',
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
    summary: '收藏三款新版游戏',
    detail: '在大厅收藏三款重构新版游戏，保存成功后解锁。旧版收藏不计入；达成后取消收藏，勋章仍会保留。',
    placeholderSymbol: '✦',
    badgeAssetPath: 'app/achievements/ach_global_favorite_three.svg',
    progressKind: 'favoriteCount',
    target: 3,
    rule: {
      type: 'eventFact',
      eventType: 'milestone',
      condition: { key: 'favoriteCount', comparison: 'atLeast', value: 3 }
    },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'global.complete_ten_sessions',
    groupId: 'global',
    gameId: 'global',
    title: '常驻鸡仔',
    summary: '累计完成十局游戏',
    detail: '在重构新版游戏中累计正常结束十局，可以重复游玩同一款。旧版、主动退出和重开不计入。',
    placeholderSymbol: '✦',
    badgeAssetPath: 'app/achievements/ach_global_complete_ten_sessions.svg',
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
    title: '庭院初见',
    summary: '完成一局庭院擂台',
    detail: '在新版庭院擂台正常结束一局，胜负都算。快速乱斗、据点、挑战和自定义事件局均可；主动退出和重开不计入。',
    placeholderSymbol: '✊',
    badgeAssetPath: 'app/achievements/ach_rps_battle_first_battle.svg',
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
    title: '小队首胜',
    summary: '自己的小队赢得一局',
    detail: '在新版庭院擂台获得一次胜利。不限模式、人数或庭院事件，也可以从第一关挑战开始。',
    placeholderSymbol: '✊',
    badgeAssetPath: 'app/achievements/ach_rps_battle_supporter_wins.svg',
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
    title: '热闹开场',
    summary: '一局发生 12 次转阵',
    detail: '正常结束一局新版庭院擂台，整场累计发生至少 12 次转阵。所有小队的转阵都算，自定义事件局也计入。',
    placeholderSymbol: '✊',
    badgeAssetPath: 'app/achievements/ach_rps_battle_conversion_storm.svg',
    progressKind: 'none',
    target: 12,
    rule: { type: 'eventFact', eventType: 'sessionEnd',
      condition: { key: 'conversions', comparison: 'atLeast', value: 12 } },
    enabled: true,
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
    badgeAssetPath: 'app/achievements/ach_freecell_complete_board.svg',
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
    summary: '200 步内完成一局',
    detail: '在 200 步以内将四个花色全部归位。以本局面板显示的步数为准，可以使用提示、撤销和自动整理。',
    placeholderSymbol: '♣',
    badgeAssetPath: 'app/achievements/ach_freecell_efficient_win.svg',
    progressKind: 'none',
    target: 1,
    rule: { type: 'eventAllFacts', eventType: 'sessionEnd', conditions: [
      { key: 'won', comparison: 'equals', value: 1 },
      { key: 'moves', comparison: 'atMost', value: 200 }
    ] },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'freecell.quick_win',
    groupId: 'freecell',
    gameId: 'freecell',
    title: '疾速清台',
    summary: '15 分钟内完成一局',
    detail: '在 15 分钟内将四个花色全部归位。可以使用自动整理，暂停和离开期间不计时。',
    placeholderSymbol: '♣',
    badgeAssetPath: 'app/achievements/ach_freecell_quick_win.svg',
    progressKind: 'none',
    target: 1,
    rule: { type: 'eventAllFacts', eventType: 'sessionEnd', conditions: [
      { key: 'won', comparison: 'equals', value: 1 },
      { key: 'elapsedSec', comparison: 'atMost', value: 900 }
    ] },
    enabled: true,
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
    badgeAssetPath: 'app/achievements/ach_minesweeper_first_clear.svg',
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
    summary: '3 分钟内完成雷区',
    detail: '在任意难度的庭院探雷中，于 3 分钟内打开所有安全格。暂停期间不计时。',
    placeholderSymbol: '✹',
    badgeAssetPath: 'app/achievements/ach_minesweeper_quick_clear.svg',
    progressKind: 'none',
    target: 1,
    rule: {
      type: 'eventAllFacts',
      eventType: 'sessionEnd',
      conditions: [
        { key: 'won', comparison: 'equals', value: 1 },
        { key: 'elapsedSec', comparison: 'atMost', value: 180 }
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
    summary: '标出全部地雷并通关',
    detail: '在任意难度通关前，手动为所有地雷插旗。允许撤旗改正；通关后自动补上的旗不计入。',
    placeholderSymbol: '✹',
    badgeAssetPath: 'app/achievements/ach_minesweeper_perfect_flags.svg',
    progressKind: 'none',
    target: 1,
    rule: {
      type: 'eventAllFacts',
      eventType: 'sessionEnd',
      conditions: [
        { key: 'won', comparison: 'equals', value: 1 },
        { key: 'manualAllMinesFlagged', comparison: 'equals', value: 1 }
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
    detail: '在暖光叠数中合成 256 方块，达成时即可解锁，无需等到本局结束。',
    placeholderSymbol: '◆',
    badgeAssetPath: 'app/achievements/ach_chicken2048_reach_256.svg',
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
    // Stable badge IDs preserve earned medals when the targets become gentler.
    id: 'chicken2048.reach_1024',
    groupId: 'chicken2048',
    gameId: 'chicken2048',
    title: '叠数渐佳',
    summary: '最大方块达到 512',
    detail: '在暖光叠数中合成 512 方块，达成时即可解锁。',
    placeholderSymbol: '◆',
    badgeAssetPath: 'app/achievements/ach_chicken2048_reach_1024.svg',
    progressKind: 'none',
    target: 512,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'maxTile', comparison: 'atLeast', value: 512 }
    },
    enabled: true,
    noticeLevel: 'highlight'
  },
  {
    id: 'chicken2048.reach_2048',
    groupId: 'chicken2048',
    gameId: 'chicken2048',
    title: '千格暖光',
    summary: '最大方块达到 1024',
    detail: '在暖光叠数中合成 1024 方块，达成时即可解锁。继续挑战 2048 不影响领取勋章。',
    placeholderSymbol: '◆',
    badgeAssetPath: 'app/achievements/ach_chicken2048_reach_2048.svg',
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
    id: 'tetris.first_tetris',
    groupId: 'tetris',
    gameId: 'tetris',
    title: '第一行光',
    summary: '消除第一行方块',
    detail: '在新版方块工坊中完成一次消行，消除一行即可，不必四消。',
    placeholderSymbol: '▣',
    badgeAssetPath: 'app/achievements/ach_tetris_first_tetris.svg',
    progressKind: 'none',
    target: 1,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'maxClearedLines', comparison: 'atLeast', value: 1 }
    },
    enabled: true,
    noticeLevel: 'highlight'
  },
  {
    id: 'tetris.twenty_lines',
    groupId: 'tetris',
    gameId: 'tetris',
    title: '清行不停',
    summary: '单局累计消除 5 行',
    detail: '在同一局新版方块工坊中累计消除五行，可以逐行完成。',
    placeholderSymbol: '▣',
    badgeAssetPath: 'app/achievements/ach_tetris_twenty_lines.svg',
    progressKind: 'none',
    target: 5,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'totalLines', comparison: 'atLeast', value: 5 }
    },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'tetris.level_three',
    groupId: 'tetris',
    gameId: 'tetris',
    title: '方块进阶',
    summary: '单局累计消除 10 行',
    detail: '在同一局新版方块工坊中累计消除十行，无需达到高速等级。',
    placeholderSymbol: '▣',
    badgeAssetPath: 'app/achievements/ach_tetris_level_three.svg',
    progressKind: 'none',
    target: 10,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'totalLines', comparison: 'atLeast', value: 10 }
    },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'suika.score_600',
    groupId: 'suika',
    gameId: 'suika',
    title: '瓜摊开张',
    summary: '本局分数达到 100',
    detail: '在一局新版鸡窝水果摊中达到 100 分，达到时即可解锁。',
    placeholderSymbol: '◉',
    badgeAssetPath: 'app/achievements/ach_suika_score_600.svg',
    progressKind: 'none',
    target: 100,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'score', comparison: 'atLeast', value: 100 }
    },
    enabled: true,
    noticeLevel: 'normal'
  },
  {
    id: 'suika.make_watermelon',
    groupId: 'suika',
    gameId: 'suika',
    title: '小瓜到手',
    summary: '合成一颗小西瓜',
    detail: '在新版鸡窝水果摊将两颗哈密瓜合成小西瓜即可，也接受更高等级的合成。',
    placeholderSymbol: '◉',
    badgeAssetPath: 'app/achievements/ach_suika_make_watermelon.svg',
    progressKind: 'none',
    target: 6,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'highestMergeLevel', comparison: 'atLeast', value: 6 }
    },
    enabled: true,
    noticeLevel: 'highlight'
  },
  {
    id: 'suika.final_merge',
    groupId: 'suika',
    gameId: 'suika',
    title: '西瓜上桌',
    summary: '合成一颗西瓜',
    detail: '在新版鸡窝水果摊将两颗小西瓜合成西瓜即可，无需完成最终合成。',
    placeholderSymbol: '◉',
    badgeAssetPath: 'app/achievements/ach_suika_final_merge.svg',
    progressKind: 'none',
    target: 7,
    rule: {
      type: 'eventFact',
      eventType: 'any',
      condition: { key: 'highestMergeLevel', comparison: 'atLeast', value: 7 }
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

export function isAchievementEventTypeAllowed(gameId: string, eventType: AchievementEventType): boolean {
  const profile = achievementProfileFor(gameId);
  return profile !== undefined && profile.eventTypes.includes(eventType);
}

export function achievementCanonicalGameId(gameId: string): string {
  if (gameId === 'rpsBattleNext') return 'rpsBattle';
  if (gameId === 'minesweeperNext') return 'minesweeper';
  if (gameId === 'chicken2048Next') return 'chicken2048';
  if (gameId === 'tetrisNext') return 'tetris';
  if (gameId === 'freecellNext') return 'freecell';
  return gameId === 'suikaNext' ? 'suika' : gameId;
}

export function achievementPrimaryFavoriteCount(gameIds: string[]): number {
  if (!Array.isArray(gameIds)) {
    return 0;
  }
  const favorites: string[] = [];
  gameIds.forEach((gameId: string) => {
    if (!isAchievementSourceGameId(gameId)) return;
    const canonicalId = achievementCanonicalGameId(gameId);
    if (ACHIEVEMENT_PRIMARY_GAME_IDS.includes(canonicalId) && !favorites.includes(canonicalId)) {
      favorites.push(canonicalId);
    }
  });
  return favorites.length;
}

export function isAchievementBadgeAssetPathValid(badgeAssetPath: string): boolean {
  if (badgeAssetPath.length === 0) {
    return true;
  }
  if (!badgeAssetPath.startsWith(ACHIEVEMENT_BADGE_ASSET_DIRECTORY)) {
    return false;
  }
  const fileName = badgeAssetPath.substring(ACHIEVEMENT_BADGE_ASSET_DIRECTORY.length);
  return /^[a-z0-9_]+\.(svg|png)$/.test(fileName);
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
    if (achievementProfileFor(definition.gameId) === undefined) {
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
    ruleFactKeys(definition.rule).forEach((factKey: string) => {
      if (!isAchievementFactKeyAllowed(definition.gameId, factKey)) {
        issues.push(`unknown-rule-fact:${definition.id}:${factKey}`);
      }
    });
  });
  return issues;
}
