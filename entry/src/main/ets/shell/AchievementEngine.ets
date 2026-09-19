import { CoopAppSnapshot, GameRecord, isGameHidden } from './GameModule';
import {
  ACHIEVEMENT_PROCESSED_EVENT_LIMIT,
  ACHIEVEMENT_SCHEMA_VERSION,
  ACHIEVEMENT_STATE_VERSION,
  ACHIEVEMENT_RULES_VERSION,
  AchievementApplyResult,
  AchievementDefinition,
  AchievementEvent,
  AchievementFact,
  AchievementFactCondition,
  AchievementFilter,
  AchievementGroupView,
  AchievementProgress,
  AchievementRule,
  AchievementState,
  AchievementStatus,
  AchievementSummary,
  AchievementUnlock,
  AchievementViewItem,
  LegacyAchievementProgress
} from './AchievementModule';
import {
  ACHIEVEMENT_DEFINITIONS,
  ACHIEVEMENT_GROUPS,
  ACHIEVEMENT_PRIMARY_GAME_IDS,
  ACHIEVEMENT_ORIGINAL_GAME_IDS,
  achievementPrimaryFavoriteCount,
  achievementCanonicalGameId,
  achievementDefinitionFor,
  achievementProfileFor,
  isAchievementEventTypeAllowed,
  isAchievementFactKeyAllowed,
  isAchievementSourceGameId
} from './AchievementRegistry';

interface SanitizedEventFacts {
  isValid: boolean;
  facts: AchievementFact[];
}

function normalizedCount(value: number): number {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.max(0, Math.floor(value));
}

function isPrimaryGameId(gameId: string): boolean {
  return ACHIEVEMENT_PRIMARY_GAME_IDS.includes(gameId);
}

function isNonEmptyString(value: string): boolean {
  return typeof value === 'string' && value.trim().length > 0;
}

function copyProgress(progress: AchievementProgress): AchievementProgress {
  return {
    achievementId: progress.achievementId,
    current: normalizedCount(progress.current),
    unlockedAt: normalizedCount(progress.unlockedAt)
  };
}

function copyLegacyProgress(progress: LegacyAchievementProgress): LegacyAchievementProgress {
  return {
    achievementId: progress.achievementId,
    current: normalizedCount(progress.current),
    unlockedAt: normalizedCount(progress.unlockedAt),
    notifiedAt: normalizedCount(progress.notifiedAt),
    isLegacyMigrated: progress.isLegacyMigrated === true
  };
}

function normalizeProcessedEventIds(eventIds: string[]): string[] {
  const normalized: string[] = [];
  if (!Array.isArray(eventIds)) {
    return normalized;
  }
  eventIds.forEach((eventId: string) => {
    if (isNonEmptyString(eventId) && !normalized.includes(eventId)) {
      normalized.push(eventId);
    }
  });
  if (normalized.length > ACHIEVEMENT_PROCESSED_EVENT_LIMIT) {
    return normalized.slice(normalized.length - ACHIEVEMENT_PROCESSED_EVENT_LIMIT);
  }
  return normalized;
}

function normalizePlayedGameIds(gameIds: string[]): string[] {
  const normalized: string[] = [];
  if (!Array.isArray(gameIds)) {
    return normalized;
  }
  gameIds.forEach((gameId: string) => {
    gameId = achievementCanonicalGameId(gameId);
    if (isPrimaryGameId(gameId) && !normalized.includes(gameId)) {
      normalized.push(gameId);
    }
  });
  return normalized;
}

function normalizeCompletedSessionIds(sessionIds: string[] | undefined): string[] {
  if (!Array.isArray(sessionIds)) return [];
  const seen: Set<string> = new Set<string>();
  return sessionIds.filter((id: string) => {
    if (!isNonEmptyString(id) || seen.has(id)) return false;
    seen.add(id);
    return true;
  });
}

export function emptyAchievementState(): AchievementState {
  return {
    version: ACHIEVEMENT_STATE_VERSION,
    rulesVersion: ACHIEVEMENT_RULES_VERSION,
    progresses: [],
    processedEventIds: [],
    completedSessionCount: 0,
    playedGameIds: [],
    completedSessionIds: []
  };
}

