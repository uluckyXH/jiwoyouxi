#!/usr/bin/env python3
"""Original vector art and short, bounded PCM effects for 庭院寻双; no external assets."""
from pathlib import Path
from xml.etree import ElementTree as ET
import math
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'entry/src/main/resources/rawfile/gamesNext/memoryGarden'
BADGES = ROOT / 'entry/src/main/resources/rawfile/app/achievements'


def svg(path, body, w=96, h=96):
    target = DEST / path
    target.parent.mkdir(parents=True, exist_ok=True)
    text = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>\n'
    ET.fromstring(text)
    target.write_text(text)
    return text


def face(x=48, y=52, outline='#526347'):
    return f'<g fill="{outline}"><circle cx="{x-8}" cy="{y}" r="2"/><circle cx="{x+8}" cy="{y}" r="2"/></g><path d="M{x-3} {y+5}q3 4 6 0" fill="none" stroke="{outline}" stroke-width="1.5" stroke-linecap="round"/><g fill="#E9A596" opacity=".65"><ellipse cx="{x-15}" cy="{y+4}" rx="4" ry="2.5"/><ellipse cx="{x+15}" cy="{y+4}" rx="4" ry="2.5"/></g>'


def flower(x, y, size, color, center='#F4D185'):
    return ''.join(f'<ellipse cx="{x}" cy="{y-size*.56}" rx="{size*.37}" ry="{size*.57}" fill="{color}" transform="rotate({i*60} {x} {y})"/>' for i in range(6)) + f'<circle cx="{x}" cy="{y}" r="{size*.34}" fill="{center}"/>'


