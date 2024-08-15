import Logger from '../../../common/Logger';

const TAG = 'FontSizeScale';

export class FontSizeScale {
  public static getLimitFontSize(fontSizeScale: number, maxScale: number, res: Resource): number | string | Resource {
    // Use res.id for the getNumber parameter. Otherwise, the performance deteriorates.
    let fontSizePx: number;
    try {
      fontSizePx = getContext().resourceManager.getNumber(res.id);
    } catch (error) {
      Logger.error(TAG, `Failed to flush preference. Code: ${error.code}`);
      return res;
    }
    let fontSizeVp: number = px2vp(fontSizePx);
    return fontSizeScale > maxScale ? `${fontSizeVp * maxScale}vp` : fontSizeVp;
  }
}