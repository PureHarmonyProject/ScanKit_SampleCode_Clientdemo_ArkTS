import { BreakpointConstants } from '../constants/BreakpointConstants';
import { CommonConstants } from '../constants/CommonConstants';
import { BreakpointType } from '../model/BreakpointType';
import { FontSizeScale } from '../model/FontSizeScale';

@Extend(LoadingProgress)
function loadingIcon() {
  .color($r('sys.color.ohos_id_color_progress'))
  .width(72)
  .height(72)
}

@Extend(Text)
function loadingText() {
  .fontFamily('HarmonyHeiTi')
  .fontSize($r('sys.float.Body_M'))
  .fontWeight(FontWeight.Regular)
  .textAlign(TextAlign.Center)
  .fontColor($r('sys.color.ohos_id_color_text_secondary_dark'))
  .lineHeight(19)
  .margin({
    top: 16
  })
}

@Component
export struct ScanLoading {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @StorageLink('scanFontSizeScale') fontSizeScale: number = 1;

  build() {
    Column() {
      Column() {
        LoadingProgress().loadingIcon()
        Text($r('app.string.Scan_album_loading')).loadingText()
          .fontSize(FontSizeScale.getLimitFontSize(this.fontSizeScale,
            CommonConstants.SCAN_FONT_SIZE_SCALE_LIMIT_SYMBOL_TEXT, $r('sys.float.Body_M')))
      }
      .height(new BreakpointType(BreakpointConstants.LOADING_HEIGHT_SM,
        BreakpointConstants.LOADING_HEIGHT_MD, BreakpointConstants.LOADING_HEIGHT_LG).getValue(this.currentBreakpoint))
      .offset({
        y: -36
      })
    }
    .justifyContent(FlexAlign.End)
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}