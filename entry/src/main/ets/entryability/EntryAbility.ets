import { AbilityConstant, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import deviceInfo from '@ohos.deviceInfo';
import { display, router, window } from '@kit.ArkUI';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { GlobalThisUtil } from '../common/GlobalThisUtil';
import { CommonConstants } from '../pages/customScan/constants/CommonConstants';
import { CommonEventManager } from '../pages/customScan/model/CommonEventManager';
import Logger from '../common/Logger';

const TAG = 'Scan SampleCode EntryAbility';

export default class EntryAbility extends UIAbility {
  private windowObj?: window.Window;
  private page: string = 'pages/Index';

  // Obtain the code value through the onCreate callback in cold launch scenarios.
  onCreate(want: Want, __: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, 'Ability onCreate');
    GlobalThisUtil.setProperty('hmsCore_scan_device_type', deviceInfo.deviceType);
    GlobalThisUtil.setProperty('hmsCore_scan_isFoldable', display.isFoldable());
    if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable')) {
      GlobalThisUtil.setProperty('hmsCore_scan_foldStatus', display.getFoldStatus());
    }
    // Obtain the uri field from the want information.
    let uri = want?.uri;
    if (uri) {
      // Process the service based on the URI.
      this.page = 'pages/access/ScanAccess';
    }

    if (this.context && this.context.config) {
      AppStorage.setOrCreate<number>('scanFontSizeScale', this.context.config.fontSizeScale);
      AppStorage.setOrCreate<number>('scanColorMode', this.context.config.colorMode);
      AppStorage.setOrCreate<string>('scanLanguage', this.context.config.language);
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    if (newConfig) {
      if (AppStorage.get('scanFontSizeScale') !== newConfig.fontSizeScale) {
        AppStorage.setOrCreate<number>('scanFontSizeScale', newConfig.fontSizeScale);
      }
      if (AppStorage.get('scanColorMode') !== newConfig.colorMode) {
        AppStorage.setOrCreate<number>('scanColorMode', newConfig.colorMode);
      }
      if (AppStorage.get('scanLanguage') !== newConfig.language) {
        AppStorage.setOrCreate<string>('scanLanguage', newConfig.language);
      }
    }
  }

  onDestroy(): void {
    Logger.info(TAG, 'Ability onDestroy');
  }

  // Visible window size listener.
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
      Logger.error(TAG, `Failed to emit WINDOW_SIZE_CHANGE. Code: ${error.code}.`);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // The window has been created. Configure the main UI for the function.
    Logger.info(TAG, 'Ability onWindowStageCreate');

    try {
      let displayClass = display.getDefaultDisplaySync();
      if (displayClass !== null) {
        AppStorage.setOrCreate('windowWidthPx', displayClass.width);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to getDefaultDisplaySync. Code: ${error.code}.`);
    }
    windowStage.getMainWindow().then((windowObj: window.Window) => {
      windowObj.setWindowLayoutFullScreen(true).catch((error: BusinessError) => {
        Logger.error(TAG, `Failed to setWindowLayoutFullScreen. Code: ${error.code}`);
      })

      let avoidArea = windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      GlobalThisUtil.setProperty('scan_topRect_height', avoidArea.topRect.height);
      windowStage.loadContent(this.page, (error, _) => {
        if (error && error.code) {
          Logger.error(TAG, `Failed to load the content. Code: ${error.code}.`);
          return;
        }
        Logger.info(TAG, 'Succeeded in loading the content.');
      });

      try {
        this.windowObj = windowObj;
        // Obtain the window size when the app is started.
        this.updateWindowSize(windowObj.getWindowProperties().windowRect)

        // Register a callback function to listen for the window size change.
        this.windowObj.on('windowSizeChange', (windowSize) => {
          this.updateWindowSize(windowSize);
        })
      } catch (error) {
        Logger.error(TAG, `Failed to listen window size change. Code: ${error.code}.`);
      }
    }).catch((error: BusinessError) => {
      Logger.error(TAG, `Failed to get getMainWindow by windowStage. Code: ${error.code}.`);
    });
  }

  // Obtain the code value through the onNewWant callback in warm launch scenarios.
  onNewWant(want: Want, _: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, 'Ability onNewWant');
    // Obtain the uri field from the want information.
    let uri = want?.uri;
    let status: router.RouterState = router.getState();
    if (status && status.name !== 'ScanAccess' && uri) {
      // Process the service based on the URI.
      router.pushUrl({
        url: 'pages/access/ScanAccess'
      });
    }
  }

  onWindowStageDestroy(): void {
    // Destroy the main window and release UI resources.
    Logger.info(TAG, 'Ability onWindowStageDestroy');
    if (this.windowObj) {
      try {
        this.windowObj.off('windowSizeChange');
      } catch (error) {
        Logger.warn(TAG, `windowObj off on windowStageDestroy. Code: ${error.code}`);
      }
    }
  }

  onForeground(): void {
    // The app is switched to the foreground.
    Logger.info(TAG, 'Ability onForeground');
    CommonEventManager.getInstance().createSubscriber();
  }

  onBackground(): void {
    // The app is switched to the background.
    Logger.info(TAG, 'Ability onBackground');
    CommonEventManager.getInstance().unsubscribe();
  }
}
