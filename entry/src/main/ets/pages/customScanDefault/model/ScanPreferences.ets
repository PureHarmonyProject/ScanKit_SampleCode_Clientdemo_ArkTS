import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import Logger from '../../../common/logger';

const TAG = 'ScanPreferences';

export class ScanPreferences {
  preferencePrivacy: preferences.Preferences | null = null;
  options: preferences.Options = { name: 'scanSampleCodeStore' };
  context: Context = getContext(this) as Context;
  private static instance: ScanPreferences | null = null;

  constructor() {
    this.getPreferencesFromStorage();
  }

  static getInstance(): ScanPreferences {
    if (ScanPreferences.instance === null) {
      ScanPreferences.instance = new ScanPreferences();
    }
    return ScanPreferences.instance;
  }

  getPreferencesFromStorage(): void {
    Logger.info(TAG, 'Start to get preferences from storage.');
    this.preferencePrivacy = preferences.getPreferencesSync(this.context, this.options);
  }

  getPreference(): boolean {
    Logger.info(TAG, `Start to get preference.`);
    if (this.preferencePrivacy) {
      return this.preferencePrivacy.hasSync('privacyConfirm');
    }
    return false;
  }

  putPreference(): void {
    Logger.info(TAG, `Start to put preference.`);
    this.preferencePrivacy?.putSync('privacyConfirm', true);
    this.flushPreference();
  }

  flushPreference(): void {
    Logger.info(TAG, 'Start to flush preference.');
    this.preferencePrivacy?.flush((error: BusinessError) => {
      if (error) {
        Logger.error(TAG, `Failed to flush preference. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      Logger.info(TAG, 'Succeeded in flushing preference.');
    })
  }

  deletePreference(): void {
    Logger.info(TAG, `Start to delete preference.`);
    if (this.preferencePrivacy) {
      this.preferencePrivacy.deleteSync('privacyConfirm');
      this.flushPreference();
    }
  }
}