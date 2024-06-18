import { router } from '@kit.ArkUI';
import { GlobalThisUtil } from './GlobalThisUtil';

export class routerParams {
  title: string

  constructor(str: string) {
    this.title = str
  }
}

@Component
export struct StatusBar {
  @Prop title: string | Resource = ''
  @State sysStatusH: number = 39

  aboutToAppear() {
    if (GlobalThisUtil.getProperty('getStatusHeight')) {
      this.sysStatusH = px2vp(GlobalThisUtil.getProperty('getStatusHeight'))
    }
  }

  build() {
    Row() {
      Image($rawfile('scan_back.svg'))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .responseRegion({
          x: '-50%',
          y: '-50%',
          width: '200%',
          height: '200%'
        })
        .draggable(false)
        .fillColor(Color.Black)
      Text(this.title)
        .fontSize(20)
        .fontColor('#000000')
        .margin({ left: 15 })
    }
    .margin({ left: 16 })
    .zIndex(10)
    .position({ x: 15, y: 0 })
    .onClick(async () => {
      router.back();
    })
    .height(56 + this.sysStatusH)
    .width('100%')
    .alignRules({
      top: { anchor: '__container__', align: VerticalAlign.Top },
      left: { anchor: '__container__', align: HorizontalAlign.Start }
    })
    .id('statusBar')
  }
}