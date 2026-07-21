import {
  RpsBattleMechanicKey,
  RpsBattleMechanicOption,
  RpsBattleMechanicSelection,
  RpsBattleModeKey,
  RpsBattleModePreset,
  RpsBattleModeRules
} from './RpsBattleTypes';

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
    subtitle: '据点 · 黑洞 · 道具',
    objective: '占点到100或限时领先',
    mechanics: ['中心据点', '黑洞', '绝地求生', '能量道具', '团队道具'],
    enabledMechanics: ['中心据点', '黑洞', '绝地求生', '能量道具', '团队道具'],
    upcomingMechanics: [],
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
        canDisable: true
      },
      {
        key: 'lastStand',
        label: '绝地求生',
        summary: '弱势阵营分裂或援军',
        state: 'enabled',
        defaultEnabled: true,
        canDisable: true
      },
      {
        key: 'powerUps',
        label: '能量道具',
        summary: '刷新加速、护盾、分裂道具',
        state: 'enabled',
        defaultEnabled: true,
        canDisable: true
      },
      {
        key: 'teamPowerUps',
        label: '团队道具',
        summary: '拾取后全队共享效果',
        state: 'enabled',
        defaultEnabled: true,
        canDisable: true
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
    hasLastStand: true,
    hasPowerUps: true,
    hasTeamPowerUps: true
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

export function rpsBattleCloneMechanicSelection(
  selection: RpsBattleMechanicSelection = {}
): RpsBattleMechanicSelection {
  return {
    baseChase: selection.baseChase,
    conversion: selection.conversion,
    controlZone: selection.controlZone,
    blackHole: selection.blackHole,
    lastStand: selection.lastStand,
    powerUps: selection.powerUps,
    teamPowerUps: selection.teamPowerUps,
    shrink: selection.shrink,
    traitor: selection.traitor,
    snap: selection.snap,
    obstacles: selection.obstacles
  };
}

export function rpsBattleDefaultMechanicSelection(modeKey: RpsBattleModeKey): RpsBattleMechanicSelection {
  let selection: RpsBattleMechanicSelection = {};
  const options = rpsBattleModeByKey(modeKey).mechanicOptions;
  for (let i = 0; i < options.length; i += 1) {
    const item = options[i];
    selection = rpsBattleSetMechanicSelectionValue(selection, item.key,
      item.state !== 'upcoming' && item.defaultEnabled);
  }
  return selection;
}

export function rpsBattleToggleMechanicSelection(
  modeKey: RpsBattleModeKey,
  selection: RpsBattleMechanicSelection,
  mechanicKey: RpsBattleMechanicKey
): RpsBattleMechanicSelection {
  const option = rpsBattleMechanicOptionByKey(modeKey, mechanicKey);
  if (option === undefined || option.state !== 'enabled' || !option.canDisable) {
    return rpsBattleCloneMechanicSelection(selection);
  }
  const enabled = rpsBattleMechanicEnabledForMode(modeKey, selection, mechanicKey);
  let next = rpsBattleSetMechanicSelectionValue(selection, mechanicKey, !enabled);
  if (mechanicKey === 'powerUps' && enabled) {
    next = rpsBattleSetMechanicSelectionValue(next, 'teamPowerUps', false);
  } else if (mechanicKey === 'teamPowerUps' && !enabled) {
    next = rpsBattleSetMechanicSelectionValue(next, 'powerUps', true);
  }
  return next;
}

export function rpsBattleMechanicEnabledForMode(
  modeKey: RpsBattleModeKey,
  selection: RpsBattleMechanicSelection,
  mechanicKey: RpsBattleMechanicKey
): boolean {
  const option = rpsBattleMechanicOptionByKey(modeKey, mechanicKey);
  if (option === undefined) {
    return false;
  }
  if (mechanicKey === 'teamPowerUps') {
    const powerUpOption = rpsBattleMechanicOptionByKey(modeKey, 'powerUps');
    if (powerUpOption === undefined || !rpsBattleResolvedMechanicEnabled(powerUpOption, selection)) {
      return false;
    }
  }
  return rpsBattleResolvedMechanicEnabled(option, selection);
}

export function rpsBattleResolveModeRulesByKey(
  key: RpsBattleModeKey,
  selection: RpsBattleMechanicSelection = {}
): RpsBattleModeRules {
  const base = rpsBattleModeRulesByKey(key);
  const result: RpsBattleModeRules = {
    key: base.key,
    hasControlZone: base.hasControlZone,
    hasBlackHole: base.hasBlackHole,
    hasLastStand: base.hasLastStand,
    hasPowerUps: base.hasPowerUps,
    hasTeamPowerUps: base.hasTeamPowerUps
  };
  const options = rpsBattleModeByKey(key).mechanicOptions;
  for (let i = 0; i < options.length; i += 1) {
    const item = options[i];
    const enabled = rpsBattleResolvedMechanicEnabled(item, selection);
    if (item.key === 'controlZone') {
      result.hasControlZone = enabled;
    } else if (item.key === 'blackHole') {
      result.hasBlackHole = enabled;
    } else if (item.key === 'lastStand') {
      result.hasLastStand = enabled;
    } else if (item.key === 'powerUps') {
      result.hasPowerUps = enabled;
    } else if (item.key === 'teamPowerUps') {
      result.hasTeamPowerUps = enabled;
    }
  }
  if (!result.hasPowerUps) {
    result.hasTeamPowerUps = false;
  }
  return result;
}

function rpsBattleMechanicOptionByKey(
  modeKey: RpsBattleModeKey,
  mechanicKey: RpsBattleMechanicKey
): RpsBattleMechanicOption | undefined {
  const options = rpsBattleModeByKey(modeKey).mechanicOptions;
  return options.find((item: RpsBattleMechanicOption) => item.key === mechanicKey);
}

function rpsBattleResolvedMechanicEnabled(
  option: RpsBattleMechanicOption,
  selection: RpsBattleMechanicSelection
): boolean {
  if (option.state === 'upcoming') {
    return false;
  }
  if (option.state === 'core' || !option.canDisable) {
    return option.defaultEnabled;
  }
  return rpsBattleMechanicSelectionValue(selection, option.key, option.defaultEnabled);
}

function rpsBattleMechanicSelectionValue(
  selection: RpsBattleMechanicSelection,
  mechanicKey: RpsBattleMechanicKey,
  fallback: boolean
): boolean {
  let value: boolean | undefined = undefined;
  if (mechanicKey === 'baseChase') {
    value = selection.baseChase;
  } else if (mechanicKey === 'conversion') {
    value = selection.conversion;
  } else if (mechanicKey === 'controlZone') {
    value = selection.controlZone;
  } else if (mechanicKey === 'blackHole') {
    value = selection.blackHole;
  } else if (mechanicKey === 'lastStand') {
    value = selection.lastStand;
  } else if (mechanicKey === 'powerUps') {
    value = selection.powerUps;
  } else if (mechanicKey === 'teamPowerUps') {
    value = selection.teamPowerUps;
  } else if (mechanicKey === 'shrink') {
    value = selection.shrink;
  } else if (mechanicKey === 'traitor') {
    value = selection.traitor;
  } else if (mechanicKey === 'snap') {
    value = selection.snap;
  } else if (mechanicKey === 'obstacles') {
    value = selection.obstacles;
  }
  return value === undefined ? fallback : value;
}

function rpsBattleSetMechanicSelectionValue(
  selection: RpsBattleMechanicSelection,
  mechanicKey: RpsBattleMechanicKey,
  value: boolean
): RpsBattleMechanicSelection {
  const next = rpsBattleCloneMechanicSelection(selection);
  if (mechanicKey === 'baseChase') {
    next.baseChase = value;
  } else if (mechanicKey === 'conversion') {
    next.conversion = value;
  } else if (mechanicKey === 'controlZone') {
    next.controlZone = value;
  } else if (mechanicKey === 'blackHole') {
    next.blackHole = value;
  } else if (mechanicKey === 'lastStand') {
    next.lastStand = value;
  } else if (mechanicKey === 'powerUps') {
    next.powerUps = value;
  } else if (mechanicKey === 'teamPowerUps') {
    next.teamPowerUps = value;
  } else if (mechanicKey === 'shrink') {
    next.shrink = value;
  } else if (mechanicKey === 'traitor') {
    next.traitor = value;
  } else if (mechanicKey === 'snap') {
    next.snap = value;
  } else if (mechanicKey === 'obstacles') {
    next.obstacles = value;
  }
  return next;
}
