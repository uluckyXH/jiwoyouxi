#!/usr/bin/env python3
"""Original vector artwork and short synthesized sounds for 星星小院. No downloads."""
from pathlib import Path
import math, wave, struct
ROOT = Path(__file__).resolve().parents[1] / 'entry/src/main/resources/rawfile'
BASE = ROOT / 'gamesNext/starPop'

def svg(body, width=96, height=None):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height or width}" viewBox="0 0 {width} {height or width}">{body}</svg>\n'
def write(path, body):
    path.parent.mkdir(parents=True, exist_ok=True); path.write_text(body)
def star(cx, cy, r, fill, angle=-90):
    pts=[]
    for i in range(10):
        a=math.radians(angle+i*36); rr=r if i%2==0 else r*.47
        pts.append(f'{cx+math.cos(a)*rr:.2f},{cy+math.sin(a)*rr:.2f}')
    return f'<polygon points="{" ".join(pts)}" fill="{fill}" stroke="{fill}" stroke-width="3" stroke-linejoin="round"/>'
def face(x=48,y=53,ink='#68523B'):
    return f'<g fill="{ink}"><circle cx="{x-7}" cy="{y}" r="1.7"/><circle cx="{x+7}" cy="{y}" r="1.7"/></g><path d="M{x-2.5} {y+4}q2.5 3 5 0" fill="none" stroke="{ink}" stroke-width="1.6" stroke-linecap="round"/>'
def motif(c,fill):
    if c==0:return star(48,45,24,fill)
    if c==1:
        return '<g fill="'+fill+'">'+''.join(f'<circle cx="{48+math.cos(i*math.pi/3)*13:.2f}" cy="{46+math.sin(i*math.pi/3)*13:.2f}" r="12"/>' for i in range(6))+'</g>'
    if c==2:return f'<path d="M27 61Q16 22 68 22Q83 63 44 72Z" fill="{fill}"/><path d="M31 66L62 32" stroke="#4B764F" stroke-opacity=".22" stroke-width="3" stroke-linecap="round"/>'
    if c==3:return f'<path d="M48 21C41 29 27 41 27 53a21 21 0 0 0 42 0C69 41 55 29 48 21Z" fill="{fill}"/>'
    return f'<path d="M64 26A25 25 0 1 0 70 62Q35 69 42 27Q50 20 64 26Z" fill="{fill}"/>'
