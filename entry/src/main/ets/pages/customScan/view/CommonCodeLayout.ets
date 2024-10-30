import { curves, display, router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { vibrator } from '@kit.SensorServiceKit';
import Logger from '../../../common/Logger';
import { GlobalThisUtil } from '../../../common/GlobalThisUtil';
import { ScanResults } from '../model/ScanService'
import { XComponentSize } from '../model/ScanSize'
import { CommonConstants } from '../constants/CommonConstants';
import { PickerDialog } from './PickerDialog';
import { ScanTitle } from './ScanTitle';
import { funcDelayer } from '../../../common/Utils';
import { scanBarcode } from '@kit.ScanKit';

@Extend(Image)
function selected(scanState: boolean, x: number, y: number) {
  .width(40)
  .height(40)
  .position({ x: x, y: y })
  .markAnchor({ x: 20, y: 20 })
  .visibility(scanState ? Visibility.Visible : Visibility.Hidden)
  .draggable(false)
}

const TAG: string = 'CommonCodeLayout';

@Component
export struct CodeLayout {
  @ObjectLink xComponentSize: XComponentSize;
  @Prop navHeight: number;
  @Prop orientation: display.Orientation;
  @State scanResults: ScanResults = {
    code: 0,
    data: [],
    size: 0,
    uri: ''
  }
  @Prop foldStatus: number = -1;
  @State multiCodeScanLocation: Array<Array<number>> = []; // Display positions of multiple barcodes.
  @State multiCodeScanResult: Array<object> = []; // Scanning result.
  @State isMultiSelected: boolean = false; // Whether a barcode among multiple barcodes is selected.
  @State multiSelectedIndex: number = 0; // Index of the selected barcode.
  @State singleCodeX: number = 0; // X-axis position of a single barcode.
  @State singleCodeY: number = 0; // Y-axis position of a single barcode.
  @State multiCodeScale: number = 0.3; // Radio button zoom ratio of multiple barcodes.
  @State multiCodeOpacity: number = 0; // Radio button transparency of multiple barcodes.
  @State singleCodeScale: number = 0.3;
  @State singleCodeOpacity: number = 0;
  @State fadeOutScale: number = 1;
  @State fadeOutOpacity: number = 1;
  @State isPickerDialogShow: boolean = false;
  @State isShowCode: boolean = true;
  public backToScan: () => void = () => {
  };

  aboutToAppear() {
    if (this.scanResults.uri) {
      // Not display the radio button for the gallery.
      if (this.scanResults.size === 0) {
        // No code value is recognized.
        this.isPickerDialogShow = true;
      } else {
        this.vibratorPlay();
        this.isShowCode = false;
        funcDelayer(() => {
          this.terminateSelfPage();
        }, 200);
      }
    } else {
      this.vibratorPlay();
      // Display the radio button for real-time scanning.
      for (let i = 0; i < this.scanResults.size; i++) {
        // Scanning result.
        let scanResult: scanBarcode.ScanResult = this.scanResults.data[i];
        this.multiCodeScanResult.push(scanResult);
        let scanCodeRect: scanBarcode.ScanCodeRect | undefined = scanResult.scanCodeRect;
        if (scanCodeRect) {
          this.multiCodeScanLocation.push(
            [scanCodeRect.left,
              scanCodeRect.top,
              scanCodeRect.right,
              scanCodeRect.bottom]
          );
        }
      }

      if (this.scanResults.size === 1) {
        // Single barcode result.
        this.multiSelectedIndex = 0;
        let location = this.multiCodeScanLocation[0];
        this.singleCodeX = this.getOffset('x', location);
        this.singleCodeY = this.getOffset('y', location);
      }
    }
  }

  aboutToDisappear() {
    GlobalThisUtil.setProperty((CommonConstants.GLOBAL_SCAN_SELECT_A_PICTURE), false);
    this.isPickerDialogShow = false;
  }

  @Builder
  SingleCodeLayout() {
    Column() {
      Image($rawfile('scan_selected.svg')).selected(true, this.singleCodeX, this.singleCodeY)
        .scale({ x: this.singleCodeScale, y: this.singleCodeScale })
        .opacity(this.singleCodeOpacity)
        .onAppear(() => {
          // Non-gallery-based single barcode recognition.
          this.singleCodeBreathe();
        })
    }
    .position({ x: 0, y: 0 })
    .width('100%')
    .height('100%')
  }

  @Builder
  MultiCodeLayout(arr: Array<number>, index: number) {
    Row() {
      Image($rawfile('scan_selected2.svg'))
        .width(40)
        .height(40)
        .visibility((this.isMultiSelected && this.multiSelectedIndex !== index) ? Visibility.None : Visibility.Visible)
        .scale({ x: this.multiCodeScale, y: this.multiCodeScale })
        .opacity(this.multiCodeOpacity)
        .onAppear(() => {
          if (index === 0) {
            this.multiAppear();
          }
        })
        .onClick(() => {
          this.openMultiCode(arr, index);
        })
    }
    .position({
      x: this.getOffset('x', arr),
      y: this.getOffset('y', arr)
    })
    .width(40)
    .height(40)
    .markAnchor({ x: 20, y: 20 })
    .scale({ x: this.fadeOutScale, y: this.fadeOutScale })
    .opacity(this.fadeOutOpacity)
    .animation({
      duration: 200,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1),
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Alternate,
    })
  }

  build() {
    Stack() {
      ScanTitle({
        scanResultSize: this.scanResults.size,
        navHeight: this.navHeight,
      }).width('100%').height('100%')

      if (this.scanResults.size === 1 && this.isShowCode) {
        // Single barcode scanning.
        this.SingleCodeLayout();
      } else {
        ForEach(this.multiCodeScanLocation, (item: Array<number>, index: number) => {
          this.MultiCodeLayout(item, index)
        }, (item: number) => item.toString())
        Image($rawfile('scan_selected.svg'))
          .selected(true, this.singleCodeX, this.singleCodeY)
          .scale({ x: this.singleCodeScale, y: this.singleCodeScale })
          .opacity(this.singleCodeOpacity)
          .visibility(this.isMultiSelected ? Visibility.Visible : Visibility.None)
      }

      if (this.isPickerDialogShow) {
        PickerDialog({
          text: $r('app.string.Scan_diaLog_not_found'),
          cancel: (() => {
            this.isPickerDialogShow = false;
            this.backToScan();
          })
        })
      }

    }
    .width('100%')
    .height('100%')
  }

  getOffset(coordinateAxis: string, location: Array<number>): number {
    if (coordinateAxis === 'x') {
      return this.setOffsetXByOrientation(location);
    }
    return this.setOffsetYByOrientation(location);
  }

  setOffsetXByOrientation(location: Array<number>): number {
    let offset: number = 0;
    switch (this.orientation) {
      case 0:
        offset = (location[0] + location[2]) / 2 + this.xComponentSize.offsetX;
        break;
      case 1:
        if (GlobalThisUtil.getProperty(CommonConstants.GLOBAL_SCAN_DEVICE_TYPE) === CommonConstants.DEVICE_TYPES[1]) {
          offset = (location[1] + location[3]) / 2 + this.xComponentSize.offsetX;
        } else {
          offset = this.xComponentSize.width - (location[1] + location[3]) / 2 + this.xComponentSize.offsetX;
        }
        break;
      case 2:
        offset = this.xComponentSize.width - (location[0] + location[2]) / 2 + this.xComponentSize.offsetX;
        break;
      case 3:
        if (GlobalThisUtil.getProperty(CommonConstants.GLOBAL_SCAN_DEVICE_TYPE) === CommonConstants.DEVICE_TYPES[1]) {
          offset = this.xComponentSize.width - (location[1] + location[3]) / 2 + this.xComponentSize.offsetX;
        } else {
          offset = (location[1] + location[3]) / 2 + this.xComponentSize.offsetX;
        }
        break;
      default:
        break;
    }
    return offset;
  }

  setOffsetYByOrientation(location: Array<number>): number {
    let offset: number = 0;
    switch (this.orientation) {
      case 0:
        offset = (location[3] + location[1]) / 2 + this.xComponentSize.offsetY;
        break;
      case 1:
        if (GlobalThisUtil.getProperty(CommonConstants.GLOBAL_SCAN_DEVICE_TYPE) === CommonConstants.DEVICE_TYPES[1]) {
          offset = this.xComponentSize.height - (location[0] + location[2]) / 2 + this.xComponentSize.offsetY;
        } else {
          offset = (location[0] + location[2]) / 2 + this.xComponentSize.offsetY;
        }
        break;
      case 2:
        offset = this.xComponentSize.height - (location[3] + location[1]) / 2 + this.xComponentSize.offsetY;
        break;
      case 3:
        if (GlobalThisUtil.getProperty(CommonConstants.GLOBAL_SCAN_DEVICE_TYPE) === CommonConstants.DEVICE_TYPES[1]) {
          offset = (location[0] + location[2]) / 2 + this.xComponentSize.offsetY;
        } else {
          offset = this.xComponentSize.height - (location[0] + location[2]) / 2 + this.xComponentSize.offsetY;
        }
        break;
      default:
        break;
    }
    return offset;
  }

  vibratorPlay() {
    // Vibration.
    try {
      vibrator.startVibration({
        type: 'time',
        duration: 100
      }, {
        id: 0,
        usage: 'alarm'
      }).then((): void => {
      }, (error: BusinessError) => {
        Logger.error(TAG, `Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
      });
    } catch (err) {
      let error: BusinessError = err as BusinessError;
      Logger.error(TAG,
        `Failed to play vibration, An unexpected error occurred. Code: ${error.code}, message: ${error.message}`);
    }
  }

  openMultiCode(arr: Array<number>, index: number): void{
    // Tap animation. Multi-barcode scanning is not supported based on the gallery currently.
    this.singleCodeX = this.getOffset('x', arr);
    this.singleCodeY = this.getOffset('y', arr);
    this.isMultiSelected = true;
    this.singleCodeScale = 0.3;
    this.singleCodeOpacity = 0;
    this.multiSelectedIndex = index || 0;
    // Button fade-out animation.
    this.fadeOutScale = 0.3;
    this.fadeOutOpacity = 0;
    // Radio button animation.
    animateTo({
      duration: 350,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1),
      delay: 100,
      iterations: 1,
      playMode: PlayMode.Alternate,
      onFinish: () => {
        this.toRedirectPage();
      }
    }, () => {
      this.singleCodeOpacity = 1;
      this.singleCodeScale = 1.1;
    });
  }

  terminateSelfPage(): void {
    if (this.scanResults && this.scanResults.size > 0) {
      try {
        router.pushUrl({
          url: 'pages/resultPage/ResultPage',
          params: this.scanResults.data[this.multiSelectedIndex]
        })
      } catch (error) {
        Logger.error(TAG, `Failed to terminateSelfPage. Code: ${error.code}, message: ${error.message}`);
        this.terminateScan();
      }
    } else {
      this.terminateScan();
    }
  }

  terminateScan() {
    router.back();
  }

  singleCodeBreathe(): void {
    // Single-barcode scanning breathing effect.
    this.singleCodeOpacity = 0.3;
    this.singleCodeScale = 0.3;
    animateTo({
      duration: 300,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // Animation curve.
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Alternate,
      onFinish: () => {
        this.terminateSelfPage();
      }
    }, () => {
      this.singleCodeOpacity = 1;
      this.singleCodeScale = 1;
    });

  }

  /*
   * Multi-code scanning result animation: 0 - 600ms stop(500ms) breath: Loop-scale: 1-0.8-1(600ms)-0.8-1(600ms)-stop(400ms)
   * 0 - 350ms  opacity:0-1 scale:0.3 - 1.1 multiAppear()
   * 350ms - 600ms scale: 1.1 - 1 multiAppearEnd()
   * */
  multiAppear(): void {
    this.multiCodeScale = 0.3;
    animateTo({
      duration: 350,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // Animation curve.
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Alternate,
      onFinish: () => {
        this.multiAppearEnd();
      }
    }, () => {
      this.multiCodeScale = 1.1;
      this.multiCodeOpacity = 1;
    });
  }

  multiAppearEnd(): void {
    animateTo({
      duration: 250,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // Animation curve.
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Alternate,
      onFinish: () => {
        funcDelayer(() => {
          this.multiCodeBreathe();
        }, 500);
      }
    }, () => {
      this.multiCodeScale = 1;
    });
  }

  multiCodeBreathe(): void {
    // Multi-barcode scanning breathing effect.
    this.multiCodeScale = 1;
    animateTo({
      duration: 300,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // Animation curve.
      delay: 0,
      iterations: 4,
      playMode: PlayMode.Alternate,
      onFinish: () => {
        funcDelayer(() => {
          this.multiCodeBreathe();
        }, 400);
      }
    }, () => {
      this.multiCodeScale = 0.8;
    });
  }

  toRedirectPage(): void {
    animateTo({
      duration: 250,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // Animation curve.
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Alternate,
      onFinish: () => {
        this.terminateSelfPage();
      }
    }, () => {
      this.singleCodeScale = 1;
    });
  }
}