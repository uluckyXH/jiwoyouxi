#!/usr/bin/env node
// Exercise the real renderer with failing/delayed native image handles on the host.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const root = resolve(import.meta.dirname, '..');
const files = ['design/CoopTheme.ets', 'gamesNext/fruitMarket/MarketModel.ets',
  'gamesNext/fruitMarket/MarketEngine.ets', 'gamesNext/fruitMarket/MarketPalette.ets',
  'gamesNext/fruitMarket/MarketRenderer.ets'];
const source = files.map(file => readFileSync(resolve(root, 'entry/src/main/ets', file), 'utf8')).join('\n')
  .replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export /gm, '');

function runtime(mode = 'ready', cacheMode = 'unavailable') {
  const bitmaps = [], sprites = [], rasterCalls = [];
  class Bitmap {
    constructor(path) {
      assert.match(path, /^resource:\/\/RAWFILE\/gamesNext\/fruitMarket\/fruits\/.*\.svg$/);
      if (mode === 'missing') throw new Error('SVG unavailable');
      this.width = this.height = mode === 'pending' ? 0 : 200;
      this.closed = 0;
      bitmaps.push(this);
    }
    close() { this.closed++; this.width = this.height = 0; }
  }
  const context = { ImageBitmap: Bitmap, console: { warn() {} } };
  if (cacheMode !== 'unavailable') {
    context.LengthMetricsUnit = { PX: 1 };
    context.RenderingContextSettings = class {};
    context.OffscreenCanvasRenderingContext2D = class {
      constructor(width, height, _settings, unit) {
        assert.equal(unit, 1, 'cache must be sized in physical pixels');
        assert.ok(width <= 768 && height <= 768, 'bound texture memory');
        this.width = width; this.height = height;
      }
      drawImage(source) {
        rasterCalls.push(source);
        if (cacheMode === 'throws') throw new Error('offscreen unavailable');
      }
      getImageData() { return { data: [0, 0, 0, cacheMode === 'transparent' ? 0 : 255] }; }
      transferToImageBitmap() {
        const sprite = { width: cacheMode === 'empty' ? 0 : this.width, height: this.height,
          isSprite: true, closed: 0, close() { this.closed++; } };
        sprites.push(sprite); return sprite;
      }
    };
  }
  vm.runInNewContext(stripTypeScriptTypes(source, { mode: 'transform' }) +
    '\nglobalThis.api = {MarketRenderer, MarketEngine};', context);
  const renderer = new context.api.MarketRenderer();
  const engine = new context.api.MarketEngine(1234);
  return { renderer, engine, bitmaps, sprites, rasterCalls };
}

function canvas(failDraw = false) {
  const calls = { images: 0, labels: [], depth: 0 };
  const ctx = new Proxy({}, {
    get: (_object, key) => {
      if (key === 'drawImage') return image => { calls.images++;
        if (typeof failDraw === 'function' ? failDraw(image) : failDraw) throw new Error('draw failed'); };
      if (key === 'fillText') return value => calls.labels.push(value);
      if (key === 'save') return () => { calls.depth++; };
      if (key === 'restore') return () => { calls.depth--; };
      return () => {};
    },
    set: () => true
  });
  return { ctx, calls };
}