export function normalizeAchievementState(state: AchievementState | undefined): AchievementState {
  if (state === undefined || state === null) {
    return emptyAchievementState();
  }
  const progresses: AchievementProgress[] = [];
  if (Array.isArray(state.progresses)) {
    state.progresses.forEach((progress: AchievementProgress) => {
      if (progress === undefined || progress === null || !isNonEmptyString(progress.achievementId)) {
        return;
      }
      if (progresses.some((item: AchievementProgress) => item.achievementId === progress.achievementId)) {
        return;
      }
      progresses.push(copyProgress(progress));
    });
  }
  return {
    version: ACHIEVEMENT_STATE_VERSION,
    rulesVersion: normalizedCount(state.rulesVersion ?? 1),
    progresses: progresses,
    processedEventIds: normalizeProcessedEventIds(state.processedEventIds),
    completedSessionCount: normalizedCount(state.completedSessionCount),
    playedGameIds: normalizePlayedGameIds(state.playedGameIds),
    completedSessionIds: normalizeCompletedSessionIds(state.completedSessionIds)
  };
}

/** Migrate only recorded achievement facts; do not infer achievements from legacy scores. */
export function migrateAchievementRules(previous: AchievementState, occurredAt: number): AchievementState {
  const state=normalizeAchievementState(previous);
  if ((state.rulesVersion ?? 1)>=ACHIEVEMENT_RULES_VERSION) return state;
  const oldWatermelon=state.progresses.find((p: AchievementProgress) => p.achievementId==='suika.make_watermelon');
  const watermelonAt=oldWatermelon?.unlockedAt ?? 0;
  const oldLines=state.progresses.find((p: AchievementProgress) => p.achievementId==='tetris.twenty_lines');
  const knownLines=oldLines?.current ?? 0;
  state.progresses.forEach((p: AchievementProgress) => {
    const d=achievementDefinitionFor(p.achievementId); if(d===undefined)return;
    if(p.achievementId==='tetris.level_three')p.current=Math.max(knownLines,p.current>=2 ? 10 : 0);
    if(p.achievementId==='suika.make_watermelon' || p.achievementId==='suika.final_merge')p.current=p.unlockedAt>0 ? d.target : 0;
    p.current=p.unlockedAt>0 ? d.target : Math.min(d.target,p.current);
    if(p.unlockedAt===0 && p.current>=d.target)p.unlockedAt=Math.floor(occurredAt);
  });
  // The former ordinary-watermelon badge already proves the new highest fruit threshold.
  if(watermelonAt>0) {
    const final=state.progresses.find((p: AchievementProgress) => p.achievementId==='suika.final_merge');
    if(final===undefined)state.progresses.push({achievementId:'suika.final_merge',current:7,unlockedAt:watermelonAt});
    else if(final.unlockedAt===0) { final.current=7; final.unlockedAt=watermelonAt; }
  }
  state.rulesVersion=ACHIEVEMENT_RULES_VERSION;
  return state;
}

function progressForState(state: AchievementState, achievementId: string): AchievementProgress | undefined {
  return state.progresses.find((item: AchievementProgress) => item.achievementId === achievementId);
}

function factValueFor(facts: AchievementFact[], key: string): number | undefined {
  const fact = facts.find((item: AchievementFact) => item.key === key);
  return fact === undefined ? undefined : fact.value;
}

function eventTypeMatches(ruleEventType: string, eventType: string): boolean {
  return ruleEventType === 'any' || ruleEventType === eventType;
}

function conditionMatches(condition: AchievementFactCondition, facts: AchievementFact[]): boolean {
  const value = factValueFor(facts, condition.key);
  if (value === undefined) {
    return false;
  }
  if (condition.comparison === 'atLeast') {
    return value >= condition.value;
  }
  if (condition.comparison === 'atMost') {
    return value <= condition.value;
  }
  return value === condition.value;
}

function candidateForRule(
  definition: AchievementDefinition,
  state: AchievementState,
  event: AchievementEvent,
  facts: AchievementFact[]
): number | undefined {
  const rule: AchievementRule = definition.rule;
  if (rule.type === 'disabled') {
    return undefined;
  }
  if (rule.type === 'globalCompletedSessionsAtLeast') {
    return event.type === 'sessionEnd' ? state.completedSessionCount : undefined;
  }
  if (rule.type === 'globalPlayedGamesAtLeast') {
    return event.type === 'sessionEnd' ? state.playedGameIds.filter((id: string) =>
      ACHIEVEMENT_ORIGINAL_GAME_IDS.includes(id)).length : undefined;
  }
  if (!eventTypeMatches(rule.eventType, event.type)) {
    return undefined;
  }
  if (rule.type === 'eventObserved') {
    return 1;
  }
  if (rule.type === 'eventFact') {
    const value = factValueFor(facts, rule.condition.key);
    if (value === undefined) {
      return undefined;
    }
    if (rule.condition.comparison === 'atLeast') {
      return value;
    }
    return conditionMatches(rule.condition, facts) ? 1 : undefined;
  }
  for (let index = 0; index < rule.conditions.length; index += 1) {
    if (!conditionMatches(rule.conditions[index], facts)) {
      return undefined;
    }
  }
  return 1;
}

