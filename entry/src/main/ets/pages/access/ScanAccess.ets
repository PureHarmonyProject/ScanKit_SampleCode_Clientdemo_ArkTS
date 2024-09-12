import { LengthMetrics, router } from '@kit.ArkUI';
import { CustomButton } from '../../common/CommonComponents';
import { StatusBar } from '../../common/StatusBar';

@Entry
@Component
struct ScanAccess {
  @State translateWidth: number = 1;
  @State translateHeight: number = 1;

  build() {
    RelativeContainer() {
      StatusBar({ isBackToHome: true })

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
      .width('100%')
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Center },
        left: { anchor: '__container__', align: HorizontalAlign.Center }
      })
      .markAnchor({
        top: LengthMetrics.vp(this.translateHeight),
        start: LengthMetrics.vp(this.translateWidth),
      })
      .onAreaChange((_: Area, newArea: Area) => {
        this.translateWidth = Number(newArea.width) / 2;
        this.translateHeight = Number(newArea.height) / 2;
      })
    }
    .width('100%')
    .height('100%')
  }
}