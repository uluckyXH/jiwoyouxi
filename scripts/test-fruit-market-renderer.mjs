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

function runtime(mode = 'ready') {
  const bitmaps = [];
  class Bitmap {
    constructor(path, unit) {
      assert.equal(unit, undefined, 'SVG and Canvas both use default vp coordinates');
      assert.match(path, /^resource:\/\/RAWFILE\/gamesNext\/fruitMarket\/fruits\/.*\.svg$/);
      if (mode === 'missing') throw new Error('SVG unavailable');
      this.width = this.height = mode === 'pending' ? 0 : 200;
      this.closed = 0;
      bitmaps.push(this);
    }
    close() { this.closed++; this.width = this.height = 0; }
  }
  const context = { ImageBitmap: Bitmap, hilog: { warn() {}, info() {} },
    RenderingContextSettings: class {},
    CanvasRenderingContext2D: class {
      constructor(_settings, unit) {
        assert.equal(unit, undefined, 'vp layout dimensions go straight to the default vp canvas');
      }
    }
  };
  vm.runInNewContext(stripTypeScriptTypes(source, { mode: 'transform' }) +
    '\nglobalThis.api = {MarketRenderer, MarketEngine, createMarketCanvas};', context);
  const renderer = new context.api.MarketRenderer();
  const engine = new context.api.MarketEngine(1234);
  return { renderer, engine, bitmaps, createCanvas: context.api.createMarketCanvas };
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
// Record the real renderer's transforms and map the circular SVG body back into
// physical pixels. A density-only multiplier on textures cannot move the collider.
function geometryCanvas(density) {
  // Native Canvas applies display density to vp coordinates exactly once.
  let m = [density, 0, 0, density, 0, 0];
  const stack = [], images = [];
  function multiply(n) {
    const [a,b,c,d,e,f] = m, [g,h,i,j,k,l] = n;
    m = [a*g+c*h,b*g+d*h,a*i+c*j,b*i+d*j,a*k+c*l+e,b*k+d*l+f];
  }
  function point(x,y) { return [m[0]*x+m[2]*y+m[4],m[1]*x+m[3]*y+m[5]]; }
  const ctx = new Proxy({}, { get: (_o,key) => {
    if (key === 'save') return () => stack.push([...m]);
    if (key === 'restore') return () => { m = stack.pop(); };
    if (key === 'scale') return (x,y) => multiply([x,0,0,y,0,0]);
    if (key === 'translate') return (x,y) => multiply([1,0,0,1,x,y]);
    if (key === 'rotate') return angle => multiply([Math.cos(angle),Math.sin(angle),-Math.sin(angle),Math.cos(angle),0,0]);
    if (key === 'drawImage') return (image,x,y,w,h) => images.push({
      center: point(x+w*.5,y+h*.515), edge: point(x+w*.92,y+h*.515), image
    });
    return () => {};
  }, set: () => true });
  return { ctx, images };
}
{
  const { renderer, engine, bitmaps, createCanvas } = runtime();
  createCanvas();
  renderer.prepare();
  engine.round.time = 10;
  engine.round.readyAt = 100;
  const radii = [13,17,21,26,31,37,43,50,58,67,77];
  for (const density of [1,2,3.5,6]) {
    for (const boardWidthVp of [288,360,620]) {
      const pixelScale = density * boardWidthVp / 360;
      for (let level=0; level<radii.length; level++) {
        engine.round.bodies = [{id:1,level,x:137,y:300,vx:0,vy:0,angle:.73,born:0,unlock:0}];
        const { ctx, images } = geometryCanvas(density);
        renderer.draw(ctx, engine, boardWidthVp, boardWidthVp*520/360, true, false);
        assert.equal(images.length, 1);
        const {center, edge, image} = images[0];
        assert.equal(image, bitmaps[level], 'always draw the original SVG, never the density-broken offscreen bitmap');
        assert.ok(Math.abs(center[0]-137*pixelScale) < 1e-6);
        assert.ok(Math.abs(center[1]-300*pixelScale) < 1e-6);
        assert.ok(Math.abs(Math.hypot(edge[0]-center[0],edge[1]-center[1])-radii[level]*pixelScale) < 1e-6,
          'circular SVG body must match its collider at all viewport sizes and densities');
      }
    }
  }
  assert.equal(bitmaps.length, 11, 'resize and density changes reuse source SVG handles');
  renderer.release();
  console.log('PASS 11 original SVGs: centers/radii match colliders at four densities and three viewport widths');
}
{
  const {renderer,engine}=runtime(); renderer.prepare();
  engine.drop(); for(let i=0;i<180;i++) engine.advance(1/60);
  assert.equal(engine.sleeping,true);
  const {ctx,calls}=canvas();
  assert.equal(renderer.draw(ctx,engine,360,520,false,false),true);
  const images=calls.images;
  for(let i=0;i<300;i++) {engine.advance(1/60);assert.equal(renderer.draw(ctx,engine,360,520,false,false),false);}
  assert.equal(calls.images,images,'a resting pile must not resubmit SVGs each callback');
  engine.aimAt(90);
  assert.equal(renderer.draw(ctx,engine,360,520,false,false),true,'aim changes repaint immediately');
  assert.equal(renderer.draw(ctx,engine,360,520,true,false),true,'theme changes repaint');
  assert.equal(renderer.draw(ctx,engine,620,620*520/360,true,false),true,'resizing repaints');
  renderer.prepare();
  assert.equal(renderer.draw(ctx,engine,620,620*520/360,true,false),true,'recreated Canvas repaints even at the same size');
  engine.round.overflow=.5;
  assert.equal(renderer.draw(ctx,engine,620,620*520/360,true,false),true);
  engine.round.overflow=1.5;
  assert.equal(renderer.draw(ctx,engine,620,620*520/360,true,false),true,'sleeping overflow countdown remains visible');
  engine.drop();
  assert.equal(renderer.draw(ctx,engine,620,620*520/360,true,false),true,'new drops repaint');
  console.log('PASS static SVG submission stops; aim, theme, resize, canvas recreation, warning and drop invalidate');
}
console.log('6 renderer regression cases passed. Native rendering still requires device validation.');
