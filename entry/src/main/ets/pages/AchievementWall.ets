import { AchievementBadge } from '../components/AchievementBadge';
import { AchievementDetail } from './AchievementDetail';
import { HubSession } from '../design/HubSession';
import { HubScroll } from './HubScroll';
import { AchievementTheme } from '../design/AchievementTheme';
import { achievementGroupCountLabel, achievementGroupRenderKey } from '../design/AchievementPresentation';
import { CoopMotion } from '../design/CoopMotion';
import { CoopTheme } from '../design/CoopTheme';
import {
  achievementGroupsForState,
  achievementSummaryForState,
  achievementViewItemForState
} from '../shell/AchievementEngine';
import {
  AchievementFilter,
  AchievementGroupView,
  AchievementState,
  AchievementViewItem
} from '../shell/AchievementModule';
import { ACHIEVEMENT_DEFINITIONS } from '../shell/AchievementRegistry';
import { gameLogoPath, moduleById } from '../shell/GameRegistry';

@Component
export struct AchievementWall {
  @Prop achievementState: AchievementState;
  @Prop isDarkMode: boolean = false;
  @ObjectLink @Watch('syncDetailPresentation') session: HubSession;
  @Prop @Watch('syncDetailPresentation') splitDetail: boolean = false;
  @Prop detailWidth: number = 340;
  @State private isDetailSheetPresented: boolean = false;

  aboutToAppear(): void { this.syncDetailPresentation(); }

