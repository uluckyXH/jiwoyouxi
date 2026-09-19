#!/usr/bin/env python3
"""Draw only Ten Garden's vectors/badges and generate its bounded, original PCM sounds."""
from pathlib import Path
from xml.etree import ElementTree as ET
import math
import struct
import wave
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'entry/src/main/resources/rawfile/gamesNext/tenGarden'
BADGES=ROOT/'entry/src/main/resources/rawfile/app/achievements'
def svg(path,body,w=96,h=96):
    target=DEST/path;target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>\n')
    ET.parse(target)
def bloom(x,y,color):
    return f'<g fill="{color}"><ellipse cx="{x}" cy="{y-8}" rx="5" ry="8"/><ellipse cx="{x}" cy="{y+8}" rx="5" ry="8"/><ellipse cx="{x-8}" cy="{y}" rx="8" ry="5"/><ellipse cx="{x+8}" cy="{y}" rx="8" ry="5"/></g><circle cx="{x}" cy="{y}" r="4" fill="#F0C777"/>'
def mill(x=48,y=43,line='#779467',a='#E9B788',b='#A5C496'):
    return f'<path d="M{x} {y}v43" fill="none" stroke="{line}" stroke-width="4" stroke-linecap="round"/><g stroke="{line}" stroke-width="1.3" stroke-linejoin="round"><path d="M{x} {y}q-28-3-19-26 21-7 19 26Z" fill="{a}"/><path d="M{x} {y}q3-28 26-19 7 21-26 19Z" fill="{b}"/><path d="M{x} {y}q28 3 19 26-21 7-19-26Z" fill="{a}"/><path d="M{x} {y}q-3 28-26 19-7-21 26-19Z" fill="{b}"/></g><circle cx="{x}" cy="{y}" r="5" fill="#F5D98B" stroke="{line}" stroke-width="1.5"/>'
# Keep this game reproducible even if another game changes its icon generator.
icons={'back': 'M19 12H5m7-7-7 7 7 7',
 'sound': 'M4 9h4l5-4v14l-5-4H4Zm12-1q4 4 0 8m3-11q7 7 0 14',
 'muted': 'M4 9h4l5-4v14l-5-4H4Zm13 0 5 6m0-6-5 6',
 'pause': 'M8 5v14m8-14v14',
 'play': 'm8 5 11 7-11 7Z',
 'help': 'M9 9a3 3 0 0 1 6 0c0 2-3 2-3 5m0 3v.1M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0',
 'close': 'm6 6 12 12M6 18 18 6',
 'check': 'm5 12 4 4L19 6',
 'restart': 'M4 10a8 8 0 1 1 1 8M4 4v6h6',
 'spark': 'M12 2q2 8 10 10-8 2-10 10Q10 14 2 12 10 10 12 2Z',
 'trophy': 'M7 3h10v7a5 5 0 0 1-10 0Zm0 2H3v4q0 4 5 4m9-8h4v4q0 4-5 4m-4 2v5m-5 1h10',
 'cards': 'M9 3h11v15H9ZM5 6H3v15h12v-1M12 7h5m-5 4h5',
 'pair': 'M3 5h8v14H3Zm10 0h8v14h-8ZM6 12h2m8 0h2',
 'flower': 'M12 8q-8-9-9-1-1 4 5 5-10 3-4 8 4 3 8-4 3 10 8 4 3-4-4-8 10-3 4-8-4-3-8 4ZM15 12a3 3 0 1 1-6 0 3 '
           '3 0 0 1 6 0',
 'next': 'M4 12h15m-6-6 6 6-6 6',
 'leaf': 'M5 19Q1 3 21 3q0 18-16 16Zm-2 3L17 7'}
