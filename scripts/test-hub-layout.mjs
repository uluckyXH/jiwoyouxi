#!/usr/bin/env node
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const source = readFileSync(resolve(root, 'entry/src/main/ets/design/HubLayout.ets'), 'utf8')
  .replace(/^export\s+/gm, '');
const context = {};
vm.runInNewContext(`${stripTypeScriptTypes(source, { mode: 'transform' })}\nthis.api = { hubLayout, hubUsableFrame };`, context);
const { hubLayout, hubUsableFrame } = context.api;
const zero = { top: 0, right: 0, bottom: 0, left: 0 };
const close = (a, b) => assert.ok(Math.abs(a - b) < 0.001, `${a} ≈ ${b}`);
const intersects = (a, b) => a.x < b.x + b.width && a.x + a.width > b.x && a.y < b.y + b.height && a.y + a.height > b.y;

const phone = hubLayout(390, 844);
assert.equal(phone.navigation, 'bottom');
assert.equal(phone.columns, 2);
assert.equal(phone.frame.width, 390);
assert.equal(hubLayout(320, 720).columns, 1, 'narrow cover screens must not squeeze two unreadable cards');
assert.equal(hubLayout(390, 844, zero, [], 1.6).columns, 1, 'larger text reduces grid density');
assert.equal(hubLayout(599, 900, zero).navigation, 'bottom');
assert.equal(hubLayout(600, 900, zero).navigation, 'rail');
assert.equal(hubLayout(1199, 900, zero).navigation, 'rail');
assert.equal(hubLayout(1200, 900, zero).navigation, 'sidebar');
assert.equal(hubLayout(844, 390, zero).navigation, 'rail');
assert.equal(hubLayout(844, 390, zero).showOverview, false, 'short windows prioritize the games');
assert.equal(hubLayout(820, 1180).frame.width, 820, 'tablets use the available width instead of a phone frame');
assert.equal(hubLayout(1440, 1000).splitDetail, true);
assert.equal(hubLayout(1440, 1000, zero, [], 2).splitDetail, false, 'large type can collapse the master/detail view');
assert.equal(hubLayout(2560, 1440).contentWidth, 1280, 'very wide windows keep a readable maximum content width');
assert.equal(hubLayout(1440, 1000).showOverview, true);

const insets = { top: 32, right: 18, bottom: 24, left: 12 };
const safe = hubUsableFrame(900, 1000, insets, []);
assert.equal(safe.x, 12); assert.equal(safe.y, 32);
assert.equal(safe.width, 870); assert.equal(safe.height, 944);
const folds = [
  { width: 1000, height: 1000, creases: [{ x: 0, y: 484, width: 1000, height: 32 }] },
  { width: 1200, height: 900, creases: [{ x: 480, y: 0, width: 24, height: 900 }] },
  { width: 1600, height: 1000, creases: [{ x: 500, y: 0, width: 24, height: 1000 }, { x: 1080, y: 0, width: 24, height: 1000 }] },
  { width: 600, height: 800, creases: [{ x: -100, y: 370, width: 900, height: 30 }] }
];
for (const { width, height, creases } of folds) {
  const layout = hubLayout(width, height, insets, creases);
  for (const crease of creases) assert.equal(intersects(layout.frame, crease), false, 'all interactive content must clear the hinge');
  assert.ok(layout.frame.width > 0 && layout.frame.height > 0);
}
const outside = hubUsableFrame(600, 800, zero, [{ x: 900, y: 0, width: 20, height: 800 }]);
assert.equal(outside.width, 600, 'creases outside a floating window have no effect');
const invalid = hubLayout(NaN, Infinity);
assert.equal(invalid.frame.width, 390); assert.ok(Number.isFinite(invalid.contentHeight));

let cases = 0;
for (let width = 240; width <= 2560; width += 17) {
  for (const height of [240, 390, 600, 844, 1000, 1440]) {
    for (const scale of [1, 1.3, 1.6, 2]) {
      const layout = hubLayout(width, height, insets, [], scale);
      assert.ok(layout.frame.x >= 0 && layout.frame.y >= 0);
      assert.ok(layout.frame.x + layout.frame.width <= width);
      assert.ok(layout.frame.y + layout.frame.height <= height);
      assert.ok(layout.contentWidth > 0 && layout.contentHeight > 0);
      close(layout.cardWidth * layout.columns + layout.gap * (layout.columns - 1), layout.contentWidth);
      assert.ok(layout.contentWidth + layout.navigationWidth + layout.padding * 2 <= layout.frame.width + 0.001);
      if (layout.splitDetail) assert.ok(layout.contentWidth - layout.detailWidth - 24 >= 400);
      cases++;
    }
  }
}
console.log(`Hub layout: phone/fold/tablet, safe areas, multiple hinges, font scaling and ${cases} window combinations passed.`);