def picture(i, dark=False):
    line = '#A8C7A3' if dark else '#6D865B'
    pale = '#DFEDBF' if dark else '#DAE8BD'
    cream = '#F4DBA0'
    rose = '#EAB2AC'
    blue = '#B6D7DD'
    ink = '#55634B'
    s = f'<ellipse cx="48" cy="82" rx="27" ry="4" fill="{line}" opacity=".12"/><g stroke="{line}" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round">'
    if i == 0:
        s += f'<path d="M23 55Q18 34 33 27q0-10 8-6 7-11 11-2 9-7 11 5 18 9 12 34Q69 80 47 80 23 78 23 55Z" fill="{cream}"/><path d="M25 49q-12-1-10 9t13 5m45-14q12-1 9 10t-12 4M37 79v5m22-5v5" fill="{cream}"/><path d="m43 55 5 4 5-4-5-3Z" fill="#CF9758" stroke="none"/>'
        s += face(48, 46)
    elif i == 1:
        s += f'<path d="M48 75V45M48 66Q22 64 25 50q24-1 23 16m0 7q23-1 22-17-18-1-22 17" fill="{pale}"/>'
        s += flower(48, 32, 23, rose) + face(48, 30)
    elif i == 2:
        s += f'<path d="M47 46V19M47 40Q20 36 22 18q25-1 25 22m0-9q23-1 27-20-25-1-27 20" fill="{pale}"/><path d="m26 50 5 27q17 8 34 0l5-27Z" fill="#D9B291"/><rect x="23" y="44" width="50" height="12" rx="5" fill="#E8C7A6"/>' + face(48, 63)
    elif i == 3:
        s += f'<path d="M67 37q23-6 20 13-2 12-20 10" fill="none"/><path d="M20 32h51v26q-2 21-25 21T20 58Z" fill="{blue}"/><ellipse cx="45" cy="32" rx="25" ry="6" fill="#BCA480"/><path d="M14 79q33 11 65 0M35 20q-7-5 0-11m16 11q-7-5 0-11" fill="none"/>' + face(45, 50)
    elif i == 4:
        s += f'<path d="M48 8v13m0 42v15" fill="none"/><path d="M23 61q8-5 8-19 0-22 17-22t17 22q0 14 8 19Z" fill="{blue}"/><path d="m42 67 12 0-2 18-12-4Z" fill="{rose}"/><path d="M28 55h40" fill="none"/>' + face(48, 41)
    elif i == 5:
        s += f'<path d="M18 38Q18 20 48 26q30-7 30 12 0 24-30 44Q18 62 18 38Z" fill="{rose}"/><path d="M48 30 31 20l9 2 5-10 6 9 16-4-12 15Z" fill="{pale}"/>'
        s += ''.join(f'<path d="M{x} {y}v2" stroke="#FFF4CE"/>' for x, y in [(29, 42), (66, 43), (35, 65), (60, 64), (48, 72)]) + face(48, 47)
    elif i == 6:
        s += f'<path d="M43 36Q15 13 23 9q20-9 25 25Q57 1 72 14q9 10-20 23" fill="{blue}"/><ellipse cx="48" cy="54" rx="29" ry="22" fill="{cream}"/><path d="M39 35v38m17-38v38" stroke="#B19357" stroke-width="6"/><path d="M24 39 17 31m10 6-1-10m51 25 8 3-8 4" fill="none"/>' + face(47, 50)
    elif i == 7:
        s += f'<path d="M36 48h23l5 31q-15 8-33 0Z" fill="#F6E6C6"/><path d="M11 48Q23 13 47 14q24-1 38 34Q48 64 11 48Z" fill="{rose}"/>'
        s += '<g fill="#FFF0DA" stroke="none"><circle cx="34" cy="30" r="6"/><circle cx="58" cy="26" r="5"/><circle cx="67" cy="43" r="5"/><circle cx="23" cy="44" r="4"/></g>' + face(48, 68)
    elif i == 8:
        s += f'<path d="M26 74Q4 26 74 14q17 53-48 60Z" fill="{pale}"/><path d="M18 84 65 28m-27 39-13-8m24-5 14 1m-16-7-10-9" fill="none"/>'
    elif i == 9:
        s += f'<path d="M29 45q-8-38 21-28 18 7 16 23" fill="none" stroke-width="7"/><path d="M61 44 79 26l9 9-18 29M24 40h44v36q-20 10-44 0Z" fill="{blue}"/><path d="m75 24 16 15m-57-6h24" fill="none"/>' + face(46, 57)
    elif i == 10:
        s += f'<path d="M23 65Q3 66 10 46q4-9 16-8 0-23 22-24 22 0 25 27 22-2 15 16-3 9-16 8Z" fill="#DEE7E9"/><path d="m29 76-4 8m21-8-4 8m21-8-4 8" stroke="#97BCCD"/>' + face(47, 48)
    elif i == 11:
        s += f'<path d="M45 44Q13 6 13 34q-2 20 21 20-24 22-5 28 21 4 17-28m5-10Q82 6 83 34q2 20-21 20 24 22 5 28-21 4-17-28" fill="#D4BFE4"/><path d="M48 36v38m0-33-7-18m7 18 7-18" stroke-width="4"/>'
        s += '<g stroke="none" fill="#F4D7A1"><circle cx="26" cy="40" r="7"/><circle cx="70" cy="40" r="7"/></g>'
    elif i == 12:
        s += f'<path d="M65 37q24-8 23 13-1 18-20 10M25 44 10 29l-6 10 20 24" fill="none" stroke-width="8"/><path d="M25 37q-13 36 18 43 35 6 30-26l-7-18Z" fill="{rose}"/><path d="M24 36q23-18 46 0Z" fill="#E6C9B3"/><circle cx="46" cy="20" r="5" fill="#E6C9B3"/>' + face(48, 53)
    elif i == 13:
        s += f'<path d="M49 29Q26 13 15 39 4 65 43 82q37-7 40-33 0-29-34-20Z" fill="{rose}"/><path d="M49 29q13-23 29-13-10 21-29 13Zm0-1q2 24-8 47" fill="{pale}"/>'
    elif i == 14:
        s += f'<path d="M60 12Q17 5 15 48q0 32 33 34 27 0 35-27Q37 64 60 12Z" fill="{cream}"/><path d="m76 17 3 7 8 2-6 5 1 8-7-4-6 4 1-8-5-5 8-2Z" fill="{blue}"/>' + face(37, 53)
    else:
        s += f'<path d="M25 44h46q0 30-23 41-23-11-23-41Z" fill="#E3BA8C"/><path d="M48 23q-1-16 10-15" fill="none"/><path d="M20 44q1-24 28-24t29 24Z" fill="#ACB67D"/><path d="m29 32 7 8m2-13 10 13m0-15 10 13m0-11 9 10" stroke="#7F915F"/>' + face(48, 56)
    return s + '</g>'


