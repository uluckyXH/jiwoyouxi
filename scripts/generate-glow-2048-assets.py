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
    # Transparent scene layers: no rectangular ground band or cropped cover art.
    gold = '#D5AF6B' if dark else '#D3A267'
    leaf = '#526C4A' if dark else '#AFC494'
    clay = '#82624B' if dark else '#D6AD86'
    svg(f'scene/atmosphere_{theme}.svg', f'''<defs>
<radialGradient id="sun" gradientUnits="userSpaceOnUse" cx="710" cy="180" r="570"><stop stop-color="{gold}" stop-opacity="{'.09' if dark else '.15'}"/><stop offset="100%" stop-color="{gold}" stop-opacity="0"/></radialGradient>
<radialGradient id="moss" gradientUnits="userSpaceOnUse" cx="140" cy="980" r="520"><stop stop-color="{leaf}" stop-opacity="{'.20' if dark else '.26'}"/><stop offset="100%" stop-color="{leaf}" stop-opacity="0"/></radialGradient></defs>
<rect width="800" height="1000" fill="url(#sun)"/><rect width="800" height="1000" fill="url(#moss)"/>
<g fill="none" stroke="{accent}" stroke-opacity=".09" stroke-width="1.4">
<path d="M-40 898Q140 826 364 914T850 900M-40 914Q154 846 370 931T850 918M-40 952Q208 893 431 962T850 960"/>
<path d="M-20 194Q90 164 138 227T243 288" stroke-dasharray="3 13"/></g>
<g fill="{gold}" fill-opacity=".38"><circle cx="58" cy="367" r="2.5"/><circle cx="751" cy="484" r="2"/><circle cx="724" cy="746" r="2.5"/>
<path d="m92 772 4 9 9 4-9 4-4 9-4-9-9-4 9-4ZM670 286l3 7 7 3-7 3-3 7-3-7-7-3 7-3Z"/></g>''', 800, 1000)
    svg(f'scene/window_{theme}.svg', f'''<defs><linearGradient id="beam" gradientUnits="userSpaceOnUse" x1="160" y1="170" x2="160" y2="430">
<stop stop-color="{gold}" stop-opacity=".16"/><stop offset="100%" stop-color="{gold}" stop-opacity="0"/></linearGradient></defs>
<path d="M95 220 26 430h117l37-210Zm102 0-31 210h135l-19-210Z" fill="url(#beam)"/>
<path d="M90 223V113a92 92 0 0 1 184 0v110Z" fill="{gold}" fill-opacity=".09" stroke="{accent}" stroke-opacity=".18" stroke-width="2"/>
<path d="M101 213V113a81 81 0 0 1 162 0v100Z" fill="none" stroke="{gold}" stroke-opacity=".35" stroke-width="1.5"/>
<path d="M182 32v181m-81-93h162M81 230h202" stroke="{accent}" stroke-opacity=".18" stroke-width="2" stroke-linecap="round"/>
<circle cx="217" cy="81" r="20" fill="{gold}" fill-opacity=".2"/>
<path d="M119 95q8-8 16 0m0 0q8-8 16 0" fill="none" stroke="{accent}" stroke-opacity=".24" stroke-width="1.5" stroke-linecap="round"/>
<g fill="{gold}" fill-opacity=".5"><path d="m50 166 4 10 10 4-10 4-4 10-4-10-10-4 10-4Z"/><circle cx="296" cy="266" r="2.5"/><circle cx="73" cy="303" r="2"/></g>''', 320, 440)
    svg(f'scene/garden_{theme}.svg', f'''<ellipse cx="94" cy="275" rx="79" ry="12" fill="{accent}" fill-opacity=".06"/>
<g stroke="{accent}" stroke-opacity=".28" stroke-width="1.7" stroke-linejoin="round">
<path d="M93 215Q67 136 105 41Q151 99 98 153" fill="{leaf}" fill-opacity=".5"/>
<path d="M87 186Q26 169 35 104Q100 110 96 176M93 208Q104 133 166 126Q162 193 96 214" fill="{leaf}" fill-opacity=".6"/>
<path d="M90 208Q47 186 26 205Q44 243 91 229M97 228Q125 184 181 192Q149 238 98 238" fill="{leaf}" fill-opacity=".4"/>
<path d="M96 242Q80 148 105 63M92 194l-43-72M96 218l53-71M91 228l-49-16m57 23 65-33" fill="none"/>
<path d="M65 226h64l-9 44q-27 12-47 0Z" fill="{clay}" fill-opacity=".5"/><path d="M61 224q33-7 72 0l-2 9q-35 5-68 0Z" fill="{clay}" fill-opacity=".6"/>
<path d="m79 241 3 22m15-22v25m16-25-3 22" stroke-opacity=".2"/>
</g><g fill="none" stroke="{gold}" stroke-opacity=".4" stroke-width="1.5"><ellipse cx="169" cy="273" rx="13" ry="6" transform="rotate(-13 169 273)"/><path d="M186 272q13-13 25-4"/></g>
<g fill="{gold}" fill-opacity=".5"><circle cx="182" cy="89" r="2"/><path d="m208 182 3 7 7 3-7 3-3 7-3-7-7-3 7-3Z"/></g>''', 260, 300)
    svg(f'scene/stilllife_{theme}.svg', f'''<ellipse cx="202" cy="170" rx="100" ry="13" fill="{accent}" fill-opacity=".06"/>
<g stroke="{accent}" stroke-opacity=".24" stroke-width="1.5">
<rect x="134" y="110" width="66" height="58" rx="15" fill="{leaf}" fill-opacity=".45"/>
<rect x="203" y="102" width="72" height="66" rx="17" fill="{clay}" fill-opacity=".4"/>
<rect x="176" y="40" width="65" height="62" rx="16" fill="{gold}" fill-opacity=".28" transform="rotate(9 208 71)"/>
<path d="M142 126q0-9 9-9h21m40 4q0-9 9-9h24M185 57l23 4" fill="none" stroke="#FFF4DC" stroke-opacity=".4"/>
</g><g fill="{accent}" fill-opacity=".25"><circle cx="160" cy="139" r="3"/><circle cx="177" cy="139" r="3"/>
<circle cx="231" cy="127" r="2.5"/><circle cx="247" cy="127" r="2.5"/><circle cx="231" cy="143" r="2.5"/><circle cx="247" cy="143" r="2.5"/>
<path d="m209 60 4 9 9 4-9 4-4 9-4-9-9-4 9-4Z"/></g>
<g fill="none" stroke="{gold}" stroke-opacity=".38" stroke-width="1.5" stroke-linecap="round"><circle cx="98" cy="97" r="18"/><path d="M98 69v-5m0 66v-5M70 97h-5m66 0h-5M78 77l-4-4m44 44 4 4m-44-4-4 4m44-44 4-4"/></g>
<path d="M296 163q-13-49 7-92m-4 46q-24-4-20-25 18 3 20 25m1 20q19-6 16-25-17 8-16 25" fill="{leaf}" fill-opacity=".4" stroke="{accent}" stroke-opacity=".2"/>
<circle cx="145" cy="65" r="2" fill="{gold}" fill-opacity=".5"/>''', 320, 200)
    svg(f'scene/compass_{theme}.svg', f'''<circle cx="30" cy="30" r="24" fill="{accent}" fill-opacity=".06"/>
<circle cx="30" cy="30" r="17" fill="none" stroke="{accent}" stroke-opacity=".22" stroke-dasharray="1 5" stroke-linecap="round"/>
<path d="m30 19 3.5 7.5L41 30l-7.5 3.5L30 41l-3.5-7.5L19 30l7.5-3.5Z" fill="{gold}" fill-opacity=".65"/>
<circle cx="30" cy="30" r="2.5" fill="{accent}" fill-opacity=".45"/>''', 60, 60)
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
