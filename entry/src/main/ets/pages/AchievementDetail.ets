import { AchievementBadge } from '../components/AchievementBadge';
import { AppIcon } from '../components/AppIcon';
import { AchievementTheme } from '../design/AchievementTheme';
import { CoopTheme } from '../design/CoopTheme';
import { AchievementState, AchievementViewItem } from '../shell/AchievementModule';
import { ACHIEVEMENT_PRIMARY_GAME_IDS } from '../shell/AchievementRegistry';
import { moduleById } from '../shell/GameRegistry';

@Component
export struct AchievementDetail {
  @Prop item: AchievementViewItem;
  @Prop achievementState: AchievementState;
  @Prop isDarkMode: boolean = false;
  @Prop embedded: boolean = false;
  close: () => void = () => {};

  build() {
    Scroll() {
      Column({ space: 14 }) {
        AchievementBadge({
          item: this.item,
          isDarkMode: this.isDarkMode,
          badgeSize: AchievementTheme.detailBadgeSize,
          accentColor: this.accentColor()
        })
        Text(this.item.definition.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.inkColor())
          .textAlign(TextAlign.Center)
        Text(this.item.definition.detail)
          .fontSize(13)
          .fontColor(this.mutedColor())
          .lineHeight(21)
          .textAlign(TextAlign.Center)
          .width('100%')
        Column({ space: 12 }) {
          this.InfoRow('当前状态', this.statusText())
          this.InfoRow(this.isGlobal() ? '成就类型' : '来源游戏',
            this.isGlobal() ? '通用 · 合集里程碑' : moduleById(this.item.definition.gameId).title)
          if (this.item.status === 'unlocked') {
            this.InfoRow('解锁时间', this.unlockDate())
          }
          if (this.item.target > 0) {
            this.InfoRow(this.item.definition.id === 'global.favorite_three' ? '已达进度' : '完成进度',
              `${this.item.current} / ${this.item.target}${this.progressUnit()}`)
            Progress({ value: this.item.current, total: this.item.target, type: ProgressType.Linear })
              .width('100%')
              .color(this.accentColor())
              .backgroundColor(this.isDarkMode ? AchievementTheme.progressTrackDark : AchievementTheme.progressTrackLight)
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.isDarkMode ? '#2D2821' : '#FFF0D8')
        .borderRadius(18)

        if (this.item.definition.id === 'global.play_six_games') {
          this.GameChecklist()
        }
        if (this.isGlobal()) {
          Text(this.item.definition.id === 'global.favorite_three'
            ? '进度保留已达到的最高值，取消收藏不会回退。只记录功能启用后的有效收藏操作。'
            : '只记录功能启用后正常结束的对局；解锁后永久保留。')
            .fontSize(11)
            .fontColor(this.mutedColor())
            .lineHeight(18)
            .width('100%')
            .textAlign(TextAlign.Center)
        }
        Button(this.embedded ? '收起详情' : '知道了')
          .width('100%')
          .constraintSize({ minHeight: 44 })
          .padding({ top: 12, bottom: 12 })
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#21160A' : '#FFFFFF')
          .backgroundColor(this.goldColor())
          .borderRadius(22)
          .onClick(() => this.close())
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 18, bottom: 28 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(this.isDarkMode ? AchievementTheme.detailSurfaceDark : AchievementTheme.detailSurfaceLight)
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize(12)
        .fontColor(this.mutedColor())
      Text(value)
        .layoutWeight(1)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.inkColor())
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  @Builder
  GameChecklist() {
    Column({ space: 10 }) {
      Text('六款游戏完成记录')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.inkColor())
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(ACHIEVEMENT_PRIMARY_GAME_IDS, (gameId: string) => {
          Row({ space: 6 }) {
            AppIcon({
              name: this.achievementState.playedGameIds.includes(gameId) ? 'check' : 'circle',
              iconSize: 16,
              tint: this.achievementState.playedGameIds.includes(gameId)
                ? (this.isDarkMode ? '#FFD083' : '#A76720') : this.mutedColor()
            })
            Text(moduleById(gameId).title)
              .layoutWeight(1)
              .fontSize(11)
              .fontColor(this.inkColor())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('48%')
          .height(36)
          .padding({ left: 9, right: 6 })
          .margin({ bottom: 8 })
          .backgroundColor(this.isDarkMode ? '#2D2821' : '#FFF0D8')
          .borderRadius(10)
          .accessibilityText(`${moduleById(gameId).title}，${this.achievementState.playedGameIds.includes(gameId)
            ? '已完成' : '未完成'}`)
        }, (gameId: string) => gameId)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  private isGlobal(): boolean {
    return this.item.definition.gameId === 'global';
  }

  private progressUnit(): string {
    if (this.item.definition.progressKind === 'totalSessions') {
      return ' 局';
    }
    return this.isGlobal() ? ' 款' : '';
  }

  private statusText(): string {
    if (!this.item.definition.enabled) {
      return '待开放';
    }
    if (this.item.status === 'unlocked') {
      return '已解锁';
    }
    return this.item.status === 'inProgress' ? '进行中' : '未达成';
  }

  private unlockDate(): string {
    const date = new Date(this.item.unlockedAt);
    return `${date.getFullYear()}-${this.twoDigits(date.getMonth() + 1)}-${this.twoDigits(date.getDate())} ` +
      `${this.twoDigits(date.getHours())}:${this.twoDigits(date.getMinutes())}`;
  }

  private twoDigits(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private goldColor(): string {
    return this.isDarkMode ? AchievementTheme.goldDark : AchievementTheme.goldLight;
  }

  private accentColor(): string {
    return this.isGlobal() ? this.goldColor() : moduleById(this.item.definition.gameId).accent;
  }

  private inkColor(): string {
    return this.isDarkMode ? '#FFF2DF' : CoopTheme.ink;
  }

  private mutedColor(): string {
    return this.isDarkMode ? '#C8B7A2' : CoopTheme.muted;
  }
}
