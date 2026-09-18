import { ArenaPalette as P } from './ArenaPalette';
import { ARENA_MISSIONS } from './ArenaModel';
import { ARENA_MISSION_TIPS, ArenaEventGuide, arenaEventGuide, arenaWinGuide,
  arenaMissionSkills, arenaMissionStars, arenaScenarioEvents } from './ArenaGuide';

@Component
export struct ArenaEventCard {
  @Prop event: string = 'none';
  @Prop dark: boolean = false;
  build() {
    Column({space:8}) {
      Row({space:8}) {
        Image($rawfile(P.icon(arenaEventGuide(this.event).icon,this.dark))).width(22).height(22).draggable(false).accessibilityLevel('no')
        Text(arenaEventGuide(this.event).name).fontSize(15).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
      }.width('100%')
      Text(arenaEventGuide(this.event).when).fontSize(11).lineHeight(18).fontColor(P.accent(this.dark))
      Text(arenaEventGuide(this.event).effect).fontSize(12).lineHeight(21).fontColor(P.ink(this.dark))
      Text(`可以这样应对：${arenaEventGuide(this.event).tip}`).fontSize(12).lineHeight(21).fontColor(P.muted(this.dark))
    }.width('100%').alignItems(HorizontalAlign.Start).padding(14).borderRadius(18).backgroundColor(P.soft(this.dark))
  }
}

@Component
export struct ArenaMissionCard {
  @Prop mission: number = 0;
  @Prop dark: boolean = false;
  build() {
    Column({space:10}) {
      Row({space:8}) {
        Image($rawfile(P.icon('flag',this.dark))).width(22).height(22).draggable(false).accessibilityLevel('no')
        Text(`第 ${this.mission+1} 关 · ${ARENA_MISSIONS[this.mission].name}`).fontSize(15).fontWeight(FontWeight.Medium)
          .fontColor(P.ink(this.dark)).layoutWeight(1)
      }.width('100%')
      this.Detail('目标',arenaWinGuide(ARENA_MISSIONS[this.mission]))
      this.Detail('开局',`${this.mission===1 ? '我方 6 位，对方各 9 位' : '三队各 8 位'}；限时 ${ARENA_MISSIONS[this.mission].limit} 秒。`)
      this.Detail('技能',arenaMissionSkills(this.mission))
      this.Detail('试着这样玩',ARENA_MISSION_TIPS[this.mission])
      if(ARENA_MISSIONS[this.mission].rule==='zones') {
        Text('占点：中心圈内人数唯一领先并保持 1 秒后开始得分；无人或并列时停分。短暂失去队员也可能等到有限援军。')
          .fontSize(11).lineHeight(19).fontColor(P.muted(this.dark))
      }
      Column({space:6}) {
        Text('怎样拿星').fontSize(12).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
        ForEach(arenaMissionStars(this.mission), (rule:string) => {
          Row({space:6}) {
            Image($rawfile(P.icon('star',this.dark))).width(14).height(14).margin({top:2}).draggable(false).accessibilityLevel('no')
            Text(rule).fontSize(11).lineHeight(19).fontColor(P.muted(this.dark)).layoutWeight(1)
          }.width('100%').alignItems(VerticalAlign.Top)
        })
      }.width('100%').alignItems(HorizontalAlign.Start)
      ForEach(arenaScenarioEvents(ARENA_MISSIONS[this.mission]), (event:ArenaEventGuide) => {
        this.Detail(event.name,`${event.when}。${event.effect}`)
      }, (event:ArenaEventGuide):string => event.id)
    }.width('100%').alignItems(HorizontalAlign.Start).padding(14).borderRadius(18)
      .backgroundColor(P.surface(this.dark)).border({width:1,color:P.line(this.dark),radius:18})
  }
  @Builder Detail(label:string,body:string) {
    Column({space:4}) {
      Text(label).fontSize(12).fontWeight(FontWeight.Medium).fontColor(P.accent(this.dark))
      Text(body).fontSize(12).lineHeight(21).fontColor(P.ink(this.dark))
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
}
