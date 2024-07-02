import { BreakpointConstants } from '../constants/BreakpointConstants';
import { BreakpointType } from '../model/BreakpointType';

@Extend(LoadingProgress)
function loadingIcon() {
  .color($r('sys.color.ohos_id_color_progress'))
  .width(72)
  .height(72)
}

@Extend(Text)
function loadingText() {
  .fontFamily('HarmonyHeiTi')
  .fontSize($r('sys.float.ohos_id_text_size_body2'))
  .fontWeight(FontWeight.Regular)
  .textAlign(TextAlign.Center)
  .fontColor($r('sys.color.ohos_id_color_text_secondary_dark'))
  .fontSize(14)
  .lineHeight(19)
  .margin({
    top: 16
  })
}

@Component
export struct ScanLoading {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;

  build() {
    Column() {
      Column() {
        LoadingProgress().loadingIcon()
        Text($r('app.string.Scan_album_loading')).loadingText()
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