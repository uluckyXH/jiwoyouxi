#!/usr/bin/env python3
"""Original SVG artwork and gentle synthesized PCM sounds for the native mine garden."""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'entry/src/main/resources/rawfile/gamesNext/minesweeper'
for folder in ['icons', 'scene', 'tiles', 'audio']:
    (ROOT / folder).mkdir(parents=True, exist_ok=True)

def svg(name, body, size='0 0 24 24'):
    _, _, width, height = size.split()
    (ROOT / name).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="{size}">{body}</svg>\n')

ICONS = {
    'back': '<path d="m14 5-7 7 7 7M7 12h13"/>',
    'pause': '<path d="M8 5v14M16 5v14" stroke-width="3.5"/>',
    'play': '<path d="m8 5 11 7-11 7Z"/>',
    'restart': '<path d="M4 10a8 8 0 1 1 1 7M4 4v6h6"/>',
    'flag': '<path d="M6 21V3m0 1c5-4 7 4 13 0v10c-6 4-8-4-13 0M3 21h7"/>',
    'open': '<rect x="4" y="4" width="16" height="16" rx="4"/><path d="m8 12 3 3 5-6"/>',
    'sound': '<path d="M3 9h4l5-4v14l-5-4H3ZM16 8q4 4 0 8m3-11q7 7 0 14"/>',
    'muted': '<path d="M3 9h4l5-4v14l-5-4H3Zm13 0 6 6m0-6-6 6"/>',
    'help': '<circle cx="12" cy="12" r="9"/><path d="M9 9a3 3 0 1 1 4 3q-1 1-1 2m0 3h.01"/>',
    'close': '<path d="m6 6 12 12M6 18 18 6"/>',
    'clock': '<circle cx="12" cy="12" r="8"/><path d="M12 7v5l3 2M9 1h6"/>',
    'trophy': '<path d="M7 4h10v6a5 5 0 0 1-10 0ZM7 6H3v3q0 4 5 4m9-7h4v3q0 4-5 4m-4 2v5m-4 0h8"/>',
    'leaf': '<path d="M5 19C1 6 10 3 21 3c0 11-4 19-16 16Zm0 0L16 8"/>',
    'sprout': '<path d="M12 21V11M12 14C3 15 3 9 3 5c8 0 10 3 9 9Zm0-4C11 3 15 2 21 2c0 6-2 9-9 8Z"/>',
    'forest': '<path d="m9 2-6 8h3l-4 6h6v5m1-19 6 8h-3l4 6H8M17 5l5 8h-3l3 5h-6m1 0v3"/>',
    'pan': '<path d="M12 3v18M3 12h18M9 6l3-3 3 3M9 18l3 3 3-3M6 9l-3 3 3 3m12-6 3 3-3 3"/>',
    'check': '<path d="m5 12 5 5L20 6"/>',
    'mine': '<circle cx="12" cy="12" r="5"/><path d="M12 2v3m0 14v3M2 12h3m14 0h3M5 5l2 2m10 10 2 2M5 19l2-2M17 7l2-2"/>',
}

for theme in ['light', 'dark']:
    dark = theme == 'dark'
    ink = '#F2E6D5' if dark else '#3A4338'
    accent = '#B6D3AD' if dark else '#416B55'
    on_accent = '#1D3427' if dark else '#FFFCF2'
    paper = '#262A24' if dark else '#FFFDF4'
    border = '#485044' if dark else '#D6DEBF'
    soft = '#333D2E' if dark else '#E7EDCF'
    for name, drawing in ICONS.items():
        for tone, color in [('', ink), ('accent_', accent), ('on_', on_accent)]:
            svg(f'icons/{name}_{tone}{theme}.svg', f'<g fill="none" stroke="{color}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{drawing}</g>')
    svg(f'tiles/closed_{theme}.svg', f'''<rect x="2" y="4" width="44" height="43" rx="10" fill="{'#1A211B' if dark else '#CBD4B2'}"/>
<rect x="2" y="1" width="44" height="43" rx="10" fill="{soft}" stroke="{border}"/>
<path d="M9 15V11q0-4 4-4h17" fill="none" stroke="{'#64705B' if dark else '#FFFDF1'}" stroke-opacity=".7" stroke-width="2" stroke-linecap="round"/>
<path d="m24 20 3 4-3 4-3-4Z" fill="{'#758468' if dark else '#B5C398'}" opacity=".45"/>''', '0 0 48 48')
    svg(f'tiles/open_{theme}.svg', f'<rect x="2" y="1" width="44" height="43" rx="9" fill="{paper}" stroke="{border}" stroke-opacity=".48"/>', '0 0 48 48')
    svg(f'tiles/flag_{theme}.svg', f'''<ellipse cx="24" cy="39" rx="11" ry="3" fill="{accent}" opacity=".14"/>
<path d="M19 37V10" stroke="{ink}" stroke-width="2.8" stroke-linecap="round"/>
<path d="M20 11c6-5 10 5 18 0v16c-8 5-12-5-18 0Z" fill="{'#EFBD72' if dark else '#D89542'}" stroke="{'#E8C796' if dark else '#A87135'}" stroke-width="1.2"/>
<path d="M24 14c4 0 6 3 10 1" fill="none" stroke="#FFF0BC" stroke-width="1.7" stroke-linecap="round"/>
<path d="M14 38h11" stroke="{ink}" stroke-width="2.5" stroke-linecap="round"/>''', '0 0 48 48')
    svg(f'tiles/mine_{theme}.svg', f'''<g stroke="{ink}" stroke-width="2.8" stroke-linecap="round"><path d="M24 7v5m0 24v5M7 24h5m24 0h5M12 12l4 4m16 16 4 4M12 36l4-4m16-16 4-4"/>
<circle cx="24" cy="24" r="11" fill="{accent}"/></g><circle cx="20" cy="20" r="3" fill="{paper}" opacity=".8"/>
<circle cx="27" cy="27" r="2" fill="{ink}" opacity=".45"/>''', '0 0 48 48')
    bg = '#101110' if dark else '#FFF4E4'
    faint = '#20281F' if dark else '#E9EBCF'
    svg(f'scene/garden_{theme}.svg', f'''<rect width="1200" height="1000" fill="{bg}"/>
<path d="M0 880Q100 780 260 888T620 928T1200 850V1000H0Z" fill="{faint}"/>
<g fill="none" stroke="{border}" stroke-width="1.5" opacity=".35"><path d="M900-70c-80 70-20 180 100 170s120 100 200 70M875-80c-95 90-30 210 100 208s130 110 225 74M850-90c-110 115-35 240 100 247s160 120 250 80"/>
<path d="M-60 280c190-80 235 70 140 110s-90 160 100 150M-60 304c160-66 203 58 111 99s-78 153 116 162"/></g>
<g fill="{accent}" opacity=".18"><path d="M46 960q-70-100-14-168 47 76 14 168Zm0 0q0-111 96-126-3 98-96 126ZM1130 972q-79-90-58-165 68 38 58 165Zm0 0q-6-92 64-123 19 79-64 123Z"/></g>
<g fill="{'#D9B87E' if dark else '#C7A86B'}" opacity=".45"><circle cx="128" cy="152" r="3"/><circle cx="1100" cy="315" r="2"/><path d="m1040 780 4 8 8 4-8 4-4 8-4-8-8-4 8-4Z"/></g>''', '0 0 1200 1000')
    svg(f'scene/action_{theme}.svg', f'''<rect x="1" y="4" width="318" height="47" rx="23" fill="{'#607C56' if dark else '#294D3A'}"/>
<rect x="1" y="1" width="318" height="46" rx="23" fill="{accent}"/>
<path d="M15 22q0-13 15-13h250" stroke="{on_accent}" opacity=".22" stroke-width="2" fill="none" stroke-linecap="round"/>''', '0 0 320 52')

