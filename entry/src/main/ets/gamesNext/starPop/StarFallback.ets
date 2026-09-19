import { StarMode, StarPuzzle } from './StarModel';

// Prevalidated startup boards; runtime prepares later random boards in bounded slices.
const STAR_FALLBACKS: StarPuzzle[] = [{"seed":260919,"cells":[1,0,0,2,2,2,2,1,3,1,0,1,1,1,2,0,0,2,3,2,0,0,3,3,3,0,3,2,3,3,2,3,0,3,1,0,2,2,2,1,3,2,0,2,3,2,3,2,3,1,1,2,1,1,3,1,3,3,0,1,0,1,3,2,3,1,0,0,2,0,1,1,0,0,1,1,0,3,0,2],"witness":1940,"path":[3,30,36,40,2,52,52,58,57,50,67,56,69,31,65,67,73,67,72]},{"seed":260920,"cells":[3,0,0,1,1,1,0,4,3,4,3,2,1,2,0,2,0,3,4,4,2,4,1,2,2,1,4,2,4,1,0,0,3,1,2,4,0,1,0,0,0,3,2,3,3,2,4,4,0,4,3,2,2,1,0,0,4,3,3,1,4,0,3,1,3,1,2,4,3,3,4,4,1,2,2,3,1,2,0,1],"witness":1010,"path":[3,30,18,19,29,50,50,0,16,30,31,39,32,36,37,40,41,51,54,68,67,68,70,71,72,74,75]}];

export function starFallback(mode: StarMode): StarPuzzle {
  const p = STAR_FALLBACKS[mode === 'easy' ? 0 : 1];
  return { seed: p.seed, cells: p.cells.slice(), witness: p.witness, path: p.path.slice() };
}
