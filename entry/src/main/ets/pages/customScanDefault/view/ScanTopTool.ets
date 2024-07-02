import { router } from '@kit.ArkUI';
import { BreakpointConstants } from '../constants/BreakpointConstants';
import { BreakpointType } from '../model/BreakpointType';
import Logger from '../../../common/logger';

const TAG = 'ScanTopTool';

@Extend(Image)
function topIcon() {
  .width(40)
  .height(40)
  .objectFit(ImageFit.Contain)
  .responseRegion({
    x: '-50%',
    y: '-50%',
    width: '200%',
    height: '200%'
  })
  .draggable(false)
  .shadow({
    radius: 4,
    type: ShadowType.BLUR,
    color: 'rgba(0,0,0,0.30)',
    offsetX: 0,
    offsetY: 2
  })
}

@Component
export struct ScanTopTool {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @Prop navHeight: number;
  @Prop scanResultSize: number;
  public backToScan: () => void = () => {
  };

  build() {
    Image($rawfile('scan_close.svg')).topIcon()
      .id('scan_page_goBack')
      .onClick(async () => {
        if (this.scanResultSize > 1) {
          Logger.info(TAG, 'Start to backToScan.');
          this.backToScan();
        } else {
          router.back();
        }
      })
      .margin({
        top: this.navHeight + 8,
        left: new BreakpointType($r('app.float.container_horizontal_padding_sm'),
          $r('app.float.container_horizontal_padding_md'),
          $r('app.float.container_horizontal_padding_lg')).getValue(this.currentBreakpoint),
      })
  }
}