function sanitizeEventFacts(event: AchievementEvent): SanitizedEventFacts {
  const facts: AchievementFact[] = [];
  if (!Array.isArray(event.facts)) {
    return { isValid: false, facts: facts };
  }
  for (let index = 0; index < event.facts.length; index += 1) {
    const fact = event.facts[index];
    if (fact === undefined || fact === null || !isNonEmptyString(fact.key)) {
      continue;
    }
    if (!isAchievementFactKeyAllowed(event.gameId, fact.key)) {
      continue;
    }
    if (!Number.isFinite(fact.value) || fact.value < 0) {
      return { isValid: false, facts: [] };
    }
    if (!facts.some((item: AchievementFact) => item.key === fact.key)) {
      facts.push({ key: fact.key, value: Math.floor(fact.value) });
    }
  }
  return { isValid: true, facts: facts };
}

function isValidEvent(event: AchievementEvent): boolean {
  if (event === undefined || event === null) {
    return false;
  }
  if (!isNonEmptyString(event.eventId) || !isNonEmptyString(event.sessionId)) {
    return false;
  }
  if (achievementProfileFor(event.gameId) === undefined) {
    return false;
  }
  if (event.type !== 'sessionEnd' && event.type !== 'milestone') {
    return false;
  }
  if (!isAchievementEventTypeAllowed(event.gameId, event.type)) {
    return false;
  }
  if (event.isOfficial !== true && event.isOfficial !== false) {
    return false;
  }
  return Number.isFinite(event.occurredAt) && event.occurredAt > 0;
}

function nextProcessedEventIds(eventIds: string[], eventId: string): string[] {
  const next = eventIds.slice();
  next.push(eventId);
  return normalizeProcessedEventIds(next);
}

function nextStateForSessionEnd(state: AchievementState, event: AchievementEvent): AchievementState {
  if (event.type !== 'sessionEnd' || !isPrimaryGameId(event.gameId)) {
    return state;
  }
  const completedSessionIds = (state.completedSessionIds ?? []).slice();
  const sessionKey = event.gameId + ':' + event.sessionId;
  if (completedSessionIds.includes(sessionKey)) return state;
  completedSessionIds.push(sessionKey);
  const playedGameIds = state.playedGameIds.slice();
  if (!playedGameIds.includes(event.gameId)) {
    playedGameIds.push(event.gameId);
  }
  return {
    version: ACHIEVEMENT_STATE_VERSION,
    rulesVersion: state.rulesVersion,
    progresses: state.progresses.slice(),
    processedEventIds: state.processedEventIds.slice(),
    completedSessionCount: state.completedSessionCount + 1,
    playedGameIds: playedGameIds,
    completedSessionIds: completedSessionIds
  };
}

function replacesProgress(
  progresses: AchievementProgress[],
  nextProgress: AchievementProgress
): AchievementProgress[] {
  const next: AchievementProgress[] = [];
  let replaced = false;
  progresses.forEach((progress: AchievementProgress) => {
    if (progress.achievementId === nextProgress.achievementId) {
      next.push(nextProgress);
      replaced = true;
    } else {
      next.push(copyProgress(progress));
    }
  });
  if (!replaced) {
    next.push(nextProgress);
  }
  return next;
}

