import freecellIntroRulesTest from './FreecellIntroRules.test';
import rpsBattleBountySystemTest from './RpsBattleBountySystem.test';
import rpsBattleEnhancementConfigTest from './RpsBattleEnhancementConfig.test';
import rpsBattleEqualityModeConfigTest from './RpsBattleEqualityModeConfig.test';
import rpsBattleGodHandSystemTest from './RpsBattleGodHandSystem.test';
import rpsBattleLastStandSystemTest from './RpsBattleLastStandSystem.test';
import rpsBattleObstacleSystemTest from './RpsBattleObstacleSystem.test';
import rpsBattlePowerUpSystemTest from './RpsBattlePowerUpSystem.test';
import rpsBattleShrinkSystemTest from './RpsBattleShrinkSystem.test';
import rpsBattleSnapSystemTest from './RpsBattleSnapSystem.test';
import rpsBattleTenAgainstOneSystemTest from './RpsBattleTenAgainstOneSystem.test';
import rpsBattleTraitorSystemTest from './RpsBattleTraitorSystem.test';
import rpsBattleZoneSystemTest from './RpsBattleZoneSystem.test';

export default function testSuite(): void {
  freecellIntroRulesTest();
  rpsBattleBountySystemTest();
  rpsBattleEnhancementConfigTest();
  rpsBattleEqualityModeConfigTest();
  rpsBattleGodHandSystemTest();
  rpsBattleLastStandSystemTest();
  rpsBattleObstacleSystemTest();
  rpsBattlePowerUpSystemTest();
  rpsBattleShrinkSystemTest();
  rpsBattleSnapSystemTest();
  rpsBattleTenAgainstOneSystemTest();
  rpsBattleTraitorSystemTest();
  rpsBattleZoneSystemTest();
}
