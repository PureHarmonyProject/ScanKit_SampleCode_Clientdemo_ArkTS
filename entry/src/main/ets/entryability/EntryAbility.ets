import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { display, window } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { ScanEventId } from '../common/Utils';
import { GlobalThisUtil } from '../common/GlobalThisUtil';

const TAG = 'Scan SampleCode EntryAbility';

export default class EntryAbility extends UIAbility {
  private windowObj?: window.Window;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, '%{public}s', 'Ability onCreate');
    GlobalThisUtil.setProperty('abilityContext', this.context);
    GlobalThisUtil.setProperty('hmsCore_scan_isFoldable', display.isFoldable());
    if (GlobalThisUtil.getProperty('hmsCore_scan_isFoldable')) {
      GlobalThisUtil.setProperty('hmsCore_scan_foldStatus', display.getFoldStatus());
    }
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, TAG, '%{public}s', 'Ability onWindowStageCreate');

    try {
      let displayClass = display.getDefaultDisplaySync();
      if (displayClass !== null) {
        AppStorage.setOrCreate('windowWidthPx', displayClass.width);
      }
    } catch (exception) {
      hilog.error(0x0001, TAG, 'Failed to obtain the default display object. Code: %{public}s ', JSON.stringify(exception));
    }
    AppStorage.setOrCreate<window.WindowStage>('winStage', windowStage)
    windowStage.getMainWindow().then((windowObj: window.Window) => {
      this.windowObj = windowObj;
      this.windowObj.on('windowSizeChange', (windowSize) => {
        AppStorage.setOrCreate('windowWidthPx', windowSize.width);
        emitter.emit({
          eventId: ScanEventId.WINDOW_SIZE_CHANGE
        })
      })
      let area = windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      windowObj.setWindowLayoutFullScreen(true, () => {
        hilog.info(0x0000, TAG, 'setWindowLayoutFullScreen Succeed!');
      });
      GlobalThisUtil.setProperty('getStatusHeight', area.topRect.height)
      windowStage.loadContent('pages/Index', (error, data) => {
        if (error.code) {
          hilog.error(0x0000, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(error) ?? '');
          return;
        }
        hilog.info(0x0000, TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
      });
    })
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
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, TAG, '%{public}s', 'Ability onBackground');
  }
}
