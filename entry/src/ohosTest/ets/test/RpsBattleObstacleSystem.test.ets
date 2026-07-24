import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  rpsBattleObstacleCenterSafeRadiusForBoard,
  rpsBattleObstacleCountForBoard,
  rpsBattleObstacleHomeSafeRadiusForBoard,
  rpsBattleResolveObstacleCollision,
  RPS_BATTLE_OBSTACLE_MAX_SMALL_RADIUS,
  RPS_BATTLE_OBSTACLE_MAX_STANDARD_RADIUS,
  RPS_BATTLE_OBSTACLE_MIN_RADIUS,
  RpsBattleObstacleSystem
} from '../../../main/ets/games/rpsBattle/RpsBattleObstacleSystem';
import {
  RpsBattleEntity,
  RpsBattleObstacle,
  RpsBattleObstacleState
} from '../../../main/ets/games/rpsBattle/RpsBattleTypes';

function randomSequence(values: number[]): () => number {
  let index = 0;
  return (): number => {
    if (index >= values.length) {
      return 0.5;
    }
    const value = values[index];
    index += 1;
    return value;
  };
}

function createEntity(x: number, y: number, vx: number = 0, vy: number = 0): RpsBattleEntity {
  return {
    id: 1,
    faction: 'rock',
    x: x,
    y: y,
    vx: vx,
    vy: vy,
    radius: 14,
    shield: 0,
    speedBoostUntilSec: 0,
    traitorRageUntilSec: 0,
    convertedAt: 0
  };
}

function intersectsCircle(obstacle: RpsBattleObstacle, x: number, y: number, radius: number): boolean {
  const dx = obstacle.x - x;
  const dy = obstacle.y - y;
  const minimumDistance = obstacle.radius + radius;
  return dx * dx + dy * dy < minimumDistance * minimumDistance;
}

function overlaps(a: RpsBattleObstacle, b: RpsBattleObstacle): boolean {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  const minimumDistance = a.radius + b.radius;
  return dx * dx + dy * dy < minimumDistance * minimumDistance;
}

export default function rpsBattleObstacleSystemTest(): void {
  describe('RpsBattleObstacleSystemTest', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
    it('uses low obstacle density for narrow phone boards', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      expect(rpsBattleObstacleCountForBoard(360, 520)).assertEqual(2);
      expect(rpsBattleObstacleCountForBoard(420, 620)).assertEqual(3);
    });

    it('generates non-overlapping obstacles outside faction homes and the center opening', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const width = 360;
      const height = 520;
      const system = new RpsBattleObstacleSystem();
      system.reset(width, height, randomSequence([0, 0, 0, 0, 0, 0, 0, 0]));
      const state = system.snapshot() as RpsBattleObstacleState;
      const homeRadius = rpsBattleObstacleHomeSafeRadiusForBoard(width, height);
      const centerRadius = rpsBattleObstacleCenterSafeRadiusForBoard(width, height);

      expect(state.obstacles.length).assertEqual(2);
      for (let i = 0; i < state.obstacles.length; i += 1) {
        const obstacle = state.obstacles[i];
        expect(obstacle.radius >= RPS_BATTLE_OBSTACLE_MIN_RADIUS).assertEqual(true);
        expect(obstacle.radius <= RPS_BATTLE_OBSTACLE_MAX_SMALL_RADIUS).assertEqual(true);
        expect(intersectsCircle(obstacle, width * 0.24, height * 0.28, homeRadius)).assertEqual(false);
        expect(intersectsCircle(obstacle, width * 0.76, height * 0.30, homeRadius)).assertEqual(false);
        expect(intersectsCircle(obstacle, width * 0.50, height * 0.74, homeRadius)).assertEqual(false);
        expect(intersectsCircle(obstacle, width * 0.50, height * 0.50, centerRadius)).assertEqual(false);
        for (let j = i + 1; j < state.obstacles.length; j += 1) {
          expect(overlaps(obstacle, state.obstacles[j])).assertEqual(false);
        }
      }
    });

    it('uses larger circular obstacles on standard phone boards', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleObstacleSystem();
      system.reset(420, 620, randomSequence([0.5, 0.5, 0.5, 0.5, 0.5, 0.5]));
      const state = system.snapshot() as RpsBattleObstacleState;

      expect(state.obstacles.length).assertEqual(3);
      for (let i = 0; i < state.obstacles.length; i += 1) {
        expect(state.obstacles[i].radius >= RPS_BATTLE_OBSTACLE_MIN_RADIUS).assertEqual(true);
        expect(state.obstacles[i].radius <= RPS_BATTLE_OBSTACLE_MAX_STANDARD_RADIUS).assertEqual(true);
      }
    });

    it('separates a unit and reflects velocity when it strikes a circular obstacle', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const obstacle: RpsBattleObstacle = {
        x: 100,
        y: 100,
        radius: 30
      };
      const entity = createEntity(60, 100, 20, 0);

      const hit = rpsBattleResolveObstacleCollision(entity, obstacle);

      expect(hit).assertEqual(true);
      expect(entity.x < 56.1).assertEqual(true);
      expect(entity.vx < 0).assertEqual(true);
    });

    it('pushes an entity out of a circular obstacle center without producing invalid coordinates', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const obstacle: RpsBattleObstacle = {
        x: 100,
        y: 100,
        radius: 30
      };
      const entity = createEntity(100, 100);

      const hit = rpsBattleResolveObstacleCollision(entity, obstacle);

      expect(hit).assertEqual(true);
      expect(Number.isFinite(entity.x)).assertEqual(true);
      expect(Number.isFinite(entity.y)).assertEqual(true);
      expect(entity.x <= 56.1 || entity.x >= 143.9 || entity.y <= 56.1 || entity.y >= 143.9).assertEqual(true);
    });

    it('clears generated state when the obstacle mechanism is disabled', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleObstacleSystem();
      system.reset(420, 620, randomSequence([0.5, 0.5, 0.5, 0.5, 0.5, 0.5]));
      expect(system.snapshot() === null).assertEqual(false);
      system.clear();
      expect(system.snapshot()).assertEqual(null);
    });
  });
}
