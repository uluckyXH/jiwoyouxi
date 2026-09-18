#!/usr/bin/env python3
"""Original code-drawn SVG art and synthesized chimes for 暖光叠数."""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'entry/src/main/resources/rawfile/gamesNext/glow2048'
for folder in ('icons', 'scene', 'tiles', 'audio'):
    (ROOT / folder).mkdir(parents=True, exist_ok=True)

def svg(name, body, width=24, height=24):
    (ROOT / name).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">{body}</svg>\n')

ICONS = {
    'back': '<path d="m13 5-7 7 7 7M6 12h14"/>',
    'left': '<path d="m13 6-6 6 6 6M7 12h12"/>',
    'right': '<path d="m11 6 6 6-6 6M5 12h12"/>',
    'up': '<path d="m6 13 6-6 6 6M12 7v12"/>',
    'down': '<path d="m6 11 6 6 6-6M12 5v12"/>',
    'sound': '<path d="M3 9h4l5-4v14l-5-4H3ZM16 8q4 4 0 8m3-11q7 7 0 14"/>',
    'muted': '<path d="M3 9h4l5-4v14l-5-4H3Zm13 0 6 6m0-6-6 6"/>',
    'pause': '<path d="M8 5v14M16 5v14" stroke-width="3.2"/>',
    'play': '<path d="m8 4 11 8-11 8Z"/>',
    'restart': '<path d="M4 10a8 8 0 1 1 1 7M4 4v6h6"/>',
    'help': '<circle cx="12" cy="12" r="9"/><path d="M9 9a3 3 0 1 1 4 3q-1 1-1 2m0 3h.01"/>',
    'close': '<path d="m6 6 12 12M6 18 18 6"/>',
    'spark': '<path d="m12 2 3.2 6.8L22 12l-6.8 3.2L12 22l-3.2-6.8L2 12l6.8-3.2Z"/>',
    'trophy': '<path d="M7 4h10v6a5 5 0 0 1-10 0ZM7 6H3v3q0 4 5 4m9-7h4v3q0 4-5 4m-4 2v5m-4 0h8"/>',
    'steps': '<rect x="3" y="12" width="7" height="9" rx="2"/><rect x="14" y="3" width="7" height="9" rx="2"/><path d="m5 6 3-3 3 3m-3-3v6m8 8v4m-3-3 3 3 3-3"/>',
    'sun': '<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M2 12h2m16 0h2M5 5l2 2m10 10 2 2M5 19l2-2M17 7l2-2"/>',
    'check': '<path d="m5 12 5 5L20 6"/>',
}
light = ['#F0E9D5', '#DDE7C4', '#BDDAC3', '#ECCAA1', '#B77353', '#AF5B4A', '#E4BA62', '#D7B554', '#6E8B58', '#3C7360', '#F2D38B']
night = ['#3D4B3D', '#485C43', '#496652', '#79644C', '#8D583F', '#914A3B', '#81672E', '#806B30', '#526F3E', '#356958', '#907438']
for theme in ('light', 'dark'):
    dark = theme == 'dark'
    ink, accent, on = ('#F5EBD9', '#B9D5A7', '#243B2B') if dark else ('#354639', '#34664D', '#FFFDF1')
    line = '#485946' if dark else '#DCE3C8'
    for name, shape in ICONS.items():
        for tone, color in [('ink', ink), ('accent', accent), ('on', on)]:
            svg(f'icons/{name}_{tone}_{theme}.svg', f'<g fill="none" stroke="{color}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{shape}</g>')
    for rank, color in enumerate(night if dark else light, 1):
        svg(f'tiles/{rank}_{theme}.svg', f'''<rect x="1" y="4" width="94" height="91" rx="19" fill="{'#0F1911' if dark else '#A3A78B'}" fill-opacity=".45"/>
<rect x="1" y="1" width="94" height="91" rx="19" fill="{color}" stroke="{'#DDDDBB' if dark else '#5F6849'}" stroke-opacity=".18"/>
<path d="M9 29v-8q0-11 12-11h38" fill="none" stroke="#FFF7DF" stroke-opacity=".28" stroke-width="2" stroke-linecap="round"/>
<path d="M18 83h45q22 0 22-18" fill="none" stroke="#273D2B" stroke-opacity=".10" stroke-width="1.4"/>
<path d="m77 14 2 4 4 2-4 2-2 4-2-4-4-2 4-2Z" fill="#FFF4C8" fill-opacity="{'.48' if rank >= 7 else '.15'}"/>''', 96, 96)
    svg(f'tiles/slot_{theme}.svg', f'<rect x="1" y="1" width="94" height="94" rx="19" fill="{accent}" fill-opacity=".07" stroke="{line}" stroke-opacity=".4"/><path d="M43 48h10m-5-5v10" stroke="{accent}" stroke-opacity=".14" stroke-width="1.2"/>', 96, 96)
    svg(f'scene/corner_{theme}.svg', f'''<g fill="none" stroke="{accent}" stroke-opacity=".13" stroke-width="1.2">
<rect x="86" y="-37" width="120" height="120" rx="32" transform="rotate(18 146 23)"/>
<rect x="72" y="-47" width="148" height="148" rx="40" transform="rotate(18 146 23)"/>
<path d="M27 165h38m-19-19v38M177 138h14m-7-7v14"/></g>
<path d="m124 117 4 9 9 4-9 4-4 9-4-9-9-4 9-4Z" fill="{'#EBC581' if dark else '#CFA66A'}" fill-opacity=".3"/>
<circle cx="75" cy="210" r="2" fill="{accent}" fill-opacity=".2"/>''', 240, 260)
    svg(f'scene/burst_{theme}.svg', f'''<g fill="none" stroke="{'#F6D99C' if dark else '#CB974F'}" stroke-width="2" stroke-linecap="round">
<path d="M48 3v10m0 70v10M3 48h10m70 0h10M16 16l7 7m50 50 7 7M16 80l7-7m50-50 7-7"/>
<circle cx="48" cy="48" r="32" stroke-opacity=".25" stroke-width="1"/></g>''', 96, 96)
    svg(f'scene/medal_{theme}.svg', f'''<circle cx="64" cy="64" r="51" fill="{accent}" fill-opacity=".08"/>
<rect x="28" y="26" width="72" height="74" rx="23" fill="{'#806B30' if dark else '#F2D38B'}" stroke="{'#D5B568' if dark else '#DBBC75'}"/>
<path d="m64 39 7 17 18 8-18 7-7 18-7-18-18-7 18-8Z" fill="{'#F5DF9D' if dark else '#9E7933'}"/>
<g stroke="{accent}" stroke-width="2" stroke-linecap="round"><path d="M18 26l-5-5M109 26l6-5M13 93l6-4M110 95l5 4"/></g>''', 128, 128)

sounds = {'slide': (.085, [440]), 'merge': (.18, [523, 784]), 'bright': (.24, [659, 988, 1318]),
          'tap': (.07, [880]), 'blocked': (.1, [220]), 'milestone': (.42, [523, 659, 784]),
          'win': (.85, [523, 659, 784, 1046]), 'end': (.48, [392, 330, 262])}
rate = 24000
for name, (duration, notes) in sounds.items():
    data = bytearray()
    for n in range(int(rate * duration)):
        t = n / rate
        sample = 0.0
        for i, frequency in enumerate(notes):
            age = t - i * duration * .18
            if age >= 0:
                envelope = min(1, age / .008) * math.exp(-age / (duration * .28))
                sample += (.30 * math.sin(2 * math.pi * frequency * age) + .035 * math.sin(4 * math.pi * frequency * age)) * envelope
        sample *= min(1, (duration - t) / .02)
        data.extend(struct.pack('<h', round(max(-.8, min(.8, sample)) * 32767)))
    with wave.open(str(ROOT / f'audio/{name}.wav'), 'wb') as out:
        out.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        out.writeframes(data)
print(f'Generated {len(list(ROOT.rglob("*.svg")))} SVGs and {len(sounds)} WAVs')
