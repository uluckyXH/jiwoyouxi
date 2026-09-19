import { STAR_LOGO, StarMode, starModeTitle } from './StarModel';
import { StarPalette as P } from './StarPalette';
import { StarButton, StarIconButton } from './StarControls';

@Component
export struct StarDialog {
  @Prop dark: boolean = false;
  @Prop mode: string = 'more';
  @Prop roundMode: StarMode = 'easy';
  @Prop pendingMode: StarMode = 'easy';
  @Prop stage: number = 1;
  @Prop score: number = 0;
  @Prop total: number = 0;
  @Prop target: number = 1000;
  @Prop remaining: number = 80;
  @Prop bonus: number = 0;
  @Prop undoAvailable: boolean = false;
  @Prop canContinue: boolean = true;
  @Prop saving: boolean = false;
  @Prop saveFailed: boolean = false;
  @Prop panelWidth: number = 350;
  @Prop panelHeight: number = 650;
  action: (name: string) => void = () => {};

  private title(): string {
    if (this.mode === 'help') return '把相邻的小欢喜，收在一起';
    if (this.mode === 'loading') return '摆一盘新的星星';
    if (this.mode === 'loadError') return '暂时读不到进度';
    if (this.mode === 'corrupt') return '这份进度暂时打不开';
    if (this.mode === 'restart') return '开启一段新旅程';
    if (this.mode === 'changeMode') return '换到' + starModeTitle(this.pendingMode);
    if (this.mode === 'stageEnd') return '第 ' + this.stage + ' 关，收获啦';
    if (this.mode === 'failed') return '这一盘，暂时走到这里';
    if (this.mode === 'finished') return '收好这一路的小星星';
    if (this.mode === 'exit') return '下次，再来小院坐坐';
    return '星星小院';
  }
  private detail(): string {
    if (this.mode === 'loading') return '准备好就能继续，不会消耗机会。';
    if (this.mode === 'loadError' || this.mode === 'corrupt') return '原存档仍然保留，可以重试读取或先返回大厅。';
    if (this.mode === 'help') return '不赶时间，想好再点。一次收得越多，分数越高。';
    if (this.mode === 'restart' || this.mode === 'changeMode') return '将从第 1 关重新开始，当前旅程会结束；最佳成绩和成就保留。';
    if (this.mode === 'stageEnd') return this.canContinue ? '目标已经达成！还能继续消除，也可以带着得分去下一关。' : '这盘已经收好了，带着得分去下一关吧。';
    if (this.mode === 'failed') return '没有相邻同色了，本关得分还差 ' + Math.max(0, this.target - this.score - this.bonus) + ' 分。';
    if (this.mode === 'finished') return '没有时间限制，下一段旅程慢慢来。';
    if (this.mode === 'exit') return '保存当前棋盘和关卡，下次打开接着玩。';
    return '四色轻松一点，五色多想一步。\n两种模式分别记录最佳旅程。';
  }
  @Builder
  Action(label: string, icon: string, name: string, primary: boolean = false) {
    StarButton({ dark: this.dark, label: label, icon: icon, primary: primary,
      active: !this.saving, action: () => this.action(name) })
  }
  @Builder
  GuideStep(index: number, title: string, detail: string) {
    Row({ space: 12 }) {
      Image($rawfile(P.scene('guide' + index, this.dark))).width(84).height(58).accessibilityLevel('no')
      Column({ space: 4 }) {
        Text(title).fontSize(14).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
        Text(detail).fontSize(12).lineHeight(19).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }.width('100%').alignItems(VerticalAlign.Center)
  }
  @Builder
  Guide() {
    this.GuideStep(0, '相邻同色，一起收走', '点一下上下左右连着的同色彩块，至少 2 块。斜着相碰不算；按住可以预览数量和得分。')
    this.GuideStep(1, '先下落，再靠左', '消除后，上方彩块落下来，空列向左收拢。本关不会补入新块，也不会自动连消。')
    this.GuideStep(2, '凑大组，分数更高', '消除得分 = 块数 × 块数 × 5。2 块 20 分、4 块 80 分、8 块 320 分。')
    Column({ space: 9 }) {
      Text('怎样继续下一关').fontSize(14).fontWeight(FontWeight.Medium).fontColor(P.accent(this.dark))
      Text('每关从 80 块开始。达到本关目标即可过关，也可以继续消除多拿分。没有可消除的组合时，先结算余块奖励，再判断是否达标。').fontSize(12).lineHeight(20).fontColor(P.ink(this.dark))
      Text('余块越少奖励越多：清空 +500，剩 5 块 +375，剩 10 块及以上不加分。奖励每关只结算一次。').fontSize(12).lineHeight(20).fontColor(P.muted(this.dark))
      Text('目标会逐渐提高，后期保持稳定。没有倒计时，也没有预设的最后一关。').fontSize(12).lineHeight(20).fontColor(P.muted(this.dark))
    }.width('100%').alignItems(HorizontalAlign.Start).padding(16).backgroundColor(P.soft(this.dark)).borderRadius(20)
    Text('每关可撤销 1 次，未达标时也能用。新关卡从第一步起一直跟随「过关路线」提示，就能达到目标；提示有时会先收小组，为后面的大组让路。').fontSize(12).lineHeight(20).fontColor(P.muted(this.dark))
    Text('自行改走后，提示会重新寻找路线。如果显示「参考走法」，表示暂未找到达标路线，可以考虑撤销。提示和撤销都不会重排棋盘或降低目标。').fontSize(12).lineHeight(20).fontColor(P.muted(this.dark))
    Text('小成就：首次消除、单次消除 8 块、累计消除 100 块。两种模式都算，使用提示和撤销也没关系。').fontSize(12).lineHeight(20).fontColor(P.muted(this.dark))
    this.Action('明白了，去收星星', 'check', 'close', true)
  }
  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor('rgba(16, 25, 15, 0.48)')
      Scroll() {
        Column({ space: 14 }) {
          if (this.mode !== 'loading') {
            Row() {
              Text('星 星 小 院').fontSize(11).fontColor(P.muted(this.dark)).layoutWeight(1)
              StarIconButton({ dark: this.dark, icon: 'close', label: '关闭', active: !this.saving,
                action: () => this.action(['corrupt', 'loadError'].includes(this.mode) ? 'leaveUntouched' : 'close') })
            }.width('100%')
          }
          Image($rawfile(STAR_LOGO)).width(70).height(70).accessibilityLevel('no')
          Text(this.title()).fontSize(22).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).textAlign(TextAlign.Center)
          Text(this.detail()).fontSize(13).lineHeight(21).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
          if (this.mode === 'help') {
            this.Guide()
          } else if (this.mode === 'loadError' || this.mode === 'corrupt') {
            this.Action('重试读取', 'restart', 'retryLoad', true)
            this.Action('返回大厅', 'back', 'leaveUntouched')
          } else if (this.mode !== 'loading') {
            if (this.saveFailed) {
              Text('进度或成就还没存好，请重试。').fontSize(12).fontColor(P.danger(this.dark))
              this.Action('重试保存', 'restart', 'retrySave')
            }
            if (['stageEnd', 'failed', 'finished'].includes(this.mode)) {
              Column({ space: 7 }) {
                Text('' + this.total).fontSize(34).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark))
                Text('旅程总分 · 第 ' + this.stage + ' 关').fontSize(11).fontColor(P.muted(this.dark))
                Divider().color(P.line(this.dark)).margin({ top: 4, bottom: 4 })
                Text('本关消除 ' + this.score + '   /   目标 ' + this.target).fontSize(12).fontColor(P.ink(this.dark))
                Text('剩余 ' + this.remaining + ' 块 · 余块奖励 +' + this.bonus).fontSize(12).fontColor(P.muted(this.dark))
              }.width('100%').padding(17).backgroundColor(P.soft(this.dark)).borderRadius(22)
              if (this.mode === 'stageEnd') this.Action('带着收获，去下一关', 'next', 'next', true)
              if (this.mode === 'failed') this.Action('收好这一局', 'check', 'finish', true)
              if (this.mode !== 'finished' && this.undoAvailable) this.Action('撤销上一步 · 本关 1 次', 'undo', 'undo')
              if (this.mode === 'finished') this.Action('再来一段旅程', 'restart', 'restart', true)
              if (this.mode === 'stageEnd') this.Action(this.canContinue ? '继续消除，多拿一点分' : '看看棋盘', 'back', 'close')
              this.Action('保存并返回大厅', 'back', 'leave')
            } else if (this.mode === 'restart' || this.mode === 'changeMode') {
              this.Action('开始新旅程', 'spark', 'confirm', true)
              this.Action('保留当前进度', 'back', 'close')
            } else if (this.mode === 'exit') {
              this.Action(this.saving ? '正在保存…' : '保存并返回大厅', 'back', 'leave', true)
              this.Action('再玩一会', 'next', 'close')
            } else {
              this.Action('继续这一盘', 'next', 'close', true)
              Row({ space: 8 }) {
                StarButton({ dark: this.dark, label: '轻松 · 四色', primary: this.roundMode === 'easy',
                  active: !this.saving, action: () => this.action('easy') }).layoutWeight(1)
                StarButton({ dark: this.dark, label: '经典 · 五色', primary: this.roundMode === 'classic',
                  active: !this.saving, action: () => this.action('classic') }).layoutWeight(1)
              }.width('100%')
              this.Action('操作与计分', 'help', 'help')
              this.Action('重新开始', 'restart', 'restart')
              this.Action('保存并返回大厅', 'back', 'leave')
            }
          }
        }.width('100%').padding(20)
      }.width(this.panelWidth).constraintSize({ maxHeight: this.panelHeight }).scrollBar(BarState.Auto)
      .backgroundColor(P.paper(this.dark)).border({ width: 1, color: P.line(this.dark), radius: 28 }).borderRadius(28).clip(true)
    }.width('100%').height('100%')
  }
}
