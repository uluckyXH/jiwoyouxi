import { NativeGameOptions } from './GameTypes';

export function mechanicSummary(options: NativeGameOptions): string {
  const items: string[] = [];
  if (options.godHand) items.push('上帝之手');
  if (options.obstacles) items.push('障碍');
  if (options.shrink) items.push('缩圈');
  if (options.controlZones) items.push('据点');
  if (options.bounty) items.push('悬赏');
  return items.length === 0 ? '默认' : items.join(' · ');
}

export function eventSummary(options: NativeGameOptions): string {
  const items: string[] = [];
  if (options.blackHole) items.push('黑洞');
  if (options.traitor) items.push('叛徒');
  if (options.lastStand) items.push('绝地');
  if (options.thanos) items.push('响指');
  if (options.powerUps) items.push(options.teamPowerUps ? '团队道具' : '道具');
  if (options.tenAgainstOne) items.push('我要打十个');
  return items.length === 0 ? '默认' : items.join(' · ');
}

export function configSummary(options: NativeGameOptions): string {
  const result: string[] = [];
  result.push(`阵容 ${options.counts[0]}/${options.counts[1]}/${options.counts[2]}`);
  result.push(options.deathmatch ? '死斗模式' : `限时 ${options.durationSec}s`);
  if (options.tournament) {
    result.push(`${options.bestOf}局赛制`);
  }
  const mechanics = mechanicSummary(options);
  const events = eventSummary(options);
  if (mechanics !== '默认') {
    result.push(mechanics);
  }
  if (events !== '默认') {
    result.push(events);
  }
  if (options.betting) {
    result.push(`竞猜 ${options.stake}`);
  }
  result.push(options.notifications ? '通知开' : '通知关');
  return result.join(' · ');
}