export function applyAchievementEvent(
  previous: AchievementState,
  event: AchievementEvent
): AchievementApplyResult {
  const state = normalizeAchievementState(previous);
  if (event===undefined || event===null || (event.gameId!=='global' && !isAchievementSourceGameId(event.gameId))) {
    return { state: state, disposition: 'ignored', newlyUnlocked: [] };
  }
  if (event !== undefined && event !== null) {
    event = { eventId: event.eventId, sessionId: event.sessionId,
      gameId: achievementCanonicalGameId(event.gameId), type: event.type,
      occurredAt: event.occurredAt, isOfficial: event.isOfficial, facts: event.facts };
  }
  if (!isValidEvent(event)) {
    return { state: state, disposition: 'ignored', newlyUnlocked: [] };
  }
  if (event.isOfficial === false) {
    return { state: state, disposition: 'ignored', newlyUnlocked: [] };
  }
  if (state.processedEventIds.includes(event.eventId)) {
    return { state: state, disposition: 'duplicate', newlyUnlocked: [] };
  }
  const sanitizedFacts = sanitizeEventFacts(event);
  if (!sanitizedFacts.isValid) {
    return { state: state, disposition: 'ignored', newlyUnlocked: [] };
  }

  let nextState = nextStateForSessionEnd(state, event);
  const newlyUnlocked: AchievementUnlock[] = [];
  ACHIEVEMENT_DEFINITIONS.forEach((definition: AchievementDefinition) => {
    if (!definition.enabled) {
      return;
    }
    if (definition.gameId !== 'global' && definition.gameId !== event.gameId) {
      return;
    }
    const candidate = candidateForRule(definition, nextState, event, sanitizedFacts.facts);
    if (candidate === undefined) {
      return;
    }
    const previousProgress = progressForState(nextState, definition.id);
    const previousCurrent = previousProgress === undefined ? 0 : previousProgress.current;
    const nextCurrent = Math.min(definition.target, Math.max(previousCurrent, normalizedCount(candidate)));
    const previousUnlockedAt = previousProgress === undefined ? 0 : previousProgress.unlockedAt;
    const unlockedAt = previousUnlockedAt > 0 || nextCurrent < definition.target
      ? previousUnlockedAt
      : Math.floor(event.occurredAt);
    if (nextCurrent === previousCurrent && unlockedAt === previousUnlockedAt) {
      return;
    }
    nextState = {
      version: ACHIEVEMENT_STATE_VERSION,
      rulesVersion: nextState.rulesVersion,
      progresses: replacesProgress(nextState.progresses, {
        achievementId: definition.id,
        current: nextCurrent,
        unlockedAt: unlockedAt
      }),
      processedEventIds: nextState.processedEventIds.slice(),
      completedSessionCount: nextState.completedSessionCount,
      playedGameIds: nextState.playedGameIds.slice(),
      completedSessionIds: (nextState.completedSessionIds ?? []).slice()
    };
    if (previousUnlockedAt === 0 && unlockedAt > 0) {
      newlyUnlocked.push({ achievementId: definition.id, unlockedAt: unlockedAt });
    }
  });
  nextState = {
    version: ACHIEVEMENT_STATE_VERSION,
    rulesVersion: nextState.rulesVersion,
    progresses: nextState.progresses.slice(),
    processedEventIds: nextProcessedEventIds(nextState.processedEventIds, event.eventId),
    completedSessionCount: nextState.completedSessionCount,
    playedGameIds: nextState.playedGameIds.slice(),
    completedSessionIds: (nextState.completedSessionIds ?? []).slice()
  };
  return { state: nextState, disposition: 'applied', newlyUnlocked: newlyUnlocked };
}

export function achievementProgressForState(
  state: AchievementState,
  achievementId: string
): AchievementProgress | undefined {
  const progress = progressForState(normalizeAchievementState(state), achievementId);
  return progress === undefined ? undefined : copyProgress(progress);
}

export function achievementSummaryForState(state: AchievementState): AchievementSummary {
  const normalized = normalizeAchievementState(state);
  let unlocked = 0;
  let total = 0;
  ACHIEVEMENT_DEFINITIONS.forEach((definition: AchievementDefinition) => {
    if (isGameHidden(definition.gameId)) return;
    total += 1;
    const progress = progressForState(normalized, definition.id);
    if (definition.enabled && progress !== undefined && progress.unlockedAt > 0) {
      unlocked += 1;
    }
  });
  return { unlocked: unlocked, total: total };
}

function stateViewTarget(definition: AchievementDefinition): number {
  if (!definition.enabled) {
    return 0;
  }
  if (definition.rule.type === 'globalCompletedSessionsAtLeast' ||
    definition.rule.type === 'globalPlayedGamesAtLeast') {
    return definition.target;
  }
  if (definition.rule.type === 'eventFact' && definition.rule.condition.comparison === 'atLeast') {
    return definition.target;
  }
  return 0;
}

