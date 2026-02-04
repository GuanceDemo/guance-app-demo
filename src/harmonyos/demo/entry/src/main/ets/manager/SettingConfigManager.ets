import { SettingData } from '../model/SettingData';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { AccessType } from '../constants/AccessType';
import { SessionReplayPrivacy } from '../constants/SessionReplayPrivacy';
import {
  DEFAULT_API_ADDRESS,
  DEFAULT_APP_ID,
  DEFAULT_DATAKIT_ADDRESS,
  DEFAULT_DATAWAY_ADDRESS,
  DEFAULT_DATAWAY_CLIENT_TOKEN,
  DEFAULT_OTEL_ADDRESS,
  PUBLIC_DATAWAY_ADDRESS,
  PUBLIC_DATAWAY_CLIENT_TOKEN,
  PUBLIC_APP_ID,
  KEY_API_ADDRESS,
  KEY_APP_ACCESS_TYPE,
  KEY_APP_ID,
  KEY_DATAWAY_ADDRESS,
  KEY_DATAWAY_CLIENT_TOKEN,
  KEY_DATAKIT_ADDRESS,
  KEY_ENABLE_SESSION_REPLAY,
  KEY_OTEL_ADDRESS,
  KEY_SESSION_REPLAY_PRIVACY_TYPE
} from '../constants/Constant';

/**
 * Settings configuration manager
 */
export class SettingConfigManager {
  private static data: SettingData | null = null;

  /**
   * Save settings
   */
  static async saveSetting(settingData: SettingData): Promise<void> {
    console.info('SettingConfigManager: Starting to save settings');
    SettingConfigManager.data = settingData;
    try {
      await PreferencesUtil.putString(KEY_DATAKIT_ADDRESS, settingData.datakitAddress);
      await PreferencesUtil.putString(KEY_API_ADDRESS, settingData.demoApiAddress);
      await PreferencesUtil.putString(KEY_APP_ID, settingData.appId);
      await PreferencesUtil.putString(KEY_DATAWAY_ADDRESS, settingData.datawayAddress);
      await PreferencesUtil.putString(KEY_DATAWAY_CLIENT_TOKEN, settingData.datawayClientToken);
      await PreferencesUtil.putString(KEY_OTEL_ADDRESS, settingData.otelAddress);
      await PreferencesUtil.putInt(KEY_APP_ACCESS_TYPE, settingData.type);
      await PreferencesUtil.putBoolean(KEY_ENABLE_SESSION_REPLAY, settingData.enableSessionReplay);
      await PreferencesUtil.putInt(KEY_SESSION_REPLAY_PRIVACY_TYPE, settingData.sessionReplayPrivacyType);
      console.info('SettingConfigManager: All settings saved successfully');
    } catch (err) {
      console.error('SettingConfigManager: Failed to save setting:', JSON.stringify(err));
    }
  }

  /**
   * Read settings
   */
  static async readSetting(): Promise<SettingData> {
    if (SettingConfigManager.data !== null) {
      console.info('SettingConfigManager: Returning cached data');
      return SettingConfigManager.data;
    }

    console.info('SettingConfigManager: Starting to read settings');
    try {
      const datakitAddress = await PreferencesUtil.getString(KEY_DATAKIT_ADDRESS, DEFAULT_DATAKIT_ADDRESS);
      const demoApiAddress = await PreferencesUtil.getString(KEY_API_ADDRESS, DEFAULT_API_ADDRESS);
      const appId = await PreferencesUtil.getString(KEY_APP_ID, PUBLIC_APP_ID);
      // Use Guance public DataWay official configuration by default
      const datawayAddress = await PreferencesUtil.getString(KEY_DATAWAY_ADDRESS, PUBLIC_DATAWAY_ADDRESS);
      const datawayClientToken = await PreferencesUtil.getString(KEY_DATAWAY_CLIENT_TOKEN, PUBLIC_DATAWAY_CLIENT_TOKEN);
      const otelAddress = await PreferencesUtil.getString(KEY_OTEL_ADDRESS, DEFAULT_OTEL_ADDRESS);
      // Use DataKit by default (aligned with Android)
      const accessType = await PreferencesUtil.getInt(KEY_APP_ACCESS_TYPE, AccessType.DATAKIT);
      const enableSessionReplay = await PreferencesUtil.getBoolean(KEY_ENABLE_SESSION_REPLAY, false);
      const privacyType = await PreferencesUtil.getInt(KEY_SESSION_REPLAY_PRIVACY_TYPE, SessionReplayPrivacy.ALLOW);

      SettingConfigManager.data = new SettingData(
        datakitAddress,
        demoApiAddress,
        appId,
        datawayAddress,
        datawayClientToken,
        otelAddress,
        accessType,
        enableSessionReplay,
        privacyType
      );

      console.info('SettingConfigManager: Settings loaded successfully');
      return SettingConfigManager.data;
    } catch (err) {
      console.error('SettingConfigManager: Failed to read setting:', JSON.stringify(err));
      // Use DataKit by default (aligned with Android)
      return new SettingData(
        DEFAULT_DATAKIT_ADDRESS,
        DEFAULT_API_ADDRESS,
        PUBLIC_APP_ID,
        PUBLIC_DATAWAY_ADDRESS,
        PUBLIC_DATAWAY_CLIENT_TOKEN,
        DEFAULT_OTEL_ADDRESS,
        AccessType.DATAKIT,
        false,
        SessionReplayPrivacy.ALLOW
      );
    }
  }
}
