#!/usr/bin/env node
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { resolve } from 'node:path';

// SVG-only generation. No fonts, embedded bitmaps, external resources or image tools.
const root = resolve(import.meta.dirname, '..');
const artwork = readFileSync(resolve(root, 'assets/brand/chicken_mark.svg'), 'utf8');
const shapes = artwork.slice(artwork.indexOf('>') + 1, artwork.lastIndexOf('</svg>'));
const svg = (body) => `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">\n${body}\n</svg>\n`;
const write = (path, body) => {
  const full = resolve(root, path);
  mkdirSync(resolve(full, '..'), { recursive: true });
  writeFileSync(full, body);
};
const paper = `<defs><linearGradient id="paper" x1="0" y1="0" x2="0" y2="1">
  <stop stop-color="#F9E7B8"/><stop offset="1" stop-color="#EDC880"/>
</linearGradient></defs><rect width="512" height="512" fill="url(#paper)"/>`;
write('AppScope/resources/base/media/app_icon.svg', svg(paper + shapes));
write('entry/src/main/resources/base/media/start_icon.svg', svg(shapes));
const dark = shapes.replaceAll('#B5C7A5', '#354633').replaceAll('#DCE5C6', '#526347')
  .replaceAll('#A17C4D', '#000000').replaceAll('#FFF4D6', '#E9C985');
write('entry/src/main/resources/dark/media/start_icon.svg', svg(dark));
console.log('Generated launcher and light/dark start marks from assets/brand/chicken_mark.svg');
