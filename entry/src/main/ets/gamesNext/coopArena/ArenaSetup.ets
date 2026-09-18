import { ArenaConfig, ArenaProfile, ARENA_MISSIONS, ARENA_NAMES, arenaDefaultConfig, arenaProfile, arenaPractice } from './ArenaModel';
import { ArenaPalette as P } from './ArenaPalette';
import { ArenaAction, ArenaIcon } from './ArenaControls';
import { ARENA_EVENTS, ArenaEventGuide } from './ArenaGuide';
import { ArenaEventCard, ArenaMissionCard } from './ArenaGuideCards';

@Component
export struct ArenaSetup {
  @Prop dark: boolean = false;
  @Prop availableWidth: number = 390;
  @Prop availableHeight: number = 760;
  @Prop profile: ArenaProfile = arenaProfile();
  @Prop initial: ArenaConfig = arenaDefaultConfig();
  @Prop sound: boolean = true;
  start: (config: ArenaConfig) => void = () => {};
  close: () => void = () => {};
  help: (config: ArenaConfig) => void = () => {};
  toggleSound: () => void = () => {};
  @State mode: string = 'classic';
  @State faction: number = 0;
  @State mission: number = 0;
  @State counts: number[] = [8,8,8];
  @State event: string = 'none';
  @State options: boolean = false;
  aboutToAppear(): void {
    this.mode = this.initial.mode; this.faction = this.initial.faction; this.mission = this.initial.mission;
    this.counts = this.initial.counts.slice(); this.event = this.initial.event;
  }
  private config(): ArenaConfig {
    return {mode:this.mode,faction:this.faction,mission:this.mission,counts:this.counts.slice(),event:this.event,
      seed:(Date.now() % 4294967294)+1};
  }
  private changeCount(f: number, delta: number): void {
    const next = this.counts.slice(); next[f] = Math.max(3,Math.min(20,next[f]+delta)); this.counts = next;
  }
  build() {
    Column({space:12}) {
      Row({space:10}) {
        ArenaIcon({name:'back',label:'返回大厅',dark:this.dark,action:this.close})
        Column({space:2}) {
          Text('鸡窝乱斗').fontSize(23).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
          Text('庭院擂台 · 小小队伍，大大变数').fontSize(11).fontColor(P.muted(this.dark)).maxLines(1)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        ArenaIcon({name:this.sound ? 'sound' : 'mute',label:this.sound ? '关闭音效' : '开启音效',dark:this.dark,action:this.toggleSound})
      }.width('100%')
      Scroll() {
        Column({space:18}) {
          Row({space:14}) {
            Image($rawfile(P.scene('mark',this.dark))).width(84).height(76).objectFit(ImageFit.Contain).draggable(false).accessibilityLevel('no')
            Column({space:5}) {
              Text('碰一下，就成了队友').fontSize(20).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
              Text('石头克剪刀，剪刀克布，布克石头。\n挑一支小队，看它逆风翻盘。').fontSize(13).lineHeight(21).fontColor(P.muted(this.dark))
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          }.width('100%').padding(14).borderRadius(24).backgroundColor(P.surface(this.dark))
          if (this.availableWidth >= 620) {
            Row({space:20}) {
              Column({space:12}) { this.Modes() }.layoutWeight(1)
              Column({space:16}) { this.Teams(); this.Record() }.layoutWeight(1)
            }.alignItems(VerticalAlign.Top)
          } else { this.Modes(); this.Teams() }
          if (this.mode === 'challenge') {
            Column({space:8}) {
              this.Section('八个庭院挑战', '点选关卡，展开目标、技能和拿星说明')
              ForEach([0,1,2,3], (row: number) => {
                Column({space:8}) {
                  Row({space:8}) { this.Mission(row*2); this.Mission(row*2+1) }.width('100%')
                  if(Math.floor(this.mission/2)===row) { ArenaMissionCard({mission:this.mission,dark:this.dark}) }
                }.width('100%')
              })
              Text('每关固定开局，可反复练习；保存本关最高星数，不会扣掉已经拿到的星星。')
                .fontSize(11).lineHeight(18).fontColor(P.muted(this.dark))
            }.width('100%')
          } else {
            ArenaAction({label:this.options ? '收起自定义' : '自定义人数与庭院事件',icon:'tune',dark:this.dark,primary:false,
              action:() => { this.options = !this.options; }})
            if (this.options) {
              Column({space:10}) {
                this.Section('小队人数', '每队 3–20 人，最多 60 人')
                Row({space:6}) {
                  ForEach([8,12,20], (count:number) => {
                    Button(`${count*3} 位`).layoutWeight(1).height(44).fontSize(13)
                      .fontColor(this.counts.every((n:number):boolean => n===count) ? P.onAccent(this.dark) : P.ink(this.dark))
                      .backgroundColor(this.counts.every((n:number):boolean => n===count) ? P.accent(this.dark) : P.soft(this.dark))
                      .accessibilityText(`三队各 ${count} 位，共 ${count*3} 位队员`)
                      .onClick(() => { this.counts=[count,count,count]; })
                  })
                }.width('100%')
                ForEach([0,1,2], (f: number) => {
                  Row({space:8}) {
                    Image($rawfile(P.piece(f,this.dark))).width(30).height(30).draggable(false).accessibilityLevel('no')
                    Text(ARENA_NAMES[f]).fontSize(14).fontColor(P.ink(this.dark)).layoutWeight(1)
                    Button('−').width(44).height(44).fontSize(20).fontColor(P.ink(this.dark)).backgroundColor(P.soft(this.dark))
                      .enabled(this.counts[f]>3).accessibilityText(`减少${ARENA_NAMES[f]}人数`).onClick(() => this.changeCount(f,-1))
                    Text(`${this.counts[f]}`).width(26).textAlign(TextAlign.Center).fontColor(P.ink(this.dark))
                    Button('+').width(44).height(44).fontSize(20).fontColor(P.ink(this.dark)).backgroundColor(P.soft(this.dark))
                      .enabled(this.counts[f]<20).accessibilityText(`增加${ARENA_NAMES[f]}人数`).onClick(() => this.changeCount(f,1))
                  }.width('100%')
                })
                this.Section('庭院事件', '开局前选择，每局一种；点选后查看说明')
                Flex({wrap:FlexWrap.Wrap}) {
                  ForEach(ARENA_EVENTS, (event: ArenaEventGuide) => {
                    Button(event.name)
                      .height(44).margin({right:6,bottom:6}).padding({left:14,right:14}).fontSize(13)
                      .fontColor(event.id===this.event ? P.onAccent(this.dark) : P.ink(this.dark))
                      .backgroundColor(event.id===this.event ? P.accent(this.dark) : P.soft(this.dark))
                      .onClick(() => { this.event = event.id; })
                  }, (event:ArenaEventGuide):string => event.id)
                }.width('100%')
                ArenaEventCard({event:this.event,dark:this.dark})
                Text('事件时间从开局算起；若对局提前结束，后续事件不再发生。').fontSize(11).lineHeight(18).fontColor(P.muted(this.dark))
                Text(arenaPractice(this.config()) ? '自由练习：不计胜场与成就，尽管试试不同组合。' : '均衡对局：正常记录胜场与成就。')
                  .fontSize(12).lineHeight(19).fontColor(P.muted(this.dark))
              }.padding(14).borderRadius(20).backgroundColor(P.surface(this.dark))
            }
          }
          if (this.availableWidth < 620) { this.Record() }
          ArenaAction({label:'玩法、技能与计分',icon:'help',primary:false,dark:this.dark,action:() => this.help(this.config())})
        }.width('100%').padding({bottom:8})
      }.layoutWeight(1).width('100%').scrollBar(BarState.Off)
      ArenaAction({label:this.mode==='challenge' ? `挑战 · ${ARENA_MISSIONS[this.mission].name}` :
        this.mode==='zones' ? '开始据点争夺' : '开始快速乱斗',icon:'play',dark:this.dark,action:() => this.start(this.config())})
    }.width('100%').height('100%').padding(12)
  }
  @Builder Section(title: string, subtitle: string) {
    Column({space:3}) {
      Text(title).fontSize(16).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
      Text(subtitle).fontSize(11).fontColor(P.muted(this.dark))
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
  @Builder Modes() {
    Column({space:8}) {
      this.Section('今天怎么玩', '短局开场，随时暂停')
      ForEach(['classic','zones','challenge'], (name: string,index: number) => {
        Button({type:ButtonType.Normal}) {
          Row({space:10}) {
            Image($rawfile(P.icon(['eye','flag','star'][index],this.dark))).width(24).height(24).draggable(false).accessibilityLevel('no')
            Column({space:4}) {
              Text(['快速乱斗','据点争夺','挑战小局'][index]).fontSize(16).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
              Text(['60 秒自动追逐 · 轻松观战','集结、护阵、风推 · 主动指挥','八个固定关卡 · 收集 24 颗星'][index]).fontSize(11).fontColor(P.muted(this.dark))
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            Text(name===this.mode ? '已选' : '选择').fontSize(11).fontColor(P.accent(this.dark))
          }.padding(14).width('100%')
        }.width('100%').padding(0).borderRadius(20).backgroundColor(name===this.mode ? P.soft(this.dark) : P.surface(this.dark))
          .border({width:1,color:name===this.mode ? P.accent(this.dark) : P.line(this.dark),radius:20})
          .onClick(() => { this.mode = name; })
      })
    }.width('100%')
  }
  @Builder Teams() {
    Column({space:10}) {
      this.Section('你为谁加油', '外形与颜色一起区分小队')
      Row({space:8}) {
        ForEach([0,1,2], (f: number) => {
          Button({type:ButtonType.Normal}) {
            Column({space:6}) {
              Image($rawfile(P.piece(f,this.dark))).width(52).height(52).draggable(false).accessibilityLevel('no')
              Text(`${ARENA_NAMES[f]}${this.faction===f ? ' · 你' : ''}`).fontSize(13).fontColor(P.faction(f,this.dark))
            }.padding(10).width('100%')
          }.layoutWeight(1).padding(0).borderRadius(22).backgroundColor(this.faction===f ? P.soft(this.dark) : P.surface(this.dark))
            .border({width:1,color:this.faction===f ? P.accent(this.dark) : P.line(this.dark),radius:22})
            .accessibilityText(`选择${ARENA_NAMES[f]}队`).onClick(() => { this.faction = f; })
        })
      }.width('100%')
    }.width('100%')
  }
  @Builder Mission(i: number) {
    Button({type:ButtonType.Normal}) {
      Column({space:4}) {
        Text(`${i+1} · ${ARENA_MISSIONS[i].name}`).fontSize(14).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
        Text(ARENA_MISSIONS[i].summary).fontSize(11).lineHeight(16).fontColor(P.muted(this.dark)).maxLines(2)
        Text(`已获 ${this.profile.stars[i]} / 3 星`).fontSize(11).fontColor(P.accent(this.dark))
      }.alignItems(HorizontalAlign.Start).width('100%').padding(12)
    }.layoutWeight(1).height(103).padding(0).borderRadius(18)
      .backgroundColor(this.mission===i ? P.soft(this.dark) : P.surface(this.dark))
      .border({width:1,color:this.mission===i ? P.accent(this.dark) : P.line(this.dark),radius:18})
      .onClick(() => { this.mission = i; })
  }
  @Builder Record() {
    Row({space:12}) {
      Image($rawfile(P.scene('bench',this.dark))).width(64).height(54).draggable(false).accessibilityLevel('no')
      Column({space:4}) {
        Text(`挑战星星 ${this.profile.stars.reduce((a:number,b:number):number => a+b,0)} / 24`).fontSize(14).fontColor(P.ink(this.dark))
        Text(`乱斗 ${this.profile.wins}/${this.profile.rounds} 胜 · 据点 ${this.profile.zoneWins}/${this.profile.zoneRounds} 胜`)
          .fontSize(11).fontColor(P.muted(this.dark))
      }.alignItems(HorizontalAlign.Start)
    }.width('100%').padding(12).borderRadius(20).backgroundColor(P.surface(this.dark))
  }
}
