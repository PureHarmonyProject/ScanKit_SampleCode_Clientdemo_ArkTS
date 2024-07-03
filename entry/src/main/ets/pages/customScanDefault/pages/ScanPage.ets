import { display, window } from '@kit.ArkUI';
import { customScan, scanBarcode, scanCore } from '@kit.ScanKit';
import { abilityAccessCtrl, common, ConfigurationConstant, Permissions, Want } from '@kit.AbilityKit';
import { AsyncCallback, BusinessError, emitter } from '@kit.BasicServicesKit';
import Logger from '../../../common/logger';
import { ScanLine } from '../view/ScanLine';
import { ScanBottom } from '../view/ScanBottom';
import { ScanTopTool } from '../view/ScanTopTool';
import { CodeLayout } from '../view/CommonCodeLayout';
import { ScanTitle } from '../view/ScanTitle';
import { PromptTone } from '../model/PromptTone';
import { openAlbum } from '../model/openPhoto';
import { GlobalThisUtil } from '../../../common/GlobalThisUtil';
import { CommonConstants } from '../constants/CommonConstants'
import { MaskLayer } from '../view/MaskLayer';
import { ScanService, ScanResult } from '../model/ScanService';
import { BreakpointConstants } from '../constants/BreakpointConstants';
import { DeviceStatus, ScanLayout, ScanSize, XComponentSize, NewArea } from '../model/ScanSize';
import { ScanXComponent } from '../view/ScanXComponent';
import { pickerDialog } from '../view/pickerDialog';
import { ScanLoading } from '../view/ScanLoading';
import { PermissionsUtil } from '../../customScan/PermissionsUtil';
import { CustomDialogExample } from '../../customScan/CustomScan';

export const TAG = 'ScanPage';

let storage = LocalStorage.getShared();

