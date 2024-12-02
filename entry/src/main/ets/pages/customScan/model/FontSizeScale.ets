import Logger from '../../../common/Logger';

const TAG = 'FontSizeScale';

export class FontSizeScale {
  public static getLimitFontSize(fontSizeScale: number, maxScale: number, res: Resource): number | string | Resource {
    let fontSizePx: number;
    try {
      // The parameters of the getNumber method must be of the Resource type. Otherwise, the performance deteriorates.
      fontSizePx = getContext().resourceManager.getNumber(res.id);
    } catch (error) {
      Logger.error(TAG, `Failed to getNumber by resourceManager. Code: ${error.code}`);
      return res;
    }
    let fontSizeVp: number = px2vp(fontSizePx);
    return fontSizeScale > maxScale ? `${fontSizeVp * maxScale}vp` : fontSizeVp;
  }
}