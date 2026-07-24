export interface CoopViewportFrame {
  width: number;
  height: number;
}

export class CoopViewport {
  static readonly phoneDefaultWidth: number = 390;
  static readonly phoneDefaultHeight: number = 844;
  static readonly phoneMaxWidth: number = 430;
  static readonly phoneMaxHeight: number = 932;

  static frame(rawWidth: number, rawHeight: number): CoopViewportFrame {
    const width = Number.isFinite(rawWidth) && rawWidth > 0 ? rawWidth : CoopViewport.phoneDefaultWidth;
    const height = Number.isFinite(rawHeight) && rawHeight > 0 ? rawHeight : CoopViewport.phoneDefaultHeight;
    if (width <= CoopViewport.phoneMaxWidth && height <= CoopViewport.phoneMaxHeight) {
      return { width: width, height: height };
    }

    const scale = Math.min(
      1,
      width / CoopViewport.phoneDefaultWidth,
      height / CoopViewport.phoneDefaultHeight
    );
    return {
      width: Math.round(CoopViewport.phoneDefaultWidth * scale),
      height: Math.round(CoopViewport.phoneDefaultHeight * scale)
    };
  }
}
