import { curves, display, router } from '@kit.ArkUI';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { vibrator } from '@kit.SensorServiceKit';
import Logger from '../../../common/logger';
import { GlobalThisUtil } from '../../../common/GlobalThisUtil';
import { ScanResult } from '../model/ScanService'
import { XComponentSize } from '../model/ScanSize'
import { CommonConstants } from '../constants/CommonConstants';
import { pickerDialog } from './pickerDialog';
import { ScanTitle } from './ScanTitle';

@Extend(Image)
function selected(scanState: boolean, x: number, y: number) {
  .width(40)
  .height(40)
  .position({ x: x, y: y })
  .markAnchor({ x: 20, y: 20 })
  .visibility(scanState ? Visibility.Visible : Visibility.Hidden)
  .draggable(false)
}

let breathTimeSet: number;
const TAG: string = 'CommonCodeLayout';

@Component
export struct CodeLayout {
  @ObjectLink xComponentSize: XComponentSize;
  @Prop darkMode: ConfigurationConstant.ColorMode;
  @Prop navHeight: number;
  @Prop orientation: display.Orientation;
  @State scanResult: ScanResult = {
    code: 0,
    data: [],
    size: 0,
    uri: ''
  }
  @Prop foldStatus: number = -1;
  @State multiCodeScanLocation: Array<Array<number>> = []; // Multi-code display position
  @State multiCodeScanResult: Array<object> = []; // Scanning result
  @State isMultiSelected: boolean = false; // Whether the scan code is selected
  @State multiSelectedIndex: number = 0; // Index selected in multi-code mode
  @State singleCodeX: number = 0; // Single code x-axis position
  @State singleCodeY: number = 0; // Single-code y-axis position
  @State multiCodeScale: number = 0.3; // Scaling ratio of multi-code icons
  @State multiCodeOpacity: number = 0; // Opacity of the multi-code icon
  @State singleCodeScale: number = 0.3;
  @State singleCodeOpacity: number = 0;
  @State fadeOutScale: number = 1;
  @State fadeOutOpacity: number = 1;
  @State isPickerDialogShow: boolean = false;
  @State isShowCode: boolean = true;
  public backToScan: () => void = () => {
  };
  @State context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  aboutToAppear() {
    if (this.scanResult.uri) {
      // Gallery data. Do not display the blue dot.
      if (this.scanResult.size === 0) {
        // The image code is not identified.
        this.isPickerDialogShow = true;
      } else {
        this.vibratorPlay();
        this.isShowCode = false;
        setTimeout(() => {
          this.terminateSelfPage();
        }, 200)
      }
    } else {
      this.vibratorPlay();
      // Scan the QR code in real time and display the blue dot.
      for (let i = 0; i < this.scanResult.size; i++) {
        // Scanning result
        this.multiCodeScanResult.push(this.scanResult.data[i]);
        this.multiCodeScanLocation.push(
          [this.scanResult.data[i]['scanCodeRect'].left,
            this.scanResult.data[i]['scanCodeRect'].top,
            this.scanResult.data[i]['scanCodeRect'].right,
            this.scanResult.data[i]['scanCodeRect'].bottom]
        );
      }

      if (this.scanResult.size === 1) {
        // Single-code result
        this.multiSelectedIndex = 0;
        let location = this.multiCodeScanLocation[0];
        this.singleCodeX = this.getOffset('x', location);
        this.singleCodeY = this.getOffset('y', location);
      }
    }
  }

  aboutToDisappear() {
    GlobalThisUtil.setProperty(('hmsCore_scan_pickerUri'), undefined);
    this.isPickerDialogShow = false;
  }

