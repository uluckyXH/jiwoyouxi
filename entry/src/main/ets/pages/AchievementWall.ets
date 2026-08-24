import { MotionPressable } from '../components/MotionPressable';
import { AchievementTheme } from '../design/AchievementTheme';
import { CoopMotion } from '../design/CoopMotion';
import { CoopTheme } from '../design/CoopTheme';
import {
  achievementGroupsForSnapshot,
  achievementSummaryForSnapshot,
  achievementViewItemFor
} from '../shell/AchievementEngine';
import {
  AchievementFilter,
  AchievementGroupView,
  AchievementViewItem
} from '../shell/AchievementModule';
import { ACHIEVEMENT_DEFINITIONS } from '../shell/AchievementRegistry';
import { CoopAppSnapshot } from '../shell/GameModule';
import { gameLogoPath, moduleById } from '../shell/GameRegistry';

@Component
export struct AchievementWall {
  @Prop snapshot: CoopAppSnapshot;
  @Prop isDarkMode: boolean = false;
  @State private activeFilter: AchievementFilter = 'all';
  @State private selectedAchievementId: string = '';
  @State private isDetailSheetPresented: boolean = false;

  build() {
    Column({ space: 16 }) {
      this.WallHeader()
      this.FilterBar()
      if (this.visibleGroups().length === 0) {
        this.FilterEmptyPanel()
      } else {
        ForEach(this.visibleGroups(), (group: AchievementGroupView) => {
          this.AchievementGroup(group)
        }, (group: AchievementGroupView) => group.definition.id)
      }
    }
    .width('100%')
    .bindSheet($$this.isDetailSheetPresented, this.AchievementDetailSheet(), {
      height: 360,
      dragBar: true,
      showClose: false
    })
  }

  @Builder
  WallHeader() {
    Column({ space: 9 }) {
      Row({ space: 12 }) {
        Row({ space: 9 }) {
          Stack({ alignContent: Alignment.Center }) {
            Text('♕')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.goldColor())
          }
          .width(32)
          .height(32)
          .backgroundColor(this.groupSurfaceColor())
          .borderRadius(16)
          .border({ width: 1, color: this.lineColor() })

          Column({ space: 2 }) {
            Text('成就墙')
              .fontSize(AchievementTheme.pageTitleSize)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.inkColor())
            Text('收集你在鸡窝里的小高光')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.mutedColor())
          }
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
    .height(AchievementTheme.filterHeight)
    .padding(4)
    .borderRadius(AchievementTheme.filterHeight / 2)
    .backgroundColor(this.filterTrackColor())
    .border({ width: 1, color: this.lineColor() })
  }