{
  const { renderer, engine, bitmaps } = runtime();
  renderer.prepare(); renderer.prepare();
  assert.equal(bitmaps.length, 11, 'load SVGs once, directly from rawfile');
  const { ctx, calls } = canvas();
  engine.drop();
  renderer.draw(ctx, engine, 360, 520, false, false);
  assert.ok(calls.images > 0);
  assert.equal(calls.depth, 0);
  renderer.release();
  assert.ok(bitmaps.every(image => image.closed === 1));
  console.log('PASS SVG drawing and release');
}
{
  const { renderer, engine } = runtime('missing');
  renderer.prepare();
  const { ctx, calls } = canvas();
  for (let i = 0; i < 2; i++) {
    assert.equal(engine.drop(), true);
    for (let frame = 0; frame < 60; frame++) {
      engine.advance(1 / 60);
      renderer.draw(ctx, engine, 360, 520, true, false);
    }
  }
  assert.ok(calls.labels.includes('1'), 'unavailable artwork still draws a visible labelled fruit');
  assert.ok(calls.labels.includes('2'), 'merged fruit also remains visible');
  assert.ok(engine.round.score > 0, 'missing artwork cannot prevent dropping or merging');
  assert.equal(calls.depth, 0);
  console.log('PASS all SVG loads fail: visible fruit, drop and merge still work');
}
{
  const { renderer, engine, bitmaps } = runtime('pending');
  renderer.prepare();
  const { ctx, calls } = canvas();
  renderer.draw(ctx, engine, 360, 520, false, false);
  assert.equal(calls.images, 0);
  assert.ok(calls.labels.includes('1'));
  for (const image of bitmaps) image.width = image.height = 200;
  renderer.draw(ctx, engine, 360, 520, false, false);
  assert.equal(calls.images, 1, 'late SVG readiness replaces the fallback without restarting');
  assert.equal(calls.depth, 0);
  console.log('PASS late SVG readiness recovers without restarting the game');
}
{
  const { renderer, engine, bitmaps } = runtime();
  renderer.prepare();
  const { ctx, calls } = canvas(true);
  renderer.draw(ctx, engine, 360, 520, true, true);
  renderer.draw(ctx, engine, 360, 520, true, true);
  assert.equal(calls.images, 1, 'disable a broken image instead of throwing every frame');
  assert.equal(calls.labels.filter(value => value === '1').length, 2);
  renderer.release();
  assert.ok(bitmaps.every(image => image.closed === 1));
  assert.equal(calls.depth, 0);
  console.log('PASS drawing errors fall back and close image handles once');
}
{
  const { renderer, engine, bitmaps, sprites, rasterCalls } = runtime('ready', 'ready');
  renderer.prepare(); engine.drop();
  engine.round.bodies.push({ ...engine.round.bodies[0], id: 2, level: 1 });
  const { ctx, calls } = canvas();
  renderer.draw(ctx, engine, 360, 520, false, false, 3.5);
  assert.equal(rasterCalls.length, 1, 'bake at most one level per display frame');
  for (let i = 0; i < 60; i++) renderer.draw(ctx, engine, 360, 520, false, false, 3.5);
  assert.equal(rasterCalls.length, 2, 'repeated fruit share two textures, not one raster per fruit per frame');
  renderer.draw(ctx, engine, 720, 1040, false, false, 7);
  assert.ok(sprites.slice(0, 2).every(image => image.closed === 1), 'resize releases obsolete textures');
  renderer.release();
  assert.ok([...bitmaps, ...sprites].every(image => image.closed === 1));
  assert.equal(calls.depth, 0);
  console.log('PASS bounded raster cache reuse, frame budget, density resize and release');
}
for (const failure of ['throws', 'transparent', 'empty']) {
  const { renderer, engine, bitmaps, sprites, rasterCalls } = runtime('ready', failure);
  renderer.prepare();
  const { ctx, calls } = canvas();
  for (let i = 0; i < 3; i++) renderer.draw(ctx, engine, 360, 520, true, false);
  assert.equal(calls.images, 3, 'cache failure still paints the original SVG');
  assert.equal(calls.labels.length, 0, 'no placeholder needed when source artwork works');
  assert.equal(rasterCalls.length, 1, 'avoid retrying broken offscreen operations every frame');
  renderer.release();
  assert.ok([...bitmaps, ...sprites].every(image => image.closed === 1));
  console.log(`PASS ${failure} raster cache preserves source SVG`);
}
{
  const { renderer, engine, bitmaps, sprites } = runtime('ready', 'ready');
  renderer.prepare();
  const { ctx, calls } = canvas(image => image.isSprite);
  renderer.draw(ctx, engine, 360, 520, false, false);
  renderer.draw(ctx, engine, 360, 520, false, false);
  assert.equal(calls.images, 3, 'bad cached image falls back to SVG in the same frame');
  assert.equal(calls.labels.length, 0);
  renderer.release();
  assert.ok([...bitmaps, ...sprites].every(image => image.closed === 1));
  console.log('PASS cached draw failure recovers original SVG without interrupting play');
}
console.log('9 renderer regression cases passed. Native rendering still requires device validation.');
