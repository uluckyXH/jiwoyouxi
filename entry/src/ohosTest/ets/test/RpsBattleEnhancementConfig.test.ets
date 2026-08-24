import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  rpsBattleDefaultEnhancementSelection,
  rpsBattleEnhancementSummary,
  rpsBattleNormalizeEnhancementSelection,
  rpsBattleSelectComebackRule,
  rpsBattleToggleGodHandSelection
} from '../../../main/ets/games/rpsBattle/RpsBattleModeConfig';
import { rpsBattleBuildResult, rpsBattleCreateOptions } from '../../../main/ets/games/rpsBattle/RpsBattleRules';
import { RpsBattleEnhancementSelection } from '../../../main/ets/games/rpsBattle/RpsBattleTypes';

function createSelection(comebackRule: 'none' | 'bounty' | 'tenAgainstOne', godHandEnabled: boolean):
  RpsBattleEnhancementSelection {
  return {
    comebackRule: comebackRule,
    godHandEnabled: godHandEnabled
  };
}

export default function rpsBattleEnhancementConfigTest(): void {
  describe('RpsBattleEnhancementConfigTest', () => {
    it('starts every mode with optional enhancements off', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const classic = rpsBattleDefaultEnhancementSelection('classic');
      const zones = rpsBattleDefaultEnhancementSelection('zones');

      expect(classic.comebackRule).assertEqual('none');
      expect(classic.godHandEnabled).assertEqual(false);
      expect(zones.comebackRule).assertEqual('none');
      expect(zones.godHandEnabled).assertEqual(false);
    });

    it('keeps classic comeback rules mutually exclusive', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const bounty = rpsBattleSelectComebackRule('classic', rpsBattleDefaultEnhancementSelection('classic'), 'bounty');
      const tenAgainstOne = rpsBattleSelectComebackRule('classic', bounty, 'tenAgainstOne');

      expect(bounty.comebackRule).assertEqual('bounty');
      expect(tenAgainstOne.comebackRule).assertEqual('tenAgainstOne');
      expect(rpsBattleEnhancementSummary('classic', tenAgainstOne)).assertEqual('我要打十个');
    });

    it('strips comeback rules outside classic while retaining god hand', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const normalized = rpsBattleNormalizeEnhancementSelection('zones', createSelection('bounty', true));

      expect(normalized.comebackRule).assertEqual('none');
      expect(normalized.godHandEnabled).assertEqual(true);
      expect(rpsBattleEnhancementSummary('zones', normalized)).assertEqual('上帝之手');
    });

    it('allows god hand to be enabled in every mode independently of comeback rules', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const zones = rpsBattleToggleGodHandSelection('zones', rpsBattleDefaultEnhancementSelection('zones'));
      const classic = rpsBattleToggleGodHandSelection('classic', createSelection('bounty', false));

      expect(zones.godHandEnabled).assertEqual(true);
      expect(zones.comebackRule).assertEqual('none');
      expect(classic.godHandEnabled).assertEqual(true);
      expect(classic.comebackRule).assertEqual('bounty');
    });

    it('normalizes options and marks a god hand result as an intervention match', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const options = rpsBattleCreateOptions(
        { rock: 8, scissors: 8, paper: 8 },
        60,
        'rock',
        'zones',
        {},
        createSelection('bounty', true)
      );
      const result = rpsBattleBuildResult(
        options,
        { rock: 12, scissors: 4, paper: 3 },
        60,
        18,
        'time'
      );

      expect(options.enhancements.comebackRule).assertEqual('none');
      expect(options.enhancements.godHandEnabled).assertEqual(true);
      expect(result.isInterventionMatch).assertEqual(true);
    });
  });
}