icons.update({'up':'M12 21V4m-7 7 7-7 7 7','down':'M12 3v17m-7-7 7 7 7-7','left':'M21 12H4m7-7-7 7 7 7','right':'M3 12h17m-7-7 7 7-7 7',
'undo':'M4 9h9a6 6 0 1 1 0 12M9 4 4 9l5 5','hint':'M8 16c0-3-3-3-3-7a7 7 0 1 1 14 0c0 4-3 4-3 7Zm1 3h6m-5 3h4',
'more':'M5 12h.1M12 12h.1M19 12h.1','clear':'m6 6 12 12M6 18 18 6','wind':'M3 8h12q7 0 5-5-3-4-5 0M3 12h16M3 16h10q6 0 4 5-3 3-5-1'})
for dark in [False,True]:
    theme='dark' if dark else 'light';bg='#171E1C' if dark else '#FFF4E4';paper='#29332E' if dark else '#FFFCF3'
    leaf='#8CA68A' if dark else '#B4CC9B';peach='#B8946E' if dark else '#EFCDA8';ink='#F6ECD8' if dark else '#324C40';accent='#AAD8B4' if dark else '#28745D'
    for name,path in icons.items():
        for tone,color in [('ink',ink),('accent',accent),('on','#183D30' if dark else '#FFFBEF')]:
            svg(f'icons/{name}_{tone}_{theme}.svg',f'<path d="{path}" fill="none" stroke="{color}" stroke-width="{3.5 if name=="more" else 1.8}" stroke-linecap="round" stroke-linejoin="round"/>',24,24)
    svg(f'scene/atmosphere_{theme}.svg',f'<path d="M0 660Q330 480 760 700t440-30v530H0Z" fill="{leaf}" opacity=".06"/><path d="M0 905Q320 840 640 990t560-10" fill="none" stroke="{leaf}" stroke-width="2" opacity=".13"/>',1200,1200)
    svg(f'scene/canopy_{theme}.svg',f'<g fill="none" stroke="{leaf}" stroke-width="2" opacity=".4"><path d="M60-20q90 120 310 55M90-20q100 110 280 35"/><path d="M138 30q-28-5-25-29 23 0 25 29m68 20q-4-30 22-35 9 21-22 35m69-4q-16 27 13 35 18-22-13-35" fill="{leaf}"/></g>',380,150)
    svg(f'scene/garden_{theme}.svg',f'<g opacity=".38"><path d="M46 237Q33 132 99 28" fill="none" stroke="{leaf}" stroke-width="3"/><path d="M58 145Q7 119 15 76q43 7 43 69Zm9-18q5-51 66-51-6 43-66 51Z" fill="{leaf}"/>{bloom(90,45,peach)}<path d="m121 220 7 37h41l9-37Z" fill="{peach}"/><path d="M150 222v-59m0 27q-33 0-28-25 28 2 28 25Zm0 15q30-5 34-30-33 1-34 30Z" fill="{leaf}" stroke="{leaf}" stroke-width="2"/></g>',250,270)
    svg(f'scene/stilllife_{theme}.svg',f'<g opacity=".44"><path d="M12 177q155-18 295 0" fill="none" stroke="{peach}" stroke-width="3"/>{mill(244,79,leaf,peach,leaf)}<rect x="71" y="130" width="38" height="38" rx="10" fill="{peach}" transform="rotate(-10 90 149)"/><path d="M86 139q10-7 12 1 1 4-10 13h11" fill="none" stroke="{ink}" stroke-width="2" stroke-linecap="round"/><rect x="120" y="130" width="38" height="38" rx="10" fill="{leaf}" transform="rotate(6 139 149)"/><path d="M132 137h14l-10 21" fill="none" stroke="{ink}" stroke-width="2" stroke-linecap="round"/></g>',320,205)
    svg(f'scene/mascot_{theme}.svg',f'<ellipse cx="87" cy="126" rx="58" ry="5" fill="{leaf}" opacity=".18"/><g transform="translate(26 1) scale(1.4)">{mill(48,43,leaf,peach,leaf)}</g>',170,140)
    svg(f'scene/edge_fade_{theme}.svg',f'<defs><linearGradient id="edge" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{bg}"/><stop offset=".15" stop-color="{bg}" stop-opacity="0"/><stop offset=".83" stop-color="{bg}" stop-opacity="0"/><stop offset="1" stop-color="{bg}"/></linearGradient></defs><rect width="100" height="100" fill="url(#edge)"/>',100,100)
    svg(f'scene/tile_leaf_{theme}.svg',f'<path d="M68 87q1-28 24-34-2 25-24 34m0 0Q46 88 45 70q24-1 23 17Z" fill="{leaf}" opacity=".2"/><path d="m61 94 22-30" fill="none" stroke="{leaf}" stroke-width="1.7" opacity=".25"/>')
