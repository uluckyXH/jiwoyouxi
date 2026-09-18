#!/usr/bin/env python3
"""Original local vectors and synthesized short sounds for 方块工坊. No external assets."""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parent.parent / 'entry/src/main/resources/rawfile/gamesNext/blockWorkshop'
for folder in ['icons', 'pieces', 'scene', 'audio']:
    (ROOT / folder).mkdir(parents=True, exist_ok=True)
paths = {
    'back': '<path d="m14 5-7 7 7 7M7 12h14"/>',
    'pause': '<path d="M8 5v14M16 5v14" stroke-width="4"/>',
    'play': '<path d="m8 5 11 7-11 7Z"/>',
    'sound': '<path d="M11 5 6 9H3v6h3l5 4ZM15 8q5 4 0 8M18 5q8 7 0 14"/>',
    'mute': '<path d="M11 5 6 9H3v6h3l5 4ZM16 9l6 6m0-6-6 6"/>',
    'help': '<circle cx="12" cy="12" r="9"/><path d="M9 9a3 3 0 0 1 6 0c0 2-3 2-3 5M12 17v.1"/>',
    'left': '<path d="m13 6-6 6 6 6M7 12h12"/>',
    'right': '<path d="m11 6 6 6-6 6M5 12h12"/>',
    'down': '<path d="m6 10 6 6 6-6M12 4v12"/>',
    'drop': '<path d="m6 9 6 6 6-6M12 3v12M5 20h14"/>',
    'rotate': '<path d="M19 9a8 8 0 1 0 0 8M19 3v6h-6"/>',
    'reverse': '<path d="M5 9a8 8 0 1 1 0 8M5 3v6h6"/>',
    'hold': '<path d="M5 8h14l-4-4M19 16H5l4 4"/>',
    'restart': '<path d="M5 9a8 8 0 1 1-1 7M5 3v6h6"/>',
    'expand': '<path d="M9 3H3v6M15 3h6v6M21 15v6h-6M9 21H3v-6M3 3l6 6m6 6 6 6M21 3l-6 6M9 15l-6 6"/>',
    'trophy': '<path d="M7 3h10v6a5 5 0 0 1-10 0ZM7 5H3v3a4 4 0 0 0 4 4M17 5h4v3a4 4 0 0 1-4 4M12 14v6M8 21h8"/>',
}
for theme in ['light', 'dark']:
    for primary in [False, True]:
        color = ('#25351f' if theme == 'dark' else '#fff9e9') if primary else ('#fff2df' if theme == 'dark' else '#3e352b')
        for name, content in paths.items():
            svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><g fill="none" stroke="{color}" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">{content}</g></svg>\n'
            (ROOT / 'icons' / f'{name}_{"primary_" if primary else ""}{theme}.svg').write_text(svg)