  @Builder
  FilterOption(filter: AchievementFilter, label: string) {
    Text(label)
      .layoutWeight(1)
      .height('100%')
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.filterTextColor(filter))
      .textAlign(TextAlign.Center)
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
      Text(this.groupProgressText(group.definition.id))
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
        Text(group.definition.placeholderSymbol)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.goldColor())
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
    MotionPressable({
      pressScale: 0.99,
      pressedOpacity: 0.97,
      action: () => {
        this.openAchievementDetail(item.definition.id);
      }
    }) {
      Row({ space: 12 }) {
        this.AchievementBadge(item)
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
      .height(AchievementTheme.rowHeight)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.rowSurfaceColor(item))
      .border({ width: 1, color: this.rowLineColor(item) })
      .borderRadius(AchievementTheme.rowRadius)
    }
  }

  @Builder
  AchievementBadge(item: AchievementViewItem) {
    Stack({ alignContent: Alignment.Center }) {
      Text(item.definition.placeholderSymbol)
        .fontSize(23)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.badgeSymbolColor(item))
      if (item.status === 'unlocked') {
        Text('✓')
          .width(17)
          .height(17)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.unlockCheckColor())
          .textAlign(TextAlign.Center)
          .backgroundColor(this.goldColor())
          .borderRadius(9)
          .position({ x: 33, y: 33 })
      }
    }
    .width(AchievementTheme.badgeSize)
    .height(AchievementTheme.badgeSize)
    .backgroundColor(this.badgeSurfaceColor(item))
    .border({ width: 1, color: this.badgeLineColor(item) })
    .borderRadius(16)
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
      Text(this.activeFilter === 'unlocked' ? '✦' : '◌')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.goldColor())
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
    if (this.selectedAchievementId.length > 0) {
      this.AchievementDetailContent(this.detailItem())
    }
  }

  @Builder
  AchievementDetailContent(item: AchievementViewItem) {
    Column({ space: 12 }) {
      this.DetailBadge(item)
      Text(item.definition.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.inkColor())
        .textAlign(TextAlign.Center)
      Text(item.definition.detail)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.mutedColor())
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Row()
        .width('100%')
        .height(1)
        .backgroundColor(this.lineColor())
      this.DetailInfoRow('当前状态', this.statusText(item))
      this.DetailInfoRow('来源游戏', this.detailGameTitle(item))
      if (item.status === 'unlocked') {
        this.DetailInfoRow('解锁记录', this.unlockedRecordText(item))
      } else if (this.hasNumericProgress(item)) {
        this.DetailInfoRow('当前进度', `${item.current} / ${item.target}`)
      }
      Text('知道了')
        .width(132)
        .height(40)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.unlockCheckColor())
        .textAlign(TextAlign.Center)
        .backgroundColor(this.goldColor())
        .borderRadius(20)
        .margin({ top: 4 })
        .onClick(() => {
          this.isDetailSheetPresented = false;
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24, top: 16, bottom: 22 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.detailSurfaceColor())
  }

  @Builder
  DetailBadge(item: AchievementViewItem) {
    Stack({ alignContent: Alignment.Center }) {
      Text(item.definition.placeholderSymbol)
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.badgeSymbolColor(item))
      if (item.status === 'unlocked') {
        Text('✓')
          .width(24)
          .height(24)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.unlockCheckColor())
          .textAlign(TextAlign.Center)
          .backgroundColor(this.goldColor())
          .borderRadius(12)
          .position({ x: 66, y: 66 })
      }
    }
    .width(AchievementTheme.detailBadgeSize)
    .height(AchievementTheme.detailBadgeSize)
    .backgroundColor(this.badgeSurfaceColor(item))
    .border({ width: 1, color: this.badgeLineColor(item) })
    .borderRadius(28)
  }

  @Builder
  DetailInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.mutedColor())
      Blank()
      Text(value)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.inkColor())
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  private visibleGroups(): AchievementGroupView[] {
    return achievementGroupsForSnapshot(this.snapshot, this.activeFilter);
  }

  private summary() {
    return achievementSummaryForSnapshot(this.snapshot);
  }

  private detailItem(): AchievementViewItem {
    const found = achievementViewItemFor(this.snapshot, this.selectedAchievementId);
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

  private groupProgressText(groupId: string): string {
    const group = achievementGroupsForSnapshot(this.snapshot, 'all')
      .find((item: AchievementGroupView) => item.definition.id === groupId);
    if (group === undefined) {
      return '0 / 0';
    }
    let unlocked = 0;
    group.items.forEach((item: AchievementViewItem) => {
      if (item.status === 'unlocked') {
        unlocked += 1;
      }
    });
    return `${unlocked} / ${group.items.length}`;
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
    if (item.status === 'unlocked') {
      return '已解锁';
    }
    return item.status === 'inProgress' ? '进行中' : '未达成';
  }

  private statusDetail(item: AchievementViewItem): string {
    if (item.status === 'unlocked') {
      return item.isLegacyMigrated ? '历史补发' : this.shortDate(item.unlockedAt);
    }
    return this.hasNumericProgress(item) ? `${item.current} / ${item.target}` : '等待达成';
  }

  private unlockedRecordText(item: AchievementViewItem): string {
    if (item.isLegacyMigrated) {
      return '已由历史记录补发';
    }
    return this.fullDate(item.unlockedAt);
  }

  private detailGameTitle(item: AchievementViewItem): string {
    if (item.definition.gameId === 'global') {
      return '鸡窝游戏合集';
    }
    return moduleById(item.definition.gameId).title;
  }

  private shortDate(timestamp: number): string {
    if (timestamp <= 0) {
      return '';
    }
    const date = new Date(timestamp);
    return `${this.twoDigits(date.getMonth() + 1)}-${this.twoDigits(date.getDate())}`;
  }

  private fullDate(timestamp: number): string {
    if (timestamp <= 0) {
      return '已解锁';
    }
    const date = new Date(timestamp);
    return `${date.getFullYear()}-${this.twoDigits(date.getMonth() + 1)}-${this.twoDigits(date.getDate())}`;
  }

  private twoDigits(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private emptyTitle(): string {
    return this.activeFilter === 'unlocked' ? '还没有已解锁成就' : '这一页的勋章都已收进册子啦';
  }

  private emptyDescription(): string {
    if (this.activeFilter === 'unlocked') {
      return '再完成一局，把第一枚勋章带回鸡窝。';
    }
    return '换到“全部”回顾已收集的小高光。';
  }

  private selectFilter(filter: AchievementFilter): void {
    if (this.activeFilter === filter) {
      return;
    }
    this.getUIContext().animateTo({
      duration: CoopMotion.microDuration,
      curve: Curve.EaseOut
    }, () => {
      this.activeFilter = filter;
    });
  }

  private openAchievementDetail(achievementId: string): void {
    this.selectedAchievementId = achievementId;
    this.isDetailSheetPresented = true;
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

  private unlockCheckColor(): string {
    return this.isDarkMode ? '#21160A' : '#FFFFFF';
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
    if (this.activeFilter !== filter) {
      return 'rgba(255,255,255,0.00)';
    }
    return this.isDarkMode ? '#493920' : '#FFF9EE';
  }

  private filterTextColor(filter: AchievementFilter): string {
    return this.activeFilter === filter ? this.goldColor() : this.mutedColor();
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

  private badgeSurfaceColor(item: AchievementViewItem): string {
    if (item.status === 'unlocked') {
      return this.isDarkMode ? AchievementTheme.goldSoftDark : AchievementTheme.goldSoftLight;
    }
    return this.isDarkMode ? '#302A23' : '#F8EFE2';
  }

  private badgeLineColor(item: AchievementViewItem): string {
    return item.status === 'unlocked' ? this.accentColor(item) : this.lineColor();
  }

  private badgeSymbolColor(item: AchievementViewItem): string {
    return item.status === 'unlocked' ? this.accentColor(item) : this.lockedSymbolColor();
  }

  private lockedSymbolColor(): string {
    return this.isDarkMode ? AchievementTheme.lockedSymbolDark : AchievementTheme.lockedSymbolLight;
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
