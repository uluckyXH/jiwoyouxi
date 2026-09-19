import { StarGenerator, starVerifyPuzzle } from './StarGenerator';
import { StarMode, StarPuzzle } from './StarModel';
import { starFallback } from './StarFallback';
import { starNow } from './StarPerf';

export interface StarPreparationTiming {
  elapsed: number;
  slices: number;
  compute: number;
  peak: number;
  verification: number;
  cancelled: boolean;
  fallback: boolean;
}

/** Yield between at most two heuristic moves; never generate a board inside a tile tap. */
export class StarPreparation {
  private timer: number = -1;
  private generation: number = 0;
  private resolve: ((puzzle: StarPuzzle | undefined) => void) | undefined = undefined;
  private report: ((cancelled: boolean) => void) | undefined = undefined;
  cancel(): void {
    this.generation++;
    if (this.timer >= 0) clearTimeout(this.timer);
    this.timer = -1;
    if (this.report !== undefined) this.report(true);
    this.report = undefined;
    if (this.resolve !== undefined) this.resolve(undefined);
    this.resolve = undefined;
  }
  prepare(mode: StarMode, seed: number,
    timing: (result: StarPreparationTiming) => void = () => {}): Promise<StarPuzzle | undefined> {
    this.cancel();
    const began = starNow();
    const token = this.generation;
    const generator = new StarGenerator(seed, mode);
    return new Promise<StarPuzzle | undefined>((resolve) => {
      this.resolve = resolve;
      let slices = 0;
      let compute = 0;
      let peak = 0;
      let verification = 0;
      let fallback = false;
      this.report = (cancelled: boolean): void => {
        timing({ elapsed: starNow() - began, slices: slices, compute: compute, peak: peak,
          verification: verification, cancelled: cancelled, fallback: fallback });
      };
      const slice = (): void => {
        if (token !== this.generation) return;
        const started = starNow();
        slices++;
        for (let i = 0; i < 2 && !generator.done; i++) {
          generator.advance();
          if (starNow() - started >= 4) break;
        }
        const ms = starNow() - started;
        compute += ms; peak = Math.max(peak, ms);
        if (generator.done || generator.steps > 82) {
          const result = generator.result();
          const verifyStart = starNow();
          fallback = result === undefined || !starVerifyPuzzle(result, mode);
          const puzzle = fallback ? starFallback(mode) : result;
          verification = starNow() - verifyStart;
          this.timer = -1; this.resolve = undefined;
          if (this.report !== undefined) this.report(false);
          this.report = undefined;
          resolve(puzzle);
        } else this.timer = setTimeout(slice, 0);
      };
      this.timer = setTimeout(slice, 0);
    });
  }
}
