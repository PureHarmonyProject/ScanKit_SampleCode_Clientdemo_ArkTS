import { customScan } from '@kit.ScanKit';
import { sensor } from '@kit.SensorServiceKit';
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
  .fontColor($r('sys.color.ohos_id_color_primary_contrary'))
  .textAlign(TextAlign.Center)
  .fontFamily('HarmonyHeiTi')
  .height(16)
  .lineHeight(16)
}

@Component
export struct FlashLight {
  @StorageLink('scanFontSizeScale') fontSizeScale: number = AppStorage.get('scanFontSizeScale') as number;
  @State scanService: ScanService = ScanService.getInstance();
  @Link isSensorLight: boolean
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
          CommonConstants.SCAN_FONT_SIZE_SCALE_limit_symbol_text, $r('sys.float.Body_S')))
    }
    .height(CommonConstants.FLASH_HEIGHT)
    .padding({
      top: 3,
      bottom: 3
    })
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.isSensorLight) {
        try {
          if (customScan.getFlashLightStatus()) {
            customScan.closeFlashLight();
          } else {
            customScan.openFlashLight();
          }
          this.scanService.isFlashlight = customScan.getFlashLightStatus();
        } catch (error) {
          Logger.error(TAG, `Failed to set flashLight. Code: ${error.code}`);
        }
      }
    })
  }
}

@Component
export struct ScanBottom {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;
  @State scanService: ScanService = ScanService.getInstance();
  @State isSensorLight: boolean = false; // Whether to display the flashlight.
  @State isAlbumOffset: boolean = false; // When the gallery text is displayed in two lines, the gallery is offset internally.
  @Prop isScanned: boolean = false; // Scanned
  @Prop enableAlbum: boolean = false;
  @Prop @Watch('watchIsOnPageShow') isScanLine: boolean = false;
  @Prop @Watch('watchFoldStatus') foldStatus: number = -1; // - 1: Non-folder, 1: Folder unfold, 2: Folder fold
  marginD: number = ScanSize.getInstance().scanLayout.marginD;
  public openPicker: () => void = () => {
  };

  aboutToAppear() {
    this.createSensor();
  }

  watchFoldStatus() {
    try {
      this.isSensorLight = false;
      this.scanService.isFlashlight = false;
    } catch (error) {
      Logger.error(TAG,
        `Failed to set watchFoldStatus, this.foldStatus is ${this.foldStatus}. Code: ${error.code}`);
    }
  }

  watchIsOnPageShow() {
    if (this.isScanLine) {
      this.createSensor();
    } else {
      this.isSensorLight = false;
      this.scanService.isFlashlight = false;
      try {
        sensor.off(sensor.SensorId.AMBIENT_LIGHT);
      } catch (error) {
        Logger.error(TAG, `Failed to sensor off. Code: ${error.code}`);
      }
    }
  }

  @Builder
  SMBuilder() {
    Column() {
      // flash lamp
      FlashLight({
        isSensorLight: this.isSensorLight,
        isLargeScreen: false
      })
        .margin({
          top: 24,
          bottom: 12 + CommonConstants.PLACEHOLDER_HEIGHT + 2 * this.marginD
        })
        .visibility(this.isSensorLight ? Visibility.Visible : Visibility.Hidden)

      // Picture button area
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
        isSensorLight: this.isSensorLight,
        isLargeScreen: true
      })
        .margin({
          right: new BreakpointType($r('app.float.flash_horizontal_margin_right_sm'),
            $r('app.float.flash_horizontal_margin_right_md'),
            $r('app.float.flash_horizontal_margin_right_lg')).getValue(this.currentBreakpoint)
        })
        .visibility(this.isSensorLight ? Visibility.Visible : Visibility.Hidden)

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

  createSensor() {
    try {
      sensor.on(sensor.SensorId.AMBIENT_LIGHT, (data: sensor.LightResponse) => {
        if (data.intensity < 80) {
          this.isSensorLight = true;
        }
        if (data.intensity > 200) {
          // The flash is not turned on.
          if (!this.scanService.isFlashlight) {
            this.isSensorLight = false;
          }
        }
      }, { interval: 300000000 }); // 0.3s
    } catch (error) {
      Logger.error(TAG, `Failed to create sensor. Code: ${error.code}`);
    }
  }
}
