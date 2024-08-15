import { TipsDialog } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import Logger from './Logger';

const TAG: string = 'Common Tips Dialog';

@CustomDialog
export struct CommonTipsDialog {
  @Link isDialogShow: boolean;
  dialogController?: CustomDialogController;

  build() {
    TipsDialog({
      title: $r('app.string.Scan_access_not_enabled'),
      content: $r('app.string.Scan_access_tips'),
      primaryButton: {
        value: $r('app.string.Scan_got_it'),
        action: () => {
          this.closeDialog();
        },
      },
      secondaryButton: {
        value: $r('app.string.Scan_settings'),
        action: () => {
          this.openPermissionsInSystemSettings();
        }
      },
    })
  }

  closeDialog(): void {
    Logger.info(TAG, 'Start to close dialog.');
    if (this.isDialogShow && this.dialogController !== undefined) {
      this.isDialogShow = false;
      this.dialogController.close();
      Logger.info(TAG, 'Succeeded in closing dialog.');
    }
  }

  openPermissionsInSystemSettings(): void {
    Logger.info(TAG, 'Start to open permissions in system settings.');
    let context = getContext(this) as common.UIAbilityContext;
    let wantInfo: Want = {
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: 'application_info_entry',
      parameters: {
        settingsParamBundleName: 'com.example.scanSample' // Open the details page of a specified application.
      }
    };
    context.startAbility(wantInfo).then(() => {
      Logger.info(TAG, 'Succeeded in starting ability.');
    }).catch((error: Error) => {
      Logger.info(TAG, `Failed to start ability. Message: ${error.message}.`);
    })
  }
}
