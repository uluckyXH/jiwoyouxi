import { common } from '@kit.AbilityKit';
import { FactionInfo, FieldMode, GameEventKind, GamePhase, NativeGameOptions, FACTIONS } from '../../model/GameTypes';
import { NativeGameEngine } from '../../model/GameEngine';
import { NativePreset, PRESETS, presetOptions } from '../../model/Presets';
import { configSummary, eventSummary, mechanicSummary } from '../../model/OptionSummary';
import { NativeBattleReport } from '../../model/BattleReport';
import { defaultLabelsForTheme, factionInfoForOptions, NativeTheme, THEMES, themeByKey } from '../../model/ThemeConfig';
import { NativeAudioService } from '../../services/AudioService';
import { RageBar } from '../../components/RageBar';
import { ReportPanel } from '../../components/ReportPanel';

@Component
export struct RpsPage {
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private engine: NativeGameEngine = new NativeGameEngine();
  private audioService: NativeAudioService = new NativeAudioService();
  private frameTimer: number = -1;
  private countdownTimer: number = -1;
  @State phase: GamePhase = GamePhase.Setup;
  @State canvasWidth: number = 390;
  @State canvasHeight: number = 760;
  @State tick: number = 0;
  @State countdown: string = '3';
  @State selectedPreset: string = 'custom';
  @State themeKey: string = 'rps';
  @State customLabel0: string = '红球';
  @State customLabel1: string = '绿球';
  @State customLabel2: string = '蓝球';
  @State syncCounts: boolean = true;
  @State fieldMode: FieldMode = FieldMode.Push;
  @State rockCount: number = 7;
  @State scissorsCount: number = 7;
  @State paperCount: number = 7;
  @State durationSec: number = 60;
  @State deathmatch: boolean = false;
  @State tournament: boolean = false;
  @State bestOf: number = 3;
  @State winnerPenalty: number = 5;
  @State godHand: boolean = false;
  @State obstacles: boolean = false;
  @State shrink: boolean = false;
  @State bounty: boolean = false;
  @State blackHole: boolean = false;
  @State traitor: boolean = false;
  @State thanos: boolean = false;
  @State lastStand: boolean = false;
  @State controlZones: boolean = false;
  @State powerUps: boolean = false;
  @State teamPowerUps: boolean = false;
  @State tenAgainstOne: boolean = false;
  @State betting: boolean = false;
  @State bank: number = 1000;
  @State selectedPick: number = 0;
  @State stake: number = 100;
  @State oddsRock: number = 2;
  @State oddsScissors: number = 2;
  @State oddsPaper: number = 2;
  @State notifications: boolean = true;
  @State roundIndex: number = 1;
  @State winsRock: number = 0;
  @State winsScissors: number = 0;
  @State winsPaper: number = 0;
  @State penaltyRock: number = 0;
  @State penaltyScissors: number = 0;
  @State penaltyPaper: number = 0;
  @State matchDone: boolean = false;
  @State bgmVolume: number = 45;
  @State sfxVolume: number = 80;
  @State sRock: number = 0;
  @State sScissors: number = 0;
  @State sPaper: number = 0;
  @State statusText: string = '未开';
  @State eventText: string = '';
  @State winner: number = -1;
  @State thanosVisible: boolean = false;
  @State thanosText: string = '啪，打个响指';
  @State heroOverlayVisible: boolean = false;
  @State heroOverlayText: string = '';
  @State heroOverlaySubText: string = '';
  @State rageType: number = -1;
  @State rageTimeLeftSec: number = 0;
  @State rageProgress: number = 0;
  @State reportVisible: boolean = false;
  @State resultOverlayReady: boolean = false;
  private lastEventId: number = 0;
  private resultSettled: boolean = false;
  private resultTimer: number = -1;
  private reportData: NativeBattleReport = emptyReport();
  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      this.audioService.init(context as common.Context);
    }
    this.updateOddsFromCounts([this.rockCount, this.scissorsCount, this.paperCount]);
    this.startLoop();
  }

  aboutToDisappear(): void {
    this.stopLoop();
    this.clearCountdown();
    this.clearResultTimer();
    this.audioService.release();
  }

  build() {
    Stack() {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.engine.resize(this.canvasWidth, this.canvasHeight);
          this.engine.draw(this.context);
        })
        .onAreaChange((oldArea, newArea) => {
          const width = Number.parseFloat(`${newArea.width}`);
          const height = Number.parseFloat(`${newArea.height}`);
          if (!Number.isNaN(width) && !Number.isNaN(height)) {
            this.canvasWidth = Math.max(280, width);
            this.canvasHeight = Math.max(420, height);
            this.engine.resize(this.canvasWidth, this.canvasHeight);
          }
        })
        .onTouch((event) => {
          this.handleTouch(event);
        })

      if (this.phase === GamePhase.Setup) {
        this.SetupScreen()
      } else {
        this.GameHud()
        this.ControlDock()
      }

      if (this.phase === GamePhase.Countdown) {
        this.CountdownScreen()
      }

      if (this.thanosVisible) {
        this.ThanosOverlay()
      }

      if (this.heroOverlayVisible) {
        this.HeroOverlay()
      }

      if (this.phase === GamePhase.Result && this.resultOverlayReady) {
        this.ResultScreen()
      }

      if (this.reportVisible) {
        Stack({ alignContent: Alignment.Center }) {
          ReportPanel({
            report: this.reportData,
            factions: this.currentFactions(),
            panelWidth: this.canvasWidth,
            close: () => {
              this.reportVisible = false;
            }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(7,8,18,0.58)')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#edf5f1')
  }

  @Builder
  SetupScreen() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column({ space: 12 }) {
          Row({ space: 12 }) {
            Image($r('app.media.app_icon'))
              .width(56)
              .height(56)
              .borderRadius(14)
            Column({ space: 3 }) {
              Text('石头剪刀布大作战')
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor('#17201c')
              Text('鸡窝游戏 · 原生鸿蒙离线模块')
                .fontSize(13)
                .fontColor('#637067')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Button('大厅')
              .height(36)
              .width(72)
              .borderRadius(8)
              .backgroundColor('rgba(23,32,28,0.08)')
              .fontColor('#17201c')
              .onClick(() => {
                this.exitToHub();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          this.PresetPanel()
          this.ThemePanel()
          this.LineupPanel()
          this.SettingsPanel()
          this.MechanicPanel()
          this.EventPanel()
          this.MatchPanel()
          Blank()
            .height(88)
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })
      }
      .width('100%')
      .height('100%')

      Row() {
        Button('开始乱斗')
          .width('100%')
          .height(50)
          .borderRadius(8)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .backgroundColor('#17201c')
          .onClick(() => {
            this.startNewMatch();
            this.beginCountdown();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 14 })
      .backgroundColor('rgba(248,250,247,0.94)')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  PresetPanel() {
    Column({ space: 10 }) {
      Row() {
        Text(this.canvasWidth < 620 ? '经典战役' : '游戏预设')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('一键套用')
          .fontSize(12)
          .fontColor('#637067')
      }
      .width('100%')

      Grid() {
        ForEach(PRESETS, (item: NativePreset) => {
          GridItem() {
            Column({ space: 4 }) {
              Text(item.name)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.selectedPreset === item.key ? '#ffffff' : '#17201c')
              Text(item.subtitle)
                .fontSize(11)
                .fontColor(this.selectedPreset === item.key ? 'rgba(255,255,255,0.78)' : '#637067')
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .height(64)
            .padding(10)
            .borderRadius(8)
            .backgroundColor(this.selectedPreset === item.key ? '#2c8f7f' : '#ffffff')
            .border({ width: 1, color: this.selectedPreset === item.key ? '#2c8f7f' : 'rgba(23,32,28,0.12)' })
            .onClick(() => {
              this.applyPreset(item.key);
            })
          }
        }, (item: NativePreset) => item.key)
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .height(136)
    }
    .panelStyle()
  }

  @Builder
  ThemePanel() {
    Column({ space: 10 }) {
      this.PanelTitle('阵营主题', themeByKey(this.themeKey).subtitle)
      Grid() {
        ForEach(THEMES, (item: NativeTheme) => {
          GridItem() {
            Column({ space: 3 }) {
              Text(item.mark)
                .fontSize(18)
              Text(item.name)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeKey === item.key ? '#ffffff' : '#17201c')
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .height(54)
            .borderRadius(8)
            .backgroundColor(this.themeKey === item.key ? '#2c8f7f' : '#ffffff')
            .border({ width: 1, color: this.themeKey === item.key ? '#2c8f7f' : 'rgba(23,32,28,0.12)' })
            .onClick(() => {
              this.applyTheme(item.key);
            })
          }
        }, (item: NativeTheme) => item.key)
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .height(116)

      if (this.themeKey !== 'rps') {
        Row({ space: 8 }) {
          this.NameControl(0)
          this.NameControl(1)
          this.NameControl(2)
        }
        .width('100%')
      }
    }
    .panelStyle()
  }

  @Builder
  NameControl(type: number) {
    TextInput({ text: this.customLabel(type), placeholder: this.defaultThemeLabel(type) })
      .height(38)
      .layoutWeight(1)
      .fontSize(12)
      .fontColor('#17201c')
      .backgroundColor('#ffffff')
      .borderRadius(8)
      .onChange((value: string) => {
        this.setCustomLabel(type, value);
      })
  }

  @Builder
  LineupPanel() {
    Column({ space: 10 }) {
      this.PanelTitle('初始阵容', `${this.rockCount}/${this.scissorsCount}/${this.paperCount} · ${this.durationSec}s`)
      Row({ space: 8 }) {
        this.CountControl(0, this.rockCount)
        this.CountControl(1, this.scissorsCount)
        this.CountControl(2, this.paperCount)
      }
      .width('100%')

      Row({ space: 8 }) {
        this.ToggleChip('人数同步', this.syncCounts, '调整一方同步三方')
        Button(`时长 ${this.durationSec}s`)
          .height(38)
          .layoutWeight(1)
          .borderRadius(8)
          .fontSize(13)
          .backgroundColor('#ffffff')
          .fontColor('#17201c')
          .onClick(() => {
            this.durationSec = this.durationSec >= 120 ? 30 : this.durationSec + 15;
          })
      }
    }
    .panelStyle()
  }

  @Builder
  SettingsPanel() {
    Column({ space: 10 }) {
      this.PanelTitle('游戏设置', `BGM ${this.bgmVolume}% · 音效 ${this.sfxVolume}% · 通知${this.notifications ? '开' : '关'}`)
      Row({ space: 8 }) {
        this.VolumeControl('BGM', this.bgmVolume)
        this.VolumeControl('音效', this.sfxVolume)
      }
      .width('100%')
      Row({ space: 8 }) {
        this.OptionButton('通知', this.notifications, '游戏中展示事件提示')
      }
      .width('100%')
    }
    .panelStyle()
  }

  @Builder
  VolumeControl(label: string, value: number) {
    Row({ space: 6 }) {
      Text(`${label} ${value}%`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17201c')
        .layoutWeight(1)
      Button('-')
        .width(30)
        .height(30)
        .borderRadius(6)
        .backgroundColor('rgba(23,32,28,0.06)')
        .fontColor('#17201c')
        .onClick(() => {
          this.stepVolume(label, -5);
        })
      Button('+')
        .width(30)
        .height(30)
        .borderRadius(6)
        .backgroundColor('rgba(23,32,28,0.06)')
        .fontColor('#17201c')
        .onClick(() => {
          this.stepVolume(label, 5);
        })
    }
    .layoutWeight(1)
    .height(44)
    .padding({ left: 10, right: 8 })
    .borderRadius(8)
    .backgroundColor('#ffffff')
    .border({ width: 1, color: 'rgba(23,32,28,0.12)' })
  }

  @Builder
  MechanicPanel() {
    Column({ space: 10 }) {
      this.PanelTitle('游戏机制', mechanicSummary(this.currentOptions()))
      Row({ space: 8 }) {
        this.OptionButton('上帝之手', this.godHand, '底部可切换推/吸')
        this.OptionButton('地形障碍', this.obstacles, '碰撞弹开')
      }
      Row({ space: 8 }) {
        this.OptionButton('缩圈', this.shrink, '边界持续内收')
        this.OptionButton('据点争夺', this.controlZones, '占点到100获胜')
      }
      Row({ space: 8 }) {
        this.OptionButton('悬赏头名', this.bounty, '领先方被全场追击')
      }
    }
    .panelStyle()
  }

  @Builder
  EventPanel() {
    Column({ space: 10 }) {
      this.PanelTitle('精彩事件', eventSummary(this.currentOptions()))
      Row({ space: 8 }) {
        this.OptionButton('黑洞', this.blackHole, '吞噬后体积+30%')
        this.OptionButton('我们中出了叛徒', this.traitor, '紫圈2秒后叛变')
      }
      Row({ space: 8 }) {
        this.OptionButton('绝地求生', this.lastStand, '少数方分裂/复活')
        this.OptionButton('灭霸响指', this.thanos, '全场派系减半')
      }
      Row({ space: 8 }) {
        this.OptionButton('能量道具', this.powerUps, '加速/护盾/分裂')
        this.OptionButton('团队道具', this.teamPowerUps, '全队共享效果')
      }
      Row({ space: 8 }) {
        this.OptionButton('我要打十个', this.tenAgainstOne, '劣势方10秒反杀')
      }
    }
    .panelStyle()
  }

  @Builder
  MatchPanel() {
    Column({ space: 10 }) {
      this.PanelTitle('赛制和竞猜积分', this.matchSummary())
      Row({ space: 8 }) {
        this.OptionButton('死斗模式', this.deathmatch, '直到一方霸屏')
        this.OptionButton('多局赛制', this.tournament, `${this.bestOf}局 · 胜方-${this.winnerPenalty}`)
      }
      if (this.tournament) {
        Row({ space: 8 }) {
          Button('三局两胜')
            .height(38)
            .layoutWeight(1)
            .borderRadius(8)
            .backgroundColor(this.bestOf === 3 ? '#2c8f7f' : '#ffffff')
            .fontColor(this.bestOf === 3 ? '#ffffff' : '#17201c')
            .onClick(() => {
              this.bestOf = 3;
            })
          Button('五局三胜')
            .height(38)
            .layoutWeight(1)
            .borderRadius(8)
            .backgroundColor(this.bestOf === 5 ? '#2c8f7f' : '#ffffff')
            .fontColor(this.bestOf === 5 ? '#ffffff' : '#17201c')
            .onClick(() => {
              this.bestOf = 5;
            })
          Button(`胜方-${this.winnerPenalty}`)
            .height(38)
            .layoutWeight(1)
            .borderRadius(8)
            .backgroundColor('#ffffff')
            .fontColor('#17201c')
            .onClick(() => {
              this.winnerPenalty = this.winnerPenalty >= 15 ? 0 : this.winnerPenalty + 5;
            })
        }
        .width('100%')
      }
      Row({ space: 8 }) {
        this.OptionButton('下注模式', this.betting, this.betting ? `本金 ${this.stake}` : '按赔率竞猜')
      }
      if (this.betting) {
        Row({ space: 8 }) {
          this.BetPickButton(0)
          this.BetPickButton(1)
          this.BetPickButton(2)
        }
        .width('100%')
        Row({ space: 8 }) {
          Button('-')
            .width(34)
            .height(34)
            .borderRadius(7)
            .backgroundColor('rgba(23,32,28,0.06)')
            .fontColor('#17201c')
            .onClick(() => {
              this.stepStake(-50);
            })
          Text(`下注 ${this.stake} · 余额 ${this.bank}`)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#17201c')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Button('+')
            .width(34)
            .height(34)
            .borderRadius(7)
            .backgroundColor('rgba(23,32,28,0.06)')
            .fontColor('#17201c')
            .onClick(() => {
              this.stepStake(50);
            })
        }
        .width('100%')
      }
    }
    .panelStyle()
  }

  @Builder
  BetPickButton(type: number) {
    Button(`${this.currentFaction(type).emoji} x${this.oddsFor(type).toFixed(2)}`)
      .height(36)
      .layoutWeight(1)
      .borderRadius(8)
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .backgroundColor(this.selectedPick === type ? this.currentFaction(type).color : '#ffffff')
      .fontColor(this.selectedPick === type ? '#ffffff' : '#17201c')
      .onClick(() => {
        this.selectedPick = type;
      })
  }

  @Builder
  PanelTitle(title: string, summary: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17201c')
      Blank()
      Text(summary)
        .fontSize(12)
        .fontColor('#637067')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  @Builder
  CountControl(type: number, count: number) {
    Column({ space: 7 }) {
      Text(`${this.currentFaction(type).emoji} ${this.currentFaction(type).label}`)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentFaction(type).darkColor)
      Row({ space: 6 }) {
        Button('-')
          .width(28)
          .height(30)
          .borderRadius(6)
          .backgroundColor('rgba(23,32,28,0.06)')
          .fontColor('#17201c')
          .onClick(() => {
            this.stepCount(type, -1);
          })
        Text(`${count}`)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#17201c')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Button('+')
          .width(28)
          .height(30)
          .borderRadius(6)
          .backgroundColor('rgba(23,32,28,0.06)')
          .fontColor('#17201c')
          .onClick(() => {
            this.stepCount(type, 1);
          })
      }
      .width('100%')
    }
    .layoutWeight(1)
    .padding(9)
    .borderRadius(8)
    .backgroundColor('#ffffff')
    .border({ width: 1, color: 'rgba(23,32,28,0.12)' })
  }

  @Builder
  OptionButton(label: string, enabled: boolean, hint: string) {
    Column({ space: 3 }) {
      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(enabled ? '#ffffff' : '#17201c')
        .maxLines(1)
      Text(hint)
        .fontSize(10)
        .fontColor(enabled ? 'rgba(255,255,255,0.76)' : '#637067')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .height(52)
    .layoutWeight(1)
    .padding(9)
    .borderRadius(8)
    .backgroundColor(enabled ? '#2c8f7f' : '#ffffff')
    .border({ width: 1, color: enabled ? '#2c8f7f' : 'rgba(23,32,28,0.12)' })
    .onClick(() => {
      this.toggleOption(label);
    })
  }

  @Builder
  ToggleChip(label: string, enabled: boolean, hint: string) {
    Column({ space: 3 }) {
      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(enabled ? '#ffffff' : '#17201c')
      Text(hint)
        .fontSize(10)
        .fontColor(enabled ? 'rgba(255,255,255,0.76)' : '#637067')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .height(38)
    .layoutWeight(1)
    .padding({ left: 10, right: 10, top: 5, bottom: 5 })
    .borderRadius(8)
    .backgroundColor(enabled ? '#17201c' : '#ffffff')
    .border({ width: 1, color: enabled ? '#17201c' : 'rgba(23,32,28,0.12)' })
    .onClick(() => {
      if (label === '人数同步') {
        this.syncCounts = !this.syncCounts;
      } else {
        this.deathmatch = !this.deathmatch;
      }
    })
  }

  @Builder
  GameHud() {
    Column({ space: 6 }) {
      Row({ space: 6 }) {
        this.ScorePill(0, this.sRock)
        this.ScorePill(1, this.sScissors)
        this.ScorePill(2, this.sPaper)
      }
      .width('100%')
      Row({ space: 6 }) {
        this.StatPill('局势', this.statusText)
        this.StatPill('积分', `${this.bank}`)
        this.StatPill('赛制', this.hudMatchText())
      }
      .width('100%')
      if (this.eventText.length > 0) {
        Text(this.eventText)
          .width('100%')
          .height(28)
          .padding({ left: 10, right: 10 })
          .borderRadius(8)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#17201c')
          .backgroundColor('rgba(255,255,255,0.90)')
      }
      if (this.rageTimeLeftSec > 0 && this.rageType >= 0) {
        RageBar({
          rageType: this.rageType,
          rageTimeLeftSec: this.rageTimeLeftSec,
          rageProgress: this.rageProgress,
          canvasWidth: this.canvasWidth,
          factions: this.currentFactions()
        })
      }
    }
    .position({ x: 10, y: 8 })
    .width(this.canvasWidth - 20)
  }

  @Builder
  StatPill(label: string, value: string) {
    Column({ space: 1 }) {
      Text(label)
        .fontSize(10)
        .fontColor('#637067')
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17201c')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height(44)
    .padding({ left: 8, right: 8, top: 5, bottom: 5 })
    .borderRadius(8)
    .backgroundColor('rgba(255,255,255,0.90)')
    .border({ width: 1, color: 'rgba(23,32,28,0.12)' })
  }

  @Builder
  ScorePill(type: number, count: number) {
    Row({ space: 6 }) {
      Text(this.currentFaction(type).emoji)
        .fontSize(18)
      Text(`${count}`)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17201c')
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(38)
    .borderRadius(8)
    .backgroundColor('rgba(255,255,255,0.90)')
    .border({ width: 1, color: this.currentFaction(type).color })
  }

  @Builder
  ControlDock() {
    Row({ space: 6 }) {
      if (this.godHand) {
        Button(this.fieldMode === FieldMode.Push ? '推开' : '吸引')
          .height(44)
          .layoutWeight(1)
          .borderRadius(8)
          .backgroundColor('#20a4f3')
          .fontColor('#ffffff')
          .onClick(() => {
            this.fieldMode = this.fieldMode === FieldMode.Push ? FieldMode.Pull : FieldMode.Push;
          })
      }
      Button(this.phase === GamePhase.Paused ? '继续' : '暂停')
        .height(44)
        .layoutWeight(1)
        .borderRadius(8)
        .backgroundColor('#ffffff')
        .fontColor('#17201c')
        .onClick(() => {
          const now = Date.now();
          if (this.phase === GamePhase.Paused) {
            this.engine.resume(now);
            this.audioService.playBgm();
            this.phase = GamePhase.Playing;
          } else if (this.phase === GamePhase.Playing) {
            this.engine.pause();
            this.audioService.pauseBgm();
            this.phase = GamePhase.Paused;
          }
        })
      Button('回首页')
        .height(44)
        .layoutWeight(1)
        .borderRadius(8)
        .backgroundColor('#17201c')
        .fontColor('#ffffff')
        .onClick(() => {
          this.goHome();
        })
    }
    .position({ x: 10, y: this.canvasHeight - 62 })
    .width(this.canvasWidth - 20)
    .padding(6)
    .borderRadius(10)
    .backgroundColor('rgba(255,255,255,0.88)')
    .border({ width: 1, color: 'rgba(23,32,28,0.12)' })
  }

  @Builder
  CountdownScreen() {
    Column({ space: 14 }) {
      Image($r('app.media.app_icon'))
        .width(72)
        .height(72)
        .borderRadius(18)
      Text('石头剪刀布大作战')
        .fontSize(27)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
      Text('请选择你支持的选手')
        .fontSize(16)
        .fontColor('rgba(255,255,255,0.78)')
      Row({ space: 12 }) {
        Text(this.currentFaction(0).emoji)
          .fontSize(34)
        Text(this.currentFaction(1).emoji)
          .fontSize(34)
        Text(this.currentFaction(2).emoji)
          .fontSize(34)
      }
      if (this.betting) {
        Row({ space: 8 }) {
          this.PickButton(0)
          this.PickButton(1)
          this.PickButton(2)
        }
        .width(Math.min(this.canvasWidth - 48, 420))
      }
      Text(this.countdown)
        .fontSize(58)
        .fontWeight(FontWeight.Bold)
        .fontColor('#f0b429')
      Text(configSummary(this.currentOptions(true)))
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.76)')
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: 24, right: 24 })
      Button('直接开始')
        .width(160)
        .height(42)
        .borderRadius(8)
        .backgroundColor('#ffffff')
        .fontColor('#17201c')
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          this.startGame();
        })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(7,8,18,0.88)')
  }

  @Builder
  PickButton(type: number) {
    Button(`${this.currentFaction(type).emoji} ${this.currentFaction(type).label} x${this.oddsFor(type).toFixed(2)}`)
      .height(40)
      .layoutWeight(1)
      .borderRadius(8)
      .backgroundColor(this.selectedPick === type ? this.currentFaction(type).color : '#ffffff')
      .fontColor(this.selectedPick === type ? '#ffffff' : '#17201c')
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .onClick(() => {
        this.selectedPick = type;
      })
  }

  @Builder
  ThanosOverlay() {
    Column({ space: 10 }) {
      Image($r('app.media.thanos'))
        .width(Math.min(this.canvasWidth - 48, 420))
        .borderRadius(8)
      Text('灭霸响指')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#fff8dc')
      Text(this.thanosText)
        .fontSize(16)
        .fontColor('rgba(255,248,220,0.78)')
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(7,8,18,0.74)')
  }

  @Builder
  HeroOverlay() {
    Column({ space: 10 }) {
      Text(this.heroOverlayText)
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#fff8dc')
        .textAlign(TextAlign.Center)
        .padding({ left: 20, right: 20 })
      Text(this.heroOverlaySubText)
        .fontSize(16)
        .fontColor('rgba(255,248,220,0.82)')
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(38,18,74,0.74)')
  }

  @Builder
  ResultScreen() {
    Column({ space: 14 }) {
      Text(this.resultTitle())
        .fontSize(27)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17201c')
      Text(`${this.currentFaction(0).emoji}${this.sRock} · ${this.currentFaction(1).emoji}${this.sScissors} · ${this.currentFaction(2).emoji}${this.sPaper}`)
        .fontSize(16)
        .fontColor('#637067')
      if (this.tournament) {
        Text(`比分 ${this.scoreText()} · 第 ${this.roundIndex} 局${this.matchDone ? ' · 赛点结束' : ''}`)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#17201c')
      }
      if (this.betting) {
        Text(`支持 ${this.currentFaction(this.selectedPick).emoji}${this.currentFaction(this.selectedPick).label} · 下注 ${this.stake} · 当前积分 ${this.bank}`)
          .fontSize(13)
          .fontColor('#637067')
      }
      Button('查看战报')
        .height(40)
        .width('100%')
        .borderRadius(8)
        .backgroundColor('rgba(23,32,28,0.06)')
        .fontColor('#17201c')
        .onClick(() => {
          this.openReport();
        })
      Row({ space: 10 }) {
        Button(this.nextRoundLabel())
          .height(44)
          .layoutWeight(1)
          .borderRadius(8)
          .backgroundColor('#2c8f7f')
          .fontColor('#ffffff')
          .onClick(() => {
            this.handleNextRoundClick();
          })
        Button('回首页')
          .height(44)
          .layoutWeight(1)
          .borderRadius(8)
          .backgroundColor('#17201c')
          .fontColor('#ffffff')
          .onClick(() => {
            this.goHome();
          })
      }
      .width('100%')
    }
    .width(Math.min(this.canvasWidth - 32, 420))
    .padding(18)
    .borderRadius(10)
    .backgroundColor('rgba(255,255,255,0.96)')
    .border({ width: 1, color: 'rgba(23,32,28,0.12)' })
  }

  private startLoop(): void {
    if (this.frameTimer >= 0) {
      return;
    }
    this.frameTimer = setInterval(() => {
      this.frame();
    }, 33);
  }

  private stopLoop(): void {
    if (this.frameTimer >= 0) {
      clearInterval(this.frameTimer);
      this.frameTimer = -1;
    }
  }

  private frame(): void {
    const now = Date.now();
    const snapshot = this.engine.update(now);
    this.sRock = snapshot.counts[0];
    this.sScissors = snapshot.counts[1];
    this.sPaper = snapshot.counts[2];
    this.statusText = snapshot.status;
    this.eventText = this.notifications ? snapshot.eventText : '';
    this.winner = snapshot.winner;
    this.thanosVisible = snapshot.thanosVisible;
    this.thanosText = snapshot.thanosText;
    this.heroOverlayVisible = snapshot.heroOverlayVisible;
    this.heroOverlayText = snapshot.heroOverlayText;
    this.heroOverlaySubText = snapshot.heroOverlaySubText;
    this.rageType = snapshot.rageType;
    this.rageTimeLeftSec = snapshot.rageTimeLeftSec;
    this.rageProgress = snapshot.rageProgress;
    this.phase = snapshot.phase === GamePhase.Setup ? this.phase : snapshot.phase;
    this.handleGameEvent(snapshot.eventId, snapshot.eventKind);
    if (snapshot.phase === GamePhase.Result && !this.resultSettled) {
      this.settleRound(snapshot.winner);
    }
    if (snapshot.phase === GamePhase.Result && !this.resultOverlayReady && this.resultTimer < 0) {
      this.resultTimer = setTimeout(() => {
        this.resultOverlayReady = true;
        this.resultTimer = -1;
      }, 1000);
    }
    this.tick = now;
    this.engine.draw(this.context);
  }

  private beginCountdown(): void {
    this.clearCountdown();
    this.clearResultTimer();
    this.reportVisible = false;
    this.resultOverlayReady = false;
    this.updateOddsFromCounts(this.currentRoundCounts());
    this.stake = Math.max(0, Math.min(this.bank, this.stake));
    this.countdown = '3';
    this.phase = GamePhase.Countdown;
    this.audioService.setBgmVolume(this.bgmVolume / 100);
    this.audioService.playBgm();
    let value = 3;
    this.countdownTimer = setInterval(() => {
      value -= 1;
      if (value > 0) {
        this.countdown = `${value}`;
      } else if (value === 0) {
        this.countdown = '开始';
      } else {
        this.startGame();
      }
    }, 1000);
  }

  private clearCountdown(): void {
    if (this.countdownTimer >= 0) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = -1;
    }
  }

  private startGame(): void {
    this.clearCountdown();
    this.clearResultTimer();
    const options = this.currentOptions(true);
    this.resultSettled = false;
    this.resultOverlayReady = false;
    this.reportVisible = false;
    this.lastEventId = 0;
    this.engine.resize(this.canvasWidth, this.canvasHeight);
    this.engine.start(options, Date.now());
    this.phase = GamePhase.Playing;
  }

  private handleGameEvent(eventId: number, eventKind: GameEventKind): void {
    if (eventId <= this.lastEventId || eventKind === GameEventKind.None) {
      return;
    }
    this.lastEventId = eventId;
    if (eventKind === GameEventKind.Attack) {
      this.audioService.play('attack');
    } else if (eventKind === GameEventKind.Warning) {
      this.audioService.play('warning');
    } else if (eventKind === GameEventKind.Shrink) {
      this.audioService.play('shrink');
    } else if (eventKind === GameEventKind.Snap) {
      this.audioService.play('snap');
    } else if (eventKind === GameEventKind.Win) {
      this.audioService.play('win');
      this.audioService.pauseBgm();
    } else if (eventKind === GameEventKind.PowerUp) {
      this.audioService.play('power');
    }
  }

  private settleRound(winner: number): void {
    this.resultSettled = true;
    this.recordScore(Math.max(this.sRock, this.sScissors, this.sPaper));
    if (this.tournament && winner >= 0) {
      this.addWin(winner);
      this.addPenalty(winner, this.winnerPenalty);
      this.matchDone = this.winCount(winner) >= Math.ceil(this.bestOf / 2);
    }
    if (!this.betting || winner < 0) {
      return;
    }
    const stake = Math.max(0, Math.min(this.bank, this.stake));
    if (winner === this.selectedPick) {
      const profit = Math.round(stake * (this.oddsFor(winner) - 1));
      this.bank += profit;
    } else {
      this.bank = Math.max(0, this.bank - stake);
    }
    this.stake = Math.max(0, Math.min(this.bank, this.stake));
  }

  private currentOptions(adjustedCounts: boolean = false): NativeGameOptions {
    const counts = adjustedCounts ? this.currentRoundCounts() : [this.rockCount, this.scissorsCount, this.paperCount];
    return {
      themeKey: this.themeKey,
      customLabels: [this.customLabel0, this.customLabel1, this.customLabel2],
      counts: counts,
      durationSec: this.durationSec,
      deathmatch: this.deathmatch,
      tournament: this.tournament,
      bestOf: this.bestOf,
      winnerPenalty: this.winnerPenalty,
      godHand: this.godHand,
      obstacles: this.obstacles,
      shrink: this.shrink,
      bounty: this.bounty,
      blackHole: this.blackHole,
      traitor: this.traitor,
      thanos: this.thanos,
      lastStand: this.lastStand,
      controlZones: this.controlZones,
      powerUps: this.powerUps,
      teamPowerUps: this.teamPowerUps,
      tenAgainstOne: this.tenAgainstOne,
      betting: this.betting,
      stake: this.stake,
      notifications: this.notifications
    };
  }

  private applyPreset(key: string): void {
    const options = presetOptions(key, this.canvasWidth);
    this.selectedPreset = key;
    this.rockCount = options.counts[0];
    this.scissorsCount = options.counts[1];
    this.paperCount = options.counts[2];
    this.durationSec = options.durationSec;
    this.deathmatch = options.deathmatch;
    this.tournament = options.tournament;
    this.bestOf = options.bestOf;
    this.winnerPenalty = options.winnerPenalty;
    this.godHand = options.godHand;
    this.obstacles = options.obstacles;
    this.shrink = options.shrink;
    this.bounty = options.bounty;
    this.blackHole = options.blackHole;
    this.traitor = options.traitor;
    this.thanos = options.thanos;
    this.lastStand = options.lastStand;
    this.controlZones = options.controlZones;
    this.powerUps = options.powerUps;
    this.teamPowerUps = options.teamPowerUps;
    this.tenAgainstOne = options.tenAgainstOne;
    this.betting = options.betting;
    this.stake = options.stake;
    this.notifications = options.notifications;
    this.updateOddsFromCounts([this.rockCount, this.scissorsCount, this.paperCount]);
  }

  private stepCount(type: number, step: number): void {
    if (this.syncCounts) {
      const base = type === 0 ? this.rockCount : type === 1 ? this.scissorsCount : this.paperCount;
      const next = Math.max(3, Math.min(60, base + step));
      this.rockCount = next;
      this.scissorsCount = next;
      this.paperCount = next;
      this.updateOddsFromCounts([this.rockCount, this.scissorsCount, this.paperCount]);
      return;
    }
    if (type === 0) {
      this.rockCount = Math.max(3, Math.min(60, this.rockCount + step));
    } else if (type === 1) {
      this.scissorsCount = Math.max(3, Math.min(60, this.scissorsCount + step));
    } else {
      this.paperCount = Math.max(3, Math.min(60, this.paperCount + step));
    }
    this.updateOddsFromCounts([this.rockCount, this.scissorsCount, this.paperCount]);
  }

  private stepVolume(label: string, step: number): void {
    if (label === 'BGM') {
      this.bgmVolume = Math.max(0, Math.min(100, this.bgmVolume + step));
      this.audioService.setBgmVolume(this.bgmVolume / 100);
    } else {
      this.sfxVolume = Math.max(0, Math.min(100, this.sfxVolume + step));
      this.audioService.setSfxVolume(this.sfxVolume / 100);
    }
  }

  private applyTheme(key: string): void {
    this.themeKey = themeByKey(key).key;
    const labels = defaultLabelsForTheme(this.themeKey);
    this.customLabel0 = labels[0];
    this.customLabel1 = labels[1];
    this.customLabel2 = labels[2];
    this.selectedPreset = 'custom';
  }

  private currentFaction(type: number): FactionInfo {
    return factionInfoForOptions(this.currentOptions(), type);
  }

  private currentFactions(): FactionInfo[] {
    return [this.currentFaction(0), this.currentFaction(1), this.currentFaction(2)];
  }

  private defaultThemeLabel(type: number): string {
    return defaultLabelsForTheme(this.themeKey)[type];
  }

  private customLabel(type: number): string {
    if (this.themeKey === 'rps') {
      return this.defaultThemeLabel(type);
    }
    if (type === 0) return this.customLabel0;
    if (type === 1) return this.customLabel1;
    return this.customLabel2;
  }

  private setCustomLabel(type: number, value: string): void {
    const fallback = this.defaultThemeLabel(type);
    const next = value.trim().length > 0 ? value.trim() : fallback;
    if (type === 0) {
      this.customLabel0 = next;
    } else if (type === 1) {
      this.customLabel1 = next;
    } else {
      this.customLabel2 = next;
    }
  }

  private currentRoundCounts(): number[] {
    return [
      Math.max(3, this.rockCount - this.penaltyRock),
      Math.max(3, this.scissorsCount - this.penaltyScissors),
      Math.max(3, this.paperCount - this.penaltyPaper)
    ];
  }

  private calculateOdds(counts: number[]): number[] {
    const total = counts[0] + counts[1] + counts[2];
    const odds = [2, 2, 2];
    for (let type = 0; type < 3; type += 1) {
      const prey = counts[(type + 1) % 3];
      const predator = counts[(type + 2) % 3];
      const strength = Math.max(1.2, counts[type] + prey * 0.3 - predator * 0.18);
      odds[type] = Math.max(1.18, Math.min(4.8, total / strength * 0.72));
    }
    return odds;
  }

  private updateOddsFromCounts(counts: number[]): void {
    const odds = this.calculateOdds(counts);
    this.oddsRock = odds[0];
    this.oddsScissors = odds[1];
    this.oddsPaper = odds[2];
  }

  private oddsFor(type: number): number {
    if (type === 0) return this.oddsRock;
    if (type === 1) return this.oddsScissors;
    return this.oddsPaper;
  }

  private stepStake(step: number): void {
    this.stake = Math.max(0, Math.min(Math.max(0, this.bank), this.stake + step));
  }

  private startNewMatch(): void {
    this.roundIndex = 1;
    this.winsRock = 0;
    this.winsScissors = 0;
    this.winsPaper = 0;
    this.penaltyRock = 0;
    this.penaltyScissors = 0;
    this.penaltyPaper = 0;
    this.matchDone = false;
    this.resultSettled = false;
    this.resultOverlayReady = false;
    this.updateOddsFromCounts([this.rockCount, this.scissorsCount, this.paperCount]);
  }

  private addWin(type: number): void {
    if (type === 0) {
      this.winsRock += 1;
    } else if (type === 1) {
      this.winsScissors += 1;
    } else {
      this.winsPaper += 1;
    }
  }

  private addPenalty(type: number, value: number): void {
    if (type === 0) {
      this.penaltyRock += value;
    } else if (type === 1) {
      this.penaltyScissors += value;
    } else {
      this.penaltyPaper += value;
    }
  }

  private winCount(type: number): number {
    if (type === 0) return this.winsRock;
    if (type === 1) return this.winsScissors;
    return this.winsPaper;
  }

  private scoreText(): string {
    return `${this.currentFaction(0).emoji}${this.winsRock} · ${this.currentFaction(1).emoji}${this.winsScissors} · ${this.currentFaction(2).emoji}${this.winsPaper}`;
  }

  private matchSummary(): string {
    const mode = this.deathmatch ? '死斗' : `${this.durationSec}s`;
    const tournament = this.tournament ? ` · ${this.bestOf}局` : '';
    const bet = this.betting ? ` · 竞猜${this.stake}` : '';
    return `${mode}${tournament}${bet}`;
  }

  private hudMatchText(): string {
    if (this.tournament) {
      return this.scoreText();
    }
    return this.deathmatch ? '死斗' : `${this.durationSec}s`;
  }

  private resultTitle(): string {
    if (this.winner < 0) {
      return '无人获胜';
    }
    const faction = this.currentFaction(this.winner);
    if (this.tournament && this.matchDone) {
      return `${faction.emoji} ${faction.label} 拿下整场`;
    }
    return `${faction.emoji} ${faction.label} 获胜`;
  }

  private nextRoundLabel(): string {
    if (this.tournament && !this.matchDone) {
      return '下一局';
    }
    return this.tournament && this.matchDone ? '新赛制' : '再来一局';
  }

  private handleNextRoundClick(): void {
    if (this.tournament && this.matchDone) {
      this.goHome();
      return;
    }
    if (this.tournament) {
      this.roundIndex += 1;
    }
    this.beginCountdown();
  }

  private goHome(): void {
    this.clearCountdown();
    this.clearResultTimer();
    this.reportVisible = false;
    this.resultOverlayReady = false;
    this.engine.resetToSetup();
    this.audioService.pauseBgm();
    this.phase = GamePhase.Setup;
  }

  private openReport(): void {
    this.reportData = this.engine.report();
    this.reportVisible = true;
  }

  private clearResultTimer(): void {
    if (this.resultTimer >= 0) {
      clearTimeout(this.resultTimer);
      this.resultTimer = -1;
    }
  }

  private toggleOption(label: string): void {
    if (label === '通知') {
      this.notifications = !this.notifications;
      if (!this.notifications) {
        this.eventText = '';
      }
    } else if (label === '上帝之手') {
      this.godHand = !this.godHand;
    } else if (label === '地形障碍') {
      this.obstacles = !this.obstacles;
    } else if (label === '缩圈') {
      this.shrink = !this.shrink;
    } else if (label === '据点争夺') {
      this.controlZones = !this.controlZones;
    } else if (label === '悬赏头名') {
      this.bounty = !this.bounty;
    } else if (label === '黑洞') {
      this.blackHole = !this.blackHole;
    } else if (label === '我们中出了叛徒') {
      this.traitor = !this.traitor;
    } else if (label === '绝地求生') {
      this.lastStand = !this.lastStand;
    } else if (label === '灭霸响指') {
      this.thanos = !this.thanos;
    } else if (label === '能量道具') {
      this.powerUps = !this.powerUps;
      if (!this.powerUps) {
        this.teamPowerUps = false;
      }
    } else if (label === '团队道具') {
      this.teamPowerUps = !this.teamPowerUps;
      if (this.teamPowerUps) {
        this.powerUps = true;
      }
    } else if (label === '我要打十个') {
      this.tenAgainstOne = !this.tenAgainstOne;
    } else if (label === '死斗模式') {
      this.deathmatch = !this.deathmatch;
    } else if (label === '多局赛制') {
      this.tournament = !this.tournament;
    } else if (label === '下注模式') {
      this.betting = !this.betting;
    }
    this.selectedPreset = 'custom';
  }

  private handleTouch(event: TouchEvent): void {
    if (!this.godHand || (this.phase !== GamePhase.Playing && this.phase !== GamePhase.Paused)) {
      this.engine.setHand(false, 0, 0, false);
      return;
    }
    if (event.touches === undefined || event.touches.length === 0) {
      this.engine.setHand(false, 0, 0, false);
      return;
    }
    const touch = event.touches[0];
    const active = event.type === TouchType.Down || event.type === TouchType.Move;
    this.engine.setHand(active, touch.x, touch.y, this.fieldMode === FieldMode.Pull);
  }
}

@Extend(Column)
function panelStyle() {
  .width('100%')
  .padding(12)
  .borderRadius(8)
  .backgroundColor('rgba(248,250,247,0.92)')
  .border({ width: 1, color: 'rgba(23,32,28,0.12)' })
}

function emptyReport(): NativeBattleReport {
  return {
    title: '本局战报',
    textLines: ['完成一局后可以查看战报。'],
    mvpLines: ['暂无数据。'],
    points: []
  };
}