  build() {
    Column({ space: 16 }) {
      this.WallHeader()
      this.FilterBar()
      Row({ space: 24 }) {
        Column() {
        HubScroll({ session: this.session, slot: 2, resetKey: this.session.achievementFilter }) {
          Column({ space: 20 }) {
            if (this.visibleGroups().length === 0) {
              this.FilterEmptyPanel()
            } else {
              ForEach(this.visibleGroups(), (group: AchievementGroupView) => {
                this.AchievementGroup(group)
              }, (group: AchievementGroupView) => achievementGroupRenderKey(group, this.session.achievementFilter))
            }
          }.width('100%')
        }
        }.layoutWeight(1).height('100%')
        if (this.splitDetail) {
          Column() {
            if (this.session.detailOpen && this.session.selectedAchievementId.length > 0) {
              AchievementDetail({ item: this.detailItem(), achievementState: this.achievementState,
                isDarkMode: this.isDarkMode, embedded: true,
                close: () => { this.session.detailOpen = false; } })
            } else {
              Column({ space: 16 }) {
                Image($rawfile('app/achievements/achievement_wall_logo.svg'))
                  .width(76).height(76).objectFit(ImageFit.Contain).accessibilityLevel('no')
                Text('每一枚，都有故事').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.inkColor())
                Text('选择左侧的成就，\n查看达成条件与收集进度。')
                  .fontSize(13).lineHeight(22).fontColor(this.mutedColor()).textAlign(TextAlign.Center)
              }.width('100%').height('100%').justifyContent(FlexAlign.Center).padding(24)
            }
          }.width(this.detailWidth).height('100%')
          .backgroundColor(this.detailSurfaceColor()).borderRadius(24)
          .border({ width: 1, color: this.lineColor() }).clip(true)
        }
      }.width('100%').layoutWeight(1).alignItems(VerticalAlign.Top)
    }
    .width('100%').height('100%')
    .bindSheet($$this.isDetailSheetPresented, this.AchievementDetailSheet(), {
      height: '85%', dragBar: true, showClose: true,
      onWillDismiss: (action: DismissSheetAction) => {
        this.session.detailOpen = false;
        action.dismiss();
      }
    })
  }

  private syncDetailPresentation(): void {
    this.isDetailSheetPresented = !this.splitDetail && this.session.detailOpen &&
      this.session.selectedAchievementId.length > 0;
  }

  @Builder
  WallHeader() {
    Column({ space: 9 }) {
      Row({ space: 12 }) {
        Row({ space: 9 }) {
          Image($rawfile('app/achievements/achievement_wall_logo.svg'))
            .width(AchievementTheme.wallLogoSize)
            .height(AchievementTheme.wallLogoSize)
            .objectFit(ImageFit.Contain)

          Column({ space: 2 }) {
            Text('成就墙')
              .fontSize(AchievementTheme.pageTitleSize)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.inkColor())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text('收集你在鸡窝里的小高光')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.mutedColor())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        Text(`${this.summary().unlocked} / ${this.summary().total}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.goldColor())
          .padding({ left: 9, right: 9, top: 6, bottom: 6 })
          .backgroundColor(this.groupSurfaceColor())
          .borderRadius(14)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(AchievementTheme.progressHeight)
          .borderRadius(AchievementTheme.progressHeight / 2)
          .backgroundColor(this.progressTrackColor())
        Row()
          .width(`${this.collectionProgressPercent()}%`)
          .height(AchievementTheme.progressHeight)
          .borderRadius(AchievementTheme.progressHeight / 2)
          .backgroundColor(this.goldColor())
      }
      .width('100%')
      .height(AchievementTheme.progressHeight)
    }
    .width('100%')
  }

  @Builder
  FilterBar() {
    Row({ space: 6 }) {
      this.FilterOption('all', '全部')
      this.FilterOption('unlocked', '已解锁')
      this.FilterOption('inProgress', '进行中')
    }
    .width('100%')
    .height(Math.max(44, AchievementTheme.filterHeight))
    .padding(4)
    .borderRadius(AchievementTheme.filterHeight / 2)
    .backgroundColor(this.filterTrackColor())
    .border({ width: 1, color: this.lineColor() })
  }

  @Builder
  FilterOption(filter: AchievementFilter, label: string) {
    Button(label, { type: ButtonType.Normal })
      .padding(0)
      .layoutWeight(1)
      .height('100%')
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.filterTextColor(filter))
      .backgroundColor(this.filterSurfaceColor(filter))
      .borderRadius((AchievementTheme.filterHeight - 8) / 2)
      .onClick(() => {
        this.selectFilter(filter);
      })
  }

  @Builder
  AchievementGroup(group: AchievementGroupView) {
    Column({ space: 8 }) {
      this.GroupHeader(group)
      if (group.definition.id === 'global') {
        Text('跨游戏积累，收集在鸡窝里的每一步')
          .width('100%')
          .fontSize(11)
          .fontColor(this.mutedColor())
          .padding({ left: 2, bottom: 2 })
      }
      ForEach(group.items, (item: AchievementViewItem) => {
        this.AchievementRow(item)
      }, (item: AchievementViewItem) => item.definition.id)
    }
    .width('100%')
  }

  @Builder
  GroupHeader(group: AchievementGroupView) {
    Row({ space: 8 }) {
      this.GroupIdentity(group)
      Text(group.definition.title)
        .layoutWeight(1)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.inkColor())
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(achievementGroupCountLabel(group, this.session.achievementFilter))
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.mutedColor())
    }
    .width('100%')
    .padding({ left: 2, right: 2 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  GroupIdentity(group: AchievementGroupView) {
    Stack({ alignContent: Alignment.Center }) {
      if (group.definition.gameId === 'global') {
        Image($rawfile('app/ui/collection.svg'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
      } else {
        Image($rawfile(gameLogoPath(group.definition.gameId)))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
      }
    }
    .width(AchievementTheme.groupLogoSize)
    .height(AchievementTheme.groupLogoSize)
    .backgroundColor(this.groupSurfaceColor())
    .borderRadius(AchievementTheme.groupLogoSize / 2)
    .border({ width: 1, color: this.lineColor() })
  }

  @Builder
  AchievementRow(item: AchievementViewItem) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 12 }) {
        AchievementBadge({ item: item, isDarkMode: this.isDarkMode, accentColor: this.accentColor(item) })
        Column({ space: 5 }) {
          Text(item.definition.title)
            .width('100%')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.inkColor())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(item.definition.summary)
            .width('100%')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.mutedColor())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.hasNumericProgress(item) && item.status !== 'unlocked') {
            this.AchievementProgressLine(item)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 3 }) {
          Text(this.statusText(item))
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.statusColor(item))
            .maxLines(1)
          Text(this.statusDetail(item))
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.mutedColor())
            .maxLines(1)
        }
        .width(56)
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .constraintSize({ minHeight: AchievementTheme.rowHeight })
      .padding({ left: 12, right: 12, top: 14, bottom: 14 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.rowSurfaceColor(item))
      .border({ width: 1, color: this.session.detailOpen && this.session.selectedAchievementId === item.definition.id
        ? this.goldColor() : this.rowLineColor(item) })
      .borderRadius(AchievementTheme.rowRadius)
    }
    .width('100%').padding(0).borderRadius(AchievementTheme.rowRadius)
    .backgroundColor(Color.Transparent)
    .onClick(() => this.openAchievementDetail(item.definition.id))
  }

  @Builder
  AchievementProgressLine(item: AchievementViewItem) {
    Row({ space: 6 }) {
      Text(`${item.current} / ${item.target}`)
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.progressLabelColor())
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(4)
          .borderRadius(2)
          .backgroundColor(this.progressTrackColor())
        Row()
          .width(`${this.itemProgressPercent(item)}%`)
          .height(4)
          .borderRadius(2)
          .backgroundColor(this.accentColor(item))
      }
      .layoutWeight(1)
      .height(4)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  FilterEmptyPanel() {
    Column({ space: 8 }) {
      Image($rawfile(this.session.achievementFilter === 'unlocked' ? 'app/ui/achievements_empty.svg' : 'app/ui/progress_empty.svg'))
        .width(64)
        .height(64)
        .objectFit(ImageFit.Contain)
        .accessibilityLevel('no')
      Text(this.emptyTitle())
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.inkColor())
      Text(this.emptyDescription())
        .fontSize(12)
        .fontColor(this.mutedColor())
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 28, bottom: 28 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.emptySurfaceColor())
    .border({ width: 1, color: this.lineColor() })
    .borderRadius(22)
  }

  @Builder
  AchievementDetailSheet() {
    if (this.session.selectedAchievementId.length > 0) {
      AchievementDetail({
        item: this.detailItem(),
        achievementState: this.achievementState,
        isDarkMode: this.isDarkMode,
        close: () => { this.session.detailOpen = false; }
      })
    }
  }

  private visibleGroups(): AchievementGroupView[] {
    return achievementGroupsForState(this.achievementState, this.session.achievementFilter);
  }

  private summary() {
    return achievementSummaryForState(this.achievementState);
  }

  private detailItem(): AchievementViewItem {
    const found = achievementViewItemForState(this.achievementState, this.session.selectedAchievementId);
    if (found !== undefined) {
      return found;
    }
    return {
      definition: ACHIEVEMENT_DEFINITIONS[0],
      current: 0,
      target: 0,
      unlockedAt: 0,
      isLegacyMigrated: false,
      status: 'locked'
    };
  }

  private collectionProgressPercent(): number {
    const summary = this.summary();
    if (summary.total <= 0) {
      return 0;
    }
    return Math.max(0, Math.min(100, Math.round(summary.unlocked * 100 / summary.total)));
  }

  private itemProgressPercent(item: AchievementViewItem): number {
    if (item.target <= 0) {
      return 0;
    }
    return Math.max(0, Math.min(100, Math.round(item.current * 100 / item.target)));
  }

  private hasNumericProgress(item: AchievementViewItem): boolean {
    return item.target > 0;
  }

  private statusText(item: AchievementViewItem): string {
    if (!item.definition.enabled) {
      return '待开放';
    }
    if (item.status === 'unlocked') {
      return '已解锁';
    }
    return item.status === 'inProgress' ? '进行中' : '未达成';
  }

  private statusDetail(item: AchievementViewItem): string {
    if (!item.definition.enabled) {
      return '待校准';
    }
    if (item.status === 'unlocked') {
      return this.shortDate(item.unlockedAt);
    }
    return this.hasNumericProgress(item) ? `${item.current} / ${item.target}` : '等待达成';
  }

  private shortDate(timestamp: number): string {
    if (timestamp <= 0) {
      return '';
    }
    const date = new Date(timestamp);
    return `${this.twoDigits(date.getMonth() + 1)}-${this.twoDigits(date.getDate())}`;
  }

  private twoDigits(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private emptyTitle(): string {
    if (this.session.achievementFilter === 'unlocked') {
      return '还没有已解锁成就';
    }
    if (this.session.achievementFilter === 'inProgress') {
      return '还没有进行中的成就';
    }
    return '暂时没有可展示成就';
  }

  private emptyDescription(): string {
    if (this.session.achievementFilter === 'unlocked') {
      return '完成一局游戏，把第一枚勋章带回鸡窝。';
    }
    if (this.session.achievementFilter === 'inProgress') {
      return '首次获得可累计的进度后，它会显示在这里。';
    }
    return '稍后再试。';
  }

  private selectFilter(filter: AchievementFilter): void {
    if (this.session.achievementFilter === filter) {
      return;
    }
    this.getUIContext().animateTo({
      duration: CoopMotion.microDuration,
      curve: Curve.EaseOut
    }, () => {
      this.session.achievementFilter = filter;
      this.session.detailOpen = false;
    });
  }

  private openAchievementDetail(achievementId: string): void {
    this.session.selectedAchievementId = achievementId;
    this.session.detailOpen = true;
  }

  private accentColor(item: AchievementViewItem): string {
    if (item.definition.gameId === 'global') {
      return this.goldColor();
    }
    return moduleById(item.definition.gameId).accent;
  }

  private goldColor(): string {
    return this.isDarkMode ? AchievementTheme.goldDark : AchievementTheme.goldLight;
  }

  private inkColor(): string {
    return this.isDarkMode ? '#FFF2DF' : CoopTheme.ink;
  }

  private mutedColor(): string {
    return this.isDarkMode ? '#C8B7A2' : CoopTheme.muted;
  }

  private lineColor(): string {
    return this.isDarkMode ? 'rgba(255,236,205,0.14)' : 'rgba(132,91,45,0.12)';
  }

  private groupSurfaceColor(): string {
    return this.isDarkMode ? AchievementTheme.groupSurfaceDark : AchievementTheme.groupSurfaceLight;
  }

  private progressTrackColor(): string {
    return this.isDarkMode ? AchievementTheme.progressTrackDark : AchievementTheme.progressTrackLight;
  }

  private filterTrackColor(): string {
    return this.isDarkMode ? '#28231E' : '#FFF1DB';
  }

  private filterSurfaceColor(filter: AchievementFilter): string {
    if (this.session.achievementFilter !== filter) {
      return 'rgba(255,255,255,0.00)';
    }
    return this.isDarkMode ? '#493920' : '#FFF9EE';
  }

  private filterTextColor(filter: AchievementFilter): string {
    return this.session.achievementFilter === filter ? this.goldColor() : this.mutedColor();
  }

  private rowSurfaceColor(item: AchievementViewItem): string {
    if (item.status === 'unlocked') {
      return this.isDarkMode ? '#2A261F' : '#FFFDF7';
    }
    return this.isDarkMode ? '#25221E' : '#FFFBF4';
  }

  private rowLineColor(item: AchievementViewItem): string {
    if (item.status === 'unlocked') {
      return this.isDarkMode ? 'rgba(255,196,111,0.28)' : 'rgba(244,166,42,0.30)';
    }
    return this.lineColor();
  }

  private statusColor(item: AchievementViewItem): string {
    return item.status === 'unlocked' ? this.goldColor() : this.mutedColor();
  }

  private progressLabelColor(): string {
    return this.isDarkMode ? '#E7C99F' : '#8B6D52';
  }

  private emptySurfaceColor(): string {
    return this.isDarkMode ? '#25221E' : '#FFF9EE';
  }

  private detailSurfaceColor(): string {
    return this.isDarkMode ? AchievementTheme.detailSurfaceDark : AchievementTheme.detailSurfaceLight;
  }

}
