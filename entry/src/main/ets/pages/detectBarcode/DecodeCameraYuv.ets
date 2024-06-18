import { camera } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { display } from '@kit.ArkUI';
import { detectBarcode, scanBarcode, scanCore } from '@kit.ScanKit';
import { GlobalThisUtil } from '../../common/GlobalThisUtil';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'Scan SampleCode DecodeCameraYuv';
const CAMERA_1080: number = 1080;
const CAMERA_1920: number = 1920;

@Entry
@Component
struct CameraHome {
  mXComponentController: XComponentController = new XComponentController();
  @State isUserGrant: boolean = false;
  @State xComponentHeight: number = 1;
  @State xComponentWidth: number = 1;
  @State previewScreenOffsetX: number = 0;
  @State previewScreenOffsetY: number = 0;
  @State scanResultPoints: Array<scanBarcode.ScanCodeRect> = [];
  @State cornerPoints: Array<Array<scanBarcode.Point>> = [];
  // CameraKit
  private cameraManager: camera.CameraManager = camera.getCameraManager(GlobalThisUtil.getProperty('abilityContext'));
  private photoSession: camera.PhotoSession | undefined = undefined;
  private cameraInput: camera.CameraInput | undefined = undefined;
  private previewOutput: camera.PreviewOutput | undefined = undefined;
  private previewOutput2: camera.PreviewOutput | undefined = undefined;
  private isDecoding: boolean = false;
  private adaptRatio: number = 1.0;

  async reqPermissionsFromUser(): Promise<void> {
    let context = getContext(this) as common.UIAbilityContext;
    let permission: boolean = await this.requestPermissionsFromUserFn(context);
    if (permission) {
      this.isUserGrant = true;
    }
  }

  requestPermissionsFromUserFn(context: common.UIAbilityContext): Promise<boolean> {
    let atManager = abilityAccessCtrl.createAtManager();
    return new Promise((resolve, reject) => {
      atManager.requestPermissionsFromUser(context, ['ohos.permission.CAMERA']).then((data) => {
        let grantStatus: Array<number> = data.authResults;
        let length: number = grantStatus.length;
        for (let i = 0; i < length; i++) {
          if (grantStatus[i] === 0) {
            // The user is authorized to continue to access the target operation.
            resolve(true);
          } else {
            // The user rejects the authorization,
            // prompts that the user must be authorized to access the functions of the current page,
            // and guides the user to enable the corresponding permission in the system settings.
            reject(false);
          }
        }
      }).catch((err: BusinessError) => {
        hilog.error(0x0001, TAG, 'requestPermissionsFromUser failed error: %{public}s', JSON.stringify(err));
        reject(false);
      })
    });
  }

  async aboutToAppear() {
    this.setDisplay();
  }

  setDisplay() {
    try {
      let displayClass = display.getDefaultDisplaySync();
      if (displayClass) {
        let widthVp: number = px2vp(displayClass.width);
        let heightVp: number = px2vp(displayClass.height);
        let ratio: number = CAMERA_1080 / CAMERA_1920;
        this.xComponentHeight = heightVp;
        this.xComponentWidth = heightVp * ratio;
        this.previewScreenOffsetX = (widthVp - this.xComponentWidth) / 2;
        this.previewScreenOffsetY = 0;
        this.adaptRatio = this.xComponentWidth / CAMERA_1080;
      }
    } catch (error) {
      hilog.error(0x0001, TAG, 'getDefaultDisplaySync failed error: %{public}s', JSON.stringify(error));
    }
  }

  aboutToDisappear(): void {
    this.stopCamera();
  }

  async onPageShow(): Promise<void> {
    if (!this.isUserGrant) {
      await this.reqPermissionsFromUser();
    } else {
      this.xComponentInit();
    }
  }

  onPageHide(): void {
    this.stopCamera();
  }

  stopCamera() {
    if (this.photoSession) {
      // Stop current camera session.
      this.photoSession.stop();
      // Release camera input.
      if (this.cameraInput) {
        this.cameraInput.close();
      }
      // Release camera preview.
      if (this.previewOutput) {
        this.previewOutput.release();
      }
      // Release second camera preview.
      if (this.previewOutput2) {
        this.previewOutput2.release();
      }
      // Release camera session.
      this.photoSession.release();
      this.photoSession = undefined;
    }
  }

