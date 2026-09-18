#!/usr/bin/env python3
"""Original vector courtyard, RPS squads and local synthesized feedback for Coop Arena."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'entry/src/main/resources/rawfile/gamesNext/coopArena'
for folder in ['factions', 'icons', 'scene', 'audio']:
    (ROOT / folder).mkdir(parents=True, exist_ok=True)

def svg(path, body, box='0 0 100 100'):
    (ROOT / path).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{box}">{body}</svg>\n')

paths = {
    'back':'M17 5 7 12l10 7M7 12h15',
    'pause':'M8 5v14M16 5v14',
    'play':'m9 5 10 7-10 7Z',
    'sound':'M4 9h4l5-4v14l-5-4H4ZM17 8q4 4 0 8M20 5q7 7 0 14',
    'mute':'M4 9h4l5-4v14l-5-4H4ZM17 9l5 6M22 9l-5 6',
    'help':'M9 8a3 3 0 1 1 5 2q-2 1-2 3M12 17h.01',
    'close':'m6 6 12 12M18 6 6 18',
    'restart':'M5 8a8 8 0 1 1-1 8M5 3v5h5',
    'gather':'M12 3v18M3 12h18M8 6l4-3 4 3M8 18l4 3 4-3M6 8l-3 4 3 4M18 8l3 4-3 4',
    'shield':'m12 3 8 3v6q0 6-8 10-8-4-8-10V6ZM8 12l3 3 5-6',
    'wind':'M3 8h13a3 3 0 1 0-3-3M3 12h17M3 16h11a3 3 0 1 1-3 3',
    'flag':'M6 21V3q4-2 7 0t7 0v10q-4 2-7 0t-7 0',
    'cup':'M8 3h8v7a4 4 0 0 1-8 0ZM8 5H4v3q0 4 5 4M16 5h4v3q0 4-5 4M12 14v6M8 21h8',
    'star':'m12 3 3 6 7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1Z',
    'expand':'M9 4H4v5M15 4h5v5M4 15v5h5M20 15v5h-5',
    'leaf':'M20 4C8 3 2 10 6 17s16 3 14-13ZM6 18 16 8',
    'tune':'M4 6h16M4 12h16M4 18h16M8 3v6M16 9v6M9 15v6',
    'save':'M5 3h12l4 4v14H3V3ZM7 3v6h9V3M7 21v-8h10v8',
    'eye':'M2 12q10-15 20 0-10 15-20 0ZM15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0',
    'home':'m3 11 9-8 9 8M6 9v12h12V9M10 21v-7h4v7'
}
for dark in [False, True]:
    theme = 'dark' if dark else 'light'
    ink = '#f9efd9' if dark else '#394637'
    for primary in [False, True]:
        color = ('#25351f' if dark else '#fff9e9') if primary else ink
        for name, path in paths.items():
            svg(f'icons/{name}_{"primary_" if primary else ""}{theme}.svg',
                f'<path d="{path}" fill="none" stroke="{color}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>','0 0 24 24')
    outline='#33434b'
    rock=f'<path d="M15 73 10 49 28 20 59 12 85 33 92 67 73 86 32 89Z" fill="#88adc1" stroke="{outline}" stroke-width="3.5" stroke-linejoin="round"/><path d="m28 20 8 22 24-7 25-2M36 42 18 64M60 35l15 29 17 3" fill="none" stroke="#bbd3df" stroke-width="4" stroke-linecap="round"/><path d="m26 74 12 7 23-3" fill="none" stroke="#65899d" stroke-width="3" stroke-linecap="round"/>'
    scissors='<path d="M43 51 29 14q-2-7 5-5l21 38M56 50 76 16q4-6 7 1L66 59" fill="#f1d6b1" stroke="#614a38" stroke-width="3.5" stroke-linejoin="round"/><path d="M47 58C45 31 4 44 15 70c7 19 33 12 32-12ZM55 59c5-27 41-11 29 12-11 20-34 7-29-12Z" fill="#e99775" stroke="#914e3b" stroke-width="3.5"/><path d="M35 55q-14-5-13 9t15 2M66 58q16-3 12 10t-16-3" fill="#fff0d7" stroke="#bd7156" stroke-width="3"/><circle cx="51" cy="50" r="7" fill="#eed4a3" stroke="#826541" stroke-width="3"/>'
    cloth='<path d="M17 20q29-6 61 1l9 57q-32 10-68 6L11 29Z" fill="#a4c994" stroke="#426348" stroke-width="3.5" stroke-linejoin="round"/><path d="m17 20 8 58q25 2 54-4M28 30q20-4 40 0" fill="none" stroke="#dbe4b5" stroke-width="3" stroke-linecap="round"/><path d="m60 81 24-18 3 15Z" fill="#779f70"/><path d="m30 34 4 33M39 32l4 36" stroke="#80ac7d" stroke-width="1.5" stroke-dasharray="3 4"/>'
    for f, body in enumerate([rock,scissors,cloth]):
        face = '' if f == 1 else '<g fill="#334434"><ellipse cx="43" cy="55" rx="2.3" ry="3"/><ellipse cx="63" cy="53" rx="2.3" ry="3"/></g><path d="M49 64q5 5 10-1" fill="none" stroke="#334434" stroke-width="2.5" stroke-linecap="round"/><g fill="#eab1a0" opacity=".7"><ellipse cx="35" cy="63" rx="5" ry="3"/><ellipse cx="71" cy="61" rx="5" ry="3"/></g>'
        svg(f'factions/{f}_{theme}.svg',body+face)
    bg='#101110' if dark else '#fff4e4'; wash='#252b21' if dark else '#eaf0d5'; clay='#383027' if dark else '#fae8ca'
    svg(f'scene/garden_{theme}.svg',f'<path fill="{bg}" d="M0 0h900v1200H0Z"/><path fill="{wash}" d="M0 180C230 170 200 520 0 650Z"/><path fill="{clay}" d="M900 50C600 200 650 490 900 660Z"/><path fill="{wash}" d="M20 1110C300 850 630 1040 880 1120Q490 1185 20 1110Z"/><g fill="none" stroke="{clay}" stroke-width="3"><circle cx="800" cy="960" r="9"/><circle cx="78" cy="880" r="5"/></g>','0 0 900 1200')
    ground='#272c22' if dark else '#eef0dc'; border='#6e6b4b' if dark else '#d8bd8b'; leaf='#5d7958' if dark else '#9dbc88'
    svg(f'scene/arena_{theme}.svg',f'<rect x="5" y="5" width="710" height="710" rx="40" fill="{ground}" stroke="{border}" stroke-width="7"/><rect x="20" y="20" width="680" height="680" rx="30" fill="none" stroke="{border}" stroke-opacity=".35" stroke-width="2"/><g stroke="{border}" stroke-width="5" stroke-linecap="round" opacity=".55"><path d="M65 14h100m390 0h90M65 706h100m390 0h90M14 65v100m0 390v90M706 65v100m0 390v90"/></g><g fill="{leaf}" opacity=".45"><ellipse cx="37" cy="45" rx="8" ry="15" transform="rotate(-30 37 45)"/><ellipse cx="685" cy="676" rx="7" ry="15" transform="rotate(35 685 676)"/></g>','0 0 720 720')
    svg(f'scene/bench_{theme}.svg',f'<path d="M20 83h160M34 84v8m131-8v8" stroke="{border}" stroke-width="7" stroke-linecap="round"/><path d="M30 82 26 57h28l-5 25" fill="{clay}"/><path d="M41 59V22M41 41Q15 35 21 16 45 24 41 41ZM42 50q29-9 26-26Q44 25 42 50Z" fill="{leaf}" stroke="{leaf}" stroke-width="3"/><g transform="translate(90 40) scale(.45)">{rock}</g>','0 0 200 100')
    svg(f'scene/unfold_{theme}.svg',f'<rect x="25" y="16" width="150" height="96" rx="14" fill="{ground}" stroke="{border}" stroke-width="4"/><path d="M100 18v92" stroke="{border}" stroke-width="2" stroke-dasharray="5 5"/><path d="m69 51-15 14 15 14m62-28 15 14-15 14M54 65h33m26 0h33" fill="none" stroke="{leaf}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>','0 0 200 128')
    svg(f'scene/mark_{theme}.svg',f'<rect width="100" height="100" rx="30" fill="{clay}"/><g transform="translate(3 2) scale(.54)">{rock}</g><g transform="translate(44 28) scale(.5)">{scissors}</g><g transform="translate(3 48) scale(.48)">{cloth}</g>')

effects={'tap':(.08,[740]),'turn':(.09,[560,700]),'skill':(.18,[440,660,880]),'zone':(.25,[523,659,784]),'warning':(.28,[440,440]),'win':(.5,[523,659,784,1047]),'finish':(.35,[523,440,330])}
rng=random.Random(720)
for name,(duration,notes) in effects.items():
    rate=22050; count=int(duration*rate); data=[]
    for i in range(count):
        t=i/rate; part=min(len(notes)-1,int(t/duration*len(notes))); frequency=notes[part]
        local=t-duration*part/len(notes); envelope=min(1,local/.008)*max(0,1-local/(duration/len(notes)))**1.6
        value=(math.sin(2*math.pi*frequency*t)+.16*math.sin(4*math.pi*frequency*t))*envelope*.38
        data.append(struct.pack('<h',int(max(-1,min(1,value))*32767)))
    with wave.open(str(ROOT/'audio'/f'{name}.wav'),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate);out.writeframes(b''.join(data))
print(f'Coop Arena: {len(list(ROOT.rglob("*.svg")))} SVG, {len(effects)} WAV')
