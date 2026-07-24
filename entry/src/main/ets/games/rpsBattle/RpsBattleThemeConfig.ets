import {
  RpsBattleFaction,
  RpsBattleFactionInfo,
  RpsBattleThemeKey,
  RpsBattleThemePreset
} from './RpsBattleTypes';

export const RPS_BATTLE_THEMES: RpsBattleThemePreset[] = [
  {
    key: 'rps',
    name: 'RPS',
    mark: '🪨✂️✋',
    subtitle: '经典三方循环克制',
    factions: [
      { id: 'rock', label: '石头', symbol: '🪨', color: '#64748b', softColor: '#e8edf3', textColor: '#334155' },
      { id: 'scissors', label: '剪刀', symbol: '✂️', color: '#0ea5a4', softColor: '#d8f5f2', textColor: '#0f766e' },
      { id: 'paper', label: '布', symbol: '✋', color: '#f59e0b', softColor: '#fff1d2', textColor: '#9a5a00' }
    ]
  },
  {
    key: 'colors',
    name: '颜色球',
    mark: '🔴🟢🔵',
    subtitle: '红绿蓝循环吞并',
    factions: [
      { id: 'rock', label: '红球', symbol: '🔴', color: '#e84f4f', softColor: '#ffe0e0', textColor: '#9c2525' },
      { id: 'scissors', label: '绿球', symbol: '🟢', color: '#22a65a', softColor: '#dcf5e5', textColor: '#126539' },
      { id: 'paper', label: '蓝球', symbol: '🔵', color: '#3478f6', softColor: '#e1ebff', textColor: '#1f4ea5' }
    ]
  },
  {
    key: 'countries',
    name: '国家队',
    mark: '🇨🇳🇺🇸🇧🇷',
    subtitle: '三队表演赛',
    factions: [
      { id: 'rock', label: '中国队', symbol: '🇨🇳', color: '#de3f32', softColor: '#ffe0dc', textColor: '#98281f' },
      { id: 'scissors', label: '美国队', symbol: '🇺🇸', color: '#2456c6', softColor: '#dfe8ff', textColor: '#183a87' },
      { id: 'paper', label: '巴西队', symbol: '🇧🇷', color: '#18a55f', softColor: '#d9f4e4', textColor: '#0d6b3d' }
    ]
  },
  {
    key: 'brands',
    name: '品牌战',
    mark: '◆✦⬢',
    subtitle: '三家公司抢占场面',
    factions: [
      { id: 'rock', label: 'Nova', symbol: '◆', color: '#e0574f', softColor: '#ffe1de', textColor: '#99342e' },
      { id: 'scissors', label: 'Pulse', symbol: '✦', color: '#15a38b', softColor: '#d7f5ee', textColor: '#0b6859' },
      { id: 'paper', label: 'Orbit', symbol: '⬢', color: '#5867db', softColor: '#e1e4ff', textColor: '#354098' }
    ]
  }
];

export function rpsBattleThemeByKey(key: RpsBattleThemeKey): RpsBattleThemePreset {
  const found = RPS_BATTLE_THEMES.find((item: RpsBattleThemePreset) => item.key === key);
  return found === undefined ? RPS_BATTLE_THEMES[0] : found;
}

export function rpsBattleThemeFactions(key: RpsBattleThemeKey): RpsBattleFactionInfo[] {
  return rpsBattleThemeByKey(key).factions;
}

export function rpsBattleThemeFactionInfo(key: RpsBattleThemeKey, faction: RpsBattleFaction): RpsBattleFactionInfo {
  const factions = rpsBattleThemeFactions(key);
  const found = factions.find((item: RpsBattleFactionInfo) => item.id === faction);
  return found === undefined ? factions[0] : found;
}
