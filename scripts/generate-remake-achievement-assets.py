#!/usr/bin/env python3
"""Draw 18 remake-game and four collection badges as font-free SVGs.

Stable file names are storage/registry contracts, not the current thresholds.
Run with Python 3; no image tools or third-party dependencies are required.
"""
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'entry/src/main/resources/rawfile/app/achievements'
OUTLINE = '#795A43'
PAPER = '#FFF5DE'
GREEN = '#35785E'
GOLD = '#EDBF6C'
CORAL = '#DE8D76'
BLUE = '#8CB6CB'


def path(d, fill='none', stroke=None, width=None, extra=''):
    attrs = f' fill="{fill}"'
    if stroke is not None:
        attrs += f' stroke="{stroke}"'
    if width is not None:
        attrs += f' stroke-width="{width}"'
    return f'<path d="{d}"{attrs}{(" " + extra) if extra else ""}/>'


def rect(x, y, w, h, fill, r=7, extra=''):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" {extra}/>'


def circle(x, y, r, fill, extra=''):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" {extra}/>'


def group(body, transform='', extra=''):
    return f'<g transform="{transform}" {extra}>{body}</g>' if transform else f'<g {extra}>{body}</g>'


def spark(x, y, size=8):
    return path(f'M{x} {y-size}Q{x+1} {y-1} {x+size} {y}Q{x+1} {y+1} {x} {y+size}Q{x-1} {y+1} {x-size} {y}Q{x-1} {y-1} {x} {y-size}Z', GOLD, '#A57C46', 2)


def leaf(x, y, scale=1, angle=0):
    return group(path('M0 17C-3 5 6-3 20-3C19 10 12 20 0 17Z', '#ADC892', '#62866B', 2.5) +
                 path('M-2 21L13 3', stroke='#62866B', width=2), f'translate({x} {y}) rotate({angle}) scale({scale})')


def check(x, y, r=13):
    return circle(x, y, r, GREEN, 'stroke="#D8E5B9" stroke-width="2.5"') + path(
        f'M{x-r*.48} {y}l{r*.32} {r*.32} {r*.65} {-r*.7}', stroke=PAPER, width=3.5)


def base(x=17, y=100, w=94):
    return rect(x, y, w, 12, '#D4AE78', 6) + path(f'M{x+9} {y+4}h{w-18}', stroke='#F4DDA8', width=2.5)


# Numerals are deliberate vector strokes, with no SVG text or font dependency.
DIGITS = {
    '0': 'M9 2C3 2 1 7 1 14S3 26 9 26S17 21 17 14S15 2 9 2Z',
    '1': 'M3 7L10 2V26M3 26H17',
    '2': 'M1 7C2 0 17 0 17 7C17 12 10 16 2 25H18',
    '4': 'M14 26V2L1 18H18',
    '5': 'M17 2H3L2 13C8 10 17 11 17 19C17 28 5 28 1 24',
    '6': 'M16 3C4-2 0 9 1 19C2 29 17 29 17 19C17 10 5 10 1 17',
    '8': 'M9 2C-1 2-1 13 9 13C19 13 19 2 9 2ZM9 13C-2 13-2 26 9 26C20 26 20 13 9 13Z'
}


def digits(value, x, y, max_width=64, height=28, color=OUTLINE):
    text = str(value)
    width = len(text) * 24 - 6
    sx = min(1, max_width / width)
    sy = height / 28
    body = ''.join(group(path(DIGITS[d], stroke=color, width=4.4), f'translate({i*24} 0)') for i, d in enumerate(text))
    return group(body, f'translate({x-width*sx/2:g} {y}) scale({sx:g} {sy:g})')


def write(name, title, detail, body):
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">\n'
           f'  <title>{title}</title>\n  <desc>{detail}</desc>\n'
           f'  <g stroke="{OUTLINE}" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round">\n'
           f'    {body}\n  </g>\n</svg>\n')
    ET.fromstring(svg)
    (DEST / name).write_text(svg, encoding='utf-8')


# Garden Mine: safe paving, a garden clock, and corrected/all-complete flags.
body = rect(14, 34, 100, 76, '#BBCC9C', 13)
for row in range(2):
    for col in range(3):
        body += rect(22 + col*29, 44 + row*29, 25, 25, PAPER if (row, col) in [(1,0),(1,1),(0,1)] else '#91B27F', 5,
                     'stroke="#71916C" stroke-width="2.2"')
