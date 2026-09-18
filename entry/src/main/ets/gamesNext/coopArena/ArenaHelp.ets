import { ArenaPalette as P } from './ArenaPalette';
import { ARENA_NAMES, ArenaConfig, ARENA_MISSIONS, arenaDefaultConfig } from './ArenaModel';
import { ArenaAction, ArenaIcon } from './ArenaControls';
import { ARENA_EVENTS, ArenaEventGuide } from './ArenaGuide';
import { ArenaEventCard, ArenaMissionCard } from './ArenaGuideCards';

@Component
export struct ArenaHelp {
  @Prop dark: boolean = false;
  @Prop config: ArenaConfig = arenaDefaultConfig();
  @State selectedMission: number = 0;
  close: () => void = () => {};
  @State tab: number = 0;
  @State demo: number = 0;
  aboutToAppear(): void {
    this.selectedMission=this.config.mission;
    this.tab=this.config.mode==='challenge' ? 3 : this.config.event!=='none' ? 2 : 0;
  }
  build() {
    Column({space:12}) {
      Row({space:10}) {
        Text('玩法与规则').fontSize(20).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark)).layoutWeight(1)
        ArenaIcon({name:'close',label:'关闭玩法说明',dark:this.dark,action:this.close})
      }.width('100%')
      Row({space:6}) {
        ForEach(['相遇规则','取胜技能','庭院事件','挑战小局'], (label: string,i: number) => {
          Button(label).layoutWeight(1).height(44).fontSize(11).padding({left:2,right:2})
            .fontColor(this.tab===i ? P.onAccent(this.dark) : P.ink(this.dark))
            .backgroundColor(this.tab===i ? P.accent(this.dark) : P.soft(this.dark)).onClick(() => { this.tab=i; })
        })
      }.width('100%')
      Scroll() {
        Column({space:14}) {
          if (this.tab === 0) {
            ForEach([0,1,2], (f: number) => {
              Row({space:12}) {
                Image($rawfile(P.piece(f,this.dark))).width(48).height(48).draggable(false).accessibilityLevel('no')
                Text('克制 →').fontSize(13).fontColor(P.muted(this.dark))
                Image($rawfile(P.piece((f+1)%3,this.dark))).width(48).height(48).draggable(false).accessibilityLevel('no')
                Text(`${ARENA_NAMES[f]}克${ARENA_NAMES[(f+1)%3]}`).fontSize(14).fontColor(P.ink(this.dark)).layoutWeight(1)
              }.width('100%').padding(12).borderRadius(20).backgroundColor(P.soft(this.dark))
            })
            this.Paragraph('外圈接触，就会转阵','以图章外圈为接触范围。石头碰到剪刀，剪刀就加入石头队；其他两组同理。同队只会挤开，场上总数量保持不变。')
            this.Paragraph('多人相遇，也只换一次','同时接触时，按这一刻各自的小队统一判定，不会在同一帧连着换队。刚转阵的队员会亮起短环，并有 0.6 秒保护；护盾也能抵挡一次转阵。')
            Column({space:12}) {
              Text('点一下，试试转阵').fontSize(16).fontColor(P.ink(this.dark))
              Row({space:18}) {
                Image($rawfile(P.piece(0,this.dark))).width(64).height(64).draggable(false)
                Image($rawfile(P.piece(this.demo ? 0 : 1,this.dark))).width(64).height(64).draggable(false)
              }
              ArenaAction({label:this.demo ? '再试一次' : '让石头碰到剪刀',icon:'play',dark:this.dark,
                action:() => { this.demo = this.demo ? 0 : 1; }})
              Text(this.demo ? '剪刀加入了石头队，场上总人数没有减少。' : '这是一段独立演示，不会影响正在玩的对局。')
                .fontSize(12).lineHeight(20).fontColor(P.muted(this.dark))
            }.width('100%').padding(16).borderRadius(24).backgroundColor(P.soft(this.dark))
          } else if (this.tab === 1) {
            this.Paragraph('快速乱斗 · 60 秒','三方自动追逐，你为选中的小队加油。场上只剩一队即获胜；时间到时人数最多者获胜，最高人数并列则平局。本模式没有指挥技能。')
            this.Paragraph('据点争夺 · 90 秒','圆圈内人数唯一领先并连续维持 1 秒，就能控制据点。每秒获得 2–3.5 分，圈内人数越多越快。无人或并列时暂停得分。先到 100 分，或时间到分数最高者获胜；最高分并列是平局。')
            this.Paragraph('有限援军，不会无限复活','仅据点模式：一队不足 3 人持续 4 秒后，预告 2 秒再补到 3 人。每队最多 2 次，场上最多 60 人；场地已满时援军等待。')
            this.Paragraph('挑战小局 · 八段不同经历','每关固定开局，目标写在关卡卡片上。少数派、护队生存、花盆、风场、换队和收圈会逐步加入。生存关只看你的小队能否撑到 45 秒，不按据点或清场结算。')
            this.Paragraph('星星与战绩','挑战通关得 1 星；整局风推最多用 1 次再得 1 星；提前 20% 完成再得 1 星。生存关第三星改为结算时至少剩 3 人。每关保存最高星数。自定义不等人数或庭院事件属于自由练习，不计正式胜场，但成就照常记录。')
            this.Paragraph('先选技能，再选位置','点亮技能后，按住战场可预览范围，移动调整，松手释放。移出战场、取消手势、暂停或改变窗口大小都不会扣次数。空范围不会消耗技能；也可以用“投向据点 / 投向队伍”快捷按钮。')
            this.Paragraph('集结 · 冷却 10 秒','范围内最多 6 名队友朝目标集合，持续 4 秒。可用于抢点、收拢队伍。敌方不会接受你的集合指令。')
            this.Paragraph('护阵 · 冷却 16 秒','范围内最多 4 名队友获得 3 秒护盾，各抵挡 1 次碰撞转阵。金色圆环就是护盾标记；护盾不会阻止预告过的换队事件。')
            this.Paragraph('风推 · 每局 2 次，冷却 12 秒','将范围内所有队员向外推开，包括自己人。用来解围或打散据点，释放前先看清范围。')
            this.Paragraph('庭院会提前提醒你','风场提前 2 秒标出范围；换队队员头顶会出现 3 秒倒计时；收圈会提前 3 秒提示。花盆固定挡路，双方都要绕行。')
            this.Paragraph('随时歇一会儿','暂停、返回大厅、切到后台都会保留进度。旋转或折叠会先停住，让你看清新布局后继续。只在空间确实太小时提示展开，不会因为设备是折叠屏就挡住游戏。')
          } else if(this.tab===2) {
            this.Paragraph('先看时间，再看变化','下面的秒数都从开局计时。事件每局只触发一次，花盆则一直在场。提前结束对局后，不会继续发生事件。')
            ForEach(ARENA_EVENTS, (event:ArenaEventGuide) => {
              ArenaEventCard({event:event.id,dark:this.dark})
            }, (event:ArenaEventGuide):string => event.id)
            this.Paragraph('如何选择','快速乱斗和据点争夺可在开局前的“自定义人数与庭院事件”中选择一种；选平静庭院就不启用事件。挑战小局使用关卡固定的组合，最后一关同时有花盆与换队。')
            this.Paragraph('会影响战绩吗','自定义事件属于自由练习，不计正式胜场，但成就照常记录。挑战中的固定事件属于正式关卡，照常记录通关星数。')
          } else {
            this.Paragraph('每一关，都有不同目标','点选关卡查看说明。这里的选择只用于阅读，不会切换或重开正在进行的游戏。')
            Flex({wrap:FlexWrap.Wrap}) {
              ForEach([0,1,2,3,4,5,6,7], (i:number) => {
                Button(`第 ${i+1} 关`).height(44).padding({left:12,right:12}).margin({right:6,bottom:6}).fontSize(12)
                  .fontColor(this.selectedMission===i ? P.onAccent(this.dark) : P.ink(this.dark))
                  .backgroundColor(this.selectedMission===i ? P.accent(this.dark) : P.soft(this.dark))
                  .accessibilityText(`第 ${i+1} 关，${ARENA_MISSIONS[i].name}`).onClick(() => { this.selectedMission=i; })
              })
            }.width('100%')
            ArenaMissionCard({mission:this.selectedMission,dark:this.dark})
            this.Paragraph('保留最好的一次','每关只保留最高星数，重复挑战不会扣星。三个得星条件分别计算，整局使用了两次风推，也仍可凭及时获胜拿到时间奖励星。')
          }
        }.width('100%').padding({bottom:12})
      }.layoutWeight(1).width('100%').scrollBar(BarState.Off)
      ArenaAction({label:'知道了',dark:this.dark,action:this.close})
    }.width('100%').height('100%').padding(16).backgroundColor(P.surface(this.dark)).borderRadius(24)
  }
  @Builder Paragraph(title: string,body: string) {
    Column({space:8}) {
      Text(title).fontSize(16).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
      Text(body).fontSize(13).lineHeight(23).fontColor(P.muted(this.dark))
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
}
