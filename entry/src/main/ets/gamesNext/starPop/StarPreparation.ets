import { StarGenerator, starVerifyPuzzle } from './StarGenerator';
import { StarMode, StarPuzzle } from './StarModel';
import { starFallback } from './StarFallback';

/** Yield between at most two heuristic moves; never generate a board inside a tile tap. */
export class StarPreparation {
  private timer: number = -1;
  private generation: number = 0;
  private resolve: ((puzzle: StarPuzzle | undefined) => void) | undefined = undefined;
  cancel(): void {
    this.generation++;
    if (this.timer >= 0) clearTimeout(this.timer);
    this.timer = -1;
    if (this.resolve !== undefined) this.resolve(undefined);
    this.resolve = undefined;
  }
  prepare(mode: StarMode, seed: number): Promise<StarPuzzle | undefined> {
    this.cancel();
    const token = this.generation;
    const generator = new StarGenerator(seed, mode);
    return new Promise<StarPuzzle | undefined>((resolve) => {
      this.resolve = resolve;
      const slice = (): void => {
        if (token !== this.generation) return;
        const started = Date.now();
        for (let i = 0; i < 2 && !generator.done; i++) {
          generator.advance();
          if (Date.now() - started >= 4) break;
        }
        if (generator.done || generator.steps > 82) {
          const result = generator.result();
          this.timer = -1; this.resolve = undefined;
          resolve(result !== undefined && starVerifyPuzzle(result, mode) ? result : starFallback(mode));
        } else this.timer = setTimeout(slice, 0);
      };
      this.timer = setTimeout(slice, 0);
    });
  }
}
