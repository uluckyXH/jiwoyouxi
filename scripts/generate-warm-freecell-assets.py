#!/usr/bin/env python3
"""Original vector artwork and deterministic local PCM effects for the card room."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'entry/src/main/resources/rawfile/gamesNext/warmFreecell'

def svg(path, body, w=24, h=24):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>\n')

SUITS = [
    'M12 2C9 6 3 9 3 14a5 5 0 0 0 8 4l-2 4h6l-2-4a5 5 0 0 0 8-4C21 9 15 6 12 2Z',
    'M12 21C9 18 2 13 2 7a5 5 0 0 1 10-1 5 5 0 0 1 10 1c0 6-7 11-10 14Z',
    'm12 2 9 10-9 10L3 12Z',
    'M12 2a5 5 0 0 0-4 8 5 5 0 1 0 3 8l-2 4h6l-2-4a5 5 0 1 0 3-8 5 5 0 0 0-4-8Z'
]
ICONS = {
    'back': 'M19 12H5m7-7-7 7 7 7', 'close': 'm6 6 12 12M18 6 6 18',
    'pause': 'M8 5v14M16 5v14', 'play': 'm8 5 11 7-11 7Z',
    'undo': 'M8 4 3 9l5 5M3 9h10a7 7 0 1 1 0 14',
    'restart': 'M4 4v6h6M4 10a8 8 0 1 1 1 8',
    'help': 'M9 8a3 3 0 1 1 5 3c-2 1-2 1-2 3m0 4v.1M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0',
    'hint': 'M9 18h6m-6 3h6M8 15a7 7 0 1 1 8 0l-1 2H9Z',
    'sound': 'm3 9 5 0 5-5v16l-5-5H3ZM17 8a6 6 0 0 1 0 8m3-11a10 10 0 0 1 0 14',
    'muted': 'm3 9 5 0 5-5v16l-5-5H3ZM17 9l5 6m0-6-5 6',
    'auto': 'm12 2 1.8 6.2L20 10l-6.2 1.8L12 18l-1.8-6.2L4 10l6.2-1.8ZM19 17v6m-3-3h6',
    'check': 'm5 12 5 5L20 6', 'time': 'M12 8v5l4 2M9 2h6m-3 0v3M21 14a9 9 0 1 1-18 0 9 9 0 0 1 18 0',
    'steps': 'M4 5h7m-3-3 3 3-3 3M20 19h-7m3-3-3 3 3 3M5 11v5h5v-5ZM14 4v7h5V4Z',
    'cards': 'M4 4h11v16H4ZM15 7h5v13h-5M8 8h3m-3 4h3',
    'trophy': 'M7 3h10v8a5 5 0 0 1-10 0ZM7 5H3v4a4 4 0 0 0 4 4m10-8h4v4a4 4 0 0 1-4 4m-5 3v5m-4 0h8'
}
for dark in [False, True]:
    theme = 'dark' if dark else 'light'
    bg, ink, accent, paper, felt, red, gold = ('#101110','#F4EBD8','#A8CFA8','#303C32','#1C2B24','#FFB5A5','#DDB875') if dark else ('#FFF4E4','#27372D','#2C6B52','#FFFCF3','#E5ECD9','#A63F39','#C49048')
    for name, path in ICONS.items():
        for tone, color in [('ink',ink),('accent',accent),('on','#183A2A' if dark else '#FFFAF2')]:
            svg(f'ui/{name}_{theme}_{tone}.svg', f'<path d="{path}" fill="none" stroke="{color}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>')
    for suit, path in enumerate(SUITS):
        color = red if suit in (1,2) else ink
        svg(f'cards/suit_{suit}_{theme}.svg', f'<path d="{path}" fill="{color}"/>')
        svg(f'cards/slot_{suit}_{theme}.svg', f'<rect x="1" y="1" width="98" height="140" rx="12" fill="{accent}" fill-opacity=".055" stroke="{accent}" stroke-opacity=".24" stroke-dasharray="4 4"/><g transform="translate(34 55) scale(1.35)" opacity=".28"><path d="{path}" fill="{color}"/></g>',100,142)
    svg(f'cards/empty_{theme}.svg', f'<rect x="1" y="1" width="98" height="140" rx="12" fill="{accent}" fill-opacity=".045" stroke="{accent}" stroke-opacity=".23"/><path d="M38 71h24m-12-12v24" stroke="{accent}" stroke-opacity=".25" stroke-width="1.5"/>',100,142)
    svg(f'cards/face_{theme}.svg', f'<rect x="1" y="4" width="98" height="137" rx="11" fill="{ink}" fill-opacity=".18"/><rect x="1" y="1" width="98" height="137" rx="11" fill="{paper}" stroke="{accent}" stroke-opacity=".30"/><path d="M7 25V15q0-8 8-8h32" fill="none" stroke="#FFFFFF" stroke-opacity=".22"/><path d="M66 131h14q12 0 12-12" fill="none" stroke="{accent}" stroke-opacity=".15"/>',100,142)
    seal = ''.join(f'<g transform="translate({36 + (i%2)*43} {30 + (i//2)*42})"><path d="{path}" fill="{accent}" fill-opacity=".11"/></g>' for i,path in enumerate(SUITS))
    svg(f'scene/seal_{theme}.svg', f'<g opacity=".11"><circle cx="70" cy="65" r="58" fill="none" stroke="{accent}" stroke-width="1"/><circle cx="70" cy="65" r="53" fill="none" stroke="{accent}" stroke-width=".7" stroke-dasharray="2 6"/>{seal}<path d="M20 132q50 12 100 0m-85 8q35 8 70 0" fill="none" stroke="{accent}"/></g>',140,158)
    for rank in [11,12,13]:
        path = 'M8 19h32L37 8l-8 8-5-12-5 12-8-8ZM10 24h28v10H10ZM15 39h18' if rank==13 else 'm24 4 6 11 12 3-7 10 1 12-12-4-12 4 1-12-7-10 12-3Z' if rank==12 else 'm24 4 15 16-7 18H16L9 20Zm-8 19h16m-8-11v20'
        svg(f'cards/royal_{rank}_{theme}.svg', f'<circle cx="24" cy="24" r="22" fill="{gold}" fill-opacity=".10"/><path d="{path}" fill="none" stroke="{gold}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>',48,48)
    svg(f'scene/backdrop_{theme}.svg', f'''<defs><radialGradient id="light" gradientUnits="userSpaceOnUse" cx="710" cy="250" r="570"><stop offset="0%" stop-color="{gold}" stop-opacity=".14"/><stop offset="100%" stop-color="{gold}" stop-opacity="0"/></radialGradient><linearGradient id="edge" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="1000"><stop offset="0%" stop-color="{bg}"/><stop offset="16%" stop-color="{bg}" stop-opacity="0"/><stop offset="84%" stop-color="{bg}" stop-opacity="0"/><stop offset="100%" stop-color="{bg}"/></linearGradient></defs>
<ellipse cx="710" cy="250" rx="570" ry="470" fill="url(#light)"/>
<g stroke="{gold}" stroke-opacity=".13" stroke-width="2" fill="none"><path d="M500 50 790 270M420 80 710 300M565 0 390 265M740 0 520 350"/><path d="M-40 890q290-90 590 10t330 0M-40 908q290-90 590 10t330 0M-40 930q290-90 590 10t330 0"/></g>
<g fill="{accent}" fill-opacity=".12" stroke="{accent}" stroke-opacity=".22"><path d="M45 932Q2 868 38 791q54 53 11 122M51 941q-3-89 72-115-6 79-72 115M51 941Q3 926 3 876q48 9 48 65"/><path d="M47 961q-5-93-9-149m10 127 67-96" fill="none"/></g>
<g transform="translate(650 740) rotate(15)"><rect width="115" height="154" rx="15" fill="{gold}" fill-opacity=".07" stroke="{gold}" stroke-opacity=".18"/><g transform="translate(35 49) scale(2)" opacity=".12"><path d="{SUITS[3]}" fill="{accent}"/></g></g><rect width="800" height="1000" fill="url(#edge)"/>''',800,1000)
    cards=''
    for i,(label,suit) in enumerate([('8',0),('7',1),('6',3)]):
        color=red if suit==1 else ink
        digit = ['M10 2C1 2 1 13 10 13s9-11 0-11Zm0 11C0 13 0 26 10 26s10-13 0-13Z','M2 2H18L7 26','M17 3C3-2 0 26 10 26c12 0 11-17 0-17-4 0-7 3-7 7'][i]
        cards+=f'<g transform="translate({12+i*75} {12+i*14})"><rect width="65" height="92" rx="9" fill="{paper}" stroke="{accent}" stroke-opacity=".4"/><path d="{digit}" transform="translate(10 8) scale(.65)" fill="none" stroke="{color}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><g transform="translate(21 40)"><path d="{SUITS[suit]}" fill="{color}"/></g></g>'
    svg(f'guide/order_{theme}.svg',cards,240,142)
svg('scene/logo.svg',f'<rect x="2" y="2" width="92" height="92" rx="24" fill="#EED7AA" stroke="#C5AE79" stroke-width="2"/><g transform="rotate(-11 45 50)"><rect x="18" y="21" width="40" height="56" rx="7" fill="#E4ECD9" stroke="#84A17C" stroke-width="2"/></g><rect x="37" y="18" width="40" height="59" rx="7" fill="#FFFCF3" stroke="#2C6B52" stroke-width="2"/><path d="m44 35 5-10 5 10m-8-4h6" fill="none" stroke="#A63F39" stroke-width="2" stroke-linecap="round"/><g transform="translate(45 42)"><path d="{SUITS[1]}" fill="#A63F39"/></g><path d="M22 85h52" stroke="#B39255" stroke-width="2" stroke-linecap="round"/>',96,96)

rng = random.Random(204852)
for name,duration,freq,peak in [('tap',.09,430,.55),('slide',.17,310,.62),('home',.28,660,.66),('undo',.18,380,.60),('hint',.34,520,.60),('blocked',.10,190,.34),('deal',.22,350,.58),('win',1.05,440,.68)]:
    samples=[]; rate=24000; noise=0
    for i in range(int(rate*duration)):
        t=i/rate; u=t/duration
        envelope=(1-math.exp(-t*160))*math.exp(-u*5)*(1-u)**.5
        noise=noise*.65+rng.uniform(-1,1)*.35
        tone=math.sin(2*math.pi*freq*t)+.22*math.sin(2*math.pi*freq*2*t)
        if name in ('slide','deal','undo'): tone=tone*.32+noise*1.5
        if name in ('home','hint','win'): tone+=.48*math.sin(2*math.pi*freq*1.25*t)+.38*math.sin(2*math.pi*freq*1.5*t)
        samples.append(envelope*tone)
    scale=peak/max(abs(x) for x in samples)
    path=ROOT/f'audio/{name}.wav';path.parent.mkdir(parents=True,exist_ok=True)
    with wave.open(str(path),'wb') as output:
        output.setparams((1,2,rate,0,'NONE','not compressed'))
        output.writeframes(b''.join(struct.pack('<h',round(x*scale*32767)) for x in samples))
print(f'Generated {sum(1 for p in ROOT.rglob("*") if p.is_file())} SVG/audio resources under {ROOT}')
