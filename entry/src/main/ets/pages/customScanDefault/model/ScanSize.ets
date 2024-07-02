import { display, window } from '@kit.ArkUI';
import { GlobalThisUtil } from '../../../common/GlobalThisUtil';
import { CommonConstants } from '../constants/CommonConstants';
import { BreakpointConstants } from '../constants/BreakpointConstants';
import Logger from '../../../common/logger';

export const TAG = 'ScanSize';

@Observed
export class XComponentSize {
  width: number;
  height: number;
  offsetX: number;
  offsetY: number;

  constructor() {
    this.width = 1080;
    this.height = 720;
    this.offsetX = 0;
    this.offsetY = 0;
  }
}

@Observed
export class DeviceStatus {
  isLandscape: boolean;
  orientation: display.Orientation;
  foldStatus: display.FoldStatus;

  constructor() {
    this.isLandscape = false;
    this.orientation = display.Orientation.PORTRAIT;
    this.foldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  }
}

@Observed
export class ScanLayout {
  topHeight: number; // Height above the scanning line area.
  bottomHeightMdOrLg: number = CommonConstants.SCAN_BOTTOM_HEIGHT; // When the device is determined as an md or lg device, the height below the scanning line area.
  bottomHeightSmExcludesmarginDSplitScreen: number =
    CommonConstants.ICON_PRESS_HEIGHT + CommonConstants.TAB_BAR_HEIGHT +
    CommonConstants.AI_BOTTOM_BAR_HEIGHT; // When the device is determined as an SM device and is in split-screen mode, the height of marginD is deducted from the bottom of the scanning line area.
  bottomHeightSmExcludesmarginD: number =
    CommonConstants.SCAN_LINE_MARGIN + CommonConstants.FLASH_HEIGHT + CommonConstants.FLASH_MARGIN_BOTTOM +
    CommonConstants.PLACEHOLDER_HEIGHT +
    this.bottomHeightSmExcludesmarginDSplitScreen; //When the device is determined as an SM device and is not in split-screen mode, the height of marginD is deducted from the bottom of the scanning line area.
  windowHeight: number = 800;
  deviceHeight: number = 800;
  marginD: number = 10;
  hasMarginD: boolean = false;
  splitScreen: boolean = false;

  constructor(navHeight: number) {
    this.topHeight = navHeight + CommonConstants.TOP_BUTTON_HEIGHT + CommonConstants.TITLE_MARGIN_TOP +
    CommonConstants.TITLE_MAIN_LINE_HEIGHT + CommonConstants.SCAN_LINE_MARGIN;
  }

