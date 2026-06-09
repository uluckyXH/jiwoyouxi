import { common } from '@kit.AbilityKit';
import { CoopStorage } from '../app/CoopStorage';
import { CoopAppSnapshot, emptySnapshot, GameRecord } from '../shell/GameModule';
import { HubPage } from './HubPage';
import { RpsPage } from '../games/rps/RpsPage';
import { WhiteTilesPage } from '../games/whiteTiles/WhiteTilesPage';
import { MinesweeperPage } from '../games/minesweeper/MinesweeperPage';
import { TetrisPage } from '../games/tetris/TetrisPage';
import { SuikaPage } from '../games/suika/SuikaPage';
import { EggSlingPage } from '../games/eggSling/EggSlingPage';

@Entry
@Component
struct Index {
  private appContext: common.Context | undefined = undefined;
  @State snapshot: CoopAppSnapshot = emptySnapshot();
  @State activeGame: string = 'hub';
  @State tetrisSession: number = 0;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      this.appContext = context as common.Context;
      CoopStorage.load(this.appContext).then((snapshot: CoopAppSnapshot) => {
        this.snapshot = snapshot;
      });
    }
  }

  onBackPress(): boolean {
    if (this.activeGame !== 'hub') {
      this.activeGame = 'hub';
      return true;
    }
    return false;
  }

  build() {
    Stack() {
      if (this.activeGame === 'hub') {
        HubPage({
          snapshot: this.snapshot,
          openGame: (gameId: string) => {
            this.openGame(gameId);
          },
          toggleFavorite: (gameId: string) => {
            this.toggleFavorite(gameId);
          },
          updateSound: (enabled: boolean) => {
            this.updateSound(enabled);
          },
          updateHaptic: (enabled: boolean) => {
            this.updateHaptic(enabled);
          }
        })
      } else if (this.activeGame === 'rps') {
        RpsPage({
          exitToHub: () => {
            this.activeGame = 'hub';
          },
          recordScore: (score: number) => {
            this.recordGameResult('rps', score);
          }
        })
      } else if (this.activeGame === 'whiteTiles') {
        WhiteTilesPage({
          bestScore: this.recordFor('whiteTiles').highScore,
          exitToHub: () => {
            this.activeGame = 'hub';
          },
          recordScore: (score: number) => {
            this.recordGameResult('whiteTiles', score);
          }
        })
      } else if (this.activeGame === 'minesweeper') {
        MinesweeperPage({
          bestScore: this.recordFor('minesweeper').highScore,
          exitToHub: () => {
            this.activeGame = 'hub';
          },
          recordScore: (score: number) => {
            this.recordGameResult('minesweeper', score);
          }
        })
      } else if (this.activeGame === 'tetris') {
        TetrisPage({
          bestScore: this.recordFor('tetris').highScore,
          session: this.tetrisSession,
          exitToHub: () => {
            this.activeGame = 'hub';
          },
          recordScore: (score: number) => {
            this.recordGameResult('tetris', score);
          }
        })
      } else if (this.activeGame === 'suika') {
        SuikaPage({
          bestScore: this.recordFor('suika').highScore,
          exitToHub: () => {
            this.activeGame = 'hub';
          },
          recordScore: (score: number) => {
            this.recordGameResult('suika', score);
          }
        })
      } else if (this.activeGame === 'eggSling') {
        EggSlingPage({
          bestScore: this.recordFor('eggSling').highScore,
          exitToHub: () => {
            this.activeGame = 'hub';
          },
          recordScore: (score: number) => {
            this.recordGameResult('eggSling', score);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  private openGame(gameId: string): void {
    if (gameId === 'tetris') {
      this.tetrisSession += 1;
    }
    this.activeGame = gameId;
    this.saveSnapshot(this.withRecent(this.snapshot, gameId));
  }

  private toggleFavorite(gameId: string): void {
    const favorites = this.snapshot.favorites.slice();
    const index = favorites.indexOf(gameId);
    if (index >= 0) {
      favorites.splice(index, 1);
    } else {
      favorites.unshift(gameId);
    }
    this.saveSnapshot({
      records: this.snapshot.records.slice(),
      favorites: favorites.slice(0, 12),
      recent: this.snapshot.recent.slice(),
      soundEnabled: this.snapshot.soundEnabled,
      hapticEnabled: this.snapshot.hapticEnabled
    });
  }

  private updateSound(enabled: boolean): void {
    this.saveSnapshot({
      records: this.snapshot.records.slice(),
      favorites: this.snapshot.favorites.slice(),
      recent: this.snapshot.recent.slice(),
      soundEnabled: enabled,
      hapticEnabled: this.snapshot.hapticEnabled
    });
  }

  private updateHaptic(enabled: boolean): void {
    this.saveSnapshot({
      records: this.snapshot.records.slice(),
      favorites: this.snapshot.favorites.slice(),
      recent: this.snapshot.recent.slice(),
      soundEnabled: this.snapshot.soundEnabled,
      hapticEnabled: enabled
    });
  }

  private recordGameResult(gameId: string, score: number): void {
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
      hapticEnabled: this.snapshot.hapticEnabled
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
      hapticEnabled: snapshot.hapticEnabled
    };
  }

  private recordFor(gameId: string): GameRecord {
    const found = this.snapshot.records.find((item: GameRecord) => item.gameId === gameId);
    if (found !== undefined) {
      return found;
    }
    return { gameId: gameId, highScore: 0, playCount: 0, lastPlayedAt: 0 };
  }

  private saveSnapshot(snapshot: CoopAppSnapshot): void {
    this.snapshot = snapshot;
    if (this.appContext !== undefined) {
      CoopStorage.save(this.appContext, snapshot);
    }
  }
}
