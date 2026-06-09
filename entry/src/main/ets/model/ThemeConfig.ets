import { FactionInfo, NativeGameOptions } from './GameTypes';

export interface NativeTheme {
  key: string;
  name: string;
  mark: string;
  subtitle: string;
  types: FactionInfo[];
}

export const THEMES: NativeTheme[] = [
  {
    key: 'rps',
    name: 'RPS',
    mark: '🪨✂️✋🏻',
    subtitle: '石头剪刀布 · 物理碰撞吞并战',
    types: [
      { id: 0, label: '石头', emoji: '🪨', color: '#d95c47', darkColor: '#873328' },
      { id: 1, label: '剪刀', emoji: '✂️', color: '#2c8f7f', darkColor: '#176055' },
      { id: 2, label: '布', emoji: '✋🏻', color: '#4e6edb', darkColor: '#263f99' }
    ]
  },
  {
    key: 'colors',
    name: '颜色球',
    mark: '🔴🟢🔵',
    subtitle: '颜色球联赛 · 红绿蓝循环吞并',
    types: [
      { id: 0, label: '红球', emoji: '🔴', color: '#e84f4f', darkColor: '#9c2525' },
      { id: 1, label: '绿球', emoji: '🟢', color: '#22a65a', darkColor: '#126539' },
      { id: 2, label: '蓝球', emoji: '🔵', color: '#3478f6', darkColor: '#1f4ea5' }
    ]
  },
  {
    key: 'countries',
    name: '国家队',
    mark: '🇨🇳🇺🇸🇧🇷',
    subtitle: '国家队表演赛 · 阵营身份换皮',
    types: [
      { id: 0, label: '中国队', emoji: '🇨🇳', color: '#de3f32', darkColor: '#98281f' },
      { id: 1, label: '美国队', emoji: '🇺🇸', color: '#2456c6', darkColor: '#183a87' },
      { id: 2, label: '巴西队', emoji: '🇧🇷', color: '#18a55f', darkColor: '#0d6b3d' }
    ]
  },
  {
    key: 'brands',
    name: '品牌战',
    mark: '◆✦⬢',
    subtitle: '虚构品牌战 · 三家公司抢占场面',
    types: [
      { id: 0, label: 'Nova', emoji: '◆', color: '#e0574f', darkColor: '#99342e' },
      { id: 1, label: 'Pulse', emoji: '✦', color: '#15a38b', darkColor: '#0b6859' },
      { id: 2, label: 'Orbit', emoji: '⬢', color: '#5867db', darkColor: '#354098' }
    ]
  }
];

export function themeByKey(key: string): NativeTheme {
  for (let i = 0; i < THEMES.length; i += 1) {
    if (THEMES[i].key === key) {
      return THEMES[i];
    }
  }
  return THEMES[0];
}

export function defaultLabelsForTheme(key: string): string[] {
  const theme = themeByKey(key);
  return [theme.types[0].label, theme.types[1].label, theme.types[2].label];
}

export function factionInfoForOptions(options: NativeGameOptions, type: number): FactionInfo {
  const theme = themeByKey(options.themeKey);
  const base = theme.types[Math.max(0, Math.min(2, type))];
  const custom = options.themeKey === 'rps' ? '' : (options.customLabels[type] || '').trim();
  return {
    id: base.id,
    label: custom.length > 0 ? custom : base.label,
    emoji: base.emoji,
    color: base.color,
    darkColor: base.darkColor
  };
}

export function factionLabel(options: NativeGameOptions, type: number): string {
  return factionInfoForOptions(options, type).label;
}

export function factionEmoji(options: NativeGameOptions, type: number): string {
  return factionInfoForOptions(options, type).emoji;
}