colors = ['#62b9b5', '#e5b95d', '#ad8bc5', '#87ae69', '#d97b7b', '#749bca', '#d59a61']
shapes = [[4,5,6,7], [1,2,5,6], [1,4,5,6], [1,2,4,5], [0,1,5,6], [0,4,5,6], [2,4,5,6]]
for kind, cells in enumerate(shapes):
    xs=[c%4 for c in cells]; ys=[c//4 for c in cells]
    ox=(100-(max(xs)-min(xs)+1)*22)/2; oy=(56-(max(ys)-min(ys)+1)*22)/2
    content=''
    for c in cells:
        x=ox+(c%4-min(xs))*22; y=oy+(c//4-min(ys))*22
        content+=f'<rect x="{x}" y="{y}" width="20" height="20" rx="4" fill="{colors[kind]}"/><path d="M{x+4} {y+4}h12" stroke="#fff" opacity=".35" stroke-linecap="round" stroke-width="2"/>'
    (ROOT/'pieces'/f'{kind}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 56">{content}</svg>\n')
# Static workshop scenery is rasterized by the native Image node once, outside the game clock.
def svg_file(name, width, height, body):
    (ROOT/'scene'/f'{name}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" preserveAspectRatio="none">{body}</svg>\n')

def block_group(x, y, unit, cells, fill, edge, rotate=0):
    body=f'<g transform="translate({x} {y}) rotate({rotate})">'
    for cell in cells:
        xx=cell%4*unit; yy=cell//4*unit
        body+=f'<rect x="{xx}" y="{yy+3}" width="{unit-3}" height="{unit-3}" rx="5" fill="{edge}"/><rect x="{xx}" y="{yy}" width="{unit-3}" height="{unit-4}" rx="5" fill="{fill}"/><path d="M{xx+5} {yy+5}h{unit-13}" stroke="#fff6db" stroke-width="2" stroke-linecap="round" opacity=".35"/>'
    return body+'</g>'

def plant(x,y,scale,leaf,pot,ink):
    return f'''<g transform="translate({x} {y}) scale({scale})"><path d="M0 0q-5-35 7-68M0-16q-22-14-26-34M4-32q19-16 25-36" fill="none" stroke="{ink}" stroke-width="3" stroke-linecap="round"/><g fill="{leaf}"><path d="M-2-26Q-36-22-34-49Q-6-54-2-26Z"/><path d="M4-39Q-5-69 11-81Q30-55 4-39Z"/><path d="M7-19Q37-18 38-47Q9-50 7-19Z"/></g><path d="M-24-1h49l-7 43h-34Z" fill="{pot}"/><rect x="-28" y="-7" width="57" height="10" rx="4" fill="{ink}"/><path d="M-15 7h31M-13 17h28" stroke="#fff4d8" opacity=".28" stroke-linecap="round" stroke-width="3"/></g>'''

for theme in ['light','dark']:
    dark=theme=='dark'
    bg='#17221d' if dark else '#fff3df'
    panel='#25382b' if dark else '#e7e8cc'
    paper='#233127' if dark else '#f7f2df'
    grain='#425141' if dark else '#bfae88'
    wood='#6b7050' if dark else '#d8b78a'
    wood_dark='#414c36' if dark else '#b89263'
    gold='#d3b273' if dark else '#bb884c'
    cream='#f3e4bd' if dark else '#fffaf0'
    green='#6b8b58' if dark else '#86a578'
    coral='#9c705d' if dark else '#dbaa87'
    # Rich framing stays on the periphery; the actual playing field remains readable.
    for wide in [False,True]:
        w,h=(1400,800) if wide else (800,1500)
        dots=' '.join(f'M6 {y}H{w}' for y in range(6,h,32))
        content=f'''<defs><linearGradient id="paper" x2="0" y2="1"><stop stop-color="{bg}"/><stop offset="1" stop-color="{panel}"/></linearGradient></defs><rect width="{w}" height="{h}" fill="url(#paper)"/><path d="{dots}" fill="none" stroke="{grain}" stroke-width="2" stroke-dasharray=".1 32" stroke-linecap="round" opacity=".22"/><path d="M0 168Q{w/2} 213 {w} 142V0H0Z" fill="{panel}" opacity=".75"/><path d="M0 182Q{w/2} 227 {w} 156" fill="none" stroke="{grain}" opacity=".2" stroke-width="2"/><path d="M0 {h-205}Q{w/2} {h-245} {w} {h-185}V{h}H0Z" fill="{wood}" opacity=".26"/><path d="M0 {h-180}H{w}M0 {h-84}H{w}" stroke="{wood_dark}" opacity=".18" stroke-width="2"/>'''
        for x in [42,w-118]:
            content+=f'<path d="M{x} 0v80" stroke="{gold}" stroke-width="2"/><circle cx="{x}" cy="78" r="4" fill="{gold}"/>'
        content+=block_group(19,81,24,[0,4,5,6],green,wood_dark,-12)
        content+=block_group(w-131,74,24,[1,4,5,6],coral,wood_dark,12)
        content+=f'<rect x="-30" y="{h*.53}" width="154" height="12" rx="6" fill="{wood}"/><rect x="{w-150}" y="{h*.7}" width="184" height="12" rx="6" fill="{wood}"/>'
        content+=plant(40,h*.53-45,1.1,green,coral,wood_dark)
        content+=plant(w-40,h*.7-40,.95,green,coral,wood_dark)
        content+=block_group(-14,h-134,32,[1,2,5,6],coral,wood_dark,-8)
        content+=block_group(w-136,h-109,30,[0,1,5,6],green,wood_dark,8)
        content+=f'<g fill="{gold}" opacity=".65"><path d="M{w-68} 284l5 10 11 2-8 8 1 11-9-5-10 5 2-11-8-8 11-2Z"/><circle cx="28" cy="345" r="4"/><circle cx="{w-24}" cy="{h-280}" r="4"/></g>'
        svg_file(f'workshop_{"wide_" if wide else ""}{theme}',w,h,content)
    # Tiny in-game identity: a block-built chick; the original home icon stays untouched.
    mascot=f'''<rect x="3" y="5" width="58" height="54" rx="20" fill="{panel}"/><path d="M19 20h12v-9h14v12h9v22H20Z" fill="{gold}"/><path d="M20 23h26v22H20Z" fill="{cream}"/><circle cx="37" cy="30" r="2.1" fill="{wood_dark}"/><path d="m44 33 9 4-9 4Z" fill="{coral}"/><path d="M24 45v6m15-6v6" stroke="{wood_dark}" stroke-width="3" stroke-linecap="round"/><path d="M11 17h6M14 14v6" stroke="{gold}" stroke-width="2" stroke-linecap="round"/>'''
    svg_file(f'emblem_{theme}',64,64,mascot)
    # Beveled wood frame with inset brass studs and calibrated edge marks.
    frame=f'''<defs><linearGradient id="rim" x2="1" y2="1"><stop stop-color="{wood}"/><stop offset=".55" stop-color="{wood_dark}"/><stop offset="1" stop-color="{wood}"/></linearGradient></defs><rect x="1" y="1" width="214" height="414" rx="18" fill="{wood_dark}"/><rect x="1" y="1" width="214" height="410" rx="17" fill="url(#rim)"/><rect x="6" y="6" width="204" height="404" rx="12" fill="{paper}" stroke="{cream}" stroke-opacity=".35"/><path d="M22 4h70m25 0h68M27 412h66m26 0h60" fill="none" stroke="{cream}" opacity=".2"/>'''
    for x,y in [(6,16),(210,16),(6,398),(210,398)]:
        frame+=f'<circle cx="{x}" cy="{y}" r="2.1" fill="{gold}"/><path d="m{x-1} {y+1} 2-2" stroke="{wood_dark}" stroke-width=".8"/>'
    for yy in range(44,382,16):
        frame+=f'<path d="M3 {yy}h2m206 0h2" stroke="{cream}" opacity=".24" stroke-width=".7"/>'
    svg_file(f'frame_{theme}',216,416,frame)
    grid_path=' '.join(f'M{x} 0V400' for x in range(0,201,20))+' '+' '.join(f'M0 {y}H200' for y in range(0,401,20))
    # The current UI uses native solid surfaces. Only the quiet grid is painted by this Image.
    grid=f'<path d="{grid_path}" fill="none" stroke="{"#34372e" if dark else "#eee8da"}" stroke-width=".5"/>'
    svg_file(f'field_{theme}',200,400,grid)
    fold_ink='#b6d39a' if dark else '#527342'
    fold_surface='#303126' if dark else '#eeeeda'
    fold_line='#716d59' if dark else '#ccbea1'
    unfold=f'''<rect x="10" y="28" width="42" height="64" rx="10" fill="{fold_surface}" stroke="{fold_line}" stroke-width="2"/><path d="M26 83h10" stroke="{fold_line}" stroke-width="2" stroke-linecap="round"/><path d="M67 59h29m-7-7 7 7-7 7" fill="none" stroke="{fold_ink}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/><rect x="112" y="15" width="95" height="88" rx="13" fill="{fold_surface}" stroke="{fold_ink}" stroke-width="2.5"/><path d="M160 20v78" stroke="{fold_line}" stroke-dasharray="3 5" stroke-width="1.5"/><g fill="{fold_ink}"><rect x="130" y="42" width="13" height="13" rx="3"/><rect x="130" y="57" width="13" height="13" rx="3"/><rect x="145" y="57" width="13" height="13" rx="3"/><rect x="160" y="57" width="13" height="13" rx="3"/></g>'''
    svg_file(f'unfold_{theme}',220,120,unfold)
    # Light ambience for the simplified UI, drawn at fixed aspect ratio in available margins.
    wash_base='#191e17' if dark else '#f8ecd5'
    wash_inner='#20251c' if dark else '#f1e5ca'
    outline_ink='#414a35' if dark else '#ded0b1'
    svg_file(f'wash_{theme}',400,400,f'<path d="M0 97Q107 19 230 118T400 276V400H0Z" fill="{wash_base}"/><path d="M0 229Q131 143 252 288T400 375V400H0Z" fill="{wash_inner}"/>')
    outline=f'<g fill="none" stroke="{outline_ink}" stroke-width="1.4">'
    for xx,yy in [(40,15),(15,40),(40,40),(65,40)]:
        outline+=f'<rect x="{xx}" y="{yy}" width="22" height="22" rx="5"/>'
    outline+=f'<path d="M14 82h6m-3-3v6" stroke-linecap="round"/><circle cx="83" cy="88" r="2"/></g>'
    svg_file(f'outline_{theme}',104,104,outline)
    # Whole-window ambience: every bottom edge returns to the app surface. No cropped patch ends behind buttons.
    garden_bg='#101110' if dark else '#fff4e4'
    garden_sun='#24251b' if dark else '#ffedcf'
    garden_mist='#192219' if dark else '#edf0db'
    garden_ground='#20291d' if dark else '#e5ebd1'
    garden=f'''<rect width="1000" height="1600" fill="{garden_bg}"/>
      <path d="M685 0C630 115 682 274 821 292C930 308 1000 218 1000 168V0Z" fill="{garden_sun}"/>
      <path d="M0 1110C115 1094 180 1163 214 1259C248 1350 443 1332 559 1439C620 1495 396 1564 161 1543C62 1533 0 1506 0 1460Z" fill="{garden_mist}"/>
      <path d="M1000 1322C913 1290 822 1335 782 1406C738 1484 807 1540 899 1551C949 1557 987 1546 1000 1530Z" fill="{garden_ground}"/>
      <g fill="{outline_ink}"><circle cx="72" cy="512" r="3"/><circle cx="923" cy="664" r="3"/><circle cx="113" cy="1490" r="2.5"/></g>'''
    svg_file(f'garden_{theme}',1000,1600,garden)
    sprig_leaf='#536044' if dark else '#bcca9f'
    sprig_line='#455039' if dark else '#b3c195'
    sprig=f'''<path d="M40 153C50 128 29 103 40 81S50 41 43 21" fill="none" stroke="{sprig_line}" stroke-width="2" stroke-linecap="round"/>
      <g fill="{sprig_leaf}"><path d="M43 68C21 65 13 48 19 35C38 37 47 52 43 68Z"/><path d="M39 94C41 68 56 56 71 60C72 80 58 94 39 94Z"/><path d="M43 124C19 121 8 109 12 94C34 93 45 109 43 124Z"/></g>'''
    svg_file(f'sprig_{theme}',84,164,sprig)
    bench_wood='#877350' if dark else '#c79f6c'
    bench_edge='#514b37' if dark else '#d8bd91'
    bench_green='#8aab77' if dark else '#98b58a'
    bench_gold='#c8ad74' if dark else '#e0bf7e'
    bench_lilac='#a797b8' if dark else '#beacd0'
    bench=f'''<ellipse cx="65" cy="153" rx="51" ry="5" fill="{garden_mist}"/>
      <path d="M24 140v12m82-12v12" stroke="{bench_wood}" stroke-width="5" stroke-linecap="round"/>
      <rect x="11" y="133" width="108" height="9" rx="4.5" fill="{bench_wood}"/>
      <path d="M22 136h30m16 0h38" stroke="{bench_edge}" stroke-width="1.5" stroke-linecap="round"/>
      <path d="M104 80q-9-17 1-39m-2 14q-20 0-19-14 17-2 19 14Zm-1 12q15-18 23-9-3 14-23 9Z" fill="{sprig_leaf}" stroke="{sprig_line}" stroke-width="1.5" stroke-linejoin="round"/>'''
    bench+=block_group(22,95,19,[0,4,5,6],bench_green,bench_edge)
    bench+=block_group(77,94,19,[0,1,4,5],bench_gold,bench_edge)
    bench+=block_group(29,57,19,[1,4,5,6],bench_lilac,bench_edge)
    svg_file(f'workbench_{theme}',130,164,bench)
    hud=f'<rect width="400" height="90" rx="20" fill="{paper}"/><path d="M302-18q-67 58 18 122h80V0Z" fill="{panel}"/><path d="M306-16q-67 58 18 122" fill="none" stroke="{gold}" stroke-width="1.2" opacity=".4"/>'
    hud+=block_group(10,56,14,[0,1,5,6],green,wood_dark,-12).replace('<g ', '<g opacity=".15" ',1)
    hud+=f'<circle cx="375" cy="16" r="15" fill="none" stroke="{gold}" opacity=".14"/><circle cx="375" cy="16" r="23" fill="none" stroke="{gold}" opacity=".12"/>'
    svg_file(f'hud_{theme}',400,90,hud)
    for role in ['move','turn','primary']:
        face=('#b7cf96' if dark else '#547348') if role=='primary' else (('#4a4235' if dark else '#f4e6cb') if role=='turn' else ('#354336' if dark else '#fff8e8'))
        lip=('#617b4c' if dark else '#385639') if role=='primary' else (('#2e342a' if dark else '#c7b48c') if role=='turn' else ('#222f24' if dark else '#cdc3a4'))
        glint='#f9f0d5' if role!='primary' or dark else '#b3cb98'
        body=f'''<rect x="1" y="3" width="118" height="56" rx="17" fill="{lip}"/><rect x="1" y="1" width="118" height="53" rx="17" fill="{face}"/><path d="M16 4h87" stroke="{glint}" stroke-width="1.4" opacity=".36" stroke-linecap="round"/><path d="M14 52h92" stroke="{lip}" stroke-width="1.2" opacity=".25"/><g fill="{lip}" opacity=".38"><circle cx="103" cy="12" r="1.2"/><circle cx="108" cy="12" r="1.2"/><circle cx="103" cy="17" r="1.2"/><circle cx="108" cy="17" r="1.2"/></g>'''
        svg_file(f'key_{role}_{theme}',120,60,body)
    for role in ['hold','queue']:
        body=f'<rect x="1" y="1" width="98" height="76" rx="15" fill="{paper}" stroke="{grain}" stroke-opacity=".45"/><rect x="5" y="23" width="90" height="49" rx="11" fill="{panel}"/><path d="M14 2h25" stroke="{green if role=="hold" else gold}" stroke-width="3" stroke-linecap="round"/><path d="M13 29h8m-8 0v8m66 29h8v-8" fill="none" stroke="{grain}" opacity=".3" stroke-width="1"/>'
        svg_file(f'slot_{role}_{theme}',100,78,body)
    controls=f'<rect x="1" y="1" width="358" height="124" rx="24" fill="{panel}" stroke="{grain}" stroke-opacity=".35"/><path d="M20 4h42m236 0h42M20 122h48m224 0h48" stroke="{cream}" opacity=".2" stroke-linecap="round"/>'
    svg_file(f'console_{theme}',360,126,controls)
    poster=f'<path d="M34 28q50-38 105-9t47 75H23Z" fill="{panel}"/><path d="M16 103h188" stroke="{wood_dark}" stroke-width="9" stroke-linecap="round"/>'
    poster+=block_group(32,40,20,[0,4,5,6],green,wood_dark,-8)
    poster+=block_group(102,34,20,[1,2,5,6],gold,wood_dark,8)
    poster+=plant(186,72,.48,green,coral,wood_dark)
    poster+=f'<path d="m101 8 3 6 7 1-5 5 1 7-6-4-6 4 1-7-5-5 7-1Z" fill="{gold}"/>'
    svg_file(f'poster_{theme}',220,118,poster)
# Sine/triangle-like warm chimes with attack/release envelopes; 22.05 kHz mono, < 0.55 s each.
effects={
 'move':([420],.045), 'rotate':([520,690],.09), 'hold':([690,520],.12),
 'drop':([190,110],.13), 'lock':([240],.065), 'clear':([523,659,784],.24),
 'four':([523,659,784,1047],.42), 'level':([659,784,1047],.36),
 'finish':([392,330,262],.48), 'tap':([610],.06)
}
rate=22050
for name,(notes,duration) in effects.items():
    frames=[]
    for i in range(int(rate*duration)):
        t=i/rate; part=duration/len(notes); ni=min(len(notes)-1,int(t/part)); local=t-ni*part
        env=min(1,local/.006)*max(0,1-local/part)**1.7
        f=notes[ni]; value=(math.sin(2*math.pi*f*local)+.15*math.sin(4*math.pi*f*local))*.3*env
        frames.append(struct.pack('<h',int(value*32767)))
    with wave.open(str(ROOT/'audio'/f'{name}.wav'),'wb') as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(rate); out.writeframes(b''.join(frames))
print('Generated',len(list(ROOT.rglob('*.svg'))),'SVGs and',len(effects),'WAVs')