body += path('M34 85H63V56', stroke='#D5AD68', width=5)
body += check(93, 87, 15) + leaf(50, 18, .85, -14) + spark(100, 25, 7)
write('ach_minesweeper_first_clear.svg', '平安出窝', '庭院石砖中的安全小径与绿色勾记，打开全部安全格。', body)

body = rect(16, 64, 72, 45, '#ACC392', 10)
for x in [24, 43, 62]:
    body += rect(x, 74, 15, 25, '#E8EDCF', 4, 'stroke="#76916C" stroke-width="2"')
body += path('M14 44H28M10 56H23', stroke='#B69B69', width=3)
body += rect(68, 14, 18, 9, '#D6B478', 3) + circle(77, 51, 29, '#F5D99C') + circle(77, 51, 23, PAPER, 'stroke="#CCB787" stroke-width="2"')
body += path('M77 32V51L89 59', stroke=GREEN, width=4) + circle(77, 51, 3, GREEN, 'stroke="none"')
body += path('M77 28V31M97 51H100M77 71V74M54 51H57', stroke='#AF9A71', width=2.2)
body += leaf(91, 93, .8, -17)
write('ach_minesweeper_quick_clear.svg', '迅捷排雷', '暖色时钟与庭院格子，任意难度三分钟内通关。', body)

body = base(y=97)
for x, top, color in [(28, 42, '#A6C690'), (63, 21, '#70A382'), (96, 40, '#91BB91')]:
    body += rect(x-13, 77, 27, 24, '#DDE5BF', 5, 'stroke="#81976E" stroke-width="2.5"')
    body += path(f'M{x} 86V{top}', stroke='#6B9171', width=3.2)
    body += path(f'M{x} {top+2}C{x+8} {top-3} {x+11} {top+10} {x+24} {top+3}V{top+20}C{x+12} {top+26} {x+8} {top+13} {x} {top+18}Z', color, GREEN, 2.4)
body += check(64, 99, 14) + leaf(11, 56, .62, -20)
write('ach_minesweeper_perfect_flags.svg', '旗开得胜', '三面绿色庭院旗与完成勾记，任意难度标出全部地雷，可撤旗改正。', body)

# Glow 2048: tiles read 256 / 512 / 1024; the final badge is a glow, not a 2048 crown.
def glow_tile(x, y, w, h, fill, value):
    return (rect(x, y+5, w, h, '#BC965D', 13) + rect(x, y, w, h, fill, 13) +
            path(f'M{x+9} {y+23}V{y+14}Q{x+9} {y+8} {x+16} {y+8}H{x+w-24}', stroke='#FFF1C9', width=3) +
            path(f'M{x+w-10} {y+h-19}Q{x+w-10} {y+h-8} {x+w-24} {y+h-8}H{x+15}', stroke='#B68F55', width=2, extra='stroke-opacity=".45"') +
            # The wall adds its own unlock tick in the lower-right corner.
            # Keep the goal numeral above that overlay, including at 48 vp.
            digits(value, x+w/2-5, y+11, w-22, 24, '#605137'))

body = rect(15, 14, 26, 22, '#F4E7C5', 7) + rect(87, 14, 26, 22, '#F4E7C5', 7)
body += path('M47 21L59 30M81 21L69 30M57 23L59 30L51 30M71 23L69 30L77 30', stroke='#AE8954', width=3)
body += glow_tile(24, 36, 78, 72, '#F2CD81', 256) + spark(111, 67, 6)
write('ach_chicken2048_reach_256.svg', '合成小能手', '两块向内合并的方块，主方块以矢量笔画标出256。', body)

body = rect(19, 23, 79, 78, '#E9D1A1', 14, 'transform="rotate(-9 60 62)"')
body += glow_tile(29, 33, 78, 72, '#EDBC76', 512) + leaf(11, 84, .8, -21) + spark(98, 17, 6)
write('ach_chicken2048_reach_1024.svg', '叠数渐佳', '暖金叠起的方块与初生叶片，主方块以矢量笔画标出512。', body)