  getMarginD(): void {
    let displayClass: display.Display | null = null;
    try {
      displayClass = display.getDefaultDisplaySync();
    } catch (error) {
      Logger.error(TAG, `Failed to getDefaultDisplaySync. Code: ${error.code}, message: ${error.message}`);
    }
    if (displayClass !== null) {
      let deviceWidth: number = px2vp(displayClass.width);
      let deviceHeight: number = px2vp(displayClass.height);
      this.deviceHeight = deviceHeight;
      this.windowHeight = deviceHeight;
      //Obtain the height of the scenic spot.
      let viewHeight: number = deviceHeight - deviceWidth * 16 / 9 - CommonConstants.TOP_BUTTON_HEIGHT;
      // Height of the icon and button area.
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
  width: number;
  height: number;
  densityPixels: number;

  constructor() {
    this.width = 1080;
    this.height = 720;
    this.densityPixels = 1;
  }
}

@Observed
export class ScanSize {
  navHeight: number;
  xComponentSize: XComponentSize;
  deviceStatus: DeviceStatus;
  scanLayout: ScanLayout;
  newArea: NewArea;

  constructor() {
    this.navHeight = CommonConstants.TABLET_NAV_HEIGHT;
    this.xComponentSize = new XComponentSize();
    this.deviceStatus = new DeviceStatus();
    this.newArea = new NewArea();
    this.scanLayout = new ScanLayout(this.navHeight);
  }

  private static instance: ScanSize | null = null;

  static getInstance(): ScanSize {
    if (ScanSize.instance === null) {
      ScanSize.instance = new ScanSize();
    }
    return ScanSize.instance;
  }

  setNavHeight() {
    if (GlobalThisUtil.getProperty('hmsCore_scan_device_type') === CommonConstants.DEVICE_TYPES[0]) {
      this.navHeight = CommonConstants.PHONE_NAV_HEIGHT;
    }
    if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable')) {
      this.navHeight = CommonConstants.FOLD_DEVICE_NAV_HEIGHT;
    }
  }

  getDisplay(): display.Display | null {
    let displayClass: display.Display | null = null;
    try {
      displayClass = display.getDefaultDisplaySync();
    } catch (error) {
      Logger.error(TAG, `Failed to getDefaultDisplaySync. Code: ${error.code}, message: ${error.message}`);
    }
    return displayClass
  }

  setWindowSize(): window.Size | null {
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

  getOrientation() {
    let displayClass: display.Display | null = this.getDisplay();
    if (displayClass !== null) {
      this.deviceStatus.orientation = displayClass.orientation;
      if (this.deviceStatus.orientation === display.Orientation.LANDSCAPE ||
        this.deviceStatus.orientation === display.Orientation.LANDSCAPE_INVERTED) {
        this.deviceStatus.isLandscape = true;
      } else {
        this.deviceStatus.isLandscape = false;
      }
    }
    Logger.info(TAG, `getOrientation scan orientation:  ${this.deviceStatus.orientation}`);
  }

  setScanXComponentSize(isSupportRotation: boolean, windowSize: window.Size): void {
    Logger.info(TAG, `Start to set scan XComponent size. Width: ${windowSize.width}, height: ${windowSize.height}`);
    if (isSupportRotation) {
      this.getOrientation();
    }
    this.updateBreakpoint(windowSize.width);
    if (windowSize) {
      let width: number = windowSize.width;
      let height: number = windowSize.height;
      let offsetY: number = 0;
      let offsetX: number = 0;
      let ratio = CommonConstants.NOT_FOLD_DEVICE_EXPAND_RATIO;
      if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable') &&
        display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_EXPANDED) {
        ratio = CommonConstants.FOLD_DEVICE_EXPAND_RATIO;
      }
      // Pixel ratio width/height = 16/9||1. The aspect ratio is the reciprocal of the pixel ratio.
      if (this.deviceStatus.orientation === display.Orientation.LANDSCAPE ||
        this.deviceStatus.orientation === display.Orientation.LANDSCAPE_INVERTED) {
        ratio = 1 / ratio;
      }
      if (ratio < width / height) {
        height = width / ratio;
        offsetY = (windowSize.height - height) / 2;
      } else {
        width = height * ratio;
        offsetX = (windowSize.width - width) / 2;
      }
      this.updateXComponentSize(width, height, offsetX, offsetY);
      Logger.info(TAG,
        `setScanXComponentSize End. Width: ${this.xComponentSize.width}, height: ${this.xComponentSize.height}, offsetX: ${this.xComponentSize.offsetX}, offsetY: ${this.xComponentSize.offsetY}`);
    }
  }

  updateXComponentSize(width: number, height: number, offsetX: number, offsetY: number): void {
    Logger.info(TAG, 'Start to update XComponent size.');
    this.xComponentSize.width = width;
    this.xComponentSize.height = height;
    this.xComponentSize.offsetX = offsetX;
    this.xComponentSize.offsetY = offsetY;
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
      // Use the status variable to record the current breakpoint value.
      AppStorage.setOrCreate('currentBreakpoint', newBp);
      Logger.info(TAG, `Succeeded in setting currentBreakpoint. CurrentBreakpoint: ${newBp}`);
    }
  }
}
