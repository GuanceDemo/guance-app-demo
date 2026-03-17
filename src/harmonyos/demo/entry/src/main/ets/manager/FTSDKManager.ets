import { Context, common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { AccessType } from '../constants/AccessType';
import { FTSDK } from 'ft_sdk/src/main/ets/components/FTSDK';
import { FTSDKConfig, FTRUMConfig, FTLoggerConfig, FTTraceConfig } from 'ft_sdk/src/main/ets/components/Configs';
import { EnvType, SyncPageSize, DBCacheDiscard } from 'ft_sdk/src/main/ets/components/enum/Enums';
import { TraceType } from 'ft_sdk/src/main/ets/components/trace/TraceType';
import { FTLogger } from 'ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from 'ft_sdk/src/main/ets/components/bean/Status';
import { ErrorMonitorType } from 'ft_sdk/src/main/ets/components/rum/enum/ErrorMonitorType';
import { DeviceMetricsMonitorType } from 'ft_sdk/src/main/ets/components/rum/enum/DeviceMetricsMonitorType';
import OpenTelemetry from 'otel_sdk';

const DOMAIN: number = 0x0000;
const TAG: string = 'FTSDKManager';

/**
 * FT SDK Manager
 * Manages SDK initialization and re-initialization
 */
export class FTSDKManager {
  private static instance: FTSDKManager | null = null;
  private context: common.UIAbilityContext | null = null;
  private isInitialized: boolean = false;

  private constructor() {}

  /**
   * Get singleton instance
   */
  public static getInstance(): FTSDKManager {
    if (!FTSDKManager.instance) {
      FTSDKManager.instance = new FTSDKManager();
    }
    return FTSDKManager.instance;
  }

  /**
   * Initialize manager with context
   * Must be called before initSDK or reInitSDK
   */
  public init(context: common.UIAbilityContext): void {
    this.context = context;
    hilog.info(DOMAIN, TAG, 'FTSDKManager initialized with context');
  }

  /**
   * Initialize FT SDK
   * Should be called on app startup
   */
  public async initSDK(): Promise<void> {
    if (!this.context) {
      hilog.error(DOMAIN, TAG, 'Context not initialized, call init() first');
      return;
    }

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
      hilog.info(DOMAIN, TAG, 'FTSDK installed successfully');

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
      hilog.info(DOMAIN, TAG, 'FTLoggerConfig installed successfully');

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
        .setExtraMonitorTypeWithError(ErrorMonitorType.ALL) // All error monitor types
        .setDeviceMetricsMonitorType(DeviceMetricsMonitorType.ALL); // All device metrics monitor types

      FTSDK.installRUMConfig(rumConfig);
      hilog.info(DOMAIN, TAG, 'FTRUMConfig installed successfully');

      // 4. Configure FTTraceConfig (Trace configuration)
      const traceConfig = new FTTraceConfig()
        .setSamplingRate(1.0)
        .setTraceType(TraceType.DDTRACE)
        .setEnableAutoTrace(true)
        .setEnableLinkRUMData(true);

      FTSDK.installTraceConfig(traceConfig);
      hilog.info(DOMAIN, TAG, 'FTTraceConfig installed successfully');

      // 5. Initialize OTEL SDK
      this.initOtelSDK(setting.otelAddress);

      // Log initialization
      FTLogger.logBackground('FT SDK initialized successfully', Status.INFO);

      this.isInitialized = true;

    } catch (error) {
      const errorObj: Error = error as Error;
      hilog.error(DOMAIN, TAG, `Failed to initialize FT SDK: ${errorObj.message}`);
    }
  }

  /**
   * Re-initialize FT SDK with new configuration
   * Should be called after configuration changes
   */
  public async reInitSDK(): Promise<void> {
    if (!this.context) {
      hilog.error(DOMAIN, TAG, 'Context not initialized, call init() first');
      return;
    }

    hilog.info(DOMAIN, TAG, 'Re-initializing FT SDK...');

    try {
      // 1. Shutdown existing SDK
      if (this.isInitialized) {
        FTSDK.shutDown();
        hilog.info(DOMAIN, TAG, 'FTSDK shut down successfully');
        this.isInitialized = false;
      }

      // 2. Wait a bit for cleanup
      await new Promise<void>((resolve: () => void) => {
        setTimeout(resolve, 100);
      });

      // 3. Re-initialize with new configuration
      await this.initSDK();

      hilog.info(DOMAIN, TAG, 'FT SDK re-initialized successfully');

    } catch (error) {
      const errorObj: Error = error as Error;
      hilog.error(DOMAIN, TAG, `Failed to re-initialize FT SDK: ${errorObj.message}`);
    }
  }

  /**
   * Initialize OTEL SDK
   */
  private initOtelSDK(otelAddress: string): void {
    try {
      if (!otelAddress || otelAddress.length === 0) {
        hilog.warn(DOMAIN, TAG, 'OTEL address is empty, skipping OTEL SDK initialization');
        return;
      }

      const success = OpenTelemetry.initialize(otelAddress, 'ft-sdk-demo');
      if (success) {
        hilog.info(DOMAIN, TAG, 'OTEL SDK initialized successfully');
      } else {
        hilog.error(DOMAIN, TAG, 'Failed to initialize OTEL SDK');
      }
    } catch (error) {
      const errorObj: Error = error as Error;
      hilog.error(DOMAIN, TAG, `Failed to initialize OTEL SDK: ${errorObj.message}`);
    }
  }

  /**
   * Check if SDK is initialized
   */
  public isSDKInitialized(): boolean {
    return this.isInitialized;
  }
}
