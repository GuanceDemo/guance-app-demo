import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { FTSDKManager } from '../manager/FTSDKManager';
import { FTSDK } from 'ft_sdk/src/main/ets/components/FTSDK';
import {
  KEY_DATAKIT_ADDRESS,
  KEY_DATAWAY_ADDRESS,
  KEY_DATAWAY_CLIENT_TOKEN,
  KEY_APP_ID,
  KEY_OTEL_ADDRESS,
  KEY_APP_ACCESS_TYPE,
  KEY_API_ADDRESS
} from '../constants/Constant';

const DOMAIN: number = 0x0000;

export default class EntryAbility extends UIAbility {
  /*   Initialize project-required parameters using launch flags.
   *   1. Uninstall the app
   *   Command line：hdc shell bm uninstall -n com.example.demo
   *   Method 1: Configure DataKit mode
               --ps datakitUrl http://...... --ps demoApiUrl http://...... --ps appId com_example_demo --pi accessType 0
       Method 1: Configure DataWay mode
               --ps datawayUrl https://rum-openway.guance.com --ps datawayClientToken 59153e0dd64a4edxxxxxxxxx --ps appId com_example_demo --ps demoApiUrl http://...... --pi accessType 1
   */
  private initialWant: Want | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    // Save want for later processing
    this.initialWant = want;
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // Initialize Preferences - must await to ensure it completes before reading settings
    await PreferencesUtil.init(this.context);
    hilog.info(DOMAIN, 'Preferences', 'PreferencesUtil initialized successfully');

    // Process want.parameters as default values (only if no existing value in Preferences)
    await this.processWantParameters();

    // Initialize FT SDK Manager with context
    FTSDKManager.getInstance().init(this.context);
    hilog.info(DOMAIN, 'FTSDKManager', 'FTSDKManager initialized with context');

    // Initialize FT SDK
    await FTSDKManager.getInstance().initSDK();

    windowStage.loadContent('pages/LoginPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      // Initialize auto-tracking for View and Action
      try {
      } catch (error) {
        hilog.error(DOMAIN, 'testTag', 'Failed to init UI features: %{public}s', JSON.stringify(error));
      }
    });
  }

  /**
   * Process want.parameters as default values.
   * Only saves to Preferences if no existing value is present.
   */
  private async processWantParameters(): Promise<void> {
    if (!this.initialWant?.parameters) {
      hilog.info(DOMAIN, 'WantParams', 'No want.parameters found, skipping');
      return;
    }

    const params = this.initialWant.parameters;
    hilog.info(DOMAIN, 'WantParams', `Processing want.parameters: ${JSON.stringify(params)}`);

    try {
      // Helper function to save if not exists
      const saveIfNotExists = async (key: string, paramKey: string) => {
        const currentValue = await PreferencesUtil.getString(key, '');
        if (!currentValue || currentValue.length === 0) {
          const paramValue = params[paramKey] as string;
          if (paramValue) {
            await PreferencesUtil.putString(key, paramValue);
            hilog.info(DOMAIN, 'WantParams', `Saved ${key} from want.parameters: ${paramValue}`);
          }
        } else {
          hilog.info(DOMAIN, 'WantParams', `Key ${key} already exists, skipping want.parameters`);
        }
      };

      // Process each supported parameter
      await saveIfNotExists(KEY_DATAKIT_ADDRESS, 'datakitUrl');
      await saveIfNotExists(KEY_DATAWAY_ADDRESS, 'datawayUrl');
      await saveIfNotExists(KEY_DATAWAY_CLIENT_TOKEN, 'datawayClientToken');
      await saveIfNotExists(KEY_APP_ID, 'appId');
      await saveIfNotExists(KEY_OTEL_ADDRESS, 'otelAddress');
      await saveIfNotExists(KEY_API_ADDRESS, 'demoApiUrl');

      // Handle access type (numeric value)
      const currentAccessType = await PreferencesUtil.getInt(KEY_APP_ACCESS_TYPE, -1);
      if (currentAccessType === -1) {
        const accessTypeParam = params['accessType'] as number;
        if (accessTypeParam !== undefined) {
          await PreferencesUtil.putInt(KEY_APP_ACCESS_TYPE, accessTypeParam);
          hilog.info(DOMAIN, 'WantParams', `Saved ${KEY_APP_ACCESS_TYPE} from want.parameters: ${accessTypeParam}`);
        }
      } else {
        hilog.info(DOMAIN, 'WantParams', `Key ${KEY_APP_ACCESS_TYPE} already exists, skipping want.parameters`);
      }

      hilog.info(DOMAIN, 'WantParams', 'want.parameters processing completed');

    } catch (error) {
      const errorObj: Error = error as Error;
      hilog.error(DOMAIN, 'WantParams', `Failed to process want.parameters: ${errorObj.message}`);
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');

    // Cleanup auto-tracking resources
    try {
      FTSDK.cleanupUIFeatures();
      hilog.info(DOMAIN, 'testTag', 'UI features cleaned up');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to cleanup UI features: %{public}s', JSON.stringify(error));
    }
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
