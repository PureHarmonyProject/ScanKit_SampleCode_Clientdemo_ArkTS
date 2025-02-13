import { display, window } from '@kit.ArkUI';
import { customScan, scanBarcode, scanCore } from '@kit.ScanKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { AsyncCallback, BusinessError, emitter } from '@kit.BasicServicesKit';
import Logger from '../../../common/Logger';
import { ScanLine } from '../view/ScanLine';
import { ScanBottom } from '../view/ScanBottom';
import { ScanTopTool } from '../view/ScanTopTool';
import { CodeLayout } from '../view/CommonCodeLayout';
import { ScanTitle } from '../view/ScanTitle';
import { PromptTone } from '../model/PromptTone';
import { openAlbum } from '../model/OpenPhoto';
import { GlobalThisUtil } from '../../../common/GlobalThisUtil';
import { CommonConstants } from '../constants/CommonConstants'
import { MaskLayer } from '../view/MaskLayer';
import { ScanService, ScanResults } from '../model/ScanService';
import { BreakpointConstants } from '../constants/BreakpointConstants';
import { DeviceStatus, ScanLayout, ScanSize, XComponentSize, NewArea } from '../model/ScanSize';
import { ScanXComponent } from '../view/ScanXComponent';
import { ScanLoading } from '../view/ScanLoading';
import { PermissionsUtil } from '../../../common/PermissionsUtil';
import { CommonTipsDialog } from '../../../common/CommonTipsDialog';
import { getFoldStatusByDisplay } from '../model/ScanSize';

