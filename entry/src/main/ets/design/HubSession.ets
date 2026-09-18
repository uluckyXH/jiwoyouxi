import { AchievementFilter } from '../shell/AchievementModule';

/** UI-only session, owned above the hub/game switch. Never written to game storage. */
@Observed
export class HubSession {
  activeTab: number = 0;
  achievementFilter: AchievementFilter = 'all';
  selectedAchievementId: string = '';
  detailOpen: boolean = false;
  scrollOffsets: number[] = [0, 0, 0, 0];
}
