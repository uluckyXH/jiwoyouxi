import {
  RPS_BATTLE_DURATION_CHOICES,
  RPS_BATTLE_DURATION_SEC,
  RPS_BATTLE_LOGICAL_FACTIONS,
  RPS_BATTLE_MAX_COUNT_PER_FACTION,
  RPS_BATTLE_MAX_TOTAL_ENTITIES,
  RPS_BATTLE_MIN_COUNT_PER_FACTION,
  RPS_BATTLE_SCALE_CHOICES,
  RpsBattleEntity,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleFinishReason,
  RpsBattleOptions,
  RpsBattleResult,
  RpsBattleScale
} from './RpsBattleTypes';

export function rpsBattleBeats(attacker: RpsBattleFaction, defender: RpsBattleFaction): boolean {
  return (attacker === 'rock' && defender === 'scissors') ||
    (attacker === 'scissors' && defender === 'paper') ||
    (attacker === 'paper' && defender === 'rock');
}

export function rpsBattlePreyOf(faction: RpsBattleFaction): RpsBattleFaction {
  if (faction === 'rock') {
    return 'scissors';
  }
  if (faction === 'scissors') {
    return 'paper';
  }
  return 'rock';
}

export function rpsBattlePredatorOf(faction: RpsBattleFaction): RpsBattleFaction {
  if (faction === 'rock') {
    return 'paper';
  }
  if (faction === 'scissors') {
    return 'rock';
  }
  return 'scissors';
}

export function rpsBattleCreateOptions(
  initialCounts: RpsBattleFactionCounts,
  durationSec: number,
  supportFaction: RpsBattleFaction
): RpsBattleOptions {
  return {
    supportFaction: supportFaction,
    initialCounts: rpsBattleClampCounts(initialCounts),
    durationSec: rpsBattleClampDuration(durationSec)
  };
}

export function rpsBattleInitialCountForScale(scale: RpsBattleScale): number {
  const found = RPS_BATTLE_SCALE_CHOICES.find((item) => item.id === scale);
  return found === undefined ? 8 : found.count;
}

export function rpsBattleCountsFromValue(value: number): RpsBattleFactionCounts {
  const count = rpsBattleClampCount(value);
  return { rock: count, scissors: count, paper: count };
}

export function rpsBattleEmptyCounts(): RpsBattleFactionCounts {
  return { rock: 0, scissors: 0, paper: 0 };
}

export function rpsBattleCloneCounts(counts: RpsBattleFactionCounts): RpsBattleFactionCounts {
  return { rock: counts.rock, scissors: counts.scissors, paper: counts.paper };
}

export function rpsBattleTotalCount(counts: RpsBattleFactionCounts): number {
  return counts.rock + counts.scissors + counts.paper;
}

export function rpsBattleClampCount(value: number): number {
  if (!Number.isFinite(value)) {
    return RPS_BATTLE_MIN_COUNT_PER_FACTION;
  }
  const rounded = Math.round(value);
  return Math.max(RPS_BATTLE_MIN_COUNT_PER_FACTION, Math.min(RPS_BATTLE_MAX_COUNT_PER_FACTION, rounded));
}

export function rpsBattleClampCounts(counts: RpsBattleFactionCounts): RpsBattleFactionCounts {
  const next: RpsBattleFactionCounts = {
    rock: rpsBattleClampCount(counts.rock),
    scissors: rpsBattleClampCount(counts.scissors),
    paper: rpsBattleClampCount(counts.paper)
  };
  while (rpsBattleTotalCount(next) > RPS_BATTLE_MAX_TOTAL_ENTITIES) {
    const largest = rpsBattleLargestFaction(next);
    if (largest === 'rock') {
      next.rock -= 1;
    } else if (largest === 'scissors') {
      next.scissors -= 1;
    } else {
      next.paper -= 1;
    }
  }
  return next;
}

export function rpsBattleCanIncreaseCount(
  counts: RpsBattleFactionCounts,
  faction: RpsBattleFaction,
  syncCounts: boolean
): boolean {
  const next = rpsBattleStepCount(counts, faction, 1, syncCounts);
  return next.rock !== counts.rock || next.scissors !== counts.scissors || next.paper !== counts.paper;
}

export function rpsBattleCanDecreaseCount(
  counts: RpsBattleFactionCounts,
  faction: RpsBattleFaction,
  syncCounts: boolean
): boolean {
  const next = rpsBattleStepCount(counts, faction, -1, syncCounts);
  return next.rock !== counts.rock || next.scissors !== counts.scissors || next.paper !== counts.paper;
}

export function rpsBattleStepCount(
  counts: RpsBattleFactionCounts,
  faction: RpsBattleFaction,
  step: number,
  syncCounts: boolean
): RpsBattleFactionCounts {
  const delta = step > 0 ? 1 : -1;
  const next = rpsBattleCloneCounts(counts);
  if (syncCounts) {
    next.rock = rpsBattleClampCount(counts.rock + delta);
    next.scissors = rpsBattleClampCount(counts.scissors + delta);
    next.paper = rpsBattleClampCount(counts.paper + delta);
  } else if (faction === 'rock') {
    next.rock = rpsBattleClampCount(counts.rock + delta);
  } else if (faction === 'scissors') {
    next.scissors = rpsBattleClampCount(counts.scissors + delta);
  } else {
    next.paper = rpsBattleClampCount(counts.paper + delta);
  }
  if (rpsBattleTotalCount(next) > RPS_BATTLE_MAX_TOTAL_ENTITIES) {
    return rpsBattleCloneCounts(counts);
  }
  return next;
}

