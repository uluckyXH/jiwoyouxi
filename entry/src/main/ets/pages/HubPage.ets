import { CoopTheme } from '../design/CoopTheme';
import { CoopAppSnapshot, GameModule, GameRecord } from '../shell/GameModule';
import { GAME_MODULES, moduleById } from '../shell/GameRegistry';

const HOME_GAME_ORDER: string[] = ['suika', 'minesweeper', 'tetris', 'eggSling', 'whiteTiles', 'rps'];

@Component
export struct HubPage {
  @Prop snapshot: CoopAppSnapshot;
  openGame: (gameId: string) => void = () => {};
  toggleFavorite: (gameId: string) => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  updateHaptic: (enabled: boolean) => void = () => {};
  @State activeTab: number = 0;

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      this.LiquidBackdrop()
      Scroll() {
        Column({ space: 14 }) {
          if (this.activeTab === 0) {
            this.HomeContent()
          } else if (this.activeTab === 1) {
            this.FavoriteList()
          } else if (this.activeTab === 2) {
            this.Achievements()
          } else {
            this.Settings()
          }
          Blank()
            .height(94)
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .padding({ left: 20, right: 20, top: 34, bottom: 18 })
      }
      .width('100%')
      .height('100%')

      this.BottomTabBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CoopTheme.bgWarm)
  }

  @Builder
  LiquidBackdrop() {
    Stack() {
      Text('')
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [['#fff8ec', 0], ['#f7eddf', 0.62], ['#eef7fb', 1]]
        })
      Text('')
        .width('100%')
        .height(260)
        .linearGradient({
          angle: 140,
          colors: [['rgba(255,224,148,0.50)', 0], ['rgba(255,127,123,0.22)', 0.52], ['rgba(255,255,255,0.10)', 1]]
        })
        .position({ x: 0, y: 0 })
      Text('')
        .width('100%')
        .height(210)
        .linearGradient({
          angle: 0,
          colors: [['rgba(255,255,255,0.00)', 0], ['rgba(255,255,255,0.62)', 1]]
        })
        .position({ x: 0, y: 210 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HomeContent() {
    Column({ space: 14 }) {
      this.WelcomeHeader()
      this.HeroBanner()
      this.SectionTitleRow('精选游戏', '🐔', true)
      this.HomeGameGrid()
      this.StatsGrid()
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
          .fontColor(CoopTheme.ink)
        Text('今天玩什么呢？')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(CoopTheme.muted)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row({ space: 10 }) {
        Text('🔔')
          .width(42)
          .height(42)
          .fontSize(19)
          .textAlign(TextAlign.Center)
          .backgroundColor(CoopTheme.panel)
          .border({ width: 1, color: CoopTheme.line })
          .borderRadius(21)
          .shadow(CoopTheme.shadow)
        Image($r('app.media.app_icon'))
          .width(42)
          .height(42)
          .objectFit(ImageFit.Cover)
          .borderRadius(21)
          .backgroundColor(CoopTheme.panel)
          .border({ width: 1, color: CoopTheme.line })
          .shadow(CoopTheme.shadow)
      }
    }
    .width('100%')
  }

  @Builder
  HeroBanner() {
    Stack() {
      Row()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [['#ffe6a8', 0], ['#ffc95c', 0.46], ['#ff7f7b', 1]]
        })
      Text('')
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 90,
          colors: [['rgba(255,255,255,0.60)', 0], ['rgba(255,255,255,0.08)', 0.48], ['rgba(74,38,18,0.18)', 1]]
        })
      Row() {
        Image($r('app.media.app_icon'))
          .width(128)
          .height(118)
          .objectFit(ImageFit.Contain)
          .shadow(CoopTheme.glow)
        Column({ space: 7 }) {
          Text('鸡窝游戏')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fffaf2')
            .textShadow({ radius: 8, color: 'rgba(70,30,10,0.34)', offsetX: 0, offsetY: 2 })
          Text('没网也能玩一窝')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fffaf2')
          Button('开始游戏 ▶')
            .height(38)
            .padding({ left: 18, right: 18 })
            .borderRadius(19)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fffaf2')
            .backgroundColor('#ff6f76')
            .shadow({
              radius: 18,
              color: 'rgba(255,111,118,0.30)',
              offsetX: 0,
              offsetY: 8
            })
            .onClick(() => {
              this.openGame(this.heroGameId());
            })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
      }
      .height('100%')
      .width('100%')
      .padding({ left: 10, right: 16 })
    }
    .width('100%')
    .height(178)
    .borderRadius(28)
    .clip(true)
    .border({ width: 1, color: 'rgba(255,255,255,0.72)' })
    .shadow({
      radius: 40,
      color: 'rgba(88,52,24,0.16)',
      offsetX: 0,
      offsetY: 18
    })
    .onClick(() => {
      this.openGame(this.heroGameId());
    })
  }

  @Builder
  SectionTitleRow(title: string, icon: string, showMore: boolean) {
    Row() {
      Row({ space: 8 }) {
        Text(icon)
          .width(28)
          .height(28)
          .fontSize(17)
          .textAlign(TextAlign.Center)
          .backgroundColor('rgba(255,250,240,0.76)')
          .borderRadius(14)
          .border({ width: 1, color: CoopTheme.line })
        Text(title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
      }
      Blank()
      if (showMore) {
        Text('›')
          .width(34)
          .height(30)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
          .textAlign(TextAlign.Center)
          .backgroundColor('rgba(255,250,240,0.52)')
          .borderRadius(15)
          .border({ width: 1, color: CoopTheme.line })
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
      }, (item: GameModule) => item.id)
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(10)
    .columnsGap(10)
    .width('100%')
    .height(3 * 96 + 20)
  }

  @Builder
  HomeGameCard(module: GameModule) {
    Row({ space: 10 }) {
      Stack() {
        Text(module.icon)
          .fontSize(30)
          .fontColor(module.accent)
        Text(this.isFavorite(module.id) ? '★' : '☆')
          .width(24)
          .height(24)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isFavorite(module.id) ? CoopTheme.brand : 'rgba(123,108,98,0.58)')
          .textAlign(TextAlign.Center)
          .backgroundColor('rgba(255,255,255,0.78)')
          .borderRadius(12)
          .border({ width: 1, color: CoopTheme.line })
          .position({ x: 31, y: -7 })
          .onClick(() => {
            this.toggleFavorite(module.id);
          })
      }
      .width(48)
      .height(48)
      .borderRadius(16)
      .linearGradient({
        angle: 180,
        colors: [['#fff2d6', 0], ['#ffe2b5', 1]]
      })
      .border({ width: 1, color: 'rgba(111,73,39,0.10)' })

      Column({ space: 5 }) {
        Text(module.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.homeTag(module.id))
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor(CoopTheme.muted)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .height(96)
    .padding(12)
    .borderRadius(20)
    .backgroundColor(CoopTheme.panel)
    .border({ width: 1, color: CoopTheme.line })
    .shadow({
      radius: 18,
      color: 'rgba(92,58,28,0.08)',
      offsetX: 0,
      offsetY: 6
    })
    .onClick(() => {
      this.openGame(module.id);
    })
  }

  @Builder
  StatsGrid() {
    Row({ space: 10 }) {
      this.StatCard('连续游玩', `${this.playStreak()}`, '天', '🔥')
      this.StatCard('鸡窝徽章', `${this.unlockedBadges()}`, `/ ${this.badgeTotal()}`, '⭐')
    }
    .width('100%')
  }

  @Builder
  StatCard(label: string, value: string, suffix: string, icon: string) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 6 }) {
        Text(label)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(CoopTheme.muted)
        Row({ space: 3 }) {
          Text(value)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(CoopTheme.ink)
          Text(suffix)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(CoopTheme.brandDark)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      Text(icon)
        .fontSize(24)
        .opacity(0.72)
        .position({ x: 100, y: 10 })
    }
    .layoutWeight(1)
    .height(84)
    .padding(14)
    .borderRadius(22)
    .backgroundColor(CoopTheme.panel)
    .border({ width: 1, color: CoopTheme.line })
    .shadow({
      radius: 20,
      color: 'rgba(92,58,28,0.08)',
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  BottomTabBar() {
    Row() {
      this.BottomTabItem(0, '⌂', '首页')
      this.BottomTabItem(1, '♡', '收藏')
      this.BottomTabItem(2, '♕', '成就')
      this.BottomTabItem(3, '⚙', '设置')
    }
    .width('92%')
    .height(66)
    .padding({ left: 8, right: 8 })
    .margin({ bottom: 12 })
    .borderRadius(26)
    .backgroundColor('rgba(255,250,240,0.84)')
    .border({ width: 1, color: CoopTheme.line })
    .shadow({
      radius: 34,
      color: 'rgba(74,45,20,0.16)',
      offsetX: 0,
      offsetY: 10
    })
  }

  @Builder
  BottomTabItem(index: number, icon: string, label: string) {
    Column({ space: 3 }) {
      Text(icon)
        .fontSize(20)
        .fontColor(this.activeTab === index ? CoopTheme.coral : CoopTheme.muted)
      Text(label)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.activeTab === index ? CoopTheme.coral : CoopTheme.muted)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .borderRadius(20)
    .backgroundColor(this.activeTab === index ? 'rgba(255,127,123,0.10)' : 'rgba(255,255,255,0.00)')
    .onClick(() => {
      this.activeTab = index;
    })
  }

  @Builder
  FavoriteList() {
    Column({ space: 10 }) {
      this.SectionTitleRow('收藏', '♡', false)
      if (this.snapshot.favorites.length === 0) {
        this.EmptyPanel('在游戏卡片右上角点星标收藏。')
      } else {
        ForEach(this.snapshot.favorites, (gameId: string) => {
          this.WideGameRow(moduleById(gameId))
        }, (gameId: string) => gameId)
      }
    }
    .width('100%')
  }

  @Builder
  WideGameRow(module: GameModule) {
    Row({ space: 12 }) {
      Text(module.icon)
        .width(48)
        .height(48)
        .fontSize(28)
        .fontColor(module.accent)
        .textAlign(TextAlign.Center)
        .backgroundColor('rgba(255,242,214,0.78)')
        .borderRadius(16)
      Column({ space: 3 }) {
        Text(module.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
        Text(`${module.highScoreLabel} ${this.recordFor(module.id).highScore} · ${this.recordFor(module.id).playCount} 局`)
          .fontSize(12)
          .fontColor(CoopTheme.muted)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Button('开始')
        .height(36)
        .width(78)
        .borderRadius(18)
        .fontColor('#ffffff')
        .fontWeight(FontWeight.Bold)
        .backgroundColor(module.accent)
        .onClick(() => {
          this.openGame(module.id);
        })
    }
    .width('100%')
    .padding(12)
    .borderRadius(20)
    .backgroundColor(CoopTheme.panel)
    .border({ width: 1, color: CoopTheme.line })
    .shadow(CoopTheme.shadow)
  }

  @Builder
  Achievements() {
    Column({ space: 10 }) {
      this.SectionTitleRow('成就墙', '♕', false)
      this.AchievementRow('鸡窝开张', this.totalPlayCount() >= 1, '完成任意 1 局')
      this.AchievementRow('六边形鸡仔', this.playedGameCount() >= 6, '6 个游戏都玩过')
      this.AchievementRow('收藏家', this.snapshot.favorites.length >= 3, '收藏 3 个游戏')
      this.AchievementRow('节奏手感', this.recordFor('whiteTiles').highScore >= 50, '别踩白块达到 50 行')
      this.AchievementRow('方块脑', this.recordFor('tetris').highScore >= 1000, '俄罗斯方块达到 1000 分')
      this.AchievementRow('西瓜自由', this.recordFor('suika').highScore >= 500, '合成大西瓜达到 500 分')
    }
    .width('100%')
  }

  @Builder
  AchievementRow(title: string, unlocked: boolean, hint: string) {
    Row({ space: 10 }) {
      Text(unlocked ? '✓' : '·')
        .width(34)
        .height(34)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(unlocked ? '#ffffff' : CoopTheme.muted)
        .textAlign(TextAlign.Center)
        .backgroundColor(unlocked ? CoopTheme.green : CoopTheme.panelSoft)
        .border({ width: 1, color: CoopTheme.line })
        .borderRadius(12)
      Column({ space: 2 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
        Text(hint)
          .fontSize(12)
          .fontColor(CoopTheme.muted)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .borderRadius(20)
    .backgroundColor(CoopTheme.panel)
    .border({ width: 1, color: CoopTheme.line })
    .shadow(CoopTheme.shadow)
  }

  @Builder
  Settings() {
    Column({ space: 10 }) {
      this.SectionTitleRow('设置', '⚙', false)
      this.SettingSwitch('声音', this.snapshot.soundEnabled, () => {
        this.updateSound(!this.snapshot.soundEnabled);
      })
      this.SettingSwitch('触感反馈', this.snapshot.hapticEnabled, () => {
        this.updateHaptic(!this.snapshot.hapticEnabled);
      })
      Text('当前阶段只维护鸿蒙原生离线版本。iOS / Android 等你口令再做。')
        .width('100%')
        .fontSize(12)
        .fontColor(CoopTheme.muted)
        .padding(14)
        .borderRadius(20)
        .backgroundColor(CoopTheme.panel)
        .border({ width: 1, color: CoopTheme.line })
    }
    .width('100%')
  }

  @Builder
  SettingSwitch(label: string, enabled: boolean, action: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(CoopTheme.ink)
      Blank()
      Button(enabled ? '开' : '关')
        .width(64)
        .height(34)
        .borderRadius(17)
        .fontColor(enabled ? '#ffffff' : CoopTheme.ink)
        .backgroundColor(enabled ? CoopTheme.teal : CoopTheme.panelSoft)
        .border({ width: 1, color: CoopTheme.line })
        .onClick(() => {
          action();
        })
    }
    .width('100%')
    .padding(14)
    .borderRadius(20)
    .backgroundColor(CoopTheme.panel)
    .border({ width: 1, color: CoopTheme.line })
    .shadow(CoopTheme.shadow)
  }

  @Builder
  EmptyPanel(text: string) {
    Text(text)
      .width('100%')
      .padding(16)
      .fontSize(13)
      .fontColor(CoopTheme.muted)
      .borderRadius(20)
      .backgroundColor(CoopTheme.panel)
      .border({ width: 1, color: CoopTheme.line })
      .shadow(CoopTheme.shadow)
  }

  private homeModules(): GameModule[] {
    const modules: GameModule[] = [];
    HOME_GAME_ORDER.forEach((id: string) => {
      modules.push(moduleById(id));
    });
    return modules;
  }

  private heroGameId(): string {
    if (this.snapshot.recent.length > 0) {
      const id = this.snapshot.recent[0];
      const found = GAME_MODULES.find((item: GameModule) => item.id === id);
      if (found !== undefined) {
        return id;
      }
    }
    return 'suika';
  }

  private homeTag(gameId: string): string {
    if (gameId === 'suika') return '水果乱炖';
    if (gameId === 'minesweeper') return '小心鸡雷';
    if (gameId === 'tetris') return '方块下蛋';
    if (gameId === 'eggSling') return '咻啪发射';
    if (gameId === 'whiteTiles') return '鸡爪节奏';
    return '鸡窝乱斗';
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

  private recordFor(gameId: string): GameRecord {
    const found = this.snapshot.records.find((item: GameRecord) => item.gameId === gameId);
    if (found !== undefined) {
      return found;
    }
    return { gameId: gameId, highScore: 0, playCount: 0, lastPlayedAt: 0 };
  }

  private totalPlayCount(): number {
    let total = 0;
    this.snapshot.records.forEach((item: GameRecord) => {
      total += item.playCount;
    });
    return total;
  }

  private playedGameCount(): number {
    let total = 0;
    this.snapshot.records.forEach((item: GameRecord) => {
      if (item.playCount > 0) {
        total += 1;
      }
    });
    return total;
  }

  private unlockedBadges(): number {
    let count = 0;
    if (this.totalPlayCount() >= 1) count += 1;
    if (this.playedGameCount() >= 6) count += 1;
    if (this.snapshot.favorites.length >= 3) count += 1;
    if (this.recordFor('whiteTiles').highScore >= 50) count += 1;
    if (this.recordFor('tetris').highScore >= 1000) count += 1;
    if (this.recordFor('suika').highScore >= 500) count += 1;
    return count;
  }

  private badgeTotal(): number {
    return 6;
  }

  private playStreak(): number {
    const days: number[] = [];
    this.snapshot.records.forEach((item: GameRecord) => {
      if (item.lastPlayedAt > 0) {
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