  @Builder
  SingleCodeLayout() {
    Column() {
      Image($rawfile('scan_selected.svg')).selected(true, this.singleCodeX, this.singleCodeY)
        .scale({ x: this.singleCodeScale, y: this.singleCodeScale })
        .opacity(this.singleCodeOpacity)
        .onAppear(() => {
          // Non-gallery recognition single code
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
          clearTimeout(breathTimeSet);
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
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // 动画曲线
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Alternate,
    })
  }

  build() {
    Stack() {
      ScanTitle({
        scanResultSize: this.scanResult.size,
        navHeight: this.navHeight,
      }).width('100%').height('100%')

      if (this.scanResult.size === 1 && this.isShowCode) {
        // single code
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
        pickerDialog({
          darkMode: this.darkMode,
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
        if (GlobalThisUtil.getProperty('hmsCore_scan_device_type') === CommonConstants.DEVICE_TYPES[1]) {
          offset = (location[1] + location[3]) / 2 + this.xComponentSize.offsetX;
        } else {
          offset = this.xComponentSize.width - (location[1] + location[3]) / 2 + this.xComponentSize.offsetX;
        }
        break;
      case 2:
        offset = this.xComponentSize.width - (location[0] + location[2]) / 2 + this.xComponentSize.offsetX;
        break;
      case 3:
        if (GlobalThisUtil.getProperty('hmsCore_scan_device_type') === CommonConstants.DEVICE_TYPES[1]) {
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
        if (GlobalThisUtil.getProperty('hmsCore_scan_device_type') === CommonConstants.DEVICE_TYPES[1]) {
          offset = this.xComponentSize.height - (location[0] + location[2]) / 2 + this.xComponentSize.offsetY;
        } else {
          offset = (location[0] + location[2]) / 2 + this.xComponentSize.offsetY;
        }
        break;
      case 2:
        offset = this.xComponentSize.height - (location[3] + location[1]) / 2 + this.xComponentSize.offsetY;
        break;
      case 3:
        if (GlobalThisUtil.getProperty('hmsCore_scan_device_type') === CommonConstants.DEVICE_TYPES[1]) {
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
    // Start the vibrator.
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

  openMultiCode(arr: Array<number>, index: number) {
    // Click animation. Gallery does not support multi-code.
    this.singleCodeX = this.getOffset('x', arr);
    this.singleCodeY = this.getOffset('y', arr);
    this.isMultiSelected = true;
    this.singleCodeScale = 0.3;
    this.singleCodeOpacity = 0;
    this.multiSelectedIndex = index || 0;
    // Click button to disappear animation
    this.fadeOutScale = 0.3;
    this.fadeOutOpacity = 0;
    // Click to cover the image animation.
    animateTo({
      duration: 350,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // 动画曲线
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

  terminateSelfPage() {
    if (this.scanResult && this.scanResult.size > 0) {
      try {
        router.pushUrl({
          url: 'pages/resultPage/ResultPage',
          params: this.scanResult.data[this.multiSelectedIndex]
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

  singleCodeBreathe() {
    // Single-code scanning result
    this.singleCodeOpacity = 0.3;
    this.singleCodeScale = 0.3;
    animateTo({
      duration: 300,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // Animation Curves
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
   * Multicode Scan Result Icon Animation： 0 - 600ms stop(500ms) breath: Loop-scale: 1-0.8-1(600ms)-0.8-1(600ms)-stop(400ms)
   * 0 - 350ms  opacity:0-1 scale:0.3 - 1.1 multiAppear()
   * 350ms - 600ms scale: 1.1 - 1 multiAppearEnd()
   * */
  multiAppear() {
    this.multiCodeScale = 0.3;
    animateTo({
      duration: 350, // 动画时长
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // Animation Curves
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

  multiAppearEnd() {
    animateTo({
      duration: 250,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // Animation Curves
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Alternate,
      onFinish: () => {
        setTimeout(() => {
          this.multiCodeBreathe();
        }, 500);
      }
    }, () => {
      this.multiCodeScale = 1;
    });
  }

  multiCodeBreathe() {
    // Multi-code scan breathing animation.
    this.multiCodeScale = 1;
    animateTo({
      duration: 300,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // Animation Curves
      delay: 0,
      iterations: 4,
      playMode: PlayMode.Alternate,
      onFinish: () => {
        breathTimeSet = setTimeout(() => {
          this.multiCodeBreathe();
        }, 400);
      }
    }, () => {
      this.multiCodeScale = 0.8;
    });
  }

  toRedirectPage() {
    animateTo({
      duration: 250,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), // Animation Curves
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