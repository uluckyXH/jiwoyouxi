import { RpsBattleModeKey, RpsBattleModePreset, RpsBattleModeRules } from './RpsBattleTypes';

export const RPS_BATTLE_MODES: RpsBattleModePreset[] = [
  {
    key: 'classic',
    name: '经典乱斗',
    icon: '⚔',
    subtitle: '基础追捕 · 清场',
    objective: '限时领先或清场',
    mechanics: ['基础追捕', '碰撞转阵'],
    enabledMechanics: ['基础追捕', '碰撞转阵'],
    upcomingMechanics: [],
    mechanicOptions: [
      {
        key: 'baseChase',
        label: '基础追捕',
        summary: '三阵营自动寻找克制目标',
        state: 'core',
        defaultEnabled: true,
        canDisable: false
      },
      {
        key: 'conversion',
        label: '碰撞转阵',
        summary: '克制方碰撞后转换阵营',
        state: 'core',
        defaultEnabled: true,
        canDisable: false
      }
    ]
  },
  {
    key: 'zones',
    name: '团队占点',
    icon: '◎',
    subtitle: '据点 · 黑洞',
    objective: '占点到100或限时领先',
    mechanics: ['中心据点', '黑洞', '绝地求生', '能量道具', '团队道具'],
    enabledMechanics: ['中心据点', '黑洞'],
    upcomingMechanics: ['绝地求生', '能量道具', '团队道具'],
    mechanicOptions: [
      {
        key: 'controlZone',
        label: '中心据点',
        summary: '中央据点涨到100获胜',
        state: 'core',
        defaultEnabled: true,
        canDisable: false
      },
      {
        key: 'blackHole',
        label: '黑洞',
        summary: '随机危险点吸入单位',
        state: 'enabled',
        defaultEnabled: true,
        canDisable: false
      },
      {
        key: 'lastStand',
        label: '绝地求生',
        summary: '弱势阵营分裂或复活',
        state: 'upcoming',
        defaultEnabled: true,
        canDisable: false
      },
      {
        key: 'powerUps',
        label: '能量道具',
        summary: '刷新加速、护盾、分裂道具',
        state: 'upcoming',
        defaultEnabled: true,
        canDisable: false
      },
      {
        key: 'teamPowerUps',
        label: '团队道具',
        summary: '拾取后全队共享效果',
        state: 'upcoming',
        defaultEnabled: true,
        canDisable: false
      }
    ]
  },
  {
    key: 'traitor',
    name: '小心叛徒',
    icon: '!',
    subtitle: '缩圈 · 叛徒',
    objective: '死斗清场',
    mechanics: ['缩圈', '叛徒', '黑洞'],
    enabledMechanics: [],
    upcomingMechanics: ['缩圈', '叛徒', '黑洞'],
    mechanicOptions: [
      {
        key: 'shrink',
        label: '缩圈',
        summary: '边界持续向内压缩',
        state: 'upcoming',
        defaultEnabled: true,
        canDisable: false
      },
      {
        key: 'traitor',
        label: '叛徒',
        summary: '标记单位倒计时叛变',
        state: 'upcoming',
        defaultEnabled: true,
        canDisable: false
      },
      {
        key: 'blackHole',
        label: '黑洞',
        summary: '随机危险点吸入单位',
        state: 'upcoming',
        defaultEnabled: true,
        canDisable: false
      }
    ]
  },
  {
    key: 'equality',
    name: '众生平等',
    icon: '=',
    subtitle: '响指 · 障碍',
    objective: '死斗清场',
    mechanics: ['响指减员', '障碍'],
    enabledMechanics: [],
    upcomingMechanics: ['响指减员', '障碍'],
    mechanicOptions: [
      {
        key: 'snap',
        label: '响指减员',
        summary: '各阵营随机减少一半',
        state: 'upcoming',
        defaultEnabled: true,
        canDisable: false
      },
      {
        key: 'obstacles',
        label: '障碍',
        summary: '地图障碍改变路线',
        state: 'upcoming',
        defaultEnabled: true,
        canDisable: false
      }
    ]
  }
];

export const RPS_BATTLE_MODE_RULES: RpsBattleModeRules[] = [
  {
    key: 'classic',
    hasControlZone: false,
    hasBlackHole: false,
    hasLastStand: false,
    hasPowerUps: false,
    hasTeamPowerUps: false
  },
  {
    key: 'zones',
    hasControlZone: true,
    hasBlackHole: true,
    hasLastStand: false,
    hasPowerUps: false,
    hasTeamPowerUps: false
  },
  {
    key: 'traitor',
    hasControlZone: false,
    hasBlackHole: false,
    hasLastStand: false,
    hasPowerUps: false,
    hasTeamPowerUps: false
  },
  {
    key: 'equality',
    hasControlZone: false,
    hasBlackHole: false,
    hasLastStand: false,
    hasPowerUps: false,
    hasTeamPowerUps: false
  }
];

export function rpsBattleModeByKey(key: RpsBattleModeKey): RpsBattleModePreset {
  const found = RPS_BATTLE_MODES.find((item: RpsBattleModePreset) => item.key === key);
  return found === undefined ? RPS_BATTLE_MODES[0] : found;
}

export function rpsBattleModeRulesByKey(key: RpsBattleModeKey): RpsBattleModeRules {
  const found = RPS_BATTLE_MODE_RULES.find((item: RpsBattleModeRules) => item.key === key);
  return found === undefined ? RPS_BATTLE_MODE_RULES[0] : found;
}
