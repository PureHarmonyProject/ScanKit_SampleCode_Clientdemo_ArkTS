import { customScan, scanBarcode, scanCore } from '@kit.ScanKit';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { GlobalThisUtil } from '../../../common/GlobalThisUtil';
import Logger from '../../../common/Logger';
import { CommonConstants } from '../constants/CommonConstants';

export const TAG = 'ScanService';

@Observed
export class ScanResults {
  public code: number;
  public data: Array<scanBarcode.ScanResult>;
  public size: number;
  public uri: string;

  constructor() {
    this.code = 0;
    this.data = [];
    this.size = 0;
    this.uri = '';
  }
}

@Observed
export class ScanService {
  public isScanned: boolean = false;
  public isScanLine: boolean = false;
  public isAlbumLoading: boolean = false;
  public isOpenAlbum: boolean = false;
  public isOnPageShow: boolean = true;
  public isReleaseCamera: boolean = false;
  public isStopCamera: boolean = false;
  public scanResult: ScanResults = new ScanResults();
  public isFlashlight: boolean = false; // Whether the flash light is turned on.
  public isSensorLight: boolean = false; // Determine whether the condition for displaying the flashing icon is met based on lightningFlash.
  public retryScanTimes: number = 0;
  private static instance: ScanService | null = null;

  public static getInstance(): ScanService {
    if (ScanService.instance === null) {
      ScanService.instance = new ScanService();
    }
    return ScanService.instance;
  }

  public initCamera(options: scanBarcode.ScanOptions, viewControl: customScan.ViewControl,
    callback: AsyncCallback<Array<scanBarcode.ScanResult>>) {
    if (this.isOnPageShow && !this.isScanLine &&
      !GlobalThisUtil.getProperty(CommonConstants.GLOBAL_SCAN_IS_DECODING_GALLERY)) {
      Logger.info(TAG, `initCamera start. width: ${viewControl.width}, height: ${viewControl.height}`);
      try {
        Logger.info(TAG, 'customScan init start');
        this.isReleaseCamera = false;
        customScan.init(options);
      } catch (error) {
        Logger.error(TAG, `Failed to init customScan. Code: ${error.code}, message: ${error.message}`);
      }
      this.startCamera(viewControl, callback);
      Logger.info(TAG, 'initCamera end');
    }
  }

  public startCamera(viewControl: customScan.ViewControl,
    callback: AsyncCallback<Array<scanBarcode.ScanResult>>): void {
    try {
      Logger.info(TAG, 'Start to start camera.');
      this.isStopCamera = false;
      customScan.start(viewControl, callback);
      this.initLightFlash()
      this.onLightingFlash();
    } catch (error) {
      Logger.error(TAG, `Failed to start customScan. Code: ${error.code}`);
    }
    this.isScanLine = true;
  }

  public async stopCamera(): Promise<void> {
    if (!this.isStopCamera) {
      try {
        this.isScanLine = false;
        this.isStopCamera = true;
        Logger.info(TAG, 'Start to stop camera.');
        this.closeFlashLight();
        this.offLightingFlash();
        await customScan.stop().catch((error: BusinessError) => {
          Logger.error(TAG, `Failed to stop customScan by promising. Code: ${error.code}`);
        });
      } catch (error) {
        Logger.error(TAG, `Failed to stop customScan by catching. Code: ${error.code}`);
      }
    }
  }

  public async releaseCamera(): Promise<void> {
    if (!this.isReleaseCamera) {
      this.isReleaseCamera = true;
      await this.stopCamera();
      try {
        Logger.info(TAG, 'Start to release camera.');
        await customScan.release().catch((error: BusinessError) => {
          Logger.error(TAG,
            `Failed to release customScan by promising. Code: ${error.code}`);
        });
      } catch (error) {
        Logger.error(TAG, `Failed to release customScan by catching. Code: ${error.code}`);
      }
    }
  }

