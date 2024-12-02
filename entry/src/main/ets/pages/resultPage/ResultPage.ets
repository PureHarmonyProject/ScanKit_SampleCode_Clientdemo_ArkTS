import { LengthMetrics, router } from '@kit.ArkUI';
import { scanBarcode } from '@kit.ScanKit';
import { StatusBar } from '../../common/StatusBar';
import { getScanTypeKey } from '../../common/Utils'

@Extend(Text)
function labelText() {
  .fontSize(20)
  .textAlign(TextAlign.Start)
  .fontColor('#000000')
}

@Extend(Text)
function valueText() {
  .margin({
    top: 4,
  })
  .fontSize(16)
  .textAlign(TextAlign.Start)
  .fontColor('#99000000')
}

@Entry
@Component
struct ResultPage {
  @State translateWidth: number = 1;
  @State translateHeight: number = 1;
  @State result: scanBarcode.ScanResult = router.getParams() as scanBarcode.ScanResult
  @StorageLink('windowWidthPx') windowWidth: number = 1;

  build() {
    RelativeContainer() {
      StatusBar({ title: $r('app.string.result_content') })

      Column() {
        Column() {
          Text($r('app.string.code_format'))
            .labelText()
          Text(getScanTypeKey(this.result.scanType))
            .valueText()

          Text($r('app.string.result_content'))
            .margin({
              top: 18,
            })
            .labelText()
          Text(this.result.originalValue)
            .valueText()

          if (this.result.scanCodeRect) {
            Text($r('app.string.code_react'))
              .margin({
                top: 18,
              })
              .labelText()
            Text('left: ' + (this.result.scanCodeRect?.left || 0) + '  top: ' + (this.result.scanCodeRect?.top || 0) +
              '  right: ' + (this.result.scanCodeRect?.right || 0) + '  bottom: ' +
              (this.result.scanCodeRect?.bottom || 0))
              .valueText()
          }

        }
        .backgroundColor('#0a000000')
        .borderRadius(12)
        .width(px2vp(this.windowWidth) <= 480 ? '85%' : '60%')
        .alignItems(HorizontalAlign.Start)
        .padding(24)
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Center },
        left: { anchor: '__container__', align: HorizontalAlign.Center }
      })
      .markAnchor({
        top: LengthMetrics.vp(this.translateHeight),
        start: LengthMetrics.vp(this.translateWidth),
      })
      .onSizeChange((_: SizeOptions, newValue: SizeOptions) => {
        if (newValue && typeof newValue.width === 'number' && typeof newValue.height === 'number') {
          this.translateWidth = newValue.width / 2;
          this.translateHeight = newValue.height / 2;
        }
      })
      .id('columnResultPage')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('white')
  }
}