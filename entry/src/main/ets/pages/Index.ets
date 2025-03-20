import { router } from '@kit.ArkUI';
import { CustomButton } from '../common/CommonComponents'

@Entry
@Component
struct Index {
  private scroller: Scroller = new Scroller();

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
        Scroll(this.scroller) {
          Column() {
            CustomButton({
              mText: $r('app.string.default_view_decode'), mOnClick: () => {
                router.pushUrl({
                  url: 'pages/defaultScan/DefaultScan'
                })
              }
            })

            CustomButton({
              mText: $r('app.string.customized_view_decode'), mOnClick: () => {
                router.pushUrl({
                  url: 'pages/customScan/CustomPage'
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
                })
              }
            })
          }
        }
        .width('90%')
        .scrollBar(BarState.Off)
        .scrollable(ScrollDirection.Vertical)
        ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Off })
      }
      .margin({
        top: 50,
        bottom: 10
      })
      .height(250)
    }
    .width('100%')
  }
}