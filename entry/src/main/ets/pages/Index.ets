import { achievementCanonicalGameId } from '../shell/AchievementRegistry';
import { HubSession } from '../design/HubSession';
import { localPlayDay, normalizePlayDays, playDaysWithLegacyRecords } from '../design/PlayActivity';
import { BlockWorkshopPage } from '../gamesNext/blockWorkshop/BlockWorkshopPage';
import { common } from '@kit.AbilityKit';
import { AchievementService } from '../app/AchievementService';
import { CoopStorage } from '../app/CoopStorage';
import { AchievementUnlockNotice } from '../components/AchievementUnlockNotice';
import { CoopMotion } from '../design/CoopMotion';
import { emptyAchievementState } from '../shell/AchievementEngine';
import {
  favoriteAchievementEventAfterPersist,
  favoriteSnapshotAfterPersist,
  favoriteSnapshotAfterToggle,
  FavoriteSnapshotToggleResult
} from '../shell/AchievementFavoriteEvent';
import {
  AchievementApplyResult,
  AchievementEvent,
  AchievementNoticeItem,
  AchievementState
} from '../shell/AchievementModule';
import { achievementNoticeItemsForUnlocks, emptyAchievementNoticeItem } from '../shell/AchievementNotice';
import { CoopAppSnapshot, emptySnapshot, GameRecord, isDarkAppearance, normalizeAppearanceMode } from '../shell/GameModule';
import { GameEntryBadge } from '../shell/GameEntryBadge';
import { GameSceneTransition } from '../shell/GameSceneTransition';
import { HubPage } from './HubPage';
import { StartupPage } from './StartupPage';
import { RpsPage } from '../games/rps/RpsPage';
import { RpsBattlePage } from '../games/rpsBattle/RpsBattlePage';
import { CoopArenaPage } from '../gamesNext/coopArena/CoopArenaPage';
import { FreecellPage } from '../games/freecell/FreecellPage';
import { FreecellRoomPage } from '../gamesNext/warmFreecell/FreecellRoomPage';
import { MinesweeperPage } from '../games/minesweeper/MinesweeperPage';
import { MineGardenPage } from '../gamesNext/minesweeper/MineGardenPage';
import { Chicken2048Page } from '../games/chicken2048/Chicken2048Page';
import { GlowPage } from '../gamesNext/glow2048/GlowPage';
import { TetrisPage } from '../games/tetris/TetrisPage';
import { SuikaPage } from '../games/suika/SuikaPage';
import { FruitMarketPage } from '../gamesNext/fruitMarket/FruitMarketPage';

@Entry
@Component
struct Index {
  private appContext: common.Context | undefined = undefined;
  private achievementService: AchievementService = new AchievementService();
  private entryBadgeInTimer: number = -1;
  private entryBadgeOutTimer: number = -1;
  private entryBadgeUnmountTimer: number = -1;
  private achievementNoticeQueue: AchievementNoticeItem[] = [];
  private achievementNoticeInTimer: number = -1;
  private achievementNoticeHoldTimer: number = -1;
  private achievementNoticeUnmountTimer: number = -1;
  private snapshotSaveQueue: Promise<boolean> = Promise.resolve(true);
  private snapshotRevision: number = 0;
  private favoriteAchievementEventSequence: number = 0;
  private startupActive: boolean = false;
  private playDaysSaveQueue: Promise<boolean> = Promise.resolve(true);
  @State private playDays: number[] = [];
  @State private startupReady: boolean = false;
  @StorageProp('coop.systemDark') private systemDark: boolean = false;
  @State private hubSession: HubSession = new HubSession();
  @State snapshot: CoopAppSnapshot = emptySnapshot();
  @State achievementState: AchievementState = emptyAchievementState();
  @State activeGame: string = 'hub';
  @State tetrisSession: number = 0;
  @State blockWorkshopExitRequest: number = 0;
  @State sceneDirection: string = 'push';
  @State sceneTransitioning: boolean = false;
  @State entryBadgeGameId: string = 'rpsBattle';
  @State entryBadgeMounted: boolean = false;
  @State entryBadgeVisible: boolean = false;
  @State achievementNotice: AchievementNoticeItem = emptyAchievementNoticeItem();
  @State achievementNoticeMounted: boolean = false;
  @State achievementNoticeVisible: boolean = false;
  @State minesweeperExitRequestId: number = 0;
  @State mineGardenExitRequest: number = 0;
  @State glow2048ExitRequest: number = 0;
  @State freecellRoomExitRequest: number = 0;
  @State fruitMarketExitRequest: number = 0;
  @State coopArenaExitRequest: number = 0;

