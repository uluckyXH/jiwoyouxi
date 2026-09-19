import { TEN_DIRECTION_ICONS, TEN_DIRECTIONS } from './TenModel';
import { TenPalette as P } from './TenPalette';

@Component
export struct TenGuide {
  @Prop dark: boolean = false;
  @Builder
  MiniBoard(values: number[], before: boolean) {
    Column({ space: 3 }) {
      ForEach([0, 1, 2], (row: number) => {
        Row({ space: 3 }) {
          ForEach([0, 1, 2], (col: number) => {
            Text(values[row * 3 + col] === 0 ? '' : '' + values[row * 3 + col])
              .fontSize(14).fontWeight(FontWeight.Medium).textAlign(TextAlign.Center)
              .fontColor(before && row === 1 && col < 2 ? P.onAccent(this.dark) : P.ink(this.dark))
              .width(27).height(27).borderRadius(7)
              .backgroundColor(before && row === 1 && col < 2 ? P.accent(this.dark) : P.soft(this.dark))
          })
        }
      })
    }.accessibilityLevel('no-hide-descendants')
  }
  @Builder
  Rule(icon: string, title: string, detail: string) {
    Row({ space: 12 }) {
      Image($rawfile(P.icon(icon, this.dark, 'accent'))).width(22).height(22).accessibilityLevel('no')
      Column({ space: 5 }) {
        Text(title).fontSize(15).fontWeight(FontWeight.Medium).fontColor(P.ink(this.dark))
        Text(detail).fontSize(12).lineHeight(21).fontColor(P.muted(this.dark))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }.width('100%').alignItems(VerticalAlign.Top)
  }
  build() {
    Column({ space: 20 }) {
      Row({ space: 8 }) {
        ForEach(['2', '+', '3', '+', '5', '=', '10'], (value: string, i: number) => {
          Text(value).fontSize(i === 6 ? 26 : 22).fontWeight(FontWeight.Medium)
            .fontColor(P.accent(this.dark)).width(i % 2 === 0 ? 34 : 12).textAlign(TextAlign.Center)
        }, (_value: string, i: number): string => '' + i)
      }.width('100%').justifyContent(FlexAlign.Center).height(66).backgroundColor(P.soft(this.dark)).borderRadius(20)
      this.Rule('check', '沿着小路，刚好凑十', '连接上下左右相邻的数字，总和等于 10 就能收下。可以转弯；不能斜连、跨空格、重复经过同一格，也不能超过 10。')
      this.Rule('cards', '凑满就收，干脆一点', '拖过相邻数字或逐个点选，总和达到 10 就自动收下，不用再点按钮。还没凑满时，点末格可退一格，点前面的已选格可退回那里；小叉取消整条连线。收下后，抬手再开始下一组。')
      Column({ space: 10 }) {
        this.Rule('wind', '每收一次，风向转一格', '先取走这一组，其余数字只向当前箭头方向靠拢，顺序不变。下一步风向也会提前显示，收之前想想它们会走到哪里。')
        Row({ space: 10 }) {
          ForEach(TEN_DIRECTION_ICONS, (icon: string, i: number) => {
            Column({ space: 3 }) {
              Image($rawfile(P.icon(icon, this.dark, 'accent'))).width(24).height(24).accessibilityLevel('no')
              Text(TEN_DIRECTIONS[i]).fontSize(11).fontColor(P.ink(this.dark))
            }.layoutWeight(1)
          })
        }.width('100%').padding(12).backgroundColor(P.soft(this.dark)).borderRadius(16)
        Text('下 → 左 → 上 → 右，循环转向；有些棋盘从其他方向开始。')
          .fontSize(11).lineHeight(18).fontColor(P.muted(this.dark))
        Row({ space: 14 }) {
          Column({ space: 8 }) {
            this.MiniBoard([1, 3, 0, 2, 8, 0, 4, 5, 7], true)
            Text('收下 2 + 8').fontSize(11).fontColor(P.muted(this.dark))
          }
          Image($rawfile(P.icon('next', this.dark, 'accent'))).width(20).height(20).accessibilityLevel('no')
          Column({ space: 8 }) {
            this.MiniBoard([0, 0, 0, 1, 3, 0, 4, 5, 7], false)
            Text('向下靠拢').fontSize(11).fontColor(P.muted(this.dark))
          }
        }.width('100%').justifyContent(FlexAlign.Center).padding({ top: 6 })
          .accessibilityText('示例：取走中间相邻的 2 和 8，上方的 1 和 3 向下补到空位，底行保持不变。')
      }
      this.Rule('flower', '收空小院，才算过关', '这一盘不会补新数字。第 1 关只需收两组；第 2 关起是 6×6 棋盘，要把 12 组全部收空。别急着收眼前的十，留意最后剩下的数字。')
      this.Rule('undo', '卡住了，也可以换条路', '没有倒计时和生命限制。撤销、重来和「看一步」都免费。提示用虚线标出已验证的路线，照着点满 10 就自动收下；需要回退时会先说明撤回几步，由你决定。')
      this.Rule('trophy', '三枚容易上手的小勋章', '收下第一组、完成第一关、累计收下 12 组，各获得一枚成就。提示和撤销不影响解锁，同一盘回退后重走的进度只计一次。')
      this.Rule('pause', '折起来，进度也留在这里', '返回大厅自动保存。折叠、展开或旋转屏幕只改变布局，不重排数字。清空后点下一关，继续新的小院。')
      Text('每轮有 256 盘挑战，包含不同朝向；走完后进入下一轮，可再试着少用提示完成。')
        .fontSize(11).lineHeight(19).fontColor(P.muted(this.dark))
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
}
