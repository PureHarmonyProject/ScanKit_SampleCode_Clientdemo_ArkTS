import { router, curves } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Extend(Image)
function selected(scanState: boolean, x: string, y: string) {
  .width(40)
  .height(40)
  .position({ x: x, y: y })
  .markAnchor({ x: 20, y: 20 })
  .visibility(scanState ? Visibility.Visible : Visibility.Hidden)
}

let breathTimeSet: number = -1;
const TAG: string = 'Scan SampleCode codeLayout';

@Component
export struct CodeLayout {
  @State multiCodeScanLocation: Array<Array<number>> = []; // Multi-code display position
  @State multiCodeScanResult: Array<object> = [];
  @State resultCode: number = -1; // Scan result code.
  @State cameraScreenOffsetX: number = 0;
  @State cameraScreenOffsetY: number = 0;
  @State cameraHeight: number = 640;
  @State cameraWidth: number = 360;
  @State isMultiSelected: boolean = false; // Whether the scanning result has been selected
  @State multiSelectedIndex: number = -1;  // Index selected in multi-code mode
  @State singleCodeX: string = '0lpx'; // Single-code x-axis position
  @State singleCodeY: string = '0lpx'; // Single-code y-axis position
  @State multiCodeScale: number = 0.3; // Multi-code icon scaling ratio
  @State multiCodeOpacity: number = 0; // Multi-code Icon Opacity
  @State singleCodeScale: number = 0.3;
  @State singleCodeOpacity: number = 0;
  @State fadeOutScale: number = 1;
  @State fadeOutOpacity: number = 1;
  @State result: Array<object> = [];
  @State codeScanSize: number = 0;
  @Link isScanned: boolean;
  @State isPickerDialogShow: boolean = false;
  @State isVertical: boolean = true;
  @State isTerminateSelfPage: boolean = false; // Indicates whether the page is redirected.
  @State isCodeScan: boolean = false;
  private isBackToPage: number = -1;
  private layLeft: number = 0;
  private layTop: number = 0;


  aboutToAppear() {
    hilog.info(0x0001, TAG, 'aboutToAppear');
    if (this.result.length === 0) {
      // No data
      this.isCodeScan = false;
      this.codeScanSize = 0;
    } else {
      this.isCodeScan = true;
      this.codeScanSize = this.result.length;
    }
    let screenRatio: number = 1;

    if (this.codeScanSize > 0) {
      // Indicates whether to return to the gallery.
      for (let i = 0; i < this.codeScanSize; i++) {
        hilog.info(0x0001, TAG, 'Promise scan result: %{public}s', 'multi');
        // Code scanning result
        this.multiCodeScanResult.push(this.result[i]);
        this.multiCodeScanLocation.push(
          [this.result[i]['scanCodeRect'].left * screenRatio,
            this.result[i]['scanCodeRect'].top * screenRatio,
            this.result[i]['scanCodeRect'].right * screenRatio,
            this.result[i]['scanCodeRect'].bottom * screenRatio]
        );
      }

      if (this.codeScanSize === 1) {
        hilog.info(0x0001, TAG, 'Promise scan result: %{public}s', 'single');
        // Single Code Result
        this.multiSelectedIndex = 0;
        let location = this.multiCodeScanLocation[0];
        if (this.isVertical) {
          this.singleCodeX = (location[2] + location[0]) / 2 + this.cameraScreenOffsetX + this.layLeft + 'lpx';
          this.singleCodeY = (location[3] + location[1]) / 2 + this.cameraScreenOffsetY + this.layTop + 'lpx';
        } else {
          this.singleCodeX = (location[3] + location[1]) / 2 + this.cameraScreenOffsetX + this.layLeft + 'lpx';
          this.singleCodeY = this.cameraHeight - ((location[2] + location[0]) / 2 + this.cameraScreenOffsetY + this.layTop) + 'lpx';
        }

      }
    }
  }

  aboutToDisappear() {
    hilog.info(0x0001, TAG, 'aboutToDisappear');
    clearTimeout(this.isBackToPage);
    this.isBackToPage = -1;
    this.isPickerDialogShow = false;
  }

