import { customScan, scanBarcode } from '@kit.ScanKit';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { GlobalThisUtil } from '../../../common/GlobalThisUtil';
import Logger from '../../../common/logger';

export const TAG = 'ScanService';

@Observed
export class ScanResult {
  code: number;
  data: Array<object>;
  size: number;
  uri: string;

  constructor() {
    this.code = 0;
    this.data = [];
    this.size = 0;
    this.uri = '';
  }
}

@Observed
export class ScanService {
  isScanned: boolean = false;
  isScanLine: boolean = false;
  isAlbumLoading: boolean = false;
  isOpenAlbum: boolean = false;
  isOnPageShow: boolean = true;
  isReleaseCamera: boolean = false;
  isStopCamera: boolean = false;
  preferenceDialog: boolean = false;
  scanResult: ScanResult = new ScanResult();
  isFlashlight: boolean = false;
  private static instance: ScanService | null = null;

  static getInstance(): ScanService {
    if (ScanService.instance === null) {
      ScanService.instance = new ScanService();
    }
    return ScanService.instance;
  }

  initCamera(options: scanBarcode.ScanOptions, viewControl: customScan.ViewControl,
    callback: AsyncCallback<Array<scanBarcode.ScanResult>>) {
    if (!this.preferenceDialog && this.isOnPageShow && !this.isScanLine && !GlobalThisUtil.getProperty('hmsCore_scan_isPickerDecode')) {
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

  startCamera(viewControl: customScan.ViewControl, callback: AsyncCallback<Array<scanBarcode.ScanResult>>): void {
    try {
      Logger.info(TAG, 'Start to start camera.');
      this.isStopCamera = false;
      customScan.start(viewControl, callback);
    } catch (error) {
      Logger.error(TAG, `Failed to start customScan. Code: ${error.code}, message: ${error.message}`);
    }
    this.isScanLine = true;
  }

  stopCamera(): void {
    if (!this.isStopCamera) {
      try {
        this.isScanLine = false;
        this.isStopCamera = true;
        Logger.info(TAG, 'Start to stop camera.');
        this.closeFlashLight();
        customScan.stop().catch((error: BusinessError) => {
          Logger.error(TAG, `Failed to stop customScan by promising. Code: ${error.code}, message: ${error.message}`);
        });
      } catch (error) {
        Logger.error(TAG, `Failed to stop customScan by catching. Code: ${error.code}, message: ${error.message}`);
      }
    }
  }

  async releaseCamera(): Promise<void> {
    if (!this.isReleaseCamera) {
      this.isReleaseCamera = true;
      this.stopCamera();
      try {
        Logger.info(TAG, 'Start to release camera.');
        customScan.release().catch((error: BusinessError) => {
          Logger.error(TAG,
            `Failed to release customScan by promising. Code: ${error.code}, message: ${error.message}`);
        });
      } catch (error) {
        Logger.error(TAG, `Failed to release customScan by catching. Code: ${error.code}, message: ${error.message}`);
      }
    }
  }

  closeFlashLight() {
    Logger.info(TAG, 'Start to close flashlight.');
    try {
      if (customScan.getFlashLightStatus()) {
        customScan.closeFlashLight();
        this.isFlashlight = false;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to closeFlashLight. Code: ${error.code}, message: ${error.message}`);
    }
  }

  resetScanData(): void {
    Logger.info(TAG, 'Start to reset scan data.');
    this.isScanLine = false;
    this.initScanData();
  }

  initScanData() {
    Logger.info(TAG, 'Start to init scan data.');
    this.isScanned = false;
    GlobalThisUtil.setProperty('hmsCore_scan_pickerUri', undefined);
    if (!this.isOpenAlbum) {
      this.isAlbumLoading = false;
      GlobalThisUtil.setProperty('hmsCore_scan_isPickerDecode', false);
    }
    this.scanResult.uri = '';
    this.scanResult.data = [];
    this.scanResult.size = 0;
  }

  scanDestroy(): void {
    Logger.info(TAG, 'Start to destroy scan.');
    this.isOnPageShow = false;
    this.resetScanData();
    this.releaseCamera();
  }

  async backToScan(options: scanBarcode.ScanOptions, viewControl: customScan.ViewControl,
    callback: AsyncCallback<Array<scanBarcode.ScanResult>>): Promise<void> {
    Logger.info(TAG, 'Start to back to scan.');
    this.resetScanData();
    this.initCamera(options, viewControl, callback);
  }
}