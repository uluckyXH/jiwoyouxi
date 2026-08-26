export const ACHIEVEMENT_SCHEMA_VERSION: number = 1;
export const ACHIEVEMENT_STATE_VERSION: number = 1;
export const ACHIEVEMENT_PROCESSED_EVENT_LIMIT: number = 32;

export type AchievementFilter = 'all' | 'unlocked' | 'inProgress';
export type AchievementProgressKind = 'totalSessions' | 'playedGames' | 'favoriteCount' | 'none';
export type AchievementStatus = 'unlocked' | 'inProgress' | 'locked';
export type AchievementEventType = 'sessionEnd' | 'milestone';
export type AchievementRuleEventType = AchievementEventType | 'any';
export type AchievementFactComparison = 'atLeast' | 'atMost' | 'equals';
export type AchievementNoticeLevel = 'normal' | 'highlight';
export type AchievementEventDisposition = 'applied' | 'duplicate' | 'ignored';

export interface AchievementFact {
  key: string;
  value: number;
}

export interface AchievementEvent {
  eventId: string;
  sessionId: string;
  gameId: string;
  type: AchievementEventType;
  occurredAt: number;
  isOfficial: boolean;
  facts: AchievementFact[];
}

export interface AchievementGateway {
  reportAchievementEvent: (event: AchievementEvent) => void;
}

export interface AchievementFactCondition {
  key: string;
  comparison: AchievementFactComparison;
  value: number;
}

export interface AchievementDisabledRule {
  type: 'disabled';
}

export interface AchievementGlobalCompletedSessionsRule {
  type: 'globalCompletedSessionsAtLeast';
  target: number;
}

export interface AchievementGlobalPlayedGamesRule {
  type: 'globalPlayedGamesAtLeast';
  target: number;
}

export interface AchievementEventObservedRule {
  type: 'eventObserved';
  eventType: AchievementRuleEventType;
}

export interface AchievementEventFactRule {
  type: 'eventFact';
  eventType: AchievementRuleEventType;
  condition: AchievementFactCondition;
}

export interface AchievementEventAllFactsRule {
  type: 'eventAllFacts';
  eventType: AchievementRuleEventType;
  conditions: AchievementFactCondition[];
}

export type AchievementRule =
  | AchievementDisabledRule
  | AchievementGlobalCompletedSessionsRule
  | AchievementGlobalPlayedGamesRule
  | AchievementEventObservedRule
  | AchievementEventFactRule
  | AchievementEventAllFactsRule;

export interface AchievementProgress {
  achievementId: string;
  current: number;
  unlockedAt: number;
}

export interface LegacyAchievementProgress {
  achievementId: string;
  current: number;
  unlockedAt: number;
  notifiedAt: number;
  isLegacyMigrated: boolean;
}

export interface AchievementState {
  version: number;
  progresses: AchievementProgress[];
  processedEventIds: string[];
  completedSessionCount: number;
  playedGameIds: string[];
}

export interface AchievementUnlock {
  achievementId: string;
  unlockedAt: number;
}

export interface AchievementApplyResult {
  state: AchievementState;
  disposition: AchievementEventDisposition;
  newlyUnlocked: AchievementUnlock[];
}

export interface AchievementDefinition {
  id: string;
  groupId: string;
  gameId: string;
  title: string;
  summary: string;
  detail: string;
  placeholderSymbol: string;
  progressKind: AchievementProgressKind;
  target: number;
  rule: AchievementRule;
  enabled: boolean;
  noticeLevel: AchievementNoticeLevel;
}

export interface AchievementGroupDefinition {
  id: string;
  title: string;
  gameId: string;
  placeholderSymbol: string;
}

export interface GameAchievementProfile {
  gameId: string;
  factKeys: string[];
}

export interface AchievementViewItem {
  definition: AchievementDefinition;
  current: number;
  target: number;
  unlockedAt: number;
  isLegacyMigrated: boolean;
  status: AchievementStatus;
}

export interface AchievementGroupView {
  definition: AchievementGroupDefinition;
  items: AchievementViewItem[];
}

export interface AchievementSummary {
  unlocked: number;
  total: number;
}
