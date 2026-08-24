import { RpsBattleSetupCardHeader } from './RpsBattleSetupCardHeader';
import { RpsBattleTheme } from './RpsBattleTheme';
import {
  RpsBattleComebackRuleKey,
  RpsBattleEnhancementSelection,
  RpsBattleModeKey
} from './RpsBattleTypes';

@Component
export struct RpsBattleEnhancementSetupCard {
  @Prop order: string = '03';
  @Prop selectedModeKey: RpsBattleModeKey = 'classic';
  @Prop enhancementSelection: RpsBattleEnhancementSelection = {
    comebackRule: 'none',
    godHandEnabled: false
  };
  selectComebackRule: (rule: RpsBattleComebackRuleKey) => void = () => {};
  toggleGodHand: () => void = () => {};

  build() {
    Column({ space: 10 }) {
      RpsBattleSetupCardHeader({ order: this.order, title: '战局强化', subtitle: this.subtitleText() })
      if (this.selectedModeKey === 'classic') {
        this.ComebackRuleRow()
        this.SectionRule()
      }
      this.GodHandRow()
    }
    .width('100%')
    .padding(14)
    .borderRadius(8)
    .backgroundColor(RpsBattleTheme.panelBg)
    .border({ width: 1, color: RpsBattleTheme.panelLine })
  }

  @Builder
  ComebackRuleRow() {
    Column({ space: 7 }) {
      Text('反滚雪球')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(RpsBattleTheme.pageInk)
        .maxLines(1)
      Text('经典乱斗专属，后选规则会覆盖前一个')
        .fontSize(10)
        .fontColor(RpsBattleTheme.muted)
        .maxLines(1)
      Row({ space: 6 }) {
        this.ComebackOption('关闭', 'none')
        this.ComebackOption('悬赏头名', 'bounty')
        this.ComebackOption('我要打十个', 'tenAgainstOne')
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  ComebackOption(label: string, rule: RpsBattleComebackRuleKey) {
    Text(label)
      .layoutWeight(1)
      .height(40)
      .fontSize(this.comebackLabelFontSize(rule))
      .fontWeight(FontWeight.Bold)
      .fontColor(this.enhancementSelection.comebackRule === rule ?
        RpsBattleTheme.primaryButtonText : RpsBattleTheme.pageInk)
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .backgroundColor(this.enhancementSelection.comebackRule === rule ?
        RpsBattleTheme.primaryButtonBg : RpsBattleTheme.optionBg)
      .borderRadius(8)
      .border({
        width: 1,
        color: this.enhancementSelection.comebackRule === rule ?
          RpsBattleTheme.primaryButtonBg : RpsBattleTheme.panelLine
      })
      .onClick(() => {
        this.selectComebackRule(rule);
      })
  }

  @Builder
  GodHandRow() {
    Row({ space: 10 }) {
      Text('✦')
        .width(28)
        .height(28)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.enhancementSelection.godHandEnabled ? RpsBattleTheme.primaryButtonText : RpsBattleTheme.muted)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.enhancementSelection.godHandEnabled ?
          RpsBattleTheme.primaryButtonBg : RpsBattleTheme.optionBg)
        .borderRadius(8)
      Column({ space: 2 }) {
        Text('上帝之手')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(RpsBattleTheme.pageInk)
          .maxLines(1)
        Text('战斗中可选推开或吸引，限三次干预')
          .fontSize(10)
          .fontColor(RpsBattleTheme.muted)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(this.enhancementSelection.godHandEnabled ? '开' : '关')
        .width(50)
        .height(40)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.enhancementSelection.godHandEnabled ?
          RpsBattleTheme.primaryButtonText : RpsBattleTheme.pageInk)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.enhancementSelection.godHandEnabled ?
          RpsBattleTheme.primaryButtonBg : RpsBattleTheme.optionBg)
        .borderRadius(8)
        .border({
          width: 1,
          color: this.enhancementSelection.godHandEnabled ?
            RpsBattleTheme.primaryButtonBg : RpsBattleTheme.panelLine
        })
        .onClick(() => {
          this.toggleGodHand();
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  SectionRule() {
    Blank()
      .width('100%')
      .height(1)
      .backgroundColor(RpsBattleTheme.panelLine)
  }

  private subtitleText(): string {
    return this.selectedModeKey === 'classic' ? '为本局增加翻盘或手动干预' : '为本局增加受限的手动干预';
  }

  private comebackLabelFontSize(rule: RpsBattleComebackRuleKey): number {
    return rule === 'tenAgainstOne' ? 10 : 11;
  }
}