light=['#F1CC75','#EBA495','#A8C4A0','#99C2D1','#BEA9D4']
dark=['#B89248','#B97E74','#779970','#648A9C','#8A759F']
for is_dark,colors in [(False,light),(True,dark)]:
    theme='dark' if is_dark else 'light'; ink='#F7EFD9' if is_dark else '#645540'
    for i,color in enumerate(colors):
        body=f'<rect x="3" y="6" width="90" height="88" rx="21" fill="{color}"/><rect x="3" y="3" width="90" height="85" rx="21" fill="{color}" stroke="{ink}" stroke-opacity=".10" stroke-width="1.5"/><path d="M16 27q0-12 12-12h17" fill="none" stroke="#FFFFFF" stroke-opacity=".35" stroke-width="4" stroke-linecap="round"/>'
        body+=motif(i, '#F9E6AA' if i==0 else ['','#F5C4B9','#D0DFB4','#C6E3E8','#DFCEE7'][i])
        body+=face(48 if i!=4 else 41,52 if i!=4 else 53)
        write(BASE/f'tiles/{i}_{theme}.svg',svg(body))
    paper='#272E27' if is_dark else '#FFFCF3'; line='#7D7656' if is_dark else '#E4C996'; soft='#20271F' if is_dark else '#F6EBD5'
    frame=f'<rect x="2" y="2" width="596" height="732" rx="32" fill="{paper}" stroke="{line}" stroke-width="3"/><rect x="8" y="8" width="584" height="720" rx="26" fill="none" stroke="{line}" stroke-opacity=".32" stroke-width="1.5"/><path d="M34 6h64M502 730h64" stroke="{line}" stroke-width="5" stroke-linecap="round"/>'
    write(BASE/f'scene/frame_{theme}.svg',svg(frame,600,736))
    # Transparent sprigs, deliberately no rectangle or hard-edged wallpaper.
    backdrop=f'<g opacity="{.25 if is_dark else .48}"><path d="M286 296Q241 206 267 114M65 278Q99 217 81 156" fill="none" stroke="{line}" stroke-width="4" stroke-linecap="round"/><g fill="{ "#506547" if is_dark else "#CBD9B1"}"><path d="M264 161q-36-12-29-43q32 6 29 43M258 200q32-4 37-38q-36 6-37 38M273 245q-40-9-40-42q41 3 40 42M84 190q-33-4-28-30q27 2 28 30M87 224q28-8 32-30q-27 1-32 30"/></g>{star(177,106,8,line)}{star(137,256,5,line)}<circle cx="199" cy="200" r="4" fill="none" stroke="{line}" stroke-width="2"/></g>'
    write(BASE/f'scene/sprigs_{theme}.svg',svg(backdrop,320,320))
    for step in range(3):
        body=f'<rect x="2" y="2" width="116" height="78" rx="18" fill="{soft}"/>'
        blocks=[(20,18,0),(47,18,0),(20,45,2),(47,45,0),(74,45,3)] if step==0 else ([(20,18,0),(47,45,2),(20,45,0),(74,45,3)] if step==1 else [(20,18,2),(20,45,2),(47,45,3)])
        for x,y,c in blocks:body+=f'<rect x="{x}" y="{y}" width="22" height="22" rx="6" fill="{colors[c]}"/>'
        if step==0:body+='<path d="M36 33l7 6-3 12" fill="none" stroke="'+ink+'" stroke-width="3" stroke-linecap="round"/>'
        if step==1:body+=f'<path d="M85 14v19m-6-6 6 6 6-6" fill="none" stroke="{ink}" stroke-width="2.5" stroke-linecap="round"/>'
        if step==2:body+=f'<path d="M94 27H76m6-6-6 6 6 6" fill="none" stroke="{ink}" stroke-width="2.5" stroke-linecap="round"/>'
        write(BASE/f'scene/guide{step}_{theme}.svg',svg(body,120,82))
# Logo and companion illustration.
logo='<rect x="1" y="1" width="98" height="98" rx="28" fill="#FFF0CE"/><path d="M22 53h56l-5 30H27Z" fill="#D3A16A"/><path d="M27 60h46M30 71h40" stroke="#EFCD9C" stroke-width="3" stroke-linecap="round"/>'+star(39,37,19,'#F3C664')+star(65,47,17,'#A7C591')+'<g transform="translate(5 2)">'+face(34,37)+'</g>'+face(65,47)+'<path d="M21 80Q13 73 15 64q12 3 13 16" fill="#90B07B"/>'
write(BASE/'scene/logo.svg',svg(logo,100))
# Icons are all repo-native paths; independent ink/on-accent palettes for both themes.
icons={
'back':'<path d="M19 12H5m6-7-7 7 7 7"/>',
'sound':'<path d="m12 4-5 4H3v8h4l5 4ZM16 8q5 4 0 8M19 4q9 8 0 16"/>',
'muted':'<path d="m12 4-5 4H3v8h4l5 4ZM17 9l5 6m0-6-5 6"/>',
'undo':'<path d="M5 4v6h6M5 10a8 8 0 1 1-1 8"/>',
'hint':'<path d="M8 16q0-2-2-5a6 6 0 1 1 12 0q-2 3-2 5ZM9 20h6M10 23h4"/>',
'more':'<circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/>',
'next':'<path d="M4 12h15m-6-7 7 7-7 7"/>',
'check':'<path d="m4 12 5 5L20 6"/>',
'close':'<path d="m6 6 12 12M18 6 6 18"/>',
'restart':'<path d="M20 9A8 8 0 1 0 20 16M20 3v6h-6"/>',
'help':'<circle cx="12" cy="12" r="9"/><path d="M9 9a3 3 0 1 1 5 2l-2 2v1M12 18h.01"/>',
'trophy':'<path d="M8 3h8v8a4 4 0 0 1-8 0ZM8 5H4v3q0 5 5 5m7-8h4v3q0 5-5 5M12 15v6m-4 0h8"/>',
'leaf':'<path d="M4 20Q0 3 21 3q0 19-17 17ZM5 19 16 8"/>',
'spark':'<path d="m12 2 2.5 7.5L22 12l-7.5 2.5L12 22l-2.5-7.5L2 12l7.5-2.5Z"/>',
'expand':'<path d="M9 3H3v6m12-6h6v6M3 15v6h6m12-6v6h-6M3 3l6 6m12-6-6 6M3 21l6-6m12 6-6-6"/>'}
for theme in ['light','dark']:
    tones={'ink':'#F7EEDC' if theme=='dark' else '#443E31','accent':'#BDD59D' if theme=='dark' else '#497143','on':'#243922' if theme=='dark' else '#FFF9EB'}
    for tone,color in tones.items():
        for name,path in icons.items():write(BASE/f'icons/{name}_{tone}_{theme}.svg',svg(f'<g fill="none" stroke="{color}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{path}</g>',24))