  build() {
    Stack() {
      // Create XComponent.
      if (this.isUserGrant) {
        Column() {
          XComponent({
            id: 'xcomponent',
            type: XComponentType.SURFACE,
            controller: this.mXComponentController
          })
            .onLoad(() => {
              this.xComponentInit();
            })
            .width(this.xComponentWidth)
            .height(this.xComponentHeight)
            .position({
              x: this.previewScreenOffsetX,
              y: this.previewScreenOffsetY
            })
        }
        .width('100%')
        .height('100%')
      }

      // Draw center point.
      Column() {
        if (this.scanResultPoints && this.scanResultPoints.length > 0) {
          ForEach(this.scanResultPoints, (rect: scanBarcode.ScanCodeRect) => {
            Image($rawfile('scan_selected.svg'))
              .position({
                x: (CAMERA_1080 - rect.bottom + CAMERA_1080 - rect.top) / 2 * this.adaptRatio,
                y: (rect.left + rect.right) / 2 * this.adaptRatio
              })
              .width(40).height(40)
              .markAnchor({ x: 20, y: 20 })
          })
        }
      }
      .width(this.xComponentWidth)
      .height(this.xComponentHeight)
      .position({
        x: this.previewScreenOffsetX,
        y: 0
      })

      // Draw QRCode corner points.
      Column() {
        if (this.cornerPoints && this.cornerPoints.length > 0) {
          ForEach(this.cornerPoints, (points: Array<scanBarcode.Point>) => {
            ForEach(points, (point: scanBarcode.Point) => {
              Row() {
              }
              .width(8)
              .height(8)
              .backgroundColor(Color.Red)
              .position({ x: (CAMERA_1080 - point.y) * this.adaptRatio, y: point.x * this.adaptRatio })
            })
          })
        }
      }
      .width(this.xComponentWidth)
      .height(this.xComponentHeight)
      .position({
        x: this.previewScreenOffsetX,
        y: 0
      })
    }
  }

  xComponentInit() {
    this.mXComponentController.setXComponentSurfaceRect({
      surfaceWidth: vp2px(this.xComponentWidth),
      surfaceHeight: vp2px(this.xComponentHeight)
    });
    let surfaceId: string = this.mXComponentController.getXComponentSurfaceId();

    try {
      // Create ImageReceiver Object.
      let size: image.Size = {
        width: CAMERA_1080,
        height: CAMERA_1920
      }
      let receiver: image.ImageReceiver = image.createImageReceiver(size, image.ImageFormat.JPEG, 8);

      this.startPreviewOutput(this.cameraManager, surfaceId, receiver);
    } catch (error) {
      hilog.error(0x0001, TAG, 'Failed to create the PreviewOutput instance error: %{public}s', JSON.stringify(error));
    }
  }

  async startPreviewOutput(
    cameraManager: camera.CameraManager, xComponentSurfaceId: string, receiver: image.ImageReceiver): Promise<void> {
    // CameraKit
    // Get supported camera device.
    let camerasDevices: Array<camera.CameraDevice> = cameraManager.getSupportedCameras();

    // Get supported mode.
    let sceneModes: Array<camera.SceneMode> = cameraManager.getSupportedSceneModes(camerasDevices[0]);
    let isSupportPhotoMode: boolean = sceneModes.indexOf(camera.SceneMode.NORMAL_PHOTO) >= 0;
    if (!isSupportPhotoMode) {
      return;
    }

    let cameraProfile: camera.Profile = {
      format: camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP,
      size: {
        "width": CAMERA_1920,
        "height": CAMERA_1080
      },
    }

    this.previewOutput = cameraManager.createPreviewOutput(cameraProfile, xComponentSurfaceId);

    let imageReceiverSurfaceId: string = await receiver.getReceivingSurfaceId();
    this.previewOutput2 = cameraManager.createPreviewOutput(cameraProfile, imageReceiverSurfaceId);

    this.cameraInput = cameraManager.createCameraInput(camerasDevices[0]);

    await this.cameraInput.open();

    this.photoSession =
      cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;

    this.photoSession.beginConfig();
    this.photoSession.addInput(this.cameraInput);
    this.photoSession.addOutput(this.previewOutput);
    this.photoSession.addOutput(this.previewOutput2);
    await this.photoSession.commitConfig();

    await this.photoSession.start();

    // Get camera preview buffer.
    this.onImageArrival(receiver);
  }

