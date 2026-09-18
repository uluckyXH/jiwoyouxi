import { GameRecord } from '../shell/GameModule';

const DAY_MS: number = 86400000;

export interface PlayDayView {
  day: number;
  label: string;
  played: boolean;
  today: boolean;
}

// Calendar ordinals preserve local dates across midnight and daylight-saving changes.
export function localPlayDay(timestamp: number): number {
  const date = new Date(timestamp);
  return Math.floor(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) / DAY_MS);
}

export function normalizePlayDays(days: number[]): number[] {
  if (!Array.isArray(days)) return [];
  const result: number[] = [];
  days.forEach((day: number) => {
    if (Number.isFinite(day) && day >= 0 && Number.isInteger(day) && !result.includes(day)) result.push(day);
  });
  return result.sort((a: number, b: number) => a - b);
}

export function playDaysWithLegacyRecords(days: number[], records: GameRecord[]): number[] {
  const merged = days.slice();
  records.forEach((record: GameRecord) => {
    if (Number.isFinite(record.lastPlayedAt) && record.lastPlayedAt > 0) merged.push(localPlayDay(record.lastPlayedAt));
  });
  return normalizePlayDays(merged);
}

export function currentPlayStreak(days: number[], now: number): number {
  const today = localPlayDay(now);
  let cursor = days.includes(today) ? today : today - 1;
  let streak = 0;
  while (days.includes(cursor)) {
    streak += 1;
    cursor -= 1;
  }
  return streak;
}

export function recentPlayWeek(days: number[], now: number): PlayDayView[] {
  const today = localPlayDay(now);
  const result: PlayDayView[] = [];
  for (let offset = 6; offset >= 0; offset -= 1) {
    const day = today - offset;
    const date = new Date(day * DAY_MS);
    result.push({ day: day, label: offset === 0 ? '今天' : `${date.getUTCMonth() + 1}/${date.getUTCDate()}`,
      played: days.includes(day), today: offset === 0 });
  }
  return result;
}