body = path('M14 82V58A50 50 0 0 1 114 58V82', stroke='#CFBA7F', width=3)
body += path('M64 9V15M28 22L32 27M100 22L96 27', stroke='#C4A163', width=3)
body += glow_tile(20, 34, 88, 72, '#E8AC76', 1024) + spark(109, 103, 8) + spark(16, 25, 5)
write('ach_chicken2048_reach_2048.svg', '千格暖光', '拱形暖光照亮1024方块，无2048字样或终点皇冠。', body)

# Warm Freecell: actual four suits, one deliberate transfer, and a gentle hourglass.
SUITS = {
    'heart': 'M12 23L3 14C-6 5 7-3 12 6C17-3 30 5 21 14Z',
    'diamond': 'M12 0L23 13L12 26L1 13Z',
    'spade': 'M12 0C7 6-2 12 2 19C4 24 10 21 12 18L8 27H16L12 18C14 21 20 24 22 19C26 12 17 6 12 0Z',
    'club': 'M12 18C6 25-3 18 2 12C3 10 6 9 8 10C1 0 22-4 18 8L16 10C29 5 28 25 16 20L12 18L17 27H7Z'
}

def suit(kind, x, y, scale=1):
    return group(path(SUITS[kind], CORAL if kind in ['heart', 'diamond'] else GREEN, 'none'), f'translate({x} {y}) scale({scale})')

body = base(15, 101, 98)
for kind, x, y in [('spade',20,24), ('heart',69,24), ('diamond',20,65), ('club',69,65)]:
    body += rect(x, y+3, 39, 35, '#D7D5B4', 6, 'stroke="none"') + rect(x, y, 39, 35, PAPER, 6)
    body += suit(kind, x+10, y+6, .8)
body += check(103, 23, 12)
write('ach_freecell_complete_board.svg', '纸牌归位', '四种纸牌花色整齐归入暖木牌架，全部归位即可获得。', body)

body = rect(18, 44, 45, 63, '#C2D2AB', 8, 'transform="rotate(-9 40 75)"')
body += rect(30, 36, 45, 65, PAPER, 8) + suit('heart', 43, 59, .9)
body += rect(84, 49, 27, 45, '#E4EACB', 6, 'stroke="#719575" stroke-width="2.8" stroke-dasharray="5 4"')
body += path('M44 25C61 10 94 17 99 36M91 31L99 37L104 29', stroke='#5D9274', width=4)
body += check(95, 101, 14) + path('M39 47H49', stroke='#D5BD8B', width=2)
write('ach_freecell_efficient_win.svg', '精打细算', '一张牌沿简洁弧线移向空位，200步内通关，允许辅助操作。', body)

body = rect(19, 29, 44, 65, '#C4D5B0', 8, 'transform="rotate(-13 41 63)"') + suit('heart', 27, 44, .74)
body += rect(76, 43, 33, 50, PAPER, 7, 'transform="rotate(12 92 68)"') + suit('club', 82, 54, .74)
body += path('M43 36H87C87 55 73 55 69 66C73 75 87 81 87 101H43C43 80 56 76 61 66C57 55 43 54 43 36Z', '#FFF1CD', '#8B7655', 3)
body += path('M50 45H80C77 53 68 56 65 61C62 56 53 52 50 45ZM50 94C55 82 62 77 65 73C68 78 75 81 80 94Z', GOLD, 'none')
body += path('M65 63V69', stroke='#BC8E4C', width=2.8)
body += rect(39, 29, 52, 10, '#8FAF83', 4) + rect(39, 100, 52, 10, '#8FAF83', 4) + spark(100, 26, 7)
write('ach_freecell_quick_win.svg', '疾速清台', '暖木沙漏与红黑花色，十五分钟内轻快整理完牌桌。', body)

# Block Workshop: one cleared row, then five and ten lines, without old level crowns.
body = rect(14, 83, 100, 24, '#D6D7B6', 7)
for x, color in zip([17,42,67,92], [BLUE,'#A7C68D',CORAL,GOLD]):
    body += rect(x, 49, 19, 29, color, 5)
    body += path(f'M{x+4} 61V55H{x+12}', stroke=PAPER, width=2, extra='stroke-opacity=".75"')
