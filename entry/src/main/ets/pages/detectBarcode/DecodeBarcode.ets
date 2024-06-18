import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction, router } from '@kit.ArkUI';
import { detectBarcode, scanBarcode, scanCore } from '@kit.ScanKit';
import { CustomButton } from '../../common/CommonComponents';
import { checkResults } from '../../common/Utils';

const TAG: string = 'Scan SampleCode DecodeBarcode';

@Entry
@Component
struct DecodeBarcode {
  @StorageLink('windowWidthPx') windowWidth: number = 1;
  // Defines the identification code parameter options.
  @State options: scanBarcode.ScanOptions = {
    scanTypes: [scanCore.ScanType.ALL],
    enableMultiMode: true,
    enableAlbum: true
  };

  build() {
    Column() {
      CustomButton({
        mText: $r('app.string.bitmap_api_decode_image'), mOnClick: () => {
          try {
            let photoOption = new photoAccessHelper.PhotoSelectOptions();
            photoOption.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
            photoOption.maxSelectNumber = 1;
            photoOption.isEditSupported = false;
            let photoPicker = new photoAccessHelper.PhotoViewPicker();

            photoPicker.select(photoOption).then((photoResult) => {
              hilog.info(0x0001, TAG, 'photoResult: %{public}s', JSON.stringify(photoResult));
              let infoW: number = 0;
              let infoH: number = 0;
              if (photoResult.photoUris[0].length > 0) {
                try {
                  let file = fileIo.openSync(photoResult.photoUris[0], fileIo.OpenMode.READ_ONLY);
                  const imageSourceApi = image.createImageSource(file.fd);
                  imageSourceApi.getImageInfo(0, (error: BusinessError, imageInfo) => {
                    if (imageInfo == undefined) {
                      hilog.error(0x0001, TAG, 'Failed to obtain the image pixel map information. error: %{public}s',
                        JSON.stringify(error));
                      return;
                    }
                    hilog.info(0x0001, TAG, 'imageInfo: %{public}s', JSON.stringify(typeof imageInfo));
                    hilog.info(0x0001, TAG, 'imageInfo: %{public}s', JSON.stringify(imageInfo));
                    infoW = imageInfo.size.width;
                    infoH = imageInfo.size.height;
                  })
                } catch (error) {
                  hilog.error(0x0001, TAG, 'Promise options Error: %{public}s', JSON.stringify(error));
                  return;
                }
              } else {
                return;
              }

              try {
                let inputImage: detectBarcode.InputImage = { uri: photoResult.photoUris[0] };
                detectBarcode.decode(inputImage, this.options).then((result: Array<scanBarcode.ScanResult>) => {
                  if (!checkResults(result)) {
                    return;
                  }
                  hilog.info(0x0001, TAG, "Promise scan result: %{public}s", JSON.stringify(result));
                  if (result && result.length > 0) {
                    router.pushUrl({
                      url: 'pages/detectBarcode/CommonCodeLayout',
                      params: {
                        result: result,
                        uri: photoResult.photoUris[0],
                        infoW: infoW,
                        infoH: infoH
                      }
                    })
                  } else {
                    promptAction.showToast({
                      message: $r('app.string.Scan_diaLog_not_found'),
                      duration: 2000
                    });
                  }
                }).catch((failResult: BusinessError) => {
                  if (photoResult.photoUris[0]) {
                    promptAction.showToast({
                      message: $r('app.string.Scan_diaLog_not_found'),
                      duration: 2000
                    });
                    hilog.error(0x0001, TAG, 'Promise scan result: %{public}s', JSON.stringify(failResult));
                  }
                });
              } catch (error) {
                hilog.error(0x0001, TAG, 'Catch: failResult: %{public}s', JSON.stringify(error));
              }

            })
          } catch (error) {
            hilog.error(0x0001, TAG, 'error: %{public}s', JSON.stringify(error));
          }
        }
      })

      CustomButton({
        mText: $r('app.string.bitmap_api_decode_pixel'), mOnClick: () => {
          router.pushUrl({
            url: 'pages/detectBarcode/DecodeCameraYuv',
            params: {
              title: $r('app.string.bitmap_api_decode_pixel')
            }
          })
        }
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignSelf(ItemAlign.Center)
  }
}