# Achievement medals; opaque warm inner field also reads against dark App cards.
for name,kind in [('first',0),('cluster',1),('collector',2)]:
    body='<path d="m33 85-5 33 20-9 16 10 5-34M65 86l5 32 15-9 17 4-9-32" fill="#D8AF74"/><circle cx="64" cy="57" r="49" fill="#FFEDC6" stroke="#CDA566" stroke-width="3"/><circle cx="64" cy="57" r="42" fill="#F8F4DF" stroke="#E4CF9B" stroke-width="1.5"/>'
    if kind==0:body+=star(46,53,21,'#F0C561')+star(81,60,17,'#A7C38F')+face(46,55)+face(81,61)
    elif kind==1:
        for x,y,r,c in [(42,36,9,'#9BC5D2'),(88,35,8,'#AFC68A'),(33,72,7,'#C1A7CE'),(89,77,10,'#EFA590'),(63,57,23,'#F0C561')]:body+=star(x,y,r,c)
        body+=face(63,57)
    else:
        body+='<path d="M41 34h46v10q8 5 8 13v24q-31 11-62 0V57q0-8 8-13Z" fill="#D7E6CD" stroke="#88A07B" stroke-width="2.5"/><rect x="39" y="30" width="50" height="10" rx="5" fill="#D6AD74"/>'
        body+=star(52,62,13,'#F0C561')+star(75,70,12,'#EAA292')+face(52,62)
    write(ROOT/f'app/achievements/ach_star_{name}.svg',svg(body,128))
# Soft marimba-like original synthesis, limited polyphony and no loops.
notes={'tap':[(660,0,.10)],'pop':[(523,0,.15),(784,.035,.16)],'burst':[(523,0,.22),(659,.055,.22),(1047,.10,.24)],'settle':[(392,0,.09)],'undo':[(659,0,.15),(494,.065,.16)],'win':[(523,0,.23),(659,.10,.23),(784,.20,.23),(1047,.30,.32)],'end':[(523,0,.23),(440,.14,.28),(349,.28,.35)]}
for name,seq in notes.items():
    rate=24000;duration=max(s+d for f,s,d in seq)+.025; values=[]
    for i in range(math.ceil(duration*rate)):
        t=i/rate;v=0
        for f,start,d in seq:
            u=t-start
            if 0<=u<=d:
                envelope=min(1,u/.008)*math.exp(-u/d*5)*min(1,(d-u)/.02)
                v+=(math.sin(2*math.pi*f*u)+.15*math.sin(4*math.pi*f*u))*envelope*.24
        values.append(struct.pack('<h',round(max(-.8,min(.8,v))*32767)))
    path=BASE/f'audio/{name}.wav';path.parent.mkdir(parents=True,exist_ok=True)
    with wave.open(str(path),'wb') as out:out.setparams((1,2,rate,0,'NONE','not compressed'));out.writeframes(b''.join(values))
print('Star Pop: original SVG assets and 7 WAV effects generated.')
