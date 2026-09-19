#!/usr/bin/env python3
"""Draw Bloom Lines' own SVG scene, patterned beads, controls and medals; synthesize short PCM effects."""
from pathlib import Path
from xml.etree import ElementTree as ET
import math
import struct
import wave

PROJECT = Path(__file__).resolve().parents[1]
DEST = PROJECT / 'entry/src/main/resources/rawfile/gamesNext/bloomLines'
BADGES = PROJECT / 'entry/src/main/resources/rawfile/app/achievements'


def svg(name, body, width=128, height=128, title=''):
    target = DEST / name
    target.parent.mkdir(parents=True, exist_ok=True)
    content = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
               f'viewBox="0 0 {width} {height}"><title>{title}</title>{body}</svg>\n')
    ET.fromstring(content)
    target.write_text(content)
    return content


def flower(x, y, radius, color, center='#F9DA89'):
    return ''.join(
        f'<ellipse cx="{x}" cy="{y-radius*.65}" rx="{radius*.38}" ry="{radius*.60}" fill="{color}" '
        f'transform="rotate({i*72} {x} {y})"/>' for i in range(5)
    ) + f'<circle cx="{x}" cy="{y}" r="{radius*.33}" fill="{center}"/>'


def chick(x, y, scale=1):
    return f'''<g transform="translate({x} {y}) scale({scale})" stroke="#9F8149" stroke-width="2" stroke-linecap="round">
<path d="M-27 11Q-35-18-15-29Q-13-39-4-34Q3-43 10-33Q32-24 30 5Q28 31 0 31Q-24 31-27 11Z" fill="#F2D58B"/>
<path d="M-26 1q-10 3-6 13m59-13q10 3 6 13" fill="#F4DA99"/>
<path d="M-13 29l-1 7m24-7 1 7" fill="none"/>
<circle cx="-10" cy="-3" r="2.5" fill="#555039" stroke="none"/><circle cx="11" cy="-3" r="2.5" fill="#555039" stroke="none"/>
<path d="m-4 5 5 4 5-4-5-2Z" fill="#D69555" stroke="none"/>
<ellipse cx="-19" cy="6" rx="5" ry="3" fill="#EAB19C" stroke="none"/><ellipse cx="20" cy="6" rx="5" ry="3" fill="#EAB19C" stroke="none"/>
</g>'''


LIGHT = [
    ('#FFE6A0', '#E9BB67', '#AA8043'), ('#D5EAC0', '#9EC48D', '#628353'),
    ('#FFD5CD', '#ECA799', '#B57069'), ('#CCE9F3', '#91C4D8', '#5C8EAA'),
    ('#E5D8F5', '#BCA6D8', '#8A71AF'), ('#FFE0B9', '#EBB181', '#AE7B51'),
    ('#CBECE1', '#8DC9B3', '#568E7B')
]
DARK = [
    ('#E8C885', '#B7954F', '#E9D5A0'), ('#ACC898', '#67835D', '#C6DEB4'),
    ('#E5B1AB', '#A56E6D', '#F2CEBE'), ('#A3CCDC', '#5D869C', '#C4E3EC'),
    ('#C6B5DB', '#857498', '#E0CFEF'), ('#E4BB97', '#A47D57', '#EED1AF'),
    ('#A2D1C1', '#5E8E7E', '#C4E8D9')
]
NAMES = ['金色小鸡', '绿色叶片', '粉色花朵', '蓝色水滴', '紫色星星', '橙色蝴蝶', '青色爱心']


