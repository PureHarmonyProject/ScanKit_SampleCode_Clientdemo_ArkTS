import { AbilityConstant, common, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import deviceInfo from '@ohos.deviceInfo';
import { display, router, window } from '@kit.ArkUI';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { GlobalThisUtil } from '../common/GlobalThisUtil';
import { CommonConstants } from '../pages/customScanDefault/constants/CommonConstants';
import { CommonEventManager } from '../pages/customScanDefault/model/CommonEventManager';

const TAG = 'Scan SampleCode EntryAbility';

export default class EntryAbility extends UIAbility {
  private windowObj?: window.Window;
  private page: string = 'pages/Index';

  onCreate(want: Want, __: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, '%{public}s', 'Ability onCreate');
    GlobalThisUtil.setProperty<common.UIAbilityContext>('scan_context', this.context);
    GlobalThisUtil.setProperty('hmsCore_scan_device_type', deviceInfo.deviceType);
    GlobalThisUtil.setProperty('hmsCore_scan_isFoldable', display.isFoldable());
    if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable')) {
      GlobalThisUtil.setProperty('hmsCore_scan_foldStatus', display.getFoldStatus());
    }
    let uri = want?.uri;
    if (uri) {
      // “扫码直达”服务，根据uri参数做业务处理
      this.page = 'pages/access/ScanAccess';
    }

    AppStorage.setOrCreate<number>('scanFontSizeScale', this.context.config.fontSizeScale);
    AppStorage.setOrCreate<number>('scanColorMode', this.context.config.colorMode);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    if (newConfig.fontSizeScale && AppStorage.get('scanFontSizeScale') !== newConfig.fontSizeScale) {
      AppStorage.setOrCreate<number>('scanFontSizeScale', newConfig.fontSizeScale);
    }
    if (newConfig.fontSizeScale && AppStorage.get('scanColorMode') !== newConfig.colorMode) {
      AppStorage.setOrCreate<number>('scanColorMode', newConfig.colorMode);
    }
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, '%{public}s', 'Ability onDestroy');
  }

  // Visual Window Size Monitoring
  private updateWindowSize(windowSize: window.Size | window.Rect): void {
    try {
      let appWindowSize: window.Size | undefined = AppStorage.get('windowSize');
      if (!appWindowSize || appWindowSize.width !== windowSize.width || appWindowSize.height !== windowSize.height) {
        AppStorage.setOrCreate('windowSize', windowSize);
        AppStorage.setOrCreate('windowWidthPx', windowSize.width);
        let eventData: emitter.EventData = {
          data: {
            "width": windowSize.width,
            "height": windowSize.height,
          }
        }
        emitter.emit({
          eventId: CommonConstants.WINDOW_SIZE_CHANGE
        }, eventData)
      }
    } catch (error) {
      hilog.error(0x0000, TAG, '%{public}s', 'Failed to emit WINDOW_SIZE_CHANGE.');
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, TAG, '%{public}s', 'Ability onWindowStageCreate');

    try {
      let displayClass = display.getDefaultDisplaySync();
      if (displayClass !== null) {
        AppStorage.setOrCreate('windowWidthPx', displayClass.width);
      }
    } catch (error) {
      hilog.error(0x0001, TAG, 'Failed to obtain the default display object. Code: %{public}s, message: %{public}s.',
        error.code, error.message);
    }
    windowStage.getMainWindow().then((windowObj: window.Window) => {
      windowObj.setWindowLayoutFullScreen(true).catch((error: BusinessError) => {
        hilog.error(0x0001, TAG, `Failed to setWindowLayoutFullScreen. Code: ${error.code}`);
      })

      let avoidArea = windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      GlobalThisUtil.setProperty('scan_topRect_height', avoidArea.topRect.height);
      windowStage.loadContent(this.page, (error, _) => {
        if (error.code) {
          hilog.error(0x0000, TAG, 'Failed to load the content. Code: %{public}s, message: %{public}s.', error.code,
            error.message);
          return;
        }
        hilog.info(0x0000, TAG, 'Succeeded in loading the content.');
      });

      try {
        this.windowObj = windowObj;
        // Obtains the window size when the application is started.
        this.updateWindowSize(windowObj.getWindowProperties().windowRect)

        // Register a callback function to monitor the window size change.
        this.windowObj.on('windowSizeChange', (windowSize) => {
          this.updateWindowSize(windowSize);
        })
      } catch (error) {
        hilog.error(0x0000, TAG, '%{public}s', 'Failed to listen window size change.');
      }
    })
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onNewWant');
    // 从want中获取传入的参数
    let uri = want?.uri;
    let status: router.RouterState = router.getState();
    if (status && status.name !== 'ScanAccess' && uri) {
      // “扫码直达”服务，根据uri参数做业务处理
      router.pushUrl({
        url: 'pages/access/ScanAccess'
      });
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, TAG, '%{public}s', 'Ability onWindowStageDestroy');
    if (this.windowObj) {
      try {
        this.windowObj.off('windowSizeChange');
      } catch (error) {
        hilog.info(0x0000, TAG, 'windowObj off try catch error：%{public}s', JSON.stringify(error));
      }
    }
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, TAG, '%{public}s', 'Ability onForeground');
    CommonEventManager.getInstance().createSubscriber();
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, TAG, '%{public}s', 'Ability onBackground');
    CommonEventManager.getInstance().unsubscribe();
  }
}
