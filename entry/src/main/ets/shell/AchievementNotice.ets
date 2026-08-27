import {
  AchievementDefinition,
  AchievementNoticeItem,
  AchievementUnlock
} from './AchievementModule';
import { achievementDefinitionFor } from './AchievementRegistry';

export const ACHIEVEMENT_NOTICE_INDIVIDUAL_LIMIT: number = 3;

export function emptyAchievementNoticeItem(): AchievementNoticeItem {
  return {
    noticeId: '',
    kind: 'achievement',
    achievementIds: [],
    gameId: 'global',
    title: '',
    summary: '',
    placeholderSymbol: '✦',
    badgeAssetPath: '',
    noticeLevel: 'normal',
    achievementCount: 0
  };
}

function definitionsForUnlocks(unlocks: AchievementUnlock[]): AchievementDefinition[] {
  const definitions: AchievementDefinition[] = [];
  if (!Array.isArray(unlocks)) {
    return definitions;
  }
  unlocks.forEach((unlock: AchievementUnlock) => {
    if (unlock === undefined || unlock === null || definitions.some((item: AchievementDefinition) =>
      item.id === unlock.achievementId)) {
      return;
    }
    const definition = achievementDefinitionFor(unlock.achievementId);
    if (definition !== undefined && definition.enabled) {
      definitions.push(definition);
    }
  });
  return definitions;
}

function noticeForDefinition(definition: AchievementDefinition): AchievementNoticeItem {
  return {
    noticeId: definition.id,
    kind: 'achievement',
    achievementIds: [definition.id],
    gameId: definition.gameId,
    title: definition.title,
    summary: definition.summary,
    placeholderSymbol: definition.placeholderSymbol,
    badgeAssetPath: definition.badgeAssetPath,
    noticeLevel: definition.noticeLevel,
    achievementCount: 1
  };
}

function summaryNoticeFor(definitions: AchievementDefinition[]): AchievementNoticeItem {
  const hasHighlight = definitions.some((definition: AchievementDefinition) =>
    definition.noticeLevel === 'highlight');
  const achievementIds: string[] = definitions.map((definition: AchievementDefinition) => definition.id);
  return {
    noticeId: `summary:${achievementIds.join('|')}`,
    kind: 'summary',
    achievementIds: achievementIds,
    gameId: 'global',
    title: `本局新解锁 ${definitions.length} 项成就`,
    summary: `已展示前 ${ACHIEVEMENT_NOTICE_INDIVIDUAL_LIMIT} 项，更多记录可在成就墙查看`,
    placeholderSymbol: '✦',
    badgeAssetPath: '',
    noticeLevel: hasHighlight ? 'highlight' : 'normal',
    achievementCount: definitions.length
  };
}

export function achievementNoticeItemsForUnlocks(unlocks: AchievementUnlock[]): AchievementNoticeItem[] {
  const definitions = definitionsForUnlocks(unlocks);
  const notices: AchievementNoticeItem[] = [];
  const individualCount = Math.min(definitions.length, ACHIEVEMENT_NOTICE_INDIVIDUAL_LIMIT);
  for (let index = 0; index < individualCount; index += 1) {
    notices.push(noticeForDefinition(definitions[index]));
  }
  if (definitions.length > ACHIEVEMENT_NOTICE_INDIVIDUAL_LIMIT) {
    notices.push(summaryNoticeFor(definitions));
  }
  return notices;
}
