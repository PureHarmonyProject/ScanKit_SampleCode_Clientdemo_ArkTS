import { fileIo } from '@kit.CoreFileKit';
import { router, display } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { scanCore, scanBarcode, customScan } from '@kit.ScanKit';
import { common, abilityAccessCtrl, Permissions, Want } from '@kit.AbilityKit';
import { emitter } from '@kit.BasicServicesKit';
import { WindowSize } from '../../common/Utils';
import { PermissionsUtil } from './PermissionsUtil';
import { GlobalThisUtil } from '../../common/GlobalThisUtil';
import { CommonConstants } from '../customScanDefault/constants/CommonConstants';

const TAG = 'Scan SampleCode CustomYuv';
const DOMAIN: number = 0x0001;
const PADDING_24 = 24;

@Extend(Image)
function topIcon() {
  .width(24)
  .height(24)
  .objectFit(ImageFit.Contain)
  .responseRegion({
    x: '-50%',
    y: '-50%',
    width: '200%',
    height: '200%'
  })
}

@Extend(Flex)
function topFlex() {
  .width('100%')
  .height(48)
  .padding({ left: PADDING_24, right: PADDING_24 })
  .linearGradient({
    angle: 180,
    colors: [['rgba(0,0,0,0.5)', 0.0], ['rgba(0,0,0,0)', 1.0]]
  })
}

@Extend(Column)
function topText() {
  .margin({ left: PADDING_24, right: PADDING_24, top: 24 })
}

@Extend(Text)
function scanTitle() {
  .width('100%')
  .fontSize(18)
  .fontColor('rgba(255,255,255,0.9)')
  .textAlign(TextAlign.Center)
  .padding({ bottom: 8 })
  .borderColor('#FF0000')
}

@Extend(Text)
function scanTips() {
  .width('100%')
  .fontSize(14)
  .fontColor('rgba(255,255,255,0.6)')
  .textAlign(TextAlign.Center)
}

@Extend(Text)
function disLogTitle() {
  .fontColor(Color.Black)
  .fontSize(12)
  .alignSelf(ItemAlign.Start)
  .padding({ left: 20 })
}

@Extend(Text)
function disLogTips() {
  .textAlign(TextAlign.Start)
  .fontColor(Color.Black)
  .fontSize(14)
  .padding({ left: 20, top: 20, right: 20 })
}

@Extend(Text)
function btn() {
  .width('50%')
  .height(20)
  .fontSize(14)
  .textAlign(TextAlign.Center)
  .fontColor(Color.Black)
}

@Extend(Flex)
function box() {
  .width(320)
  .height(140)
  .padding(15)
  .backgroundColor(Color.White)
  .borderRadius(24)
}

@Extend(Row)
function angleSizes(position: Position, borderOption: BorderOptions) {
  .width(20)
  .height(20)
  .border(borderOption)
  .position(position)
}

@CustomDialog
export struct CustomDialogExample {
  controller: CustomDialogController = new CustomDialogController({
    builder: null
  });
  cancel: () => void = () => {
  };
  action: () => void = () => {
  };

  build() {
    Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceBetween }) {
      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text($r('app.string.Scan_access_not_enabled')).disLogTitle()
        Text($r('app.string.Scan_access_tips')).disLogTips()
      }.height(105)

      Flex({ justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
        Text($r('app.string.Scan_got_it')).btn()
          .onClick(() => {
            this.controller.close();
            this.cancel();
          })
        Text($r('app.string.Scan_settings')).btn()
          .onClick(() => {
            this.action();
          })
      }.height(35)
    }.box()
  }
}

@Component
struct closeImage {
  build() {
    Column() {
      Image($rawfile('scan_back.svg'))
        .topIcon()
        .id('scan_page_goBack_yuv')
        .onClick(async () => {
          router.back();
        })
    }
  }
}

@Component
export struct ArkUiDrawView {
  @Prop positionArray: Position[];
  @Prop xComponentWidth: number;
  @Prop xComponentHeight: number;

  build() {
    Column() {
      Row()
        .angleSizes(this.positionArray[0], { width: { top: 3, left: 3, }, color: '#FFFFFF' })
      Row()
        .angleSizes(this.positionArray[1], { width: { top: 3, right: 3 }, color: '#FFFFFF' })
        .markAnchor({ x: 20, y: 0 })
      Row()
        .angleSizes(this.positionArray[2], { width: { bottom: 3, left: 3 }, color: '#FFFFFF' })
        .markAnchor({ x: 0, y: 20 })
      Row()
        .angleSizes(this.positionArray[3], { width: { bottom: 3, right: 3 }, color: '#FFFFFF' })
        .markAnchor({ x: 20, y: 20 })
    }
    .width(this.xComponentWidth)
    .height(this.xComponentHeight)
  }
}