function stateViewItemFor(state: AchievementState, definition: AchievementDefinition): AchievementViewItem {
  const progress = progressForState(state, definition.id);
  const target = stateViewTarget(definition);
  const current = progress === undefined || target === 0
    ? 0
    : Math.min(target, normalizedCount(progress.current));
  const unlockedAt = !definition.enabled || progress === undefined ? 0 : normalizedCount(progress.unlockedAt);
  let status: AchievementStatus = 'locked';
  if (unlockedAt > 0) {
    status = 'unlocked';
  } else if (current > 0) {
    status = 'inProgress';
  }
  return {
    definition: definition,
    current: current,
    target: target,
    unlockedAt: unlockedAt,
    isLegacyMigrated: false,
    status: status
  };
}

function matchesStateFilter(item: AchievementViewItem, filter: AchievementFilter): boolean {
  if (filter === 'all') {
    return true;
  }
  if (filter === 'unlocked') {
    return item.status === 'unlocked';
  }
  return item.status === 'inProgress';
}

export function achievementGroupsForState(
  state: AchievementState,
  filter: AchievementFilter
): AchievementGroupView[] {
  const normalized = normalizeAchievementState(state);
  const groups: AchievementGroupView[] = [];
  ACHIEVEMENT_GROUPS.forEach((group) => {
    if (isGameHidden(group.gameId)) return;
    const items: AchievementViewItem[] = [];
    ACHIEVEMENT_DEFINITIONS.forEach((definition: AchievementDefinition) => {
      if (definition.groupId === group.id) {
        const item = stateViewItemFor(normalized, definition);
        if (matchesStateFilter(item, filter)) {
          items.push(item);
        }
      }
    });
    if (items.length > 0) {
      groups.push({ definition: group, items: items });
    }
  });
  return groups;
}

export function achievementViewItemForState(
  state: AchievementState,
  achievementId: string
): AchievementViewItem | undefined {
  const definition = achievementDefinitionFor(achievementId);
  if (definition === undefined || isGameHidden(definition.gameId)) {
    return undefined;
  }
  return stateViewItemFor(normalizeAchievementState(state), definition);
}

function isRegisteredAchievementId(achievementId: string): boolean {
  return achievementDefinitionFor(achievementId) !== undefined;
}

function legacyProgressFor(snapshot: CoopAppSnapshot, achievementId: string): LegacyAchievementProgress | undefined {
  return snapshot.achievements.find((item: LegacyAchievementProgress) => item.achievementId === achievementId);
}

function legacyViewItemFor(snapshot: CoopAppSnapshot, definition: AchievementDefinition): AchievementViewItem {
  const progress = legacyProgressFor(snapshot, definition.id);
  const current = progress === undefined ? 0 : normalizedCount(progress.current);
  const unlockedAt = progress === undefined ? 0 : normalizedCount(progress.unlockedAt);
  let status: AchievementStatus = 'locked';
  if (unlockedAt > 0) {
    status = 'unlocked';
  } else if (definition.target > 0) {
    status = 'inProgress';
  }
  return {
    definition: definition,
    current: current,
    target: definition.progressKind === 'none' ? 0 : definition.target,
    unlockedAt: unlockedAt,
    isLegacyMigrated: progress !== undefined && progress.isLegacyMigrated === true,
    status: status
  };
}

function matchesFilter(item: AchievementViewItem, filter: AchievementFilter): boolean {
  if (filter === 'all') {
    return true;
  }
  if (filter === 'unlocked') {
    return item.status === 'unlocked';
  }
  return item.status !== 'unlocked';
}