body += path('M10 77H117', stroke='#FFF3C5', width=6) + path('M16 92H107', stroke='#A3AF82', width=2.5)
body += spark(65, 37, 9) + path('M14 43L20 47M112 43L107 47', stroke='#C2A467', width=3)
write('ach_tetris_first_tetris.svg', '第一行光', '仅一行圆角方块被暖光清除，明确不再表示四消。', body)

body = rect(16, 23, 80, 84, '#F3E9CC', 12)
for i, color in enumerate([BLUE,'#AAC592',CORAL,GOLD,'#9DBDAD']):
    body += rect(24, 32+i*13, 59, 9, color, 3, 'stroke-width="2"')
    body += path(f'M40 {34+i*13}v5M60 {34+i*13}v5', stroke='#FFF4D9', width=1.5)
body += circle(95, 45, 20, '#F4CF83') + digits(5, 95, 31, 20, 27) + spark(103, 15, 6)
write('ach_tetris_twenty_lines.svg', '清行不停', '五条柔和彩色消行记录和矢量数字5，表示单局累计五行。', body)

body = rect(17, 21, 94, 83, '#EEE4C6', 13)
for row, color in enumerate([BLUE,'#AFC997',CORAL,GOLD,'#9FBEA9']):
    for col in range(2):
        body += rect(25+col*41, 55+row*10, 33, 7, color, 3, 'stroke-width="1.8"')
body += rect(38, 17, 69, 36, '#F4CD7D', 12) + digits(10, 73, 23, 40, 23) + spark(17, 101, 7)
write('ach_tetris_level_three.svg', '方块进阶', '十条分列的消行记录与矢量数字10，无等级数字或皇冠。', body)

# Courtyard Arena: use the remake's blue rock, coral scissors and green fabric.
def symbol(kind, x, y, scale=1):
    if kind == 0:
        body = path('M1 18L6 6L18 1L28 7L32 20L22 29L7 28Z', BLUE, '#547A88', 2.2)
        body += path('M6 6L12 14L22 10L28 7M12 14L7 24M22 10L26 20', stroke='#DAE6DC', width=2)
    elif kind == 1:
        body = path('M13 17L7 2M19 17L27 2', stroke='#C2B597', width=5)
        body += path('M13 17L7 2M19 17L27 2', stroke='#7D7258', width=1.7)
        body += circle(8, 23, 7, CORAL, 'stroke="#A35F48" stroke-width="2"') + circle(24, 23, 7, CORAL, 'stroke="#A35F48" stroke-width="2"')
        body += circle(8, 23, 3, PAPER, 'stroke="none"') + circle(24, 23, 3, PAPER, 'stroke="none"') + circle(16, 16, 3, GOLD, 'stroke-width="1.8"')
    else:
        body = path('M3 3Q16 0 28 4L31 27Q17 32 4 28L1 8Z', '#ACCB92', '#63866B', 2.2)
        body += path('M7 7L9 24L25 24', stroke='#E4ECCA', width=2)
        body += path('M12 8L14 22M17 8L19 22', stroke='#729E7A', width=1.2, extra='stroke-dasharray="2 3"')
    return group(body, f'translate({x} {y}) scale({scale})')

body = path('M31 54C37 37 84 31 102 64M100 89C83 110 43 111 24 90M19 77C17 68 20 60 25 53', stroke='#B7C394', width=4)
for kind, x, y in [(0,64,36),(1,33,85),(2,96,85)]:
    body += circle(x, y, 23, PAPER, 'stroke="#B6B68B" stroke-width="2.5"') + symbol(kind, x-16, y-16, 1)
body += leaf(14, 20, .64, -13) + spark(105, 26, 6)
write('ach_rps_battle_first_battle.svg', '庭院初见', '庭院里相遇的蓝色石头、珊瑚剪刀和绿色布，完成一局即可获得。', body)

body = path('M37 37H20V49Q20 68 41 69M91 37H108V49Q108 68 87 69', '#EBCD8B', OUTLINE, 3)
body += path('M37 24H91V53C91 69 77 78 64 78S37 69 37 53Z', '#F2CB78')
body += path('M45 32V48Q45 63 56 66', stroke='#FFF0B7', width=3)
body += path('M64 78V96', stroke=OUTLINE, width=9) + path('M64 79V94', stroke=GOLD, width=5)
body += rect(40, 96, 48, 13, '#DBB477', 5) + spark(64, 49, 11)
for x, color in [(45,BLUE),(64,CORAL),(83,'#A8C591')]:
    body += circle(x, 102, 4, color, 'stroke="none"')
