import { AbilityConstant, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import { display, router, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { CommonEventManager } from '../pages/customScan/model/CommonEventManager';
import Logger from '../common/Logger';
import { WindowService } from '../pages/customScan/model/WindowService';
import { DeviceService } from '../pages/customScan/model/DeviceService';

const TAG = 'Scan SampleCode EntryAbility';

export default class EntryAbility extends UIAbility {
  private page: string = 'pages/Index';

  // Obtain the code value through the onCreate callback in cold launch scenarios.
  onCreate(want: Want, __: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, 'Ability onCreate');
    try {
      DeviceService.isFolding = display.isFoldable();
    } catch (error) {
      Logger.error(`Failed to invoke an API of isFoldable. Code: ${error.code}`);
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

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // The window has been created. Configure the main UI for the function.
    Logger.info(TAG, 'Ability onWindowStageCreate');

    windowStage.getMainWindow().then((windowObj: window.Window) => {
      WindowService.getInstance().initWindowObj(windowObj);

      windowStage.loadContent(this.page, (error, _) => {
        if (error && error.code) {
          Logger.error(TAG, `Failed to load the content. Code: ${error.code}.`);
          return;
        }
        Logger.info(TAG, 'Succeeded in loading the content.');
      });
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

  onWindowStageWillDestroy(): void {
    // Destroy the main window and release UI resources.
    Logger.info(TAG, 'Ability onWindowStageWillDestroy');
    WindowService.getInstance().offWindowSizeChange();
    WindowService.getInstance().offAvoidAreaChange();
  }
}