ICONS = {
 'back': 'M19 12H5m7-7-7 7 7 7', 'sound': 'M4 9h4l5-4v14l-5-4H4Zm12-1q4 4 0 8m3-11q7 7 0 14',
 'muted': 'M4 9h4l5-4v14l-5-4H4Zm13 0 5 6m0-6-5 6', 'pause': 'M8 5v14m8-14v14',
 'play': 'm8 5 11 7-11 7Z', 'help': 'M9 9a3 3 0 0 1 6 0c0 2-3 2-3 5m0 3v.1M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0',
 'close': 'm6 6 12 12M6 18 18 6', 'check': 'm5 12 4 4L19 6', 'restart': 'M4 10a8 8 0 1 1 1 8M4 4v6h6',
 'spark': 'M12 2q2 8 10 10-8 2-10 10Q10 14 2 12 10 10 12 2Z',
 'trophy': 'M7 3h10v7a5 5 0 0 1-10 0Zm0 2H3v4q0 4 5 4m9-8h4v4q0 4-5 4m-4 2v5m-5 1h10',
 'cards': 'M9 3h11v15H9ZM5 6H3v15h12v-1M12 7h5m-5 4h5',
 'pair': 'M3 5h8v14H3Zm10 0h8v14h-8ZM6 12h2m8 0h2',
 'flower': 'M12 8q-8-9-9-1-1 4 5 5-10 3-4 8 4 3 8-4 3 10 8 4 3-4-4-8 10-3 4-8-4-3-8 4ZM15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0',
 'next': 'M4 12h15m-6-6 6 6-6 6', 'leaf': 'M5 19Q1 3 21 3q0 18-16 16Zm-2 3L17 7'
}
for dark in [False, True]:
    theme = 'dark' if dark else 'light'
    bg = '#171E1C' if dark else '#FFF4E4'
    paper = '#29332E' if dark else '#FFFCF3'
    line = '#4B6152' if dark else '#D4E1C6'
    leaf = '#738D75' if dark else '#C6D4A5'
    peach = '#877055' if dark else '#EBC8A3'
    accent = '#AAD8B4' if dark else '#28745D'
    ink = '#F6ECD8' if dark else '#324C40'
    for i in range(16):
        svg(f'cards/{i}_{theme}.svg', picture(i, dark))
    for name, path in ICONS.items():
        for tone, color in [('ink', ink), ('accent', accent), ('on', '#183D30' if dark else '#FFFBEF')]:
            svg(f'icons/{name}_{tone}_{theme}.svg', f'<path d="{path}" fill="none" stroke="{color}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>', 24, 24)
    svg(f'scene/back_{theme}.svg', f'''<defs><linearGradient id="cloth" x2="0" y2="1"><stop stop-color="{'#415D4B' if dark else '#B9D2B2'}"/><stop offset="1" stop-color="{'#314B3C' if dark else '#D8E4BF'}"/></linearGradient></defs><rect x="2" y="2" width="92" height="104" rx="17" fill="url(#cloth)" stroke="{line}" stroke-width="2"/><rect x="8" y="8" width="80" height="92" rx="12" fill="none" stroke="{paper}" stroke-opacity=".55" stroke-dasharray="3 5"/><path d="M18 22h60M18 86h60M23 16v76m50-76v76" stroke="{paper}" stroke-opacity=".15"/><path d="M48 26 69 54 48 82 27 54Z" fill="{paper}" opacity=".16"/><path d="M48 66V41m0 13Q32 55 33 42q15-2 15 12Zm0-4q0-16 16-16 1 15-16 16Z" fill="none" stroke="{paper}" stroke-width="2.5" stroke-linecap="round"/><circle cx="48" cy="21" r="2" fill="{paper}" opacity=".7"/><circle cx="48" cy="88" r="2" fill="{paper}" opacity=".7"/>''',96,108)
    svg(f'scene/atmosphere_{theme}.svg', f'''<defs><radialGradient id="glow"><stop stop-color="{peach}" stop-opacity=".28"/><stop offset="1" stop-color="{bg}" stop-opacity="0"/></radialGradient><linearGradient id="ground" x2="0" y2="1"><stop stop-color="{leaf}" stop-opacity="0"/><stop offset=".6" stop-color="{leaf}" stop-opacity=".16"/><stop offset="1" stop-color="{bg}" stop-opacity="0"/></linearGradient></defs><ellipse cx="840" cy="310" rx="740" ry="430" fill="url(#glow)"/><path d="M0 780Q350 640 660 790T1200 720V1200H0Z" fill="url(#ground)"/><g fill="none" stroke="{leaf}" stroke-opacity=".13"><path d="M0 880Q320 740 730 900T1200 850M0 897Q320 757 730 917T1200 867"/></g>''',1200,1200)
    svg(f'scene/canopy_{theme}.svg', f'''<g fill="none" stroke="{leaf}" stroke-width="2" opacity=".35"><path d="M50-20Q200 160 380 40M70-20Q200 120 380 20M82-20Q270 70 380-10"/><path d="M95 22q-27 1-24-28 24 2 24 28m52 46q-4-25 22-28 8 20-22 28m55 5q-14 27 12 34 20-25-12-34" fill="{leaf}"/></g><g transform="translate(218 78) scale(.75)" opacity=".36">{picture(4,dark)}</g><path d="m109 156 4 11 11 4-11 4-4 11-4-11-11-4 11-4Z" fill="{peach}" opacity=".55"/>''',380,270)
    svg(f'scene/garden_{theme}.svg', f'''<g stroke="{leaf}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="{leaf}" fill-opacity=".27"><path d="M35 238Q30 135 112 29M55 143Q2 106 13 69q48 9 42 74Zm20-43Q46 27 86 10q21 49-11 90Zm-20 43q59-5 88-43-64-6-88 43Zm-20 59q-7-65-34-59-6 27 34 59Z"/><path d="M30 224q87-20 101-68-76-1-101 68Z"/></g>{flower(162,192,13,peach)}<g transform="translate(158 211) scale(.44)" opacity=".7">{picture(7,dark)}</g>''',250,270)
    svg(f'scene/stilllife_{theme}.svg', f'''<g fill="none" stroke="{peach}" stroke-width="2" opacity=".45"><path d="M12 173q150-30 294 0M27 181q130-22 265 0"/></g><g transform="translate(177 78) scale(.87)" opacity=".62">{picture(2,dark)}</g><g transform="translate(92 101) scale(.82)" opacity=".62">{picture(3,dark)}</g><g transform="translate(2 72) scale(.86)" opacity=".62">{picture(0,dark)}</g>''',320,205)
    svg(f'scene/mascot_{theme}.svg', f'<ellipse cx="92" cy="119" rx="67" ry="8" fill="{leaf}" opacity=".14"/><g transform="translate(9 15) scale(1.1)">{picture(0,dark)}</g><g transform="translate(88 44) scale(.75)">{picture(3,dark)}</g>'+flower(137,26,12,peach),170,140)
    svg(f'scene/edge_fade_{theme}.svg', f'<defs><linearGradient id="edge" x2="0" y2="1"><stop stop-color="{bg}"/><stop offset=".1" stop-color="{bg}" stop-opacity="0"/><stop offset=".85" stop-color="{bg}" stop-opacity="0"/><stop offset="1" stop-color="{bg}"/></linearGradient></defs><rect width="100" height="100" fill="url(#edge)"/>',100,100)

