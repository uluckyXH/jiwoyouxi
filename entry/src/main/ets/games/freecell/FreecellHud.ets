import { FREECELL_INTRO_ASSET_TITLE } from './FreecellAssetWarmup';
import { computeFreecellLayout } from './FreecellLayout';
import { FreecellMotion } from './FreecellMotion';
import { FreecellTheme } from './FreecellTheme';
import { FreecellLayout } from './FreecellTypes';

@Component
export struct FreecellHud {
  @Prop pageWidth: number = 390;
  @Prop pageHeight: number = 760;
  @Prop bestScore: number = 0;
  @Prop score: number = 0;
  @Prop elapsed: number = 0;
  @Prop moves: number = 0;
  @Prop introSceneVisible: boolean = false;
  @Prop actionsEnabled: boolean = false;
  requestExit: () => void = () => {};
  undo: () => void = () => {};
  hint: () => void = () => {};
  openGuide: () => void = () => {};
  titleReady: () => void = () => {};
  titleFailed: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.Title()
      this.BackButton()
      this.TopActions()
      this.Stats()
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  Title() {
    Image($rawfile('games/freecell/klondike_title_banner_cut.png'))
      .width(this.layout().titleWidth)
      .height(this.layout().titleHeight)
      .objectFit(ImageFit.Contain)
      .position({
        x: this.layout().offsetX + (this.layout().appWidth - this.layout().titleWidth) * 0.5,
        y: this.layout().titleTop
      })
      .opacity(this.introSceneVisible ? 1 : 0)
      .translate({ x: 0, y: this.sceneRevealOffset() })
      .animation({ duration: FreecellMotion.sceneRevealDuration, curve: Curve.EaseOut })
      .shadow({ radius: 4, color: 'rgba(88,45,8,0.16)', offsetX: 0, offsetY: 4 })
      .onComplete(() => {
        this.titleReady();
      })
      .onError(() => {
        this.titleFailed();
      })
  }

  @Builder
  BackButton() {
    Image($rawfile('games/freecell/btn_back_hall.png'))
      .width(this.backWidth())
      .height(this.backHeight())
      .objectFit(ImageFit.Contain)
      .position({
        x: this.layout().offsetX + (this.layout().tiny ? 4 : 5),
        y: this.layout().titleTop + this.layout().titleHeight * (this.layout().tiny ? 0.38 : 0.42)
      })
      .onClick(() => {
        this.requestExit();
      })
  }

  @Builder
  TopActions() {
    if (this.layout().tiny) {
      this.TopAction('games/freecell/btn_settings_cut.png', '玩法', 0, () => {
        this.openGuide();
      })
    } else {
      this.TopAction('games/freecell/btn_undo_cut.png', '撤销', 0, () => {
        this.undo();
      })
      this.TopAction('games/freecell/btn_hint_cut_cut.png', '提示', 1, () => {
        this.hint();
      })
      this.TopAction('games/freecell/btn_settings_cut.png', '玩法', 2, () => {
        this.openGuide();
      })
    }
  }

  @Builder
  TopAction(path: string, label: string, index: number, action: () => void) {
    Stack({ alignContent: Alignment.Top }) {
      Image($rawfile(path))
        .width(this.topIconWidth())
        .height(this.topIconWidth())
        .objectFit(ImageFit.Contain)
      Text(label)
        .width(this.topIconWidth())
        .fontSize(this.layout().tiny ? 6 : 8)
        .fontWeight(FontWeight.Bold)
        .fontColor(FreecellTheme.brown)
        .textAlign(TextAlign.Center)
        .textShadow({ radius: 1, color: 'rgba(255,248,224,0.86)', offsetX: 0, offsetY: 1 })
        .position({ x: 0, y: this.topIconWidth() + (this.layout().tiny ? 4 : 6) })
    }
    .width(this.topIconWidth())
    .height(this.topIconWidth() + 16)
    .position({
      x: this.topStartX() + index * (this.topIconWidth() + this.topGap()),
      y: this.topY()
    })
    .opacity(this.introSceneVisible ? 1 : 0)
    .translate({ x: 0, y: this.sceneRevealOffset() })
    .animation({ duration: FreecellMotion.sceneRevealDuration, curve: Curve.EaseOut })
    .onClick(() => {
      if (this.actionsEnabled) {
        action();
      }
    })
  }

  @Builder
  Stats() {
    this.StatCard('games/freecell/card_score_cut.png', 'score', 0, false)
    this.StatCard('games/freecell/card_timer_cut.png', 'timer', 1, true)
    this.StatCard('games/freecell/card_steps_cut.png', 'moves', 2, false)
    this.StatCard('games/freecell/card_best_score_cut.png', 'best', 3, false)
    if (!this.layout().compact) {
      Image($rawfile('games/freecell/coop_badge_corner_cut.png'))
        .width(Math.min(44, this.layout().appWidth * 0.13))
        .height(Math.min(44, this.layout().appWidth * 0.13) * 364 / 448)
        .objectFit(ImageFit.Contain)
        .position({
          x: this.layout().offsetX + this.layout().appWidth - Math.min(44, this.layout().appWidth * 0.13) - 2,
          y: this.layout().statsTop + this.layout().statHeight * 0.08
        })
        .opacity(this.introSceneVisible ? 1 : 0)
        .translate({ x: 0, y: this.sceneRevealOffset() })
        .animation({ duration: FreecellMotion.sceneRevealDuration, curve: Curve.EaseOut })
    }
  }

