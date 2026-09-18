import { ArenaPalette as P } from './ArenaPalette';
import { ARENA_NAMES, ARENA_SKILLS } from './ArenaModel';

@Component
export struct ArenaIcon {
  @Prop name: string = 'pause';
  @Prop label: string = '暂停';
  @Prop dark: boolean = false;
  @Prop primary: boolean = false;
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Circle }) {
      Image($rawfile(P.icon(this.name,this.dark,this.primary))).width(21).height(21)
        .draggable(false).accessibilityLevel('no')
    }.width(44).height(44).padding(0).backgroundColor(this.primary ? P.accent(this.dark) : P.surface(this.dark))
      .border({width:this.primary ? 0 : 1,color:P.line(this.dark),radius:22})
      .accessibilityText(this.label).onClick(this.action)
  }
}

@Component
export struct ArenaAction {
  @Prop label: string = '开始乱斗';
  @Prop icon: string = '';
  @Prop dark: boolean = false;
  @Prop primary: boolean = true;
  @Prop active: boolean = true;
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Capsule }) {
      Row({space:8}) {
        if (this.icon.length > 0) {
          Image($rawfile(P.icon(this.icon,this.dark,this.primary))).width(19).height(19)
            .draggable(false).accessibilityLevel('no')
        }
        Text(this.label).fontSize(15).fontWeight(FontWeight.Medium).maxLines(2).textAlign(TextAlign.Center)
          .fontColor(this.primary ? P.onAccent(this.dark) : P.ink(this.dark))
      }.justifyContent(FlexAlign.Center)
    }.width('100%').height(48).padding({left:12,right:12}).enabled(this.active)
      .backgroundColor(this.primary ? P.accent(this.dark) : P.soft(this.dark))
      .accessibilityText(this.label).onClick(this.action)
  }
}

@Component
export struct ArenaSkill {
  @Prop index: number = 0;
  @Prop hint: string = '准备好了';
  @Prop dark: boolean = false;
  @Prop selected: boolean = false;
  @Prop active: boolean = true;
  @Prop spacious: boolean = false;
  action: () => void = () => {};
  build() {
    Button({type:ButtonType.Normal}) {
      Column({space:3}) {
        Row({space:5}) {
          Image($rawfile(P.icon(['gather','shield','wind'][this.index],this.dark,this.selected)))
            .width(this.spacious ? 23 : 18).height(this.spacious ? 23 : 18).draggable(false).accessibilityLevel('no')
          Text(ARENA_SKILLS[this.index]).fontSize(this.spacious ? 16 : 14).fontWeight(FontWeight.Medium)
            .fontColor(this.selected ? P.onAccent(this.dark) : P.ink(this.dark))
        }
        Text(this.hint).fontSize(10).maxLines(1)
          .fontColor(this.selected ? P.onAccent(this.dark) : P.muted(this.dark))
      }.justifyContent(FlexAlign.Center)
    }.width('100%').height(this.spacious ? 76 : 54).padding(0).borderRadius(18)
      .backgroundColor(this.selected ? P.accent(this.dark) : P.surface(this.dark))
      .border({width:1,color:this.selected ? P.accent(this.dark) : P.line(this.dark),radius:18})
      .opacity(this.active ? 1 : .62).enabled(this.active)
      .accessibilityText(`${ARENA_SKILLS[this.index]}，${this.hint}`).onClick(this.action)
  }
}

@Component
export struct ArenaTeam {
  @Prop faction: number = 0;
  @Prop count: number = 0;
  @Prop score: number = 0;
  @Prop dark: boolean = false;
  @Prop zones: boolean = false;
  @Prop chosen: boolean = false;
  @Prop compact: boolean = false;
  build() {
    Column({space:2}) {
      Row({space:5}) {
        Image($rawfile(P.piece(this.faction,this.dark))).width(this.compact ? 19 : 25).height(this.compact ? 19 : 25)
          .draggable(false).accessibilityLevel('no')
        Text(ARENA_NAMES[this.faction]).fontSize(this.compact ? 10 : 12).fontWeight(FontWeight.Medium)
          .maxLines(1).fontColor(P.faction(this.faction,this.dark))
        if(this.chosen && !this.compact) {
          Text('我方').fontSize(8).fontColor(P.faction(this.faction,this.dark)).padding({left:3,right:3,top:1,bottom:1})
            .backgroundColor(P.surface(this.dark)).borderRadius(4)
        }
      }.justifyContent(FlexAlign.Center)
      Row({space:3}) {
        Text(`${this.zones ? Math.floor(this.score) : this.count}`).fontSize(this.compact ? 15 : 22)
          .fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark)).maxLines(1)
        Text(this.zones ? `分 · ${this.count} 位` : '位').fontSize(this.compact ? 9 : 10).fontColor(P.muted(this.dark)).maxLines(1)
      }.alignItems(VerticalAlign.Bottom).justifyContent(FlexAlign.Center)
    }.width('100%').height(this.compact ? 44 : 64).justifyContent(FlexAlign.Center).borderRadius(this.compact ? 13 : 18)
      .backgroundColor(this.chosen ? P.teamSurface(this.faction,this.dark) : P.surface(this.dark))
      .border({width:this.chosen ? 1 : 0,color:this.chosen ? P.faction(this.faction,this.dark) : P.line(this.dark)})
      .accessibilityText(`${ARENA_NAMES[this.faction]}队${this.chosen ? '，你的小队' : ''}，${this.count}位队员${this.zones ? '，'+Math.floor(this.score)+'据点分' : ''}`)
  }
}

@Component
export struct ArenaRuleStrip {
  @Prop dark: boolean = false;
  build() {
    Row({space:5}) {
      Text('相遇转阵').fontSize(10).fontColor(P.muted(this.dark)).margin({right:3})
      ForEach([0,1,2,0], (f:number,i:number) => {
        Image($rawfile(P.piece(f,this.dark))).width(20).height(20).draggable(false).accessibilityLevel('no')
        if(i<3) {
          Image($rawfile(P.icon('arrow',this.dark))).width(12).height(12).opacity(.6).draggable(false).accessibilityLevel('no')
        }
      }, (f:number,i:number):string => `${f}-${i}`)
    }.width('100%').height(24).justifyContent(FlexAlign.Center)
      .accessibilityText('石头克剪刀，剪刀克布，布克石头。接触后，被克制的一方换队。')
  }
}