body += leaf(14, 78, .74, -30) + leaf(102, 83, .65, 14)
write('ach_rps_battle_supporter_wins.svg', '小队首胜', '带三色队伍印记的庭院奖杯，表示自己的小队赢得一局，不再使用押注旗帜。', body)

body = path('M34 27C60 7 97 23 106 47M101 83C86 111 46 119 24 94M18 66C14 56 18 44 24 37', stroke='#D1AC65', width=5)
body += path('M98 43L107 49L109 38M29 87L22 96L34 97M16 40L25 35L28 46', stroke='#AA8551', width=3)
for kind, x, y in [(0,37,45),(1,86,59),(2,56,94)]:
    body += circle(x, y, 19, PAPER, 'stroke="#B7B18A" stroke-width="2"') + symbol(kind, x-13, y-13, .82)
body += spark(81, 18, 5) + spark(110, 104, 6)
write('ach_rps_battle_conversion_storm.svg', '热闹开场', '三种庭院棋子沿循环箭头转阵，轻快星点呼应十二次转阵。', body)

# Fruit Market: the real level-six and level-seven green skins; no giant-fruit crown.
def melon(cx, cy, r, small=False):
    skin = '#A6CA78' if small else '#6BA681'
    stripe = '#709754' if small else '#397754'
    body = circle(cx, cy, r, skin, f'stroke="{stripe}" stroke-width="3"')
    for offset in [-.48, 0, .48]:
        x = cx + offset*r
        body += path(f'M{x:g} {cy-r*.87:g}C{x-r*.3:g} {cy-r*.35:g} {x+r*.28:g} {cy+r*.27:g} {x:g} {cy+r*.88:g}', stroke=stripe, width=4)
    body += path(f'M{cx-r*.61:g} {cy-r*.4:g}Q{cx-r*.48:g} {cy-r*.65:g} {cx-r*.2:g} {cy-r*.72:g}', stroke='#EDF5C5', width=3)
    body += circle(cx-r*.25, cy+r*.1, 2.4, '#405440', 'stroke="none"') + circle(cx+r*.25, cy+r*.1, 2.4, '#405440', 'stroke="none"')
    body += path(f'M{cx-5} {cy+r*.3:g}Q{cx} {cy+r*.42:g} {cx+5} {cy+r*.3:g}', stroke='#405440', width=2)
    body += path(f'M{cx} {cy-r+9}Q{cx-4} {cy-r-2} {cx+3} {cy-r-8}', stroke='#A27A4C', width=3)
    body += leaf(cx+2, cy-r-5, .65, -10)
    return body

body = path('M27 48V104M101 48V104', stroke='#A07E52', width=5)
body += path('M20 46L28 25H100L108 46Z', '#F2D9A5')
body += path('M36 25H50L47 46H31ZM76 25H90L96 46H79Z', CORAL, 'none')
body += path('M20 46Q27 60 35 46Q44 60 53 46Q64 60 75 46Q85 60 93 46Q102 60 108 46', '#F2D9A5', OUTLINE, 3)
body += rect(18, 88, 92, 16, '#DBB37A', 5)
for x, y in [(33,73),(44,72),(39,82)]:
    body += circle(x, y, 7, '#B095BD', 'stroke="#857397" stroke-width="2"')
body += circle(65, 75, 13, '#E8AF66', 'stroke="#B48751" stroke-width="2.5"') + leaf(61, 57, .52, -10)
body += circle(97, 98, 17, GOLD) + spark(97, 98, 8) + path('M28 110H76', stroke='#AC8A5C', width=2.5)
write('ach_suika_score_600.svg', '瓜摊开张', '暖色条纹小摊、葡萄橘子与第一枚金币，表示一百分的开张小目标。', body)

body = path('M22 99Q63 114 104 99', stroke='#C6B380', width=5)
body += melon(64, 68, 34, True) + leaf(21, 90, .62, -40) + spark(105, 47, 6)
write('ach_suika_make_watermelon.svg', '小瓜到手', '浅绿色小西瓜、圆润笑脸和一片嫩叶，对应重构版等级六的水果。', body)

