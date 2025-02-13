import { display, window } from '@kit.ArkUI';
import { GlobalThisUtil } from '../../../common/GlobalThisUtil';
import { CommonConstants, DisplayRotationAngle } from '../constants/CommonConstants';
import { BreakpointConstants } from '../constants/BreakpointConstants';
import Logger from '../../../common/Logger';

export const TAG = 'ScanKit ScanSize';

export function getFoldStatusByDisplay(): display.FoldStatus {
  let foldStatus: display.FoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  try {
    let getFoldStatus: display.FoldStatus = display.getFoldStatus();
    if (getFoldStatus) {
      foldStatus = getFoldStatus;
    }
  } catch (error) {
    Logger.error(TAG, `Failed to getFoldStatusByDisplay. Code: ${error.code}`);

  }
  return foldStatus;
}

@Observed
export class XComponentSize {
  public width: number; // XComponent width
  public height: number; // XComponent height
  public offsetX: number; // XComponent's offset on the x-axis
  public offsetY: number; // XComponent's offset on the y-axis

  constructor() {
    this.width = 1080;
    this.height = 720;
    this.offsetX = 0;
    this.offsetY = 0;
  }
}

@Observed
export class DeviceStatus {
  public rotation: number;
  public oldFoldStatus: display.FoldStatus;
  public newFoldStatus: display.FoldStatus;
  public deviceType: string;

  constructor() {
    this.rotation = DisplayRotationAngle.ROTATION_0;
    this.oldFoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
    this.newFoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
    this.deviceType = GlobalThisUtil.getProperty(CommonConstants.GLOBAL_SCAN_DEVICE_TYPE);
  }

  public isLandscape(): boolean {
    let displayClass: display.Display | null = null;
    try {
      displayClass = display.getDefaultDisplaySync();
    } catch (error) {
      Logger.error(TAG, `Failed to getDefaultDisplaySync. Code: ${error.code}`);
    }
    if (displayClass !== null) {
      Logger.info(TAG, `Display rotation: ${displayClass.rotation}`);
      this.rotation = displayClass.rotation;
    }
    return this.rotation === DisplayRotationAngle.ROTATION_90 ||
        this.rotation === DisplayRotationAngle.ROTATION_270;
  }

  public setRotation(rotation: number): void {
    Logger.info(TAG, `setRotation,rotation: ${rotation}`);
    this.rotation = rotation;
  }
}

@Observed
export class ScanLayout {
  public topHeight: number; // Scanning line bottom area height.
  public bottomHeightMdOrLg: number =
    CommonConstants.SCAN_BOTTOM_HEIGHT; // Height below the scanning line area when the device is considered as an MD or LG device.
  public bottomHeightSmExcludesMarginDSplitScreen: number =
    CommonConstants.ICON_PRESS_HEIGHT + CommonConstants.TAB_BAR_HEIGHT +
    CommonConstants.AI_BOTTOM_BAR_HEIGHT; // Height below the scanning line area minus marginD if the device is an SM device and is in split-screen mode.
  public bottomHeightSmExcludesMarginD: number =
    CommonConstants.SCAN_LINE_MARGIN + CommonConstants.FLASH_HEIGHT + CommonConstants.FLASH_MARGIN_BOTTOM +
    CommonConstants.PLACEHOLDER_HEIGHT +
    this.bottomHeightSmExcludesMarginDSplitScreen; // Height below the scanning line area minus marginD if the device is an SM device and is not in split-screen mode.
  public windowHeight: number = 800; // Window height.
  public deviceHeight: number = 800; // Window width.
  public marginD: number = 10; // MarginID defined by UX.
  public hasMarginD: boolean = false;
  public splitScreen: boolean = false; // Whether the device is in split-screen mode.

  constructor(navHeight: number) {
    this.topHeight = navHeight + CommonConstants.TOP_BUTTON_HEIGHT + CommonConstants.TITLE_MARGIN_TOP +
    CommonConstants.TITLE_MAIN_LINE_HEIGHT + CommonConstants.SCAN_LINE_MARGIN;
  }

  public getMarginD(): void {
    let displayClass: display.Display | null = null;
    try {
      displayClass = display.getDefaultDisplaySync();
    } catch (error) {
      Logger.error(TAG, `Failed to getDefaultDisplaySync. Code: ${error.code}`);
    }
    if (displayClass !== null) {
      let deviceWidth: number = px2vp(displayClass.width);
      let deviceHeight: number = px2vp(displayClass.height);
      this.deviceHeight = deviceHeight;
      this.windowHeight = deviceHeight;
      // Viewing area height.
      let viewHeight: number = deviceHeight - deviceWidth * 16 / 9 - CommonConstants.TOP_BUTTON_HEIGHT;
      // Icon and button area height.
      let buttonHeight: number = deviceWidth * 16 / 9 - deviceWidth * 4 / 3;
      if (viewHeight >= 72) {
        this.marginD = (buttonHeight - 128) / 3;
      } else {
        this.marginD = (buttonHeight - 160) / 3;
      }
    }
  }
}

@Observed
export class NewArea {
  public width: number;
  public height: number;
  public densityPixels: number; // Pixel density.

  constructor() {
    this.width = 1080;
    this.height = 720;
    this.densityPixels = 1;
  }
}

@Observed
export class ScanSize {
  public navHeight: number; // Height of the navigation bar at the top.
  public xComponentSize: XComponentSize;
  public deviceStatus: DeviceStatus;
  public scanLayout: ScanLayout; // Scan UI layout.
  public newArea: NewArea; // Area information after the window is refreshed.