export const TAG = 'ScanPage';

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
  @State scanSize: ScanSize = ScanSize.getInstance();
  @State deviceStatus: DeviceStatus = this.scanSize.deviceStatus;
  @State xComponentSize: XComponentSize = this.scanSize.xComponentSize;
  @State scanLayout: ScanLayout = this.scanSize.scanLayout;
  @State scanService: ScanService = ScanService.getInstance();
  @State scanResult: ScanResults = this.scanService.scanResult;
  @State surfaceId: string = '';
  @State densityDPI: number = 0; // Pixel density.
  @State newArea: NewArea = this.scanSize.newArea; // Latest window area information.
  @State viewControl: customScan.ViewControl = {
    width: this.xComponentSize.width,
    height: this.xComponentSize.height,
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
  customCallbackScan: AsyncCallback<scanBarcode.ScanResult[]> =
    async (error: BusinessError, result: scanBarcode.ScanResult[]) => {
      if (this.scanService.retryOnCondition(error, this.options, this.viewControl, this.customCallbackScan)) {
        return;
      }
      if (!this.scanService.isScanned && !this.scanService.isOpenAlbum &&
      this.scanService.isOnPageShow) {
        this.scanResult.code = (error && error.code) ? error.code : 0;
        this.scanResult.data = result || [];
        let resultLength: number = result ? result.length : 0;
        if (GlobalThisUtil.getProperty(CommonConstants.GLOBAL_SCAN_SELECT_A_PICTURE) || resultLength) {
          this.scanService.releaseCamera();
          this.clearTimer();
          this.scanService.isScanned = true; // Scanned successfully.
          this.scanResult.uri = GlobalThisUtil.getProperty(CommonConstants.GLOBAL_SCAN_SELECT_A_PICTURE);
          this.scanResult.size = resultLength;
          // Display mask.
          if (this.scanResult.uri) {
            this.scanService.isAlbumLoading = true;
          }
          if (this.scanResult.size >= 1) {
            this.scanService.isScanLine = false;
            if (this.avPlayer) {
              try {
                this.avPlayer.playDrip();
              } catch (error) {
                Logger.error(TAG, `avPlayer catch error. Code: ${error.code}`);
              }
            }
          } else {
            this.scanService.isAlbumLoading = false;
          }
        } else {
          this.scanService.isAlbumLoading = false;
          // No image is selected.
          this.scanService.isOpenAlbum = false;
          this.initScan();

        }
      } else {
        // Failed to scan the QR code from an image in the gallery.
        this.scanService.isAlbumLoading = false;
      }
    }

  aboutToAppear() {
    // Obtain the device orientation.
    this.scanSize.setDisplayRotation();

    // Not access the gallery for code recognition.
    GlobalThisUtil.setProperty(CommonConstants.GLOBAL_SCAN_IS_DECODING_GALLERY, false);
    this.scanService.isOpenAlbum = false;

    if (GlobalThisUtil.getProperty('scan_topRect_height')) {
      this.scanSize.navHeight = px2vp(GlobalThisUtil.getProperty('scan_topRect_height'));
    }

    if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable')) {
      this.deviceStatus.newFoldStatus = getFoldStatusByDisplay();
      this.deviceStatus.oldFoldStatus = this.deviceStatus.newFoldStatus;
      // Foldable screen status listener.
      this.foldStatusSubscribe();
    }

    // Initialize XComponentSize based on the window size.
    this.setDisplay();

    // Window size listener.
    this.windowSizeSubscribe();

    // Pixel density listener.
    this.onDensityDPI();

    // Screen event listener.
    this.onScreenEvent();
  }

  async onPageShow(): Promise<void> {
    await this.empowerment();
    this.scanService.isOnPageShow = true;
    this.scanService.isReleaseCamera = false;
    this.scanService.isStopCamera = false;
  }

  onPageHide(): void {
    this.scanService.scanDestroy();
    this.scanService.resetRetryScanTimes();
    this.clearTimer();
    this.userGrant = false;
    this.isDialogShow = false;
    this.dialogController.close();
  }

  async aboutToDisappear(): Promise<void> {
    try {
      emitter.off(CommonConstants.WINDOW_SIZE_CHANGE);
      if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable')) {
        display.off('foldStatusChange');
      }
    } catch (error) {
      Logger.error(TAG, `listener off catch error. Code: ${error.code}`);
    }
    this.offDensityDPI();
    this.offScreenEvent();
  }

  @Builder
  BackgroundBuilder() {
    ScanXComponent({
      xComponentSize: this.xComponentSize,
      surfaceId: this.surfaceId,
      initScan: (() => {
        this.initScan();
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
        navHeight: this.scanSize.navHeight,
      }).width('100%')
        .onAreaChange((_: Area, newArea: Area) => {
          this.scanLayout.topHeight = Number(newArea.height);
        })
        .visibility(this.scanResult.size > 0 ? Visibility.Hidden : Visibility.Visible)
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
    if (this.scanService.isScanLine) {
      Column() {
        ScanLine({
          isScanned: this.scanService.isScanned,
          isOpenAlbum: this.scanService.isOpenAlbum
        })
          .height(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM ?
            `calc(100% - ${this.scanLayout.topHeight}vp - ${this.scanLayout.bottomHeightSmExcludesMarginD}vp - ${3 *
            this.scanLayout.marginD}vp)`
            : `calc(100% - ${this.scanLayout.topHeight}vp - ${this.scanLayout.bottomHeightMdOrLg}vp)`)
          .margin({
            bottom: this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM ?
              `calc(${this.scanLayout.bottomHeightSmExcludesMarginD}vp + ${3 * this.scanLayout.marginD}vp)`
              : this.scanLayout.bottomHeightMdOrLg
          })
          .constraintSize({
            minHeight: 100
          })
      }
      .justifyContent(FlexAlign.End)
      .width('100%').height('100%')
    }
  }

  @Builder
  ScanBottomBuilder() {
    // Gallery, flash light
    ScanBottom({
      isScanned: this.scanService.isScanned,
      enableAlbum: this.options.enableAlbum,
      openPicker: (async () => {
        if (!this.scanService.isScanned) {
          GlobalThisUtil.setProperty(CommonConstants.GLOBAL_SCAN_SELECT_A_PICTURE, false);
          GlobalThisUtil.setProperty(CommonConstants.GLOBAL_SCAN_IS_DECODING_GALLERY, true);
          this.scanService.isOpenAlbum = true;
          this.scanService.isScanned = false;
          this.scanService.isScanLine = false;
          await this.scanService.releaseCamera();
          this.scanService.resetRetryScanTimes();
          this.clearTimer();
          openAlbum(this.options, this.customCallbackScan, () => {
            this.scanService.isAlbumLoading = true;
            this.scanService.isOpenAlbum = false;
          });
        }
      })
    })
  }

  @Builder
  CodeLayoutBuilder() {
    // Display the radio button for scanning a single barcode or multiple barcodes.
    if (this.scanService.isScanned) {
      MaskLayer()
      Column() {
        CodeLayout({
          rotation: this.deviceStatus.rotation,
          xComponentSize: this.xComponentSize,
          navHeight: this.scanSize.navHeight,
          scanResults: this.scanResult,
          backToScan: (() => {
            this.backToScanCamera();
          })
        })
      }
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.userGrant) {
        this.BackgroundBuilder()
      }

      this.ScanTitleBuilder()

      this.ScanLineBuilder()

      this.ScanBottomBuilder()

      this.CodeLayoutBuilder()

      ScanTopTool({
        scanResultSize: this.scanResult.size,
        navHeight: this.scanSize.navHeight,
        backToScan: (() => {
          this.backToScanCamera();
        })
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.userGrant ? Color.Transparent : Color.Black)
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
      this.initScan();
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
        if (this.isDialogShow) {
          this.isDialogShow = false;
          this.dialogController.close();
        }
        this.initScan();
      } else {
        // If the user refuses to grant the permission, display a message indicating that user authorization is required, and direct the user to set the permission in system settings.
        Logger.info(TAG, `Failed to requesting permissions from user.`);
        this.userGrant = false;
        if (!this.isDialogShow) {
          this.dialogController.open();
          this.isDialogShow = true;
        }
      }
    }
  }

  onDensityDPI(): void {
    display.on('change', () => {
      try {
        let newDisplay = display.getDefaultDisplaySync();
        if (newDisplay !== null && this.newArea.densityPixels !== newDisplay.densityPixels) {
          Logger.info(TAG, 'densityPixels has changed.');
          this.newArea.densityPixels = newDisplay.densityPixels;
          if (newDisplay.densityPixels > 0) {
            let windowSize: window.Size = {
              width: this.newArea.width / newDisplay.densityPixels,
              height: this.newArea.height / newDisplay.densityPixels,
            };
            this.startScan(windowSize);
          } else {
            Logger.error(TAG, `densityPixels less than or equal to 0`);
          }
        }

        if (this.deviceStatus.rotation !== newDisplay.rotation) {
          Logger.info(TAG,
            `onDisplayChange, pre_rotation: ${this.deviceStatus.rotation}, new_rotation: ${newDisplay.rotation}.`);
          this.scanService.initScanData();
          let rotationAngle: number = Math.abs(this.deviceStatus.rotation - newDisplay.rotation);
          this.deviceStatus.setRotation(newDisplay.rotation);
          if (rotationAngle === 2) {
            this.initScan();
          }
        }
      } catch (error) {
        Logger.error(TAG, `Failed to invoke an API of getDefaultDisplaySync. Code: ${error.code}`);
      }
    })
  }

  offDensityDPI(): void {
    try {
      display.off('change');
    } catch (error) {
      Logger.error(TAG, `offDensityDPI off catch error. Code: ${error.code}`);
    }
  }

  setDisplay(): void {
    let windowSize: window.Size | null = this.scanSize.setWindowSize();
    if (windowSize) {
      this.scanSize.setScanXComponentSize(windowSize)
    }
  }

  startScan(windowSize: window.Size | null): void {
    if (windowSize) {
      this.scanSize.setScanXComponentSize(windowSize);
      this.initScan()
    }
  }

  initScan(): void {
    this.viewControl = {
      width: this.xComponentSize.width,
      height: this.xComponentSize.height,
      surfaceId: this.surfaceId
    }
    if (this.surfaceId) {
      Logger.info(TAG, `startScan`)
      this.scanService.initCamera(this.options, this.viewControl, this.customCallbackScan);
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
        let windowSize: window.Size = {
          width: px2vp(eventData.data.width),
          height: px2vp(eventData.data.height)
        }
        if (this.deviceStatus.oldFoldStatus !== this.deviceStatus.newFoldStatus) {
          await this.releaseUI();
          this.scanService.resetRetryScanTimes();
          this.deviceStatus.oldFoldStatus = this.deviceStatus.newFoldStatus;
        }
        this.startScan(windowSize);
      }
    });
  }

  foldStatusSubscribe(): void {
    try {
      display.on('foldStatusChange', async (foldStatus: display.FoldStatus) => {
        // FOLD_STATUS_FOLDED => FOLD_STATUS_HALF_FOLDED; FOLD_STATUS_EXPANDED or FOLD_STATUS_HALF_FOLDED => FOLD_STATUS_FOLDED
        Logger.info(TAG,
          `foldStatus has changed, pre_foldStatus: ${this.deviceStatus.newFoldStatus}, new_foldStatus: ${foldStatus}`);
        this.deviceStatus.oldFoldStatus = this.deviceStatus.newFoldStatus;
        this.deviceStatus.newFoldStatus = foldStatus;
      });
    } catch (error) {
      Logger.error(TAG, `Failed to foldStatusListen. Code: ${error.code}`);
    }
  }

  async releaseUI(): Promise<void> {
    this.scanService.resetScanData();
    this.clearTimer();
    await this.scanService.releaseCamera();
  }

  async backToScanCamera() {
    this.clearTimer();
    this.scanService.backToScan(this.options, this.viewControl, this.customCallbackScan);
    this.startTimer()
  }
}
