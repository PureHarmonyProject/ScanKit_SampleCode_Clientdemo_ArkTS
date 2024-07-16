import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { picker, fileIo } from '@kit.CoreFileKit';
import { router, display, curves, TipsDialog } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { scanBarcode, customScan, scanCore, detectBarcode } from '@kit.ScanKit';
import { common, abilityAccessCtrl, Permissions, Want } from '@kit.AbilityKit';
import { emitter } from '@kit.BasicServicesKit';
import { WindowSize } from '../../common/Utils';
import { CodeLayout } from './CommonCodeLayout';
import { PermissionsUtil } from './PermissionsUtil'
import { GlobalThisUtil } from '../../common/GlobalThisUtil';
import { CommonConstants } from '../customScanDefault/constants/CommonConstants';

let maxPaddingStart = 24;
let maxPaddingEnd = 24;

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
  .padding({ left: maxPaddingStart, right: maxPaddingEnd })
  .linearGradient({
    angle: 180,
    colors: [['rgba(0,0,0,0.5)', 0.0], ['rgba(0,0,0,0)', 1.0]]
  })
}

@Extend(Column)
function topText() {
  .margin({ left: maxPaddingStart, right: maxPaddingEnd, top: 24 })
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

@Extend(Image)
function lightIcon() {
  .width(40)
  .height(40)
  .margin({ top: 24, bottom: 4 })
}

@Extend(Text)
function lightText() {
  .fontColor('rgba(255,255,255,0.9)')
  .textAlign(TextAlign.Center)
  .fontSize(14)
}

@Extend(Column)
function mainStyle() {
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
}

@Extend(Column)
function maskStyle() {
  .width('100%')
  .height('100%')
  .backgroundColor('rgba(0,0,0,0.5)')
  .animation({
    duration: 350, // Animation Duration
    curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // Animation Curves
    delay: 0,
    iterations: 1,
    playMode: PlayMode.Alternate,
  })
}

const TAG = 'Scan SampleCode CustomScan';


@Component
struct closeImage {
  build() {
    Column() {
      Image($rawfile('scan_back.svg'))
        .topIcon()
        .id('scan_page_goBack')
        .onClick(async () => {
          router.back();
        })
    }
  }
}

@Entry
@Component
struct ScanPage {
  @State isOnPageShow: boolean = false;
  @State isReleaseCamera: boolean = false;
  @State isFlashlight: boolean = false; // Whether the flashlight is turned on.
  @State isShowLightIcon: boolean = false; // Whether to display the flashlight.
  @State isSensorLight: boolean = false; // Record the current environment brightness status.
  @State isScanned: boolean = false;
  @State cameraHeight: number = 640; // Sets the XComponent height. The default unit is vp.
  @State cameraWidth: number = 360; // Sets the XComponent width. The default unit is vp.
  @State isDialogShow: boolean = false;
  @State userGrant: boolean = false;
  private isUserGrantDialog: number = 0;
  @State surfaceId: string = '';
  @State cameraScreenOffsetX: number = 0;
  @State cameraScreenOffsetY: number = 0;
  @State maskOpacity: number = 0;
  @State isStop: boolean = false;
  @State hasOptions: boolean = false;
  @State result: Array<object> = [];
  @State isVertical: boolean = true;
  @State orientation: display.Orientation = 0;
  @State statusHeight: number = 39;
  @State zoomValue: number = 1;
  @State setZoomValue: number = 1;
  @State scaleValue: number = 1;
  @State pinchValue: number = 1;
  private displayHeight: number = 0;
  private displayWidth: number = 0;
  private mXComponentController: XComponentController = new XComponentController();
  private viewControl: customScan.ViewControl = { width: 1920, height: 1080, surfaceId: this.surfaceId };
  options: scanBarcode.ScanOptions = {
    scanTypes: [scanCore.ScanType.ALL],
    enableMultiMode: true,
    enableAlbum: true
  }
  dialogController: CustomDialogController = new CustomDialogController({
    builder: TipsDialog({
      title: $r('app.string.Scan_access_not_enabled'),
      content: $r('app.string.Scan_access_tips'),
      primaryButton: {
        value: $r('app.string.Scan_got_it'),
        action: () => {
          this.existApp();
        },
      },
      secondaryButton: {
        value: $r('app.string.Scan_settings'),
        action: () => {
          this.openPermissionsInSystemSettings();
        }
      },
    }),
    autoCancel: false,
    customStyle: false,
    alignment: DialogAlignment.Center
  })

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
    this.dialogController.close();
    hilog.info(0x0001, TAG, 'Start to permissionUsedRecord. isDialogShow: %{public}s', this.isDialogShow);
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
        try {
          if (this.hasOptions) {
            customScan.init(this.options)
            hilog.info(0x0001, TAG, 'init hasOptions success');
          } else {
            customScan.init()
            hilog.info(0x0001, TAG, 'init no options success');
          }
        } catch (error) {
          hilog.error(0x0001, TAG, 'Catch: init: %{public}s', JSON.stringify(error));
        }
      } else {
        // The user rejects the authorization, prompts that the user must be authorized to access the functions of the current page, and guides the user to enable the corresponding permission in the system settings.
        hilog.error(0x0001, TAG, `requestPermissionsFromUser failed`);
        this.userGrant = false;
        if (!this.isDialogShow) {
          this.dialogController.open();
          this.isDialogShow = true;
        }
        // 已扫描出结果
        if (!this.isDialogShow) {
          this.isUserGrantDialog = setInterval(() => {
            if (this.isScanned) {
              clearInterval(this.isUserGrantDialog);
              this.isUserGrantDialog = -1;
              this.isDialogShow = false;
              this.dialogController.close();
            }
          }, 300);
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
        this.displayWidth = displayClass.width;
        this.displayHeight = displayClass.height;
        windowSize = {
          width: displayClass.width,
          height: displayClass.height
        };
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
      let maxLen: number = px2lpx(Math.max(displayClass.height, displayClass.width));
      let minLen: number = px2lpx(Math.min(displayClass.height, displayClass.width));
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
    // 订阅WINDOW_SIZE
    emitter.on({ eventId: CommonConstants.WINDOW_SIZE_CHANGE }, async () => {
      if (GlobalThisUtil.getProperty('hmsCore_scan_foldStatus') === 1 ||
        GlobalThisUtil.getProperty('hmsCore_scan_foldStatus') === 2) {
        await this.releaseCamera();
        this.setDisplay();
      }
    });
  }

  aboutToAppear() {
    let params = router.getParams() as Record<string, string | boolean>;
    this.hasOptions = params.hasOptions as boolean;
    this.result = [];
    this.statusHeight = GlobalThisUtil.getProperty('scan_topRect_height');
    if (GlobalThisUtil.getProperty('scan_topRect_height')) {
      this.statusHeight = px2vp(GlobalThisUtil.getProperty('scan_topRect_height'));
    }
    this.setDisplay();
    if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable')) {
      this.windowSizeSubscribe();
      display.on('foldStatusChange', async (foldStatus: display.FoldStatus) => {
        // 1:展开态，2：折叠态
        if (foldStatus === 1 || foldStatus === 2) {
          this.isScanned = false;
          this.isFlashlight = false;
          GlobalThisUtil.setProperty('hmsCore_scan_foldStatus', foldStatus);
        }
      });
    }
  }

  aboutToDisappear() {
    hilog.info(0x0001, TAG, ' AboutToDisappear lifecycle start.');
    if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable')) {
      emitter.off(CommonConstants.WINDOW_SIZE_CHANGE);
      display.off('foldStatusChange');
    }
  }

  async onPageShow() {
    this.isShowLightIcon = false;
    this.maskOpacity = 0;
    this.isScanned = false;
    this.isReleaseCamera = false;
    this.isOnPageShow = true;
    hilog.info(0x0001, TAG, 'onPageShow isDialogShow : %{public}s ', this.isDialogShow);
    const permissions: Array<Permissions> = ['ohos.permission.CAMERA'];
    let grantStatus = await PermissionsUtil.checkAccessToken(permissions[0]);
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      // You have been authorized to continue to access the target operation.
      this.userGrant = true;
      try {
        if (this.hasOptions) {
          customScan.init(this.options)
          hilog.info(0x0001, TAG, 'init hasOptions success');
        } else {
          customScan.init()
          hilog.info(0x0001, TAG, 'init no options success');
        }
      } catch (error) {
        hilog.error(0x0001, TAG, 'Catch: init: %{public}s', JSON.stringify(error));
      }
      if (this.surfaceId) {
        this.startCustomScan();
      }
    } else {
      // Applying for Camera Permissions
      this.requestCameraPermission();
    }
  }

  // Start the camera to scan the code
  startCustomScan() {
    this.viewControl = { width: this.cameraWidth, height: this.cameraHeight, surfaceId: this.surfaceId };
    try {
      customScan.start(this.viewControl).then(async (result: Array<scanBarcode.ScanResult>) => {
        hilog.info(0x0001, TAG, "Promise scan result: %{public}s", JSON.stringify(result));
        try {
          await customScan.stop();
        } catch (error) {
          hilog.error(0x0001, TAG, "Catch: stop: %{public}s", JSON.stringify(error));
        }
        if (!this.isScanned) {
          hilog.info(0x0001, TAG, 'isScanned: %{public}s ', this.isScanned);
          this.isScanned = true;
          this.maskOpacity = 1;
          this.result = result;
        }
      }).catch((failResult: BusinessError) => {
        hilog.error(0x0001, TAG, "Promise scan failResult: %{public}s", JSON.stringify(failResult));
      })
    } catch (error) {
      hilog.error(0x0001, TAG, "Catch: start: %{public}s", JSON.stringify(error));
    }
    try {
      customScan.on('lightingFlash', (error, isLightingFlash) => {
        if (error) {
          hilog.error(0x0001, TAG, 'lightingFlash callback error: %{public}s', JSON.stringify(error));
          return;
        }
        if (isLightingFlash) {
          this.isShowLightIcon = true;
        } else {
          if (!customScan.getFlashLightStatus()) {
            this.isShowLightIcon = false;
          }
        }
        this.isSensorLight = isLightingFlash;
      });
    } catch (error) {
      hilog.error(0x0001, TAG, "Catch: on('lightingFlash'): %{public}s", JSON.stringify(error));
    }
  }

  // Customized initialization interface
  initCamera() {
    hilog.info(0x0001, TAG, 'initCamera, hasOptions: %{public}s', this.hasOptions);
    this.isReleaseCamera = false;

    try {
      if (this.hasOptions) {
        customScan.init(this.options);
        hilog.info(0x0001, TAG, 'init hasOptions success');
      } else {
        customScan.init();
        hilog.info(0x0001, TAG, 'init no options success');
      }
    } catch (error) {
      hilog.error(0x0001, TAG, 'Catch: init: %{public}s', JSON.stringify(error));
    }

    this.startCustomScan();
  }

  async stopCamera() {
    if (!this.isReleaseCamera) {
      try {
        await customScan.stop();
      } catch (error) {
        hilog.error(0x0001, TAG, 'Catch: stopCamera: %{public}s', JSON.stringify(error));
      }
    }
  }

  async releaseCamera() {
    if (!this.isReleaseCamera) {
      await this.stopCamera();
      try {
        await customScan.release();
        this.isReleaseCamera = true;
      } catch (error) {
        hilog.error(0x0001, TAG, "Catch: releaseCamera: %{public}s", JSON.stringify(error));
      }
    }
  }

  async onPageHide() {
    hilog.info(0x0001, TAG, ' OnPageHide lifecycle start.')
    this.isFlashlight = false;
    this.isSensorLight = false;
    this.dialogController.close();
    this.isDialogShow = false;
    this.maskOpacity = 0;
    this.isReleaseCamera = true;
    this.isOnPageShow = false;
    try {
      customScan.off('lightingFlash');
    } catch (error) {
      hilog.error(0x0001, TAG, "Catch: off lightingFlash: %{public}s", JSON.stringify(error));
    }
    try {
      if (!this.isScanned) {
        await customScan.stop();
      }
    } catch (error) {
      hilog.error(0x0001, TAG, 'Catch: stop: %{public}s', JSON.stringify(error));
    }
    try {
      await customScan.release();
    } catch (error) {
      hilog.error(0x0001, TAG, 'Catch: release: %{public}s', JSON.stringify(error));
    }
    this.isScanned = false;
  }

  @Builder
  TopTool() {
    Column() {
      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        closeImage()
        Image($rawfile('scan_photo.svg'))
          .topIcon()
          .id('scan_page_openPicker')
          .draggable(false)
          .opacity(this.isScanned ? 0.4 : 1)
          .onClick(async () => {
            try {
              let photoOption = new picker.PhotoSelectOptions();
              photoOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
              photoOption.maxSelectNumber = 1;
              let options: scanBarcode.ScanOptions = {
                scanTypes: [scanCore.ScanType.QR_CODE],
                enableMultiMode: true,
                enableAlbum: true
              }
              let photoPicker = new picker.PhotoViewPicker();
              photoPicker.select(photoOption).then((photoResult) => {
                hilog.info(0x0001, TAG, 'photoResult: %{public}s', JSON.stringify(photoResult));
                let infoW: number = 0;
                let infoH: number = 0;
                try {
                  let file = fileIo.openSync(photoResult.photoUris[0], fileIo.OpenMode.READ_ONLY);
                  const imageSourceApi = image.createImageSource(file.fd);
                  imageSourceApi.getImageInfo(0, (error: BusinessError, imageInfo) => {
                    if (imageInfo == undefined) {
                      hilog.error(0x0001, TAG, 'Failed to obtain the image pixel map information: %{public}s',
                        JSON.stringify(error));
                    }
                    hilog.info(0x0001, TAG, 'imageInfo: %{public}s', JSON.stringify(typeof imageInfo));
                    hilog.info(0x0001, TAG, 'imageInfo: %{public}s', JSON.stringify(imageInfo));
                    infoW = imageInfo.size.width;
                    infoH = imageInfo.size.height;
                  })
                } catch (error) {
                  hilog.error(0x0001, TAG, 'photoPicker error: %{public}s', error);
                }
                try {
                  let inputImage: detectBarcode.InputImage = { uri: photoResult.photoUris[0] }
                  detectBarcode.decode(inputImage, options).then((result: Array<scanBarcode.ScanResult>) => {
                    // If the value is not identified, the value is returned without assigning a value.
                    if (result && result.length > 0) {
                      router.pushUrl({
                        url: 'pages/detectBarcode/CommonCodeLayout',
                        params: {
                          result: result,
                          uri: photoResult.photoUris[0],
                          infoW: infoW,
                          infoH: infoH,
                          options: options
                        }
                      });
                    } else {
                      hilog.error(0x0001, TAG, 'Promise scan result error');
                    }
                  }).catch((failResult: BusinessError) => {
                    hilog.error(0x0001, TAG, 'Promise scan result: %{public}s', JSON.stringify(failResult));
                  });
                } catch (error) {
                  hilog.error(0x0001, TAG, 'Catch: failResult: %{public}s', JSON.stringify(error));
                }
              })
            } catch (error) {
              hilog.error(0x0001, TAG, 'error : %{public}s', error);
            }
          })
      }.topFlex()
      .padding({
        top: this.statusHeight,
        left: maxPaddingStart,
        right: maxPaddingEnd
      })

      Column() {
        Text($r('app.string.Scan_barcode')).scanTitle()
        Text($r('app.string.Scan_barcode_tips')).scanTips()
      }.topText()
    }
    .height(146)
    .width('100%')
  }

  @Builder
  BottomFooter() {
    Column() {
      Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        Column() {
          Image($rawfile(this.isFlashlight ? 'scan_light_on.svg' : 'scan_light_off.svg')).lightIcon().draggable(false)
          Text(this.isFlashlight ? $r('app.string.Scan_light_to_off') : $r('app.string.Scan_light_to_on')).lightText()
        }
        .onClick(async () => {
          try {
            this.isFlashlight = customScan.getFlashLightStatus();
            if (!this.isFlashlight) {
              customScan.openFlashLight();
            } else {
              customScan.closeFlashLight();
              setTimeout(() => {
                this.isShowLightIcon = this.isSensorLight;
              }, 200);
            }
            this.isFlashlight = customScan.getFlashLightStatus();
          } catch (error) {
            hilog.error(0x0001, TAG, 'Catch: stop: %{public}s', JSON.stringify(error));
          }
        })
      }
      .width('100%')
      .visibility(this.isShowLightIcon ? Visibility.Visible : Visibility.Hidden)

      if (this.userGrant) {
        Row() {
          Button($r('app.string.decode_zoom_current'))
            .onClick(() => {
              // Set Camera Zoom
              this.zoomValue = this.zoomValue;
              this.setZoomValue = this.zoomValue;
              customScan.setZoom(this.zoomValue);
            })
          Text(this.setZoomValue + '')
            .offset({
              x: -20
            })
            .fontColor(Color.White)
        }.margin(10)

        Row() {
          TextInput({ placeholder: $r('app.string.decode_zoom_enter') })
            .width(200)
            .type(InputType.Number)
            .borderWidth(1)
            .backgroundColor(Color.White)
            .onChange(value => {
              this.zoomValue = Number(value);
            })
        }
      }
    }
    .height(223)
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
            .height(this.cameraHeight + 'lpx')
            .width(this.cameraWidth + 'lpx')
            .position({ x: this.cameraScreenOffsetX + 'lpx', y: this.cameraScreenOffsetY + 'lpx' })
        }
        .height('100%')
        .width('100%')
        .position({ x: 0, y: 0 })
      }
      // mask layer
      if (this.isScanned) {
        Column() {
        }.maskStyle()
        .opacity(this.maskOpacity)
      }

      Column() {
        this.TopTool()
        Column() {
        }
        .layoutWeight(1)
        .width('100%')

        this.BottomFooter()
      }
      .mainStyle()

      if (this.isScanned) {
        Column() {
          CodeLayout({
            resultCode: 0,
            cameraWidth: this.cameraWidth,
            cameraHeight: this.cameraHeight,
            isVertical: this.isVertical,
            result: this.result,
            isScanned: $isScanned,
            cameraScreenOffsetX: this.cameraScreenOffsetX,
            cameraScreenOffsetY: this.cameraScreenOffsetY,
          })
        }
      }
      if (this.isScanned) {
        closeImage()
          .position({ x: 24, y: this.statusHeight })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.userGrant ? Color.Transparent : Color.Black)
    .onClick((event: ClickEvent) => {
      let x1 = vp2px(event.displayY) / (this.displayHeight + 0.0);
      let y1 = 1.0 - (vp2px(event.displayX) / (this.displayWidth + 0.0));
      hilog.info(0x0001, TAG, 'onLoad setFocusPoint x1: %{public}d', x1);
      hilog.info(0x0001, TAG, 'onLoad setFocusPoint y1: %{public}d', y1);
      try {
        customScan.setFocusPoint({ x: x1, y: y1 });
      } catch (error) {
        hilog.error(0x0001, TAG, 'Catch: setFocusPoint: %{public}s', JSON.stringify(error));
      }
      setTimeout(() => {
        try {
          customScan.resetFocus();
        } catch (error) {
          hilog.error(0x0001, TAG, 'Catch: setFocus: %{public}s', JSON.stringify(error));
        }
      }, 200);
    })
    .gesture(PinchGesture({ fingers: 2 })
      .onActionStart((_: GestureEvent) => {
        hilog.info(0x0001, TAG, 'Pinch start');
      })
      .onActionUpdate((event: GestureEvent) => {
        if (event) {
          this.scaleValue = event.scale;
        }
      })
      .onActionEnd((_: GestureEvent) => {
        try {
          let zoom = customScan.getZoom();
          this.pinchValue = this.scaleValue * zoom;
          customScan.setZoom(this.pinchValue);
          hilog.info(0x0001, TAG, 'Pinch end');
        } catch (error) {
          hilog.error(0x0001, TAG, 'Catch: setFocusPoint: %{public}s', JSON.stringify(error));
        }
      }))
  }
}