  constructor() {
    this.navHeight = CommonConstants.TABLET_NAV_HEIGHT;
    this.xComponentSize = new XComponentSize();
    this.deviceStatus = new DeviceStatus();
    this.newArea = new NewArea();
    this.scanLayout = new ScanLayout(this.navHeight);
  }

  private static instance: ScanSize | null = null;

  public static getInstance(): ScanSize {
    if (ScanSize.instance === null) {
      ScanSize.instance = new ScanSize();
    }
    return ScanSize.instance;
  }

  public setNavHeight() {
    if (GlobalThisUtil.getProperty(CommonConstants.GLOBAL_SCAN_DEVICE_TYPE) === CommonConstants.DEVICE_TYPES[0]) {
      this.navHeight = CommonConstants.PHONE_NAV_HEIGHT;
    }
    if (GlobalThisUtil.getProperty(CommonConstants.GLOBAL_SCAN_DEVICE_IS_FOLDING)) {
      this.navHeight = CommonConstants.FOLD_DEVICE_NAV_HEIGHT;
    }
  }

  public getDisplay(): display.Display | null {
    let displayClass: display.Display | null = null;
    try {
      displayClass = display.getDefaultDisplaySync();
    } catch (error) {
      Logger.error(TAG, `Failed to getDefaultDisplaySync. Code: ${error.code}`);
    }
    return displayClass;
  }

  public setWindowSize(): window.Size | null {
    Logger.info(TAG, 'Start to set window size');
    let displayClass: display.Display | null = this.getDisplay();
    let windowSize: window.Size;
    if (displayClass !== null) {
      windowSize = {
        width: px2vp(displayClass.width),
        height: px2vp(displayClass.height)
      }
      this.newArea.width = displayClass.width;
      this.newArea.height = displayClass.height;
      this.newArea.densityPixels = displayClass.densityPixels;
      return windowSize;
    }
    return null;
  }

  public setDisplayRotation(): void {
    let displayClass: display.Display | null = this.getDisplay();
    if (displayClass !== null) {
      this.deviceStatus.setRotation(displayClass.rotation);
      Logger.info(TAG, `setDisplayRotation rotation: ${displayClass.rotation}`);
    }
  }

  public setScanXComponentSize(windowSize: window.Size): void {
    if (windowSize) {
      Logger.info(TAG, `Start to set scan XComponent size. Width: ${windowSize.width}, height: ${windowSize.height}`);
      this.updateBreakpoint(windowSize.width);
      let width: number = windowSize.width;
      let height: number = windowSize.height;
      let offsetY: number = 0;
      let offsetX: number = 0;
      let ratio = CommonConstants.NOT_FOLD_DEVICE_EXPAND_RATIO;
      ratio = width <= height ? this.selectSuitableRatio(width, height) : this.selectSuitableRatio(height, width);

      // The aspect ratio is 9/16 or 1. When the device is in landscape mode, the reciprocal is used.
      if (this.deviceStatus.isLandscape()) {
        ratio = 1 / ratio;
      }
      if (height > 0) {
        if (ratio < width / height) {
          height = width / ratio;
          offsetY = (windowSize.height - height) / 2;
        } else {
          width = height * ratio;
          offsetX = (windowSize.width - width) / 2;
        }
        this.updateXComponentSize(width, height, offsetX, offsetY);
        Logger.info(TAG,
          `setScanXComponentSize End. Width: ${this.xComponentSize.width}, height: ${this.xComponentSize.height},
          offsetX: ${this.xComponentSize.offsetX}, offsetY: ${this.xComponentSize.offsetY}`);
      } else {
        Logger.error(TAG, `height less than or equal to 0`);
      }
    }
  }

  public updateXComponentSize(width: number, height: number, offsetX: number, offsetY: number): void {
    Logger.info(TAG, 'Start to update XComponent size.');
    this.xComponentSize.width = width;
    this.xComponentSize.height = height;
    this.xComponentSize.offsetX = offsetX;
    this.xComponentSize.offsetY = offsetY;
  }

  private selectSuitableRatio(width: number, height: number): number {
    let suitableRatio: number = 9/16;
    let cameraRatios: Array<number> = [9/16, 3/4, 1];
    let smallestRatioDelta: number = Infinity;
    for (let ratio of cameraRatios) {
      let ratioDelta = Math.abs(ratio - width / height)
      if (ratioDelta < smallestRatioDelta) {
        smallestRatioDelta = ratioDelta;
        suitableRatio = ratio;
      }
    }
    return suitableRatio;
  }

  private updateBreakpoint(windowWidth: number): void {
    Logger.info(TAG, 'Start to update breakpoint.');
    let newBp: string = '';
    if (windowWidth < BreakpointConstants.MIDDLE_DEVICE_WIDTH) {
      newBp = BreakpointConstants.BREAKPOINT_SM;
      if (!this.scanLayout.hasMarginD) {
        this.scanLayout.hasMarginD = true;
        this.scanLayout.getMarginD();
        Logger.info(TAG, `Succeeded in getting marginD. MarginD: ${this.scanLayout.marginD}`);
      }
    } else if (windowWidth < BreakpointConstants.LARGE_DEVICE_WIDTH) {
      newBp = BreakpointConstants.BREAKPOINT_MD;
    } else {
      newBp = BreakpointConstants.BREAKPOINT_LG;
    }
    if (AppStorage.get('currentBreakpoint') !== newBp) {
      // Use AppStorage to record the current breakpoint value.
      AppStorage.setOrCreate('currentBreakpoint', newBp);
      Logger.info(TAG, `Succeeded in setting currentBreakpoint. CurrentBreakpoint: ${newBp}`);
    }
  }
}
