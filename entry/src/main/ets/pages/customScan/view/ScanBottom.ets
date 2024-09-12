import { customScan } from '@kit.ScanKit';
import { IconPress } from './IconPress'
import Logger from '../../../common/Logger';
import { BreakpointConstants } from '../constants/BreakpointConstants';
import { CommonConstants } from '../constants/CommonConstants';
import { ScanSize } from '../model/ScanSize';
import { BreakpointType } from '../model/BreakpointType';
import { ScanService } from '../model/ScanService';
import { FontSizeScale } from '../model/FontSizeScale';

const TAG: string = 'ScanBottom';

@Extend(Column)
function componentColumnContainer(currentBreakpoint: string) {
  .width('100%')
  .height('100%')
  .alignItems(HorizontalAlign.Center)
  .justifyContent(FlexAlign.End)
  .padding({
    left: new BreakpointType($r('app.float.container_horizontal_padding_sm'),
      $r('app.float.container_horizontal_padding_md'),
      $r('app.float.container_horizontal_padding_lg')).getValue(currentBreakpoint),
    right: new BreakpointType($r('app.float.container_horizontal_padding_sm'),
      $r('app.float.container_horizontal_padding_md'),
      $r('app.float.container_horizontal_padding_lg')).getValue(currentBreakpoint)
  })
}

@Extend(Row)
function componentRowContainer(currentBreakpoint: string) {
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.End)
  .alignItems(VerticalAlign.Center)
  .padding({
    left: new BreakpointType($r('app.float.container_horizontal_padding_sm'),
      $r('app.float.container_horizontal_padding_md'),
      $r('app.float.container_horizontal_padding_lg')).getValue(currentBreakpoint),
    right: new BreakpointType($r('app.float.container_horizontal_padding_sm'),
      $r('app.float.container_horizontal_padding_md'),
      $r('app.float.container_horizontal_padding_lg')).getValue(currentBreakpoint)
  })
}

@Extend(SymbolGlyph)
function lightIcon() {
  .fontColor([$r('sys.color.font_on_primary')])
  .fontWeight(FontWeight.Regular)
  .fontSize('24vp')
}

@Extend(Text)
function lightText() {
  .fontColor($r('sys.color.icon_on_primary'))
  .textAlign(TextAlign.Center)
  .fontFamily('HarmonyHeiTi')
  .height(16)
  .lineHeight(16)
}

@Component
export struct FlashLight {
  @StorageLink('scanFontSizeScale') fontSizeScale: number = 1;
  @State scanService: ScanService = ScanService.getInstance();
  @Prop isLargeScreen: boolean

  build() {
    Column() {
      SymbolGlyph(this.scanService.isFlashlight ? $r('sys.symbol.flashlight_on') : $r('sys.symbol.flashlight_off'))
        .lightIcon()
        .margin({ bottom: 6 })
        .stateStyles({
          pressed: {
            .opacity(0.4)
          },
          normal: {
            .opacity(1)
          }
        })
      Text(this.scanService.isFlashlight ? $r('app.string.Scan_light_to_off') : $r('app.string.Scan_light_to_on'))
        .lightText()
        .fontSize(FontSizeScale.getLimitFontSize(this.fontSizeScale,
          CommonConstants.SCAN_FONT_SIZE_SCALE_LIMIT_SYMBOL_TEXT, $r('sys.float.Body_S')))
    }
    .height(CommonConstants.FLASH_HEIGHT)
    .padding({
      top: 3,
      bottom: 3
    })
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.scanService.changeFlashlight();
    })
  }
}

@Component
export struct ScanBottom {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;
  @State scanService: ScanService = ScanService.getInstance();
  @State isAlbumOffset: boolean =
    false; // When the gallery text is displayed between two lines, the gallery is internally offset.
  @Prop isScanned: boolean = false; // Scanning result.
  @Prop enableAlbum: boolean = false;
  marginD: number = ScanSize.getInstance().scanLayout.marginD;
  public openPicker: () => void = () => {
  };

  @Builder
  SMBuilder() {
    Column() {
      // Flash light.
      FlashLight({
        isLargeScreen: false
      })
        .margin({
          top: 24,
          bottom: 12 + CommonConstants.PLACEHOLDER_HEIGHT + 2 * this.marginD
        })
        .visibility(this.scanService.isFlashlight || this.scanService.isSensorLight ? Visibility.Visible :
        Visibility.Hidden) // Determine whether to turn on the flash light based on the light conditions, light change, and whether the flash light is already on.

      // Image button area.
      Row() {
        if (this.enableAlbum) {
          IconPress({
            url: $r('sys.symbol.picture'),
            text: $r('app.string.Scan_gallery'),
            iconId: 'scan_page_openPicker',
            isAlbumOffset: this.isAlbumOffset,
            imageClick: (() => {
              this.openPicker();
            })
          })
        }
      }
      .height(CommonConstants.ICON_PRESS_HEIGHT)
      .width('100%')
      .margin({
        bottom: CommonConstants.TAB_BAR_HEIGHT + CommonConstants.AI_BOTTOM_BAR_HEIGHT
      })
      .justifyContent(FlexAlign.Center)
    }
    .componentColumnContainer(this.currentBreakpoint)
  }

  @Builder
  NotSMBuilder() {
    Row() {
      FlashLight({
        isLargeScreen: true
      })
        .margin({
          right: new BreakpointType($r('app.float.flash_horizontal_margin_right_sm'),
            $r('app.float.flash_horizontal_margin_right_md'),
            $r('app.float.flash_horizontal_margin_right_lg')).getValue(this.currentBreakpoint)
        })
        .visibility(this.scanService.isFlashlight || this.scanService.isSensorLight ? Visibility.Visible :
        Visibility.Hidden) // Determine whether to turn on the flash light based on the light conditions, light change, and whether the flash light is already on.

      Column() {
        if (this.enableAlbum) {
          IconPress({
            url: $r('sys.symbol.picture'),
            text: $r('app.string.Scan_gallery'),
            iconId: 'scan_page_openPicker',
            isAlbumOffset: this.isAlbumOffset,
            imageClick: (() => {
              this.openPicker();
            })
          })
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .width(new BreakpointType($r('app.float.icon_container_horizontal_width_sm'),
        $r('app.float.icon_container_horizontal_width_md'),
        $r('app.float.icon_container_horizontal_width_lg')).getValue(this.currentBreakpoint))
    }
    .componentRowContainer(this.currentBreakpoint)
  }

  build() {
    if (this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM) {
      this.SMBuilder()
    } else {
      this.NotSMBuilder()
    }
  }
}
