import {
  FREECELL_INTRO_DEALING,
  FREECELL_INTRO_READY,
  FreecellIntroPhase
} from './FreecellIntroTypes';
import { FreecellCard } from './FreecellTypes';

export const FREECELL_INTRO_HIDDEN_DEAL_ROUND: number = -1;

export function freecellIntroLastDealRound(tableau: FreecellCard[][]): number {
  let lastRound = 0;
  for (let columnIndex = 0; columnIndex < tableau.length; columnIndex += 1) {
    const cardCount = tableau[columnIndex].length;
    if (cardCount > 0) {
      lastRound = Math.max(lastRound, cardCount - 1);
    }
  }
  return lastRound;
}

export function freecellIntroShouldRenderTableauCard(
  phase: FreecellIntroPhase,
  dealRound: number,
  cardIndex: number
): boolean {
  if (phase === FREECELL_INTRO_READY) {
    return true;
  }
  if (phase !== FREECELL_INTRO_DEALING) {
    return false;
  }
  return cardIndex <= dealRound;
}

export function freecellIntroCanInteract(phase: FreecellIntroPhase): boolean {
  return phase === FREECELL_INTRO_READY;
}
