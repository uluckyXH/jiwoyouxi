#!/usr/bin/env python3
"""Original, reproducible vector artwork and synthesized sounds for Fruit Market Next.
No downloaded artwork, fonts, raster images, or audio samples are used.
"""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'entry/src/main/resources/rawfile/gamesNext/fruitMarket'
for directory in ['fruits', 'scene', 'icons', 'audio']:
    (ROOT / directory).mkdir(parents=True, exist_ok=True)

def svg(path, body, view='0 0 200 200'):
    _, _, width, height = view.split()
    (ROOT / path).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="{view}">{body}</svg>\n')

def face(y=114, happy=False):
    mouth = f'M88 {y+12} Q100 {y+24} 112 {y+12}' if happy else f'M94 {y+14} Q100 {y+20} 106 {y+14}'
    return f'''<g fill="#493627"><ellipse cx="76" cy="{y}" rx="4" ry="6"/><ellipse cx="124" cy="{y}" rx="4" ry="6"/></g>
    <g fill="#fff" opacity=".8"><circle cx="75" cy="{y-2}" r="1.4"/><circle cx="123" cy="{y-2}" r="1.4"/></g>
    <g fill="#f08379" opacity=".45"><ellipse cx="62" cy="{y+9}" rx="9" ry="4.5"/><ellipse cx="138" cy="{y+9}" rx="9" ry="4.5"/></g>
    <path d="{mouth}" fill="none" stroke="#493627" stroke-width="3" stroke-linecap="round"/>'''

def leaf(x=101,y=29):
    return f'''<path d="M{x} {y+15}q-5-15 5-24" fill="none" stroke="#79553c" stroke-width="5" stroke-linecap="round"/>
    <path d="M{x+2} {y+7}q7-28 35-21-8 26-35 21Z" fill="#62934c" stroke="#416d37" stroke-width="2.5"/>
    <path d="M{x+4} {y+4}l23-12" stroke="#bdd68b" stroke-width="2.5" stroke-linecap="round"/>'''

palette=[('#bfa0eb','#7751ad','#624389'),('#96b9e6','#5579b4','#425d89'),('#ffce75','#ef983d','#bf732b'),('#ff9c81','#e66050','#b4433b'),('#ffd0b4','#f29496','#ca707a'),('#f4d993','#caaa66','#998552'),('#b4d879','#6ba15d','#518049'),('#90c992','#488e66','#336b51'),('#74b588','#2f795a','#255f49'),('#71bf9b','#318d6c','#216950'),('#ffe9a3','#e8bc57','#b18c3e')]
names=['grape','blueberry','orange','apple','peach','melon','small_watermelon','watermelon','big_watermelon','rooster_watermelon','giant_watermelon']
for i, (light, dark, outline) in enumerate(palette):
    defs=f'''<defs><radialGradient id="skin" cx="32%" cy="25%" r="82%"><stop stop-color="{light}"/><stop offset=".7" stop-color="{dark}"/><stop offset="1" stop-color="{outline}"/></radialGradient><clipPath id="body"><circle cx="100" cy="103" r="84"/></clipPath></defs>'''
    base=f'<circle cx="100" cy="103" r="84" fill="url(#skin)" stroke="{outline}" stroke-width="3"/>'
    details=''
    if i==0:
        details='''<g fill="#b091d5" stroke="#8060ad" stroke-width="2" opacity=".8"><circle cx="62" cy="68" r="22"/><circle cx="104" cy="55" r="22"/><circle cx="143" cy="76" r="23"/><circle cx="53" cy="112" r="23"/><circle cx="93" cy="96" r="25"/><circle cx="139" cy="120" r="25"/><circle cx="85" cy="147" r="26"/></g>'''
    elif i==1:
        details='''<path d="M80 30l15 8 14-10 5 15 17 6-15 9-2 17-15-10-16 7 2-18-13-10 17-2Z" fill="#5271a4" opacity=".8"/><path d="M42 66q17-22 39-24" stroke="#c5d9f0" stroke-width="6" fill="none" stroke-linecap="round"/>'''
    elif i==2:
        details=''.join(f'<circle cx="{x}" cy="{y}" r="2" fill="#c98031" opacity=".4"/>' for x,y in [(39,95),(48,138),(75,158),(121,161),(157,141),(162,98),(138,60),(73,59),(99,76)])
    elif i==3:
        details='<path d="M94 22q7 12 17 0" stroke="#b54439" stroke-width="5" fill="none" stroke-linecap="round"/><path d="M45 84q5-25 22-30" stroke="#ffd0b1" stroke-width="9" fill="none" stroke-linecap="round"/>'
    elif i==4:
        details='<path d="M108 29C77 66 109 145 92 174" fill="none" stroke="#cf7680" stroke-width="3" opacity=".6"/>'
    elif i==5:
        details='<g clip-path="url(#body)" stroke="#fff1c7" stroke-width="2" opacity=".55">'+''.join(f'<path d="M-30 {y}L230 {y+130}M-30 {y+130}L230 {y}"/>' for y in range(-140,220,28))+'</g>'
    elif i>=6:
        stripe='#649753' if i==6 else '#256b4b' if i<10 else '#cf9840'
        details=f'<g clip-path="url(#body)" fill="none" stroke="{stripe}" stroke-width="{9 if i<8 else 12}" opacity=".58"><path d="M55 12C91 63 20 115 60 196M100 13C129 68 70 133 105 196M146 16C168 73 133 130 153 188"/></g>'
        if i>=8:
            details+='<g fill="#e2efb7" opacity=".55"><path d="M45 67l2-6 3 6 6 2-6 2-3 6-2-6-6-2ZM151 143l2-5 2 5 5 2-5 2-2 5-2-5-5-2Z"/></g>'
    # A unified highlight and small face keep the whole family readable at game size.
    highlight='<path d="M42 70q8-20 27-27" fill="none" stroke="#fffbe9" stroke-opacity=".47" stroke-width="7" stroke-linecap="round"/>' if i not in [1,3] else ''
    topper=leaf() if i in [0,2,3,4,5,6,7,8] else ''
    if i==9:
        topper='''<path d="M74 34C61 15 70 5 80 17 78 0 98-2 102 16 111-2 130 8 121 25 138 18 144 32 126 39Z" fill="#f08263" stroke="#b65644" stroke-width="3"/>'''
    if i==10:
        topper='''<path d="M69 33 61 9 84 21 100 2 115 21 141 9 133 37Z" fill="#fff0a5" stroke="#b18c3e" stroke-width="3" stroke-linejoin="round"/><circle cx="100" cy="22" r="4" fill="#ed8e67"/>'''
    svg(f'fruits/{i:02}_{names[i]}.svg',defs+base+details+highlight+face(happy=i>=7)+topper)

