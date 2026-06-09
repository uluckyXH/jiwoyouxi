import { FactionInfo, FACTIONS } from '../model/GameTypes';
import { BattleReportPoint, NativeBattleReport } from '../model/BattleReport';

@Component
export struct ReportPanel {
  @Prop report: NativeBattleReport;
  @Prop factions: FactionInfo[] = FACTIONS;
  @Prop panelWidth: number;
  close: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(this.report.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#17201c')
        Blank()
        Button('关闭')
          .height(34)
          .borderRadius(8)
          .backgroundColor('#17201c')
          .fontColor('#ffffff')
          .onClick(() => {
            this.close();
          })
      }
      .width('100%')

      Scroll() {
        Column({ space: 12 }) {
          this.SectionTitle('战况摘要')
          ForEach(this.report.textLines, (line: string) => {
            Text(line)
              .width('100%')
              .fontSize(13)
              .fontColor('#344039')
              .lineHeight(19)
          }, (line: string) => line)

          this.SectionTitle('MVP')
          ForEach(this.report.mvpLines, (line: string) => {
            Text(line)
              .width('100%')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#17201c')
              .padding(10)
              .borderRadius(8)
              .backgroundColor('rgba(23,32,28,0.06)')
          }, (line: string) => line)

          this.SectionTitle('数量走势')
          ForEach(this.visiblePoints(), (point: BattleReportPoint) => {
            this.PointRow(point)
          }, (point: BattleReportPoint) => `${point.timeSec}-${point.label}-${point.counts[0]}-${point.counts[1]}-${point.counts[2]}`)
        }
        .width('100%')
      }
      .width('100%')
      .height(Math.min(520, this.panelWidth * 1.06))
    }
    .width(Math.min(this.panelWidth - 28, 480))
    .padding(16)
    .borderRadius(10)
    .backgroundColor('rgba(255,255,255,0.97)')
    .border({ width: 1, color: 'rgba(23,32,28,0.12)' })
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .width('100%')
      .fontSize(15)
      .fontWeight(FontWeight.Bold)
      .fontColor('#17201c')
  }

  @Builder
  PointRow(point: BattleReportPoint) {
    Column({ space: 6 }) {
      Row() {
        Text(`${point.timeSec.toFixed(1)}s`)
          .fontSize(11)
          .fontColor('#637067')
        Blank()
        Text(point.label.length > 0 ? point.label : `${point.counts[0]}/${point.counts[1]}/${point.counts[2]}`)
          .fontSize(11)
          .fontColor('#637067')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      ForEach([0, 1, 2], (type: number) => {
        Row({ space: 6 }) {
          Text(this.factions[type].emoji)
            .fontSize(14)
          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(7)
              .borderRadius(4)
              .backgroundColor('rgba(23,32,28,0.08)')
            Row()
              .width(this.barWidth(point.counts[type]))
              .height(7)
              .borderRadius(4)
              .backgroundColor(this.factions[type].color)
          }
          .layoutWeight(1)
          .height(7)
          Text(`${point.counts[type]}`)
            .width(24)
            .fontSize(11)
            .fontColor('#17201c')
            .textAlign(TextAlign.End)
        }
        .width('100%')
      }, (type: number) => `${type}`)
    }
    .width('100%')
    .padding(10)
    .borderRadius(8)
    .backgroundColor('rgba(248,250,247,0.92)')
  }

  private visiblePoints(): BattleReportPoint[] {
    const points = this.report.points;
    const start = Math.max(0, points.length - 9);
    return points.slice(start);
  }

  private maxPointCount(): number {
    let max = 1;
    for (let i = 0; i < this.report.points.length; i += 1) {
      const point = this.report.points[i];
      max = Math.max(max, point.counts[0], point.counts[1], point.counts[2]);
    }
    return max;
  }

  private barWidth(count: number): string {
    return `${Math.max(4, count / this.maxPointCount() * 100)}%`;
  }
}