  onImageArrival(receiver: image.ImageReceiver): void {
    receiver.on('imageArrival', () => {
      receiver.readNextImage((err: BusinessError, nextImage: image.Image) => {
        hilog.info(0x0001, TAG, 'Receiver.readNextImage success');
        if (err || nextImage === undefined) {
          hilog.error(0x0001, TAG, 'receiver.readNextImage failed, err: ' + JSON.stringify(err));
          return;
        }
        nextImage.getComponent(image.ComponentType.JPEG, (err: BusinessError, imgComponent: image.Component) => {
          if (err || nextImage === undefined) {
            hilog.error(0x0001, TAG, 'readNextImage failed');
            return;
          }

          if (!this.isDecoding && imgComponent && imgComponent.byteBuffer as ArrayBuffer) {
            // Decode camera preview buffer.
            // Note: Cameras and camera previews aren’t always in the same orientation.
            this.decodeImageBuffer(imgComponent, CAMERA_1920, CAMERA_1080);
          }
          nextImage.release();
        })
      })
    })
  }

  decodeImageBuffer(imgComponent: image.Component, width: number, height: number) {
    try {
      let byteImg: detectBarcode.ByteImage = {
        byteBuffer: imgComponent.byteBuffer,
        width: width,
        height: height,
        format: detectBarcode.ImageFormat.NV21
      }

      let options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.QR_CODE],
        enableMultiMode: true,
        enableAlbum: false
      }

      this.scanResultPoints = [];
      this.cornerPoints = [];
      this.isDecoding = true;
      // Decode image buffer.
      detectBarcode.decodeImage(byteImg, options).then((res: detectBarcode.DetectResult) => {
        let results: Array<scanBarcode.ScanResult> = res.scanResults;

        results.forEach((result) => {
          // Barcode value.
          let codeType: scanCore.ScanType = result.scanType;
          let codeValue: string = result.originalValue;
          hilog.info(0x0001, TAG, 'Scan result: type: ' + codeType + ' value: ' + codeValue);

          // Barcode area.
          let rect: scanBarcode.ScanCodeRect | undefined = result.scanCodeRect;
          if (rect) {
            this.scanResultPoints.push({
              left: rect.left,
              top: rect.top,
              right: rect.right,
              bottom: rect.bottom
            });
          }

          // QRCode corner points.
          let points: Array<scanBarcode.Point> | undefined = result.cornerPoints;
          if (result.scanType == scanCore.ScanType.QR_CODE && points) {
            this.cornerPoints.push([]);
            points.forEach((point) => {
              this.cornerPoints[this.cornerPoints.length - 1].push(point);
            });
          }
        });

        // Try to zoom.
        if (res.zoomValue > 1.0) {
          this.setCameraZoom(res.zoomValue);
        }

        this.isDecoding = false;
      }).catch((error: BusinessError) => {
        hilog.error(0x0001, TAG, 'decodeImage, error: ' + JSON.stringify(error));
        this.isDecoding = false;
      })
    } catch (error) {
      this.isDecoding = false;
    }
  }

  setCameraZoom(zoomValue: number) {
    // Set zoom ratio.
    if (this.photoSession) {
      try {
        let zoomRatio: number = this.photoSession.getZoomRatio() * zoomValue;
        if (zoomRatio < 10.0) {
          this.photoSession.setZoomRatio(zoomRatio);
        }
      } catch (error) {
        hilog.error(0x0001, TAG, 'Failed to set the zoom ratio value, error: ' + JSON.stringify(error));
      }
    }
  }
}