body = '<ellipse cx="65" cy="104" rx="47" ry="10" fill="#D6B880"/>'
body += path('M30 104H102', stroke='#F1DFB5', width=2)
body += melon(70, 63, 41)
body += path('M20 80H78A29 29 0 0 1 20 80Z', '#6FA67C', '#527D59', 2.5)
body += path('M25 83H73A24 24 0 0 1 25 83Z', '#F9E9BA', 'none')
body += path('M29 84H69A20 20 0 0 1 29 84Z', '#E99A80', 'none')
body += path('M39 91L41 94M49 94V98M60 91L58 94', stroke='#805440', width=2.5) + spark(20, 47, 6)
write('ach_suika_final_merge.svg', '西瓜上桌', '深绿色普通西瓜与木托盘上的果肉切片，对应等级七，不再画最终巨瓜或皇冠。', body)

# Collection milestones: a first completed visit, six distinct games, three
# favorites, and ten completed sessions. No old-game marks or calendar-day goal.
body = path('M24 53L64 21L104 53V109H24Z', '#E8C892')
body += path('M16 55L64 17L112 55', stroke='#A27B51', width=7)
body += path('M16 53L64 15L112 53', stroke='#E0B978', width=3)
body += rect(42, 55, 44, 54, PAPER, 19) + path('M64 64C53 64 45 83 48 93C52 111 80 111 81 92C82 82 73 64 64 64Z', '#F6DC9D')
body += spark(64, 82, 9) + check(103, 102, 12) + leaf(13, 81, .67, -27)
write('ach_global_first_settlement.svg', '鸡窝开张', '暖木小屋迎来第一颗星星蛋，任一重构游戏首次正常完成一局。', body)

body = path('M64 21L102 43V86L64 108L26 86V43Z', '#E5E6C0', '#92A77D', 3)
positions = [(64,21,BLUE),(102,43,CORAL),(102,86,'#96BD8B'),(64,108,GOLD),(26,86,'#B5A0C1'),(26,43,'#C6B08B')]
for x, y, color in positions:
    body += circle(x, y, 12, color, 'stroke="#A28B65" stroke-width="2.5"')
    body += path(f'M{x-4} {y-4}L{x} {y-6}L{x+4} {y-4}', stroke=PAPER, width=2)
body += path('M64 40C52 40 44 63 46 75C49 95 79 95 82 75C84 63 76 40 64 40Z', PAPER)
body += spark(64, 68, 10)
write('ach_global_play_six_games.svg', '六边形鸡仔', '六枚不同颜色的游戏印记围成六边形，中心是星星蛋，对应六款重构游戏。', body)

body = rect(20, 37, 38, 65, '#B7CE9F', 8, 'transform="rotate(-14 39 69)"')
body += rect(70, 37, 38, 65, '#E9BD89', 8, 'transform="rotate(14 89 69)"')
body += rect(40, 25, 48, 77, PAPER, 8)
body += path('M57 26V16H71V26', stroke='#BC985B', width=4)
body += group(path(SUITS['heart'], CORAL, '#AA6956', 2.4), 'translate(47 46) scale(1.4)')
body += path('M51 87H77', stroke='#C2CBA1', width=3) + leaf(86, 99, .62, -3)
write('ach_global_favorite_three.svg', '收藏家', '三张被珍藏的游戏卡片与珊瑚爱心，只统计三款不同重构游戏。', body)

body = rect(24, 21, 80, 89, '#D4B37F', 11)
body += rect(31, 17, 66, 87, PAPER, 9)
body += path('M45 13V23M83 13V23', stroke='#AD8C59', width=4)
body += digits(10, 65, 33, 40, 28, GREEN)
for row in range(2):
    for col in range(5):
        body += circle(42+col*11, 79+row*12, 3.5, '#92B583', 'stroke="none"')
body += spark(108, 29, 7) + leaf(14, 90, .69, -31)
write('ach_global_complete_ten_sessions.svg', '常驻鸡仔', '十枚游玩印记与矢量数字10，记录正常完成十局，不是连续十天。', body)

print('Drew all 22 achievement SVGs; existing file names and registry paths are unchanged.')
