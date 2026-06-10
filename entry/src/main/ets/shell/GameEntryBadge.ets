import { CoopMotion } from '../design/CoopMotion';
import { CoopTheme } from '../design/CoopTheme';
import { GameModule } from './GameModule';
import { moduleById } from './GameRegistry';

@Component
export struct GameEntryBadge {
  @Prop gameId: string = 'rps';
  @Prop badgeVisible: boolean = false;

  build() {
    Column() {
      Row({ space: 9 }) {
        Text(this.icon())
          .width(30)
          .height(30)
          .fontSize(18)
          .fontColor(this.accent())
          .textAlign(TextAlign.Center)
          .backgroundColor('rgba(255,242,214,0.82)')
          .borderRadius(15)
          .border({ width: 1, color: 'rgba(111,73,39,0.10)' })
        Text(this.title())
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(CoopTheme.ink)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .height(42)
      .padding({ left: 8, right: 14 })
      .borderRadius(21)
      .backgroundColor('rgba(255,250,240,0.90)')
      .border({ width: 1, color: 'rgba(255,255,255,0.88)' })
      .shadow({
        radius: 18,
        color: 'rgba(62,40,18,0.16)',
        offsetX: 0,
        offsetY: 8
      })
      .opacity(this.badgeVisible ? 1 : 0)
      .translate({ x: 0, y: this.badgeVisible ? 0 : -CoopMotion.entryBadgeOffsetVp })
      .animation({ duration: CoopMotion.entryBadgeDuration, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
    .padding({ top: 24 })
    .alignItems(HorizontalAlign.Center)
    .hitTestBehavior(HitTestMode.None)
  }

  private module(): GameModule {
    return moduleById(this.gameId);
  }

  private icon(): string {
    return this.module().icon;
  }

  private title(): string {
    return this.module().title;
  }

  private accent(): string {
    return this.module().accent;
  }
}
