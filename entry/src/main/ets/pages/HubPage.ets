import { AppIcon } from '../components/AppIcon';
import { MotionPressable } from '../components/MotionPressable';
import { CoopMotion } from '../design/CoopMotion';
import { CoopTheme } from '../design/CoopTheme';
import { CoopViewport } from '../design/CoopViewport';
import { achievementSummaryForState } from '../shell/AchievementEngine';
import { AchievementState } from '../shell/AchievementModule';
import {
  APPEARANCE_DARK,
  APPEARANCE_LIGHT,
  CoopAppSnapshot,
  GameModule,
  GameRecord
} from '../shell/GameModule';
import { GAME_MODULES, moduleById } from '../shell/GameRegistry';
import { AchievementWall } from './AchievementWall';
import { HubBottomTabBar } from './HubBottomTabBar';
import { HubGameLogoTile } from './HubGameLogoTile';
import { HubHeroBanner } from './HubHeroBanner';
import { HubSettingsPanel } from './HubSettingsPanel';
import { HubStatsPanel } from './HubStatsPanel';

const HOME_GAME_ORDER: string[] = ['suikaNext', 'suika', 'minesweeper', 'tetris', 'chicken2048', 'freecell', 'rps', 'rpsBattle'];
const HOME_SIDE_PADDING: number = 20;
const HOME_TOP_PADDING: number = 56;
const HOME_CONTENT_BOTTOM_SPACE: number = 108;
const HOME_HEADER_ACTION_SIZE: number = 42;
const HOME_HEADER_ICON_SIZE: number = 22;
const HOME_GAME_CARD_HEIGHT: number = 108;
const HOME_GAME_CARD_SLOT_HEIGHT: number = 122;
const HOME_GAME_GRID_GAP: number = 10;
const HOME_GAME_LOGO_TILE_SIZE: number = 62;
const HOME_GAME_LOGO_IMAGE_SIZE: number = 56;
const HOME_FAVORITE_CARD_HEIGHT: number = 138;
const HOME_FAVORITE_CARD_SLOT_HEIGHT: number = 152;
const HOME_FAVORITE_LOGO_TILE_SIZE: number = 58;
const HOME_FAVORITE_LOGO_IMAGE_SIZE: number = 52;

@Component
export struct HubPage {
  @Prop snapshot: CoopAppSnapshot;
  @Prop achievementState: AchievementState;
  openGame: (gameId: string) => void = () => {};
  resetAchievements: () => Promise<boolean> = async (): Promise<boolean> => false;
  refreshAchievements: () => Promise<void> = async (): Promise<void> => {};
  toggleFavorite: (gameId: string) => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  updateHaptic: (enabled: boolean) => void = () => {};
  updateAppearanceMode: (appearanceMode: string) => void = () => {};
  @State activeTab: number = 0;
  @State pageWidth: number = CoopViewport.phoneDefaultWidth;
  @State pageHeight: number = CoopViewport.phoneDefaultHeight;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Stack({ alignContent: Alignment.Bottom }) {
        Scroll() {
          Column({ space: 14 }) {
            this.ActiveTabContent()
            Blank()
              .height(HOME_CONTENT_BOTTOM_SPACE)
          }
          .width('100%')
          .constraintSize({ minHeight: '100%' })
          .padding({ left: HOME_SIDE_PADDING, right: HOME_SIDE_PADDING, top: HOME_TOP_PADDING, bottom: 18 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)

        HubBottomTabBar({
          activeTab: this.activeTab,
          isDarkMode: this.isDarkMode(),
          onTabSelected: (index: number) => {
            this.switchTab(index);
          }
        })
      }
      .width(this.homeFrameWidth())
      .height(this.homeFrameHeight())
      .backgroundColor(this.homeBgColor())
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.homeBgColor())
    .onAreaChange((oldArea, newArea) => {
      this.handlePageAreaChange(newArea);
    })
  }

  @Builder
  ActiveTabContent() {
    if (this.activeTab === 0) {
      Stack() {
        this.HomeContent()
      }
      .width('100%')
      .transition(this.tabTransition())
    } else if (this.activeTab === 1) {
      Stack() {
        this.FavoriteList()
      }
      .width('100%')
      .transition(this.tabTransition())
    } else if (this.activeTab === 2) {
      Stack() {
        this.Achievements()
      }
      .width('100%')
      .transition(this.tabTransition())
    } else {
      Stack() {
        this.Settings()
      }
      .width('100%')
      .transition(this.tabTransition())
    }
  }

