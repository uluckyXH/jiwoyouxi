import { TEN_LOGO } from './TenModel';
import { TenPalette as P } from './TenPalette';
import { TenActionButton, TenIconButton } from './TenControls';
import { TenGuide } from './TenGuide';

@Component
export struct TenDialog {
  @Prop dark: boolean = false;
  @Prop mode: string = 'pause';
  @Prop stage: number = 1;
  @Prop collected: number = 0;
  @Prop goal: number = 2;
  @Prop rewind: number = 0;
  @Prop hints: number = 0;
  @Prop undos: number = 0;
  @Prop resumeStage: number = 0;
  @Prop saving: boolean = false;
  @Prop saveFailed: boolean = false;
  @Prop panelWidth: number = 350;
  @Prop panelHeight: number = 700;
  close: () => void = () => {};
  confirm: () => void = () => {};
  restart: () => void = () => {};
  previous: () => void = () => {};
  resume: () => void = () => {};
  help: () => void = () => {};
  leave: () => void = () => {};
  discard: () => void = () => {};
  retry: () => void = () => {};
  retrySave: () => void = () => {};
  private title(): string {
    if (this.mode === 'loading') return '等风把小院摆好';
    if (this.mode === 'intro') return '先从两个数字开始';
    if (this.mode === 'loadError') return '暂时读不到进度';
    if (this.mode === 'corrupt') return '这份进度暂时打不开';
    if (this.mode === 'help') return '凑成十，再借一阵风';
    if (this.mode === 'complete') return this.resumeStage > 0 ? '这盘又收好啦' : this.stage === 1 ? '热身好了，风要变啦' : '小院，收得干干净净';
    if (this.mode === 'previous') return '回到第 ' + (this.stage - 1) + ' 关看看';
    if (this.mode === 'restart') return '再试一次这盘小院';
    if (this.mode === 'hintRewind') return '从熟悉的路口再出发';
    if (this.mode === 'resume') return '数字都还在原处';
    if (this.mode === 'exit') return '把这一阵风留到下次';
    return '坐一会，慢慢想';
  }
  private detail(): string {
    if (this.mode === 'loading') return '正在读取棋盘和小小的收藏';
    if (this.mode === 'intro') return '连过相邻的 2 和 8，或者逐个点选。凑满 10 就会自动收下。';
    if (this.mode === 'loadError') return '可以重试读取，或先返回大厅。';
    if (this.mode === 'corrupt') return '原存档尚未替换。可重试读取，或选择从第 1 关重新开始。';
    if (this.mode === 'help') return '数字相加，风向轮转。一步简单，收空可不简单。';
    if (this.mode === 'complete') return this.resumeStage > 0 ? '回顾不重复累计成就。第 ' + this.resumeStage + ' 关的原棋盘与撤销记录仍在。' :
      this.stage === 1 ? '接下来是 6×6 挑战。没有倒计时，卡住了随时撤销或看一步。' : '这一盘的十二组小欢喜，全部收好。';
    if (this.mode === 'previous') return '从上一关开头回顾。第 ' + (this.resumeStage > 0 ? this.resumeStage : this.stage) +
      ' 关的当前棋盘、风向与撤销记录都会保留，随时可以返回继续。';
    if (this.mode === 'restart') return '回到这关最初的数字与风向。累计进度和成就保留，不会换成另一盘。';
    if (this.mode === 'hintRewind') return '当前走法离开了参考路线，不代表一定无解。看这条已验证的提示，需要撤回 ' + this.rewind + ' 步，再标出下一组。';
    if (this.mode === 'exit') return '保存棋盘、风向和撤销记录，回来接着想。';
    if (this.resumeStage > 0) return '正在回顾第 ' + this.stage + ' 关。原进度停在第 ' + this.resumeStage + ' 关，可以随时返回。';
    return '没有时间限制，小院等你准备好。';
  }
  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(this.dark ? '#DD171E1C' : '#E8FFF4E4')
      Scroll() {
        Column({ space: 16 }) {
          if (!['loading', 'loadError', 'corrupt', 'complete'].includes(this.mode)) {
            Row() {
              Text('凑 十 小 院').fontSize(11).letterSpacing(2).fontColor(P.muted(this.dark)).layoutWeight(1)
              TenIconButton({ dark: this.dark, icon: 'close', label: '关闭弹窗', active: !this.saving, action: this.close })
            }.width('100%')
          }
          Image($rawfile(this.mode === 'help' ? TEN_LOGO : P.scene('mascot', this.dark)))
            .width(100).height(86).objectFit(ImageFit.Contain).accessibilityLevel('no')
          Text(this.title()).fontSize(23).fontWeight(FontWeight.Bold).fontColor(P.ink(this.dark)).textAlign(TextAlign.Center)
          Text(this.detail()).fontSize(13).lineHeight(22).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
          if (this.mode === 'intro') {
            Text('余下数字跟着箭头靠拢，收空整盘就过关。\n没有倒计时，慢慢来。')
              .fontSize(13).lineHeight(23).fontColor(P.muted(this.dark)).textAlign(TextAlign.Center)
            TenActionButton({ dark: this.dark, icon: 'play', label: '从 2 + 8 开始', action: this.close })
            TenActionButton({ dark: this.dark, icon: 'help', label: '先看看完整玩法', primary: false, action: this.help })
          } else if (this.mode === 'help') {
            TenGuide({ dark: this.dark })
            TenActionButton({ dark: this.dark, icon: 'check', label: '明白了，去小院看看', action: this.close })
          } else if (this.mode === 'loadError' || this.mode === 'corrupt') {
            TenActionButton({ dark: this.dark, icon: 'restart', label: '重试读取', action: this.retry })
            if (this.mode === 'corrupt') {
              TenActionButton({ dark: this.dark, icon: 'cards', label: '从第 1 关开始并替换存档', primary: false, action: this.confirm })
            }
            TenActionButton({ dark: this.dark, icon: 'back', label: '返回大厅', primary: false, action: this.discard })
          } else if (this.mode !== 'loading') {
            Row() {
              Text('第 ' + this.stage + ' 关').fontSize(19).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark)).layoutWeight(1)
              Text('已收 ' + this.collected + ' / ' + this.goal + ' 组').fontSize(13).fontColor(P.accent(this.dark))
            }.width('100%').padding(16).backgroundColor(P.soft(this.dark)).borderRadius(19)
            if (this.saveFailed) {
              Text('进度或成就还没存好，请重试保存。').fontSize(12).fontColor(P.danger(this.dark))
              TenActionButton({ dark: this.dark, icon: 'restart', label: '重试保存', primary: false,
                active: !this.saving, action: this.retrySave })
            }
            if (this.mode === 'complete') {
              Text('提示 ' + this.hints + ' 次 · 撤销 ' + this.undos + ' 步')
                .fontSize(11).fontColor(P.muted(this.dark))
              TenActionButton({ dark: this.dark, icon: 'next', label: this.saving ? '正在收好进度…' :
                this.resumeStage > 0 ? (this.stage + 1 >= this.resumeStage ? '回到第 ' + this.resumeStage + ' 关进度' : '回顾下一关') :
                this.stage === 1 ? '挑战第 2 关' : '下一关',
                active: !this.saving && !this.saveFailed, action: this.confirm })
              if (this.stage > 1) {
                TenActionButton({ dark: this.dark, icon: 'back', label: '回顾上一关', primary: false, active: !this.saving, action: this.previous })
              }
              TenActionButton({ dark: this.dark, icon: 'back', label: '保存并返回大厅', primary: false, active: !this.saving, action: this.leave })
            } else if (this.mode === 'restart' || this.mode === 'hintRewind' || this.mode === 'previous') {
              TenActionButton({ dark: this.dark, icon: this.mode === 'restart' ? 'restart' : this.mode === 'previous' ? 'back' : 'hint',
                label: this.mode === 'restart' ? '重新摆好这盘' : this.mode === 'previous' ? '回顾第 ' + (this.stage - 1) + ' 关' :
                  '撤回 ' + this.rewind + ' 步，看提示',
                active: !this.saving, action: this.confirm })
              TenActionButton({ dark: this.dark, icon: 'back', label: '保留当前走法', primary: false, active: !this.saving, action: this.close })
            } else if (this.mode === 'exit') {
              TenActionButton({ dark: this.dark, icon: 'back', label: this.saving ? '正在保存…' : '保存并返回大厅',
                active: !this.saving, action: this.leave })
              TenActionButton({ dark: this.dark, label: '再想一会', primary: false, active: !this.saving, action: this.close })
              if (this.saveFailed) {
                TenActionButton({ dark: this.dark, icon: 'close', label: '不保存，直接返回', primary: false,
                  active: !this.saving, action: this.discard })
              }
            } else {
              TenActionButton({ dark: this.dark, icon: 'play', label: '继续凑十', active: !this.saving, action: this.close })
              TenActionButton({ dark: this.dark, icon: 'help', label: '游玩指南', primary: false, active: !this.saving, action: this.help })
              TenActionButton({ dark: this.dark, icon: 'restart', label: '重试这盘', primary: false, active: !this.saving, action: this.restart })
              if (this.stage > 1) {
                TenActionButton({ dark: this.dark, icon: 'back', label: '回顾上一关', primary: false, active: !this.saving, action: this.previous })
              }
              if (this.resumeStage > 0) {
                TenActionButton({ dark: this.dark, icon: 'next', label: '回到第 ' + this.resumeStage + ' 关进度',
                  primary: false, active: !this.saving, action: this.resume })
              }
              TenActionButton({ dark: this.dark, icon: 'back', label: '保存并返回大厅', primary: false, active: !this.saving, action: this.leave })
            }
          }
        }.width('100%').padding(20)
      }.width(this.panelWidth).constraintSize({ maxHeight: this.panelHeight }).scrollBar(BarState.Off)
        .backgroundColor(P.paper(this.dark)).borderRadius(28).border({ width: 1, color: P.line(this.dark), radius: 28 }).clip(true)
    }.width('100%').height('100%')
  }
}
