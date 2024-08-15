import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { CustomButton } from '../../common/CommonComponents';
import { checkResult, showError } from '../../common/Utils';

const TAG = 'Default Scan';

@Entry
@Component
struct CustomPage {
  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Column() {
        CustomButton({
          mText: $r('app.string.default_view_decode'), mOnClick: () => {
            try {
              scanBarcode.startScanForResult(getContext(this), {
                scanTypes: [scanCore.ScanType.ALL],
                enableMultiMode: true,
                enableAlbum: true
              }).then((result: scanBarcode.ScanResult) => {
                if (!checkResult(result)) {
                  return;
                }
                hilog.info(0x0001, TAG, 'Promise scan result: %{public}s', JSON.stringify(result));
                router.pushUrl({
                  url: 'pages/resultPage/ResultPage',
                  params: {
                    originalValue: result.originalValue,
                    scanType: result.scanType
                  }
                })
              }).catch((error: BusinessError) => {
                if (error.code == scanCore.ScanErrorCode.SCAN_SERVICE_CANCELED) {
                  hilog.info(0x0001, TAG, `Disabling the Scanning Service.`);
                } else {
                  hilog.error(0x0001, TAG,
                    `Failed to start the scanning service. Code: ${error.code}, message: ${error.message}.`);
                }
              });
            } catch (error) {
              hilog.error(0x0001, TAG,
                `Failed to start the scanning service. Code: ${error.code}, message: ${error.message}.`);
              showError(error);
            }
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