@Entry
@Component
struct YUVScan {
  @State positionArkUi: Array<Position[]> = [];
  @State isOnPageShow: boolean = false;
  @State isReleaseCamera: boolean = false;
  @State cameraHeight: number = 640;
  @State cameraWidth: number = 360;
  @State isDialogShow: boolean = false;
  @State userGrant: boolean = false;
  @State surfaceId: string = '';
  @State cameraScreenOffsetX: number = 0;
  @State cameraScreenOffsetY: number = 0;
  @State result: Array<object> = [];
  @State isVertical: boolean = true;
  @State orientation: display.Orientation = 0;
  @State statusHeight: number = 39;
  @State multiCodeScanResult: Array<scanBarcode.ScanCodeRect> = [];
  private mXComponentController: XComponentController = new XComponentController();
  @State scanCodeRect: Array<scanBarcode.ScanCodeRect> = [];
  @State scanFlag: boolean = false;
  @State count: number = 0;
  private viewControl: customScan.ViewControl = { width: 1920, height: 1080, surfaceId: this.surfaceId };
  options: scanBarcode.ScanOptions = {
    scanTypes: [scanCore.ScanType.ALL],
    enableMultiMode: true,
    enableAlbum: true
  };
  private callback: AsyncCallback<scanBarcode.ScanResult[]> =
    async (error: BusinessError, result: scanBarcode.ScanResult[]) => {
      if (error) {
        hilog.info(0x0001, TAG, 'callback error: %{public}s ', JSON.stringify(error));
        return;
      }
      hilog.info(0x0001, TAG, 'callback result: %{public}s ', JSON.stringify(result));
    };
  //A callback that returns the camera frame
  private frameCallback: AsyncCallback<customScan.ScanFrame> =
    async (error: BusinessError, frameResult: customScan.ScanFrame) => {
      if (error) {
        hilog.error(0x0001, TAG, `frameCallback failed, code: ${error.code}, message: ${error.message}`);
        return;
      }
      // byteBuffer: array of YUV images captured by the camera
      hilog.info(0x0001, TAG, `frameCallback width: ${JSON.stringify(frameResult.width)}`);
      hilog.info(0x0001, TAG, `frameCallback height: ${JSON.stringify(frameResult.height)}`);
      hilog.info(0x0001, TAG, `frameCallback scanCodeRects: ${JSON.stringify(frameResult.scanCodeRects)}`);
      if ((this.count++ % 5) === 0) {
        this.multiCodeScanResult = [];
        this.positionArkUi = [];
        let ratio: number;
        if (this.isVertical) {
          ratio = this.cameraWidth / frameResult.height;
        } else {
          ratio = this.cameraHeight / frameResult.height;
        }
        if (frameResult && frameResult.scanCodeRects && frameResult.scanCodeRects.length > 0) {
          this.scanFlag = true;
          for (let i = 0; i < frameResult.scanCodeRects.length; i++) {
            let reactConverts: scanBarcode.ScanCodeRect
            let leftPoint: Position;
            if (this.isVertical) {
              let rect: scanBarcode.ScanCodeRect = frameResult.scanCodeRects[i];
              hilog.info(0x0001, TAG,
                `frameCallback rect: ${JSON.stringify(rect)}`);
              reactConverts = {
                left: rect.bottom * ratio,
                top: rect.left * ratio,
                right: rect.top * ratio,
                bottom: rect.right * ratio
              };
              hilog.info(0x0001, TAG,
                `frameCallback reactConverts: ${JSON.stringify(reactConverts)}`);
              leftPoint = {
                x: this.cameraWidth - reactConverts.left,
                y: reactConverts.top
              };
            } else {
              let rect: scanBarcode.ScanCodeRect = frameResult.scanCodeRects[i];
              hilog.info(0x0001, TAG,
                `frameCallback rect: ${JSON.stringify(rect)}`);
              reactConverts = {
                left: rect.left * ratio,
                top: rect.top * ratio,
                right: rect.right * ratio,
                bottom: rect.bottom * ratio
              };
              hilog.info(0x0001, TAG,
                `frameCallback reactConverts: ${JSON.stringify(reactConverts)}`);
              leftPoint = {
                x: reactConverts.left,
                y: reactConverts.top
              };
            }
            hilog.info(0x0001, TAG, `frameCallback leftPoint: ${JSON.stringify(leftPoint)}`);
            let width = Math.abs(reactConverts.left - reactConverts.right);
            let height = Math.abs(reactConverts.top - reactConverts.bottom);
            hilog.info(0x0001, TAG,
              `frameCallback leftPoint: ${JSON.stringify(leftPoint)}, width: ${width}, height: ${height}`);
            this.positionArkUi.push([
              { x: Number(leftPoint.x), y: Number(leftPoint.y) },
              { x: Number(leftPoint.x) + width, y: Number(leftPoint.y) },
              { x: Number(leftPoint.x), y: Number(leftPoint.y) + height },
              { x: Number(leftPoint.x) + width, y: Number(leftPoint.y) + height }]);
            hilog.info(0x0001, TAG, `frameCallback positionArkUi: ${JSON.stringify(this.positionArkUi)}`);
          }

          try {
            let file =
              fileIo.openSync("/data/storage/el2/base/haps/entry/files/IMG_" + this.getTimeStringInYYMMDD_HHMMSS() +
                ".yuv", fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
            fileIo.writeSync(file.fd, frameResult.byteBuffer);
            fileIo.closeSync(file);
          } catch (err) {
            hilog.error(DOMAIN, TAG, 'Invoke saveArrayBuffer2MediaLibrary failed, err: %{public}s',
              JSON.stringify(err));
          }
          hilog.info(0x0001, TAG, 'ScanFrame scanCodeRect: %{public}s ', JSON.stringify(this.scanCodeRect));
        } else {
          this.scanFlag = false;
        }
      }
    };
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDialogExample({
      action: this.openPermissionsInSystemSettings,
      cancel: this.existApp,
    }),
    autoCancel: false,
    customStyle: true,
    alignment: DialogAlignment.Center
  });

  openPermissionsInSystemSettings(): void {
    hilog.error(0x0001, TAG, `openPermissionsInSystemSettings`);
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
      hilog.info(0x0001, TAG, 'startAbility Success');
    }).catch((error: Error) => {
      hilog.info(0x0001, TAG, 'startAbility error: %{public}s', error);
    })
  }

  existApp() {
    this.isDialogShow = false;
    hilog.info(0x0001, TAG, 'Succeeded in exit app. isDialogShow: %{public}s', this.isDialogShow);
  }

  async requestCameraPermission() {
    let grantStatus = await PermissionsUtil.reqPermissionsFromUser();
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        // The user is authorized to continue to access the target operation.
        hilog.info(0x0001, TAG, `requestPermissionsFromUser success`);
        this.userGrant = true;
        if (this.isDialogShow) {
          this.isDialogShow = false;
          this.dialogController.close();
        }
        this.initCustomScan();
      } else {
        // The user rejects the authorization, prompts that the user must be authorized to access the functions of the current page, and guides the user to enable the corresponding permission in the system settings.
        hilog.error(0x0001, TAG, `requestPermissionsFromUser failed`);
        this.userGrant = false;
        if (!this.isDialogShow) {
          this.dialogController.open();
          this.isDialogShow = true;
        }
      }
    }
  }

  setDisplay() {
    // Default Portrait
    try {
      let displayClass = display.getDefaultDisplaySync();
      let windowSize: WindowSize;
      if (displayClass !== null) {
        windowSize = {
          width: displayClass.width,
          height: displayClass.height
        }
        this.setWindowSize(windowSize);
      }
    } catch (exception) {
      hilog.error(0x0001, TAG, 'Failed to obtain the default display object. Code: %{public}s ',
        JSON.stringify(exception));
    }
  }

  getOrientation() {
    let displayClass: display.Display | null = null;
    try {
      displayClass = display.getDefaultDisplaySync();
      this.orientation = displayClass.orientation;
    } catch (exception) {
      hilog.error(0x0001, TAG, 'Failed to obtain the default display object. exception: %{public}s',
        JSON.stringify(exception));
    }
  }

  async setWindowSize(windowSize: WindowSize): Promise<void> {
    this.getOrientation();
    let displayClass: WindowSize = windowSize;
    hilog.info(0x0001, TAG, 'windowSize Init: %{public}s', JSON.stringify(displayClass));
    if (displayClass) {
      let maxLen: number = px2vp(Math.max(displayClass.height, displayClass.width));
      let minLen: number = px2vp(Math.min(displayClass.height, displayClass.width));
      let ratio: number = 9 / 16;
      if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable') &&
        GlobalThisUtil.getProperty('hmsCore_scan_foldStatus') === 1) {
        ratio = 1;
      } else {
        ratio = 9 / 16;
      }
      hilog.info(0x0001, TAG, 'windowSize, maxLen: %{public}d, minLen: %{public}d', maxLen, minLen);
      if (this.orientation === 1 || this.orientation === 3) {
        // Landscape screen
        this.isVertical = false;
        if (ratio < minLen / maxLen) {
          this.cameraHeight = minLen;
          this.cameraWidth = minLen / ratio;
          this.cameraScreenOffsetX = (maxLen - this.cameraWidth) / 2;
          this.cameraScreenOffsetY = 0;
        } else {
          this.cameraHeight = maxLen * ratio;
          this.cameraWidth = maxLen;
          this.cameraScreenOffsetY = (minLen - this.cameraHeight) / 2;
          this.cameraScreenOffsetX = 0;
        }
      } else {
        // Portrait screen
        this.isVertical = true;
        if (displayClass.height >= displayClass.width) {
          if (ratio < minLen / maxLen) {
            this.cameraWidth = minLen;
            this.cameraHeight = minLen / ratio;
            this.cameraScreenOffsetY = (maxLen - this.cameraHeight) / 2;
            this.cameraScreenOffsetX = 0;
          } else {
            this.cameraHeight = maxLen;
            this.cameraWidth = maxLen * ratio;
            this.cameraScreenOffsetX = (minLen - this.cameraWidth) / 2;
            this.cameraScreenOffsetY = 0;
          }
        }
      }
      hilog.info(0x0001, TAG, 'setWindowSize, isReleaseCamera: %{public}s, isOnPageShow: %{public}s',
        this.isReleaseCamera, this.isOnPageShow);
      if (this.isReleaseCamera && this.isOnPageShow) {
        this.initCamera();
      }
      hilog.info(0x0001, TAG,
        'setDisplay End, cameraHeight: %{public}d, cameraWidth: %{public}d, cameraScreenOffsetX: %{public}d, cameraScreenOffsetY: %{public}d',
        this.cameraHeight, this.cameraWidth, this.cameraScreenOffsetX, this.cameraScreenOffsetY);
    }
  }

  windowSizeSubscribe(): void {
    emitter.on({ eventId: CommonConstants.WINDOW_SIZE_CHANGE }, async () => {
      if (GlobalThisUtil.getProperty('hmsCore_scan_foldStatus') === 1 ||
        GlobalThisUtil.getProperty('hmsCore_scan_foldStatus') === 2) {
        await this.releaseCamera();
        this.setDisplay();
      }
    });
  }

  aboutToAppear() {
    this.result = [];
    this.statusHeight = GlobalThisUtil.getProperty('scan_topRect_height');
    if (GlobalThisUtil.getProperty('scan_topRect_height')) {
      this.statusHeight = px2vp(GlobalThisUtil.getProperty('scan_topRect_height'));
    }
    this.setDisplay();
    if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable')) {
      this.windowSizeSubscribe();
      display.on('foldStatusChange', async (foldStatus: display.FoldStatus) => {
        if (foldStatus === 1 || foldStatus === 2) {
          GlobalThisUtil.setProperty('hmsCore_scan_foldStatus', foldStatus);
        }
      });
    }
  }

  aboutToDisappear() {
    hilog.info(0x0001, TAG, ' AboutToDisappear lifecycle start.')
    if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable')) {
      emitter.off(CommonConstants.WINDOW_SIZE_CHANGE);
      display.off('foldStatusChange');
    }
  }

  async onPageShow() {
    this.isReleaseCamera = false;
    this.isOnPageShow = true;
    hilog.info(0x0001, TAG, 'onPageShow isDialogShow : %{public}s ', this.isDialogShow)
    const permissions: Array<Permissions> = ['ohos.permission.CAMERA'];
    let grantStatus = await PermissionsUtil.checkAccessToken(permissions[0]);
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      // You have been authorized to continue to access the target operation.
      this.userGrant = true;
      this.initCustomScan();
      if (this.surfaceId) {
        this.startCustomScan();
      }
    } else {
      // Applying for Camera Permissions
      this.requestCameraPermission();
    }
  }

  initCamera() {
    this.isReleaseCamera = false;
    this.initCustomScan();
    this.startCustomScan();
  }

  // Customized initialization interface
  initCustomScan() {
    try {
      customScan.init(this.options);
      hilog.info(0x0001, TAG, 'init hasOptions success');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Catch init error: %{public}s', JSON.stringify(error));
    }
  }

  // Start the camera to scan the code
  startCustomScan() {
    this.viewControl = { width: this.cameraWidth, height: this.cameraHeight, surfaceId: this.surfaceId };
    try {
      this.scanCodeRect = [];
      this.scanFlag = false;
      hilog.error(DOMAIN, TAG, 'viewControl: %{public}s', JSON.stringify(this.viewControl));
      customScan.start(this.viewControl, this.callback, this.frameCallback);
      hilog.info(0x0001, TAG, 'start success');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Catch start error: %{public}s', JSON.stringify(error));
    }
  }

  async stopCamera() {
    if (!this.isReleaseCamera) {
      try {
        await customScan.stop();
        hilog.info(0x0001, TAG, 'stop success');
      } catch (error) {
        hilog.error(DOMAIN, TAG, 'Catch: stopCamera: %{public}s', JSON.stringify(error));
      }
    }
  }

  async releaseCamera() {
    if (!this.isReleaseCamera) {
      await this.stopCamera();
      try {
        await customScan.release();
        this.isReleaseCamera = true;
        hilog.info(0x0001, TAG, 'release success');
      } catch (error) {
        hilog.error(DOMAIN, TAG, "Catch: releaseCamera: %{public}s", JSON.stringify(error));
      }
    }
  }

  async onPageHide() {
    hilog.info(0x0001, TAG, ' OnPageHide lifecycle start.');
    this.dialogController.close();
    this.isDialogShow = false;
    this.isOnPageShow = false;
    this.releaseCamera();
  }

  @Builder
  TopTool() {
    Column() {
      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        closeImage()
      }.topFlex()
      .padding({
        top: this.statusHeight,
        left: PADDING_24,
        right: PADDING_24
      })

      Column() {
        Text($r('app.string.Scan_barcode')).scanTitle()
        Text($r('app.string.Scan_barcode_tips')).scanTips()
      }.topText()
    }
    .height(146)
    .width('100%')
  }

  build() {
    Stack() {
      if (this.userGrant) {
        Column() {
          XComponent({
            id: 'componentId',
            type: 'surface',
            controller: this.mXComponentController
          })
            .onLoad(() => {
              hilog.info(0x0001, TAG, 'onLoad is called');
              this.surfaceId = this.mXComponentController.getXComponentSurfaceId();
              hilog.info(0x0001, TAG, 'onLoad surfaceId unreboot: %{public}s', this.surfaceId);
              this.startCustomScan();
            })
            .height(this.cameraHeight)
            .width(this.cameraWidth)
            .position({ x: this.cameraScreenOffsetX, y: this.cameraScreenOffsetY })
        }
        .height('100%')
        .width('100%')
        .position({ x: 0, y: 0 })
      }

      Column() {
        this.TopTool()
        Column() {
        }
        .layoutWeight(1)
        .width('100%')

      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)

      if (this.scanFlag) {
        ForEach(this.positionArkUi, (item: Array<Position>) => {
          ArkUiDrawView({
            positionArray: item,
            xComponentWidth: this.cameraWidth,
            xComponentHeight: this.cameraHeight,
          })
        }, (item: Array<Position>, index: number) => {
          return index + '__' + JSON.stringify(item)
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.userGrant ? Color.Transparent : Color.Black)
  }

  getTimeStringInYYMMDD_HHMMSS(): string {
    const curDate = new Date();
    let year = curDate.getFullYear();
    let mouth = this.get2DigitStr(curDate.getMonth() + 1);
    let date = this.get2DigitStr(curDate.getDate());
    let hours = this.get2DigitStr(curDate.getHours());
    let minutes = this.get2DigitStr(curDate.getMinutes());
    let seconds = this.get2DigitStr(curDate.getSeconds());
    return `${year}${mouth}${date}_${hours}${minutes}${seconds}`;
  }

  get2DigitStr(num: number): string {
    let numStr = num.toString();
    const numStrLen = numStr.length;
    if (numStrLen === 1) {
      numStr = `0${numStr}`;
    } else {
      numStr = numStr.substring(numStrLen - 2, numStrLen);
    }
    return numStr;
  }
}