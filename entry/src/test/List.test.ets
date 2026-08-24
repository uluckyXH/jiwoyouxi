import rpsBattleBountySystemTest from '../ohosTest/ets/test/RpsBattleBountySystem.test';
import rpsBattleEnhancementConfigTest from '../ohosTest/ets/test/RpsBattleEnhancementConfig.test';
import rpsBattleGodHandSystemTest from '../ohosTest/ets/test/RpsBattleGodHandSystem.test';
import rpsBattleTenAgainstOneSystemTest from '../ohosTest/ets/test/RpsBattleTenAgainstOneSystem.test';

export default function testSuite(): void {
  rpsBattleBountySystemTest();
  rpsBattleEnhancementConfigTest();
  rpsBattleGodHandSystemTest();
  rpsBattleTenAgainstOneSystemTest();
}