  @Builder
  StatCard(path: string, kind: string, index: number, timer: boolean) {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(path))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
      Text(this.statText(kind))
        .width(this.statValueWidth(timer, this.statText(kind)))
        .height(this.statValueHeight())
        .fontSize(this.statValueFontSize(timer, this.statText(kind)))
        .fontWeight(FontWeight.Bold)
        .fontColor(FreecellTheme.deepBrown)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .backgroundColor(FreecellTheme.hudValueBg)
        .borderRadius(5)
        .border({ width: 1, color: FreecellTheme.hudValueBorder })
        .shadow({ radius: 1, color: FreecellTheme.hudValueShadow, offsetX: 0, offsetY: 1 })
        .position({ x: this.statValueX(timer, this.statText(kind)), y: this.statValueY() })
    }
    .width(this.layout().statWidth)
    .height(this.layout().statHeight)
    .position({
      x: this.layout().offsetX + this.layout().side + index * (this.layout().statWidth + this.layout().statGap),
      y: this.layout().statsTop
    })
    .opacity(this.introSceneVisible ? 1 : 0)
    .translate({ x: 0, y: this.sceneRevealOffset() })
    .animation({ duration: FreecellMotion.sceneRevealDuration, curve: Curve.EaseOut })
  }

  private layout(): FreecellLayout {
    return computeFreecellLayout(this.pageWidth, this.pageHeight);
  }

  private sceneRevealOffset(): number {
    return this.introSceneVisible ? 0 : -FreecellMotion.sceneRevealOffsetVp;
  }

  private backWidth(): number {
    return Math.min(this.layout().appWidth * 0.2, this.layout().tiny ? 48 : 75);
  }

  private backHeight(): number {
    return this.backWidth() * 246 / 418;
  }

  private topIconWidth(): number {
    return this.layout().tiny
      ? Math.min(23, Math.max(21, this.layout().cardWidth * 0.9))
      : Math.min(36, Math.max(28, this.layout().cardWidth * 1.05));
  }

  private topGap(): number {
    return this.layout().tiny ? 0 : 4;
  }

  private topStartX(): number {
    if (this.layout().tiny) {
      return this.layout().offsetX + this.layout().appWidth - this.layout().side - this.topIconWidth();
    }
    return this.layout().offsetX + this.layout().appWidth - this.topIconWidth() * 3 - this.topGap() * 2 - 8;
  }

  private topY(): number {
    return this.layout().titleTop + this.layout().titleHeight * (this.layout().tiny ? 0.38 : 0.46);
  }

  private statValueY(): number {
    return this.layout().statHeight * (this.layout().compact && !this.layout().tiny ? 0.54 : 0.5);
  }

  private statValueWidth(timer: boolean, text: string): number {
    if (timer) {
      return this.layout().statWidth * (text.length > 5 ? 0.62 : 0.54);
    }
    if (text.length >= 6) {
      return this.layout().statWidth * 0.54;
    }
    if (text.length >= 4) {
      return this.layout().statWidth * 0.46;
    }
    return this.layout().statWidth * 0.36;
  }

  private statValueX(timer: boolean, text: string): number {
    const width = this.statValueWidth(timer, text);
    if (timer) {
      return this.layout().statWidth * 0.38;
    }
    return this.layout().statWidth - width - this.layout().statWidth * 0.12;
  }

  private statValueHeight(): number {
    return Math.max(14, this.layout().statHeight * 0.34);
  }

  private statValueFontSize(timer: boolean, text: string): number {
    const base = this.statBaseFontSize(timer);
    const min = timer ? Math.max(7, this.layout().statHeight * 0.2) : Math.max(8, this.layout().statHeight * 0.22);
    const estimated = this.statValueWidth(timer, text) / Math.max(1, text.length) * (timer ? 1.28 : 1.42);
    return Math.max(min, Math.min(base, estimated));
  }

  private statBaseFontSize(timer: boolean): number {
    if (this.layout().tiny) {
      return timer ? Math.max(8, Math.min(10, this.layout().statHeight * 0.3)) : Math.max(10, Math.min(13, this.layout().statHeight * 0.36));
    }
    if (this.layout().compact) {
      return timer ? Math.max(9, Math.min(12, this.layout().statHeight * 0.24)) : Math.max(12, Math.min(17, this.layout().statHeight * 0.33));
    }
    return timer ? Math.max(9, this.layout().statHeight * 0.31) : Math.max(12, this.layout().statHeight * 0.45);
  }

  private statText(kind: string): string {
    if (kind === 'score') {
      return `${this.score}`;
    }
    if (kind === 'timer') {
      return this.formatTime(this.elapsed);
    }
    if (kind === 'moves') {
      return `${this.moves}`;
    }
    return `${Math.max(this.bestScore, this.score)}`;
  }

  private formatTime(seconds: number): string {
    const min = Math.floor(seconds / 60);
    const sec = seconds % 60;
    const minText = min < 10 ? `0${min}` : `${min}`;
    const secText = sec < 10 ? `0${sec}` : `${sec}`;
    return `${minText}:${secText}`;
  }
}
