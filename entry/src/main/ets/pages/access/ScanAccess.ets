import { CustomButton } from '../../common/CommonComponents'
import { router } from '@kit.ArkUI'

@Entry
@Component
struct ScanAccess {
  build() {
    Column() {
      Text($r('app.string.welcome_to_access'))
        .id('AccessMessage')
        .fontSize(25)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 50 })
        .textAlign(TextAlign.Center)

      CustomButton({
        mText: $r('app.string.access_integration_process'), mOnClick: () => {
          router.pushUrl({
            url: 'pages/access/ScanDetail'
          })
        }
      })
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}