def bead(color, dark=False, uid='bead'):
    light, shade, outline = (DARK if dark else LIGHT)[color]
    white = '#FFF9E9'
    body = f'''<defs><linearGradient id="{uid}" x1="0" y1="0" x2="1" y2="1"><stop stop-color="{light}"/>
<stop offset="1" stop-color="{shade}"/></linearGradient></defs>
<ellipse cx="48" cy="82" rx="34" ry="7" fill="#1A3325" opacity=".12"/>
<circle cx="48" cy="46" r="39" fill="url(#{uid})" stroke="{outline}" stroke-width="2"/>
<path d="M19 38Q24 17 46 16" fill="none" stroke="{white}" stroke-opacity=".57" stroke-width="4.5" stroke-linecap="round"/>
<path d="M72 61q-6 12-20 13" fill="none" stroke="{outline}" stroke-opacity=".38" stroke-width="2.5" stroke-linecap="round"/>'''
    if color == 0:
        body += f'''<path d="M43 25q-7-9-10-3m10 3q-1-11 6-9" fill="none" stroke="{outline}" stroke-width="2.4" stroke-linecap="round"/>
<circle cx="35" cy="43" r="3" fill="#584E36"/><circle cx="59" cy="43" r="3" fill="#584E36"/>
<path d="m42 51 6-3 6 3-6 6Z" fill="#BB7E39"/><ellipse cx="27" cy="53" rx="5" ry="3" fill="#EA9F85"/>
<ellipse cx="68" cy="53" rx="5" ry="3" fill="#EA9F85"/>'''
    elif color == 1:
        body += f'<path d="M33 61Q27 31 65 28Q66 60 33 61Z" fill="{white}" opacity=".88"/><path d="M31 65 57 37m-12 13-9-3m16-4 1-8" fill="none" stroke="{outline}" stroke-width="2.8" stroke-linecap="round"/>'
    elif color == 2:
        body += flower(48, 47, 23, white, '#D58E70')
        body += '<circle cx="46" cy="46" r="1.7" fill="#795642"/><circle cx="51" cy="46" r="1.7" fill="#795642"/>'
    elif color == 3:
        body += f'<path d="M48 23C43 34 31 42 32 52C32 72 65 72 65 52C65 42 53 33 48 23Z" fill="{white}" opacity=".9"/><path d="M39 51q-1 10 8 11" fill="none" stroke="{outline}" stroke-width="2.7" stroke-linecap="round"/>'
    elif color == 4:
        body += f'<path d="m48 24 7 14 16 3-11 12 2 16-14-7-14 7 2-16-11-12 16-3Z" fill="{white}" stroke="{outline}" stroke-width="1.5" stroke-linejoin="round"/>'
    elif color == 5:
        body += f'<path d="M47 46C24 10 18 48 37 50C20 71 49 77 48 51C49 77 77 71 61 50C81 48 72 10 49 46Z" fill="{white}" opacity=".92"/><path d="M48 41v18m0-17-6-10m6 10 6-10" fill="none" stroke="{outline}" stroke-width="2.5" stroke-linecap="round"/>'
    else:
        body += f'<path d="M48 66C40 60 26 52 28 40C30 28 43 29 48 37C54 28 67 28 69 40C71 51 57 61 48 66Z" fill="{white}" opacity=".92"/>'
    return body


ICONS = {
    'back': 'M19 12H5m7-7-7 7 7 7',
    'sound': 'M4 9h4l5-4v14l-5-4H4Zm12-1q4 4 0 8m3-11q7 7 0 14',
    'muted': 'M4 9h4l5-4v14l-5-4H4Zm13 0 5 6m0-6-5 6',
    'pause': 'M8 5v14m8-14v14',
    'play': 'm8 5 11 7-11 7Z',
    'help': 'M9 9a3 3 0 0 1 6 0c0 2-3 2-3 5m0 3v.1M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0',
    'close': 'm6 6 12 12M6 18 18 6',
    'check': 'm5 12 4 4L19 6',
    'restart': 'M4 10a8 8 0 1 1 1 8M4 4v6h6',
    'undo': 'M9 5 3 11l6 6M3 11h11a6 6 0 0 1 0 12',
    'spark': 'M12 2q2 8 10 10-8 2-10 10Q10 14 2 12 10 10 12 2Z',
    'trophy': 'M7 3h10v7a5 5 0 0 1-10 0Zm0 2H3v4q0 4 5 4m9-8h4v4q0 4-5 4m-4 2v5m-5 1h10',
    'leaf': 'M5 19Q1 3 21 3q0 18-16 16Zm-2 3L17 7',
    'path': 'M4 20h8v-8h7V4m-4 4 4-4 4 4',
    'seed': 'M12 22V11M12 13Q1 13 3 3q11-1 9 10Zm0-4q0-9 10-8 1 10-10 8',
    'flower': 'M12 8q-8-9-9-1-1 4 5 5-10 3-4 8 4 3 8-4 3 10 8 4 3-4-4-8 10-3 4-8-4-3-8 4ZM15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0',
    'steps': 'M4 3h5v6H4Zm11 12h5v6h-5ZM4 15v6h5m-5 0 5-6M20 9V3h-5m5 0-5 6',
    'basket': 'M3 10h18l-3 11H6Zm4 0 5-8 5 8M9 13v5m6-5v5'
}


