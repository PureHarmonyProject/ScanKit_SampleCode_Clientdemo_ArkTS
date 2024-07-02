import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { detectBarcode, scanBarcode } from '@kit.ScanKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import Logger from '../../../common/logger';
import { GlobalThisUtil } from '../../../common/GlobalThisUtil';

const TAG = 'openPhoto';

enum ScanErrorCode {
  SCAN_SUCCEED = 0,
  SCAN_NO_PERMISSION = 201,
  SCAN_INVALID_PARAM = 401,
}

class ScanError extends Error {
  code: ScanErrorCode;

  constructor(code: ScanErrorCode, message: string) {
    super(message);
    this.code = code;
  }
}

function decodeAlbum(option: scanBarcode.ScanOptions, uri: string, callback: AsyncCallback<Array<scanBarcode.ScanResult>>): void {
  GlobalThisUtil.setProperty('hmsCore_scan_pickerUri', uri);
  // Image recognition parameters. The default value is Single Code.
  let inputImage: detectBarcode.InputImage = { uri: uri };
  let options: scanBarcode.ScanOptions = {
    scanTypes: option.scanTypes,
    enableMultiMode: false,
    enableAlbum: option.enableAlbum ? true : false
  };
  detectBarcode.decode(inputImage, options)
    .then((result: Array<scanBarcode.ScanResult>) => {
      // If no value is identified, the system returns without assigning a value.
      if (!result || result.length === 0) {
        noResultCallBack(callback);
        return;
      }
      let scanResult: scanBarcode.ScanResult = {
        scanType: result[0].scanType,
        originalValue: result[0].originalValue,
        scanCodeRect: result[0].scanCodeRect
      };
      callback((new ScanError(ScanErrorCode.SCAN_SUCCEED, "")), [scanResult]);
    })
    .catch((error: BusinessError) => {
      Logger.error(TAG, `Failed to detectBarcode. Code: ${error.code}, message: ${error.message}`);
      noResultCallBack(callback);
    });
}

function noResultCallBack(callback: AsyncCallback<scanBarcode.ScanResult[]>): void {
  callback((new ScanError(ScanErrorCode.SCAN_INVALID_PARAM, "")), []);
}

export async function openAlbum(option: scanBarcode.ScanOptions, callback: AsyncCallback<Array<scanBarcode.ScanResult>>, callBackFn: CallableFunction): Promise<void> {

  try {
    let PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    PhotoSelectOptions.maxSelectNumber = 1;
    PhotoSelectOptions.isPhotoTakingSupported = false;
    PhotoSelectOptions.isEditSupported = false;
    let photoPicker = new photoAccessHelper.PhotoViewPicker();

    try {
      await photoPicker.select(PhotoSelectOptions).then((result: photoAccessHelper.PhotoSelectResult) => {
        callBackFn();
        if (!result || (result.photoUris && result.photoUris.length === 0) ) {
          Logger.info(TAG, `Failed to get photoUris. IsOriginalPhoto: ${result.isOriginalPhoto}`);
          GlobalThisUtil.setProperty('hmsCore_scan_isPickerDecode', false);
          noResultCallBack(callback);
          return;
        }
        let uri = result.photoUris[0];
        try {
          decodeAlbum(option, uri, callback);
        } catch (error) {
          Logger.error(TAG, `Failed to decodeAlbum. Code: ${error.code}, message: ${error.message}`);
          GlobalThisUtil.setProperty('hmsCore_scan_isPickerDecode', false);
          noResultCallBack(callback);
        }
      });
    } catch (error) {
      Logger.error(TAG, `Failed to select a picture. Code: ${error.code}, message: ${error.message}`);
      GlobalThisUtil.setProperty('hmsCore_scan_isPickerDecode', false);
      noResultCallBack(callback);
    }
  } catch (error) {
    Logger.error(TAG, `Failed to get photoPicker. Code: ${error.code}, message: ${error.message}`);
    GlobalThisUtil.setProperty('hmsCore_scan_isPickerDecode', false);
    noResultCallBack(callback);
  }
}