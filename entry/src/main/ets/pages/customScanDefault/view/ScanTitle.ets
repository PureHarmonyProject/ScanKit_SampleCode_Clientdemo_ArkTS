import { BreakpointConstants } from '../constants/BreakpointConstants';
import { CommonConstants } from '../constants/CommonConstants';
import { BreakpointType } from '../model/BreakpointType';
import { ScanService } from '../model/ScanService';

/**
 * @param fontSize
 * @param color
 * @param fontWeight
 */
@Extend(Text)
function scanTitle(fontSize: ResourceColor, color: ResourceColor, fontWeight: FontWeight) {
  .width('100%')
  .fontSize(fontSize)
  .textAlign(TextAlign.Center)
  .fontFamily('HarmonyHeiTi')
  .fontWeight(fontWeight)
  .fontColor(color)
  .constraintSize({
    maxWidth: 460
  })
  .maxLines(2)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .textShadow({
    radius: 4,
    type: ShadowType.BLUR,
    color: 'rgba(0,0,0,0.30)',
    offsetX: 0,
    offsetY: 2
  })
}

@Component
export struct ScanTitle {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @State scanService: ScanService = ScanService.getInstance();
  @Prop scanResultSize: number = 0
  @Prop navHeight: number

  build() {
    Column() {
      Text(this.scanResultSize > 1 ? $r('app.string.Scan_barcode_tips_callback') : $r('app.string.Scan_barcode'))
        .scanTitle($r('sys.float.ohos_id_text_size_headline9'), $r('sys.color.ohos_id_color_primary_contrary'),
          FontWeight.Regular)
        .lineHeight(CommonConstants.TITLE_MAIN_LINE_HEIGHT)
    }
    .alignItems(HorizontalAlign.Center)
    .margin({
      top: this.navHeight + CommonConstants.TOP_BUTTON_HEIGHT + CommonConstants.TITLE_MARGIN_TOP,
      bottom: CommonConstants.SCAN_LINE_MARGIN
    })
    .padding({
      left: new BreakpointType($r('app.float.container_horizontal_padding_sm'),
        $r('app.float.container_horizontal_padding_md'),
        $r('app.float.container_horizontal_padding_lg')).getValue(this.currentBreakpoint),
      right: new BreakpointType($r('app.float.container_horizontal_padding_sm'),
        $r('app.float.container_horizontal_padding_md'),
        $r('app.float.container_horizontal_padding_lg')).getValue(this.currentBreakpoint)
    })
    .width('100%')
  }
}