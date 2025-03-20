import display from '@ohos.display';
import { WindowService } from './WindowService';
import { DeviceService } from './DeviceService';
import Logger from '../../../common/Logger';

export const TAG = 'ScanSize';


@Observed
export class FoldStatus {
  public oldFoldStatus: display.FoldStatus;
  public newFoldStatus: display.FoldStatus;

  constructor() {
    this.oldFoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
    this.newFoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  }
}

@Observed
export class XComponentService {
  public width: number = 1080;
  public height: number = 720;
  public offsetX: number = 0;
  public offsetY: number = 0;
  public foldStatus: FoldStatus = new FoldStatus();
  private static instance: XComponentService | null = null;

  public static getInstance(): XComponentService {
    if (XComponentService.instance === null) {
      XComponentService.instance = new XComponentService();
    }
    return XComponentService.instance;
  }

  public setScanXComponentSize(): void {
    let windowService: WindowService = WindowService.getInstance();
    let width: number = windowService.width;
    let height: number = windowService.height;
    let offsetY: number = 0;
    let offsetX: number = 0;
    let ratio: number = DeviceService.portraitRatio;

    if (DeviceService.isLandscape()) {
      ratio = 1 / DeviceService.portraitRatio;
    }

    Logger.info(TAG, `Start to set scan XComponent size. Width: ${width}, height: ${height}, ratio: ${ratio}`);
    if (height > 0) {
      if (ratio < width / height) {
        height = width / ratio;
        offsetY = (windowService.height - height) / 2;
      } else {
        width = height * ratio;
        offsetX = (windowService.width - width) / 2;
      }
      this.width = width;
      this.height = height;
      this.offsetX = offsetX;
      this.offsetY = offsetY;
      Logger.info(TAG,
        `setScanXComponentSize End. Width: ${this.width}, height: ${this.height}, offsetX: ${this.offsetX}, offsetY: ${this.offsetY}`);
    } else {
      Logger.error(TAG, `height less than or equal to 0`);
    }
  }
}
