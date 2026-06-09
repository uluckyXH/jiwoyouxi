import { Entity, TYPE_COUNT } from './GameTypes';

export function countEntities(entities: Entity[]): number[] {
  const result = [0, 0, 0];
  for (let i = 0; i < entities.length; i += 1) {
    const entity = entities[i];
    if (entity.alive) {
      result[entity.type] += 1;
    }
  }
  return result;
}

export function aliveTypeCount(counts: number[]): number {
  let total = 0;
  for (let type = 0; type < TYPE_COUNT; type += 1) {
    if (counts[type] > 0) {
      total += 1;
    }
  }
  return total;
}

export function aliveTypeList(counts: number[]): number[] {
  const types: number[] = [];
  for (let type = 0; type < TYPE_COUNT; type += 1) {
    if (counts[type] > 0) {
      types.push(type);
    }
  }
  return types;
}

export function leadingType(counts: number[]): number {
  let winner = -1;
  let max = -1;
  let tied = false;
  for (let type = 0; type < TYPE_COUNT; type += 1) {
    if (counts[type] > max) {
      winner = type;
      max = counts[type];
      tied = false;
    } else if (counts[type] === max) {
      tied = true;
    }
  }
  return tied || max <= 0 ? -1 : winner;
}