@Entry(storage)
@Component
struct ScanPage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @State scanSize: ScanSize = ScanSize.getInstance();
  @State deviceStatus: DeviceStatus = this.scanSize.deviceStatus;
  @State xComponentSize: XComponentSize = this.scanSize.xComponentSize;
  @State scanLayout: ScanLayout = this.scanSize.scanLayout;
  @State scanService: ScanService = ScanService.getInstance();
  @State scanResult: ScanResult = this.scanService.scanResult;
  @State darkMode: ConfigurationConstant.ColorMode | undefined = undefined;
  @State surfaceId: string = '';
  @State densityDPI: number = 0;
  @State newArea: NewArea = this.scanSize.newArea;
  @State viewControl: customScan.ViewControl = {
    width: this.xComponentSize.width,
    height: this.xComponentSize.height,
    surfaceId: ''
  };
  @State isDialogShow: boolean = false;
  @State userGrant: boolean = false;
  options: scanBarcode.ScanOptions = {
    scanTypes: [scanCore.ScanType.ALL],
    enableMultiMode: true,
    enableAlbum: true
  };
  public avPlayer: PromptTone | null = null // Audio control after successful code scanning.
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDialogExample({
      action: this.openPermissionsInSystemSettings,
      cancel: this.existApp,
    }),
    autoCancel: false,
    customStyle: true,
    alignment: DialogAlignment.Center
  });
  customCallbackScan: AsyncCallback<scanBarcode.ScanResult[]> =
    async (error: BusinessError, result: scanBarcode.ScanResult[]) => {
      if(error) {
        Logger.error(TAG, `An error is returned during customCallbackScan. Code: ${error.code}, message: ${error.message}`);
      }
      if (!this.scanService.isScanned && !this.scanService.isOpenAlbum &&
      this.scanService.isOnPageShow) {
        this.scanResult.code = (error && error.code) ? error.code : 0;
        this.scanResult.data = result || [];
        let resultLength: number = result ? result.length : 0;
        if (GlobalThisUtil.getProperty('hmsCore_scan_pickerUri') || resultLength) {
          this.scanService.stopCamera();
          this.scanService.isScanned = true; // The result has been scanned.
          this.scanResult.uri = GlobalThisUtil.getProperty('hmsCore_scan_pickerUri');
          this.scanResult.size = resultLength;
          // Display the mask layer.
          if (this.scanResult.uri) {
            this.scanService.isAlbumLoading = true;
          }
          if (this.scanResult.size >= 1) {
            this.scanService.isScanLine = false;
            if (this.avPlayer) {
              try {
                this.avPlayer.playDrip();
              } catch (error) {
                Logger.error(TAG, `avPlayer catch error. Code: ${error.code}, message: ${error.message}`);
              }
            }
          } else {
            this.scanService.isAlbumLoading = false;
          }
        } else {
          this.scanService.isAlbumLoading = false;
          // Return if no image is selected.
          this.scanService.isOpenAlbum = false;
          this.initScan();

        }
      } else {
        // Gallery QR code scanning failed.
        this.scanService.isAlbumLoading = false;
      }
    }

  aboutToAppear() {
    this.scanSize.getOrientation();

    GlobalThisUtil.setProperty('hmsCore_scan_isPickerDecode', false);
    this.scanService.isOpenAlbum = false;

    if (GlobalThisUtil.getProperty('scan_topRect_height')) {
      this.scanSize.navHeight = px2vp(GlobalThisUtil.getProperty('scan_topRect_height'));
    }

    if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable')) {
      this.deviceStatus.foldStatus = display.getFoldStatus();
      this.foldStatusSubscribe();
    }

    this.setDisplay();

    this.windowSizeSubscribe();

    this.onDensityDPI();
  }

  async onPageShow(): Promise<void> {
    this.scanService.isOnPageShow = true;
    this.scanService.isReleaseCamera = false;
    this.scanService.isStopCamera = false;

    await this.empowerment();

    this.darkMode = (getContext(this) as common.UIAbilityContext).config.colorMode;
  }

  onPageHide(): void {
    this.scanService.scanDestroy();
    this.isDialogShow = false;
  }

  async aboutToDisappear(): Promise<void> {
    try {
      emitter.off(CommonConstants.WINDOW_SIZE_CHANGE);
      if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable')) {
        display.off('foldStatusChange');
      }
    } catch (error) {
      Logger.error(TAG, `listener off catch error. Code: ${error.code}, message: ${error.message}`);
    }
    this.offDensityDPI();
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

    // Loading status when the image bitmap is parsed.
    if (this.scanService.isAlbumLoading) {
      ScanLoading()
    }
  }

  @Builder
  ScanTitleBuilder() {
    //Top title
    ScanTitle({
      scanResultSize: this.scanResult.size,
      navHeight: this.scanSize.navHeight,
    }).width('100%')
      .onAreaChange((_: Area, newArea: Area) => {
        this.scanLayout.topHeight = Number(newArea.height);
      })
      .visibility(this.scanResult.size > 0 ? Visibility.Hidden : Visibility.Visible)
  }

  @Builder
  ScanLineBuilder() {
    // Scan line
    if (this.scanService.isScanLine) {
      Column() {
        ScanLine({
          isScanned: this.scanService.isScanned,
          isOpenAlbum: this.scanService.isOpenAlbum
        })
          .height(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM ?
            `calc(100% - ${this.scanLayout.topHeight}vp - ${this.scanLayout.bottomHeightSmExcludesmarginD}vp - ${3 *
            this.scanLayout.marginD}vp)`
            : `calc(100% - ${this.scanLayout.topHeight}vp - ${this.scanLayout.bottomHeightMdOrLg}vp)`)
          .margin({
            bottom: this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM ?
              `calc(${this.scanLayout.bottomHeightSmExcludesmarginD}vp + ${3 * this.scanLayout.marginD}vp)`
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
    // Gallery, flash
    ScanBottom({
      isScanned: this.scanService.isScanned,
      enableAlbum: this.options.enableAlbum,
      isScanLine: this.scanService.isScanLine,
      foldStatus: this.deviceStatus.foldStatus,
      openPicker: (async () => {
        if (!this.scanService.isScanned) {
          GlobalThisUtil.setProperty('hmsCore_scan_pickerUri', undefined);
          GlobalThisUtil.setProperty('hmsCore_scan_isPickerDecode', true);
          this.scanService.isOpenAlbum = true;
          this.scanService.isScanned = false;
          this.scanService.isScanLine = false;
          await this.scanService.releaseCamera();
          openAlbum(this.options, this.customCallbackScan, () => {
            this.scanService.isAlbumLoading = true;
            this.scanService.isOpenAlbum = false;
            this.onPageShow();
          });
        }
      })
    })
  }

  @Builder
  CodeLayoutBuilder() {
    // Single-code and multi-code scanning display blue dot information
    if (this.scanService.isScanned) {
      MaskLayer()
      Column() {
        CodeLayout({
          darkMode: this.darkMode,
          orientation: this.deviceStatus.orientation,
          xComponentSize: this.xComponentSize,
          navHeight: this.scanSize.navHeight,
          scanResult: this.scanResult,
          foldStatus: this.deviceStatus.foldStatus,
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

  async empowerment() {
    const permissions: Array<Permissions> = ['ohos.permission.CAMERA'];
    let grantStatus = await PermissionsUtil.checkAccessToken(permissions[0]);
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      // You have been authorized to continue to access the target operation.
      this.userGrant = true;
      this.initScan();
    } else {
      // Applying for Camera Permissions
      this.requestCameraPermission();
    }
  }

  openPermissionsInSystemSettings(): void {
    Logger.info(TAG, 'Start to open permissions in system settings.');
    let context = getContext(this) as common.UIAbilityContext;
    let wantInfo: Want = {
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: 'application_info_entry',
      parameters: {
        settingsParamBundleName: 'com.example.testclient' // Open the details page of a specified application.
      }
    }
    context.startAbility(wantInfo).then(() => {
      Logger.info(TAG, 'Succeeded in starting ability.');
    }).catch((error: Error) => {
      Logger.info(TAG,  `Failed to start ability. Message: ${error.message}`);
    })
  }

  existApp() {
    this.isDialogShow = false;
    Logger.info(TAG, 'Succeeded in exiting app.');
  }

  async requestCameraPermission() {
    let grantStatus = await PermissionsUtil.reqPermissionsFromUser();
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        // The user is authorized to continue to access the target operation.
        Logger.info(TAG, 'Succeeded in requesting permissions from user.');
        this.userGrant = true;
        if (this.isDialogShow) {
          this.isDialogShow = false;
          this.dialogController.close();
        }
        this.initScan();
      } else {
        // The user rejects the authorization, prompts that the user must be authorized to access the functions of the current page, and guides the user to enable the corresponding permission in the system settings.
        Logger.info(TAG,  `Failed to requesting permissions from user.`);
        this.userGrant = false;
        if (!this.isDialogShow) {
          this.dialogController.open();
          this.isDialogShow = true;
        }
      }
    }
  }

  onDensityDPI() {
    display.on("change", () => {
      let newDisplay = display.getDefaultDisplaySync();
      if (newDisplay !== null && this.newArea.densityPixels !== newDisplay.densityPixels) {
        Logger.info(TAG, 'densityPixels has changed.');
        this.newArea.densityPixels = newDisplay.densityPixels;
        let windowSize: window.Size | null = {
          width: this.newArea.width / newDisplay.densityPixels,
          height: this.newArea.height / newDisplay.densityPixels,
        };
        this.startScan(windowSize);
      }
    })
  }

  offDensityDPI() {
    try {
      display.off('change');
    } catch (error) {
      Logger.error(TAG, `offDensityDPI off catch error. Code: ${error.code}, message: ${error.message}`);
    }
  }

  setDisplay(): void {
    let windowSize: window.Size | null = this.scanSize.setWindowSize()
    this.startScan(windowSize)
  }

  startScan(windowSize: window.Size | null): void {
    if (windowSize) {
      this.scanSize.setScanXComponentSize(true, windowSize)
      this.initScan()
    }
  }

  initScan() {
    this.viewControl = {
      width: this.xComponentSize.width,
      height: this.xComponentSize.height,
      surfaceId: this.surfaceId
    }
    if (this.surfaceId) {
      Logger.info(TAG, `startScan`)
      this.scanService.initCamera(this.options, this.viewControl, this.customCallbackScan);
      this.avPlayer = PromptTone.getInstance(getContext(this) as common.UIAbilityContext);
    }
  }

  windowSizeSubscribe(): void {
    // Response window size change.
    emitter.on({ eventId: CommonConstants.WINDOW_SIZE_CHANGE }, (eventData: emitter.EventData) => {
      Logger.info(TAG, 'windowSizeChange enter');
      this.releaseUI();
      if (eventData.data) {
        let windowSize: window.Size = {
          width: px2vp(eventData.data.width),
          height: px2vp(eventData.data.height)
        }
        this.startScan(windowSize)
      }
    });
  }

  foldStatusSubscribe(): void {
    try {
      display.on('foldStatusChange', async (foldStatus: display.FoldStatus) => {
        if (foldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED ||
          foldStatus === display.FoldStatus.FOLD_STATUS_FOLDED) {
          Logger.info(TAG, 'Start to subscribe foldStatus, foldStatus has changed.');
          this.deviceStatus.foldStatus = foldStatus;
        }
      });
    } catch (error) {
      Logger.error(TAG, `Failed to subscribe foldStatus. Code: ${error.code}, message: ${error.message}`);
    }
  }

  async releaseUI(): Promise<void> {
    this.scanService.resetScanData();
    await this.scanService.releaseCamera();
  }

  async backToScanCamera() {
    this.scanService.backToScan(this.options, this.viewControl, this.customCallbackScan);
  }
}
