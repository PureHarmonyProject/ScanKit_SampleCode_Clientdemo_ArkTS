import { display, LengthMetrics, router } from '@kit.ArkUI';
import { customScan, scanBarcode, scanCore } from '@kit.ScanKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { AsyncCallback, BusinessError, emitter } from '@kit.BasicServicesKit';
import Logger from '../../../common/Logger';
import { ScanLine } from '../view/ScanLine';
import { ScanBottom } from '../view/ScanBottom';
import { CodeLayout } from '../view/CommonCodeLayout';
import { ScanTitle } from '../view/ScanTitle';
import { PromptTone } from '../model/PromptTone';
import { openAlbum } from '../model/OpenPhoto';
import { CommonConstants } from '../constants/CommonConstants'
import { MaskLayer } from '../view/MaskLayer';
import { ScanService, ScanResults, ScanStatus } from '../model/ScanService';
import { BreakpointConstants } from '../constants/BreakpointConstants';
import { ScanXComponent } from '../view/ScanXComponent';
import { ScanLoading } from '../view/ScanLoading';
import { PermissionsUtil } from '../../../common/PermissionsUtil';
import { CommonTipsDialog } from '../../../common/CommonTipsDialog';
import { DeviceService } from '../model/DeviceService';
import { WindowService } from '../model/WindowService';
import { FoldStatus, XComponentService } from '../model/XComponentService';
import { ScanLayout } from '../model/ScanLayout';
import { BREAK_POINT_TYPE_MARGIN_VP } from '../model/BreakpointType';

const TAG = 'ScanPage';

let storage = LocalStorage.getShared();
let timerId: number | null;

@Extend(Row)
function tipContainer() {
  .margin({
    top: 16
  })
  .padding(8)
  .backgroundColor($r('sys.color.ohos_id_blur_style_component_ultra_thick_color'))
  .borderRadius($r('sys.float.corner_radius_level10'))
}

