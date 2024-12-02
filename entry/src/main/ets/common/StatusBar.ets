import { LengthMetrics, router } from '@kit.ArkUI';
import { GlobalThisUtil } from './GlobalThisUtil';

@Component
export struct StatusBar {
  @Prop title: string | Resource = '';
  @State sysStatusH: number = 39;
  @Prop isBackToHome: boolean = false;

  aboutToAppear() {
    if (GlobalThisUtil.getProperty('scan_topRect_height')) {
      this.sysStatusH = px2vp(GlobalThisUtil.getProperty('scan_topRect_height'));
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
        .margin({ start: LengthMetrics.vp(15) })
    }
    .margin({ start: LengthMetrics.vp(16) })
    .zIndex(10)
    .position({ start: LengthMetrics.vp(15) })
    .onClick(async () => {
      if (this.isBackToHome) {
        router.clear();
        router.replaceUrl({
          url: 'pages/Index'
        });
      } else {
        router.back();
      }
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