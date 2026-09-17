import { AchievementBadge } from '../components/AchievementBadge';
import { AchievementDetail } from './AchievementDetail';
import { MotionPressable } from '../components/MotionPressable';
import { AchievementTheme } from '../design/AchievementTheme';
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
  resetAchievements: () => Promise<boolean> = async (): Promise<boolean> => false;
  @State private activeFilter: AchievementFilter = 'all';
  @State private selectedAchievementId: string = '';
  @State private isDetailSheetPresented: boolean = false;
  @State private isResetSheetPresented: boolean = false;
  @State private isResetting: boolean = false;
  @State private resetFeedback: string = '';
  @State private resetError: string = '';

  build() {
    Column({ space: 16 }) {
      this.WallHeader()
      this.DeveloperTools()
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
      height: this.selectedAchievementId === 'global.play_six_games' ? '80%' : 520,
      dragBar: true,
      showClose: false
    })
  }

  @Builder
  DeveloperTools() {
    Column({ space: 6 }) {
      Row() {
        Text('DEV 工具')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.devHintColor())
        Blank()
        Text('仅清除成就数据')
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.mutedColor())
      }
      .width('100%')

      Text('DEV · 清除本机成就')
        .width('100%')
        .height(42)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.devResetTextColor())
        .textAlign(TextAlign.Center)
        .backgroundColor(this.devResetSurfaceColor())
        .border({ width: 1, color: this.devResetLineColor() })
        .borderRadius(14)
        .onClick(() => {
          if (!this.isResetting) {
            this.resetError = '';
            this.isResetSheetPresented = true;
          }
        })
        .bindSheet($$this.isResetSheetPresented, this.AchievementResetSheet(), {
          height: 286,
          dragBar: true,
          showClose: false
        })

      if (this.resetFeedback.length > 0) {
        Text(this.resetFeedback)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.devHintColor())
          .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  AchievementResetSheet() {
    Column({ space: 12 }) {
      Text('清除本机成就？')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.inkColor())
      Text('会清空成就进度、已处理事件和本局提醒队列；游戏存档、最高分、收藏和设置不会受影响。')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.mutedColor())
        .textAlign(TextAlign.Center)
        .maxLines(3)
      if (this.resetError.length > 0) {
        Text(this.resetError)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.devResetTextColor())
          .textAlign(TextAlign.Center)
      }
      Row({ space: 10 }) {
        Text('取消')
          .layoutWeight(1)
          .height(42)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.inkColor())
          .textAlign(TextAlign.Center)
          .backgroundColor(this.groupSurfaceColor())
          .border({ width: 1, color: this.lineColor() })
          .borderRadius(21)
          .onClick(() => {
            if (!this.isResetting) {
              this.isResetSheetPresented = false;
            }
          })
        Text(this.isResetting ? '清除中…' : '确认清除')
          .layoutWeight(1)
          .height(42)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#2A1714' : '#FFFFFF')
          .textAlign(TextAlign.Center)
          .backgroundColor(this.devResetActionColor())
          .borderRadius(21)
          .opacity(this.isResetting ? 0.62 : 1)
          .onClick(() => {
            this.confirmAchievementReset();
          })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24, top: 16, bottom: 22 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.detailSurfaceColor())
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
    MotionPressable({
      pressScale: 0.99,
      pressedOpacity: 0.97,
      action: () => {
        this.openAchievementDetail(item.definition.id);
      }
    }) {
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
      .height(AchievementTheme.rowHeight)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.rowSurfaceColor(item))
      .border({ width: 1, color: this.rowLineColor(item) })
      .borderRadius(AchievementTheme.rowRadius)
    }
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
      Image($rawfile(this.activeFilter === 'unlocked' ? 'app/ui/achievements_empty.svg' : 'app/ui/progress_empty.svg'))
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
    if (this.selectedAchievementId.length > 0) {
      AchievementDetail({
        item: this.detailItem(),
        achievementState: this.achievementState,
        isDarkMode: this.isDarkMode,
        close: () => { this.isDetailSheetPresented = false; }
      })
    }
  }

  private visibleGroups(): AchievementGroupView[] {
    return achievementGroupsForState(this.achievementState, this.activeFilter);
  }

  private summary() {
    return achievementSummaryForState(this.achievementState);
  }

  private detailItem(): AchievementViewItem {
    const found = achievementViewItemForState(this.achievementState, this.selectedAchievementId);
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
    const group = achievementGroupsForState(this.achievementState, 'all')
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
    if (this.activeFilter === 'unlocked') {
      return '还没有已解锁成就';
    }
    if (this.activeFilter === 'inProgress') {
      return '还没有进行中的成就';
    }
    return '暂时没有可展示成就';
  }

  private emptyDescription(): string {
    if (this.activeFilter === 'unlocked') {
      return '完成一局游戏，把第一枚勋章带回鸡窝。';
    }
    if (this.activeFilter === 'inProgress') {
      return '首次获得可累计的进度后，它会显示在这里。';
    }
    return '稍后再试。';
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

  private confirmAchievementReset(): void {
    if (this.isResetting) {
      return;
    }
    this.isResetting = true;
    this.resetFeedback = '';
    this.resetError = '';
    this.resetAchievements().then((didReset: boolean) => {
      this.isResetting = false;
      if (!didReset) {
        this.resetError = '未能写入本机成就数据，请重试。';
        return;
      }
      this.activeFilter = 'all';
      this.isResetSheetPresented = false;
      this.resetFeedback = '已清除本机成就进度，可重新测试。';
    }).catch(() => {
      this.isResetting = false;
      this.resetError = '未能写入本机成就数据，请重试。';
    });
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

  private devHintColor(): string {
    return this.isDarkMode ? '#FFB9A7' : '#B34F3F';
  }

  private devResetTextColor(): string {
    return this.isDarkMode ? '#FFD0C4' : '#A33E30';
  }

  private devResetSurfaceColor(): string {
    return this.isDarkMode ? 'rgba(255,164,139,0.12)' : 'rgba(190,73,55,0.08)';
  }

  private devResetLineColor(): string {
    return this.isDarkMode ? 'rgba(255,186,166,0.32)' : 'rgba(178,66,48,0.28)';
  }

  private devResetActionColor(): string {
    return this.isDarkMode ? '#E47C66' : '#C85443';
  }
}