logo = '<rect x="4" y="4" width="120" height="120" rx="31" fill="#F1D7A4" stroke="#CCB68E" stroke-width="2"/><g transform="rotate(-9 45 66)"><rect x="15" y="24" width="56" height="76" rx="12" fill="#B8CEAA" stroke="#73906C" stroke-width="2"/><path d="M25 36h35v50H25Z" fill="none" stroke="#EFF1D5" stroke-dasharray="3 3"/></g><g transform="rotate(8 83 65)"><rect x="55" y="23" width="57" height="78" rx="12" fill="#FFFAEA" stroke="#A5B789" stroke-width="2"/><g transform="translate(56 35) scale(.58)">'+picture(0)+'</g></g><path d="m108 91 3 7 8 3-8 3-3 8-3-8-7-3 7-3Z" fill="#D99873"/>'
svg('scene/logo.svg',logo,128,128)
# Balance the pair around x=64, including wings and shadows, inside the stitched ring.
first_pair = (
    '<g transform="translate(12 29) scale(.62)">' + picture(0) + '</g>'
    '<g transform="translate(56 29) scale(.62)">' + picture(0) + '</g>'
    '<path d="M64 100C59 96 54 93 56 89c2-4 6-4 8 0 2-4 6-4 8 0 2 4-3 7-8 11Z" '
    'fill="#E6B6A1" stroke="#C88F79" stroke-width="1.2" stroke-linejoin="round"/>'
)
for name, art in [('first_pair', first_pair),('first_table', '<g transform="translate(18 11) scale(.94)">'+picture(1)+'</g><path d="m79 94 12 11 24-27" fill="none" stroke="#4D8665" stroke-width="6" stroke-linecap="round"/>'),('collector', '<g transform="translate(22 7) scale(.94)">'+picture(4)+'</g><path d="m42 107 22-13 23 13" fill="none" stroke="#CF9C65" stroke-width="4"/>')]:
    body = '<circle cx="64" cy="64" r="59" fill="#F7E8C6" stroke="#D8B77D" stroke-width="3"/><circle cx="64" cy="64" r="50" fill="#FFFAE9" stroke="#D7DDB8" stroke-width="1.5" stroke-dasharray="3 5"/>' + art
    target=BADGES/f'ach_memory_{name}.svg'
    target.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">{body}</svg>\n')
    ET.parse(target)