for dark in [False, True]:
    theme = 'dark' if dark else 'light'
    bg = '#181B19' if dark else '#FFF4E4'
    ink = '#F8EEDB' if dark else '#3D4938'
    accent = '#BCD49C' if dark else '#4D7048'
    on = '#253A29' if dark else '#FFFCEC'
    leaf = '#728469' if dark else '#CFDCA9'
    gold = '#D9B67B' if dark else '#E7BD7D'
    pink = '#B27D79' if dark else '#EAB6A5'
    for color in range(7):
        svg(f'beads/{color}_{theme}.svg', bead(color, dark), 96, 96, NAMES[color])
    for name, path in ICONS.items():
        for tone, color in [('ink', ink), ('accent', accent), ('on', on)]:
            svg(f'icons/{name}_{tone}_{theme}.svg',
                f'<path d="{path}" fill="none" stroke="{color}" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>',
                24, 24, name)
    slot = '#354034' if dark else '#F0EEDC'
    line = '#465341' if dark else '#E1E5CB'
    svg(f'scene/slot_{theme}.svg', f'''<rect x="1" y="1" width="62" height="62" rx="17" fill="{slot}" stroke="{line}" stroke-width="1.2"/>
<path d="M9 20q0-11 11-11h10" fill="none" stroke="{ink}" stroke-opacity=".07" stroke-width="2" stroke-linecap="round"/>
<circle cx="32" cy="32" r="2.1" fill="{accent}" opacity=".11"/>''', 64, 64)
    svg(f'scene/burst_{theme}.svg', ''.join(
        f'<ellipse cx="48" cy="11" rx="3.5" ry="7" fill="{pink if i%2 else gold}" transform="rotate({i*45} 48 48)"/>'
        for i in range(8)
    ) + f'<circle cx="48" cy="48" r="29" fill="none" stroke="{gold}" stroke-opacity=".35"/>', 96, 96)
    svg(f'scene/atmosphere_{theme}.svg', f'''<defs>
<radialGradient id="warm"><stop stop-color="{pink}" stop-opacity=".14"/><stop offset="1" stop-color="{bg}" stop-opacity="0"/></radialGradient>
<radialGradient id="green"><stop stop-color="{leaf}" stop-opacity=".25"/><stop offset="1" stop-color="{bg}" stop-opacity="0"/></radialGradient></defs>
<ellipse cx="660" cy="120" rx="460" ry="380" fill="url(#warm)"/><ellipse cx="80" cy="850" rx="620" ry="390" fill="url(#green)"/>
<g fill="none" stroke="{accent}" stroke-opacity=".07" stroke-width="1.4">
<path d="M-70 800Q230 690 400 830T950 820M-70 817Q230 707 400 847T950 837"/>
<path d="M30 182Q143 202 121 312T182 423" stroke-dasharray="2 11" stroke-linecap="round"/></g>
<g fill="{gold}" opacity=".42"><circle cx="61" cy="390" r="2.5"/><circle cx="712" cy="640" r="2.2"/><circle cx="740" cy="310" r="2.8"/></g>
{flower(745, 766, 12, pink)}{flower(70, 632, 8, leaf)}''', 800, 1000)
    svg(f'scene/window_{theme}.svg', f'''<g stroke="{accent}" stroke-opacity=".24" stroke-width="2" fill="none">
<path d="M80 277V117a103 103 0 0 1 206 0v160Z" fill="{gold}" fill-opacity=".065"/>
<path d="M91 266V117a92 92 0 0 1 184 0v149ZM183 24v242M91 148h184"/>
<path d="M99 87q20-28 43-12 19-36 41-15 22-21 41 15 23-16 43 12" stroke="{pink}" stroke-opacity=".5"/>
<path d="M70 279h228m-213 7h198"/></g>
<g opacity=".42">{flower(237, 110, 15, pink)}{flower(126, 205, 12, leaf)}</g>
<path d="M119 267q-20-37 10-48 28 11 7 48m71 0q-16-36 15-47 27 12 9 47" fill="{leaf}" fill-opacity=".2" stroke="{accent}" stroke-opacity=".18"/>
<path d="M54 15v87" stroke="{accent}" stroke-opacity=".22" stroke-width="1.5"/>
<circle cx="54" cy="109" r="11" fill="{pink}" fill-opacity=".28"/>
<circle cx="54" cy="142" r="13" fill="{gold}" fill-opacity=".3"/>
<path d="M54 120v9m0 26v16" stroke="{accent}" stroke-opacity=".25"/>
<path d="M88 290 24 430h274l-16-140Z" fill="{gold}" fill-opacity=".035"/>''', 320, 440)
    svg(f'scene/garden_{theme}.svg', f'''<g opacity="{'.30' if dark else '.58'}" stroke="{accent}" stroke-width="1.5" stroke-opacity=".45">
<path d="M65 273Q57 189 120 91M69 240q-64-31-49-92 58 10 53 77m1-11q5-79 68-88-3 62-68 88" fill="{leaf}" fill-opacity=".65"/>
<path d="M68 250q-7-71 4-130" fill="none"/>
<path d="M51 243h57l-7 38H58Z" fill="{pink}" fill-opacity=".6"/>
</g><g opacity=".65">{flower(76, 112, 18, pink)}{flower(123, 80, 15, gold)}{flower(157, 184, 13, pink)}</g>
<path d="M146 261q28-41 47-11" fill="none" stroke="{accent}" stroke-opacity=".24" stroke-width="1.4" stroke-dasharray="2 5"/>''', 240, 300)
    svg(f'scene/stilllife_{theme}.svg', f'''<ellipse cx="179" cy="180" rx="122" ry="13" fill="{leaf}" opacity=".13"/>
<g opacity="{'.34' if dark else '.58'}">{chick(205, 126, 1.25)}
<path d="M54 153h76l-9 27H63Z" fill="{leaf}" stroke="{accent}" stroke-opacity=".4" stroke-width="1.5"/>
<circle cx="76" cy="145" r="13" fill="{pink}"/><circle cx="102" cy="141" r="15" fill="{gold}"/>
<path d="M47 154h91" stroke="{accent}" stroke-width="2" stroke-opacity=".35"/></g>
<g opacity=".4">{flower(283, 155, 15, pink)}</g>''', 320, 210)
    svg(f'scene/mascot_{theme}.svg', f'<ellipse cx="63" cy="110" rx="42" ry="9" fill="{leaf}" opacity=".22"/>{chick(64, 70, 1.15)}{flower(23, 32, 10, pink)}', 128, 128, '陪你排彩珠的小鸡')
    svg(f'scene/edge_fade_{theme}.svg', f'''<defs><linearGradient id="edge" x1="0" y1="0" x2="0" y2="1">
<stop stop-color="{bg}"/><stop offset=".05" stop-color="{bg}" stop-opacity=".5"/><stop offset=".13" stop-color="{bg}" stop-opacity="0"/>
<stop offset=".86" stop-color="{bg}" stop-opacity="0"/><stop offset=".95" stop-color="{bg}" stop-opacity=".5"/><stop offset="1" stop-color="{bg}"/></linearGradient></defs>
<rect width="800" height="1000" fill="url(#edge)"/>''', 800, 1000)

