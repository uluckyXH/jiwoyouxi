export interface GameModule {
  id: string;
  title: string;
  subtitle: string;
  icon: string;
  tags: string[];
  accent: string;
  highScoreLabel: string;
}

export interface GameRecord {
  gameId: string;
  highScore: number;
  playCount: number;
  lastPlayedAt: number;
}

export interface CoopAppSnapshot {
  records: GameRecord[];
  favorites: string[];
  recent: string[];
  soundEnabled: boolean;
  hapticEnabled: boolean;
  appearanceMode: string;
}

export const APPEARANCE_LIGHT: string = 'light';
export const APPEARANCE_DARK: string = 'dark';

export function emptySnapshot(): CoopAppSnapshot {
  return {
    records: [],
    favorites: [],
    recent: [],
    soundEnabled: true,
    hapticEnabled: true,
    appearanceMode: APPEARANCE_LIGHT
  };
}
