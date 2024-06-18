import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { showError, checkResult } from '../common/Utils';
import { CustomButton } from '../common/CommonComponents'

const TAG = 'Scan SampleCode Index';

@Entry
@Component
struct Index {
  @StorageLink('windowWidthPx') windowWidth: number = 1;
  @State options: scanBarcode.ScanOptions = {
    scanTypes: [scanCore.ScanType.ALL],
    enableMultiMode: true,
    enableAlbum: true
  };

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text($r('app.string.demo_title'))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#000000')

      Column() {
        Text($r('app.string.demo_subject'))
          .margin({
            top: 24,
          })
          .fontSize(24)
          .textAlign(TextAlign.Center)
          .fontColor('#000000')
        Text($r('app.string.demo_detail'))
          .margin({
            top: 16,
            left: 24,
            right: 24,
            bottom: 20,
          })
          .fontSize(18)
          .fontColor('#99000000')
      }
      .backgroundColor('#0a000000')
      .borderRadius(12)
      .margin({
        top: 45,
        bottom: 20,
        right: 20,
        left: 20
      })

      Column() {
        CustomButton({
          mText: $r('app.string.default_view_decoe'), mOnClick: () => {
            try {
              scanBarcode.startScanForResult(getContext(this), this.options).then((result: scanBarcode.ScanResult) => {
                if (!checkResult(result)) {
                  return
                }
                hilog.info(0x0001, TAG, 'Promise scan result: %{public}s', JSON.stringify(result));
                router.pushUrl({
                  url: 'pages/resultPage/ResultPage',
                  params: {
                    originalValue: result.originalValue,
                    scanType: result.scanType
                  }
                })
              }).catch((failResult: Error) => {
                hilog.error(0x0001, TAG, 'Promise error: %{public}s', JSON.stringify(failResult));
              });
            } catch (error) {
              hilog.error(0x0001, TAG, 'failReason: %{public}s', JSON.stringify(error));
              showError(error);
            }
          }
        })
        CustomButton({
          mText: $r('app.string.customized_view_decode'), mOnClick: () => {
            router.pushUrl({
              url: 'pages/customScan/CustomPage',
              params: {
                hasOptions: true,
                isCallback: false
              }
            })
          }
        })
        CustomButton({
          mText: $r('app.string.bitmap_api_decode'), mOnClick: () => {
            router.pushUrl({
              url: "pages/detectBarcode/DecodeBarcode"
            })
          }
        })

        CustomButton({
          mText: $r('app.string.generate_QR_code'), mOnClick: () => {
            router.pushUrl({
              url: 'pages/generateBarcode/CreateBarcode',
              params: {
                title: $r('app.string.generate_QR_code')
              }
            })
          }
        })
      }.margin({
        top: 50,
        bottom: 50
      })
    }
    .width('100%')
  }
}