# Gentle marimba/paper-like tones, bounded peak, no runtime synthesis or loops.
sounds = {'flip': (.13,[740]), 'match': (.32,[659,880]), 'combo': (.42,[659,880,1109]),
          'miss': (.19,[330,294]), 'deal': (.30,[392,523,659]), 'complete': (.76,[523,659,784,1046]), 'tap': (.10,[600])}
for name,(duration,notes) in sounds.items():
    rate=24000
    samples=[]
    for i in range(int(rate*duration)):
        t=i/rate
        value=0.0
        for j,freq in enumerate(notes):
            start=j*duration*.45/max(1,len(notes)-1)
            age=t-start
            if age>=0:
                env=min(1,age/.008)*math.exp(-age/(.055 if name=='flip' else .13))
                value+=(math.sin(2*math.pi*freq*age)+.22*math.sin(2*math.pi*freq*2.01*age))*env
        # Finish at silence instead of cutting a ringing note at a nonzero sample.
        samples.append(value * min(1.0, (duration-t)/.025))
    peak=max(abs(v) for v in samples)
    ceiling=.34 if name=='miss' else .63
    path=DEST/'audio'/f'{name}.wav'
    path.parent.mkdir(parents=True,exist_ok=True)
    with wave.open(str(path),'wb') as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(rate)
        out.writeframes(b''.join(struct.pack('<h',round(v/peak*ceiling*32767)) for v in samples))
print('Memory Garden:',len(list(DEST.rglob('*.svg'))),'SVG,',len(sounds),'PCM effects, 3 badges')
