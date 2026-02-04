import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { AccessType } from '../constants/AccessType';
import { FTSDK } from 'ft_sdk/src/main/ets/components/FTSDK';
import { FTSDKConfig, FTRUMConfig, FTLoggerConfig, FTTraceConfig } from 'ft_sdk/src/main/ets/components/Configs';
import { EnvType, SyncPageSize, DBCacheDiscard } from 'ft_sdk/src/main/ets/components/enum/Enums';
import { TraceType } from 'ft_sdk/src/main/ets/components/trace/TraceType';
import { FTLogger } from 'ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from 'ft_sdk/src/main/ets/components/bean/Status';
import { FTRUMConfigManager } from 'ft_sdk/src/main/ets/components/rum/FTRUMConfigManager';
import { ErrorMonitorType } from 'ft_sdk/src/main/ets/components/rum/enum/ErrorMonitorType';
import { DeviceMetricsMonitorType } from 'ft_sdk/src/main/ets/components/rum/enum/DeviceMetricsMonitorType';
import OpenTelemetry from 'otel_sdk';

const DOMAIN: number = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // Initialize Preferences
    PreferencesUtil.init(this.context);

    // Initialize FT SDK
    await this.initFTSDK();

    windowStage.loadContent('pages/LoginPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  /**
   * Initialize FT SDK
   */
  private async initFTSDK(): Promise<void> {
    try {
      const setting = await SettingConfigManager.readSetting();

      // 1. Configure FTSDKConfig
      let sdkConfig: FTSDKConfig;
      if (setting.type === AccessType.DATAKIT) {
        // Local environment deployment (DataKit)
        sdkConfig = FTSDKConfig.builder(setting.datakitAddress);
      } else {
        // Public DataWay
        sdkConfig = FTSDKConfig.builder(setting.datawayAddress, setting.datawayClientToken);
      }

      sdkConfig.setServiceName('ft-sdk-demo-harmonyos')
        .setDebug(true)
        .setEnv(EnvType.PROD)
        .setAutoSync(true)
        .setSyncPageSize(SyncPageSize.LARGE) // Increase page size for faster upload
        .setDbCacheLimit(10 * 1024 * 1024) // 10MB database cache limit
        .setDBCacheDiscard(DBCacheDiscard.DISCARD_OLDEST);

      await FTSDK.install(sdkConfig, this.context);
      hilog.info(DOMAIN, 'FTSDK', 'FTSDK installed successfully');

      // 2. Configure FTLoggerConfig (Log configuration)
      const logConfig = new FTLoggerConfig()
        .setSamplingRate(1.0) // 100% sampling rate
        .setEnableCustomLog(true)
        .setEnableLinkRumData(true)
        .setEnableConsoleLog(true) // Enable console log capture
        .setLogCacheLimitCount(10000) // Log cache count
        .setPrintCustomLogToConsole(true) // Print custom logs to console
        .setLogLevelFilters([
          Status.ERROR,
          Status.WARN,
          Status.INFO,
          Status.DEBUG
        ]);

      FTSDK.installLogConfig(logConfig);
      hilog.info(DOMAIN, 'FTSDK', 'FTLoggerConfig installed successfully');

      // 3. Configure FTRUMConfig (RUM configuration)
      const rumConfig = new FTRUMConfig()
        .setRumAppId(setting.appId)
        .setSamplingRate(1.0) // 100% RUM sampling rate
        .setSessionErrorSampleRate(1.0) // 100% error sampling rate
        .setEnableTraceUserAction(true)
        .setEnableTraceUserView(true)
        .setEnableTraceUserResource(true)
        .setEnableTrackAppCrash(true) // Enable crash tracking
        .setEnableTrackAppANR(true) // Enable ANR tracking
        .setEnableTrackAppUIBlock(true) // Enable UI block tracking
        .setEnableTraceWebView(true) // Enable WebView tracking
        .setEnableTrackNativeCrash(true)
        .setExtraMonitorTypeWithError(ErrorMonitorType.ALL) // All error monitor types
        .setDeviceMetricsMonitorType(DeviceMetricsMonitorType.ALL); // All device metrics monitor types

      await FTSDK.installRUMConfig(rumConfig);
      hilog.info(DOMAIN, 'FTSDK', 'FTRUMConfig installed successfully');

      // 4. Configure FTTraceConfig (Trace configuration)
      const traceConfig = new FTTraceConfig()
        .setSamplingRate(1.0)
        .setTraceType(TraceType.DDTRACE)
        .setEnableAutoTrace(true)
        .setEnableLinkRUMData(true);

      FTSDK.installTraceConfig(traceConfig);
      hilog.info(DOMAIN, 'FTSDK', 'FTTraceConfig installed successfully');

      // 5. Initialize OTEL SDK (similar to Android's setOtelSDK)
      this.initOtelSDK(setting.otelAddress);

      // Log initialization (using static method)
      FTLogger.logBackground('FT SDK initialized successfully', Status.INFO);

    } catch (error) {
      const errorObj: Error = error as Error;
      hilog.error(DOMAIN, 'FTSDK', `Failed to initialize FT SDK: ${errorObj.message}`);
    }
  }

  /**
   * Initialize OTEL SDK
   * Similar to Android's setOtelSDK method
   */
  private initOtelSDK(otelAddress: string): void {
    try {
      if (!otelAddress || otelAddress.length === 0) {
        hilog.warn(DOMAIN, 'OTEL', 'OTEL address is empty, skipping OTEL SDK initialization');
        return;
      }

      const success = OpenTelemetry.initialize(otelAddress, 'ft-sdk-demo');
      if (success) {
        hilog.info(DOMAIN, 'OTEL', 'OTEL SDK initialized successfully');
      } else {
        hilog.error(DOMAIN, 'OTEL', 'Failed to initialize OTEL SDK');
      }
    } catch (error) {
      const errorObj: Error = error as Error;
      hilog.error(DOMAIN, 'OTEL', `Failed to initialize OTEL SDK: ${errorObj.message}`);
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
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
