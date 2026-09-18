import { common } from '@kit.AbilityKit';
import systemDateTime from '@ohos.systemDateTime';
import { AchievementEvent } from '../../shell/AchievementModule';
import { ArenaConfig, ArenaEntity, ArenaProfile, ArenaSave, ArenaScenario, ARENA_NAMES, ARENA_SKILLS,
  arenaConfigValid, arenaDefaultConfig, arenaPractice, arenaProfile, arenaScenario } from './ArenaModel';
import { ArenaEngine } from './ArenaEngine';
import { ArenaInsets, ArenaRect, ArenaLayout, arenaLayout } from './ArenaLayout';
import { ArenaPalette as P } from './ArenaPalette';
import { ArenaAudio } from './ArenaAudio';
import { ArenaWindow, ArenaFold } from './ArenaWindow';
import { ArenaStorage } from './ArenaStorage';
import { ArenaRenderer } from './ArenaRenderer';
import { ArenaPerfScene, ArenaPerformance } from './ArenaPerformance';
import { ArenaClock } from './ArenaClock';
import { ArenaInput } from './ArenaInput';
import { arenaSave, arenaApplyResult, arenaProfileValid } from './ArenaProgress';
import { ArenaAction, ArenaIcon, ArenaSkill, ArenaTeam, ArenaRuleStrip } from './ArenaControls';
import { ArenaSetup } from './ArenaSetup';
import { ArenaHelp } from './ArenaHelp';
import { ArenaDialogFrame } from './ArenaDialogFrame';
import { ArenaReport } from './ArenaReport';
import { arenaSceneLabel, arenaLiveNotice } from './ArenaGuide';

@Component
export struct CoopArenaPage {
  @Prop @Watch('themeChanged') dark: boolean = false;
  @Prop @Watch('soundChanged') soundEnabled: boolean = true;
  @Prop @Watch('exitRequested') exitRequest: number = 0;
  exitToHub: () => void = () => {};
  updateSound: (enabled: boolean) => void = () => {};
  recordScore: (score: number) => void = () => {};
  reportAchievementEvent: (event: AchievementEvent) => Promise<boolean> = async () => false;
  private engine: ArenaEngine = new ArenaEngine();
  private renderer: ArenaRenderer = new ArenaRenderer();
  private canvas: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private sounds: ArenaAudio = new ArenaAudio();
  private storage: ArenaStorage = new ArenaStorage();
  private hostWindow: ArenaWindow = new ArenaWindow();
  private clock: ArenaClock = new ArenaClock();
  private perf: ArenaPerformance = new ArenaPerformance();
  private input: ArenaInput = new ArenaInput();
  private context: common.Context | undefined = undefined;
  private insets: ArenaInsets = {top:24,bottom:16,left:0,right:0};
  private creases: ArenaRect[] = [];
  private fold: ArenaFold = {foldable:false,status:0};
  private pageWidth: number = 390;
  private pageHeight: number = 844;
  private canvasReady: boolean = false;
  private disposed: boolean = false;
  private loaded: boolean = false;
  private hasRound: boolean = false;
  private lastTick: number = 0;
  private lastHud: number = 0;
  private lastSave: number = 0;
  private pixelRatio: number = 1;
  private profileCounter: number = 0;
  private profileClock: () => number = () => this.now();
  private remainingCountdown: number = 3000;
  private helpReturn: string = 'setup';
  @State viewport: ArenaLayout = arenaLayout(390,844);
  @State dialog: string = 'loading';
  @State profile: ArenaProfile = arenaProfile();
  @State configuration: ArenaConfig = arenaDefaultConfig();
  @State scenario: ArenaScenario = arenaScenario(arenaDefaultConfig());
  @State counts: number[] = [8,8,8];
  @State scores: number[] = [0,0,0];
  @State timeLeft: number = 60;
  @State cooldowns: number[] = [0,0,0];
  @State skillAllowed: boolean[] = [false,false,false];
  @State windLeft: number = 2;
  @State armed: number = -1;
  @State countdown: number = 3;
  @State message: string = '挑一支小队，为它加油';
  @State notice: string = '';
  @State saveFailed: boolean = false;
  @State saving: boolean = false;
  @State errorText: string = '进度暂时没能读出来，请重试。';

