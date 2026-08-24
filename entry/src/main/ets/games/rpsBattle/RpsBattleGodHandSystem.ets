import {
  RpsBattleEntity,
  RpsBattleGodHandMode,
  RpsBattleGodHandState
} from './RpsBattleTypes';

export const RPS_BATTLE_GOD_HAND_CHARGES: number = 3;
export const RPS_BATTLE_GOD_HAND_RADIUS: number = 130;
export const RPS_BATTLE_GOD_HAND_PULSE_DURATION_SEC: number = 0.35;
export const RPS_BATTLE_GOD_HAND_COOLDOWN_SEC: number = 2.2;
export const RPS_BATTLE_GOD_HAND_FORCE: number = 720;

export class RpsBattleGodHandSystem {
  private state: RpsBattleGodHandState = {
    enabled: false,
    mode: 'push',
    chargesRemaining: 0,
    cooldownEndsAtSec: 0,
    pulseStartedAtSec: -1,
    pulseEndsAtSec: -1,
    x: 0,
    y: 0,
    lastHitCount: 0,
    totalUses: 0
  };

  reset(enabled: boolean): void {
    this.state = {
      enabled: enabled,
      mode: 'push',
      chargesRemaining: enabled ? RPS_BATTLE_GOD_HAND_CHARGES : 0,
      cooldownEndsAtSec: 0,
      pulseStartedAtSec: -1,
      pulseEndsAtSec: -1,
      x: 0,
      y: 0,
      lastHitCount: 0,
      totalUses: 0
    };
  }

  clear(): void {
    this.reset(false);
  }

  requestPulse(x: number, y: number, mode: RpsBattleGodHandMode, elapsedSec: number): boolean {
    if (!this.state.enabled || this.state.chargesRemaining <= 0 || elapsedSec < this.state.cooldownEndsAtSec) {
      return false;
    }
    this.state.mode = mode;
    this.state.chargesRemaining -= 1;
    this.state.cooldownEndsAtSec = elapsedSec + RPS_BATTLE_GOD_HAND_COOLDOWN_SEC;
    this.state.pulseStartedAtSec = elapsedSec;
    this.state.pulseEndsAtSec = elapsedSec + RPS_BATTLE_GOD_HAND_PULSE_DURATION_SEC;
    this.state.x = x;
    this.state.y = y;
    this.state.lastHitCount = 0;
    this.state.totalUses += 1;
    return true;
  }

  update(entities: RpsBattleEntity[], elapsedSec: number, dtSec: number): number {
    this.state.lastHitCount = 0;
    if (!this.isPulseActive(elapsedSec)) {
      return 0;
    }
    const direction = this.state.mode === 'pull' ? -1 : 1;
    for (let i = 0; i < entities.length; i += 1) {
      const entity = entities[i];
      const dx = entity.x - this.state.x;
      const dy = entity.y - this.state.y;
      const distanceSq = dx * dx + dy * dy;
      if (distanceSq >= RPS_BATTLE_GOD_HAND_RADIUS * RPS_BATTLE_GOD_HAND_RADIUS) {
        continue;
      }
      const distance = Math.max(1, Math.sqrt(distanceSq));
      const force = (1 - distance / RPS_BATTLE_GOD_HAND_RADIUS) * RPS_BATTLE_GOD_HAND_FORCE * direction;
      entity.vx += dx / distance * force * dtSec;
      entity.vy += dy / distance * force * dtSec;
      this.state.lastHitCount += 1;
    }
    return this.state.lastHitCount;
  }

  clearTransient(): void {
    if (!this.state.enabled) {
      return;
    }
    this.state.pulseStartedAtSec = -1;
    this.state.pulseEndsAtSec = -1;
    this.state.lastHitCount = 0;
  }

  resize(ratioX: number, ratioY: number): void {
    if (!this.state.enabled || this.state.pulseStartedAtSec < 0) {
      return;
    }
    this.state.x *= ratioX;
    this.state.y *= ratioY;
  }

  isPulseActive(elapsedSec: number): boolean {
    return this.state.enabled && this.state.pulseStartedAtSec >= 0 && elapsedSec < this.state.pulseEndsAtSec;
  }

  isEnabled(): boolean {
    return this.state.enabled;
  }

  snapshot(): RpsBattleGodHandState | null {
    if (!this.state.enabled) {
      return null;
    }
    return {
      enabled: this.state.enabled,
      mode: this.state.mode,
      chargesRemaining: this.state.chargesRemaining,
      cooldownEndsAtSec: this.state.cooldownEndsAtSec,
      pulseStartedAtSec: this.state.pulseStartedAtSec,
      pulseEndsAtSec: this.state.pulseEndsAtSec,
      x: this.state.x,
      y: this.state.y,
      lastHitCount: this.state.lastHitCount,
      totalUses: this.state.totalUses
    };
  }

  currentState(): RpsBattleGodHandState | null {
    return this.state.enabled ? this.state : null;
  }
}