  @Builder
  HomeContent() {
    Column({ space: 14 }) {
      this.WelcomeHeader()
      HubHeroBanner({
        isDarkMode: this.isDarkMode(),
        gameTitle: moduleById(this.heroGameId()).title + (this.heroGameId() === 'suikaNext' ? ' · 重构中' : ''),
        startGame: () => this.openGame(this.heroGameId())
      })
      this.SectionTitleRow('精选游戏', 'app/ui/chicken.svg', true)
      this.HomeGameGrid()
      HubStatsPanel({
        playStreak: this.playStreak(),
        unlockedBadges: this.unlockedBadges(),
        badgeTotal: this.badgeTotal(),
        isDarkMode: this.isDarkMode()
      })
    }
    .width('100%')
  }

  @Builder
  WelcomeHeader() {
    Row() {
      Column({ space: 4 }) {
        Text(this.greetingTitle())
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.inkColor())
        Text('今天玩什么呢？')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.mutedColor())
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row({ space: 10 }) {
        Stack({ alignContent: Alignment.Center }) {
          AppIcon({
            name: this.isDarkMode() ? 'sun' : 'moon',
            iconSize: HOME_HEADER_ICON_SIZE,
            tint: this.activeColor()
          })
        }
          .width(HOME_HEADER_ACTION_SIZE)
          .height(HOME_HEADER_ACTION_SIZE)
          .backgroundColor(this.iconButtonBgColor())
          .border({ width: 1, color: this.lineColor() })
          .borderRadius(HOME_HEADER_ACTION_SIZE / 2)
          .shadow(this.softShadow())
          .accessibilityText(this.isDarkMode() ? '切换到浅色模式' : '切换到深色模式')
          .onClick(() => {
            this.toggleAppearanceMode();
          })
        Image($rawfile('app/ui/chicken.svg'))
          .width(HOME_HEADER_ACTION_SIZE)
          .height(HOME_HEADER_ACTION_SIZE)
          .padding(3)
          .objectFit(ImageFit.Contain)
          .accessibilityText('鸡窝游戏')
          .borderRadius(HOME_HEADER_ACTION_SIZE / 2)
          .backgroundColor(this.iconButtonBgColor())
          .border({ width: 1, color: this.lineColor() })
          .shadow(this.softShadow())
      }
    }
    .width('100%')
  }

  @Builder
  SectionTitleRow(title: string, icon: string, showMore: boolean) {
    Row() {
      Row({ space: 8 }) {
        Image($rawfile(icon))
          .width(28)
          .height(28)
          .padding(2)
          .objectFit(ImageFit.Contain)
          .accessibilityLevel('no')
          .backgroundColor(this.sectionIconBgColor())
          .borderRadius(14)
          .border({ width: 1, color: this.lineColor() })
        Text(title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.inkColor())
      }
      Blank()
      if (showMore) {
        Stack({ alignContent: Alignment.Center }) {
          AppIcon({ name: 'chevron_right', iconSize: 20, tint: this.inkColor() })
        }
          .width(34)
          .height(30)
          .backgroundColor(this.sectionActionBgColor())
          .borderRadius(15)
          .border({ width: 1, color: this.lineColor() })
          .responseRegion({ x: -3, y: -5, width: 40, height: 40 })
          .accessibilityText('查看精选游戏')
          .onClick(() => {
            this.activeTab = 0;
          })
      }
    }
    .width('100%')
    .margin({ top: 2 })
  }

  @Builder
  HomeGameGrid() {
    Grid() {
      ForEach(this.homeModules(), (item: GameModule) => {
        GridItem() {
          this.HomeGameCard(item)
        }
        .padding({ top: 2, bottom: 10 })
      }, (item: GameModule) => item.id)
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(HOME_GAME_GRID_GAP)
    .columnsGap(HOME_GAME_GRID_GAP)
    .width('100%')
    .height(this.homeGridHeight())
  }

  @Builder
  HomeGameCard(module: GameModule) {
    MotionPressable({
      action: () => {
        this.openGame(module.id);
      }
    }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Row()
          .width(42)
          .height(4)
          .borderRadius(2)
          .backgroundColor(module.accent)
          .opacity(this.isDarkMode() ? 0.72 : 0.58)
          .position({ x: 14, y: 10 })
        Row({ space: 12 }) {
          HubGameLogoTile({
            gameId: module.id,
            tileSize: HOME_GAME_LOGO_TILE_SIZE,
            imageSize: HOME_GAME_LOGO_IMAGE_SIZE,
            showFavorite: true,
            isFavorite: this.isFavorite(module.id),
            isDarkMode: this.isDarkMode(),
            toggleFavorite: this.toggleFavorite
          })

          Column({ space: 6 }) {
            Text(module.title)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.inkColor())
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.homeTag(module.id))
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .fontColor(module.id === 'suikaNext' ? this.activeColor() : this.mutedColor())
              .backgroundColor(module.id === 'suikaNext' ? this.panelSoftColor() : Color.Transparent)
              .padding({ left: module.id === 'suikaNext' ? 6 : 0, right: 6, top: 2, bottom: 2 })
              .borderRadius(6)
              .maxLines(1)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(HOME_GAME_CARD_HEIGHT)
      .padding({ left: 12, right: 12, top: 16, bottom: 12 })
      .borderRadius(20)
      .backgroundColor(this.gameCardBgColor())
      .border({ width: 1, color: this.gameCardLineColor() })
      .shadow(this.cardShadow())
    }
  }

  @Builder
  FavoriteList() {
    Column({ space: 12 }) {
      this.SectionTitleRow('我的收藏', 'app/ui/favorites_empty.svg', false)
      if (this.visibleFavoriteIds().length === 0) {
        this.FavoriteEmptyPanel()
      } else {
        this.FavoriteGrid()
      }
    }
    .width('100%')
  }

  @Builder
  FavoriteGrid() {
    Grid() {
      ForEach(this.visibleFavoriteIds(), (gameId: string) => {
        GridItem() {
          this.FavoriteGameCard(moduleById(gameId))
        }
        .padding({ top: 2, bottom: 10 })
      }, (gameId: string) => gameId)
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(HOME_GAME_GRID_GAP)
    .columnsGap(HOME_GAME_GRID_GAP)
    .width('100%')
    .height(this.favoriteGridHeight())
  }

  @Builder
  FavoriteGameCard(module: GameModule) {
    MotionPressable({
      action: () => {
        this.openGame(module.id);
      }
    }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Row()
          .width(34)
          .height(4)
          .borderRadius(2)
          .backgroundColor(module.accent)
          .opacity(this.isDarkMode() ? 0.70 : 0.52)
          .position({ x: 12, y: 10 })

        Column({ space: 8 }) {
          Row() {
            HubGameLogoTile({
              gameId: module.id,
              tileSize: HOME_FAVORITE_LOGO_TILE_SIZE,
              imageSize: HOME_FAVORITE_LOGO_IMAGE_SIZE,
              isDarkMode: this.isDarkMode()
            })
            Blank()
            AppIcon({ name: 'star_filled', iconSize: 24, tint: this.favoriteActiveColor() })
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          Column({ space: 4 }) {
            Text(module.title)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.inkColor())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.favoriteRecordText(module))
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.mutedColor())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height(HOME_FAVORITE_CARD_HEIGHT)
      .padding({ left: 12, right: 12, top: 16, bottom: 12 })
      .borderRadius(20)
      .backgroundColor(this.gameCardBgColor())
      .border({ width: 1, color: this.gameCardLineColor() })
      .shadow(this.cardShadow())
    }
  }

  @Builder
  FavoriteEmptyPanel() {
    Column({ space: 10 }) {
      Image($rawfile('app/ui/favorites_empty.svg'))
        .width(72)
        .height(72)
        .objectFit(ImageFit.Contain)
        .accessibilityLevel('no')
      Text('还没有收藏')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.inkColor())
      Text('去首页挑几个常玩的游戏。')
        .fontSize(12)
        .fontColor(this.mutedColor())
        .textAlign(TextAlign.Center)
      MotionPressable({
        pressScale: 0.97,
        action: () => {
          this.switchTab(0);
        }
      }) {
        Text('去首页看看')
          .width(132)
          .height(38)
          .borderRadius(19)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.favoriteActionTextColor())
          .textAlign(TextAlign.Center)
          .backgroundColor(this.favoriteActionBgColor())
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 28, bottom: 24 })
    .alignItems(HorizontalAlign.Center)
    .borderRadius(22)
    .backgroundColor(this.panelColor())
    .border({ width: 1, color: this.lineColor() })
    .shadow(this.softShadow())
  }

  @Builder
  Achievements() {
    AchievementWall({
      achievementState: this.achievementState,
      isDarkMode: this.isDarkMode(),
      resetAchievements: this.resetAchievements
    })
  }

  @Builder
  Settings() {
    HubSettingsPanel({
      appearanceMode: this.snapshot.appearanceMode,
      updateAppearanceMode: (appearanceMode: string) => {
        this.updateAppearanceMode(appearanceMode);
      }
    })
  }

  private homeModules(): GameModule[] {
    const modules: GameModule[] = [];
    HOME_GAME_ORDER.forEach((id: string) => {
      modules.push(moduleById(id));
    });
    return modules;
  }

  private homeGridHeight(): number {
    const rows = Math.ceil(this.homeModules().length / 2);
    return rows * HOME_GAME_CARD_SLOT_HEIGHT + Math.max(0, rows - 1) * HOME_GAME_GRID_GAP;
  }

  private favoriteGridHeight(): number {
    const rows = Math.ceil(this.visibleFavoriteIds().length / 2);
    return rows * HOME_FAVORITE_CARD_SLOT_HEIGHT + Math.max(0, rows - 1) * HOME_GAME_GRID_GAP;
  }

  private homeFrameWidth(): number {
    return this.pageWidth;
  }

  private homeFrameHeight(): number {
    return this.pageHeight;
  }

  private handlePageAreaChange(newArea: Area): void {
    const width = Number.parseFloat(`${newArea.width}`);
    const height = Number.parseFloat(`${newArea.height}`);
    if (Number.isFinite(width) && width > 0 && Number.isFinite(height) && height > 0) {
      const frame = CoopViewport.frame(width, height);
      this.pageWidth = frame.width;
      this.pageHeight = frame.height;
    }
  }

  private heroGameId(): string {
    for (let index = 0; index < this.snapshot.recent.length; index += 1) {
      const id = this.snapshot.recent[index];
      const found = GAME_MODULES.find((item: GameModule) => item.id === id);
      if (found !== undefined && this.isVisibleGameId(id)) {
        return id;
      }
    }
    return 'suika';
  }

  private homeTag(gameId: string): string {
    if (gameId === 'rpsBattle') return '鸡窝乱斗';
    if (gameId === 'suikaNext') return '重构中';
    if (gameId === 'suika') return '经典版';
    if (gameId === 'chicken2048') return '数字叠叠乐';
    if (gameId === 'minesweeper') return '小心鸡雷';
    if (gameId === 'tetris') return '方块下蛋';
    if (gameId === 'freecell') return '纸牌归位';
    return '鸡窝乱斗';
  }

  private favoriteRecordText(module: GameModule): string {
    const record = this.recordFor(module.id);
    return `${module.id === 'suikaNext' ? '重构中 · ' : ''}${module.highScoreLabel} ${record.highScore} · ${record.playCount} 局`;
  }

  private greetingTitle(): string {
    const hour = new Date().getHours();
    if (hour >= 5 && hour < 11) return '早上好，鸡仔！';
    if (hour >= 11 && hour < 14) return '中午好，鸡仔！';
    if (hour >= 14 && hour < 18) return '下午好，鸡仔！';
    if (hour >= 18 && hour < 23) return '晚上好，鸡仔！';
    return '还不睡，鸡仔？';
  }

  private isFavorite(gameId: string): boolean {
    return this.snapshot.favorites.includes(gameId);
  }

  private isVisibleGameId(gameId: string): boolean {
    return HOME_GAME_ORDER.includes(gameId);
  }

  private visibleFavoriteIds(): string[] {
    return this.snapshot.favorites.filter((gameId: string) => this.isVisibleGameId(gameId));
  }

  private isDarkMode(): boolean {
    return this.snapshot.appearanceMode === APPEARANCE_DARK;
  }

  private toggleAppearanceMode(): void {
    const nextMode = this.isDarkMode() ? APPEARANCE_LIGHT : APPEARANCE_DARK;
    this.getUIContext().animateTo({
      duration: CoopMotion.modalDuration,
      curve: Curve.EaseOut
    }, () => {
      this.updateAppearanceMode(nextMode);
    });
  }

  private homeBgColor(): string {
    return this.isDarkMode() ? '#101110' : CoopTheme.appSurface;
  }

  private inkColor(): string {
    return this.isDarkMode() ? '#fff2df' : CoopTheme.ink;
  }

  private mutedColor(): string {
    return this.isDarkMode() ? '#c8b7a2' : '#786555';
  }

  private activeColor(): string {
    return this.isDarkMode() ? '#FFD083' : '#A76720';
  }

  private favoriteActiveColor(): string {
    return this.isDarkMode() ? '#FFD083' : '#B47628';
  }

  private favoriteActionBgColor(): string {
    return this.isDarkMode() ? '#d99632' : CoopTheme.brand;
  }

  private favoriteActionTextColor(): string {
    return this.isDarkMode() ? '#21160a' : '#ffffff';
  }

  private panelColor(): string {
    return this.isDarkMode() ? '#211f1b' : '#fffaf2';
  }

  private panelSoftColor(): string {
    return this.isDarkMode() ? '#2a2621' : '#fff0da';
  }

  private lineColor(): string {
    return this.isDarkMode() ? 'rgba(255,236,205,0.14)' : 'rgba(132,91,45,0.12)';
  }

  private iconButtonBgColor(): string {
    return this.panelColor();
  }

  private sectionIconBgColor(): string {
    return this.panelSoftColor();
  }

  private sectionActionBgColor(): string {
    return this.panelSoftColor();
  }

  private gameCardBgColor(): string {
    return this.isDarkMode() ? '#25221e' : '#fffdf8';
  }

  private gameCardLineColor(): string {
    return this.isDarkMode() ? 'rgba(255,231,196,0.18)' : 'rgba(126,78,35,0.16)';
  }

  private softShadow(): ShadowOptions {
    if (this.isDarkMode()) {
      return {
        radius: 26,
        color: 'rgba(0,0,0,0.42)',
        offsetX: 0,
        offsetY: 12
      };
    }
    return {
      radius: 26,
      color: 'rgba(112,73,34,0.18)',
      offsetX: 0,
      offsetY: 12
    };
  }

  private cardShadow(): ShadowOptions {
    if (this.isDarkMode()) {
      return {
        radius: 30,
        color: 'rgba(0,0,0,0.48)',
        offsetX: 0,
        offsetY: 16
      };
    }
    return {
      radius: 30,
      color: 'rgba(112,69,28,0.22)',
      offsetX: 0,
      offsetY: 16
    };
  }

  private tabTransition(): TransitionEffect {
    return TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ x: 0, y: CoopMotion.tabOffsetVp }))
      .animation({ duration: CoopMotion.tabDuration, curve: Curve.EaseOut });
  }

  private switchTab(index: number): void {
    if (index === 2) {
      this.refreshAchievements();
    }
    if (this.activeTab === index) {
      return;
    }
    this.getUIContext().animateTo({
      duration: CoopMotion.tabDuration,
      curve: Curve.EaseOut
    }, () => {
      this.activeTab = index;
    });
  }

  private recordFor(gameId: string): GameRecord {
    const found = this.snapshot.records.find((item: GameRecord) => item.gameId === gameId);
    if (found !== undefined) {
      return found;
    }
    return { gameId: gameId, highScore: 0, playCount: 0, lastPlayedAt: 0 };
  }

  private unlockedBadges(): number {
    return achievementSummaryForState(this.achievementState).unlocked;
  }

  private badgeTotal(): number {
    return achievementSummaryForState(this.achievementState).total;
  }

  private playStreak(): number {
    const days: number[] = [];
    this.snapshot.records.forEach((item: GameRecord) => {
      if (this.isVisibleGameId(item.gameId) && item.lastPlayedAt > 0) {
        const day = Math.floor(item.lastPlayedAt / 86400000);
        if (!days.includes(day)) {
          days.push(day);
        }
      }
    });
    if (days.length === 0) {
      return 0;
    }
    const today = Math.floor(Date.now() / 86400000);
    let streak = 0;
    for (let offset = 0; offset < 30; offset += 1) {
      if (days.includes(today - offset)) {
        streak += 1;
      } else if (offset === 0) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }
}