logo = '''<rect x="7" y="9" width="114" height="110" rx="33" fill="#EBD09B" stroke="#B9AF7D" stroke-width="2"/>
<rect x="15" y="16" width="98" height="95" rx="26" fill="#FFF5D9"/>
<path d="M29 100V54a35 35 0 0 1 70 0v46M64 22v79M30 64h68" fill="none" stroke="#C9D6AB" stroke-width="3"/>'''
for i, (x, y, scale) in enumerate([(35, 6, .58), (5, 48, .44), (42, 57, .44), (80, 48, .44)]):
    logo += f'<g transform="translate({x} {y}) scale({scale})">{bead(i, uid=f"logo{i}")}</g>'
logo += flower(101, 27, 12, '#EAAE9F')
svg('scene/logo.svg', logo, title='五子连珠 · 花窗连珠')

def medal(name, title, body):
    content = f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<title>{title}</title><path d="M36 90 25 120l22-8 13 8 9-30M72 90l8 30 14-9 19 7-18-30" fill="#C5D6AE" stroke="#789265" stroke-width="2"/>
<circle cx="64" cy="61" r="51" fill="#FFF2D9" stroke="#CDA66A" stroke-width="3"/>
<circle cx="64" cy="61" r="44" fill="none" stroke="#E7D5AA" stroke-width="1.5"/>{body}</svg>\n'''
    ET.fromstring(content)
    BADGES.mkdir(parents=True, exist_ok=True)
    (BADGES / name).write_text(content)

body = flower(64, 61, 20, '#ECAE9F', '#ECC677')
for i in range(5):
    angle = (i*72-90)*math.pi/180
    x, y = 64 + 31*math.cos(angle)-11, 61+31*math.sin(angle)-11
    body += f'<g transform="translate({x:.2f} {y:.2f}) scale(.24)">{bead(i, uid=f"first{i}")}</g>'
medal('ach_bloom_first_flower.svg', '第一朵花', body)
body = '''<path d="M32 92V45a32 32 0 0 1 64 0v47Z" fill="#DBE6C5" stroke="#91A378" stroke-width="2"/>
<path d="M64 17v75M32 57h64" fill="none" stroke="#A1B58A" stroke-width="2"/>
<rect x="39" y="41" width="50" height="39" rx="12" fill="#FFF5DE"/>
<g fill="none" stroke="#7C6446" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round">
<path d="M46 50q14-6 14 3 0 7-9 7 12 0 9 9-5 5-14 0M74 47q-9 0-9 14t9 14q9 0 9-14t-9-14Z"/></g>'''
body += flower(34, 87, 13, '#E8AC9C') + flower(67, 91, 10, '#D8BBDC') + flower(97, 84, 12, '#EBC987')
medal('ach_bloom_score_30.svg', '花窗渐满', body)
body = '<path d="M35 65q0-35 29-35t29 35" fill="none" stroke="#B8955F" stroke-width="5"/>'
for i, (x, y) in enumerate([(29, 40), (52, 31), (75, 40), (41, 57), (67, 56)]):
    body += f'<g transform="translate({x} {y}) scale(.30)">{bead(i, uid=f"basket{i}")}</g>'
body += '''<path d="M24 72h80l-9 29q-30 10-62 0Z" fill="#DBBB80" stroke="#A58757" stroke-width="2.5"/>
<path d="M30 81h69M33 91h63M41 76l3 27m19-27v28m20-28-3 27" fill="none" stroke="#B59965" stroke-width="2"/>
<path d="M24 72h80" stroke="#F0D79B" stroke-width="5" stroke-linecap="round"/>'''
medal('ach_bloom_collector.svg', '彩珠收藏家', body)

SOUNDS = {
    'tap': (.085, [784]), 'travel': (.15, [523, 659]), 'spawn': (.16, [659, 784]),
    'clear': (.44, [523, 659, 784, 1046]), 'blocked': (.10, [294]),
    'undo': (.17, [784, 587]), 'end': (.58, [659, 523, 392])
}
rate = 24000
(DEST / 'audio').mkdir(exist_ok=True)
for name, (duration, notes) in SOUNDS.items():
    samples = []
    for n in range(int(duration * rate)):
        t = n / rate
        sample = 0
        for i, frequency in enumerate(notes):
            age = t - i * duration * .16
            if age >= 0:
                env = min(1, age / .006) * math.exp(-age / (duration * .26))
                sample += (math.sin(2*math.pi*frequency*age) + .13*math.sin(4*math.pi*frequency*age)) * env
        samples.append(sample * min(1, (duration-t)/.018))
    peak = max(abs(s) for s in samples) or 1
    gain = (.38 if name == 'blocked' else .62) / peak
    with wave.open(str(DEST / f'audio/{name}.wav'), 'wb') as out:
        out.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        out.writeframes(b''.join(struct.pack('<h', round(s*gain*32767)) for s in samples))

for file in DEST.rglob('*.svg'):
    ET.parse(file)
print(f'Bloom Lines: {len(list(DEST.rglob("*.svg")))} SVG assets, 7 PCM effects and 3 achievement medals.')