  aboutToAppear(): void {
    this.startupActive = true;
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      const appContext = context as common.Context;
      this.appContext = appContext;
      // Restore local UI data before mounting the hub.
      Promise.all([
        CoopStorage.load(appContext).then((snapshot: CoopAppSnapshot) => {
          if (this.startupActive) {
            this.saveSnapshot(snapshot);
          }
        }).catch(() => {
          console.warn('Unable to restore the app snapshot during startup');
        }),
        CoopStorage.loadPlayDays(appContext).then((days: number[]) => {
          if (this.startupActive) this.playDays = days;
        }),
        this.achievementService.initialize(appContext).then((state: AchievementState) => {
          if (this.startupActive) {
            this.achievementState = state;
          }
        }).catch(() => {
          console.warn('Unable to restore achievements during startup');
        })
      ]).then(() => {
        if (this.startupActive) {
          this.playDays = playDaysWithLegacyRecords(this.playDays, this.snapshot.records);
          this.persistPlayDays();
          this.startupReady = true;
        }
      });
    } else {
      this.startupReady = true;
    }
  }

  onBackPress(): boolean {
    if (this.activeGame === 'rpsBattleNext') {
      this.coopArenaExitRequest += 1;
      return true;
    }
    if (this.activeGame === 'freecellNext') {
      this.freecellRoomExitRequest += 1;
      return true;
    }
    if (this.activeGame === 'chicken2048Next') {
      this.glow2048ExitRequest += 1;
      return true;
    }
    if (this.activeGame === 'hub') {
      if (this.hubSession.activeTab === 2 && this.hubSession.detailOpen) {
        this.hubSession.detailOpen = false;
        return true;
      }
      if (this.hubSession.activeTab !== 0) {
        this.hubSession.activeTab = 0;
        return true;
      }
    }
    if (this.activeGame === 'minesweeperNext') {
      this.mineGardenExitRequest += 1;
      return true;
    }
    if (this.activeGame === 'tetrisNext') {
      this.blockWorkshopExitRequest += 1;
      return true;
    }
    if (this.activeGame === 'suikaNext') {
      this.fruitMarketExitRequest += 1;
      return true;
    }
    if (this.activeGame === 'minesweeper') {
      this.requestMinesweeperExit();
      return true;
    }
    if (this.activeGame !== 'hub') {
      this.closeGameAnimated();
      return true;
    }
    return false;
  }

  aboutToDisappear(): void {
    this.startupActive = false;
    this.clearEntryBadgeTimers();
    this.clearAchievementNotices();
  }

  build() {
    Stack() {
      if (!this.startupReady) {
        StartupPage()
      } else if (this.activeGame === 'hub') {
        GameSceneTransition({ role: 'hub', sceneDirection: this.sceneDirection }) {
          HubPage({
            session: this.hubSession,
            playDays: this.playDays,
            dark: this.isDarkMode(),
            snapshot: this.snapshot,
            achievementState: this.achievementState,
            openGame: (gameId: string) => {
              this.openGame(gameId);
            },
            resetAchievements: () => {
              return this.resetAchievements();
            },
            refreshAchievements: () => {
              return this.refreshAchievementState();
            },
            toggleFavorite: (gameId: string) => {
              this.toggleFavorite(gameId);
            },
            updateSound: (enabled: boolean) => {
              this.updateSound(enabled);
            },
            updateHaptic: (enabled: boolean) => {
              this.updateHaptic(enabled);
            },
            updateAppearanceMode: (appearanceMode: string) => {
              this.updateAppearanceMode(appearanceMode);
            }
          })
        }
      } else if (this.activeGame === 'rps') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          RpsPage({
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('rps', score);
            }
          })
        }
      } else if (this.activeGame === 'rpsBattleNext') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          CoopArenaPage({
            dark: this.isDarkMode(),
            soundEnabled: this.snapshot.soundEnabled,
            exitRequest: this.coopArenaExitRequest,
            exitToHub: () => this.closeGameAnimated(),
            recordScore: (score: number) => this.recordGameResult('rpsBattleNext', score),
            updateSound: (enabled: boolean) => this.updateSound(enabled),
            reportAchievementEvent: (event: AchievementEvent) => this.reportAchievementEvent(event)
          })
        }
      } else if (this.activeGame === 'rpsBattle') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          RpsBattlePage({
            bestScore: this.recordFor('rpsBattle').highScore,
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('rpsBattle', score);
            },
            reportAchievementEvent: (event: AchievementEvent) => {
              return this.reportAchievementEvent(event);
            }
          })
        }
      } else if (this.activeGame === 'freecellNext') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          FreecellRoomPage({
            dark: this.isDarkMode(),
            soundEnabled: this.snapshot.soundEnabled,
            exitRequest: this.freecellRoomExitRequest,
            exitToHub: () => this.closeGameAnimated(),
            updateSound: (enabled: boolean) => this.updateSound(enabled),
            recordScore: (score: number) => this.recordGameResult('freecellNext', score),
            reportAchievementEvent: (event: AchievementEvent) => this.reportAchievementEvent(event)
          })
        }
      } else if (this.activeGame === 'freecell') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          FreecellPage({
            bestScore: this.recordFor('freecell').highScore,
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('freecell', score);
            },
            reportAchievementEvent: (event: AchievementEvent) => {
              return this.reportAchievementEvent(event);
            }
          })
        }
      } else if (this.activeGame === 'minesweeperNext') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          MineGardenPage({
            dark: this.isDarkMode(),
            bestScore: this.recordFor('minesweeperNext').highScore,
            soundEnabled: this.snapshot.soundEnabled,
            exitRequest: this.mineGardenExitRequest,
            exitToHub: () => this.closeGameAnimated(),
            recordScore: (score: number) => this.recordGameResult('minesweeperNext', score),
            updateSound: (enabled: boolean) => this.updateSound(enabled),
            reportAchievementEvent: (event: AchievementEvent) => this.reportAchievementEvent(event)
          })
        }
      } else if (this.activeGame === 'minesweeper') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          MinesweeperPage({
            bestScore: this.recordFor('minesweeper').highScore,
            externalExitRequestId: this.minesweeperExitRequestId,
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('minesweeper', score);
            },
            reportAchievementEvent: (event: AchievementEvent) => {
              return this.reportAchievementEvent(event);
            }
          })
        }
      } else if (this.activeGame === 'chicken2048Next') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          GlowPage({
            dark: this.isDarkMode(),
            bestScore: this.recordFor('chicken2048Next').highScore,
            soundEnabled: this.snapshot.soundEnabled,
            exitRequest: this.glow2048ExitRequest,
            exitToHub: () => this.closeGameAnimated(),
            recordScore: (score: number) => this.recordGameResult('chicken2048Next', score),
            updateSound: (enabled: boolean) => this.updateSound(enabled),
            reportAchievementEvent: (event: AchievementEvent) => this.reportAchievementEvent(event)
          })
        }
      } else if (this.activeGame === 'chicken2048') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          Chicken2048Page({
            bestScore: this.recordFor('chicken2048').highScore,
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('chicken2048', score);
            },
            reportAchievementEvent: (event: AchievementEvent) => {
              return this.reportAchievementEvent(event);
            }
          })
        }
      } else if (this.activeGame === 'tetrisNext') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          BlockWorkshopPage({
            dark: this.isDarkMode(),
            bestScore: this.recordFor('tetrisNext').highScore,
            soundEnabled: this.snapshot.soundEnabled,
            exitRequest: this.blockWorkshopExitRequest,
            exitToHub: () => this.closeGameAnimated(),
            recordScore: (score: number) => this.recordGameResult('tetrisNext', score),
            updateSound: (enabled: boolean) => this.updateSound(enabled),
            reportAchievementEvent: (event: AchievementEvent) => this.reportAchievementEvent(event)
          })
        }
      } else if (this.activeGame === 'tetris') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          TetrisPage({
            bestScore: this.recordFor('tetris').highScore,
            session: this.tetrisSession,
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('tetris', score);
            },
            reportAchievementEvent: (event: AchievementEvent) => {
              return this.reportAchievementEvent(event);
            }
          })
        }
      } else if (this.activeGame === 'suikaNext') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          FruitMarketPage({
            dark: this.isDarkMode(),
            bestScore: this.recordFor('suikaNext').highScore,
            soundEnabled: this.snapshot.soundEnabled,
            exitRequest: this.fruitMarketExitRequest,
            exitToHub: () => this.closeGameAnimated(),
            recordScore: (score: number) => this.recordGameResult('suikaNext', score),
            updateSound: (enabled: boolean) => this.updateSound(enabled),
            reportAchievementEvent: (event: AchievementEvent) => this.reportAchievementEvent(event)
          })
        }
      } else if (this.activeGame === 'suika') {
        GameSceneTransition({ role: 'game', sceneDirection: this.sceneDirection }) {
          SuikaPage({
            bestScore: this.recordFor('suika').highScore,
            exitToHub: () => {
              this.closeGameAnimated();
            },
            recordScore: (score: number) => {
              this.recordGameResult('suika', score);
            },
            reportAchievementEvent: (event: AchievementEvent) => {
              return this.reportAchievementEvent(event);
            }
          })
        }
      }

      if (this.entryBadgeMounted) {
        GameEntryBadge({
          gameId: this.entryBadgeGameId,
          badgeVisible: this.entryBadgeVisible,
          isDarkMode: this.isDarkMode()
        })
      }

      if (this.achievementNoticeMounted) {
        AchievementUnlockNotice({
          notice: this.achievementNotice,
          noticeVisible: this.achievementNoticeVisible,
          isDarkMode: this.isDarkMode()
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode() ? '#101110' : '#FFF4E4')
  }

  private openGame(gameId: string): void {
    if (this.sceneTransitioning || this.activeGame === gameId) {
      return;
    }
    this.clearAchievementNotices();
    this.recordPlayDay();
    if (gameId === 'tetris') {
      this.tetrisSession += 1;
    }
    this.sceneDirection = 'push';
    this.sceneTransitioning = true;
    this.saveSnapshot(this.withRecent(this.snapshot, gameId));
    this.showEntryBadge(gameId);
    this.getUIContext().animateTo({
      duration: CoopMotion.scenePushDuration,
      curve: Curve.Friction,
      onFinish: () => {
        this.sceneTransitioning = false;
      }
    }, () => {
      this.activeGame = gameId;
    });
  }

  private closeGameAnimated(): void {
    if (this.sceneTransitioning || this.activeGame === 'hub') {
      return;
    }
    this.clearAchievementNotices();
    this.sceneDirection = 'pop';
    this.sceneTransitioning = true;
    this.hideEntryBadge();
    this.getUIContext().animateTo({
      duration: CoopMotion.scenePopDuration,
      curve: Curve.Friction,
      onFinish: () => {
        this.sceneTransitioning = false;
      }
    }, () => {
      this.activeGame = 'hub';
    });
  }

  private requestMinesweeperExit(): void {
    if (this.sceneTransitioning) {
      return;
    }
    this.minesweeperExitRequestId += 1;
  }

  private toggleFavorite(gameId: string): void {
    const previousSnapshot = this.snapshot;
    const toggleResult: FavoriteSnapshotToggleResult = favoriteSnapshotAfterToggle(previousSnapshot, gameId);
    const revision = this.replaceSnapshot(toggleResult.snapshot);
    this.enqueueSnapshotSave(toggleResult.snapshot).then((didSave: boolean) => {
      if (!didSave) {
        if (revision === this.snapshotRevision) {
          this.replaceSnapshot(favoriteSnapshotAfterPersist(previousSnapshot, toggleResult.snapshot, false));
        }
        return;
      }
      this.favoriteAchievementEventSequence += 1;
      const event = favoriteAchievementEventAfterPersist(
        gameId,
        true,
        toggleResult.didAddFavorite,
        toggleResult.snapshot.favorites,
        Date.now(),
        this.favoriteAchievementEventSequence
      );
      if (event !== undefined) {
        this.reportAchievementEvent(event);
      }
    });
  }

  private updateSound(enabled: boolean): void {
    this.saveSnapshot({
      records: this.snapshot.records.slice(),
      favorites: this.snapshot.favorites.slice(),
      recent: this.snapshot.recent.slice(),
      soundEnabled: enabled,
      hapticEnabled: this.snapshot.hapticEnabled,
      appearanceMode: this.snapshot.appearanceMode,
      achievementSchemaVersion: this.snapshot.achievementSchemaVersion,
      achievements: this.snapshot.achievements.slice(),
      recentAchievementEventIds: this.snapshot.recentAchievementEventIds.slice()
    });
  }

  private updateHaptic(enabled: boolean): void {
    this.saveSnapshot({
      records: this.snapshot.records.slice(),
      favorites: this.snapshot.favorites.slice(),
      recent: this.snapshot.recent.slice(),
      soundEnabled: this.snapshot.soundEnabled,
      hapticEnabled: enabled,
      appearanceMode: this.snapshot.appearanceMode,
      achievementSchemaVersion: this.snapshot.achievementSchemaVersion,
      achievements: this.snapshot.achievements.slice(),
      recentAchievementEventIds: this.snapshot.recentAchievementEventIds.slice()
    });
  }

  private isDarkMode(): boolean {
    return isDarkAppearance(this.snapshot.appearanceMode, this.systemDark);
  }

  private persistPlayDays(): void {
    const context = this.appContext;
    if (context === undefined) return;
    const days = this.playDays.slice();
    this.playDaysSaveQueue = this.playDaysSaveQueue.then(() => CoopStorage.savePlayDays(context, days));
  }

  private recordPlayDay(): void {
    const day = localPlayDay(Date.now());
    if (this.playDays.includes(day)) return;
    this.playDays = normalizePlayDays(this.playDays.concat([day]));
    this.persistPlayDays();
  }

  private updateAppearanceMode(appearanceMode: string): void {
    this.saveSnapshot({
      records: this.snapshot.records.slice(),
      favorites: this.snapshot.favorites.slice(),
      recent: this.snapshot.recent.slice(),
      soundEnabled: this.snapshot.soundEnabled,
      hapticEnabled: this.snapshot.hapticEnabled,
      appearanceMode: normalizeAppearanceMode(appearanceMode),
      achievementSchemaVersion: this.snapshot.achievementSchemaVersion,
      achievements: this.snapshot.achievements.slice(),
      recentAchievementEventIds: this.snapshot.recentAchievementEventIds.slice()
    });
  }

  private recordGameResult(gameId: string, score: number): void {
    // A session can continue beyond midnight without entering the game again.
    this.recordPlayDay();
    const records = this.snapshot.records.slice();
    const index = records.findIndex((item: GameRecord) => item.gameId === gameId);
    const now = Date.now();
    if (index >= 0) {
      const current = records[index];
      records[index] = {
        gameId: gameId,
        highScore: Math.max(current.highScore, Math.max(0, Math.floor(score))),
        playCount: current.playCount + 1,
        lastPlayedAt: now
      };
    } else {
      records.push({
        gameId: gameId,
        highScore: Math.max(0, Math.floor(score)),
        playCount: 1,
        lastPlayedAt: now
      });
    }
    this.saveSnapshot(this.withRecent({
      records: records,
      favorites: this.snapshot.favorites.slice(),
      recent: this.snapshot.recent.slice(),
      soundEnabled: this.snapshot.soundEnabled,
      hapticEnabled: this.snapshot.hapticEnabled,
      appearanceMode: this.snapshot.appearanceMode,
      achievementSchemaVersion: this.snapshot.achievementSchemaVersion,
      achievements: this.snapshot.achievements.slice(),
      recentAchievementEventIds: this.snapshot.recentAchievementEventIds.slice()
    }, gameId));
  }

  private withRecent(snapshot: CoopAppSnapshot, gameId: string): CoopAppSnapshot {
    const recent = snapshot.recent.filter((item: string) => item !== gameId);
    recent.unshift(gameId);
    return {
      records: snapshot.records.slice(),
      favorites: snapshot.favorites.slice(),
      recent: recent.slice(0, 6),
      soundEnabled: snapshot.soundEnabled,
      hapticEnabled: snapshot.hapticEnabled,
      appearanceMode: snapshot.appearanceMode,
      achievementSchemaVersion: snapshot.achievementSchemaVersion,
      achievements: snapshot.achievements.slice(),
      recentAchievementEventIds: snapshot.recentAchievementEventIds.slice()
    };
  }

  private recordFor(gameId: string): GameRecord {
    const found = this.snapshot.records.find((item: GameRecord) => item.gameId === gameId);
    if (found !== undefined) {
      return found;
    }
    return { gameId: gameId, highScore: 0, playCount: 0, lastPlayedAt: 0 };
  }

  private showEntryBadge(gameId: string): void {
    this.clearEntryBadgeTimers();
    this.entryBadgeGameId = gameId;
    this.entryBadgeVisible = false;
    this.entryBadgeMounted = true;
    this.entryBadgeInTimer = setTimeout(() => {
      this.getUIContext().animateTo({
        duration: CoopMotion.entryBadgeDuration,
        curve: Curve.EaseOut
      }, () => {
        this.entryBadgeVisible = true;
      });
    }, 20);
    this.entryBadgeOutTimer = setTimeout(() => {
      this.hideEntryBadge();
    }, CoopMotion.entryBadgeHoldDuration);
  }

  private hideEntryBadge(): void {
    if (!this.entryBadgeMounted) {
      return;
    }
    this.clearEntryBadgeTimers();
    this.getUIContext().animateTo({
      duration: CoopMotion.entryBadgeDuration,
      curve: Curve.EaseOut
    }, () => {
      this.entryBadgeVisible = false;
    });
    this.entryBadgeUnmountTimer = setTimeout(() => {
      this.entryBadgeMounted = false;
      this.entryBadgeUnmountTimer = -1;
      this.tryShowAchievementNotice();
    }, CoopMotion.entryBadgeDuration);
  }

  private clearEntryBadgeTimers(): void {
    if (this.entryBadgeInTimer !== -1) {
      clearTimeout(this.entryBadgeInTimer);
      this.entryBadgeInTimer = -1;
    }
    if (this.entryBadgeOutTimer !== -1) {
      clearTimeout(this.entryBadgeOutTimer);
      this.entryBadgeOutTimer = -1;
    }
    if (this.entryBadgeUnmountTimer !== -1) {
      clearTimeout(this.entryBadgeUnmountTimer);
      this.entryBadgeUnmountTimer = -1;
    }
  }

  private async reportAchievementEvent(event: AchievementEvent): Promise<boolean> {
    const context = this.appContext;
    if (context === undefined) return false;
    try {
      const result = await this.achievementService.report(context, event);
      this.achievementState = result.state;
      if (this.activeGame === 'hub' ||
        achievementCanonicalGameId(this.activeGame) === achievementCanonicalGameId(event.gameId)) {
        this.enqueueAchievementNotices(result);
      }
      return result.disposition !== 'ignored';
    } catch (_) {
      // The game keeps its unacknowledged result so restoring it can retry.
      return false;
    }
  }

  private async resetAchievements(): Promise<boolean> {
    const context = this.appContext;
    if (context === undefined) {
      return false;
    }
    try {
      const resetState = await this.achievementService.reset(context);
      this.achievementState = resetState;
      this.clearAchievementNotices();
      return true;
    } catch (error) {
      return false;
    }
  }

  private async refreshAchievementState(): Promise<void> {
    const context = this.appContext;
    if (context === undefined) {
      return;
    }
    try {
      this.achievementState = await this.achievementService.refresh(context);
    } catch (error) {
      // Keep the in-memory state visible when local persistence is temporarily unavailable.
    }
  }

  private enqueueAchievementNotices(result: AchievementApplyResult): void {
    const notices = achievementNoticeItemsForUnlocks(result.newlyUnlocked);
    notices.forEach((notice: AchievementNoticeItem) => {
      this.achievementNoticeQueue.push(notice);
    });
    this.tryShowAchievementNotice();
  }

  private tryShowAchievementNotice(): void {
    if (this.achievementNoticeMounted || this.achievementNoticeQueue.length === 0 ||
      this.activeGame === 'hub' || this.sceneTransitioning || this.entryBadgeMounted) {
      return;
    }
    const nextNotice = this.achievementNoticeQueue.shift();
    if (nextNotice === undefined) {
      return;
    }
    this.achievementNotice = nextNotice;
    this.achievementNoticeVisible = false;
    this.achievementNoticeMounted = true;
    this.achievementNoticeInTimer = setTimeout(() => {
      this.achievementNoticeInTimer = -1;
      if (!this.achievementNoticeMounted) {
        return;
      }
      this.getUIContext().animateTo({
        duration: CoopMotion.achievementNoticeEnterDuration,
        curve: Curve.EaseOut
      }, () => {
        this.achievementNoticeVisible = true;
      });
    }, 20);
    const holdDuration = nextNotice.noticeLevel === 'highlight'
      ? CoopMotion.achievementNoticeHighlightHoldDuration
      : CoopMotion.achievementNoticeNormalHoldDuration;
    this.achievementNoticeHoldTimer = setTimeout(() => {
      this.achievementNoticeHoldTimer = -1;
      this.hideAchievementNotice();
    }, 20 + CoopMotion.achievementNoticeEnterDuration + holdDuration);
  }

  private hideAchievementNotice(): void {
    if (!this.achievementNoticeMounted || this.achievementNoticeUnmountTimer !== -1) {
      return;
    }
    this.clearAchievementNoticeTimers();
    this.getUIContext().animateTo({
      duration: CoopMotion.achievementNoticeExitDuration,
      curve: Curve.EaseOut
    }, () => {
      this.achievementNoticeVisible = false;
    });
    this.achievementNoticeUnmountTimer = setTimeout(() => {
      this.achievementNoticeUnmountTimer = -1;
      this.achievementNoticeMounted = false;
      this.achievementNotice = emptyAchievementNoticeItem();
      this.tryShowAchievementNotice();
    }, CoopMotion.achievementNoticeExitDuration);
  }

  private clearAchievementNotices(): void {
    this.clearAchievementNoticeTimers();
    this.achievementNoticeQueue = [];
    this.achievementNoticeVisible = false;
    this.achievementNoticeMounted = false;
    this.achievementNotice = emptyAchievementNoticeItem();
  }

  private clearAchievementNoticeTimers(): void {
    if (this.achievementNoticeInTimer !== -1) {
      clearTimeout(this.achievementNoticeInTimer);
      this.achievementNoticeInTimer = -1;
    }
    if (this.achievementNoticeHoldTimer !== -1) {
      clearTimeout(this.achievementNoticeHoldTimer);
      this.achievementNoticeHoldTimer = -1;
    }
    if (this.achievementNoticeUnmountTimer !== -1) {
      clearTimeout(this.achievementNoticeUnmountTimer);
      this.achievementNoticeUnmountTimer = -1;
    }
  }

  private saveSnapshot(snapshot: CoopAppSnapshot): void {
    this.replaceSnapshot(snapshot);
    this.enqueueSnapshotSave(snapshot);
  }

  private replaceSnapshot(snapshot: CoopAppSnapshot): number {
    this.snapshot = snapshot;
    this.snapshotRevision += 1;
    return this.snapshotRevision;
  }

  private enqueueSnapshotSave(snapshot: CoopAppSnapshot): Promise<boolean> {
    const context = this.appContext;
    if (context === undefined) {
      return Promise.resolve(false);
    }
    const saveTask: Promise<boolean> = this.snapshotSaveQueue.then(() => {
      return CoopStorage.save(context, snapshot);
    });
    this.snapshotSaveQueue = saveTask.then((didSave: boolean) => {
      return didSave;
    }, () => {
      return false;
    });
    return saveTask;
  }
}
