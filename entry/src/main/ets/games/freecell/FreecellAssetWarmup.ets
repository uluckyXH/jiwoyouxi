export const FREECELL_INTRO_ASSET_BACKGROUND: string = 'background';
export const FREECELL_INTRO_ASSET_TITLE: string = 'title';
export const FREECELL_INTRO_ASSET_EMPTY_SLOT: string = 'empty-slot';
export const FREECELL_INTRO_ASSET_FOUNDATION_SPADES: string = 'foundation-spades';
export const FREECELL_INTRO_ASSET_FOUNDATION_HEARTS: string = 'foundation-hearts';
export const FREECELL_INTRO_ASSET_FOUNDATION_DIAMONDS: string = 'foundation-diamonds';
export const FREECELL_INTRO_ASSET_FOUNDATION_CLUBS: string = 'foundation-clubs';

export const FREECELL_INTRO_CRITICAL_ASSET_IDS: string[] = [
  FREECELL_INTRO_ASSET_BACKGROUND,
  FREECELL_INTRO_ASSET_TITLE,
  FREECELL_INTRO_ASSET_EMPTY_SLOT,
  FREECELL_INTRO_ASSET_FOUNDATION_SPADES,
  FREECELL_INTRO_ASSET_FOUNDATION_HEARTS,
  FREECELL_INTRO_ASSET_FOUNDATION_DIAMONDS,
  FREECELL_INTRO_ASSET_FOUNDATION_CLUBS
];

export class FreecellAssetWarmup {
  private requiredAssetIds: string[];
  private resolvedAssetIds: string[] = [];
  private failedAssetIds: string[] = [];

  constructor(requiredAssetIds: string[] = FREECELL_INTRO_CRITICAL_ASSET_IDS) {
    this.requiredAssetIds = requiredAssetIds.slice();
  }

  reset(): void {
    this.resolvedAssetIds = [];
    this.failedAssetIds = [];
  }

  markReady(assetId: string): boolean {
    if (!this.isRequired(assetId) || this.hasResolved(assetId)) {
      return this.isReady();
    }
    this.resolvedAssetIds.push(assetId);
    return this.isReady();
  }

  markFailed(assetId: string): void {
    if (!this.isRequired(assetId) || this.hasFailed(assetId)) {
      return;
    }
    this.failedAssetIds.push(assetId);
  }

  isReady(): boolean {
    return !this.hasFailure() && this.resolvedAssetIds.length === this.requiredAssetIds.length;
  }

  hasFailure(): boolean {
    return this.failedAssetIds.length > 0;
  }

  private isRequired(assetId: string): boolean {
    return this.requiredAssetIds.indexOf(assetId) >= 0;
  }

  private hasResolved(assetId: string): boolean {
    return this.resolvedAssetIds.indexOf(assetId) >= 0;
  }

  private hasFailed(assetId: string): boolean {
    return this.failedAssetIds.indexOf(assetId) >= 0;
  }
}