logo='<rect x="4" y="4" width="120" height="120" rx="32" fill="#F4DDB1"/><rect x="17" y="37" width="43" height="56" rx="13" fill="#FFFCF3" stroke="#C8D6AB" stroke-width="2" transform="rotate(-8 39 65)"/><rect x="62" y="37" width="43" height="56" rx="13" fill="#C2D5AC" stroke="#91AE83" stroke-width="2" transform="rotate(7 83 65)"/><path d="m29 55 10-7v35m34-26c0-12 19-12 19 0v17c0 12-19 12-19 0Z" fill="none" stroke="#496B4B" stroke-width="4" stroke-linecap="round"/><g transform="translate(80 1) scale(.39)">'+mill()+'</g><path d="M25 105q35 7 72 0" fill="none" stroke="#C79665" stroke-width="3" stroke-linecap="round"/>'
svg('scene/logo.svg',logo,128,128)
first='<g transform="rotate(-9 41 65)"><rect x="16" y="36" width="43" height="51" rx="11" fill="#F1C98C"/><path d="M29 51q17-11 19 1 1 7-18 23h19" fill="none" stroke="#865F39" stroke-width="3" stroke-linecap="round"/></g><g transform="rotate(8 88 65)"><rect x="67" y="36" width="43" height="51" rx="11" fill="#B5CDA5"/><path d="M80 51c0-10 18-10 18 0s-18 10-18 0Zm-2 21c0-14 22-14 22 0s-22 14-22 0Z" fill="none" stroke="#526F47" stroke-width="2.5"/></g>'+bloom(64,98,'#E7B1A1')
clear='<circle cx="83" cy="37" r="16" fill="#F1CB77"/><path d="M24 91V62q0-30 32-30t32 30v29" fill="#E6EDCE" stroke="#96AF77" stroke-width="3"/><path d="M37 90V63q0-17 19-17t19 17v27" fill="#FFFAE9"/><path d="M18 96h90" stroke="#D6AA75" stroke-width="4" stroke-linecap="round"/>'+bloom(88,82,'#DFB1A0')
collector='<path d="M25 71h79l-10 34H35Z" fill="#DBAD77" stroke="#B68B5C" stroke-width="2"/><path d="M37 75q-2-48 28-48t28 48" fill="none" stroke="#B68B5C" stroke-width="4"/><path d="M31 84h67M35 96h60" fill="none" stroke="#F6DEAC" stroke-width="3"/>'+bloom(46,62,'#DAB0CB')+bloom(76,57,'#B5CFA0')+'<path d="m57 81 6-3v18m7-14c0-7 11-7 11 0v9c0 7-11 7-11 0Z" fill="none" stroke="#745237" stroke-width="2.4" stroke-linecap="round"/>'
for name,art in [('first',first),('clear',clear),('collector',collector)]:
    target=BADGES/f'ach_ten_{name}.svg'
    target.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><circle cx="64" cy="64" r="59" fill="#F7E8C6" stroke="#D8B77D" stroke-width="3"/><circle cx="64" cy="64" r="51" fill="#FFFAE9"/>'+art+'</svg>\n');ET.parse(target)
sounds={'select':(.08,[660]),'collect':(.30,[523,659,784]),'wind':(.16,[392,523]),'undo':(.14,[440,330]),'complete':(.65,[523,659,784,1046]),'tap':(.09,[550])}
for name,(duration,notes) in sounds.items():
    rate=24000;samples=[]
    for i in range(int(rate*duration)):
        t=i/rate;value=0
        for j,f in enumerate(notes):
            age=t-j*duration*.42/max(1,len(notes)-1)
            if age>=0:value+=(math.sin(2*math.pi*f*age)+.15*math.sin(2*math.pi*f*2*age))*min(1,age/.008)*math.exp(-age/.095)
        samples.append(value*min(1,(duration-t)/.025))
    peak=max(map(abs,samples));ceiling=.38 if name=='select' else .55
    path=DEST/'audio'/f'{name}.wav';path.parent.mkdir(parents=True,exist_ok=True)
    with wave.open(str(path),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate)
        out.writeframes(b''.join(struct.pack('<h',round(v/peak*ceiling*32767)) for v in samples))
print('Ten Garden:',len(list(DEST.rglob('*.svg'))),'SVG,',len(sounds),'sounds, 3 new badges')