for theme in ['light','dark']:
    dark=theme=='dark'
    fill='#292922' if dark else '#fff9eb'
    inner='#242a25' if dark else '#f5f2dd'
    border='#61523d' if dark else '#ddc599'
    wood='#755539' if dark else '#c99862'
    stripe='#65846b' if dark else '#91b492'
    svg(f'scene/stall_{theme}.svg',f'''<defs><linearGradient id="well" x2="0" y2="1"><stop stop-color="{fill}"/><stop offset="1" stop-color="{inner}"/></linearGradient><clipPath id="roof"><path d="M27 8h306l15 26v13q-10 16-23 0-14 16-28 0-14 16-28 0-14 16-28 0-14 16-28 0-14 16-28 0-14 16-28 0-14 16-28 0-14 16-28 0-14 16-28 0-14 16-23 0V34Z"/></clipPath></defs>
    <rect x="10" y="75" width="340" height="429" rx="24" fill="url(#well)" stroke="{border}" stroke-width="2"/>
    <path d="M23 121v349q0 20 20 20h274q20 0 20-20V121" fill="none" stroke="{border}" stroke-opacity=".4" stroke-width="2"/>
    <g clip-path="url(#roof)"><path d="M8 8h344v60H8Z" fill="{'#d6c4a4' if dark else '#fff5d7'}"/>
    {''.join(f'<path d="M{x} 7h23l5 53h-33Z" fill="{stripe}"/>' for x in range(18,350,56))}</g>
    <path d="M26 9h307" stroke="{border}" stroke-width="4" stroke-linecap="round"/>
    <rect x="8" y="494" width="344" height="20" rx="8" fill="{wood}"/><path d="M29 502h58m38 0h77m42 0h80" stroke="{'#aa8259' if dark else '#e4ba82'}" stroke-width="2" stroke-linecap="round"/>
    <g fill="{border}" opacity=".5"><circle cx="30" cy="477" r="3"/><circle cx="330" cy="477" r="3"/></g>''','0 0 360 520')
    bg='#101110' if dark else '#fff4e4'
    soft='#27291e' if dark else '#e5ebcd'
    cloud='#24221c' if dark else '#ffebc8'
    svg(f'scene/garden_{theme}.svg',f'''<path fill="{bg}" d="M0 0h1600v1000H0Z"/>
    <circle cx="1460" cy="120" r="260" fill="{cloud}"/><ellipse cx="90" cy="1020" rx="480" ry="250" fill="{soft}"/><ellipse cx="1560" cy="1020" rx="320" ry="390" fill="{soft}"/>
    <g stroke="{'#485137' if dark else '#c3ce9f'}" fill="none" stroke-width="4" opacity=".5"><path d="M40 860Q180 640 83 412M1530 878Q1400 700 1470 465"/></g>
    <g fill="{'#3a442f' if dark else '#c9d6a8'}" opacity=".7"><path d="M105 630q-86-23-83-100 91 13 83 100ZM103 564q-11-95 77-125 10 90-77 125ZM1484 657q-7-112 85-139 4 104-85 139ZM1466 572q-86-30-64-106 82 20 64 106Z"/></g>
    <g fill="{'#eac578' if dark else '#e8bd78'}" opacity=".6"><circle cx="220" cy="265" r="4"/><circle cx="1340" cy="408" r="3"/><circle cx="1260" cy="710" r="4"/></g>''','0 0 1600 1000')

