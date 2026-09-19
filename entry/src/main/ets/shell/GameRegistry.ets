import { GameModule } from './GameModule';

export const GAME_MODULES: GameModule[] = [
  {
    id: 'bloomLines',
    title: '五子连珠',
    subtitle: '花窗连珠 · 给彩珠找条小路，连成五颗开花',
    icon: '✿',
    tags: ['消除', '寻路', '休闲'],
    accent: '#4D7048',
    highScoreLabel: '最高分'
  },
  {
    id: 'tangram',
    title: '七巧板',
    subtitle: '七巧小院 · 七块拼板，拼出一院小风景',
    icon: '△',
    tags: ['拼图', '图鉴', '休闲'],
    accent: '#779563',
    highScoreLabel: '收集作品'
  },
  {
    id: 'rps',
    title: '石头剪刀布大作战',
    subtitle: '三方自动追捕，机制全开也能离线玩',
    icon: '✊',
    tags: ['观战', '策略', '乱斗'],
    accent: '#2c8f7f',
    highScoreLabel: '最高存活数'
  },
  {
    id: 'freecellNext',
    title: '空当接龙',
    subtitle: '暖木牌室 · 纸牌归位、提示与轻柔音效',
    icon: '♣',
    tags: ['纸牌', '策略', '多屏'],
    accent: '#2C6B52',
    highScoreLabel: '最高分'
  },
  {
    id: 'freecell',
    title: '空当接龙',
    subtitle: '经典纸牌策略，红黑交替递减，四花色归位',
    icon: '♣',
    tags: ['纸牌', '策略', '竖屏'],
    accent: '#b46b2a',
    highScoreLabel: '最高分'
  },
  {
    id: 'minesweeperNext',
    title: '扫雷',
    subtitle: '庭院探雷，三档难度与轻柔音效',
    icon: '✹',
    tags: ['推理', '三档难度', '休闲'],
    accent: '#416B55',
    highScoreLabel: '最高得分'
  },
  {
    id: 'minesweeper',
    title: '扫雷',
    subtitle: '经典雷区推理，首点安全，支持插旗模式',
    icon: '✹',
    tags: ['推理', '棋盘', '休闲'],
    accent: '#4e6edb',
    highScoreLabel: '最高得分'
  },
  {
    id: 'chicken2048Next',
    title: '2048',
    subtitle: '暖光叠数，滑动合并与轻柔和弦',
    icon: '2',
    tags: ['合成', '数字', '休闲'],
    accent: '#34664D',
    highScoreLabel: '最高分'
  },
  {
    id: 'chicken2048',
    title: '2048',
    subtitle: '滑动数字块合成升级，冲到 2048',
    icon: '2',
    tags: ['合成', '棋盘', '轻松'],
    accent: '#f4a62a',
    highScoreLabel: '最高分'
  },
  {
    id: 'tetrisNext',
    title: '俄罗斯方块',
    subtitle: '方块工坊 · 暂存、落点预览与轻柔消行音效',
    icon: '▣',
    tags: ['消行', '暂存', '多屏'],
    accent: '#496e41',
    highScoreLabel: '最高分'
  },
  {
    id: 'tetris',
    title: '俄罗斯方块',
    subtitle: '10×20 网格、7 种方块、消行升级',
    icon: '▣',
    tags: ['下落', '消除', '长局'],
    accent: '#8b5cf6',
    highScoreLabel: '最高分'
  },
  {
    id: 'suikaNext',
    title: '鸡窝水果摊',
    subtitle: '鲜果合成 · 合并同类水果，攒出一颗大西瓜',
    icon: '◉',
    tags: ['合成', '物理', '休闲'],
    accent: '#779553',
    highScoreLabel: '最高瓜分'
  },
  {
    id: 'suika',
    title: '鸡窝水果摊',
    subtitle: '圆滚滚玩具水果落进木箱，相同碰撞合成',
    icon: '◉',
    tags: ['物理', '合成', '软弹'],
    accent: '#16a34a',
    highScoreLabel: '最高瓜分'
  },
  {
    id: 'rpsBattle',
    title: '石头剪刀布大作战',
    subtitle: '三方自动追捕，配置阵营和机制后开始乱斗',
    icon: '✊',
    tags: ['观战', '策略', '乱斗'],
    accent: '#2c8f7f',
    highScoreLabel: '最高存活数'
  },
  {
    id: 'rpsBattleNext',
    title: '石头剪刀布大作战',
    subtitle: '庭院擂台 · 三方转阵、据点指挥与八个挑战',
    icon: '✊',
    tags: ['乱斗', '指挥', '多屏'],
    accent: '#527342',
    highScoreLabel: '挑战星数'
  }
];

export function moduleById(id: string): GameModule {
  const found = GAME_MODULES.find((item: GameModule) => item.id === id);
  if (found !== undefined) {
    return found;
  }
  const fallback = GAME_MODULES.find((item: GameModule) => item.id === 'rpsBattle');
  return fallback === undefined ? GAME_MODULES[0] : fallback;
}

export function gameLogoPath(gameId: string): string {
  if (gameId === 'bloomLines') return 'gamesNext/bloomLines/scene/logo.svg';
  if (gameId === 'tangram') return 'gamesNext/tangramGarden/scene/logo.svg';
  // App shell identities only; game scenes own their artwork under rawfile/games/.
  if (gameId === 'suika' || gameId === 'suikaNext') {
    return 'app/game_logos/game_icon_suika.svg';
  }
  if (gameId === 'minesweeper' || gameId === 'minesweeperNext') {
    return 'gamesNext/minesweeper/scene/logo.svg';
  }
  if (gameId === 'tetris' || gameId === 'tetrisNext') {
    return 'app/game_logos/game_icon_tetris.svg';
  }
  if (gameId === 'chicken2048' || gameId === 'chicken2048Next') {
    return 'app/game_logos/game_icon_chicken2048.svg';
  }
  if (gameId === 'freecell' || gameId === 'freecellNext') {
    return 'gamesNext/warmFreecell/scene/logo.svg';
  }
  return 'app/game_logos/game_icon_rps.svg';
}