export function synchronizeAchievementProgress(snapshot: CoopAppSnapshot, occurredAt: number): CoopAppSnapshot {
  const achievements: LegacyAchievementProgress[] = [];
  const isLegacyMigration = snapshot.achievementSchemaVersion < ACHIEVEMENT_SCHEMA_VERSION;
  ACHIEVEMENT_DEFINITIONS.forEach((definition: AchievementDefinition) => {
    const previous = legacyProgressFor(snapshot, definition.id);
    const current = legacyProgressValueForDefinition(snapshot, definition);
    const nextCurrent = maxLegacyProgress(definition, previous === undefined ? 0 : previous.current, current);
    let unlockedAt = previous === undefined ? 0 : normalizedCount(previous.unlockedAt);
    let isLegacyMigrated = previous !== undefined && previous.isLegacyMigrated === true;
    if (definition.target > 0 && nextCurrent >= definition.target && unlockedAt === 0) {
      unlockedAt = normalizedCount(occurredAt);
      isLegacyMigrated = isLegacyMigration;
    }
    achievements.push({
      achievementId: definition.id,
      current: nextCurrent,
      unlockedAt: unlockedAt,
      notifiedAt: previous === undefined ? 0 : normalizedCount(previous.notifiedAt),
      isLegacyMigrated: isLegacyMigrated
    });
  });
  snapshot.achievements.forEach((progress: LegacyAchievementProgress) => {
    if (progress !== undefined && progress !== null && isNonEmptyString(progress.achievementId) &&
      !isRegisteredAchievementId(progress.achievementId)) {
      achievements.push(copyLegacyProgress(progress));
    }
  });
  return {
    records: snapshot.records.slice(),
    favorites: snapshot.favorites.slice(),
    recent: snapshot.recent.slice(),
    soundEnabled: snapshot.soundEnabled,
    hapticEnabled: snapshot.hapticEnabled,
    appearanceMode: snapshot.appearanceMode,
    achievementSchemaVersion: ACHIEVEMENT_SCHEMA_VERSION,
    achievements: achievements,
    recentAchievementEventIds: normalizeProcessedEventIds(snapshot.recentAchievementEventIds)
  };
}

function legacyProgressValueForDefinition(snapshot: CoopAppSnapshot, definition: AchievementDefinition): number {
  if (definition.progressKind === 'totalSessions') {
    let total = 0;
    snapshot.records.forEach((record: GameRecord) => {
      if (isPrimaryGameId(record.gameId)) {
        total += normalizedCount(record.playCount);
      }
    });
    return total;
  }
  if (definition.progressKind === 'playedGames') {
    const playedGameIds: string[] = [];
    snapshot.records.forEach((record: GameRecord) => {
      if (ACHIEVEMENT_ORIGINAL_GAME_IDS.includes(record.gameId) && normalizedCount(record.playCount) > 0 &&
        !playedGameIds.includes(record.gameId)) {
        playedGameIds.push(record.gameId);
      }
    });
    return playedGameIds.length;
  }
  if (definition.progressKind === 'favoriteCount') {
    return achievementPrimaryFavoriteCount(snapshot.favorites);
  }
  return 0;
}

function maxLegacyProgress(definition: AchievementDefinition, previous: number, current: number): number {
  if (definition.target <= 0) {
    return normalizedCount(previous);
  }
  return Math.min(definition.target, Math.max(normalizedCount(previous), normalizedCount(current)));
}

export function achievementSummaryForSnapshot(snapshot: CoopAppSnapshot): AchievementSummary {
  let unlocked = 0;
  let total = 0;
  ACHIEVEMENT_DEFINITIONS.forEach((definition: AchievementDefinition) => {
    if (isGameHidden(definition.gameId)) return;
    total += 1;
    const progress = legacyProgressFor(snapshot, definition.id);
    if (progress !== undefined && progress.unlockedAt > 0) {
      unlocked += 1;
    }
  });
  return { unlocked: unlocked, total: total };
}

export function achievementGroupsForSnapshot(
  snapshot: CoopAppSnapshot,
  filter: AchievementFilter
): AchievementGroupView[] {
  const groups: AchievementGroupView[] = [];
  ACHIEVEMENT_GROUPS.forEach((group) => {
    if (isGameHidden(group.gameId)) return;
    const items: AchievementViewItem[] = [];
    ACHIEVEMENT_DEFINITIONS.forEach((definition: AchievementDefinition) => {
      if (definition.groupId === group.id) {
        const item = legacyViewItemFor(snapshot, definition);
        if (matchesFilter(item, filter)) {
          items.push(item);
        }
      }
    });
    if (items.length > 0) {
      groups.push({ definition: group, items: items });
    }
  });
  return groups;
}

export function achievementViewItemFor(
  snapshot: CoopAppSnapshot,
  achievementId: string
): AchievementViewItem | undefined {
  const definition = achievementDefinitionFor(achievementId);
  return definition === undefined || isGameHidden(definition.gameId) ? undefined : legacyViewItemFor(snapshot, definition);
}

export function hasRegisteredAchievementId(achievementId: string): boolean {
  return isRegisteredAchievementId(achievementId);
}
