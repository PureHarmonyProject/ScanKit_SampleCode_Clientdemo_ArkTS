@Extend(Text)
function textHead() {
  .width('100%')
  .fontSize(20)
  .fontWeight(FontWeight.Bold)
  .fontColor('#000000')
  .textAlign(TextAlign.Center)
  .margin({ top: 50 })
}

@Extend(Text)
function text() {
  .width('100%')
  .textAlign(TextAlign.Start)
  .fontSize(14)
  .lineHeight(20)
}

@Extend(Text)
function textTitle() {
  .width('100%')
  .textAlign(TextAlign.Start)
  .fontSize(16)
  .fontWeight(FontWeight.Bold)
  .margin({ top: 20 })
}

@Entry
@Component
struct ScanDetail {
  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start, justifyContent: FlexAlign.Start }) {

      Text($r('app.string.access_detail_title')).textHead()

      Column() {

        Text($r('app.string.access_detail_info_f'))
          .text()
        Text($r('app.string.access_detail_info_t'))
          .text()

        Text($r('app.string.access_detail_example')).textTitle()
        Text($r('app.string.access_detail_example_f')).text()
        Text($r('app.string.access_detail_example_t'))
          .text()

        Text($r('app.string.access_detail_procedure')).textTitle()
        Text($r('app.string.access_detail_procedure1')).text()
        Text($r('app.string.access_detail_procedure2'))
          .text()
        Text($r('app.string.access_detail_procedure3')).text()
        Text($r('app.string.access_detail_procedure4')).text()

        Text($r('app.string.access_detail_th')).text().margin({ top: 20 }).textAlign(TextAlign.Center)
        Image($rawfile('access.jpg'))
          .height(150)

      }
      .margin(10)

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0a000000')
  }
}