export function rpsBattleScaleForCounts(counts: RpsBattleFactionCounts): RpsBattleScale {
  if (counts.rock !== counts.scissors || counts.rock !== counts.paper) {
    return 'custom';
  }
  const found = RPS_BATTLE_SCALE_CHOICES.find((item) => item.count === counts.rock);
  return found === undefined ? 'custom' : found.id;
}

export function rpsBattleClampDuration(durationSec: number): number {
  const found = RPS_BATTLE_DURATION_CHOICES.find((item) => item.durationSec === durationSec);
  return found === undefined ? RPS_BATTLE_DURATION_SEC : durationSec;
}

export function rpsBattleCountEntities(entities: RpsBattleEntity[]): RpsBattleFactionCounts {
  const counts = rpsBattleEmptyCounts();
  for (let i = 0; i < entities.length; i += 1) {
    const entity = entities[i];
    if (entity.faction === 'rock') {
      counts.rock += 1;
    } else if (entity.faction === 'scissors') {
      counts.scissors += 1;
    } else {
      counts.paper += 1;
    }
  }
  return counts;
}

export function rpsBattleCountValue(counts: RpsBattleFactionCounts, faction: RpsBattleFaction): number {
  if (faction === 'rock') {
    return counts.rock;
  }
  if (faction === 'scissors') {
    return counts.scissors;
  }
  return counts.paper;
}

function rpsBattleLargestFaction(counts: RpsBattleFactionCounts): RpsBattleFaction {
  if (counts.rock >= counts.scissors && counts.rock >= counts.paper) {
    return 'rock';
  }
  if (counts.scissors >= counts.rock && counts.scissors >= counts.paper) {
    return 'scissors';
  }
  return 'paper';
}

export function rpsBattleAliveFactions(counts: RpsBattleFactionCounts): RpsBattleFaction[] {
  const result: RpsBattleFaction[] = [];
  if (counts.rock > 0) {
    result.push('rock');
  }
  if (counts.scissors > 0) {
    result.push('scissors');
  }
  if (counts.paper > 0) {
    result.push('paper');
  }
  return result;
}

export function rpsBattleLeadingFaction(counts: RpsBattleFactionCounts): RpsBattleFaction | '' {
  let winner: RpsBattleFaction | '' = '';
  let best = 0;
  let tied = false;
  for (let i = 0; i < RPS_BATTLE_LOGICAL_FACTIONS.length; i += 1) {
    const faction = RPS_BATTLE_LOGICAL_FACTIONS[i];
    const count = rpsBattleCountValue(counts, faction);
    if (count > best) {
      best = count;
      winner = faction;
      tied = false;
    } else if (count === best && count > 0) {
      tied = true;
    }
  }
  return tied ? '' : winner;
}

export function rpsBattleResultScore(result: RpsBattleResult): number {
  if (result.winner === '') {
    return 0;
  }
  return rpsBattleCountValue(result.counts, result.winner);
}

export function rpsBattleInitialResult(supportFaction: RpsBattleFaction): RpsBattleResult {
  return {
    finishReason: 'none',
    winner: '',
    supportFaction: supportFaction,
    supportWon: false,
    counts: rpsBattleEmptyCounts(),
    elapsedSec: 0,
    conversions: 0,
    score: 0
  };
}

export function rpsBattleBuildResult(
  options: RpsBattleOptions,
  counts: RpsBattleFactionCounts,
  elapsedSec: number,
  conversions: number,
  finishReason: RpsBattleFinishReason
): RpsBattleResult {
  let winner: RpsBattleFaction | '' = '';
  let reason: RpsBattleFinishReason = finishReason;
  const alive = rpsBattleAliveFactions(counts);
  if (finishReason === 'clear' && alive.length === 1) {
    winner = alive[0];
  } else if (finishReason === 'time') {
    winner = rpsBattleLeadingFaction(counts);
    if (winner === '') {
      reason = 'draw';
    }
  }
  const result: RpsBattleResult = {
    finishReason: reason,
    winner: winner,
    supportFaction: options.supportFaction,
    supportWon: winner !== '' && winner === options.supportFaction,
    counts: {
      rock: counts.rock,
      scissors: counts.scissors,
      paper: counts.paper
    },
    elapsedSec: elapsedSec,
    conversions: conversions,
    score: 0
  };
  result.score = rpsBattleResultScore(result);
  return result;
}

export function rpsBattleCloneEntity(entity: RpsBattleEntity): RpsBattleEntity {
  return {
    id: entity.id,
    faction: entity.faction,
    x: entity.x,
    y: entity.y,
    vx: entity.vx,
    vy: entity.vy,
    radius: entity.radius,
    convertedAt: entity.convertedAt
  };
}

export function rpsBattleCloneEntities(entities: RpsBattleEntity[]): RpsBattleEntity[] {
  const result: RpsBattleEntity[] = [];
  for (let i = 0; i < entities.length; i += 1) {
    result.push(rpsBattleCloneEntity(entities[i]));
  }
  return result;
}