  aboutToAppear(): void {
    this.context = this.getUIContext().getHostContext() as common.Context;
    if (this.context === undefined) { this.dialog='error'; return; }
    this.pixelRatio=this.getUIContext().vp2px(1);
    this.sounds.setEnabled(this.soundEnabled); this.sounds.init(this.context);
    this.hostWindow.setDark(this.dark);
    this.hostWindow.attach(this.context,(px:number):number => this.getUIContext().px2vp(px),
      (insets:ArenaInsets,creases:ArenaRect[],fold:ArenaFold) => this.windowChanged(insets,creases,fold),
      () => this.pause('已暂停，回来后再继续'));
    this.renderer.prepare(this.dark); this.boot();
  }
  aboutToDisappear(): void {
    this.disposed=true; this.stop(); this.save(); this.renderer.release(); this.sounds.release(); this.hostWindow.release();
  }
  build() {
    Stack({alignContent:Alignment.TopStart}) {
      Image($rawfile(P.scene('garden',this.dark))).width('100%').height('100%').objectFit(ImageFit.Fill)
        .draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      if (this.dialog === 'setup') {
        ArenaSetup({dark:this.dark,availableWidth:this.sheetWidth(840),availableHeight:this.sheetHeight(),profile:this.profile,
          initial:this.configuration,sound:this.soundEnabled,start:(config:ArenaConfig) => this.newRound(config),
          close:() => this.leave(),help:(config:ArenaConfig) => { this.configuration=config; this.showHelp(); },toggleSound:() => this.updateSound(!this.soundEnabled)})
          .width(this.sheetWidth(840)).height(this.sheetHeight())
          .position({x:this.sheetX(840),y:this.viewport.pane.y+8})
      } else if (this.hasRound && !this.viewport.limited) {
        this.Board()
        if (this.viewport.wide) {
          Scroll() {
            Column({space:12}) {
              this.Header()
              this.Stats()
              if (!this.viewport.compact) {
                Text(this.scenario.summary).fontSize(12).lineHeight(19).fontColor(P.muted(this.dark)).width('100%')
              }
              this.Commands()
              ArenaAction({label:'玩法与计分',icon:'help',primary:false,dark:this.dark,action:() => this.showHelp()})
              if (this.viewport.panel.height > 500) {
                Image($rawfile(P.scene('bench',this.dark))).width('100%').height(100).objectFit(ImageFit.Contain)
                  .draggable(false).accessibilityLevel('no')
              }
            }.width('100%').padding({bottom:8})
          }.width(this.viewport.panel.width).height(this.viewport.panel.height)
            .position({x:this.viewport.panel.x,y:this.viewport.panel.y}).scrollBar(BarState.Off)
        } else {
          Column({space:this.viewport.gap}) { this.Header(); this.Stats() }
            .width(this.viewport.panel.width).position({x:this.viewport.panel.x,y:this.viewport.pane.y})
          Column() { this.Commands() }.width(this.viewport.panel.width).height(this.viewport.keys)
            .position({x:this.viewport.panel.x,y:this.viewport.board.y+this.viewport.board.height+this.viewport.gap})
          if (this.portraitSpare() >= 88) {
            Image($rawfile(P.scene('bench',this.dark))).width(200).height(Math.min(96,this.portraitSpare()-16))
              .objectFit(ImageFit.Contain).draggable(false).accessibilityLevel('no').hitTestBehavior(HitTestMode.None)
              .position({x:this.viewport.pane.x+(this.viewport.pane.width-200)/2,
                y:this.viewport.pane.y+this.viewport.pane.height-this.portraitSpare()/2-Math.min(96,this.portraitSpare()-16)/2})
          }
        }
      }
      if (this.dialog === 'help') {
        ArenaHelp({dark:this.dark,config:this.configuration,close:() => this.closeHelp()}).width(this.sheetWidth(640)).height(this.sheetHeight())
          .position({x:this.sheetX(640),y:this.viewport.pane.y+8})
      } else if (this.dialog === 'result') {
        ArenaReport({dark:this.dark,round:this.engine.round,saveFailed:this.saveFailed,busy:this.saving,
          retry:() => this.replay(),next:() => this.nextMission(),setup:() => this.toSetup(),save:() => this.publishResult()})
          .width(this.sheetWidth(580)).height(this.sheetHeight()).position({x:this.sheetX(580),y:this.viewport.pane.y+8})
      } else if (this.dialog !== 'setup' && (this.viewport.limited || !['play','countdown'].includes(this.dialog))) {
        this.Dialog()
      } else if (this.dialog === 'countdown') {
        Text(`${this.countdown}`).fontSize(76).fontWeight(FontWeight.Bold).fontColor(P.accent(this.dark))
          .width(120).height(120).textAlign(TextAlign.Center).backgroundColor(P.surface(this.dark)).borderRadius(60)
          .position({x:this.viewport.board.x+(this.viewport.board.width-120)/2,y:this.viewport.board.y+(this.viewport.board.height-120)/2})
          .hitTestBehavior(HitTestMode.None)
      }
    }.width('100%').height('100%').backgroundColor(P.background(this.dark))
      .onAreaChange((oldArea:Area,area:Area) => {
        this.pageWidth=Number(area.width); this.pageHeight=Number(area.height); this.hostWindow.measure(); this.relayout();
      })
  }
  @Builder Header() {
    Row({space:6}) {
      ArenaIcon({name:'back',label:'暂停并返回',dark:this.dark,action:() => this.exitRequested()})
      Column({space:2}) {
        Text('鸡窝乱斗').fontSize(this.viewport.wide ? 18 : 20)
          .fontWeight(FontWeight.Medium).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).fontColor(P.ink(this.dark))
        Row({space:4}) {
          Image($rawfile(P.icon('clock',this.dark))).width(12).height(12).draggable(false).accessibilityLevel('no')
          Text(this.clockText()).fontSize(12).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
          Text(`· ${this.scenario.name}`).fontSize(11).fontColor(P.muted(this.dark)).maxLines(1)
            .textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1)
        }.width('100%')
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      ArenaIcon({name:this.soundEnabled ? 'sound' : 'mute',label:this.soundEnabled ? '关闭音效' : '开启音效',dark:this.dark,
        action:() => this.updateSound(!this.soundEnabled)})
      ArenaIcon({name:'pause',label:'暂停与玩法',primary:true,dark:this.dark,action:() => this.pause()})
    }.width('100%').height(this.viewport.header)
  }
  @Builder Stats() {
    Row({space:5}) {
      ForEach([0,1,2], (f:number) => {
        ArenaTeam({faction:f,count:this.counts[f],score:this.scores[f],dark:this.dark,zones:this.scenario.rule==='zones',
          chosen:this.configuration.faction===f,compact:this.viewport.compact||this.viewport.wide}).layoutWeight(1)
      })
    }.width('100%').height(this.viewport.stats)
  }
  @Builder Board() {
    Stack() {
      Image($rawfile(P.scene(this.scenario.obstacles ? 'arena_garden' : 'arena',this.dark))).width('100%').height('100%').objectFit(ImageFit.Fill)
        .draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      Canvas(this.canvas).width('100%').height('100%')
        .onReady(() => { this.canvasReady=true; this.paint(); })
        .onAreaChange(() => this.paint())
        .onTouch((event:TouchEvent) => this.touch(event))
        .accessibilityText(`庭院战场，石头 ${this.counts[0]} 人，剪刀 ${this.counts[1]} 人，布 ${this.counts[2]} 人。选择技能后可触摸战场或使用投向据点、投向队伍按钮。`)
      if (this.armed >= 0) {
        Text(this.message).fontSize(11).lineHeight(16).maxLines(2).textAlign(TextAlign.Center)
          .fontColor(P.ink(this.dark)).backgroundColor(P.surface(this.dark)).borderRadius(14).padding(8)
          .width(this.viewport.board.width-24).position({x:12,y:12}).hitTestBehavior(HitTestMode.None)
      }
    }.width(this.viewport.board.width).height(this.viewport.board.height).borderRadius(24).clip(true)
      .backgroundColor(P.surface(this.dark)).border({width:1,color:P.line(this.dark),radius:24})
      .position({x:this.viewport.board.x,y:this.viewport.board.y})
  }
  @Builder Commands() {
    Column({space:6}) {
      if (this.scenario.skills.some((s:boolean):boolean => s)) {
        Row({space:6}) {
          ForEach([0,1,2], (i:number) => {
            ArenaSkill({index:i,hint:!this.scenario.skills[i] ? '本关不可用' : this.cooldowns[i]>0 ? `${this.cooldowns[i]} 秒` :
              i===2 ? `余 ${this.windLeft} 次` : '点击选点',dark:this.dark,selected:this.armed===i,active:this.skillAllowed[i]&&this.dialog==='play',
              spacious:this.viewport.wide&&!this.viewport.compact,action:() => this.arm(i)}).layoutWeight(1)
          })
        }.width('100%')
        if (this.armed >= 0) {
          Row({space:6}) {
            Button('投向据点').layoutWeight(1).height(44).fontSize(12).fontColor(P.ink(this.dark)).backgroundColor(P.soft(this.dark))
              .onClick(() => this.cast(360,360))
            Button('投向队伍').layoutWeight(1).height(44).fontSize(12).fontColor(P.ink(this.dark)).backgroundColor(P.soft(this.dark))
              .onClick(() => this.castAtTeam())
            ArenaIcon({name:'close',label:'取消技能',dark:this.dark,action:() => { this.cancelInput(); this.paint(); }})
          }.width('100%')
        } else {
          Text(this.message).width('100%').height(44).fontSize(11).lineHeight(17).maxLines(2)
            .textAlign(TextAlign.Center).fontColor(P.muted(this.dark))
        }
      } else {
        Column({space:6}) {
          Row({space:8}) {
            Image($rawfile(P.icon(this.notice.length>0 ? 'leaf' : 'eye',this.dark))).width(20).height(20).draggable(false).accessibilityLevel('no')
            Column({space:3}) {
              Text(this.counts[this.configuration.faction]===0 ? '我方已转阵，看看谁能胜出' : '小队正在自动交锋')
                .fontSize(13).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark)).maxLines(1)
              Text(this.notice.length>0 ? this.notice : '统一全场获胜 · 时间到比队员数量').fontSize(11).lineHeight(17)
                .fontColor(this.notice.length>0 ? P.accent(this.dark) : P.muted(this.dark)).maxLines(2)
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            ArenaIcon({name:'help',label:'查看碰撞规则与玩法',dark:this.dark,action:() => this.showHelp()})
          }.width('100%')
          ArenaRuleStrip({dark:this.dark})
        }.width('100%').padding(10).borderRadius(22).backgroundColor(P.surface(this.dark))
      }
    }.width('100%')
  }
  @Builder Dialog() {
    ArenaDialogFrame({dark:this.dark,availableWidth:this.viewport.pane.width,availableHeight:this.viewport.pane.height,
      paneX:this.viewport.pane.x,paneY:this.viewport.pane.y,contentKey:this.dialog,
      estimatedHeight:this.dialog==='loading' ? 240 : 480}) {
      Column({space:10}) {
        Image($rawfile(P.scene(this.viewport.limited&&this.hasRound ? 'unfold' : 'mark',this.dark)))
          .width(80).height(64).objectFit(ImageFit.Contain).draggable(false).accessibilityLevel('no')
        Text(this.dialogTitle()).fontSize(20).lineHeight(26).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).textAlign(TextAlign.Center)
        Text(this.dialogBody()).fontSize(13).lineHeight(22).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
        if (this.dialog === 'loading') {
          LoadingProgress().width(36).height(36).color(P.accent(this.dark))
        } else if (this.dialog === 'error') {
          ArenaAction({label:'重新读取进度',dark:this.dark,action:() => this.boot()})
          ArenaAction({label:'重新建立本游戏进度',dark:this.dark,primary:false,action:() => { this.dialog='erase'; }})
          ArenaAction({label:'返回大厅',dark:this.dark,primary:false,action:this.exitToHub})
        } else if (this.dialog === 'erase') {
          ArenaAction({label:'确认重新建立',dark:this.dark,action:() => this.erase()})
          ArenaAction({label:'保留原记录',dark:this.dark,primary:false,action:() => { this.dialog='error'; }})
        } else if (this.dialog === 'restart') {
          ArenaAction({label:'结束这局，重新选择',dark:this.dark,action:() => this.toSetup()})
          ArenaAction({label:'保留这局',dark:this.dark,primary:false,action:() => { this.dialog='paused'; }})
        } else {
          if (!this.viewport.limited) {
            ArenaAction({label:this.remainingCountdown>0 ? '准备上场' : '继续这局',icon:'play',dark:this.dark,action:() => this.resume()})
          }
          if (this.saveFailed) { Text('刚才没有保存成功，返回前会再次尝试。').fontSize(12).fontColor(P.muted(this.dark)) }
          ArenaAction({label:'玩法与计分',icon:'help',dark:this.dark,primary:false,action:() => this.showHelp()})
          ArenaAction({label:this.profile.reducedMotion ? '效果：轻量（点击恢复）' : '效果：柔和（点击减弱）',icon:'leaf',dark:this.dark,
            primary:false,action:() => this.toggleMotion()})
          ArenaAction({label:'换个玩法',icon:'restart',dark:this.dark,primary:false,active:!this.saving,action:() => { this.dialog='restart'; }})
          ArenaAction({label:this.saving ? '正在保存…' : '保存并返回大厅',icon:'save',dark:this.dark,primary:false,
            active:!this.saving,action:() => this.leave()})
        }
      }.width('100%').padding(20)
    }
  }

  private async boot(): Promise<void> {
    if (this.context === undefined) return;
    this.dialog='loading'; this.loaded=false;
    const raw = await this.storage.load(this.context);
    if (this.disposed) return;
    if (this.storage.lastLoadFailed) { this.errorText='进度暂时没能读出来，请重试。原记录会保留。'; this.dialog='error'; return; }
    if (raw.length === 0) { this.loaded=true; this.hasRound=false; this.dialog='setup'; return; }
    try {
      if (raw.length>170000) throw new Error('oversized save');
      const save = JSON.parse(raw) as ArenaSave;
      if (save===null || save.version!==1 || !arenaProfileValid(save.profile) || typeof save.round!=='string') throw new Error('invalid save');
      const e = new ArenaEngine();
      if (save.round.length>0 && !e.restore(save.round)) throw new Error('invalid round');
      this.profile=save.profile; this.engine=e; this.scenario=JSON.parse(JSON.stringify(e.scenario)) as ArenaScenario; this.hasRound=save.round.length>0; this.loaded=true;
      if (save.config!==undefined && arenaConfigValid(save.config)) this.configuration=save.config;
      if (this.hasRound) {
        this.configuration=JSON.parse(JSON.stringify(e.round.config)) as ArenaConfig; this.remainingCountdown=e.round.tick===0 ? 3000 : 0;
        this.updateHud(); this.dialog=e.round.finished ? 'result' : 'paused';
        this.message='已找到上次的对局，准备好再继续';
        if (e.round.finished) this.publishResult();
      } else this.dialog='setup';
    } catch (_) {
      this.errorText='这份本地进度暂时无法读取。可以重试，或确认后重新建立；旧版乱斗的记录不会受影响。'; this.dialog='error';
    }
  }
  private newRound(config: ArenaConfig): void {
    if (this.saving || !this.loaded) return;
    this.stop(); this.engine=new ArenaEngine(config); this.configuration=JSON.parse(JSON.stringify(this.engine.round.config)) as ArenaConfig;
    this.scenario=JSON.parse(JSON.stringify(this.engine.scenario)) as ArenaScenario; this.hasRound=true;
    this.remainingCountdown=3000; this.countdown=3; this.message=this.engine.scenario.summary; this.updateHud();
    this.dialog=this.viewport.limited ? 'paused' : 'countdown'; this.save(); this.paint();
    if (!this.viewport.limited) this.run();
  }
  private async replay(): Promise<void> {
    if (this.saving || !await this.preserveResult()) return;
    const c: ArenaConfig = JSON.parse(JSON.stringify(this.configuration)) as ArenaConfig;
    c.seed=(Date.now()%4294967294)+1; this.newRound(c);
  }
  private async nextMission(): Promise<void> {
    if (this.saving || !await this.preserveResult()) return;
    const c: ArenaConfig = JSON.parse(JSON.stringify(this.configuration)) as ArenaConfig;
    c.mission=Math.min(7,c.mission+1); this.newRound(c);
  }
  private async toSetup(): Promise<void> {
    if (this.saving) return;
    if (this.hasRound && this.engine.round.finished && !await this.preserveResult()) return;
    this.stop(); this.hasRound=false; this.dialog='setup'; this.save();
  }
  private async preserveResult(): Promise<boolean> {
    if (!this.hasRound || !this.engine.round.finished || arenaPractice(this.configuration) || this.engine.round.reported) return true;
    await this.publishResult();
    return this.engine.round.reported && !this.saveFailed;
  }
  private erase(): void {
    this.stop(); this.profile=arenaProfile(); this.hasRound=false; this.loaded=true; this.dialog='setup'; this.save();
  }
  private run(): void {
    if (this.disposed || this.viewport.limited) return;
    this.lastTick=this.now(); this.lastHud=this.lastTick; this.lastSave=this.lastTick; this.engine.resetClock(); this.profileCounter=0; this.perf.begin(this.lastTick,this.perfScene());
    this.clock.start(() => this.tick());
  }
  private tick(): void {
    if (this.disposed || this.viewport.limited || !['play','countdown'].includes(this.dialog)) return;
    const now=this.now(), interval=now-this.lastTick, clock=this.clock.mode; this.lastTick=now;
    if (interval>500) { this.perf.stall(interval); this.pause('刚才离开了一会儿，准备好再继续'); return; }
    if (this.dialog==='countdown') {
      this.remainingCountdown=Math.max(0,this.remainingCountdown-Math.min(50,interval));
      this.countdown=Math.max(1,Math.ceil(this.remainingCountdown/1000));
      if (this.remainingCountdown===0) { this.dialog='play'; this.perf.reset(now); this.sounds.play('tap'); }
      return;
    }
    this.profileCounter+=1;
    // Eleven avoids phase-locking the samples to six-tick targeting or thirty-tick AI commands.
    const steps=this.engine.advance(interval,this.profileCounter%11===0 ? this.profileClock : undefined), simulated=this.now();
    this.paint(); const painted=this.now();
    let hudChanged=false;
    if (now-this.lastHud>=100) { this.lastHud=now; hudChanged=this.updateHud(); }
    const saveStart=this.now(), finished=this.engine.round.finished;
    if(finished) { this.stop(false); this.updateHud(); this.dialog='result'; this.publishResult(); }
    else if (now-this.lastSave>=5000) { this.lastSave=now; this.save(); }
    const saveSubmitted=this.now();
    this.playEvents();
    const completed=this.now(), sampled=this.engine.timing, r=this.engine.round;
    this.perf.frame({at:now,interval:interval,logic:simulated-now,paint:painted-simulated,total:completed-now,
      hud:saveStart-painted,hudChanged:hudChanged,clock:clock,sprites:this.renderer.mode(),audio:completed-saveSubmitted,
      save:saveSubmitted-saveStart,steps:steps,checks:this.engine.checks,scans:this.engine.scans,dropped:this.engine.droppedMs,
      count:r.entities.length,seed:this.configuration.seed,elapsed:this.engine.time(),rock:r.counts[0],scissors:r.counts[1],cloth:r.counts[2],
      effects:this.profile.reducedMotion ? 0 : this.engine.effects.length,conversions:r.conversions,contacts:this.engine.contacts,crowding:this.engine.crowding,
      sampled:sampled.steps,grid:sampled.grid,seek:sampled.seek,move:sampled.move,contact:sampled.contact,rules:sampled.rules});
    if(finished)this.perf.finish('结算');
  }
  private perfScene(): ArenaPerfScene {
    const r=this.engine.round;
    return {session:r.session,label:arenaSceneLabel(r.config),seed:r.config.seed,initial:r.config.counts.join('/'),
      window:`${this.pageWidth.toFixed(1)}×${this.pageHeight.toFixed(1)}`,board:this.viewport.board.width,density:this.pixelRatio,fold:this.fold.status,
      dark:this.dark,reduced:this.profile.reducedMotion,sound:this.soundEnabled};
  }
  private reportScene(): void { if(this.hasRound && this.loaded)this.perf.context(this.perfScene()); }
  private playEvents(): void {
    const events=this.engine.sounds;
    if (events.length===0) return;
    const priority=['win','finish','warning','skill','zone','turn'];
    for (let i=0;i<priority.length;i+=1) if (events.includes(priority[i])) { this.sounds.play(priority[i]); break; }
    events.length=0;
  }
  private stop(finishSampling: boolean = true): void {
    if(finishSampling)this.perf.finish(this.engine.round.finished ? '结算' : '暂停或退出');
    this.clock.stop(); this.cancelInput(); this.engine.resetClock(); this.sounds.silence(); }
  private pause(message: string = '歇一会儿，队友们会等你'): void {
    if (this.dialog!=='play' && this.dialog!=='countdown') { this.cancelInput(); return; }
    this.stop(); this.dialog='paused'; this.message=message; this.save(); this.paint();
  }
  private resume(): void {
    if (!this.loaded || this.viewport.limited || !this.hasRound || this.engine.round.finished) return;
    this.dialog=this.remainingCountdown>0 ? 'countdown' : 'play'; this.message=this.engine.scenario.summary; this.run();
  }
  private showHelp(): void {
    this.helpReturn=this.dialog==='setup' ? 'setup' : 'paused'; this.pause(); this.dialog='help';
  }
  private closeHelp(): void { this.dialog=this.helpReturn; this.paint(); }
  private exitRequested(): void {
    if (this.saving) return;
    if (this.armed>=0) { this.cancelInput(); this.paint(); return; }
    if (this.dialog==='help') { this.closeHelp(); return; }
    if (this.dialog==='play' || this.dialog==='countdown') { this.pause(); return; }
    if (this.dialog==='restart') { this.dialog='paused'; return; }
    if (!this.loaded) { this.exitToHub(); return; }
    this.leave();
  }
  private async leave(): Promise<void> {
    if (this.saving) return;
    this.pause();
    if (!this.loaded) { this.exitToHub(); return; }
    this.saving=true; const ok=await this.save(); this.saving=false;
    if (ok && !this.disposed) this.exitToHub();
  }
  private async save(): Promise<boolean> {
    if (!this.loaded || this.context===undefined) return false;
    const began=this.now(), session=this.engine.round.session;
    const ok=await this.storage.save(this.context,arenaSave(this.profile,this.hasRound ? this.engine.serialize() : '',this.configuration));
    this.perf.saved(this.now()-began,ok,session);
    if (!this.disposed) this.saveFailed=!ok;
    return ok;
  }
  private async publishResult(): Promise<void> {
    const r=this.engine.round;
    if (!r.finished || this.saving) return;
    this.saving=true;
    const profile: ArenaProfile=JSON.parse(JSON.stringify(this.profile)) as ArenaProfile;
    arenaApplyResult(profile,r); this.profile=profile;
    const wasReported=r.reported;
    const ok=await this.save();
    if (ok && !wasReported && !arenaPractice(r.config)) {
      const accepted=await this.reportAchievementEvent({eventId:`${r.session}:finish`,sessionId:r.session,gameId:'rpsBattle',type:'sessionEnd',
        occurredAt:Date.now(),isOfficial:true,facts:[{key:'won',value:r.won ? 1 : 0},{key:'supportWon',value:r.won ? 1 : 0},
          {key:'conversions',value:r.conversions},{key:'elapsedSec',value:this.engine.time()},{key:'score',value:r.counts[r.config.faction]}]}).catch(() => false);
      if (accepted) {
        r.reported=true;
        this.recordScore(profile.stars.reduce((a:number,b:number):number => a+b,0));
        if (r===this.engine.round) await this.save();
      } else if (!this.disposed) this.saveFailed=true;
    }
    if (!this.disposed) this.saving=false;
  }
  private updateHud(): boolean {
    const r=this.engine.round, t=this.engine.time(), f=r.config.faction;
    let changed=false;
    if(this.valuesDiffer(this.counts,r.counts)) { this.counts=r.counts.slice(); changed=true; }
    const scores=r.scores.map((n:number):number => Math.floor(n));
    if(this.valuesDiffer(this.scores,scores)) { this.scores=scores; changed=true; }
    const left=Math.max(0,Math.ceil(this.engine.scenario.limit-t));
    if(this.timeLeft!==left) { this.timeLeft=left; changed=true; }
    if(this.windLeft!==r.windLeft[f]) { this.windLeft=r.windLeft[f]; changed=true; }
    const cooldowns=r.readyAt[f].map((n:number):number => Math.max(0,Math.ceil(n-t)));
    if(this.valuesDiffer(this.cooldowns,cooldowns)) { this.cooldowns=cooldowns; changed=true; }
    const allowed=[this.engine.skillReady(f,0),this.engine.skillReady(f,1),this.engine.skillReady(f,2)];
    if(allowed.some((value:boolean,i:number):boolean => value!==this.skillAllowed[i])) { this.skillAllowed=allowed; changed=true; }
    const moments=r.moments;
    const notice=arenaLiveNotice(r,this.engine.scenario);
    if(this.notice!==notice) { this.notice=notice; changed=true; }
    let message=this.message;
    if (this.armed<0 && moments.length>0 && t-moments[moments.length-1].time<4) message=moments[moments.length-1].text;
    else if (this.armed<0) message=this.engine.scenario.rule==='zones' ?
      (r.capturing<0 ? '据点争夺中 · 暂未得分' : `${ARENA_NAMES[r.capturing]}队占领中 · 目标 ${this.engine.scenario.target} 分`) : this.engine.scenario.summary;
    if(this.armed<0 && notice.length>0)message=notice;
    if(this.message!==message) { this.message=message; changed=true; }
    if (this.armed>=0 && !this.skillAllowed[this.armed]) { this.cancelInput(); changed=true; }
    return changed;
  }
  private valuesDiffer(a:number[],b:number[]): boolean {
    for(let i=0;i<b.length;i+=1)if(a[i]!==b[i])return true;
    return a.length!==b.length;
  }
  private arm(i:number): void {
    if (this.dialog!=='play' || !this.engine.skillReady(this.configuration.faction,i)) return;
    const next=this.armed===i ? -1 : i; this.input.arm(next); this.armed=next;
    this.message=next>=0 ? `${ARENA_SKILLS[i]}：按住预览，松手释放` : this.engine.scenario.summary;
    this.sounds.play('tap'); this.paint();
  }
  private touch(event:TouchEvent): void {
    if (this.dialog!=='play' || this.viewport.limited || this.armed<0) return;
    const size=this.viewport.board.width;
    if (event.type===TouchType.Cancel) { this.cancelInput(); this.paint(); return; }
    const list=event.changedTouches;
    for (let i=0;i<list.length;i+=1) {
      const p=list[i];
      if (event.type===TouchType.Down) this.input.down(p.id,p.x,p.y,size);
      else if (event.type===TouchType.Move) this.input.move(p.id,p.x,p.y,size);
      else if (event.type===TouchType.Up) {
        const target=this.input.up(p.id,p.x,p.y,size);
        if (target!==undefined) this.cast(target.x,target.y);
      }
    }
    this.paint();
  }
  private castAtTeam(): void {
    const own=this.engine.round.entities.filter((e:ArenaEntity):boolean => e.faction===this.configuration.faction);
    if (own.length===0) return;
    let best=own[0], count=0;
    for (let i=0;i<own.length;i+=1) {
      const n=own.filter((e:ArenaEntity):boolean => Math.pow(e.x-own[i].x,2)+Math.pow(e.y-own[i].y,2)<=Math.pow(this.engine.radius(this.armed),2)).length;
      if (n>count) { count=n; best=own[i]; }
    }
    this.cast(best.x,best.y);
  }
  private cast(x:number,y:number): void {
    if (this.dialog!=='play' || this.armed<0 || this.viewport.limited) return;
    const affected=this.engine.cast(this.configuration.faction,this.armed,x,y);
    if (affected>0) { this.cancelInput(); this.playEvents(); this.updateHud(); this.save(); }
    else this.message='这里没有可影响的队员，次数没有扣除';
    this.paint();
  }
  private cancelInput(): void { this.input.cancel(); this.armed=-1; }
  private paint(): void {
    if (!this.canvasReady || this.disposed || !this.hasRound || this.viewport.limited) return;
    this.renderer.paint(this.canvas,this.engine,this.viewport.board.width,this.dark,this.armed,this.input.x,this.input.y,this.profile.reducedMotion,
      this.dialog==='play' ? this.engine.interpolation() : 1);
  }
  private windowChanged(insets:ArenaInsets,creases:ArenaRect[],fold:ArenaFold): void {
    const changed=this.fold.status!==fold.status || JSON.stringify(this.insets)!==JSON.stringify(insets) || JSON.stringify(this.creases)!==JSON.stringify(creases);
    this.insets=insets; this.creases=creases; this.fold=fold;
    if (changed) { this.pause('屏幕布局变了，准备好再继续'); this.cancelInput(); }
    this.relayout(); this.reportScene();
  }
  private relayout(): void {
    if (this.pageWidth<=0 || this.pageHeight<=0) return;
    const next=arenaLayout(this.pageWidth,this.pageHeight,this.insets,this.creases);
    if (JSON.stringify(next)===JSON.stringify(this.viewport)) return;
    this.pause('屏幕布局变了，准备好再继续'); this.cancelInput(); this.viewport=next; this.paint(); this.reportScene();
  }
  private themeChanged(): void { this.hostWindow.setDark(this.dark); this.paint(); this.reportScene(); }
  private soundChanged(): void { this.sounds.setEnabled(this.soundEnabled); this.reportScene(); }
  private toggleMotion(): void {
    const p: ArenaProfile=JSON.parse(JSON.stringify(this.profile)) as ArenaProfile;
    p.reducedMotion=!p.reducedMotion; this.profile=p; this.save(); this.paint(); this.reportScene();
  }
  private clockText(): string { return `${Math.floor(this.timeLeft/60)}:${(this.timeLeft%60).toString().padStart(2,'0')}`; }
  private now(): number { return systemDateTime.getUptime(systemDateTime.TimeType.STARTUP,true)/1000000; }
  private sheetWidth(max:number): number { return Math.max(1,Math.min(max,this.viewport.pane.width-16)); }
  private sheetX(max:number): number { return this.viewport.pane.x+(this.viewport.pane.width-this.sheetWidth(max))/2; }
  private sheetHeight(): number { return Math.max(1,this.viewport.pane.height-16); }
  private portraitSpare(): number {
    return this.viewport.pane.y+this.viewport.pane.height-this.viewport.board.y-this.viewport.board.height-this.viewport.gap-this.viewport.keys;
  }
  private dialogTitle(): string {
    if (this.dialog==='loading') return '队友们正在集合';
    if (this.dialog==='error') return '进度还没准备好';
    if (this.dialog==='erase') return '重新建立本游戏进度？';
    if (this.dialog==='restart') return '要换一种玩法吗？';
    return this.viewport.limited ? '展开一点，玩得更舒服' : '庭院歇一会儿';
  }
  private dialogBody(): string {
    if (this.dialog==='loading') return '正在读取这座庭院的记录';
    if (this.dialog==='error') return this.errorText;
    if (this.dialog==='erase') return '这会清除庭院擂台的对局和挑战星数。旧版乱斗与其他游戏记录会保留。';
    if (this.dialog==='restart') return '当前对局会结束，不记胜负。也可以保留，稍后继续。';
    return this.viewport.limited ? '当前可用空间太小，对局已经暂停并保存。展开屏幕或放大窗口后，点继续即可。' : this.message;
  }
}
