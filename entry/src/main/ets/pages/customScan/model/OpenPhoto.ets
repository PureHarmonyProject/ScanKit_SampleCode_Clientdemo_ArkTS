import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { detectBarcode, scanBarcode } from '@kit.ScanKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import Logger from '../../../common/Logger';
import { GlobalThisUtil } from '../../../common/GlobalThisUtil';
import { CommonConstants } from '../constants/CommonConstants';

const TAG = 'OpenPhoto';

enum ScanErrorCode {
  SCAN_SUCCEED = 0,
  SCAN_NO_PERMISSION = 201,
  SCAN_INVALID_PARAM = 401,
}

class ScanError implements BusinessError {
  code: number;
  name: string;
  message: string;
  constructor(code: number,  message: string) {
    this.name = 'galleryDecodeResult';
    this.code = code;
    this.message = message;
  }
}

function decodeAlbum(option: scanBarcode.ScanOptions, uri: string,
  callback: AsyncCallback<Array<scanBarcode.ScanResult>>): void {
  GlobalThisUtil.setProperty(CommonConstants.GLOBAL_SCAN_SELECT_A_PICTURE, true);
  // Image recognition parameter. By default, a single barcode is recognized.
  let inputImage: detectBarcode.InputImage = { uri: uri };
  let options: scanBarcode.ScanOptions = {
    scanTypes: option.scanTypes,
    enableMultiMode: false,
    enableAlbum: true
  };
  try {
    detectBarcode.decode(inputImage, options)
      .then((result: Array<scanBarcode.ScanResult>) => {
        // If no value is returned, no processing is performed.
        if (!result || result.length === 0) {
          noResultCallBack(callback);
          return;
        }
        let scanResult: scanBarcode.ScanResult = {
          scanType: result[0].scanType,
          originalValue: result[0].originalValue,
          scanCodeRect: result[0].scanCodeRect
        };
        callback((new ScanError(ScanErrorCode.SCAN_SUCCEED, '')), [scanResult]);
      })
      .catch((error: BusinessError) => {
        Logger.error(TAG, `Failed to detectBarcode. Code: ${error.code}`);
        noResultCallBack(callback);
      });
  } catch (error) {
    Logger.error(TAG, `Failed to detectBarcode.decode. Code: ${error.code}`);
  }
}

function noResultCallBack(callback: AsyncCallback<scanBarcode.ScanResult[]>): void {
  callback((new ScanError(ScanErrorCode.SCAN_INVALID_PARAM, '')), []);
}

export async function openAlbum(option: scanBarcode.ScanOptions, callback: AsyncCallback<Array<scanBarcode.ScanResult>>,
  callBackFn: CallableFunction): Promise<void> {

  try {
    let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    photoSelectOptions.maxSelectNumber = 1;
    photoSelectOptions.isPhotoTakingSupported = false;
    photoSelectOptions.isEditSupported = false;
    let photoPicker = new photoAccessHelper.PhotoViewPicker();

    try {
      await photoPicker.select(photoSelectOptions).then((result: photoAccessHelper.PhotoSelectResult) => {
        callBackFn();
        if (!result || (result.photoUris && result.photoUris.length === 0)) {
          callBackFailed(`Failed to get photoPicker result.`, callback);
          return;
        }
        Logger.info(TAG, `Succeed in getting photoUris. IsOriginalPhoto: ${result.isOriginalPhoto}`);
        let uri = result.photoUris[0];
        decodeAlbum(option, uri, callback);
      });
    } catch (error) {
      callBackFailed(`Failed to select a picture. Code: ${error.code}`, callback);
    }
  } catch (error) {
    callBackFailed(`Failed to get photoPicker. Code: ${error.code}`, callback);
  }
}

function callBackFailed(msg: string, callback: AsyncCallback<Array<scanBarcode.ScanResult>>): void {
  Logger.error(TAG, msg);
  GlobalThisUtil.setProperty(CommonConstants.GLOBAL_SCAN_IS_DECODING_GALLERY, false);
  noResultCallBack(callback);
}