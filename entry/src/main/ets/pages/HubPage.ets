import { common } from '@kit.AbilityKit';
import { AppIcon } from '../components/AppIcon';
import { HubInsets, HubLayout, HubRect, hubInsets, hubLayout } from '../design/HubLayout';
import { HubSession } from '../design/HubSession';
import { HubWindow } from '../design/HubWindow';
import { achievementSummaryForState } from '../shell/AchievementEngine';
import { AchievementState } from '../shell/AchievementModule';
import { APPEARANCE_DARK, APPEARANCE_LIGHT, APPEARANCE_SYSTEM, CoopAppSnapshot, GameModule, GameRecord, isGameHidden } from '../shell/GameModule';
import { GAME_MODULES, moduleById, gameLogoPath } from '../shell/GameRegistry';
import { AchievementWall } from './AchievementWall';
import { HubGameCard } from './HubGameCard';
import { HubHeroBanner } from './HubHeroBanner';
import { HubNavigation, hubNavigationSurface } from './HubNavigation';
import { HubScroll } from './HubScroll';
import { HubSettingsPanel } from './HubSettingsPanel';
import { HubStatsPanel } from './HubStatsPanel';
import { PlayStreakSheet } from './PlayStreakSheet';
import { currentPlayStreak } from '../design/PlayActivity';

const HOME_GAME_ORDER: string[] = [
  'bloomLines',
  'tangram',
  'suikaNext', 'minesweeperNext', 'tetrisNext', 'chicken2048Next', 'freecellNext', 'rpsBattleNext'
];

// Hide classic entry points on Home while retaining their routes, saves and favorites.
const HIDDEN_HOME_GAME_IDS: string[] = ['chicken2048', 'minesweeper', 'suika', 'tetris', 'freecell', 'rps', 'rpsBattle'];

@Component
export struct HubPage {
  @Prop snapshot: CoopAppSnapshot;
  @Prop @Watch('appearanceChanged') dark: boolean = false;
  @Prop achievementState: AchievementState;
  @Prop playDays: number[] = [];
  @State private streakPresented: boolean = false;
  @ObjectLink session: HubSession;
  openGame: (gameId: string) => void = () => {};
  resetAchievements: () => Promise<boolean> = async (): Promise<boolean> => false;
  refreshAchievements: () => Promise<void> = async (): Promise<void> => {};
  toggleFavorite: (gameId: string) => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  updateHaptic: (enabled: boolean) => void = () => {};
  updateAppearanceMode: (appearanceMode: string) => void = () => {};
  @State private layout: HubLayout = hubLayout(390, 844);
  @State private feedback: string = '';
  private pageWidth: number = 390;
  private pageHeight: number = 844;
  private insets: HubInsets = hubInsets();
  private creases: HubRect[] = [];
  private windowObserver: HubWindow = new HubWindow();
  private feedbackTimer: number = -1;
  private launching: boolean = false;

  aboutToAppear(): void {
    const ui = this.getUIContext();
    const context = ui.getHostContext();
    this.windowObserver.setDark(this.isDarkMode());
    if (context !== undefined) {
      this.windowObserver.attach(context, (px: number): number => ui.px2vp(px),
        (insets: HubInsets, creases: HubRect[]) => {
          ui.runScopedTask(() => {
            this.insets = insets;
            this.creases = creases;
            this.relayout();
          });
        });
    }
  }

