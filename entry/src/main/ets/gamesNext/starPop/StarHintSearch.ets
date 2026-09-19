import { StarPlan } from './StarModel';
import { StarPlanner } from './StarPlanner';
import { starNow } from './StarPerf';

export interface StarHintTiming {
  elapsed: number;
  slices: number;
  compute: number;
  peak: number;
  cancelled: boolean;
}

/** Only needed after a detour or for an old save; normal route hints are immediate. */
export class StarHintSearch {
  private timer: number = -1;
  private generation: number = 0;
  private resolve: ((plan: StarPlan | undefined) => void) | undefined = undefined;
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

  search(cells: number[], timing: (result: StarHintTiming) => void = () => {}): Promise<StarPlan | undefined> {
    this.cancel();
    const began = starNow();
    const token = this.generation;
    const planner = new StarPlanner(cells);
    return new Promise<StarPlan | undefined>((resolve) => {
      this.resolve = resolve;
      let slices = 0;
      let compute = 0;
      let peak = 0;
      this.report = (cancelled: boolean): void => {
        timing({ elapsed: starNow() - began, slices: slices, compute: compute, peak: peak, cancelled: cancelled });
      };
      const slice = (): void => {
        if (token !== this.generation) return;
        const started = starNow();
        slices++;
        for (let i = 0; i < 2 && !planner.done; i++) {
          planner.advance();
          if (starNow() - started >= 4) break;
        }
        const ms = starNow() - started;
        compute += ms;
        peak = Math.max(peak, ms);
        if (planner.done || planner.steps >= 82) {
          this.timer = -1;
          this.resolve = undefined;
          if (this.report !== undefined) this.report(false);
          this.report = undefined;
          resolve(planner.result());
        } else {
          this.timer = setTimeout(slice, 0);
        }
      };
      this.timer = setTimeout(slice, 0);
    });
  }
}
