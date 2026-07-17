import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import { FreecellAssetWarmup } from '../../../main/ets/games/freecell/FreecellAssetWarmup';
import {
  FREECELL_INTRO_HIDDEN_DEAL_ROUND,
  freecellIntroCanInteract,
  freecellIntroLastDealRound,
  freecellIntroShouldRenderTableauCard
} from '../../../main/ets/games/freecell/FreecellIntroRules';
import {
  FREECELL_INTRO_DEALING,
  FREECELL_INTRO_READY,
  FREECELL_INTRO_WAITING_LAYOUT,
  FREECELL_INTRO_WARMING_ASSETS
} from '../../../main/ets/games/freecell/FreecellIntroTypes';
import { FreecellCard } from '../../../main/ets/games/freecell/FreecellTypes';

function createColumn(cardCount: number, columnIndex: number): FreecellCard[] {
  const column: FreecellCard[] = [];
  for (let cardIndex = 0; cardIndex < cardCount; cardIndex += 1) {
    column.push({ id: `${columnIndex}-${cardIndex}`, suit: 'S', rank: cardIndex + 1 });
  }
  return column;
}

export default function freecellIntroRulesTest(): void {
  describe('FreecellIntroRulesTest', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
    it('reveals a shuffled six-seven-column deal in seven rounds', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const tableau: FreecellCard[][] = [7, 6, 7, 6, 7, 6, 6, 7].map(createColumn);
      expect(freecellIntroLastDealRound(tableau)).assertEqual(6);
    });

    it('hides cards before the dealing phase and reveals each round progressively', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      expect(freecellIntroShouldRenderTableauCard(FREECELL_INTRO_WARMING_ASSETS, 0, 0)).assertEqual(false);
      expect(freecellIntroShouldRenderTableauCard(FREECELL_INTRO_DEALING, 0, 0)).assertEqual(true);
      expect(freecellIntroShouldRenderTableauCard(FREECELL_INTRO_DEALING, 0, 1)).assertEqual(false);
      expect(freecellIntroShouldRenderTableauCard(FREECELL_INTRO_DEALING, 5, 5)).assertEqual(true);
      expect(freecellIntroShouldRenderTableauCard(FREECELL_INTRO_DEALING, 5, 6)).assertEqual(false);
      expect(
        freecellIntroShouldRenderTableauCard(FREECELL_INTRO_READY, FREECELL_INTRO_HIDDEN_DEAL_ROUND, 6)
      ).assertEqual(true);
    });

    it('only allows card operations after the introduction completes', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      expect(freecellIntroCanInteract(FREECELL_INTRO_WAITING_LAYOUT)).assertEqual(false);
      expect(freecellIntroCanInteract(FREECELL_INTRO_WARMING_ASSETS)).assertEqual(false);
      expect(freecellIntroCanInteract(FREECELL_INTRO_DEALING)).assertEqual(false);
      expect(freecellIntroCanInteract(FREECELL_INTRO_READY)).assertEqual(true);
    });

    it('requires every critical asset and treats any failure as static-entry fallback', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const warmup = new FreecellAssetWarmup(['background', 'title']);
      expect(warmup.markReady('unknown')).assertEqual(false);
      expect(warmup.markReady('background')).assertEqual(false);
      expect(warmup.markReady('background')).assertEqual(false);
      expect(warmup.markReady('title')).assertEqual(true);
      expect(warmup.isReady()).assertEqual(true);

      warmup.reset();
      warmup.markReady('background');
      warmup.markFailed('title');
      expect(warmup.hasFailure()).assertEqual(true);
      expect(warmup.isReady()).assertEqual(false);
    });
  });
}
