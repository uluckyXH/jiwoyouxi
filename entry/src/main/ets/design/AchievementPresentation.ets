import { AchievementFilter, AchievementGroupView } from '../shell/AchievementModule';

// ArkUI ForEach must replace a plain-data group when its membership/progress changes.
export function achievementGroupRenderKey(group: AchievementGroupView, filter: AchievementFilter): string {
  return `${filter}:${group.definition.id}:` + group.items.map((item) =>
    `${item.definition.id}/${item.status}/${item.current}/${item.target}/${item.unlockedAt}`).join('|');
}

export function achievementGroupCountLabel(group: AchievementGroupView, filter: AchievementFilter): string {
  if (filter !== 'all') return `${group.items.length} 项${filter === 'unlocked' ? '已解锁' : '进行中'}`;
  return `${group.items.filter((item) => item.status === 'unlocked').length} / ${group.items.length}`;
}
