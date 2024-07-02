import { router } from '@kit.ArkUI';
import { CustomButton } from '../../common/CommonComponents'

@Entry
@Component
struct CustomPage {
  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Column() {

        CustomButton({
          mText: $r('app.string.customized_view_decode'), mOnClick: () => {
            router.pushUrl({
              url: 'pages/customScan/CustomScan',
              params: {
                hasOptions: true,
                isCallback: false
              }
            })
          }
        })
        CustomButton({
          mText: $r('app.string.customized_view_decode_frame'), mOnClick: () => {
            router.pushUrl({
              url: "pages/customScan/CustomYuv"
            })
          }
        })
        CustomButton({
          mText: $r('app.string.customized_view_decode_default'), mOnClick: () => {
            router.pushUrl({
              url: "pages/customScanDefault/pages/ScanPage"
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