svg('scene/logo.svg', '''<defs><linearGradient id="base" x2="0" y2="1"><stop stop-color="#F9ECC7"/><stop offset="1" stop-color="#E8D6A5"/></linearGradient></defs>
<rect x="6" y="8" width="116" height="114" rx="35" fill="#B7BF94"/>
<rect x="6" y="4" width="116" height="112" rx="35" fill="url(#base)" stroke="#BEAA7D" stroke-width="2"/>
<g stroke="#547455" stroke-width="1.5"><rect x="25" y="60" width="24" height="26" rx="6" fill="#A7BC85"/>
<rect x="52" y="60" width="24" height="26" rx="6" fill="#F7F2D8"/><rect x="79" y="60" width="24" height="26" rx="6" fill="#A7BC85"/>
<rect x="25" y="88" width="24" height="17" rx="5" fill="#D6DFB1"/><rect x="52" y="88" width="24" height="17" rx="5" fill="#A7BC85"/><rect x="79" y="88" width="24" height="17" rx="5" fill="#D6DFB1"/></g>
<path d="M63 77V25" stroke="#3C5540" stroke-width="4" stroke-linecap="round"/>
<path d="M65 28c12-9 19 7 35-1v26c-16 8-23-8-35 1Z" fill="#4B7B5B" stroke="#33583F" stroke-width="2"/>
<path d="M70 33c8-2 14 5 23 1" stroke="#A3CAA1" stroke-width="2.5" fill="none" stroke-linecap="round"/>
<path d="M53 80h19" stroke="#3C5540" stroke-width="3" stroke-linecap="round"/>
<path d="M30 42q-13-3-11-16 14 0 16 16m-5 0q-2-17 12-21 7 15-8 22" fill="#7D9A61" stroke="#547455" stroke-width="1.5"/>
<path d="m99 78 2 5 5 2-5 2-2 5-2-5-5-2 5-2Z" fill="#C3883E"/>
<path d="M18 37q2-21 22-22" fill="none" stroke="#FFF9DF" stroke-width="4" stroke-linecap="round"/>''', '0 0 128 128')

SOUNDS = {'open': (.10, [660]), 'flood': (.27, [523, 659, 784]), 'flag': (.15, [740, 990]),
          'unflag': (.12, [590, 440]), 'tap': (.065, [880]), 'blocked': (.14, [330, 294]),
          'win': (.8, [523, 659, 784, 1046]), 'lose': (.46, [294, 247, 196])}
rate = 24000
for name, (duration, notes) in SOUNDS.items():
    data = bytearray()
    for n in range(int(rate * duration)):
        t = n / rate
        value = 0.0
        for i, frequency in enumerate(notes):
            age = t - i * duration * .17
            if age >= 0:
                envelope = min(1, age / .008) * math.exp(-age / (duration * .25))
                value += (math.sin(2 * math.pi * frequency * age) + .12 * math.sin(4 * math.pi * frequency * age)) * envelope * .34
        value *= min(1, (duration - t) / .02)
        data.extend(struct.pack('<h', round(max(-.85, min(.85, value)) * 32767)))
    with wave.open(str(ROOT / f'audio/{name}.wav'), 'wb') as out:
        out.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        out.writeframes(data)
print(f'Generated {len(list(ROOT.rglob("*.svg")))} SVGs and {len(SOUNDS)} WAVs in {ROOT}')