  aboutToDisappear(): void {
    this.windowObserver.release();
    if (this.feedbackTimer >= 0) clearTimeout(this.feedbackTimer);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.layout.navigation === 'bottom') {
        // Carry the bar surface behind the system gesture area, without moving its controls.
        Row()
          .width(this.layout.frame.width)
          .height(this.layout.navigationHeight + this.navigationBottomInset())
          .position({ x: this.layout.frame.x,
            y: this.layout.frame.y + this.layout.frame.height - this.layout.navigationHeight })
          .backgroundColor(hubNavigationSurface(this.isDarkMode()))
          .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      }
      Column() {
        Row() {
          if (this.layout.navigation !== 'bottom') {
            this.Navigation()
          }
          Column() {
            this.ActiveTabContent()
          }
          .width(this.layout.frame.width - this.layout.navigationWidth)
          .height('100%')
          .padding({ left: this.layout.padding, right: this.layout.padding,
            top: this.layout.padding, bottom: this.layout.bottomPadding })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height(this.layout.frame.height - this.layout.navigationHeight)
        .alignItems(VerticalAlign.Top)
        if (this.layout.navigation === 'bottom') {
          this.Navigation()
        }
      }
      .width(this.layout.frame.width)
      .height(this.layout.frame.height)
      .position({ x: this.layout.frame.x, y: this.layout.frame.y })
      if (this.feedback.length > 0) {
        Text(this.feedback)
          .fontSize(13).fontColor(this.inkColor())
          .padding({ left: 18, right: 18, top: 12, bottom: 12 })
          .backgroundColor(this.panelColor()).borderRadius(22)
          .border({ width: 1, color: this.lineColor() })
          .constraintSize({ maxWidth: Math.max(100, this.layout.frame.width - 32) })
          .position({ x: this.layout.frame.x + 16,
            y: this.layout.frame.y + this.layout.frame.height - this.layout.navigationHeight - 58 })
          .hitTestBehavior(HitTestMode.None)
          .accessibilityText(this.feedback)
      }
    }
    .width('100%').height('100%')
    .backgroundColor(this.homeBgColor())
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END])
    .onAreaChange((oldArea, area) => {
      const width = Number(area.width);
      const height = Number(area.height);
      if (width > 0 && height > 0 && (width !== this.pageWidth || height !== this.pageHeight)) {
        this.pageWidth = width;
        this.pageHeight = height;
        this.relayout();
        this.windowObserver.measure();
      }
    })
    .bindSheet($$this.streakPresented, this.StreakSheet(), {
      height: SheetSize.FIT_CONTENT, dragBar: true, showClose: true
    })
  }

  @Builder
  StreakSheet() {
    PlayStreakSheet({ days: this.playDays, dark: this.isDarkMode() })
  }

  @Builder
  Navigation() {
    HubNavigation({ mode: this.layout.navigation, activeTab: this.session.activeTab,
      dark: this.isDarkMode(), short: this.layout.short, select: (tab: number) => this.switchTab(tab) })
  }

  @Builder
  ActiveTabContent() {
    if (this.session.activeTab === 0) {
      Column() {
        HubScroll({ session: this.session, slot: 0 }) {
          this.HomeContent()
        }
      }.width(this.layout.contentWidth).height('100%')
    } else if (this.session.activeTab === 1) {
      Column() {
        HubScroll({ session: this.session, slot: 1 }) {
          this.FavoriteList()
        }
      }.width(this.layout.contentWidth).height('100%')
    } else if (this.session.activeTab === 2) {
      AchievementWall({ achievementState: this.achievementState, session: this.session,
        isDarkMode: this.isDarkMode(), splitDetail: this.layout.splitDetail,
        detailWidth: this.layout.detailWidth })
        .width(this.layout.contentWidth).height('100%')
    } else {
      Column() {
      HubScroll({ session: this.session, slot: 3 }) {
        HubSettingsPanel({ appearanceMode: this.snapshot.appearanceMode, isDarkMode: this.isDarkMode(),
          roomy: this.layout.contentWidth >= 700,
          stackedAppearance: this.layout.contentWidth < 320 * this.layout.textScale,
          updateAppearanceMode: this.updateAppearanceMode })
      }
      }.width(Math.min(900, this.layout.contentWidth)).height('100%')
    }
  }

  @Builder
  HomeContent() {
    Column({ space: this.layout.gap + 2 }) {
      this.WelcomeHeader()
      if (this.layout.showOverview) {
        Row({ space: 20 }) {
          HubHeroBanner({ isDarkMode: this.isDarkMode(), availableWidth: this.layout.contentWidth - 304,
            textScale: this.layout.textScale, gameTitle: this.heroTitle(), spacious: true,
            bannerHeight: 252, startGame: () => this.launchGame(this.heroGameId()) }).layoutWeight(1)
          this.Overview()
        }.width('100%').alignItems(VerticalAlign.Top)
      } else {
        HubHeroBanner({ isDarkMode: this.isDarkMode(), availableWidth: this.layout.contentWidth,
          textScale: this.layout.textScale, gameTitle: this.heroTitle(),
          spacious: this.layout.contentWidth >= 500, compact: this.layout.short,
          bannerHeight: this.layout.heroHeight, startGame: () => this.launchGame(this.heroGameId()) })
      }
      this.SectionTitle(false)
      this.GameGrid(false)
      HubStatsPanel({ playStreak: this.playStreak(), unlockedBadges: this.unlockedBadges(),
        stacked: this.layout.contentWidth < 280 * this.layout.textScale,
        badgeTotal: this.badgeTotal(), isDarkMode: this.isDarkMode(),
        openStreak: () => { this.streakPresented = true; }, openAchievements: () => this.openAchievementWall() })
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  WelcomeHeader() {
    Row({ space: 12 }) {
      Column({ space: 5 }) {
        Text(this.greetingTitle()).fontSize(this.layout.navigation === 'bottom' ? 22 : 28)
          .fontWeight(FontWeight.Bold).fontColor(this.inkColor())
        Text('今天玩什么呢？').fontSize(13).fontColor(this.mutedColor())
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Button({ type: ButtonType.Circle }) {
        AppIcon({ name: this.snapshot.appearanceMode === APPEARANCE_SYSTEM ? 'theme_auto' :
          this.isDarkMode() ? 'moon' : 'sun', iconSize: 22, tint: this.activeColor() })
      }
      .width(44).height(44).backgroundColor(this.panelColor())
      .border({ width: 1, color: this.lineColor() })
      .accessibilityText(`选择外观，当前${this.snapshot.appearanceMode === APPEARANCE_SYSTEM ? '跟随系统，' : ''}${this.isDarkMode() ? '深色' : '浅色'}`)
      .bindMenu([
        { value: this.appearanceMenuLabel(APPEARANCE_SYSTEM, '跟随系统'), action: () => this.updateAppearanceMode(APPEARANCE_SYSTEM) },
        { value: this.appearanceMenuLabel(APPEARANCE_LIGHT, '浅色'), action: () => this.updateAppearanceMode(APPEARANCE_LIGHT) },
        { value: this.appearanceMenuLabel(APPEARANCE_DARK, '深色'), action: () => this.updateAppearanceMode(APPEARANCE_DARK) }
      ])
      if (this.layout.navigation === 'bottom' && this.layout.frame.width >= 360) {
        Image($rawfile('app/ui/chicken.svg')).width(42).height(42)
          .objectFit(ImageFit.Contain).accessibilityLevel('no')
      }
    }.width('100%').alignItems(VerticalAlign.Center)
  }

  @Builder
  SectionTitle(favorites: boolean) {
    Row({ space: 12 }) {
      Text(favorites ? '我的收藏' : '精选游戏')
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.inkColor()).layoutWeight(1)
      Text(favorites ? `${this.favoriteModules().length} 款常玩游戏` : `${this.homeModules().length} 款随心玩`)
        .fontSize(11).fontColor(this.mutedColor()).maxLines(1)
    }.width('100%').padding({ top: 6, bottom: 2 })
  }

  @Builder
  GameGrid(favorites: boolean) {
    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Start }) {
      ForEach(favorites ? this.favoriteModules() : this.homeModules(), (game: GameModule, index: number) => {
        HubGameCard({ game: game, subtitle: this.homeTag(game.id),
          detail: favorites ? this.favoriteRecordText(game) : '', favorite: this.isFavorite(game.id),
          dark: this.isDarkMode(), textScale: this.layout.textScale, cardWidth: this.layout.cardWidth,
          launch: (id: string) => this.launchGame(id), toggleFavorite: (id: string) => this.changeFavorite(id) })
          .width(this.layout.cardWidth)
          .margin({ right: (index + 1) % this.layout.columns === 0 ? 0 : this.layout.gap,
            bottom: this.layout.gap })
      }, (game: GameModule) => game.id)
    }.width('100%')
  }

  @Builder
  Overview() {
    Column({ space: 12 }) {
      Row() {
        Text('最近玩过').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.inkColor())
        Blank()
        Text('随时再来一局').fontSize(10).fontColor(this.mutedColor())
      }.width('100%')
      if (this.recentGames().length > 0) {
        ForEach(this.recentGames(), (game: GameModule) => {
          Button({ type: ButtonType.Normal }) {
            Row({ space: 10 }) {
              Image($rawfile(gameLogoPath(game.id))).width(36).height(36).objectFit(ImageFit.Contain)
              Column({ space: 3 }) {
                Text(game.title).fontSize(13).fontWeight(FontWeight.Medium).fontColor(this.inkColor())
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.homeTag(game.id)).fontSize(10).fontColor(this.mutedColor())
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              AppIcon({ name: 'play', iconSize: 15, tint: this.activeColor() })
            }.width('100%')
          }.width('100%').height(52).padding(8).borderRadius(12)
          .backgroundColor(this.isDarkMode() ? '#30291F' : '#FFF1D9')
          .onClick(() => this.launchGame(game.id))
        }, (game: GameModule) => game.id)
      } else {
        Text('从喜欢的一款开始，\n你的游玩足迹会留在这里。')
          .fontSize(12).lineHeight(22).fontColor(this.mutedColor())
          .width('100%').layoutWeight(1)
      }
      Blank()
      Button({ type: ButtonType.Normal }) {
        Row() {
          AppIcon({ name: 'medal', iconSize: 20, tint: this.activeColor() })
          Text(`已收集 ${this.unlockedBadges()} / ${this.badgeTotal()} 枚徽章`)
            .fontSize(12).fontColor(this.inkColor()).layoutWeight(1).margin({ left: 8 })
          AppIcon({ name: 'chevron_right', iconSize: 16, tint: this.mutedColor() })
        }.width('100%')
      }.width('100%').height(42).padding(0).backgroundColor(Color.Transparent)
      .onClick(() => this.openAchievementWall())
    }
    .width(284).height(252).padding(18).borderRadius(24)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.panelColor()).border({ width: 1, color: this.lineColor() })
  }

  @Builder
  FavoriteList() {
    Column({ space: 14 }) {
      this.SectionTitle(true)
      Text('把喜欢的留在身边，想玩时一眼就找到。').fontSize(13).fontColor(this.mutedColor())
        .width('100%')
      if (this.favoriteModules().length > 0) {
        this.GameGrid(true)
      } else {
        Column({ space: 14 }) {
          Image($rawfile('app/ui/favorites_empty.svg')).width(84).height(84).objectFit(ImageFit.Contain)
            .accessibilityLevel('no')
          Text('还没有收藏').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.inkColor())
          Text('点亮游戏卡片上的星星，\n在这里安放你的心头好。')
            .fontSize(13).lineHeight(22).fontColor(this.mutedColor()).textAlign(TextAlign.Center)
          Button('去首页看看').fontSize(14).fontColor('#493018').backgroundColor('#F7C66B')
            .height(44).padding({ left: 24, right: 24 }).onClick(() => this.switchTab(0))
        }
        .width('100%').constraintSize({ maxWidth: 480 })
        .padding({ top: 40, bottom: 40, left: 24, right: 24 })
        .backgroundColor(this.panelColor()).borderRadius(24)
        .border({ width: 1, color: this.lineColor() }).margin({ top: 16 })
      }
    }.width('100%')
  }

  private navigationBottomInset(): number {
    const remaining = this.pageHeight - this.layout.frame.y - this.layout.frame.height;
    // A half-folded pane can end at a hinge instead of at the physical bottom of the window.
    return remaining <= this.insets.bottom + 1 ? Math.max(0, remaining) : 0;
  }

  private relayout(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const fontScale = context?.config?.fontSizeScale ?? 1;
    this.layout = hubLayout(this.pageWidth, this.pageHeight, this.insets, this.creases, fontScale);
  }

  private async launchGame(id: string): Promise<void> {
    if (this.launching) return;
    this.launching = true;
    // Restore the hub's window policy before mounting a game, not after its exit transition.
    await this.windowObserver.release();
    this.openGame(id);
  }

  private appearanceChanged(): void { this.windowObserver.setDark(this.isDarkMode()); }

  private switchTab(tab: number): void {
    if (tab === this.session.activeTab) return;
    this.feedback = '';
    this.session.activeTab = tab;
    if (tab === 2) this.refreshAchievements();
  }

  private openAchievementWall(): void {
    this.session.achievementFilter = 'all';
    this.session.detailOpen = false;
    this.session.scrollOffsets[2] = 0;
    this.switchTab(2);
  }

  private changeFavorite(id: string): void {
    const removing = this.isFavorite(id);
    this.toggleFavorite(id);
    this.feedback = removing ? '已取消收藏' : '已加入收藏';
    if (this.feedbackTimer >= 0) clearTimeout(this.feedbackTimer);
    this.feedbackTimer = setTimeout(() => { this.feedback = ''; }, 1600);
  }

  private homeModules(): GameModule[] {
    const ordered: GameModule[] = [];
    HOME_GAME_ORDER.forEach((id: string) => {
      const game = GAME_MODULES.find((item: GameModule) => item.id === id);
      if (game !== undefined) ordered.push(game);
    });
    // Newly registered games appear without requiring a second shell integration.
    GAME_MODULES.forEach((game: GameModule) => {
      if (!HOME_GAME_ORDER.includes(game.id)) ordered.push(game);
    });
    return ordered.filter((game: GameModule) => !HIDDEN_HOME_GAME_IDS.includes(game.id) && !isGameHidden(game.id));
  }
  private favoriteModules(): GameModule[] {
    const favorites: GameModule[] = [];
    this.snapshot.favorites.forEach((id: string) => {
      const game = GAME_MODULES.find((item: GameModule) => item.id === id);
      if (game !== undefined && !isGameHidden(game.id)) favorites.push(game);
    });
    return favorites;
  }
  private recentGames(): GameModule[] {
    return this.homeModules().filter((game: GameModule) => this.snapshot.recent.includes(game.id))
      .sort((a: GameModule, b: GameModule) => this.snapshot.recent.indexOf(a.id) - this.snapshot.recent.indexOf(b.id))
      .slice(0, 2);
  }
  private heroGameId(): string { return this.recentGames().length > 0 ? this.recentGames()[0].id : 'suikaNext'; }
  private heroTitle(): string { return `${moduleById(this.heroGameId()).title} · ${this.homeTag(this.heroGameId())}`; }
  private isFavorite(id: string): boolean { return this.snapshot.favorites.includes(id); }
  private isVisibleGameId(id: string): boolean { return !isGameHidden(id) && GAME_MODULES.some((game: GameModule) => game.id === id); }
  private appearanceMenuLabel(mode: string, label: string): string {
    return this.snapshot.appearanceMode === mode ? `${label} · 已选择` : label;
  }
  private isDarkMode(): boolean { return this.dark; }
  private homeBgColor(): string { return this.isDarkMode() ? '#101110' : '#FFF4E4'; }
  private inkColor(): string { return this.isDarkMode() ? '#FFF2DF' : '#39291E'; }
  private mutedColor(): string { return this.isDarkMode() ? '#C8B7A2' : '#806A54'; }
  private activeColor(): string { return this.isDarkMode() ? '#FFD083' : '#A76720'; }
  private panelColor(): string { return this.isDarkMode() ? '#211F1B' : '#FFFAF2'; }
  private lineColor(): string { return this.isDarkMode() ? '#44392B' : '#E9D9C1'; }

  private homeTag(gameId: string): string {
    if (gameId === 'bloomLines') return '花窗连珠';
    if (gameId === 'rpsBattle') return '鸡窝乱斗';
    if (gameId === 'tangram') return '七巧小院';
    if (gameId === 'rpsBattleNext') return '庭院擂台';
    if (gameId === 'suikaNext') return '鲜果合成';
    if (gameId === 'suika') return '经典版';
    if (gameId === 'chicken2048Next') return '暖光叠数';
    if (gameId === 'chicken2048') return '经典版';
    if (gameId === 'minesweeperNext') return '庭院探雷';
    if (gameId === 'minesweeper') return '经典版';
    if (gameId === 'tetrisNext') return '方块工坊';
    if (gameId === 'tetris') return '经典版';
    if (gameId === 'freecellNext') return '暖木牌室';
    if (gameId === 'freecell') return '经典版';
    return moduleById(gameId).tags.slice(0, 2).join(' · ');
  }



  private favoriteRecordText(module: GameModule): string {
    const record = this.recordFor(module.id);
    return record.playCount > 0 ? `${module.highScoreLabel} ${record.highScore} · ${record.playCount} 局` : '还没玩过，来试试吧';
  }

  private greetingTitle(): string {
    const hour = new Date().getHours();
    if (hour >= 5 && hour < 11) return '早上好，鸡仔！';
    if (hour >= 11 && hour < 14) return '中午好，鸡仔！';
    if (hour >= 14 && hour < 18) return '下午好，鸡仔！';
    if (hour >= 18 && hour < 23) return '晚上好，鸡仔！';
    return '还不睡，鸡仔？';
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
    return currentPlayStreak(this.playDays, Date.now());
  }
}
