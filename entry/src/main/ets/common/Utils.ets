import { scanCore, type scanBarcode, generateBarcode } from '@kit.ScanKit';
import { promptAction } from '@kit.ArkUI';
import { type BusinessError } from '@kit.BasicServicesKit';
import Logger from './Logger';

const TAG = 'Utils';

export function checkResults(result: scanBarcode.ScanResult[]): boolean {
  if (result === undefined || result === null) {
    return false;
  }
  return true;
}

export function checkResult(result: scanBarcode.ScanResult): boolean {
  if (result === undefined || result === null) {
    return false
  }

  if (result.originalValue === undefined && result.scanType === undefined) {
    return false
  }
  return true;
}

export function getColorType(type: string | undefined): number {
  let color: number = 0x000000;
  switch (type) {
    case 'Black':
      color = 0x000000;
      break;
    case 'Blue':
      color = 0x0000ff;
      break;
    case 'Brown':
      color = 0xa52a2a;
      break;
    case 'Gray':
      color = 0x808080;
      break;
    case 'Green':
      color = 0x008000;
      break;
    case 'Orange':
      color = 0xffa500;
      break;
    case 'Red':
      color = 0xff0000;
      break;
    case 'White':
      color = 0xffffff;
      break;
    case 'Yellow':
      color = 0xffff00;
      break;
    default:
      color = 0x1e1e1e;
      break;
  }
  return color;
}

export function showError(businessError: BusinessError): void {
  try {
    promptAction.showToast({
      message: `Error Code: ${businessError.code} ${businessError.message}`,
      duration: 2000
    });
  } catch (error) {
    Logger.error(TAG, `Catch: showError showToast. Code: ${error.code}.`);
  }
}

export function showMessage(message: Resource): void {
  try {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  } catch (error) {
    Logger.error(TAG, `Catch: showMessage showToast. Code: ${error.code}.`);
  }
}

export function getLevelType(type: string | undefined): generateBarcode.ErrorCorrectionLevel {
  let result: generateBarcode.ErrorCorrectionLevel = generateBarcode.ErrorCorrectionLevel.LEVEL_H;
  switch (type) {
    case 'LEVEL_L':
      result = generateBarcode.ErrorCorrectionLevel.LEVEL_L;
      break;
    case 'LEVEL_M':
      result = generateBarcode.ErrorCorrectionLevel.LEVEL_M;
      break;
    case 'LEVEL_Q':
      result = generateBarcode.ErrorCorrectionLevel.LEVEL_Q;
      break;
    case 'LEVEL_H':
      result = generateBarcode.ErrorCorrectionLevel.LEVEL_H;
      break;
    default:
      result = generateBarcode.ErrorCorrectionLevel.LEVEL_H;
      break;
  }
  return result;
}

export function getTypeNum(type: string | undefined): scanCore.ScanType {
  let result: scanCore.ScanType = scanCore.ScanType.QR_CODE;
  switch (type) {
    case 'AZTEC_CODE':
      result = scanCore.ScanType.AZTEC_CODE;
      break;
    case 'CODABAR_CODE':
      result = scanCore.ScanType.CODABAR_CODE;
      break;
    case 'CODE39_CODE':
      result = scanCore.ScanType.CODE39_CODE;
      break;
    case 'CODE93_CODE':
      result = scanCore.ScanType.CODE93_CODE;
      break;
    case 'CODE128_CODE':
      result = scanCore.ScanType.CODE128_CODE;
      break;
    case 'DATAMATRIX_CODE':
      result = scanCore.ScanType.DATAMATRIX_CODE;
      break;
    case 'EAN8_CODE':
      result = scanCore.ScanType.EAN8_CODE;
      break;
    case 'EAN13_CODE':
      result = scanCore.ScanType.EAN13_CODE;
      break;
    case 'ITF14_CODE':
      result = scanCore.ScanType.ITF14_CODE;
      break;
    case 'PDF417_CODE':
      result = scanCore.ScanType.PDF417_CODE;
      break;
    case 'QR_CODE':
      result = scanCore.ScanType.QR_CODE;
      break;
    case 'UPC_A_CODE':
      result = scanCore.ScanType.UPC_A_CODE;
      break;
    case 'UPC_E_CODE':
      result = scanCore.ScanType.UPC_E_CODE;
      break;
    case 'MULTIFUNCTIONAL_CODE':
      result = scanCore.ScanType.MULTIFUNCTIONAL_CODE;
      break;
    default:
      result = scanCore.ScanType.QR_CODE;
      break;
  }
  return result;
}

/**
 *
 FORMAT_UNKNOWN = 0,
 AZTEC_CODE = 1,
 CODABAR_CODE = 2,
 CODE39_CODE = 3,
 CODE93_CODE = 4,
 CODE128_CODE = 5,
 DATAMATRIX_CODE = 6,
 EAN8_CODE = 7,
 EAN13_CODE = 8,
 ITF14_CODE = 9,
 PDF417_CODE = 10,
 QR_CODE = 11,
 UPC_A_CODE = 12,
 UPC_E_CODE = 13,
 MULTIFUNCTIONAL_CODE = 14,
 ONE_D_CODE = 100,
 TWO_D_CODE = 101,
 */
export function getTypeStr(type: number): string {
  switch (type) {
    case 0:
      return 'FORMAT_UNKNOWN';
    case 1:
      return 'AZTEC_CODE';
    case 2:
      return 'CODABAR_CODE';
    case 3:
      return 'CODE39_CODE';
    case 4:
      return 'CODE93_CODE';
    case 5:
      return 'CODE128_CODE';
    case 6:
      return 'DATAMATRIX_CODE';
    case 7:
      return 'EAN8_CODE';
    case 8:
      return 'EAN13_CODE';
    case 9:
      return 'ITF14_CODE';
    case 10:
      return 'PDF417_CODE';
    case 11:
      return 'QR_CODE';
    case 12:
      return 'UPC_A_CODE';
    case 13:
      return 'UPC_E_CODE';
    case 14:
      return 'MULTIFUNCTIONAL_CODE';
    case 100:
      return 'ONE_D_CODE';
    case 101:
      return 'TWO_D_CODE';
    default:
      return '';
  }
}

export interface WindowSize {
  width: number,
  height: number
}

export function funcDelayer(func: Function, time: number): void {
  let timerId = setTimeout(() => {
    try {
      func();
    } catch (error) {
      Logger.error(TAG, `Failed to execute func in timer. Code: ${error.code}`);
    }
    clearTimeout(timerId);
  }, time);
}