  @Builder
  SingleCodeLayout() {
    Column() {
      Image($rawfile('scan_selected.svg')).selected(true, this.singleCodeX, this.singleCodeY)
        .scale({ x: this.singleCodeScale, y: this.singleCodeScale })
        .opacity(this.singleCodeOpacity)
        .onAppear(() => {
          // Non-graphic library identification single code
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
          // Click animation
          if (this.isVertical) {
            this.singleCodeX = (arr[2] + arr[0]) / 2 + this.cameraScreenOffsetX + this.layLeft + 'lpx';
            this.singleCodeY = (arr[1] + arr[3]) / 2 + this.cameraScreenOffsetY + this.layTop + 'lpx';
          } else {
            this.singleCodeX = (arr[1] + arr[3]) / 2 + this.cameraScreenOffsetX + this.layLeft + 'lpx';
            this.singleCodeY = this.cameraHeight - ((arr[0] + arr[2]) / 2 + this.cameraScreenOffsetY + this.layTop) + 'lpx';
          }
          this.isMultiSelected = true;
          this.singleCodeScale = 0.3;
          this.singleCodeOpacity = 0;
          this.multiSelectedIndex = index;
          // Current button disappears animation
          this.fadeOutScale = 0.3;
          this.fadeOutOpacity = 0;
          // Click to cover the picture animation
          animateTo({
            duration: 350,
            curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1),
            delay: 100,
            iterations: 1,
            playMode: PlayMode.Alternate,
            onFinish: () => {
              this.toRedirectPage(index);
            }
          }, () => {
            this.singleCodeOpacity = 1;
            this.singleCodeScale = 1.1;
            this.backToPage(500);
          });
        })
    }
    .position({
      x: this.isVertical ? (arr[2] + arr[0]) / 2 + this.cameraScreenOffsetX + this.layLeft + 'lpx' : (arr[1] + arr[3]) / 2 + this.cameraScreenOffsetX + this.layLeft + 'lpx',
      y: this.isVertical ? (arr[3] + arr[1]) / 2 + this.cameraScreenOffsetY + this.layTop + 'lpx' : this.cameraHeight - ((arr[2] + arr[0]) / 2 + this.cameraScreenOffsetY + this.layTop) + 'lpx'
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
    Column() {
      Row() {
      }
      .position({ x: 12, y: 0 })
      .width(48)
      .height(48)
      .id('scan_page_goBack_code')
      .onClick(() => {

      })

      if (this.codeScanSize === 1) {
        // Single-code identification success. Directly jump to the page.
        this.SingleCodeLayout()
      } else {
        // Multi-code identification is successful. You need to click the blue dot to go to the next page.
        ForEach(this.multiCodeScanLocation, (item: Array<number>, index: number) => {
          this.MultiCodeLayout(item, index)
        })
        Image($rawfile('scan_selected.svg')).selected(true, this.singleCodeX, this.singleCodeY)
          .scale({ x: this.singleCodeScale, y: this.singleCodeScale })
          .opacity(this.singleCodeOpacity)
          .visibility(this.isMultiSelected ? Visibility.Visible : Visibility.None)
      }

    }
    .width('100%')
    .height('100%')
  }

  terminateSelfPage(index: number) {
    if (this.resultCode !== -1 && this.multiCodeScanResult.length > 0) {
      this.isTerminateSelfPage = true;
      router.replaceUrl({
        url: 'pages/resultPage/ResultPage',
        params: this.result[index]

      })
    }
  }

  singleCodeBreathe() {
    // Single-code scanning result
    this.singleCodeOpacity = 0.3;
    this.singleCodeScale = 0.3;
    animateTo({
      duration: 300, // Animation duration
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1),
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Alternate,
      onFinish: () => {
        setTimeout(() => {
          this.terminateSelfPage(0);
        });
      }
    }, () => {
      this.singleCodeOpacity = 1;
      this.singleCodeScale = 1;
      this.backToPage(700);
    });
  }

  /*
   * Multi-Code Scan Result Icon Animation： 0 - 600ms stop(500ms) breath: Loop-scale: 1-0.8-1(600ms)-0.8-1(600ms)-stop(400ms)
   * 0 - 350ms  opacity:0-1 scale:0.3 - 1.1 multiAppear()
   * 350ms - 600ms scale: 1.1 - 1 multiAppearEnd()
   * */
  multiAppear() {
    this.multiCodeScale = 0.3;
    animateTo({
      duration: 350,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1),
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
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1),
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
    // Multi-code Scan Breathing Animation
    this.multiCodeScale = 1;
    animateTo({
      duration: 300,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1),
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

  toRedirectPage(index: number) {
    animateTo({
      duration: 250,
      curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1),
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Alternate,
      onFinish: () => {
        this.terminateSelfPage(index);
      }
    }, () => {
      this.singleCodeScale = 1;
      this.backToPage(350);
    });
  }

  backToPage(time: number) {
    this.isBackToPage = setTimeout(() => {
    }, time);
  }
}