icons={
'back':'<path d="m14 5-7 7 7 7M7 12h14"/>',
'pause':'<path d="M8 5v14M16 5v14" stroke-width="4"/>',
'play':'<path d="m8 4 12 8-12 8Z"/>',
'restart':'<path d="M4 10a8 8 0 1 1 1 7M4 4v6h6"/>',
'sound':'<path d="M4 9h4l5-4v14l-5-4H4ZM17 8q4 4 0 8m3-11q7 7 0 14"/>',
'muted':'<path d="M4 9h4l5-4v14l-5-4H4Zm13 0 5 6m0-6-5 6"/>',
'help':'<circle cx="12" cy="12" r="9"/><path d="M9 9a3 3 0 1 1 4 3c-1 .5-1 1-1 2m0 3h.01"/>',
'close':'<path d="m6 6 12 12M6 18 18 6"/>',
'trophy':'<path d="M7 4h10v6a5 5 0 0 1-10 0ZM7 6H3v3q0 4 5 4m9-7h4v3q0 4-5 4m-4 2v5m-4 0h8"/>',
'leaf':'<path d="M5 19C0 6 11 3 21 3c0 12-5 19-16 16Zm0 0L16 8"/>',
'arrow':'<path d="M4 12h16m-6-6 6 6-6 6"/>',
'expand':'<rect x="3" y="4" width="18" height="16" rx="4"/><path d="M12 7v10M9 9l-3 3 3 3m6-6 3 3-3 3"/>',
'spark':'<path d="m12 2 3 7 7 3-7 3-3 7-3-7-7-3 7-3Z"/>'}
for name, paths in icons.items():
    svg(f'icons/{name}.svg',f'<g fill="none" stroke="#000" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">{paths}</g>','0 0 24 24')
    # Native Image.fillColor changes fills, not strokes; supply explicit palette variants.
    for tone, color in {'light':'#463c2d', 'dark':'#eee5d0',
                        'primary_light':'#fff9e9', 'primary_dark':'#25351f',
                        'accent_light':'#527342', 'accent_dark':'#b6d39a',
                        'gold_light':'#9b6324', 'gold_dark':'#ffd083'}.items():
        svg(f'icons/{name}_{tone}.svg',f'<g fill="none" stroke="{color}" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">{paths}</g>','0 0 24 24')
# An original market emblem used inside the game; the home entry shares the classic game logo.
svg('scene/market_badge.svg','''<rect x="8" y="8" width="184" height="184" rx="58" fill="#f9e9c5"/><path d="M34 48h132l11 28q-11 19-26 1-17 17-34 0-17 17-34 0-17 17-34 0-15 18-26-1Z" fill="#93af81"/><path d="M43 84v62m114-62v62" stroke="#b58250" stroke-width="7" stroke-linecap="round"/><circle cx="100" cy="123" r="37" fill="#6ca475" stroke="#4b815a" stroke-width="3"/><path d="M81 89q-15 33 0 67m20-70q-12 40 0 75m20-71q-6 29 1 64" stroke="#3e7b52" fill="none" stroke-width="6"/><path d="M86 113v5m27-5v5m-19 10q6 5 12 0" fill="none" stroke="#334b34" stroke-width="3" stroke-linecap="round"/><rect x="27" y="153" width="146" height="18" rx="7" fill="#c0915d"/>''')

# Soft, short PCM effects. Synthesized locally; deterministic and royalty-free.
SR=24000
sounds={'drop':(.17,[480,260]),'merge':(.27,[523.25,659.25,783.99]),'bloom':(.47,[659.25,783.99,1046.5]),'crown':(.85,[523.25,659.25,783.99,1046.5]),'warning':(.24,[392,392]),'finish':(.65,[523.25,440,349.23]),'tap':(.065,[880])}
for name,(duration,notes) in sounds.items():
    rng=random.Random(23)
    samples=[]
    for n in range(int(SR*duration)):
        t=n/SR
        value=0.0
        for k,freq in enumerate(notes):
            delay=k*duration*.16
            age=t-delay
            if age>=0:
                env=min(1,age/.005)*math.exp(-age/(duration*.24))
                value+=(math.sin(2*math.pi*freq*age)+.22*math.sin(2*math.pi*freq*2*age))*env*.24
        if name=='drop':
            value+=rng.uniform(-1,1)*.06*math.exp(-t*60)
        value*=min(1,(duration-t)/.018)
        samples.append(struct.pack('<h',int(max(-.8,min(.8,value))*32767)))
    with wave.open(str(ROOT / f'audio/{name}.wav'),'wb') as wav:
        wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(SR);wav.writeframes(b''.join(samples))
print(f'Created {len(list(ROOT.rglob("*.svg")))} SVGs and 7 original WAV effects in',ROOT)