@Entry(storage)
@Component
struct ScanPage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @State tipShow: boolean = false; // Determine whether to display the message indicating that no barcode is recognized.
  @State xComponentService: XComponentService = XComponentService.getInstance();
  @State foldStatus: FoldStatus = this.xComponentService.foldStatus;
  @State windowService: WindowService = WindowService.getInstance();
  @State scanLayout: ScanLayout = ScanLayout.getInstance();
  @State scanService: ScanService = ScanService.getInstance();
  @State scanResult: ScanResults = this.scanService.scanResult;
  @State surfaceId: string = '';
  @State densityDPI: number = 0; // Pixel density.
  @State viewControl: customScan.ViewControl = {
    width: this.xComponentService.width,
    height: this.xComponentService.height,
    surfaceId: ''
  };
  @State isDialogShow: boolean = false;
  @State userGrant: boolean = false; // Check whether the camera permission is granted.
  options: scanBarcode.ScanOptions = {
    scanTypes: [scanCore.ScanType.ALL],
    enableMultiMode: true,
    enableAlbum: true
  };
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CommonTipsDialog({
      isDialogShow: this.isDialogShow
    }),
    autoCancel: false,
    customStyle: false,
    alignment: DialogAlignment.Center
  });
  public avPlayer: PromptTone | null = null; // Audio notification after successful barcode scanning.
  photoPickerCallback: AsyncCallback<scanBarcode.ScanResult[]> =
    async (error: BusinessError, result: scanBarcode.ScanResult[]) => {
      Logger.info(TAG,
        `photoPickerCallback start. Code: ${error.code}, message: ${error.message},scanStatus: ${this.scanService.scanStatus}`);
      if (this.scanService.scanStatus === ScanStatus.NO_PHOTO_SELECT) {
        this.startCustomScan();
      } else {
        // ScanStatus: PHOTO_DECODING_COMPLETED
        this.scanService.isAlbumLoading = true;
        this.handleDecodeResult(error, result);
        this.scanService.updateScanStatus(ScanStatus.PHOTO_DECODING_COMPLETED);
      }
    }
  customScanCallback: AsyncCallback<scanBarcode.ScanResult[]> =
    async (error: BusinessError, result: scanBarcode.ScanResult[]) => {
      if (this.scanService.retryOnCondition(error, this.options, this.viewControl, this.customScanCallback)) {
        return;
      }
      if (this.scanService.scanStatus === ScanStatus.PREVIEW_DECODING) {
        this.handleDecodeResult(error, result);
        if (this.scanResult.size > 0) {
          this.scanService.stopPreviewStream();
          Logger.info(TAG, `customScanCallback, scanStatus: ${this.scanService.scanStatus}`);
          this.scanService.updateScanStatus(ScanStatus.PREVIEW_DECODING_COMPLETED);
          this.clearTimer();
        }
      }
    }

  aboutToAppear() {
    Logger.info(TAG, 'aboutToAppear.');
    if (DeviceService.isFolding) {
      this.foldStatus.newFoldStatus = DeviceService.getFoldStatusByDisplay();
      this.foldStatus.oldFoldStatus = this.foldStatus.newFoldStatus;
      // Foldable screen status listener.
      this.foldStatusSubscribe();
    }

    // Window size listener.
    this.windowSizeSubscribe();

    // Pixel density listener.
    this.onDisplayChange();

    // Screen event listener.
    this.onScreenEvent();

    this.windowService.enterCustomScanPage();
  }

  async onPageShow(): Promise<void> {
    Logger.info(TAG, 'onPageShow.');
    await this.empowerment();
  }

  onPageHide(): void {
    Logger.info(TAG, 'onPageHide.');
    this.scanService.stopPreviewStream();
    this.scanService.updateScanStatus(ScanStatus.FORBIDDEN);
    this.clearTimer();
    this.userGrant = false;
    this.isDialogShow = false;
    this.dialogController.close();
  }

  async aboutToDisappear(): Promise<void> {
    Logger.info(TAG, 'aboutToDisappear.');
    try {
      emitter.off(CommonConstants.WINDOW_SIZE_CHANGE);
      if (DeviceService.isFolding) {
        display.off('foldStatusChange');
      }
    } catch (error) {
      Logger.error(TAG, `listener off catch error. Code: ${error.code}`);
    }
    this.offDisplayChange();
    this.offScreenEvent();
    this.windowService.leaveCustomScanPage();
  }

  @Builder
  BackgroundBuilder() {
    ScanXComponent({
      surfaceId: this.surfaceId,
      startCustomScan: (() => {
        this.startCustomScan();
      })
    }).height('100%')
      .width('100%')
      .position({ x: 0, y: 0 })

    // Loading animation before redirection from gallery-based barcode image recognition.
    if (this.scanService.isAlbumLoading) {
      ScanLoading()
    }
  }

  @Builder
  ScanTitleBuilder() {
    // Scan title.
    Column() {
      ScanTitle({
        scanResultSize: this.scanResult.size,
      }).width('100%')
      if (this.tipShow) {
        Row() {
          Text($r('app.string.Scan_diaLog_not_found'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontFamily('HarmonyHeiTi')
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .tipContainer()
      }
    }
  }

  @Builder
  ScanLineBuilder() {
    // Scanning line.
    if (this.scanService.scanStatus === ScanStatus.PREVIEW_DECODING) {
      Column() {
        ScanLine()
          .height(`calc(100% - ${this.scanLayout.scanLineMarginTop}vp - ${this.scanLayout.scanLineMarginBottom}vp)`)
          .margin({
            top: this.scanLayout.scanLineMarginTop
          })
      }
      .justifyContent(FlexAlign.Start)
      .width('100%').height('100%')
    }
  }

  @Builder
  ScanBottomBuilder() {
    // Gallery, flash light
    ScanBottom({
      enableAlbum: this.options.enableAlbum,
      openPicker: (async () => {
        if (this.scanService.scanStatus === ScanStatus.PREVIEW_DECODING) {
          await this.scanService.stopPreviewStream();
          this.clearTimer();
          this.scanService.updateScanStatus(ScanStatus.PHOTO_DECODING);
          Logger.info(TAG, `openAlbum, scanStatus: ${this.scanService.scanStatus}`);
          openAlbum(this.photoPickerCallback);
        }
      })
    })
  }

  @Builder
  MaskLayerBuilder() {
    // Radio button information in the single-code and multi-code scanning results.
    if (this.scanService.isDecodingCompleted()) {
      MaskLayer()
    }
  }

  @Builder
  CodeLayoutBuilder() {
    // Display the radio button for scanning a single barcode or multiple barcodes.
    if (this.scanService.isDecodingCompleted()) {
      Column() {
        CodeLayout({
          scanResults: this.scanResult,
          restartPreviewStream: (() => {
            Logger.info(TAG, 'Start to restartPreviewStream by dialog button.');
            this.restartPreviewStream();
          })
        })
      }
    }
  }

  @Builder
  CloseButtonBuilder() {
    Button({
      type: ButtonType.Circle,
      stateEffect: true
    }) {
      SymbolGlyph($r('sys.symbol.xmark'))
        .fontWeight(FontWeight.Regular)
        .fontColor([$r('sys.color.font_on_primary')])
        .fontSize('24vp')
    }
    .width(CommonConstants.CLOSE_IMAGE_SIZE)
    .height(CommonConstants.CLOSE_IMAGE_SIZE)
    .backgroundColor('rgba(255,255,255,0.15)')
    .id('scan_page_goBack')
    .margin({
      top: LengthMetrics.vp(this.scanLayout.closeButtonMarginTop),
      start: LengthMetrics.vp(BREAK_POINT_TYPE_MARGIN_VP.getValue(this.scanLayout.widthBreakpoint))
    })
    .onClick(async () => {
      if (this.scanResult.size > 1) {
        Logger.info(TAG, 'Start to restartPreviewStream by close button.');
        this.restartPreviewStream();
      } else {
        Logger.info(TAG, 'router back');
        router.back();
      }
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.userGrant) {
        this.BackgroundBuilder()
      }

      this.ScanLineBuilder()

      this.ScanBottomBuilder()

      this.MaskLayerBuilder()

      this.ScanTitleBuilder()

      this.CodeLayoutBuilder()

      this.CloseButtonBuilder()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.userGrant ? Color.Transparent : Color.Black)
  }

  // Code recognition information processing.
  handleDecodeResult(error: BusinessError, result: scanBarcode.ScanResult[]): void {
    if (result) {
      this.scanResult.size = result.length;
      // Barcode image information recognized.
      if (this.scanResult.size > 0) {
        this.scanResult.code = (error && error.code) ? error.code : 0;
        this.scanResult.data = result;
        this.avPlayer?.playDrip();
      }
    }
  }

  onScreenEvent(): void {
    // Subscribe to COMMON_EVENT_SCREEN_CHANGE.
    emitter.on({ eventId: CommonConstants.COMMON_EVENT_SCREEN_CHANGE }, (eventData: emitter.EventData) => {
      Logger.info(TAG, 'screenEventChange enter');
      if (eventData.data && eventData.data.screenEventChange === CommonConstants.EVENT_SCREEN_OFF) {
        this.onPageHide();
      } else if (eventData.data && eventData.data.screenEventChange === CommonConstants.EVENT_SCREEN_ON) {
        this.onPageShow();
      }
    });
  }

  offScreenEvent(): void {
    emitter.off(CommonConstants.COMMON_EVENT_SCREEN_CHANGE);
  }

  async empowerment() {
    const permissions: Array<Permissions> = ['ohos.permission.CAMERA'];
    let grantStatus = await PermissionsUtil.checkAccessToken(permissions[0]);
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      // If the user has granted the permission, the operation is allowed.
      this.userGrant = true;
      this.scanService.updateScanStatus(ScanStatus.NOT_STARTED);
      this.startCustomScan();
    } else {
      // Apply for the camera permission.
      this.requestCameraPermission();
    }
  }

  async requestCameraPermission() {
    let grantStatus = await PermissionsUtil.reqPermissionsFromUser();
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        // The user has granted the permission.
        Logger.info(TAG, 'Succeeded in requesting permissions from user.');
        this.userGrant = true;
        this.scanService.updateScanStatus(ScanStatus.NOT_STARTED);
        if (this.isDialogShow) {
          this.isDialogShow = false;
          this.dialogController.close();
        }
        this.startCustomScan();
      } else {
        // If the user refuses to grant the permission, display a message indicating that user authorization is required, and direct the user to set the permission in system settings.
        Logger.info(TAG, `Failed to requesting permissions from user.`);
        this.userGrant = false;
        if (!this.isDialogShow) {
          this.isDialogShow = true;
          this.dialogController.open();
        }
      }
    }
  }

  onDisplayChange(): void {
    display.on('change', () => {
      let newDisplay = DeviceService.getDisplayInfoSync();
      Logger.info(TAG,
        `onDisplayChange, pre_densityPixels: ${DeviceService.densityPixels}, new_densityPixels: ${newDisplay?.densityPixels}.pre_rotation: ${DeviceService.rotation}, new_rotation: ${newDisplay?.rotation}.`);
      if (newDisplay !== null) {
        // The device rotates.
        if (DeviceService.rotation !== newDisplay.rotation) {
          Logger.info(TAG,
            `onDisplayChange, pre_rotation: ${DeviceService.rotation}, new_rotation: ${newDisplay.rotation}.`);
          let rotationAngle: number = Math.abs(DeviceService.rotation - newDisplay.rotation);
          DeviceService.setDisplayInfo(newDisplay);

          // The device rotates and the screen density changes.
          if (DeviceService.densityPixels !== newDisplay.densityPixels) {
            this.windowService.refreshLayoutByDensityPixels(DeviceService.densityPixels);
          } else {
            this.xComponentService.setScanXComponentSize();
          }

          // rotationAngle === 2 indicates that the rotation angle is 180 degrees. In this case, you do not need to initialize the width and height of XComponent. Instead, you can directly use initScan.
          if (rotationAngle === 2) {
            this.startCustomScan();
          }

          // The device screen density changes.
        } else if (DeviceService.densityPixels !== newDisplay.densityPixels) {
          Logger.info(TAG,
            `onDisplayChange, pre_densityPixels: ${DeviceService.densityPixels}, new_densityPixels: ${newDisplay.densityPixels}.`);
          DeviceService.setDisplayInfo(newDisplay);
          this.windowService.refreshLayoutByDensityPixels(DeviceService.densityPixels);
        } else {
          DeviceService.setDisplayInfo(newDisplay);
        }
      }
    })
  }

  offDisplayChange(): void {
    try {
      display.off('change');
    } catch (error) {
      Logger.error(TAG, `offDensityDPI off catch error. Code: ${error.code}`);
    }
  }

  startCustomScan(): void {
    this.viewControl = {
      width: this.xComponentService.width,
      height: this.xComponentService.height,
      surfaceId: this.surfaceId
    }
    if (this.surfaceId) {
      Logger.info(TAG, `startCustomScan, surfaceId: ${this.surfaceId}`);
      this.scanService.startPreviewStream(this.options, this.viewControl, this.customScanCallback);
      this.startTimer()
      this.avPlayer = PromptTone.getInstance(getContext(this) as common.UIAbilityContext);
    }
  }

  clearTimer() {
    if (timerId !== null) {
      clearTimeout(timerId);
      timerId = null;
      this.tipShow = false;
    }
  }

  startTimer() {
    this.clearTimer();
    timerId = setTimeout(() => {
      if (this.userGrant && this.scanResult.size === 0) {
        this.tipShow = true;
      }
    }, 5000);
  }

  windowSizeSubscribe(): void {
    // Respond to the window size change.
    emitter.on({ eventId: CommonConstants.WINDOW_SIZE_CHANGE }, async (eventData: emitter.EventData) => {
      Logger.info(TAG, 'windowSizeChange enter');
      if (eventData.data) {
        if (this.foldStatus.oldFoldStatus !== this.foldStatus.newFoldStatus) {
          this.foldStatus.oldFoldStatus = this.foldStatus.newFoldStatus;
          this.clearTimer();
          await this.scanService.stopPreviewStream();
          DeviceService.selectSuitableRatio();
          this.xComponentService.setScanXComponentSize();
        }
        this.startCustomScan();
      }
    });
  }

  foldStatusSubscribe(): void {
    try {
      display.on('foldStatusChange', async (foldStatus: display.FoldStatus) => {
        // FOLD_STATUS_FOLDED => FOLD_STATUS_HALF_FOLDED; FOLD_STATUS_EXPANDED or FOLD_STATUS_HALF_FOLDED => FOLD_STATUS_FOLDED
        Logger.info(TAG,
          `foldStatus has changed, pre_foldStatus: ${this.foldStatus.newFoldStatus}, new_foldStatus: ${foldStatus}`);
        this.foldStatus.oldFoldStatus = this.foldStatus.newFoldStatus;
        this.foldStatus.newFoldStatus = foldStatus;
      });
    } catch (error) {
      Logger.error(TAG, `Failed to foldStatusListen. Code: ${error.code}`);
    }
  }

  restartPreviewStream() {
    this.scanService.startPreviewStream(this.options, this.viewControl, this.customScanCallback);
    this.startTimer();
  }
}
