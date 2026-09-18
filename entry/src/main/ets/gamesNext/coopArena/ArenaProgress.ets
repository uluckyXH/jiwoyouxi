import { ArenaConfig, ArenaProfile, ArenaRound, ArenaSave, arenaDefaultConfig, arenaPractice } from './ArenaModel';

export function arenaProfileValid(p: ArenaProfile): boolean {
  return p !== null && p !== undefined && p.version === 1 && Array.isArray(p.stars) && p.stars.length === 8 &&
    p.stars.every((n: number): boolean => Number.isInteger(n) && n >= 0 && n <= 3) &&
    [p.rounds,p.wins,p.zoneRounds,p.zoneWins].every((n: number): boolean => Number.isInteger(n) && n >= 0 && n < 10000000) &&
    p.wins <= p.rounds && p.zoneWins <= p.zoneRounds && typeof p.lastSession === 'string' && p.lastSession.length <= 100 &&
    typeof p.reducedMotion === 'boolean';
}
/** Natural results only. A resumed result cannot increment local records again. */
export function arenaApplyResult(p: ArenaProfile, r: ArenaRound): boolean {
  if (!r.finished || r.session === p.lastSession) return false;
  p.lastSession = r.session;
  if (arenaPractice(r.config)) return true;
  if (r.config.mode === 'challenge') p.stars[r.config.mission] = Math.max(p.stars[r.config.mission],r.stars);
  else if (r.config.mode === 'zones') { p.zoneRounds += 1; if (r.won) p.zoneWins += 1; }
  else { p.rounds += 1; if (r.won) p.wins += 1; }
  return true;
}
export function arenaSave(profile: ArenaProfile, round: string, config: ArenaConfig = arenaDefaultConfig()): string {
  const save: ArenaSave = {version:1,profile:profile,round:round,config:config}; return JSON.stringify(save);
}
