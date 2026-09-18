import { ArenaPalette as P } from './ArenaPalette';
import { ARENA_NAMES } from './ArenaModel';
import { ArenaAction, ArenaIcon } from './ArenaControls';

@Component
export struct ArenaHelp {
  @Prop dark: boolean = false;
  close: () => void = () => {};
  @State tab: number = 0;
  @State demo: number = 0;
  build() {
    Column({space:12}) {
      Row({space:10}) {
        Text('上场前，先认识队友').fontSize(21).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).layoutWeight(1)
        ArenaIcon({name:'close',label:'关闭玩法说明',dark:this.dark,action:this.close})
      }.width('100%')
      Row({space:6}) {
        ForEach(['怎么转阵','如何取胜','指挥小队'], (label: string,i: number) => {
          Button(label).layoutWeight(1).height(44).fontSize(13)
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
            this.Paragraph('碰到对手，就有变化','被克制的一方加入对方小队，不是从场上消失。同队只会轻轻挤开。刚转阵的队员有 0.6 秒缓冲，不会一瞬间反复变队。')
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
            this.Paragraph('星星与战绩','挑战通关得 1 星；整局风推最多用 1 次再得 1 星；提前 20% 完成再得 1 星。生存关第三星改为结算时至少剩 3 人。每关保存最高星数。自定义不等人数或庭院事件属于自由练习，不计正式胜场和成就。')
          } else {
            this.Paragraph('先选技能，再选位置','点亮技能后，按住战场可预览范围，移动调整，松手释放。移出战场、取消手势、暂停或改变窗口大小都不会扣次数。空范围不会消耗技能；也可以用“投向据点 / 投向队伍”快捷按钮。')
            this.Paragraph('集结 · 冷却 10 秒','范围内最多 6 名队友朝目标集合，持续 4 秒。可用于抢点、收拢队伍。敌方不会接受你的集合指令。')
            this.Paragraph('护阵 · 冷却 16 秒','范围内最多 4 名队友获得 3 秒护盾，各抵挡 1 次碰撞转阵。金色圆环就是护盾标记；护盾不会阻止预告过的换队事件。')
            this.Paragraph('风推 · 每局 2 次，冷却 12 秒','将范围内所有队员向外推开，包括自己人。用来解围或打散据点，释放前先看清范围。')
            this.Paragraph('庭院会提前提醒你','风场提前 2 秒标出范围；换队队员头顶会出现 3 秒倒计时；收圈会提前 3 秒提示。花盆固定挡路，双方都要绕行。')
            this.Paragraph('随时歇一会儿','暂停、返回大厅、切到后台都会保留进度。旋转或折叠会先停住，让你看清新布局后继续。只在空间确实太小时提示展开，不会因为设备是折叠屏就挡住游戏。')
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