  public closeFlashLight() {
    Logger.info(TAG, 'Start to close flashlight.');
    try {
      if (customScan.getFlashLightStatus()) {
        customScan.closeFlashLight();
        this.isFlashlight = false;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to closeFlashLight. Code: ${error.code}`);
    }
  }

  public resetScanData(): void {
    Logger.info(TAG, 'Start to reset scan data.');
    this.isScanLine = false;
    this.initScanData();
  }

  public initScanData() {
    Logger.info(TAG, 'Start to init scan data.');
    this.isScanned = false;
    GlobalThisUtil.setProperty(CommonConstants.GLOBAL_SCAN_SELECT_A_PICTURE, false);
    if (!this.isOpenAlbum) {
      this.isAlbumLoading = false;
      GlobalThisUtil.setProperty(CommonConstants.GLOBAL_SCAN_IS_DECODING_GALLERY, false);
    }
    this.scanResult.uri = '';
    this.scanResult.data = [];
    this.scanResult.size = 0;
  }

  public scanDestroy(): void {
    Logger.info(TAG, 'Start to destroy scan.');
    this.isOnPageShow = false;
    this.resetScanData();
    this.releaseCamera();
  }

  public async backToScan(options: scanBarcode.ScanOptions, viewControl: customScan.ViewControl,
    callback: AsyncCallback<Array<scanBarcode.ScanResult>>): Promise<void> {
    Logger.info(TAG, 'Start to back to scan.');
    this.resetScanData();
    this.initCamera(options, viewControl, callback);
  }

  public initLightFlash(): void {
    this.isSensorLight = false;
    this.isFlashlight = false;
  }

  public offLightingFlash(): void {
    try {
      customScan.off('lightingFlash');
    } catch (error) {
      Logger.error(TAG, `Catch: off lightingFlash. Code: ${error.code}, message: ${error?.message}`);
    }
  }

  public onLightingFlash(): void {
    try {
      customScan.on('lightingFlash', (error, isLightingFlash) => {
        if (error) {
          Logger.error(TAG,
            `lightingFlash callback error. Code: ${error.code}, message: ${error?.message}`);
          return;
        }
        this.isSensorLight = isLightingFlash
        Logger.info(TAG, `isSensorLight: ${this.isSensorLight}`);
      });
    } catch (error) {
      Logger.error(TAG,
        `lightingFlash callback error by catching. Code: ${error.code}, message: ${error?.message}`);
    }
  }

  public getZoom(): number {
    let zoom = 1;
    try {
      zoom = customScan.getZoom();
      Logger.info(TAG, `getZoom, zoom: ${zoom}`);
    } catch (error) {
      Logger.error(TAG, 'Catch: customScan getZoom. Code: ${error.code}, message: ${error?.message}');
    }
    return zoom;
  }

  public setZoom(pinchValue: number): void {
    try {
      customScan.setZoom(pinchValue);
      Logger.info(TAG, `setZoom, pinchValue: ${pinchValue}`);
    } catch (error) {
      Logger.error(TAG, 'Catch: customScan setZoom. Code: ${error.code}, message: ${error?.message}');
    }
  }

  public changeFlashlight(): void {
    try {
      if (customScan.getFlashLightStatus()) {
        customScan.closeFlashLight();
      } else {
        customScan.openFlashLight();
      }
      this.isFlashlight = customScan.getFlashLightStatus();
    } catch (error) {
      Logger.error(TAG, `Failed to change flashLight. Code: ${error.code}`);
    }
  }

  // start回调时，根据error判断是否做重试操作
  retryOnCondition(error: BusinessError, options: scanBarcode.ScanOptions, viewControl: customScan.ViewControl,
    callback: AsyncCallback<Array<scanBarcode.ScanResult>>): boolean {
    if (error) {
      Logger.error(TAG,
        `An error is returned during customCallbackScan. Code: ${error.code}, message: ${error.message}`);
      if (error.name !== 'galleryDecodeResult' && this.retryScanTimes < CommonConstants.MAX_RETRY_SCAN_TIMES &&
        error.code === scanCore.ScanErrorCode.INTERNAL_ERROR) {
        this.retryScanTimes++;
        let timeId = setTimeout(async () => {
          Logger.info(TAG, `Retry scan start by customScan.start callback. Times: ${this.retryScanTimes}.`);
          this.isScanLine = false;
          await this.releaseCamera();
          this.backToScan(options, viewControl, callback);
          Logger.info(TAG, `Retry scan end.`);
          clearTimeout(timeId);
        }, CommonConstants.DELAY_RETRY_SCAN_TIME)
        // 重试了
        return true;
      }
    }
    return false; // 没做重试
  }

  resetRetryScanTimes(): void {
    Logger.info(TAG, 'Reset retry scan times.');
    this.retryScanTimes = 0;
  }
}